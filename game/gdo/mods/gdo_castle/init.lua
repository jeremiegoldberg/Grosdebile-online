-- GDO — Château des Brumes
-- Architecture originale de château-école gothique fantastique.
-- Génération unique par monde ; aucune dépendance externe.

local modname = minetest.get_current_modname()
local S = minetest.get_translator and minetest.get_translator(modname) or function(s) return s end

-- Toute l'emprise du Château des Brumes, de ses jardins et de la zone tutorielle
-- est réservée au scénario. Les constructions des joueurs commencent au-delà.
gdo_zones.register_readonly_zone({
    name = "Château des Brumes",
    description = "Château, cour, pavillons des maisons, jardin des navets et parcours d'initiation",
    min = {x = -52, y = -10, z = -58},
    max = {x = 52, y = 100, z = 85},
})

local nodes = {
    stone = "gdo_castle:castle_stone",
    dark = "gdo_castle:castle_dark_stone",
    roof = "gdo_castle:castle_roof",
    wood = "gdo_castle:castle_wood",
    glass = "gdo_castle:castle_glass",
    floor = "gdo_castle:castle_floor",
    gold = "gdo_castle:castle_gold",
    marble = "gdo_castle:castle_marble",
    copper = "gdo_castle:castle_copper",
}

local function register_block(name, description, texture, groups, paramtype)
    minetest.register_node(name, {
        description = S(description),
        tiles = {texture},
        groups = groups or {cracky = 2, oddly_breakable_by_hand = 2},
        paramtype = paramtype,
        sunlight_propagates = paramtype == "light",
    })
end

register_block(nodes.stone, "Pierre claire du château",
    "unknown_node.png^[colorize:#aaa99f:220", {cracky = 2})
register_block(nodes.dark, "Pierre sombre du château",
    "unknown_node.png^[colorize:#555b68:220", {cracky = 2})
register_block(nodes.roof, "Ardoise bleutée",
    "unknown_node.png^[colorize:#303d58:220", {cracky = 2})
register_block(nodes.wood, "Chêne ancien",
    "unknown_node.png^[colorize:#68442d:220", {choppy = 2})
register_block(nodes.glass, "Vitrail ambré",
    "unknown_node.png^[colorize:#e6b84d:220", {cracky = 2, oddly_breakable_by_hand = 2}, "light")
register_block(nodes.floor, "Dallage du château",
    "unknown_node.png^[colorize:#777b83:220", {cracky = 2})
register_block(nodes.gold, "Ornement doré",
    "unknown_node.png^[colorize:#d5a52d:220", {cracky = 2})
register_block(nodes.marble, "Marbre de cérémonie",
    "unknown_node.png^[colorize:#d9d0b8:220", {cracky = 2})
register_block(nodes.copper, "Cuivre patiné",
    "unknown_node.png^[colorize:#9b6846:220", {cracky = 2})
register_block("gdo_castle:castle_books", "Rayonnage de grimoires",
    "unknown_node.png^[colorize:#70452e:220", {choppy = 2})
register_block("gdo_castle:castle_banner", "Bannière du Nawak",
    "unknown_node.png^[colorize:#8c2638:220", {choppy = 2})
minetest.register_node("gdo_castle:castle_lantern", {
    description = S("Lanterne enchantée"),
    tiles = {"unknown_node.png^[colorize:#ffd36a:220"},
    groups = {cracky = 2},
    light_source = 12,
    paramtype = "light",
    sunlight_propagates = true,
})
minetest.register_node("gdo_castle:castle_noticeboard", {
    description = S("Panneau officiel du château"),
    tiles = {"unknown_node.png^[colorize:#8b623e:220"},
    groups = {choppy = 2},
    on_rightclick = function(pos, node, clicker)
        if clicker and clicker:is_player() then
            minetest.chat_send_player(clicker:get_player_name(),
                "DÉCRET ROYAL N° 404 : le dragon a été prié de patienter. Votre formulaire de quête est en cours de traitement. Délai estimé : 3 à 5 ères géologiques.")
        end
    end,
})

