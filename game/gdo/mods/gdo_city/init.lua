-- GDO — Cité des Canaux
-- Nouvelle région indépendante, inspirée de la capture "elven.png" du diaporama NLite.
-- La capture sert de référence visuelle : aucun monde, schéma ou asset tiers n'est importé.
-- La génération est déterministe, limitée à sa propre emprise et versionnée séparément.

local A = gdo_castle_architecture
assert(A and A.materials, "[GDO City] gdo_castle_architecture doit être chargé avant la cité.")

local storage = minetest.get_mod_storage()
local VERSION = 1
local BOUNDS = {x1 = -58, x2 = 58, z1 = 780, z2 = 920}
local SPAWN = {x = 0, z = 861}
local CITY_NAME = "Cité des Canaux"
local base_y = nil
local ready = false
local building = false
local pending_spawns = {}
local M = A.materials
local water_node = "gdo_core:eau"

gdo_city = {
    name = CITY_NAME,
    bounds = BOUNDS,
    spawn = nil,
    is_ready = function() return ready end,
}

local function y(offset)
    return (base_y or 0) + offset
end

local function put(x, level, z, node, param2)
    A.put(x, y(level), z, node, param2)
end

local function fill(x1, level1, z1, x2, level2, z2, node)
    A.fill(x1, y(level1), z1, x2, y(level2), z2, node)
end

local function clear(x1, level1, z1, x2, level2, z2)
    A.clear(x1, y(level1), z1, x2, y(level2), z2)
end

local function build_channel(x1, z1, x2, z2)
    -- Lit de pierre et eau en source : le canal reste stable, sans calcul de courant.
    fill(x1, -4, z1, x2, -2, z2, M.stone)
    fill(x1, -1, z1, x2, -1, z2, water_node)
end

local function build_house(cx, cz, width, depth, variant)
    local x1, x2 = cx, cx + width - 1
    local z1, z2 = cz, cz + depth - 1
    local mid = math.floor((x1 + x2) / 2)
    local wall = (variant % 3 == 0) and M.plaster or M.stone
    local roof = (variant % 2 == 0) and M.tile_red or M.roof

    fill(x1, 0, z1, x2, 0, z2, M.floor)
    fill(x1, 1, z1, x2, 5, z2, wall)
    clear(x1 + 1, 1, z1 + 1, x2 - 1, 4, z2 - 1)

    -- Portes orientées vers le canal ou la rue principale (façade sud).
    clear(mid - 1, 1, z2, mid + 1, 4, z2)
    fill(mid - 2, 1, z2, mid - 2, 4, z2, M.trim)
    fill(mid + 2, 1, z2, mid + 2, 4, z2, M.trim)
    fill(mid - 2, 5, z2, mid + 2, 5, z2, M.trim)

    -- Fenêtres à meneaux sur les façades visibles.
    for _, z in ipairs({z1, z2}) do
        for _, x in ipairs({x1 + 2, x2 - 2}) do
            if not (z == z2 and math.abs(x - mid) <= 2) then
                put(x, 3, z, M.trim)
                put(x, 4, z, M.glass)
                put(x, 5, z, M.trim)
            end
        end
    end
    for _, x in ipairs({x1, x2}) do
        local wz = math.floor((z1 + z2) / 2)
        put(x, 3, wz, M.trim)
        put(x, 4, wz, M.glass)
        put(x, 5, wz, M.trim)
    end

    -- Colombages apparents : montants et traverses en chêne sombre.
    for _, x in ipairs({x1, x1 + 3, x2 - 3, x2}) do
        fill(x, 1, z1, x, 5, z1, M.wood)
        fill(x, 1, z2, x, 5, z2, M.wood)
    end
    fill(x1, 5, z1, x2, 5, z1, M.wood)
    fill(x1, 5, z2, x2, 5, z2, M.wood)

    -- Toit à deux pans, pignons visibles et faîtage continu.
    local half = math.floor(width / 2)
    for layer = 0, half - 1 do
        local left, right = x1 + layer, x2 - layer
        local roof_y = 6 + layer
        fill(left, roof_y, z1 - 1, left, roof_y, z2 + 1, roof)
        fill(right, roof_y, z1 - 1, right, roof_y, z2 + 1, roof)
        fill(left, 5 + layer, z1, right, 5 + layer, z1, wall)
        fill(left, 5 + layer, z2, right, 5 + layer, z2, wall)
    end
    fill(mid, 6 + half, z1 - 1, mid, 6 + half, z2 + 1, M.trim)

    -- Cheminée et mobilier simple, sans bloquer la circulation intérieure.
    fill(x1 + 1, 6, z1 + 1, x1 + 2, 8, z1 + 2, M.stone)
    put(x1 + 4, 1, z1 + 4, M.table)
    put(x1 + 3, 1, z1 + 4, M.bench)
    A.lamp(x2 - 2, y(4), z1 + 2)
