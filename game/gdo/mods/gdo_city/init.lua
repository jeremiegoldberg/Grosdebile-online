-- GDO — Port elfique NLite
-- Reconstruction procédurale des vues "elven.png" et "praiaelven.png" de l'archive NLite.
-- Aucun monde Minecraft ni structure exportée n'est disponible ; les volumes visibles sont reconstruits en Lua.
-- La génération est versionnée, indépendante et limitée à son emprise dynamique.

local A = gdo_castle_architecture
assert(A and A.materials, "[GDO City] gdo_castle_architecture doit être chargé avant la cité.")

local storage = minetest.get_mod_storage()
local VERSION = 2
local LEGACY_BOUNDS = {x1 = -58, x2 = 58, z1 = 780, z2 = 920}
local RADIUS = 96
local BOUNDS = LEGACY_BOUNDS
local SPAWN = {x = 82, z = 868}
local center_x, center_z = 0, 850
local SITE_Y_MIN, SITE_Y_MAX = -32, 192
local SITE_CANDIDATES = {
    {270, 860}, {-270, 860}, {270, 1180}, {-270, 1180},
    {0, 1180}, {0, 560}, {270, 560}, {-270, 560},
    {270, 1500}, {-270, 1500}, {0, 1500},
    {270, 2000}, {-270, 2000}, {0, 2000},
    {270, -560}, {-270, -560}, {0, -560},
    {850, 0}, {-850, 0}, {0, -850}, {850, -850}, {-850, -850},
    {0, 2400}, {0, -1800}, {1200, 0}, {-1200, 0},
}
local CITY_NAME = "Port elfique"
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

-- Coordonnées locales : le centre absolu n'est choisi qu'après validation du terrain.
local function wx(x) return center_x + x end
local function wz(z) return center_z + z - 850 end
local function put(x, level, z, node, param2)
    A.put(wx(x), y(level), wz(z), node, param2)
end
local function fill(x1, level1, z1, x2, level2, z2, node)
    A.fill(wx(x1), y(level1), wz(z1), wx(x2), y(level2), wz(z2), node)
end
local function clear(x1, level1, z1, x2, level2, z2)
    A.clear(wx(x1), y(level1), wz(z1), wx(x2), y(level2), wz(z2))
end
local function lamp(x, level, z)
    A.lamp(wx(x), y(level), wz(z))
end
local function build_channel(x1, z1, x2, z2)
    fill(x1, -5, z1, x2, -3, z2, M.stone)
    fill(x1, -2, z1, x2, -1, z2, water_node)
end


local function build_house(cx, cz, width, depth, variant, front)
    local x1, x2 = cx, cx + width - 1
    local z1, z2 = cz, cz + depth - 1
    local mid = math.floor((x1 + x2) / 2)
    local wall = (variant % 3 == 0) and M.plaster or M.stone
    local roof = (variant % 2 == 0) and M.tile_red or M.roof

    fill(x1, 0, z1, x2, 0, z2, M.floor)
    fill(x1, 1, z1, x2, 5, z2, wall)
    clear(x1 + 1, 1, z1 + 1, x2 - 1, 4, z2 - 1)

    -- Entrée tournée vers le canal selon la rive.
    local front_z = (front == "north") and z1 or z2
    clear(mid - 1, 1, front_z, mid + 1, 4, front_z)
    fill(mid - 2, 1, front_z, mid - 2, 4, front_z, M.trim)
    fill(mid + 2, 1, front_z, mid + 2, 4, front_z, M.trim)
    fill(mid - 2, 5, front_z, mid + 2, 5, front_z, M.trim)

    -- Fenêtres à meneaux sur les façades visibles.
    for _, z in ipairs({z1, z2}) do
        for _, x in ipairs({x1 + 2, x2 - 2}) do
            if not (z == front_z and math.abs(x - mid) <= 2) then
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
    lamp(x2 - 2, 4, z1 + 2)
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
    lamp(cx, 4, cz)
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
    lamp(-9, 7, 891)
    lamp(9, 7, 891)
    put(0, 1, 900, M.banner)
    put(-8, 1, 900, M.table)
    put(8, 1, 900, M.table)
