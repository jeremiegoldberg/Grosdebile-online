-- GDO — Protection des zones scénarisées
-- Les zones d'histoire sont protégées. Le reste du monde est volontairement libre :
-- pas de claims, pas de propriété des constructions, pas de protection entre joueurs.

gdo_zones = gdo_zones or {}
local zones = {}
gdo_zones.register_readonly_zone = function(def)
    assert(type(def) == "table" and type(def.name) == "string", "zone needs a name")
    assert(type(def.min) == "table" and type(def.max) == "table", "zone needs min/max positions")
    assert(def.min.x <= def.max.x and def.min.y <= def.max.y and def.min.z <= def.max.z,
        "invalid zone bounds")
    zones[#zones + 1] = {
        name = def.name,
        description = def.description or "Zone scénarisée protégée",
        min = {x = def.min.x, y = def.min.y, z = def.min.z},
        max = {x = def.max.x, y = def.max.y, z = def.max.z},
    }
end

local function contains(zone, pos)
    return pos.x >= zone.min.x and pos.x <= zone.max.x
        and pos.y >= zone.min.y and pos.y <= zone.max.y
        and pos.z >= zone.min.z and pos.z <= zone.max.z
end

local previous_is_protected = minetest.is_protected
minetest.is_protected = function(pos, name)
    if name and name ~= "" and minetest.check_player_privs(name, {protection_bypass = true}) then
        return previous_is_protected and previous_is_protected(pos, name) or false
    end
    for _, zone in ipairs(zones) do
        if contains(zone, pos) then
            return true
        end
    end
    if previous_is_protected then
        return previous_is_protected(pos, name)
    end
    return false
end

minetest.register_on_protection_violation(function(pos, name)
    for _, zone in ipairs(zones) do
        if contains(zone, pos) then
            minetest.chat_send_player(name,
                "Zone scénarisée protégée : " .. zone.name .. ". Ici, on ne construit pas et on ne démolit pas. Les catastrophes sont réservées aux scénaristes.")
            return
        end
    end
end)

minetest.register_chatcommand("gdo_zones", {
    description = "Affiche les zones scénarisées protégées et les règles du monde libre",
    func = function(name)
        minetest.chat_send_player(name, "RÈGLES DU ROYAUME : les zones de quêtes sont sanctuarisées ; ailleurs, liberté totale.")
        for _, zone in ipairs(zones) do
            minetest.chat_send_player(name,
                zone.name .. " — " .. zone.description
                .. " | X " .. zone.min.x .. " à " .. zone.max.x
                .. ", Y " .. zone.min.y .. " à " .. zone.max.y
                .. ", Z " .. zone.min.z .. " à " .. zone.max.z)
        end
        minetest.chat_send_player(name,
            "Hors de ces limites : construis, creuse, modifie ou détruis librement, y compris les constructions des autres joueurs. Aucun terrain n'est réservé.")
        return true
    end,
})

minetest.log("action", "[GDO] Protection des zones scénarisées chargée ; le reste du monde est libre.")
