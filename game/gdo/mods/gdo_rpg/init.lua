-- GDO RPG : progression, races, classes, ressources et capacités.
-- Les données des personnages sont conservées dans les métadonnées du joueur.
local modpath = minetest.get_modpath(minetest.get_current_modname())
local races = dofile(modpath .. "/races.lua")
local classes = dofile(modpath .. "/classes.lua")

gdo_rpg = {
    races = races,
    classes = classes,
    max_level = 60,
}

local function clamp(value, low, high)
    return math.max(low, math.min(high, value))
end

local function get_meta(player)
    return player and player:is_player() and player:get_meta() or nil
end

function gdo_rpg.xp_to_next_level(level)
    return math.max(1, level) * 100
end

function gdo_rpg.get_level(player)
    local meta = get_meta(player)
    return meta and math.max(1, meta:get_int("gdo_level")) or 1
end

function gdo_rpg.get_character(player)
    local meta = get_meta(player)
    if not meta then return nil end
    return {
        race = meta:get_string("gdo_race"),
        class = meta:get_string("gdo_class"),
        level = math.max(1, meta:get_int("gdo_level")),
        xp = math.max(0, meta:get_int("gdo_xp")),
        mana = meta:get_int("gdo_mana"),
        stamina = meta:get_int("gdo_stamina"),
    }
end

function gdo_rpg.get_stats(player)
    local meta = get_meta(player)
    if not meta then return nil end
    local race = races[meta:get_string("gdo_race")] or races.elf
    local class = classes[meta:get_string("gdo_class")] or classes.ranger
    local level = math.max(1, meta:get_int("gdo_level"))
    local stats = {
        hp_max = clamp(20 + race.hp + class.hp + math.floor((level - 1) * 0.5), 10, 120),
        speed = clamp(race.speed * class.speed, 0.55, 1.6),
        jump = clamp(race.jump * class.jump, 0.65, 1.6),
        mana_max = clamp(40 + race.mana + class.mana + math.floor((level - 1) * 1.5), 20, 250),
        stamina_max = clamp(80 + race.stamina + class.stamina + math.floor((level - 1) * 1.2), 40, 220),
        damage = race.damage + class.damage + math.floor((level - 1) / 10),
        defense = clamp(class.defense, 0, 0.5),
        race = race,
        class = class,
    }
    return stats
end

function gdo_rpg.apply_player(player)
    local meta = get_meta(player)
    if not meta then return end
    local stats = gdo_rpg.get_stats(player)
    local old_hp = player:get_hp()
    local breath_max = stats.race == races.merling and 20 or 10
    player:set_properties({hp_max = stats.hp_max, breath_max = breath_max})
    player:set_hp(math.min(old_hp, stats.hp_max))
    player:set_breath(breath_max)
    player:set_physics_override({speed = stats.speed, jump = stats.jump})
    local mana = meta:get_int("gdo_mana")
    local stamina = meta:get_int("gdo_stamina")
    if meta:get_string("gdo_resources_initialized") ~= "1" then
        mana = stats.mana_max
        stamina = stats.stamina_max
        meta:set_string("gdo_resources_initialized", "1")
    end
    meta:set_int("gdo_mana", clamp(mana, 0, stats.mana_max))
    meta:set_int("gdo_stamina", clamp(stamina, 0, stats.stamina_max))
end

function gdo_rpg.add_experience(player, amount, reason)
    local meta = get_meta(player)
    if not meta or type(amount) ~= "number" or amount <= 0 then return false end
    local level = math.max(1, meta:get_int("gdo_level"))
    local xp = math.max(0, meta:get_int("gdo_xp")) + math.floor(amount)
    local gained = 0
    while level < gdo_rpg.max_level and xp >= gdo_rpg.xp_to_next_level(level) do
        xp = xp - gdo_rpg.xp_to_next_level(level)
        level = level + 1
        gained = gained + 1
    end
    if level >= gdo_rpg.max_level then xp = 0 end
    meta:set_int("gdo_level", level)
    meta:set_int("gdo_xp", xp)
    if gained > 0 then
        gdo_rpg.apply_player(player)
        minetest.chat_send_player(player:get_player_name(),
            "Progression : niveau " .. level .. " ! Tes caractéristiques ont progressé.")
    elseif reason then
        minetest.chat_send_player(player:get_player_name(), "+" .. math.floor(amount) .. " XP — " .. reason)
    end
    return true, gained