minetest.register_node("gdo_castle:arrival_sign", {
    description = S("Panneau d'accueil du Royaume"),
    tiles = {"unknown_node.png^[colorize:#b58a4a:220"},
    groups = {choppy = 2},
    on_rightclick = function(pos, node, clicker)
        if clicker and clicker:is_player() then
            minetest.chat_send_player(clicker:get_player_name(),
                "BIENVENUE AU ROYAUME DU NAWAK ! Le grand portail devant toi mène à la cour du Château des Brumes. Gérard le Magnifique t'attend près du jardin des navets. Clic droit sur Gérard pour commencer, puis choisis ta maison grâce aux blasons dans la cour. Commandes : /gdo, /maisons, /maison.")
        end
    end,
})

local function put(x, y, z, name)
    minetest.set_node({x = x, y = y, z = z}, {name = name})
end

local function cuboid(x1, y1, z1, x2, y2, z2, name)
    for x = math.min(x1, x2), math.max(x1, x2) do
        for y = math.min(y1, y2), math.max(y1, y2) do
            for z = math.min(z1, z2), math.max(z1, z2) do
                put(x, y, z, name)
            end
        end
    end
end

local function clear_box(x1, y1, z1, x2, y2, z2)
    cuboid(x1, y1, z1, x2, y2, z2, "air")
end

local function wall_x(x1, x2, y1, y2, z, name, thickness)
    cuboid(x1, y1, z, x2, y2, z + (thickness or 1) - 1, name)
end

local function wall_z(z1, z2, y1, y2, x, name, thickness)
    cuboid(x, y1, z1, x + (thickness or 1) - 1, y2, z2, name)
end

local function floor_rect(x1, z1, x2, z2, y, name)
    cuboid(x1, y, z1, x2, y, z2, name)
end

local function tower(cx, cz, radius, base_y, height, material, roof_material)
    -- Tour octogonale massive, avec contreforts, fenêtres et toit en pointe.
    for y = base_y, base_y + height do
        local r = radius
        for x = -r, r do
            for z = -r, r do
                local d = math.max(math.abs(x), math.abs(z))
                local corner = math.abs(x) == math.abs(z)
                if d == r or (corner and d >= r - 1) then
                    put(cx + x, y, cz + z, material)
                elseif y == base_y or y == base_y + height then
                    put(cx + x, y, cz + z, nodes.floor)
                end
            end
        end
    end

    -- Ouvertures verticales vitrées sur les quatre faces.
    for y = base_y + 4, base_y + height - 3, 6 do
        put(cx, y, cz - radius, nodes.glass)
        put(cx, y, cz + radius, nodes.glass)
        put(cx - radius, y, cz, nodes.glass)
        put(cx + radius, y, cz, nodes.glass)
    end

    -- Couronne crénelée.
    for x = -radius, radius do
        for z = -radius, radius do
            if math.max(math.abs(x), math.abs(z)) == radius and (x + z) % 2 == 0 then
                put(cx + x, base_y + height + 1, cz + z, nodes.dark)
            end
        end
    end

    -- Toit pyramidal à étages, culminant en une flèche.
    local roof_base = base_y + height + 2
    for layer = 0, radius + 1 do
        local r = math.max(0, radius - layer)
        if r == 0 then
            put(cx, roof_base + layer, cz, nodes.gold)
        else
            for x = -r, r do
                for z = -r, r do
                    if math.max(math.abs(x), math.abs(z)) == r then
                        put(cx + x, roof_base + layer, cz + z, roof_material)
                    end
                end
            end
        end
    end
    put(cx, roof_base + radius + 2, cz, nodes.gold)
end