end

local function build_spire(cx, cz, radius, wall_height)
    for level = 1, wall_height do
        for dx = -radius, radius do
            for dz = -radius, radius do
                if math.max(math.abs(dx), math.abs(dz)) == radius then
                    put(cx + dx, level, cz + dz, (level % 5 == 0) and M.trim or M.stone)
                end
            end
        end
    end
    clear(cx - radius + 1, 1, cz - radius + 1,
        cx + radius - 1, wall_height - 1, cz + radius - 1)
    fill(cx - radius + 1, 0, cz - radius + 1,
        cx + radius - 1, 0, cz + radius - 1, M.floor)
    for layer = 0, radius + 2 do
        local inset = math.max(0, radius - layer)
        fill(cx - inset, wall_height + 1 + layer, cz - inset,
            cx + inset, wall_height + 1 + layer, cz + inset, M.roof)
    end
    put(cx, wall_height + radius + 4, cz, M.gold)
    A.lamp(cx, y(4), cz)
end

local function build_city_hall()
    local x1, x2, z1, z2 = -14, 14, 885, 909

    fill(x1, 0, z1, x2, 0, z2, M.floor)
    fill(x1, 1, z1, x2, 9, z2, M.stone)
    clear(x1 + 1, 2, z1 + 1, x2 - 1, 8, z2 - 1)

    -- Grande entrée tournée vers la place et le point d'apparition.
    clear(-3, 1, z1, 3, 7, z1)
    fill(-5, 1, z1, -4, 7, z1, M.trim)
    fill(4, 1, z1, 5, 7, z1, M.trim)
    fill(-5, 8, z1, 5, 8, z1, M.trim)
    put(0, 9, z1, M.gold)

    -- Fenêtres hautes et contreforts verticaux.
    for _, x in ipairs({-10, -6, 6, 10}) do
        put(x, 4, z1, M.trim)
        put(x, 5, z1, M.glass)
        put(x, 6, z1, M.trim)
        put(x, 4, z2, M.trim)
        put(x, 5, z2, M.glass)
        put(x, 6, z2, M.trim)
        fill(x, 1, z1 + 2, x, 8, z1 + 2, M.trim)
    end

    -- Toiture pentue à deux pans.
    for layer = 0, 7 do
        local left, right = x1 + layer, x2 - layer
        fill(left, 10 + layer, z1 - 1, left, 10 + layer, z2 + 1, M.roof)
        fill(right, 10 + layer, z1 - 1, right, 10 + layer, z2 + 1, M.roof)
        fill(left, 9 + layer, z1, right, 9 + layer, z1, M.trim)
        fill(left, 9 + layer, z2, right, 9 + layer, z2, M.trim)
    end
    fill(0, 18, z1 - 1, 0, 18, z2 + 1, M.trim)

    -- Tour d'horloge sur le faîtage, visible depuis les canaux.
    build_spire(0, 897, 3, 15)
    A.lamp(-9, y(7), 891)
    A.lamp(9, y(7), 891)
    put(0, 1, 900, M.banner)
    put(-8, 1, 900, M.table)
    put(8, 1, 900, M.table)
end

local function build_bridges()
    -- Trois ponts de pierre au niveau des quais : pas de marches ni de seuil haut.
    for _, cx in ipairs({-27, 5, 44}) do
        fill(cx - 2, 0, 834, cx + 2, 0, 853, M.floor)
        fill(cx - 2, 1, 834, cx - 2, 2, 853, M.trim)
        fill(cx + 2, 1, 834, cx + 2, 2, 853, M.trim)
        for _, z in ipairs({835, 852}) do
            fill(cx - 2, 1, z, cx + 2, 1, z, M.gold)
        end
    end

    -- Passage transversal sur le canal secondaire.
    fill(17, 0, 878, 38, 0, 882, M.floor)
    fill(17, 1, 878, 17, 2, 882, M.trim)
    fill(38, 1, 878, 38, 2, 882, M.trim)
end

