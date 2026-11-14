-- Gros Débile Online — prototype jouable
-- Compatible avec l'API Lua de Luanti. Aucun mod externe requis.

local modname = minetest.get_current_modname()
local S = minetest.get_translator and minetest.get_translator(modname) or function(s) return s end

local C = {
    grass = "unknown_node.png^[colorize:#4d963d:220",
    dirt = "unknown_node.png^[colorize:#79553a:220",
    path = "unknown_node.png^[colorize:#b69a69:220",
    wood = "unknown_node.png^[colorize:#79502f:220",
    stone = "unknown_node.png^[colorize:#777777:220",
    navet = "unknown_node.png^[colorize:#d6b24c:220",
    npc = "unknown_node.png^[colorize:#d9a06b:220",
    water = "unknown_node.png^[colorize:#319bd1:180",
    sand = "unknown_node.png^[colorize:#d9c18b:220",
    gravel = "unknown_node.png^[colorize:#77736b:220",
    snow = "unknown_node.png^[colorize:#e8f1f7:240",
    tree = "unknown_node.png^[colorize:#684326:240",
    leaves = "unknown_node.png^[colorize:#3e783b:220",
}

minetest.register_node("gdo_core:herbe", {
    description = S("Herbe du Royaume"),
    tiles = {C.grass},
    groups = {crumbly = 3, soil = 1, oddly_breakable_by_hand = 3},
    sounds = {},
})

minetest.register_node("gdo_core:terre", {
    description = S("Terre du Royaume"),
    tiles = {C.dirt},
    groups = {crumbly = 3, soil = 1, oddly_breakable_by_hand = 3},
})

minetest.register_node("gdo_core:chemin", {
    description = S("Chemin poussiéreux"),
    tiles = {C.path},
    groups = {crumbly = 2, oddly_breakable_by_hand = 2},
})

minetest.register_node("gdo_core:bois", {
    description = S("Bois rustique"),
    tiles = {C.wood},
    groups = {choppy = 3, oddly_breakable_by_hand = 2},
})

minetest.register_node("gdo_core:pierre", {
    description = S("Pierre grise"),
    tiles = {C.stone},
    groups = {cracky = 3, oddly_breakable_by_hand = 3},
})

-- Blocs naturels utilisés par le mapgen v6.
-- Le jeu GDO est autonome : il déclare ses propres sols, arbres et liquides.
minetest.register_node("gdo_core:sable", {
    description = S("Sable naturel"),
    tiles = {C.sand},
    groups = {crumbly = 3, falling_node = 1, sand = 1},
})
minetest.register_node("gdo_core:gravier", {
    description = S("Gravier naturel"),
    tiles = {C.gravel},
    groups = {crumbly = 2, falling_node = 1},
})
minetest.register_node("gdo_core:neige", {
    description = S("Neige"),
    tiles = {C.snow},
    groups = {crumbly = 3, falling_node = 1},
})
minetest.register_node("gdo_core:glace", {
    description = S("Glace"),
    tiles = {C.water},
    groups = {cracky = 3},
})
minetest.register_node("gdo_core:arbre", {
    description = S("Tronc naturel"),
    tiles = {C.tree},
    groups = {tree = 1, choppy = 2, oddly_breakable_by_hand = 1},
})
minetest.register_node("gdo_core:feuilles", {
    description = S("Feuillage naturel"),
    drawtype = "allfaces_optional",
    tiles = {C.leaves},
    paramtype = "light",
    sunlight_propagates = true,
    groups = {snappy = 3, leaves = 1, flammable = 2},
})
minetest.register_node("gdo_core:pomme", {
    description = S("Pomme sauvage"),
    drawtype = "plantlike",
    tiles = {C.navet},
    inventory_image = C.navet,
    wield_image = C.navet,
    paramtype = "light",
    sunlight_propagates = true,
    walkable = false,
    groups = {snappy = 3, food = 1},
})
minetest.register_node("gdo_core:herbe_jungle", {
    description = S("Herbe de jungle"),
    drawtype = "plantlike",
    tiles = {C.leaves},
    paramtype = "light",
    sunlight_propagates = true,
    walkable = false,
    groups = {snappy = 3, flora = 1},
})