local function build_keep()
    -- Donjon central, haut et asymétrique, avec grande salle et ailes.
    floor_rect(-18, -43, 18, -8, 1, nodes.floor)
    cuboid(-18, 2, -43, 18, 24, -8, nodes.stone)
    clear_box(-16, 3, -41, 16, 22, -10)

    -- Façade sud : porche monumental.
    clear_box(-4, 2, -9, 4, 11, -8)
    wall_x(-6, 6, 11, 12, -8, nodes.dark, 2)
    for x = -6, 6 do
        if math.abs(x) >= 5 then put(x, 4, -8, nodes.gold) end
    end

    -- Étages, planchers et couloirs.
    floor_rect(-16, -41, 16, -10, 8, nodes.floor)
    floor_rect(-16, -41, 16, -10, 16, nodes.floor)
    wall_x(-17, 17, 8, 9, -26, nodes.dark, 1)
    wall_x(-17, 17, 16, 17, -26, nodes.dark, 1)

    -- Fenêtres de façade.
    for x = -13, 13, 4 do
        put(x, 7, -8, nodes.glass)
        put(x, 14, -8, nodes.glass)
        put(x, 20, -8, nodes.glass)
    end
    for z = -39, -12, 4 do
        put(-18, 7, z, nodes.glass)
        put(18, 7, z, nodes.glass)
        put(-18, 14, z, nodes.glass)
        put(18, 14, z, nodes.glass)
    end

    -- Toiture centrale en ardoise, étagée pour former un grand toit pentu.
    for layer = 0, 8 do
        local inset = layer * 2
        for x = -18 + inset, 18 - inset do
            for z = -43 + inset, -8 - inset do
                put(x, 25 + layer, z, nodes.roof)
            end
        end
    end

    -- Quatre tours du donjon.
    tower(-18, -43, 5, 1, 31, nodes.dark, nodes.roof)
    tower(18, -43, 5, 1, 37, nodes.dark, nodes.roof)
    tower(-18, -8, 5, 1, 27, nodes.dark, nodes.roof)
    tower(18, -8, 5, 1, 33, nodes.dark, nodes.roof)

    -- Aile de la grande salle.
    cuboid(-34, 2, -37, -20, 14, -9, nodes.stone)
    clear_box(-32, 3, -35, -22, 12, -11)
    floor_rect(-32, -35, -22, -11, 7, nodes.floor)
    tower(-27, -37, 4, 1, 22, nodes.dark, nodes.roof)
    tower(-27, -9, 4, 1, 19, nodes.dark, nodes.roof)

    -- Aile de la bibliothèque et observatoire.
    cuboid(20, 2, -37, 34, 18, -9, nodes.stone)
    clear_box(22, 3, -35, 32, 16, -11)
    floor_rect(22, -35, 32, -11, 8, nodes.floor)
    tower(27, -37, 4, 1, 26, nodes.dark, nodes.roof)
    tower(27, -9, 4, 1, 23, nodes.dark, nodes.roof)
    tower(0, -26, 4, 26, 18, nodes.dark, nodes.roof)

    -- Pignons et ornements de façade.
    for y = 2, 15 do
        local width = math.max(1, 10 - math.floor(y * 0.6))
        wall_x(-width, width, y, y, -44, nodes.dark, 1)
    end
    for x = -3, 3 do
        put(x, 18, -44, nodes.gold)
    end
end


local function build_great_hall()
    -- Grande salle de banquet : longues tables, bancs, estrade et lustres.
    floor_rect(-32, -35, -22, -11, 2, nodes.marble)
    for z = -32, -14, 6 do
        cuboid(-31, 3, z, -23, 3, z + 1, nodes.wood)
        cuboid(-31, 2, z - 1, -23, 2, z - 1, nodes.wood)
        cuboid(-31, 2, z + 2, -23, 2, z + 2, nodes.wood)
        for x = -30, -24, 2 do
            put(x, 4, z, nodes.gold)
        end
    end
    -- Estrade du maître de cérémonie.
    cuboid(-31, 3, -34, -23, 4, -32, nodes.dark)
    cuboid(-30, 5, -34, -24, 5, -33, nodes.wood)
    -- Poutres et lustres lumineux.
    for x = -31, -23, 4 do
        cuboid(x, 12, -33, x, 12, -13, nodes.wood)
    end
    for z = -30, -14, 8 do
        cuboid(-29, 11, z, -25, 11, z, nodes.copper)
        for x = -29, -25, 2 do
            put(x, 10, z, "gdo_castle:castle_lantern")
        end
    end
    -- Vitraux et bannières de la maison du Nawak.
    for z = -30, -14, 8 do
        put(-34, 7, z, nodes.glass)
        put(-34, 8, z, "gdo_castle:castle_banner")
    end
end

local function build_library()
    -- Bibliothèque à deux niveaux, rayonnages hauts et passerelles.
    floor_rect(22, -35, 32, -11, 2, nodes.marble)
    for z = -34, -13, 3 do
        cuboid(22, 3, z, 22, 7, z + 1, "gdo_castle:castle_books")
        cuboid(32, 3, z, 32, 7, z + 1, "gdo_castle:castle_books")
    end
    for x = 24, 30, 3 do
        cuboid(x, 3, -34, x + 1, 7, -34, "gdo_castle:castle_books")
        cuboid(x, 3, -12, x + 1, 7, -12, "gdo_castle:castle_books")
    end
    floor_rect(23, -33, 31, -13, 9, nodes.wood)
    -- Tables de consultation au rez-de-chaussée.
    for z = -29, -17, 6 do
        cuboid(25, 3, z, 29, 3, z + 1, nodes.wood)
        put(24, 2, z, nodes.wood)
        put(30, 2, z, nodes.wood)
    end
    -- Échelle monumentale et lanternes.
    for y = 3, 8 do
        put(30 - (y - 3), y, -23, nodes.wood)
    end
    put(27, 10, -23, "gdo_castle:castle_lantern")
    put(27, 10, -18, "gdo_castle:castle_lantern")
    put(27, 10, -28, "gdo_castle:castle_lantern")