end

local function build_bridges()
    -- Trois traversées du canal principal, avec une arche basse sous la chaussée.
    for _, cx in ipairs({-27, 5, 44}) do
        fill(cx - 3, 0, 834, cx + 3, 0, 853, M.floor)
        fill(cx - 3, 1, 834, cx - 3, 2, 853, M.trim)
        fill(cx + 3, 1, 834, cx + 3, 2, 853, M.trim)
        for _, x in ipairs({cx - 2, cx + 2}) do
            for z = 837, 850 do
                local arch = math.floor(math.sqrt(math.max(0, 49 - (z - 843.5) * (z - 843.5))) / 3)
                put(x, -2 + arch, z, M.stone)
            end
        end
    end
    -- Pont transversal sur le bras qui rejoint la plage.
    fill(52, 0, 878, 78, 0, 882, M.floor)
    fill(52, 1, 878, 52, 2, 882, M.trim)
    fill(78, 1, 878, 78, 2, 882, M.trim)
end



local function build_docks()
    -- Quais de pierre et pontons en bois dans le bassin ouest.
    fill(-94, 0, 827, -66, 0, 830, M.wood)
    fill(-92, 0, 855, -66, 0, 858, M.wood)
    for _, x in ipairs({-91, -82, -73}) do
        fill(x, 1, 827, x, 4, 827, M.wood)
        fill(x, 1, 855, x, 4, 855, M.wood)
        put(x, 1, 828, M.barrel)
        put(x + 2, 1, 828, M.crate)
    end
    lamp(-66, 4, 829)
    lamp(-66, 4, 856)
end



local function build_market()
    -- Petite place de débarquement à l'est du bras de canal, reliée au pont.
    fill(78, 0, 866, 95, 0, 881, M.floor)
    fill(78, 0, 866, 95, 0, 867, M.trim)
    fill(78, 0, 880, 95, 0, 881, M.trim)
    fill(78, 0, 866, 79, 0, 881, M.trim)
    fill(94, 0, 866, 95, 0, 881, M.trim)
    fill(83, 0, 871, 89, 0, 877, M.stone)
    fill(84, 1, 872, 88, 1, 876, water_node)
    for _, x in ipairs({79, 89}) do
        fill(x, 0, 875, x + 4, 0, 879, M.wood)
        fill(x, 4, 874, x + 4, 4, 880, (x < 85) and M.tile_red or M.roof)
        put(x + 1, 1, 876, M.crate)
        put(x + 3, 1, 877, M.barrel)
    end
    put(85, 1, 878, "gdo_city:waystone")
    lamp(85, 4, 878)
end


local function build_houses()
    -- Maisons mitoyennes serrées en deux fronts continus, tournés vers le canal.
    local positions = {-58, -43, -28, -13, 2, 17, 32}
    for i, x in ipairs(positions) do
        build_house(x, 811, 15, 22, i, "south")
        build_house(x, 860, 15, 22, i + 8, "north")
    end
    -- Échoppes et maisons hautes qui ferment visuellement le bassin portuaire.
    for i, p in ipairs({
        {-89, 868, 13}, {-73, 868, 15}, {-57, 868, 12},
        {-89, 787, 14}, {-72, 787, 12}, {-55, 787, 15},
        {72, 810, 12}, {72, 832, 14},
    }) do
        build_house(p[1], p[2], 14, 20, p[3] + i, "south")
    end
end



local function build_greenery()
    -- Arbres de quai et arbre clair à floraison blanche près de la plage.
    for _, p in ipairs({
        {x = -94, z = 875}, {x = -92, z = 884}, {x = 91, z = 906},
        {x = 94, z = 910}, {x = 88, z = 913},
    }) do
        fill(p.x, 1, p.z, p.x, 5, p.z, "gdo_core:arbre")
        for dx = -2, 2 do
            for dz = -2, 2 do
                if math.abs(dx) + math.abs(dz) <= 3 then
                    put(p.x + dx, 6, p.z + dz, M.leaves)
                    put(p.x + dx, 7, p.z + dz, M.leaves)
                end
            end
        end
    end
    put(-85, 1, 872, M.bench)
    lamp(-85, 4, 874)
