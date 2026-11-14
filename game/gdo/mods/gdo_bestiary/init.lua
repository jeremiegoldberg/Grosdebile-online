-- Bestiaire provisoire : entités cubiques légères, sans modèle ou texture tiers.
-- Les modèles NLite seront importés après conversion et audit de licences.
local definitions = {
    slime = {
        name = "Gelée des marais", color = "#55b96b", hp = 18, speed = 2.0,
        damage = 2, xp = 25, range = 1.6, interval = 1.5, drop = "gdo_bestiary:slime_gel",
        size = 0.9,
    },
    goblin = {
        name = "Gobelin pillard", color = "#82a34c", hp = 32, speed = 2.8,
        damage = 4, xp = 50, range = 1.7, interval = 1.2, drop = "gdo_economy:coin 2",
        size = 1.0,
    },
    wolf = {
        name = "Loup des brumes", color = "#858b95", hp = 25, speed = 4.0,
        damage = 5, xp = 45, range = 1.8, interval = 1.0, drop = "gdo_bestiary:wolf_hide",
        size = 1.0,
    },
}

gdo_bestiary = {definitions = definitions}

minetest.register_craftitem("gdo_bestiary:slime_gel", {
    description = "Gelée de marais", inventory_image = "unknown_node.png^[colorize:#55b96b:220",
})
minetest.register_craftitem("gdo_bestiary:wolf_hide", {
    description = "Peau de loup", inventory_image = "unknown_node.png^[colorize:#858b95:220",
})

local function register_mob(id, spec)
    local entity_name = "gdo_bestiary:" .. id
    minetest.register_entity(entity_name, {
        initial_properties = {
            physical = true,
            collide_with_objects = true,
            collisionbox = {-0.35 * spec.size, -0.5 * spec.size, -0.35 * spec.size, 0.35 * spec.size, 0.45 * spec.size, 0.35 * spec.size},
            selectionbox = {-0.45 * spec.size, -0.5 * spec.size, -0.45 * spec.size, 0.45 * spec.size, 0.5 * spec.size, 0.45 * spec.size},
            visual = "cube",
            visual_size = {x = spec.size, y = spec.size},
            textures = {
                "unknown_node.png^[colorize:" .. spec.color .. ":220", "unknown_node.png^[colorize:" .. spec.color .. ":220",
                "unknown_node.png^[colorize:" .. spec.color .. ":220", "unknown_node.png^[colorize:" .. spec.color .. ":220",
                "unknown_node.png^[colorize:" .. spec.color .. ":220", "unknown_node.png^[colorize:" .. spec.color .. ":220",
            },
            hp_max = spec.hp,
            makes_footstep_sound = false,
            static_save = true,
            stepheight = 0.6,
        },
        on_activate = function(self, staticdata)
            self._gdo_monster = true
            self._gdo_ai_timer = 0
            self._gdo_attack_timer = 0
            self._gdo_slow_until = 0
            self._gdo_idle = 0
            self.object:set_armor_groups({fleshy = 100})
            self.object:set_acceleration({x = 0, y = -9.81, z = 0})
            if self.object:get_hp() <= 0 then self.object:set_hp(spec.hp) end
        end,
        get_staticdata = function(self)
            return "gdo_bestiary_v1"
        end,
        on_step = function(self, dtime)
            self._gdo_ai_timer = self._gdo_ai_timer + dtime
            self._gdo_attack_timer = math.max(0, self._gdo_attack_timer - dtime)
            if self._gdo_ai_timer < 0.25 then return end
            self._gdo_ai_timer = 0
            local pos = self.object:get_pos()
            if not pos then return end
            local nearest, nearest_distance
            -- Recherche spatiale locale : évite de parcourir tous les joueurs du serveur.
            for _, object in ipairs(minetest.get_objects_inside_radius(pos, 18)) do
                if object:is_player() then
                    local distance = vector.distance(pos, object:get_pos())
                    if not nearest_distance or distance < nearest_distance then
                        nearest, nearest_distance = object, distance
                    end
                end
            end
            local velocity = self.object:get_velocity()
            if not nearest then
                self._gdo_idle = self._gdo_idle + 0.25
                if self._gdo_idle >= 60 then
                    self.object:remove()
                    return
                end
                self.object:set_velocity({x = 0, y = velocity.y, z = 0})
                return
            end
            self._gdo_idle = 0
            local target_pos = nearest:get_pos()
            local direction = vector.direction(pos, target_pos)
            direction.y = 0
            if vector.length(direction) > 0 then direction = vector.normalize(direction) end
            self.object:set_yaw(minetest.dir_to_yaw(direction))
            local speed = spec.speed
            if self._gdo_slow_until > os.time() then speed = speed * 0.35 end
            if nearest_distance > spec.range then
                self.object:set_velocity({x = direction.x * speed, y = velocity.y, z = direction.z * speed})
            else
                self.object:set_velocity({x = 0, y = velocity.y, z = 0})
                if self._gdo_attack_timer <= 0 then
                    nearest:punch(self.object, 1.0, {full_punch_interval = 1.0, damage_groups = {fleshy = spec.damage}}, direction)
                    self._gdo_attack_timer = spec.interval
                end
            end
        end,
        on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir, damage)
            if puncher and puncher:is_player() then
                local stats = gdo_rpg.get_stats(puncher)
                self.object:set_hp(self.object:get_hp() - math.max(0, (damage or 0) + stats.damage))
                return true
            end
            return false
        end,
        on_death = function(self, killer)
            local pos = self.object:get_pos()
            if killer and killer:is_player() then
                gdo_rpg.add_experience(killer, spec.xp, "victoire contre " .. spec.name)
                if gdo_npcs and gdo_npcs.on_mob_killed then gdo_npcs.on_mob_killed(killer, entity_name) end
            end
            if pos and spec.drop then minetest.add_item(pos, spec.drop) end
            if pos then
                minetest.add_particlespawner({amount = 12, time = 0.15,
                    minpos = {x = pos.x - 0.3, y = pos.y - 0.3, z = pos.z - 0.3},
                    maxpos = {x = pos.x + 0.3, y = pos.y + 0.3, z = pos.z + 0.3},
                    minvel = {x = -1, y = 0, z = -1}, maxvel = {x = 1, y = 2, z = 1},
                    minexptime = 0.2, maxexptime = 0.6, minsize = 1, maxsize = 2,
                    texture = "unknown_node.png^[colorize:" .. spec.color .. ":220"})
            end
        end,
    })

    minetest.register_craftitem("gdo_bestiary:" .. id .. "_spawn_egg", {
        description = spec.name .. " — œuf d'apparition",
        inventory_image = "unknown_node.png^[colorize:" .. spec.color .. ":220",
        on_place = function(itemstack, placer, pointed_thing)
            if not pointed_thing or pointed_thing.type ~= "node" then return itemstack end
            local pos = pointed_thing.above
            minetest.add_entity(pos, entity_name)
            if placer and not minetest.is_creative_enabled(placer:get_player_name()) then itemstack:take_item() end
            return itemstack
        end,
    })