-- Eau de carte : sources et écoulement standard, sans dépendance externe.
minetest.register_node("gdo_core:eau_courante", {
    description = S("Eau courante"),
    drawtype = "flowingliquid",
    tiles = {C.water},
    special_tiles = {
        {name = C.water, backface_culling = false},
        {name = C.water, backface_culling = true},
    },
    paramtype = "light",
    paramtype2 = "flowingliquid",
    walkable = false,
    pointable = false,
    diggable = false,
    buildable_to = true,
    liquidtype = "flowing",
    liquid_alternative_flowing = "gdo_core:eau_courante",
    liquid_alternative_source = "gdo_core:eau",
    liquid_viscosity = 1,
    liquid_range = 8,
    groups = {water = 3, liquid = 3},
})
minetest.register_node("gdo_core:eau", {
    description = S("Eau"),
    drawtype = "liquid",
    tiles = {C.water},
    special_tiles = {
        {name = C.water, backface_culling = false},
        {name = C.water, backface_culling = true},
    },
    paramtype = "light",
    walkable = false,
    pointable = false,
    diggable = false,
    buildable_to = true,
    liquidtype = "source",
    liquid_alternative_flowing = "gdo_core:eau_courante",
    liquid_alternative_source = "gdo_core:eau",
    liquid_viscosity = 1,
    liquid_range = 8,
    groups = {water = 3, liquid = 3},
})

-- Aliases indispensables au mapgen v6.
minetest.register_alias("mapgen_stone", "gdo_core:pierre")
minetest.register_alias("mapgen_water_source", "gdo_core:eau")
minetest.register_alias("mapgen_river_water_source", "gdo_core:eau")
minetest.register_alias("mapgen_lava_source", "air")
minetest.register_alias("mapgen_dirt", "gdo_core:terre")
minetest.register_alias("mapgen_dirt_with_grass", "gdo_core:herbe")
minetest.register_alias("mapgen_sand", "gdo_core:sable")
minetest.register_alias("mapgen_gravel", "gdo_core:gravier")
minetest.register_alias("mapgen_desert_stone", "gdo_core:pierre")
minetest.register_alias("mapgen_desert_sand", "gdo_core:sable")
minetest.register_alias("mapgen_dirt_with_snow", "gdo_core:herbe")
minetest.register_alias("mapgen_snowblock", "gdo_core:neige")
minetest.register_alias("mapgen_snow", "gdo_core:neige")
minetest.register_alias("mapgen_ice", "gdo_core:glace")
minetest.register_alias("mapgen_tree", "gdo_core:arbre")
minetest.register_alias("mapgen_leaves", "gdo_core:feuilles")
minetest.register_alias("mapgen_apple", "gdo_core:pomme")
minetest.register_alias("mapgen_jungletree", "gdo_core:arbre")
minetest.register_alias("mapgen_jungleleaves", "gdo_core:feuilles")
minetest.register_alias("mapgen_junglegrass", "gdo_core:herbe_jungle")
minetest.register_alias("mapgen_pine_tree", "gdo_core:arbre")
minetest.register_alias("mapgen_pine_needles", "gdo_core:feuilles")
minetest.register_alias("mapgen_cobble", "gdo_core:pierre")
minetest.register_alias("mapgen_stair_cobble", "gdo_core:pierre")
minetest.register_alias("mapgen_mossycobble", "gdo_core:pierre")
minetest.register_alias("mapgen_stair_desert_stone", "gdo_core:pierre")

minetest.register_craftitem("gdo_core:navet", {
    description = S("Navet héroïque"),
    inventory_image = C.navet,
    stack_max = 99,
})

minetest.register_craftitem("gdo_core:badge_du_nawak", {
    description = S("Badge officiel du Nawak"),
    inventory_image = C.navet .. "^[brighten",
    stack_max = 1,
})