end



local function build_south_gate()
    -- Muraille arrière et porte fortifiée, derrière la silhouette de la cathédrale.
    fill(-96, 1, 940, -12, 16, 943, M.stone)
    fill(12, 1, 940, 96, 16, 943, M.stone)
    clear(-11, 1, 940, 11, 10, 943)
    fill(-14, 1, 940, -12, 19, 943, M.trim)
    fill(12, 1, 940, 14, 19, 943, M.trim)
    fill(-14, 20, 940, 14, 20, 943, M.roof)
    for _, x in ipairs({-88, -55, -22, 22, 55, 88}) do
        build_spire(x, 941, 4, 14)
    end
end



local function build_roads()
    -- Promenades de pierre sur les deux berges et axe d'accès au quartier haut.
    fill(-95, 0, 831, 60, 0, 834, M.path)
    fill(-95, 0, 854, 60, 0, 857, M.path)
    fill(52, 0, 854, 56, 0, 939, M.path)
    fill(58, 0, 899, 91, 0, 902, M.path)
    for _, x in ipairs({-25, 18, 53}) do
        fill(x - 2, 0, 833, x + 2, 0, 854, M.floor)
    end
end



local function build_lighting()
    for x = -90, 90, 15 do
        lamp(x, 4, 831)
        lamp(x, 4, 856)
    end
    for z = 790, 930, 18 do
        lamp(-94, 4, z)
        lamp(91, 4, z)
    end
end

local function build_ships()
    -- Trois navires marchands : coques, ponts, mâts et voiles dans le bassin ouest.
    local function ship(x, z, length, sail)
        for row = 0, 5 do
            local half = math.floor(length / 2 * (1 - math.abs(row - 2.5) / 4))
            fill(x - half, -1, z + row, x + half, -1, z + row, M.wood)
            if half > 1 then
                fill(x - half + 1, -2, z + row, x + half - 1, -2, z + row, M.wood)
            end
        end
        local deck_half = math.floor(length / 2) - 2
        fill(x - deck_half, 0, z + 1, x + deck_half, 0, z + 4, M.wood)
        fill(x, 1, z + 2, x, 15, z + 2, M.wood)
        fill(x - 1, 4, z + 1, x + 1, 12, z + 1, sail)
        fill(x - 1, 5, z + 3, x + 1, 13, z + 3, sail)
        put(x, 14, z + 2, M.trim)
    end
    ship(-84, 832, 25, M.plaster)
    ship(-75, 848, 21, M.tile_red)
    ship(-87, 857, 17, M.plaster)
    for _, x in ipairs({-96, -90, -68}) do
        fill(x, 1, 862, x, 12, 862, M.wood)
        fill(x - 4, 11, 862, x + 4, 11, 862, M.wood)
        put(x, 10, 861, M.barrel)
        put(x + 2, 1, 864, M.crate)
    end
end

local function build_cathedral()
    -- Cathédrale monumentale et tours secondaires, en fond de perspective.
    fill(20, 0, 884, 82, 0, 931, M.floor)
    fill(25, 1, 886, 77, 12, 928, M.stone)
    clear(27, 1, 888, 75, 10, 926)
    clear(46, 1, 886, 57, 7, 894)
    for _, x in ipairs({27, 35, 67, 75}) do
        fill(x, 1, 888, x + 1, 11, 926, M.trim)
    end
    for _, z in ipairs({898, 908, 918}) do
        put(25, 5, z, M.trim); put(25, 6, z, M.glass); put(25, 7, z, M.trim)
        put(77, 5, z, M.trim); put(77, 6, z, M.glass); put(77, 7, z, M.trim)
    end
    for layer = 0, 11 do
        fill(25 + layer, 13 + layer, 885, 77 - layer, 13 + layer, 929,
            (layer % 3 == 0) and M.tile_red or M.roof)
    end
    build_spire(51, 906, 4, 23)
    build_spire(30, 887, 3, 16)
    build_spire(72, 887, 3, 16)
end