end

for id, spec in pairs(definitions) do register_mob(id, spec) end

minetest.register_chatcommand("gdo_bestiary", {
    description = "Affiche le bestiaire du prototype",
    func = function(name)
        return true, "Créatures disponibles : gelée des marais (18 PV), gobelin pillard (32 PV), loup des brumes (25 PV). Apparitions naturelles limitées dans les terres sauvages ; les œufs restent accessibles en mode créatif."
    end,
})

minetest.log("action", "[GDO Bestiary] Trois créatures hostiles sont enregistrées.")


-- Apparition naturelle plafonnée, réservée aux terres sauvages.
-- Le château et sa zone d'accueil (rayon 105 autour de l'origine) restent sûrs.
local spawn_enabled = minetest.settings:get_bool("gdo_bestiary_natural_spawn", true)
local spawn_timer = 0
local spawn_interval = 25
local spawn_cap = 5
local spawn_radius = 48

local function find_spawn_position(player)
    local center = player:get_pos()
    if math.sqrt(center.x * center.x + center.z * center.z) < 105 then return nil end

    local angle = math.random() * math.pi * 2
    local distance = math.random(18, 30)
    local x = math.floor(center.x + math.cos(angle) * distance)
    local z = math.floor(center.z + math.sin(angle) * distance)
    local base_y = math.floor(center.y)

    for y = base_y + 7, base_y - 12, -1 do
        local ground_pos = {x = x, y = y, z = z}
        local ground = minetest.get_node_or_nil(ground_pos)
        local feet_pos = {x = x, y = y + 1, z = z}
        local head_pos = {x = x, y = y + 2, z = z}
        local feet = minetest.get_node_or_nil(feet_pos)
        local head = minetest.get_node_or_nil(head_pos)
        if ground and feet and head then
            local ground_def = minetest.registered_nodes[ground.name]
            local feet_def = minetest.registered_nodes[feet.name]
            local head_def = minetest.registered_nodes[head.name]
            local light = minetest.get_node_light(feet_pos) or 0
            local function is_non_liquid(def)
                return def and (not def.liquidtype or def.liquidtype == "none")
            end
            if ground_def and ground_def.walkable and is_non_liquid(ground_def)
                and feet_def and not feet_def.walkable and is_non_liquid(feet_def)
                and head_def and not head_def.walkable and is_non_liquid(head_def)
                and light >= 3 then
                return {x = x + 0.5, y = y + 1, z = z + 0.5}
            end
        end
    end
    return nil
end

local function count_nearby_monsters(pos)
    local count = 0
    for _, object in ipairs(minetest.get_objects_inside_radius(pos, spawn_radius)) do
        local entity = object:get_luaentity()
        if entity and entity._gdo_monster then count = count + 1 end
    end
    return count
end

minetest.register_globalstep(function(dtime)
    if not spawn_enabled then return end
    spawn_timer = spawn_timer + dtime
    if spawn_timer < spawn_interval then return end
    spawn_timer = 0

    for _, player in ipairs(minetest.get_connected_players()) do
        local center = player:get_pos()
        if math.sqrt(center.x * center.x + center.z * center.z) >= 105
            and count_nearby_monsters(center) < spawn_cap then
            for attempt = 1, 8 do
                local pos = find_spawn_position(player)
                if pos then
                    local choices = {"slime", "goblin", "wolf"}
                    local id = choices[math.random(1, #choices)]
                    minetest.add_entity(pos, "gdo_bestiary:" .. id)
                    break
                end
            end
        end
    end
end)