minetest.register_node("gdo_core:navet_sur_pied", {
    description = S("Navet héroïque (à récolter)"),
    drawtype = "plantlike",
    tiles = {C.navet},
    inventory_image = C.navet,
    wield_image = C.navet,
    paramtype = "light",
    sunlight_propagates = true,
    walkable = false,
    buildable_to = false,
    groups = {snappy = 3, oddly_breakable_by_hand = 3},
    selection_box = {
        type = "fixed",
        fixed = {-0.25, -0.5, -0.25, 0.25, 0.25, 0.25},
    },
    on_rightclick = function(pos, node, clicker)
        if not clicker or not clicker:is_player() then return end
        local meta = clicker:get_meta()
        if meta:get_int("gdo_quest_started") ~= 1 then
            minetest.chat_send_player(clicker:get_player_name(),
                "Ce navet a l'air important. Gérard devrait d'abord t'expliquer pourquoi.")
            return
        end
        local leftover = clicker:get_inventory():add_item("main", "gdo_core:navet")
        if not leftover:is_empty() then
            minetest.chat_send_player(clicker:get_player_name(),
                "Ton sac est plein. Fais un peu de place avant de récolter.")
            return
        end
        minetest.remove_node(pos)
        minetest.chat_send_player(clicker:get_player_name(),
            "Navet héroïque récolté ! Il ne manque plus que les autres.")
    end,
})

local function build_starting_area()
    -- Petite clairière plate, construite sans dépendre d'un autre jeu.
    for x = -12, 12 do
        for z = -12, 12 do
            minetest.set_node({x = x, y = -1, z = z}, {name = "gdo_core:terre"})
            minetest.set_node({x = x, y = 0, z = z}, {name = "gdo_core:herbe"})
            for y = 1, 5 do
                minetest.set_node({x = x, y = y, z = z}, {name = "air"})
            end
        end
    end

    -- Bordure en bois : on comprend vite où commence la zone de test.
    for n = -12, 12 do
        for _, p in ipairs({
            {x = n, y = 1, z = -12}, {x = n, y = 1, z = 12},
            {x = -12, y = 1, z = n}, {x = 12, y = 1, z = n},
        }) do
            minetest.set_node(p, {name = "gdo_core:bois"})
        end
    end

    -- Allée centrale et petite place.
    for x = -1, 1 do
        for z = -8, 5 do
            minetest.set_node({x = x, y = 1, z = z}, {name = "gdo_core:chemin"})
        end
    end
    for x = 2, 6 do
        for z = -2, 2 do
            minetest.set_node({x = x, y = 1, z = z}, {name = "gdo_core:chemin"})
        end
    end

    -- Jardin : trois navets, pas un de plus. La pénurie est une tradition locale.
    for _, p in ipairs({
        {x = -8, y = 1, z = 39},
        {x = -8, y = 1, z = 41},
        {x = -10, y = 1, z = 40},
    }) do
        minetest.set_node(p, {name = "gdo_core:navet_sur_pied"})
    end

    -- Quelques éléments de décor très rudimentaires.
    for x = 4, 6 do
        minetest.set_node({x = x, y = 1, z = 5}, {name = "gdo_core:bois"})
        minetest.set_node({x = x, y = 2, z = 5}, {name = "gdo_core:bois"})
    end
end