end

local function show_character_form(player)
    local meta = player:get_meta()
    local race_ids, race_labels, race_index = {}, {}, 1
    for id, race in pairs(races) do
        race_ids[#race_ids + 1] = id
        race_labels[#race_labels + 1] = race.name
    end
    table.sort(race_ids)
    race_labels = {}
    for i, id in ipairs(race_ids) do
        race_labels[i] = races[id].name
        if id == meta:get_string("gdo_race") then race_index = i end
    end
    local class_ids = {"warrior", "mage", "ranger"}
    local class_labels = {"Guerrier", "Mage", "Rôdeur"}
    local class_index = 1
    for i, id in ipairs(class_ids) do
        if id == meta:get_string("gdo_class") then class_index = i end
    end
    local fs = "formspec_version[4]size[11,8]" ..
        "label[0.6,0.45;Création du personnage — Royaume du Nawak]" ..
        "box[0.5,0.85;10,0.05;#88704c]" ..
        "label[0.7,1.35;Choisis une race]" ..
        "dropdown[0.7,1.7;4.5,0.65;race;" .. table.concat(race_ids, ",") .. ";" .. race_index .. "]" ..
        "label[5.4,1.35;Choisis une classe]" ..
        "dropdown[5.4,1.7;4.5,0.65;class;" .. table.concat(class_labels, ",") .. ";" .. class_index .. "]" ..
        "label[0.7,2.65;Les choix définissent tes statistiques et ta capacité raciale.]" ..
        "label[0.7,3.15;Races : Centaure, Né-de-la-flamme, Endérien, Félin, Golem, Arachnide, Merling, Nain, Sang-dragon, Elfe.]" ..
        "label[0.7,3.65;Classes : Guerrier (résistance), Mage (mana), Rôdeur (mobilité).]" ..
        "button[3.55,5.9;3.8,0.8;confirm;Valider mon personnage]" ..
        "button_exit[8.6,6.9;1.8,0.55;cancel;Plus tard]"
    minetest.show_formspec(player:get_player_name(), "gdo_rpg:character", fs)
end

gdo_rpg.show_character_form = show_character_form

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "gdo_rpg:character" or not fields.confirm then return false end
    local meta = player:get_meta()
    if meta:get_string("gdo_race") ~= "" or meta:get_string("gdo_class") ~= "" then
        minetest.chat_send_player(player:get_player_name(), "Ton personnage a déjà été créé : ses choix sont définitifs pour cette version.")
        return true
    end
    local race_id = fields.race or "elf"
    local class_label = fields.class or "Guerrier"
    local class_id = ({["Guerrier"] = "warrior", ["Mage"] = "mage", ["Rôdeur"] = "ranger"})[class_label]
    if not races[race_id] or not class_id then
        minetest.chat_send_player(player:get_player_name(), "Choix invalide. Utilise /gdo_character pour recommencer.")
        return true
    end
    meta:set_string("gdo_race", race_id)
    meta:set_string("gdo_class", class_id)
    local chosen_stats = gdo_rpg.get_stats(player)
    meta:set_int("gdo_mana", chosen_stats.mana_max)
    meta:set_int("gdo_stamina", chosen_stats.stamina_max)
    meta:set_string("gdo_resources_initialized", "1")
    gdo_rpg.apply_player(player)
    local race, class = races[race_id], classes[class_id]
    minetest.chat_send_player(player:get_player_name(),
        "Personnage créé : " .. race.name .. " " .. class.name .. ". Capacité : /gdo_ability — " .. race.ability .. ".")
    return true
end)

local function damage_monsters(player, radius, damage, knockback, slow_time)
    local origin = player:get_pos()
    for _, object in ipairs(minetest.get_objects_inside_radius(origin, radius)) do
        if object ~= player and object:is_valid() then
            local entity = object:get_luaentity()
            if entity and entity._gdo_monster then
                local target_pos = object:get_pos()
                local direction = vector.direction(origin, target_pos)
                object:punch(player, 1.0, {
                    full_punch_interval = 1.0,
                    damage_groups = {fleshy = damage},
                }, direction)
                if knockback and knockback > 0 then
                    object:add_velocity({x = direction.x * knockback, y = 2, z = direction.z * knockback})
                end
                if slow_time then entity._gdo_slow_until = os.time() + slow_time end
            end
        end
    end
end

gdo_rpg.damage_monsters = damage_monsters

local abilities = {
    centaur = function(player)
        local look = player:get_look_dir()
        player:add_velocity({x = look.x * 10, y = 2.5, z = look.z * 10})
    end,
    blazeborn = function(player)
        damage_monsters(player, 5, 8, 4)
        minetest.add_particlespawner({amount = 45, time = 0.3,
            minpos = {x = player:get_pos().x - 2, y = player:get_pos().y - 2, z = player:get_pos().z - 2},
            maxpos = {x = player:get_pos().x + 2, y = player:get_pos().y + 2, z = player:get_pos().z + 2},
            minvel = {x = -2, y = 0, z = -2}, maxvel = {x = 2, y = 3, z = 2},
            minacc = {x = 0, y = 1, z = 0}, maxacc = {x = 0, y = 2, z = 0},
            minexptime = 0.3, maxexptime = 0.8, minsize = 1, maxsize = 3,
            texture = "unknown_node.png^[colorize:#f26a24:220"})
    end,
    enderian = function(player)
        local origin, look = player:get_pos(), player:get_look_dir()
        for distance = 8, 3, -1 do
            local target = vector.add(origin, vector.multiply(look, distance))
            local feet = minetest.get_node_or_nil(target)
            local head = minetest.get_node_or_nil({x = target.x, y = target.y + 1, z = target.z})
            if feet and head and minetest.registered_nodes[feet.name] and minetest.registered_nodes[head.name]
                and not minetest.registered_nodes[feet.name].walkable and not minetest.registered_nodes[head.name].walkable then
                player:set_pos(target)
                return
            end
        end
        minetest.chat_send_player(player:get_player_name(), "Le vide refuse de te laisser passer ici.")
    end,
    feline = function(player)
        local look = player:get_look_dir()
        player:add_velocity({x = look.x * 7, y = 6, z = look.z * 7})
    end,
    golem = function(player)
        local meta = player:get_meta()
        meta:set_int("gdo_guard_until", os.time() + 8)
        player:set_hp(math.min(player:get_properties().hp_max, player:get_hp() + 4))
        minetest.chat_send_player(player:get_player_name(), "Mur de granit : les dégâts reçus sont fortement réduits pendant 8 secondes.")
    end,
    arachnid = function(player)
        damage_monsters(player, 6, 4, 1, 5)
    end,
    merling = function(player)
        player:set_hp(math.min(player:get_properties().hp_max, player:get_hp() + 7))
        player:set_properties({breath_max = 20})
        player:set_breath(20)
    end,
    dwarf = function(player)
        local stats = gdo_rpg.get_stats(player)
        local meta = player:get_meta()
        meta:set_int("gdo_stamina", math.min(stats.stamina_max, meta:get_int("gdo_stamina") + 35))
        player:set_hp(math.min(stats.hp_max, player:get_hp() + 3))
    end,
    dragonkin = function(player)
        damage_monsters(player, 7, 9, 7)
    end,
    elf = function(player)
        local stats = gdo_rpg.get_stats(player)
        local meta = player:get_meta()
        player:set_hp(math.min(stats.hp_max, player:get_hp() + 8))
        meta:set_int("gdo_mana", math.min(stats.mana_max, meta:get_int("gdo_mana") + 15))
    end,
}

function gdo_rpg.use_ability(player)
    local meta = get_meta(player)
    if not meta then return false, "Joueur introuvable." end
    local race_id = meta:get_string("gdo_race")
    local race = races[race_id]
    if not race then return false, "Crée d'abord ton personnage avec /gdo_character." end
    local ready_at = meta:get_int("gdo_ability_ready_at")
    local now = os.time()
    if ready_at > now then return false, "Capacité en recharge : " .. (ready_at - now) .. " seconde(s)." end
    local resource_key = race.resource == "mana" and "gdo_mana" or "gdo_stamina"
    local current = meta:get_int(resource_key)
    if current < race.cost then return false, "Ressource insuffisante : " .. race.cost .. " " .. race.resource .. " requis." end
    meta:set_int(resource_key, current - race.cost)
    meta:set_int("gdo_ability_ready_at", now + 20)
    abilities[race_id](player)
    return true, race.ability .. " déclenchée. Recharge : 20 secondes."
end

minetest.register_chatcommand("gdo_character", {
    description = "Créer ou consulter ton personnage RPG",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then return false, "Joueur introuvable." end
        local character = gdo_rpg.get_character(player)
        if character.race ~= "" and character.class ~= "" then
            local stats = gdo_rpg.get_stats(player)
            return true, races[character.race].name .. " " .. classes[character.class].name ..
                " — niveau " .. character.level .. " — PV " .. stats.hp_max .. " — mana " .. character.mana .. "/" .. stats.mana_max ..
                " — endurance " .. character.stamina .. "/" .. stats.stamina_max .. "."
        end
        show_character_form(player)
        return true, "Choisis une race et une classe dans la fenêtre qui vient de s'ouvrir."
    end,
})

minetest.register_chatcommand("gdo_ability", {
    description = "Déclenche ta capacité raciale",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then return false, "Joueur introuvable." end
        local ok, message = gdo_rpg.use_ability(player)
        if ok then minetest.chat_send_player(name, message) end
        return ok, message
    end,
})

minetest.register_chatcommand("gdo_stats", {
    description = "Affiche tes statistiques détaillées",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then return false, "Joueur introuvable." end
        local stats = gdo_rpg.get_stats(player)
        local meta = player:get_meta()
        local level = math.max(1, meta:get_int("gdo_level"))
        local xp = meta:get_int("gdo_xp")
        return true, string.format("Niv. %d (%d/%d XP) | PV %d | dégâts +%d | mana %d/%d | endurance %d/%d | vitesse %.2f | saut %.2f | défense %.0f%%",
            level, xp, gdo_rpg.xp_to_next_level(level), stats.hp_max, stats.damage,
            meta:get_int("gdo_mana"), stats.mana_max, meta:get_int("gdo_stamina"), stats.stamina_max,
            stats.speed, stats.jump, stats.defense * 100)
    end,
})

minetest.register_globalstep(function(dtime)
    gdo_rpg._regen_timer = (gdo_rpg._regen_timer or 0) + dtime
    if gdo_rpg._regen_timer < 1 then return end
    gdo_rpg._regen_timer = 0
    for _, player in ipairs(minetest.get_connected_players()) do
        local stats = gdo_rpg.get_stats(player)
        local meta = player:get_meta()
        meta:set_int("gdo_mana", math.min(stats.mana_max, meta:get_int("gdo_mana") + 2))
        meta:set_int("gdo_stamina", math.min(stats.stamina_max, meta:get_int("gdo_stamina") + 4))
    end
end)

-- Réduction temporaire des dégâts du Golem et bonus défensif du Guerrier.
minetest.register_on_player_hpchange(function(player, hp_change)
    if hp_change >= 0 then return hp_change end
    local meta = player:get_meta()
    local multiplier = 1
    if meta:get_int("gdo_guard_until") >= os.time() then multiplier = multiplier * 0.4 end
    if meta:get_string("gdo_class") == "warrior" then multiplier = multiplier * 0.88 end
    return hp_change * multiplier
end, true)

minetest.register_on_joinplayer(function(player)
    gdo_rpg.apply_player(player)
    minetest.after(2, function()
        if player and player:is_player() then
            local meta = player:get_meta()
            if meta:get_string("gdo_race") == "" or meta:get_string("gdo_class") == "" then
                show_character_form(player)
            end
        end
    end)
end)

minetest.register_on_respawnplayer(function(player)
    minetest.after(0.1, function()
        if player and player:is_player() then gdo_rpg.apply_player(player) end
    end)
end)

-- GDO avait déjà une progression locale ; on conserve ses métadonnées et son seuil
-- XP historique, mais on centralise désormais l'attribution dans ce module.
minetest.register_on_mods_loaded(function()
    if gdo_society and gdo_society.add_experience then
        gdo_society.add_experience = function(player, amount)
            return gdo_rpg.add_experience(player, amount, "récompense de quête")
        end
    end
end)

minetest.log("action", "[GDO RPG] Races, classes et progression chargées.")