end

local function build_keep_interior()
    -- Escalier monumental en lacets reliant les trois niveaux du donjon.
    for step = 0, 7 do
        floor_rect(-12 + step, -37 + step, -9 + step, -35 + step, 3 + step, nodes.marble)
        put(-13 + step, 3 + step, -36 + step, nodes.gold)
    end
    for step = 0, 7 do
        floor_rect(9 - step, -19 - step, 12 - step, -17 - step, 11 + step, nodes.marble)
        put(13 - step, 11 + step, -18 - step, nodes.gold)
    end
    -- Salle du conseil au niveau supérieur.
    floor_rect(-12, -24, 12, -12, 17, nodes.marble)
    cuboid(-5, 18, -22, 5, 18, -14, nodes.wood)
    for x = -4, 4, 2 do put(x, 19, -18, nodes.gold) end
    for x = -10, 10, 4 do
        put(x, 18, -12, "gdo_castle:castle_lantern")
    end
    -- Bannières monumentales dans le hall central.
    for y = 4, 7 do
        put(-15, y, -25, "gdo_castle:castle_banner")
        put(15, y, -25, "gdo_castle:castle_banner")
    end
    -- Portes intérieures stylisées et éclairage des paliers.
    put(-8, 4, -10, "gdo_castle:castle_lantern")
    put(8, 4, -10, "gdo_castle:castle_lantern")
    put(-8, 12, -10, "gdo_castle:castle_lantern")
    put(8, 12, -10, "gdo_castle:castle_lantern")
end

local function build_training_room()
    -- Petite salle de cours dans l'aile nord du donjon : pupitres et estrade.
    floor_rect(-14, -40, 14, -28, 9, nodes.marble)
    cuboid(-3, 10, -39, 3, 10, -38, nodes.dark)
    for z = -36, -30, 3 do
        for x = -10, 10, 5 do
            cuboid(x, 10, z, x + 2, 10, z + 1, nodes.wood)
            put(x, 9, z, nodes.wood)
            put(x + 2, 9, z, nodes.wood)
        end
    end
    put(0, 12, -39, "gdo_castle:castle_lantern")
    put(-12, 12, -34, "gdo_castle:castle_banner")
    put(12, 12, -34, "gdo_castle:castle_banner")
end


local function build_great_hall()
    -- Salle de banquet : la table est longue, le budget nourriture beaucoup moins.
    floor_rect(-32, -35, -22, -11, 2, nodes.marble)
    for z = -32, -14, 6 do
        cuboid(-31, 3, z, -23, 3, z + 1, nodes.wood)
        cuboid(-31, 2, z - 1, -23, 2, z - 1, nodes.wood)
        cuboid(-31, 2, z + 2, -23, 2, z + 2, nodes.wood)
        for x = -30, -24, 2 do put(x, 4, z, nodes.gold) end
    end
    cuboid(-31, 3, -34, -23, 4, -32, nodes.dark)
    cuboid(-30, 5, -34, -24, 5, -33, nodes.wood)
    for x = -31, -23, 4 do cuboid(x, 12, -33, x, 12, -13, nodes.wood) end
    for z = -30, -14, 8 do
        cuboid(-29, 11, z, -25, 11, z, nodes.copper)
        for x = -29, -25, 2 do put(x, 10, z, "gdo_castle:castle_lantern") end
    end
    for z = -30, -14, 8 do
        put(-34, 7, z, nodes.glass)
        put(-34, 8, z, "gdo_castle:castle_banner")
    end
    put(-27, 3, -12, "gdo_castle:castle_noticeboard")
end