minetest.register_entity("gdo_core:gerard", {
    static_save = false,
    initial_properties = {
        physical = true,
        collide_with_objects = true,
        collisionbox = {-0.3, -0.5, -0.3, 0.3, 0.9, 0.3},
        visual = "cube",
        visual_size = {x = 0.7, y = 1.4},
        textures = {C.npc, C.npc, C.npc, C.npc, C.npc, C.npc},
        makes_footstep_sound = false,
        nametag = "Gérard le Magnifique",
        nametag_color = "#ffe08a",
    },

    on_activate = function(self)
        self.object:set_armor_groups({immortal = 1})
    end,

    on_step = function(self, dtime)
        -- Gérard est un PNJ de dialogue : il ne part pas à l'aventure.
    end,

    on_punch = function(self, puncher)
        if puncher and puncher:is_player() then
            minetest.chat_send_player(puncher:get_player_name(),
                "Gérard : Hé ! Je suis le donneur de quêtes, pas un sac de frappe.")
        end
    end,

    on_rightclick = function(self, clicker)
        if not clicker or not clicker:is_player() then return end
        local name = clicker:get_player_name()
        local meta = clicker:get_meta()
        local inventory = clicker:get_inventory()

        if meta:get_int("gdo_quest_done") == 1 then
            minetest.chat_send_player(name,
                "Gérard : Ah, mon héros préféré ! Enfin... mon seul héros. Merci encore !")
            return
        end

        if meta:get_int("gdo_quest_started") ~= 1 then
            meta:set_int("gdo_quest_started", 1)
            minetest.chat_send_player(name,
                "Gérard le Magnifique : Bienvenue, aventurier ! Le Royaume est en danger : nous manquons de navets. Récolte les 3 navets héroïques dans le jardin près de la grande porte, puis reviens me voir. Oui, c'est une quête officielle.")
            return
        end

        if inventory:contains_item("main", "gdo_core:navet 3") then
            inventory:remove_item("main", "gdo_core:navet 3")
            inventory:add_item("main", "gdo_core:badge_du_nawak")
            meta:set_int("gdo_quest_done", 1)
            if gdo_society and gdo_society.add_experience then
                gdo_society.add_experience(clicker, 100)
            end
            minetest.chat_send_player(name,
                "Gérard : Trois navets ! L'Histoire retiendra ton courage. Voici le Badge officiel du Nawak. Tu es désormais une légende locale.")
        else
            local count = inventory:get_stack("main", 1):get_count()
            local total = 0
            for _, stack in ipairs(inventory:get_list("main") or {}) do
                if stack:get_name() == "gdo_core:navet" then
                    total = total + stack:get_count()
                end
            end
            minetest.chat_send_player(name,
                "Gérard : Il me faut 3 navets héroïques. Tu en as " .. total .. ". Le destin du Royaume attendra bien cinq minutes.")
        end
    end,
})

local function ensure_gerard()
    local pos = {x = 3, y = 1, z = 35}
    local objects = minetest.get_objects_inside_radius(pos, 2)
    for _, object in ipairs(objects) do
        local entity = object:get_luaentity()
        if entity and entity.name == "gdo_core:gerard" then
            return
        end
    end
    minetest.add_entity(pos, "gdo_core:gerard")
end

-- Le château Dourdan construit désormais le plateau d'arrivée.
-- On ne génère plus de clairière ni de plateforme volante à altitude fixe ici.
minetest.register_on_mods_loaded(function()
    minetest.log("action", "[GDO] Les points d'arrivée et la cour sont gérés par gdo_castle.")
end)

minetest.register_on_joinplayer(function(player)
    if player.override_day_night_ratio then
        player:override_day_night_ratio(1)
    end

    local meta = player:get_meta()
    local first_spawn = meta:get_int("gdo_spawned") ~= 1
    minetest.after(2, function()
        if not player or not player:is_player() then return end
        meta:set_int("gdo_spawned", 1)
        if first_spawn then
            minetest.chat_send_player(player:get_player_name(),
                "Bienvenue dans le Royaume du Nawak ! Tu commences au Port elfique. Le Château des Brumes reste accessible par la pierre de passage ou /gdo_castle.")
        end
    end)
end)

minetest.register_chatcommand("gdo", {
    description = "Affiche les commandes et objectifs du prototype GDO",
    func = function(name)
        minetest.chat_send_player(name,
            "GDO — Parle à Gérard, récolte 3 navets héroïques puis retourne le voir. Choisis une maison avec un clic droit sur son blason dans la cour. /maisons présente les maisons, /maison affiche ton affectation.")
        return true
    end,
})

minetest.log("action", "[GDO] Le Royaume du Nawak est prêt à accueillir ses héros.")