local function build_docks()
    -- Deux pontons de marchandises, barils et lanternes.
    fill(-56, 0, 829, -39, 0, 832, M.wood)
    fill(-54, 0, 855, -40, 0, 858, M.wood)
    for _, x in ipairs({-54, -48, -42}) do
        fill(x, 1, 829, x, 3, 829, M.wood)
        fill(x, 1, 855, x, 3, 855, M.wood)
    end
    for _, pos in ipairs({
        {x = -52, z = 830}, {x = -45, z = 831},
        {x = -51, z = 856}, {x = -43, z = 856},
    }) do
        put(pos.x, 1, pos.z, M.barrel)
        put(pos.x + 1, 1, pos.z, M.crate)
    end
    A.lamp(-40, y(4), 830)
    A.lamp(-40, y(4), 857)
end

local function build_market()
    -- Place centrale pavée, bordure de pierre et fontaine.
    fill(-17, 0, 858, 17, 0, 882, M.floor)
    fill(-17, 0, 858, 17, 0, 859, M.trim)
    fill(-17, 0, 881, 17, 0, 882, M.trim)
    fill(-17, 0, 858, -16, 0, 882, M.trim)
    fill(16, 0, 858, 17, 0, 882, M.trim)

    -- Fontaine circulaire, au ras de la place.
    fill(-4, 0, 866, 4, 0, 874, M.stone)
    fill(-3, 1, 867, 3, 1, 873, water_node)
    fill(-4, 1, 866, 4, 1, 866, M.trim)
    fill(-4, 1, 874, 4, 1, 874, M.trim)
    fill(-4, 1, 866, -4, 1, 874, M.trim)
    fill(4, 1, 866, 4, 1, 874, M.trim)
    fill(-1, 2, 869, 1, 3, 871, M.gold)
    A.lamp(0, y(4), 870)

    -- Deux étals couverts, laissant un large axe jusqu'à l'hôtel de ville.
    for _, x in ipairs({-12, 12}) do
        fill(x - 3, 0, 863, x + 3, 0, 868, M.wood)
        fill(x - 3, 3, 862, x + 3, 3, 869, (x < 0) and M.tile_red or M.roof)
        fill(x - 3, 1, 863, x + 3, 1, 863, M.trim)
        put(x - 2, 1, 865, M.crate)
        put(x + 2, 1, 865, M.barrel)
    end

    -- Pierre de passage vers l'ancien quartier du Château des Brumes.
    put(0, 1, 877, "gdo_city:waystone")
    put(-15, 1, 878, M.banner)
    put(15, 1, 878, M.banner)
end

local function build_houses()
    local houses = {
        {-52, 790, 11, 12, 1}, {-36, 790, 11, 12, 2},
        {-20, 790, 11, 12, 3}, {17, 790, 11, 12, 4},
        {38, 790, 11, 12, 5},
        {-52, 813, 11, 12, 6}, {-36, 813, 11, 12, 7},
        {-20, 813, 11, 12, 8}, {17, 813, 11, 12, 9},
        {38, 813, 11, 12, 10},
        {-52, 860, 11, 12, 11}, {-36, 860, 11, 12, 12},
        {-52, 883, 11, 12, 13}, {-36, 883, 11, 12, 14},
        {39, 860, 10, 12, 15}, {39, 883, 10, 12, 16},
        {49, 860, 9, 12, 17}, {49, 883, 9, 12, 18},
    }
    for _, h in ipairs(houses) do
        build_house(h[1], h[2], h[3], h[4], h[5])
    end
end

local function build_greenery()
    -- Petits jardins de rive, arbres et bancs ; les plantations restent hors des rues.
    for _, p in ipairs({
        {x = -55, z = 875}, {x = -47, z = 877}, {x = 48, z = 905},
        {x = 52, z = 905}, {x = 50, z = 910},
    }) do
        fill(p.x, 1, p.z, p.x, 5, p.z, "gdo_core:arbre")
        for dx = -2, 2 do
            for dz = -2, 2 do
                if math.abs(dx) + math.abs(dz) <= 3 then
                    put(p.x + dx, 5, p.z + dz, "gdo_core:feuilles")
                    put(p.x + dx, 6, p.z + dz, "gdo_core:feuilles")
                end
            end
        end
    end
    for _, p in ipairs({{x = -44, z = 872}, {x = 44, z = 906}}) do
        put(p.x, 1, p.z, M.bench)
        A.lamp(p.x, y(4), p.z + 2)
    end
end

local function build_south_gate()
    -- Porte sud et deux petites tours ; raccord au chemin venant des autres régions.
    fill(-58, 1, 914, -8, 5, 915, M.stone)
    fill(8, 1, 914, 58, 5, 915, M.stone)
    clear(-4, 1, 914, 4, 5, 915)
    fill(-7, 1, 914, -5, 7, 915, M.trim)
    fill(5, 1, 914, 7, 7, 915, M.trim)
    fill(-7, 8, 914, 7, 8, 915, M.gold)
    build_spire(-10, 914, 2, 8)
    build_spire(10, 914, 2, 8)
    A.lamp(0, y(9), 914)