local function build_library()
    -- Bibliothèque à deux niveaux : les livres sont classés par ordre alphabétique,
    -- sauf ceux dont le titre commence par « probablement maudit ».
    floor_rect(22, -35, 32, -11, 2, nodes.marble)
    for z = -34, -13, 3 do
        cuboid(22, 3, z, 22, 7, z + 1, "gdo_castle:castle_books")
        cuboid(32, 3, z, 32, 7, z + 1, "gdo_castle:castle_books")
    end
    for x = 24, 30, 3 do
        cuboid(x, 3, -34, x + 1, 7, -34, "gdo_castle:castle_books")
        cuboid(x, 3, -12, x + 1, 7, -12, "gdo_castle:castle_books")
    end
    floor_rect(23, -33, 31, -13, 9, nodes.wood)
    for z = -29, -17, 6 do
        cuboid(25, 3, z, 29, 3, z + 1, nodes.wood)
        put(24, 2, z, nodes.wood)
        put(30, 2, z, nodes.wood)
    end
    for y = 3, 8 do put(30 - (y - 3), y, -23, nodes.wood) end
    put(27, 10, -23, "gdo_castle:castle_lantern")
    put(27, 10, -18, "gdo_castle:castle_lantern")
    put(27, 10, -28, "gdo_castle:castle_lantern")
    put(27, 3, -12, "gdo_castle:castle_noticeboard")
end

local function build_school_of_nawak()
    -- Salle de cours : l'ardoise magique n'a pas encore reçu son permis d'enseignement.
    floor_rect(-14, -40, 14, -28, 9, nodes.marble)
    cuboid(-3, 10, -39, 3, 10, -38, nodes.dark)
    for z = -36, -30, 3 do
        for x = -10, 10, 5 do
            cuboid(x, 10, z, x + 2, 10, z + 1, nodes.wood)
            put(x, 9, z, nodes.wood)
            put(x + 2, 9, z, nodes.wood)
        end
    end
    put(0, 12, -39, "gdo_castle:castle_lantern")
    put(-12, 12, -34, "gdo_castle:castle_banner")
    put(12, 12, -34, "gdo_castle:castle_banner")
    put(0, 10, -29, "gdo_castle:castle_noticeboard")
end

local function build_bureau_des_quetes()
    -- Guichet officiel : une aventure commence toujours par trois exemplaires.
    floor_rect(-8, -6, 8, 5, 2, nodes.marble)
    cuboid(-6, 3, -4, 6, 4, -3, nodes.wood)
    for x = -5, 5, 2 do
        put(x, 5, -3, nodes.gold)
        put(x, 3, 1, nodes.wood)
    end
    put(0, 5, -5, "gdo_castle:castle_lantern")
    put(0, 3, 4, "gdo_castle:castle_noticeboard")
    put(-7, 3, 0, "gdo_castle:castle_banner")
    put(7, 3, 0, "gdo_castle:castle_banner")
end

local function build_trophy_gallery()
    -- Galerie des exploits : le premier trophée est volontairement un navet.
    for x = -16, 16 do
        put(x, 2, 20, nodes.marble)
        put(x, 6, 20, nodes.wood)
    end
    for x = -12, 12, 6 do
        cuboid(x - 1, 3, 19, x + 1, 4, 19, nodes.gold)
        put(x, 5, 19, "gdo_castle:castle_lantern")
    end
    put(0, 3, 18, "gdo_castle:castle_noticeboard")
end


-- Les quatre maisons : chaque blason est un point d'inscription interactif.
local houses = {
    {
        id = "bras_casses", title = "Les Bras Cassés",
        motto = "Le courage avant la compétence.",
        color = "#b84a35", emblem = "unknown_node.png^[colorize:#b84a35:220",
        center = {x = -24, z = -1},
        lore = "On fonce d'abord. On lit le panneau après. Parfois.",
    },
    {
        id = "mages_dimanche", title = "Les Mages du Dimanche",
        motto = "La magie, c'est 10 % de talent et 90 % d'excuses.",
        color = "#536eb5", emblem = "unknown_node.png^[colorize:#536eb5:220",
        center = {x = 24, z = -1},
        lore = "Leurs sorts fonctionnent. Les effets secondaires sont une fonctionnalité.",
    },
    {
        id = "rats_bibliotheque", title = "Les Rats de Bibliothèque",
        motto = "Savoir, c'est pouvoir. Sortir, c'est facultatif.",
        color = "#4d986a", emblem = "unknown_node.png^[colorize:#4d986a:220",
        center = {x = -24, z = 13},
        lore = "Ils connaissent tous les secrets du Royaume, sauf le chemin de la sortie.",
    },
    {
        id = "seigneurs_navet", title = "Les Seigneurs du Navet",
        motto = "Une racine noble, un destin grandiose.",
        color = "#c49b39", emblem = "unknown_node.png^[colorize:#c49b39:220",
        center = {x = 24, z = 13},
        lore = "Une aristocratie agricole qui prend ses récoltes très au sérieux.",
    },
}