local function build_city()
    A.flatten_rect(BOUNDS, base_y, 192)
    A.clear(BOUNDS.x1, base_y + 1, BOUNDS.z1, BOUNDS.x2, 192, BOUNDS.z2)

    -- Bassin ouest relié au canal principal, puis bras vers la plage.
    build_channel(-96, 827, -62, 862)
    build_channel(-66, 838, 65, 849)
    build_channel(58, 845, 72, 912)

    build_roads()
    build_bridges()
    build_docks()
    build_ships()
    build_houses()
    build_market()
    build_city_hall()
    build_cathedral()
    build_south_gate()
    build_greenery()
    build_lighting()

    -- Plage en escalier sur le coude du canal, comme dans la seconde vue NLite.
    for step = 0, 5 do
        fill(84 + step * 2, -step, 888 + step, 96, -step, 894 + step, "gdo_core:sable")
    end

    A.fix_light(BOUNDS)
    ready = true
    storage:set_int("city_version", VERSION)
    storage:set_int("city_base_y", base_y)
    storage:set_int("city_base_initialized", 1)
    minetest.log("action", "[GDO][CITY] Port elfique reconstruit sur terrain continental.")
end

local function spawn_position()
    return {x = wx(SPAWN.x), y = y(1), z = wz(SPAWN.z)}
end



local function finish_pending_spawns()
    for name in pairs(pending_spawns) do
        local player = minetest.get_player_by_name(name)
        if player then
            if ready then
                player:set_pos(spawn_position())
                if player.set_velocity then player:set_velocity({x = 0, y = 0, z = 0}) end
                minetest.chat_send_player(name, "Bienvenue au Port elfique ! Explore les quais, les navires, le canal et la cathédrale. /gdo_castle permet de rejoindre le Château des Brumes.")
            else
                local castle_y = gdo_castle_storage:get_int("architecture_castle_level")
                player:set_pos({x = 0, y = castle_y + 1, z = 68})
                minetest.chat_send_player(name, "Aucun site terrestre n'est encore validé pour le port elfique. Tu commences au Château des Brumes.")
            end
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
    player:set_pos(spawn_position())
    if player.set_velocity then player:set_velocity({x = 0, y = 0, z = 0}) end
    return true
end

local function register_city_zone()
    if gdo_zones and gdo_zones.register_readonly_zone then
        gdo_zones.register_readonly_zone({
            name = CITY_NAME,
            description = "Port elfique, maisons mitoyennes, bassin, canal, ponts, cathédrale et remparts",
            min = {x = BOUNDS.x1, y = -32, z = BOUNDS.z1},
            max = {x = BOUNDS.x2, y = 192, z = BOUNDS.z2},
        })
    end
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
    description = "Rejoindre le Port elfique",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then return false, "Joueur introuvable." end
        gdo_city.spawn(player)
        if not ready then return true, "La cité termine sa préparation ; tu y seras envoyé dès qu'elle sera prête." end
        return true, "Bienvenue au Port elfique."
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

local function make_bounds(x, z)
    return {x1 = x - RADIUS, x2 = x + RADIUS, z1 = z - RADIUS, z2 = z + RADIUS}
end

local function dry_surface(x, z)
    local surface = A.find_surface_y(x, z)
    if not surface then return nil end
    local above = minetest.get_node_or_nil({x = x, y = surface + 1, z = z})
    if not above or above.name == "ignore" then return nil end
    local def = minetest.registered_nodes[above.name]
    if def and def.liquidtype and def.liquidtype ~= "none" then return nil end
    return surface
end

