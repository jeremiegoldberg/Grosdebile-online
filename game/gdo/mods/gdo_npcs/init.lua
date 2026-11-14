-- Quêtes natives et persistées par personnage. Gérard conserve sa quête tutorielle historique.
gdo_npcs = {}
local quest = {
    id = "goblin_bounty",
    title = "Prime aux gobelins",
    description = "Élimine trois gobelins qui rôdent dans les terres sauvages.",
    target = "gdo_bestiary:goblin",
    required = 3,
    xp = 150,
    coins = 35,
}

gdo_npcs.quests = {goblin_bounty = quest}

local function key(field)
    return "gdo_quest_" .. quest.id .. "_" .. field
end

function gdo_npcs.on_mob_killed(player, mob_name)
    if not player or not player:is_player() or mob_name ~= quest.target then return end
    local meta = player:get_meta()
    if meta:get_string(key("status")) ~= "active" then return end
    local count = math.min(quest.required, meta:get_int(key("count")) + 1)
    meta:set_int(key("count"), count)
    if count >= quest.required then
        meta:set_string(key("status"), "ready")
        minetest.chat_send_player(player:get_player_name(), "Objectif atteint : retourne au tableau des aventuriers pour réclamer ta prime.")
    else
        minetest.chat_send_player(player:get_player_name(), "Prime aux gobelins : " .. count .. "/" .. quest.required .. ".")
    end
end

local function show_quests(player)
    local meta = player:get_meta()
    local status = meta:get_string(key("status"))
    if status == "" then status = "available" end
    local count = meta:get_int(key("count"))
    local action = "button[0.8,4.3;3.2,0.7;accept;Accepter la quête]"
    local status_text = "Quête disponible"
    if status == "active" then
        status_text = "En cours : " .. count .. "/" .. quest.required .. " gobelins vaincus"
        action = "label[0.8,4.35;Reviens quand l'objectif sera atteint.]"
    elseif status == "ready" then
        status_text = "Objectif atteint : récompense disponible"
        action = "button[0.8,4.3;3.2,0.7;claim;Réclamer la récompense]"
    elseif status == "completed" then
        status_text = "Quête terminée — merci pour le service rendu."
        action = "label[0.8,4.35;Aucune autre prime disponible pour le moment.]"
    end
    local fs = "formspec_version[4]size[8,6]" ..
        "label[0.6,0.5;Tableau des aventuriers]" ..
        "box[0.5,0.9;7,0.05;#88704c]" ..
        "label[0.8,1.35;" .. minetest.formspec_escape(quest.title) .. "]" ..
        "textarea[0.8,1.7;6.3,1.4;;;" .. minetest.formspec_escape(quest.description) .. "]" ..
        "label[0.8,3.35;" .. minetest.formspec_escape(status_text) .. "]" .. action ..
        "button_exit[5.7,4.3;1.5,0.7;close;Fermer]"
    minetest.show_formspec(player:get_player_name(), "gdo_npcs:quests", fs)
end

gdo_npcs.show_quests = show_quests

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "gdo_npcs:quests" then return false end
    local meta = player:get_meta()
    local status = meta:get_string(key("status"))
    if fields.accept and (status == "" or status == "available") then
        meta:set_string(key("status"), "active")
        meta:set_int(key("count"), 0)
        minetest.chat_send_player(player:get_player_name(), "Quête acceptée : " .. quest.title .. ".")
        show_quests(player)
        return true
    end
    if fields.claim and status == "ready" then
        meta:set_string(key("status"), "completed")
        gdo_rpg.add_experience(player, quest.xp, "prime aux gobelins")
        gdo_economy.add_coins(player, quest.coins)
        minetest.chat_send_player(player:get_player_name(), "Prime versée : " .. quest.xp .. " XP et " .. quest.coins .. " pièces.")
        show_quests(player)
        return true
    end
    return false
end)

minetest.register_node("gdo_npcs:quest_board", {
    description = "Tableau des aventuriers",
    tiles = {"unknown_node.png^[colorize:#80603b:220"},
    groups = {choppy = 2, oddly_breakable_by_hand = 2},
    on_rightclick = function(pos, node, clicker)
        if clicker and clicker:is_player() then show_quests(clicker) end
    end,
})

minetest.register_chatcommand("gdo_quests", {
    description = "Consulte les quêtes disponibles",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then return false, "Joueur introuvable." end
        show_quests(player)
        return true, "Le tableau des aventuriers est ouvert."
    end,
})

minetest.log("action", "[GDO NPC] Le registre de quêtes est chargé.")