end

local function build_roads()
    -- Rue principale nord-sud, promenades des quais et venelles est-ouest.
    fill(-7, 0, 780, 7, 0, 835, M.path)
    fill(-56, 0, 830, 56, 0, 833, M.path)
    fill(-56, 0, 854, 56, 0, 857, M.path)
    fill(-56, 0, 807, 56, 0, 809, M.path)
    fill(-56, 0, 829, -40, 0, 829, M.trim)
    fill(-56, 0, 858, -40, 0, 858, M.trim)
    fill(35, 0, 851, 37, 0, 914, M.path)
    fill(18, 0, 881, 56, 0, 883, M.path)

    -- Pavage décoratif des carrefours.
    for _, x in ipairs({-27, 5, 44}) do
        fill(x - 3, 0, 830, x + 3, 0, 835, M.floor)
        fill(x - 3, 0, 853, x + 3, 0, 858, M.floor)
    end
end

local function build_lighting()
    for x = -52, 52, 13 do
        for _, z in ipairs({833, 854, 808, 881}) do
            A.lamp(x, y(4), z)
            put(x, 0, z, M.stone)
        end
    end
    for z = 790, 910, 16 do
        A.lamp(-55, y(4), z)
        A.lamp(55, y(4), z)
    end
end

local function build_city()
    -- Le secteur n'a pas d'emprise sur les cartes du château ou des villages de guilde.
    A.flatten_rect(BOUNDS, base_y, 192)
    clear(BOUNDS.x1, 1, BOUNDS.z1, BOUNDS.x2, 30, BOUNDS.z2)

    -- Canaux principaux et bassin portuaire.
    build_channel(-55, 838, 56, 849)
    build_channel(-57, 827, -40, 860)
    build_channel(22, 848, 33, 910)

    -- Quais, promenades, rues et ponts.
    build_roads()
    build_bridges()
    build_docks()

    -- Bâtiments et lieux de vie.
    build_houses()
    build_market()
    build_city_hall()
    build_greenery()
    build_south_gate()
    build_lighting()

    A.fix_light(BOUNDS)
    ready = true
    storage:set_int("city_version", VERSION)
    storage:set_int("city_base_y", base_y)
    storage:set_int("city_base_initialized", 1)
    minetest.log("action", "[GDO][CITY] Cité des Canaux construite et conservée comme région indépendante.")
end

local function finish_pending_spawns()
    for name in pairs(pending_spawns) do
        local player = minetest.get_player_by_name(name)
        if player then
            player:set_pos({x = SPAWN.x, y = y(1), z = SPAWN.z})
            if player.set_velocity then player:set_velocity({x = 0, y = 0, z = 0}) end
            minetest.chat_send_player(name, "Bienvenue dans la Cité des Canaux ! Explore le port, les ponts et la place de l'hôtel de ville. /gdo_castle permet de rejoindre le Château des Brumes.")
        end
        pending_spawns[name] = nil
    end
end

function gdo_city.spawn(player)
    if not player or not player:is_player() then return false end
    local name = player:get_player_name()
    if not ready then
        pending_spawns[name] = true
        return true
    end
    player:set_pos({x = SPAWN.x, y = y(1), z = SPAWN.z})
    if player.set_velocity then player:set_velocity({x = 0, y = 0, z = 0}) end
    return true
end

-- Région scénarisée en lecture seule ; les villages et terres sauvages restent inchangés.
if gdo_zones and gdo_zones.register_readonly_zone then
    gdo_zones.register_readonly_zone({
        name = CITY_NAME,
        description = "Cité portuaire, canaux, hôtel de ville, quais, ponts et maisons",
        min = {x = BOUNDS.x1, y = -32, z = BOUNDS.z1},
        max = {x = BOUNDS.x2, y = 192, z = BOUNDS.z2},
    })
end