for _, definition in ipairs(houses) do
    local house = definition
    minetest.register_node("gdo_castle:house_wall_" .. house.id, {
        description = "Pierre aux couleurs — " .. house.title,
        tiles = {house.emblem},
        groups = {cracky = 2},
    })
    minetest.register_node("gdo_castle:house_crest_" .. house.id, {
        description = "Blason — " .. house.title,
        tiles = {house.emblem},
        groups = {cracky = 2, oddly_breakable_by_hand = 2},
        on_rightclick = function(pos, node, clicker)
            if not clicker or not clicker:is_player() then return end
            local meta = clicker:get_meta()
            local current = meta:get_string("gdo_house")
            if current == house.id then
                minetest.chat_send_player(clicker:get_player_name(),
                    house.title .. " : " .. house.motto .. " " .. house.lore)
                return
            end
            if current ~= "" then
                minetest.chat_send_player(clicker:get_player_name(),
                    "Tu appartiens déjà à une maison. Le changement de maison nécessite l'autorisation du proviseur (qui est actuellement en réunion).")
                return
            end
            meta:set_string("gdo_house", house.id)
            meta:set_string("gdo_house_title", house.title)
            if gdo_society and gdo_society.join_founder_guild then
                gdo_society.join_founder_guild(clicker, house.id)
            end
            minetest.chat_send_all(clicker:get_player_name() .. " rejoint " .. house.title .. " ! " .. house.motto)
        end,
    })
end

local function build_house_common_room(house)
    local cx, cz = house.center.x, house.center.z
    local x1, x2, z1, z2 = cx - 4, cx + 4, cz - 4, cz + 4
    -- Pavillon compact : façade tournée vers le centre de la cour.
    floor_rect(x1, z1, x2, z2, 1, nodes.marble)
    cuboid(x1, 2, z1, x2, 6, z1, "gdo_castle:house_wall_" .. house.id)
    cuboid(x1, 2, z2, x2, 6, z2, "gdo_castle:house_wall_" .. house.id)
    cuboid(x1, 2, z1 + 1, x1, 6, z2 - 1, "gdo_castle:house_wall_" .. house.id)
    cuboid(x2, 2, z1 + 1, x2, 6, z2 - 1, "gdo_castle:house_wall_" .. house.id)
    -- Porte ouverte sur la cour, côté sud pour les pavillons nord et inversement.
    local front_z = cz < 5 and z2 or z1
    clear_box(cx - 1, 2, front_z, cx + 1, 4, front_z)
    -- Toit à deux niveaux, avec blason au sommet.
    cuboid(x1 - 1, 7, z1 - 1, x2 + 1, 7, z2 + 1, nodes.roof)
    cuboid(x1 + 1, 8, z1 + 1, x2 - 1, 8, z2 - 1, nodes.dark)
    -- Blason visible depuis la cour.
    put(cx, 5, front_z, "gdo_castle:house_crest_" .. house.id)
    -- Cheminée et foyer symbolique.
    cuboid(x1 + 1, 2, z1 + 1, x1 + 2, 4, z1 + 2, nodes.wood)
    put(x1 + 1, 5, z1 + 1, "gdo_castle:castle_lantern")
    -- Tables, bancs et tapis aux couleurs de la maison.
    cuboid(cx - 2, 2, cz - 1, cx + 2, 2, cz + 1, nodes.wood)
    cuboid(cx - 3, 2, cz - 2, cx - 3, 2, cz + 2, nodes.wood)
    cuboid(cx + 3, 2, cz - 2, cx + 3, 2, cz + 2, nodes.wood)
    for dx = -2, 2 do
        put(cx + dx, 3, z1, "gdo_castle:house_crest_" .. house.id)
    end
    put(cx, 3, cz, "gdo_castle:castle_lantern")
end

local function build_four_houses()
    for _, house in ipairs(houses) do
        build_house_common_room(house)
    end
end

