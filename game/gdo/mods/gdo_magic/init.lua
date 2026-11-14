-- Magie légère : ciblage serveur par raycast, coûts de mana et effets natifs Luanti.
local function find_monster_target(player, range)
    local origin = vector.add(player:get_pos(), {x = 0, y = 1.35, z = 0})
    local target = vector.add(origin, vector.multiply(player:get_look_dir(), range))
    local ray = minetest.raycast(origin, target, true, false)
    for pointed in ray do
        if pointed.type == "object" and pointed.ref ~= player and pointed.ref:is_valid() then
            local entity = pointed.ref:get_luaentity()
            if entity and entity._gdo_monster then return pointed.ref end
        end
    end
    return nil
end

local function spend_mana(player, cost)
    local meta = player:get_meta()
    local current = meta:get_int("gdo_mana")
    if current < cost then return false end
    meta:set_int("gdo_mana", current - cost)
    return true
end

local function spell_effect(pos, color)
    minetest.add_particlespawner({amount = 18, time = 0.15,
        minpos = {x = pos.x - 0.35, y = pos.y - 0.35, z = pos.z - 0.35},
        maxpos = {x = pos.x + 0.35, y = pos.y + 0.35, z = pos.z + 0.35},
        minvel = {x = -1, y = 0, z = -1}, maxvel = {x = 1, y = 2, z = 1},
        minacc = {x = 0, y = 0, z = 0}, maxacc = {x = 0, y = 1, z = 0},
        minexptime = 0.3, maxexptime = 0.7, minsize = 1, maxsize = 2,
        texture = "unknown_node.png^[colorize:" .. color .. ":220"})
end

local spells = {
    firebolt = {
        name = "Trait de feu", cost = 15, description = "Inflige 10 dégâts à une cible devant toi.",
        cast = function(player)
            local target = find_monster_target(player, 18)
            if not target then return false, "Aucun monstre dans ta ligne de mire." end
            local stats = gdo_rpg.get_stats(player)
            target:punch(player, 1, {full_punch_interval = 1, damage_groups = {fleshy = 10 + stats.damage}}, player:get_look_dir())
            spell_effect(target:get_pos(), "#ef6d24")
            return true, "Trait de feu lancé."
        end,
    },
    heal = {
        name = "Soin", cost = 20, description = "Restaure 9 points de vie.",
        cast = function(player)
            local max_hp = player:get_properties().hp_max or 20
            player:set_hp(math.min(max_hp, player:get_hp() + 9))
            spell_effect(player:get_pos(), "#55d68b")
            return true, "La magie referme tes blessures."
        end,
    },
    frostnova = {
        name = "Nova de givre", cost = 28, description = "Blesse et ralentit les monstres proches.",
        cast = function(player)
            gdo_rpg.damage_monsters(player, 6, 6, 2, 5)
            spell_effect(player:get_pos(), "#73d7ff")
            return true, "Une onde glacée se propage autour de toi."
        end,
    },
    arcane_burst = {
        name = "Décharge arcanique", cost = 25, description = "Dégâts magiques de zone.",
        cast = function(player)
            gdo_rpg.damage_monsters(player, 4.5, 8, 3)
            spell_effect(player:get_pos(), "#bd83ff")
            return true, "La décharge arcanique explose autour de toi."
        end,
    },
}

gdo_magic = {spells = spells}

minetest.register_chatcommand("gdo_spell", {
    params = "<firebolt|heal|frostnova|arcane_burst>",
    description = "Lance un sort en dépensant du mana",
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        if not player then return false, "Joueur introuvable." end
        local spell = spells[(param or ""):lower()]
        if not spell then return false, "Sort inconnu. Utilise /gdo_spells pour la liste." end
        local ready_at = player:get_meta():get_int("gdo_spell_ready_at")
        if ready_at > os.time() then return false, "Ton grimoire se recharge encore." end
        if player:get_meta():get_int("gdo_mana") < spell.cost then return false, "Mana insuffisant : " .. spell.cost .. " requis." end
        local ok, message = spell.cast(player)
        if not ok then return false, message end
        spend_mana(player, spell.cost)
        player:get_meta():set_int("gdo_spell_ready_at", os.time() + 1)
        return true, message .. " Mana : -" .. spell.cost .. "."
    end,
})

minetest.register_chatcommand("gdo_spells", {
    description = "Liste les sorts connus",
    func = function(name)
        for id, spell in pairs(spells) do
            minetest.chat_send_player(name, id .. " — " .. spell.name .. " : " .. spell.description .. " Coût : " .. spell.cost .. " mana.")
        end
        return true, "Pour lancer un sort : /gdo_spell <nom>."
    end,
})

minetest.register_craftitem("gdo_magic:spellbook", {
    description = "Grimoire des arcanes",
    inventory_image = "unknown_node.png^[colorize:#7652a8:220",
    on_use = function(itemstack, user)
        if user and user:is_player() then
            minetest.chat_send_player(user:get_player_name(), "Grimoire : /gdo_spells pour la liste, puis /gdo_spell firebolt, heal, frostnova ou arcane_burst.")
        end
        return itemstack
    end,
})

minetest.log("action", "[GDO Magic] Les arcanes sont disponibles.")