minetest.register_node("gdo_city:waystone", {
    description = "Pierre de passage — Château des Brumes",
    drawtype = "nodebox",
    tiles = {"unknown_node.png^[colorize:#d5a52d:220"},
    paramtype = "light",
    light_source = 8,
    walkable = false,
    node_box = {type = "fixed", fixed = {-0.3, -0.5, -0.3, 0.3, 0.35, 0.3}},
    groups = {cracky = 2, oddly_breakable_by_hand = 2},
    on_rightclick = function(pos, node, clicker)
        if not clicker or not clicker:is_player() then return end
        local castle_y = gdo_castle_storage and gdo_castle_storage:get_int("architecture_castle_level") or 0
        clicker:set_pos({x = 0, y = castle_y + 1, z = 68})
        minetest.chat_send_player(clicker:get_player_name(), "Tu retournes au Château des Brumes. /gdo_city permet de revenir dans la cité.")
    end,
})

minetest.register_chatcommand("gdo_city", {
    description = "Rejoindre la Cité des Canaux",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then return false, "Joueur introuvable." end
        gdo_city.spawn(player)
        if not ready then return true, "La cité termine sa préparation ; tu y seras envoyé dès qu'elle sera prête." end
        return true, "Bienvenue dans la Cité des Canaux."
    end,
})

minetest.register_chatcommand("gdo_castle", {
    description = "Rejoindre le Château des Brumes",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then return false, "Joueur introuvable." end
        local castle_y = gdo_castle_storage and gdo_castle_storage:get_int("architecture_castle_level") or 0
        player:set_pos({x = 0, y = castle_y + 1, z = 68})
        return true, "Tu rejoins le Château des Brumes."
    end,
})

local function wait_for_site()
    if building or ready then return end
    if not gdo_castle_storage or gdo_castle_storage:get_int("architecture_site_version") < 1 then
        minetest.after(2, wait_for_site)
        return
    end

    local castle_y = gdo_castle_storage:get_int("architecture_castle_level")
    base_y = storage:get_int("city_base_y")
    building = true
    local emerge_failed = false

    minetest.emerge_area(
        {x = BOUNDS.x1, y = -32, z = BOUNDS.z1},
        {x = BOUNDS.x2, y = 192, z = BOUNDS.z2},
        function(_, action, remaining)
            if action == minetest.EMERGE_ERRORED or action == minetest.EMERGE_CANCELLED then
                emerge_failed = true
            end
            if remaining == 0 then
                if emerge_failed then
                    building = false
                    minetest.log("error", "[GDO][CITY] Impossible de charger les chunks de la cité ; la génération sera retentée.")
                    minetest.after(5, wait_for_site)
                    return
                end
                if storage:get_int("city_version") < VERSION then
                    if storage:get_int("city_base_initialized") == 1 then
                        -- Une reconstruction ne doit pas faire dériver l'altitude à cause
                        -- des fondations GDO déjà présentes sous la ville.
                        base_y = storage:get_int("city_base_y")
                    else
                        -- Échantillonner après l'émergence : avant celle-ci, la zone peut être
                        -- composée de nœuds "ignore" et produire une altitude erronée.
                        local sampled = A.median_surface(BOUNDS, 12)
                        base_y = sampled or castle_y
                    end
                    storage:set_int("city_base_y", base_y)
                    build_city()
                else
                    base_y = storage:get_int("city_base_y")
                    ready = true
                    minetest.log("action", "[GDO][CITY] Cité déjà présente ; aucune reconstruction nécessaire.")
                end
                building = false
                finish_pending_spawns()
            end
        end
    )
end

minetest.register_on_mods_loaded(function()
    minetest.after(4, wait_for_site)
end)

minetest.register_on_joinplayer(function(player)
    minetest.after(1, function()
        if player and player:is_player() then gdo_city.spawn(player) end
    end)
end)

minetest.register_on_respawnplayer(function(player)
    minetest.after(0.2, function()
        if player and player:is_player() then gdo_city.spawn(player) end
    end)
    return true
end)

minetest.register_chatcommand("gdo_city_info", {
    description = "Affiche l'état de la Cité des Canaux",
    func = function()
        return true, string.format("%s — version %d/%d — prête=%s — centre: X=%d, Z=%d — altitude=%d",
            CITY_NAME, storage:get_int("city_version"), VERSION,
            ready and "oui" or "en préparation", SPAWN.x, SPAWN.z, base_y or 0)
    end,
})

minetest.register_chatcommand("gdo_city_rebuild", {
    description = "Reconstruit la Cité des Canaux (zone réservée)",
    privs = {server = true},
    func = function()
        if building then return false, "La génération de la cité est déjà en cours." end
        storage:set_int("city_version", 0)
        ready = false
        pending_spawns = {}
        wait_for_site()
        return true, "Reconstruction de la Cité des Canaux demandée. Seule son emprise sera remplacée."
    end,
})

minetest.log("action", "[GDO City] La Cité des Canaux est enregistrée ; elle sera générée après le site du château.")