local function build_outer_walls()
    -- Grande enceinte rectangulaire, avec chemin de ronde et créneaux.
    wall_x(-40, 40, 1, 12, -50, nodes.dark, 2)
    wall_x(-40, 40, 1, 12, 27, nodes.dark, 2)
    wall_z(-50, 27, 1, 12, -40, nodes.dark, 2)
    wall_z(-28, 27, 1, 12, 39, nodes.dark, 2)

    -- Deux sorties latérales au niveau du parvis : le joueur ne doit pas
    -- apparaître dans une enceinte qui ressemble à une fosse sans issue.
    clear_box(-41, 1, 38, -38, 14, 44)
    clear_box(38, 1, 38, 41, 14, 44)

    -- Remparts et merlons.
    for x = -40, 40, 2 do
        cuboid(x, 13, -50, x, 14, -49, nodes.stone)
        cuboid(x, 13, 27, x, 14, 28, nodes.stone)
    end
    for z = -50, 27, 2 do
        cuboid(-40, 13, z, -39, 14, z, nodes.stone)
        cuboid(39, 13, z, 40, 14, z, nodes.stone)
    end

    -- Porte monumentale au sud, passage ouvert au milieu.
    clear_box(-5, 1, 26, 5, 9, 29)
    cuboid(-12, 1, 25, -6, 18, 30, nodes.stone)
    cuboid(6, 1, 25, 12, 18, 30, nodes.stone)
    cuboid(-12, 18, 25, 12, 20, 30, nodes.dark)
    clear_box(-4, 1, 25, 4, 8, 30)
    for x = -5, 5 do
        put(x, 9, 25, nodes.gold)
        put(x, 9, 30, nodes.gold)
    end

    -- Tours d'angle et tours de la porte.
    tower(-40, -50, 6, 1, 20, nodes.dark, nodes.roof)
    tower(40, -50, 6, 1, 20, nodes.dark, nodes.roof)
    tower(-40, 27, 6, 1, 20, nodes.dark, nodes.roof)
    tower(40, 27, 6, 1, 20, nodes.dark, nodes.roof)
    tower(-10, 27, 4, 1, 22, nodes.dark, nodes.roof)
    tower(10, 27, 4, 1, 22, nodes.dark, nodes.roof)
end

local function build_courtyard()
    floor_rect(-38, -26, 38, 25, 0, nodes.floor)
    -- Motif central en étoile stylisée.
    for n = -8, 8 do
        put(n, 1, 0, nodes.gold)
        put(0, 1, n, nodes.gold)
    end
    for x = -5, 5 do
        for z = -5, 5 do
            if math.abs(x) == math.abs(z) then
                put(x, 1, z, nodes.gold)
            end
        end
    end

    -- Deux bassins décoratifs.
    for _, cx in ipairs({-27, 27}) do
        floor_rect(cx - 4, -2, cx + 4, 2, 0, nodes.dark)
        floor_rect(cx - 3, -1, cx + 3, 1, 1, nodes.glass)
        tower(cx, 0, 1, 1, 2, nodes.stone, nodes.gold)
    end

    -- Allée d'accès et pont franchissant le fossé symbolique.
    floor_rect(-3, 28, 3, 48, 0, nodes.floor)
    for z = 29, 46 do
        put(-4, 1, z, nodes.dark)
        put(4, 1, z, nodes.dark)
        if z % 3 == 0 then
            put(-4, 2, z, nodes.gold)
            put(4, 2, z, nodes.gold)
        end
    end
end

local function build_ground()
    -- Plateau de construction en blocs du jeu, sans dépendance à un autre game.
    for x = -52, 52 do
        for z = -58, 85 do
            put(x, -1, z, "gdo_core:terre")
            put(x, 0, z, "gdo_core:herbe")
        end
    end
end

local function build_arrival_area()
    -- Parvis extérieur : une place ouverte, au niveau du terrain, avant le pont.
    floor_rect(-12, 55, 12, 73, 0, nodes.marble)
    floor_rect(-3, 29, 3, 56, 0, nodes.floor)
    floor_rect(-5, 49, 5, 56, 0, nodes.gold)

    -- Bordures basses et motifs de dallage pour rendre l'entrée lisible.
    for z = 57, 71, 2 do
        put(-11, 0, z, nodes.dark)
        put(11, 0, z, nodes.dark)
    end
    for x = -8, 8, 4 do
        for z = 58, 70, 4 do
            put(x, 1, z, nodes.gold)
        end
    end

    -- Deux lanternes monumentales marquent la place sans enfermer le joueur.
    for _, x in ipairs({-9, 9}) do
        cuboid(x - 1, 1, 60, x + 1, 4, 62, nodes.dark)
        put(x, 5, 61, "gdo_castle:castle_lantern")
        put(x, 6, 61, nodes.gold)
    end
    put(0, 1, 71, "gdo_castle:arrival_sign")