local function inspect_site(x, z)
    local values, total = {}, 0
    for sx = x - RADIUS + 8, x + RADIUS - 8, 16 do
        for sz = z - RADIUS + 8, z + RADIUS - 8, 16 do
            total = total + 1
            local ground = dry_surface(sx, sz)
            if ground then values[#values + 1] = ground end
        end
    end
    if #values / total < 0.985 then return nil end
    table.sort(values)
    local low = values[math.max(1, math.floor(#values * 0.05))]
    local high = values[math.min(#values, math.ceil(#values * 0.95))]
    if high - low > 24 then return nil end
    return values[math.floor((#values + 1) / 2)]
end

local function coarse_site_ok(x, z)
    local values = {}
    for _, dx in ipairs({-80, 0, 80}) do
        for _, dz in ipairs({-80, 0, 80}) do
            local ground = dry_surface(x + dx, z + dz)
            if ground then values[#values + 1] = ground end
        end
    end
    if #values < 8 then return false end
    table.sort(values)
    return values[#values] - values[1] <= 32
end

local function emerge_box(bounds, callback)
    local failed = false
    minetest.emerge_area(
        {x = bounds.x1, y = SITE_Y_MIN, z = bounds.z1},
        {x = bounds.x2, y = SITE_Y_MAX, z = bounds.z2},
        function(_, action, remaining)
            if action == minetest.EMERGE_ERRORED or action == minetest.EMERGE_CANCELLED then failed = true end
            if remaining == 0 then callback(failed) end
        end
    )
end

local function cleanup_legacy(callback)
    if storage:get_int("city_legacy_migrated") == 1 then callback(true); return end
    if storage:get_int("city_version") < 1 then
        storage:set_int("city_legacy_migrated", 1)
        callback(true)
        return
    end
    emerge_box(LEGACY_BOUNDS, function(failed)
        if failed then callback(false); return end
        local old_y = storage:get_int("city_base_y")
        local levels = {}
        for _, point in ipairs({
            {-60, 780}, {-60, 850}, {-60, 920}, {0, 778},
            {0, 922}, {60, 780}, {60, 850}, {60, 920},
        }) do
            for sy = 192, -32, -1 do
                local node = minetest.get_node_or_nil({x = point[1], y = sy, z = point[2]})
                if node and node.name ~= "ignore" then
                    local def = minetest.registered_nodes[node.name]
                    if def and def.liquidtype and def.liquidtype ~= "none" then
                        levels[#levels + 1] = sy
                        break
                    end
                end
            end
        end
        table.sort(levels)
        local waterline = (#levels > 0) and levels[math.floor((#levels + 1) / 2)] or old_y
        local floor = math.min(old_y, waterline) - 4
        local low = math.min(old_y - 2, floor)
        local high = math.max(old_y + 34, waterline)
        for x = LEGACY_BOUNDS.x1, LEGACY_BOUNDS.x2 do
            for z = LEGACY_BOUNDS.z1, LEGACY_BOUNDS.z2 do
                A.clear(x, low, z, x, high, z)
                local dx, dz = x / 56, (z - 850) / 68
                local distance = dx * dx + dz * dz
                if distance <= 0.82 then
                    A.fill(x, floor, z, x, floor + 1, z, M.stone)
                    A.fill(x, floor + 2, z, x, waterline, z, water_node)
                elseif distance <= 1.05 then
                    A.fill(x, floor, z, x, waterline - 1, z, "gdo_core:sable")
                    A.put(x, waterline, z, "gdo_core:sable")
                else
                    A.put(x, waterline - 1, z, "gdo_core:terre")
                    A.put(x, waterline, z, M.grass)
                end
            end
        end
        storage:set_int("city_legacy_migrated", 1)
        A.fix_light(LEGACY_BOUNDS)
        minetest.log("action", "[GDO][CITY] Ancienne emprise v1 transformée en lagune au niveau de l'eau locale.")
        callback(true)
    end)
end

local function set_site(x, z, ground_y)
    center_x, center_z, base_y = x, z, ground_y
    BOUNDS = make_bounds(x, z)
    gdo_city.bounds = BOUNDS
    gdo_city.center = {x = x, y = ground_y, z = z}
    storage:set_int("city_x", x)
    storage:set_int("city_z", z)
    storage:set_int("city_y", ground_y)
    storage:set_int("city_site", 1)
    register_city_zone()
end

local function finish_pending()
    for name in pairs(pending_spawns) do
        local player = minetest.get_player_by_name(name)
        if player then
            if ready then
                player:set_pos(spawn_position())
            else
                local castle_y = gdo_castle_storage:get_int("architecture_castle_level")
                player:set_pos({x = 0, y = castle_y + 1, z = 68})
            end
            pending_spawns[name] = nil
        end
    end
end

local function candidate_search(index)
    if building or ready then return end
    if index > #SITE_CANDIDATES then
        minetest.log("error", "[GDO][CITY] Aucun site continental assez plat trouvé. Aucune ville ne sera construite dans l'eau.")
        finish_pending()
        minetest.after(60, function() if not ready then candidate_search(1) end end)
        return
    end
    local candidate = SITE_CANDIDATES[index]
    local bounds = make_bounds(candidate[1], candidate[2])
    if not (bounds.x2 < LEGACY_BOUNDS.x1 or bounds.x1 > LEGACY_BOUNDS.x2
        or bounds.z2 < LEGACY_BOUNDS.z1 or bounds.z1 > LEGACY_BOUNDS.z2) then
        candidate_search(index + 1)
        return
    end
    local samples = {}
    for _, dx in ipairs({-80, 0, 80}) do
        for _, dz in ipairs({-80, 0, 80}) do
            samples[#samples + 1] = {x = candidate[1] + dx, z = candidate[2] + dz}
        end
    end
    local remaining, failed = #samples, false
    for _, point in ipairs(samples) do
        minetest.emerge_area(
            {x = point.x, y = SITE_Y_MIN, z = point.z},
            {x = point.x, y = SITE_Y_MAX, z = point.z},
            function(_, action, left)
                if action == minetest.EMERGE_ERRORED or action == minetest.EMERGE_CANCELLED then failed = true end
                if left == 0 then
                    remaining = remaining - 1
                    if remaining == 0 then
                        if failed or not coarse_site_ok(candidate[1], candidate[2]) then
                            candidate_search(index + 1)
                            return
                        end
                        emerge_box(bounds, function(emerge_failed)
                            if emerge_failed then candidate_search(index + 1); return end
                            local ground_y = inspect_site(candidate[1], candidate[2])
                            if not ground_y then candidate_search(index + 1); return end
                            set_site(candidate[1], candidate[2], ground_y)
                            building = true
                            cleanup_legacy(function(ok)
                                if ok then build_city() end
                                building = false
                                finish_pending()
                            end)
                        end)
                    end
                end
            end
        )
    end
end

local function start_city()
    if building or ready then return end
    if not gdo_castle_storage or gdo_castle_storage:get_int("architecture_site_version") < 1 then
        minetest.after(3, start_city)
        return
    end
    if storage:get_int("city_site") == 1 then
        center_x = storage:get_int("city_x")
        center_z = storage:get_int("city_z")
        base_y = storage:get_int("city_y")
        BOUNDS = make_bounds(center_x, center_z)
        gdo_city.bounds = BOUNDS
        gdo_city.center = {x = center_x, y = base_y, z = center_z}
        register_city_zone()
        building = true
        emerge_box(BOUNDS, function(failed)
            if failed then building = false; minetest.after(10, start_city); return end
            if storage:get_int("city_version") < VERSION then
                cleanup_legacy(function(ok)
                    if ok then build_city() end
                    building = false
                    finish_pending()
                end)
            else
                ready = true
                building = false
                finish_pending()
            end
        end)
    else
        candidate_search(1)
    end
end



minetest.register_on_mods_loaded(function()
    minetest.after(4, start_city)
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
    description = "Affiche l'état du port elfique",
    func = function()
        return true, string.format("%s — version %d/%d — prêt=%s — centre X=%d Z=%d Y=%d",
            CITY_NAME, storage:get_int("city_version"), VERSION,
            ready and "oui" or "non", center_x, center_z, base_y or 0)
    end
})

minetest.register_chatcommand("gdo_city_rebuild", {
    description = "Reconstruit le Port elfique (zone réservée)",
    privs = {server = true},
    func = function()
        if building then return false, "La génération de la cité est déjà en cours." end
        storage:set_int("city_version", 0)
        ready = false
        pending_spawns = {}
        start_city()
        return true, "Reconstruction du Port elfique demandée. Seule son emprise sera remplacée."
    end,
})

minetest.log("action", "[GDO City] Le Port elfique est enregistré ; elle sera générée après le site du château.")