end

local function generate_castle()
    build_ground()
    build_arrival_area()
    -- Les volumes intérieurs sont évidés pièce par pièce : pas de grand nettoyage
    -- massif de plusieurs centaines de milliers de blocs au démarrage.
    build_outer_walls()
    build_keep()
    build_great_hall()
    build_library()
    build_school_of_nawak()
    build_bureau_des_quetes()
    build_trophy_gallery()
    build_courtyard()
    build_four_houses()
    -- Le jardin de la quête est recréé après la construction du terrain.
    put(-8, 1, 39, "gdo_core:navet_sur_pied")
    put(-8, 1, 41, "gdo_core:navet_sur_pied")
    put(-10, 1, 40, "gdo_core:navet_sur_pied")

    -- Deux longues galeries latérales à arcades, éclairées régulièrement.
    for _, side in ipairs({-1, 1}) do
        local x1, x2 = side == -1 and -35 or 30, side == -1 and -30 or 35
        cuboid(x1, 2, -5, x2, 8, 20, nodes.stone)
        clear_box(x1 + 1, 3, -4, x2 - 1, 7, 19)
        for z = -3, 18, 5 do
            cuboid(x1, 3, z, x2, 7, z, nodes.dark)
        end
        floor_rect(x1, -5, x2, 20, 1, nodes.floor)
        local lamp_x = side == -1 and -32 or 32
        for z = 0, 15, 5 do
            put(lamp_x, 6, z, "gdo_castle:castle_lantern")
        end
    end

    -- Forcer un recalcul de lumière sur le château et le point d'arrivée.
    if minetest.fix_light then
        minetest.fix_light(
            {x = -52, y = -10, z = -58},
            {x = 52, y = 100, z = 52}
        )
        minetest.fix_light(
            {x = -16, y = -4, z = 24},
            {x = 16, y = 12, z = 56}
        )
    end
    -- Le prototype démarre en plein jour pour rendre le parcours immédiatement lisible.
    if minetest.set_timeofday then
        minetest.set_timeofday(0.5)
    end

    minetest.log("action", "[GDO] Le Château des Brumes a été construit.")
end

-- La génération du château est désormais entièrement gérée par refit.lua.
-- Un seul stockage de mod est initialisé, dans ce fichier de refonte.

minetest.register_chatcommand("maison", {
    description = "Affiche ta maison ou explique comment en rejoindre une",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then return false, "Joueur introuvable." end
        local id = player:get_meta():get_string("gdo_house")
        if id == "" then
            minetest.chat_send_player(name,
                "Tu n'as pas encore de maison ! Dans la cour, visite les quatre pavillons et fais un clic droit sur le blason de celui qui te ressemble. Attention : le choix est définitif pour cette version.")
            return true
        end
        for _, house in ipairs(houses) do
            if house.id == id then
                minetest.chat_send_player(name,
                    "Ta maison : " .. house.title .. " — " .. house.motto .. " " .. house.lore)
                return true
            end
        end
        return true
    end,
})

minetest.register_chatcommand("maisons", {
    description = "Présente les quatre maisons du Château des Brumes",
    func = function(name)
        for _, house in ipairs(houses) do
            minetest.chat_send_player(name,
                house.title .. " — " .. house.motto .. " " .. house.lore)
        end
        minetest.chat_send_player(name,
            "Pour rejoindre une maison, clique droit sur son blason dans son pavillon. /maison affiche ton affectation.")
        return true
    end,
})

minetest.register_chatcommand("chateau", {
    description = "Affiche les informations sur le Château des Brumes",
    func = function(name)
        minetest.chat_send_player(name,
            "Le Château des Brumes : une forteresse-école aux tours innombrables, au grand donjon, à la bibliothèque et à la cour des novices.")
        return true
    end,
})

minetest.log("action", "[GDO] Le module du Château des Brumes est chargé.")

-- Refonte visuelle et remise à niveau du terrain de départ.
dofile(minetest.get_modpath(modname) .. "/refit.lua")
