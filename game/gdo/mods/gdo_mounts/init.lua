-- Montures natives minimalistes. Les modèles et selles NLite ne sont pas copiés.
local mounts = {
    horse = {name = "Cheval du Royaume", color = "#9a6c42", speed = 6, fly = false, jump = 5, hp = 30},
    dragon = {name = "Drake des Brumes", color = "#765da7", speed = 9, fly = true, jump = 5, hp = 90},
}
gdo_mounts = {definitions = mounts}

local function detach(self)
    if not self._rider then return end
    local player = minetest.get_player_by_name(self._rider)
    if player then player:set_detach() end
    self._rider = nil
end

local function register_mount(id, spec)
    local entity_name = "gdo_mounts:" .. id
    minetest.register_entity(entity_name, {
        initial_properties = {
            physical = true,
            collide_with_objects = true,
            collisionbox = {-0.55, -0.5, -0.7, 0.55, 1.0, 0.7},
            visual = "cube",
            visual_size = {x = 1.1, y = 1.4},
            textures = {
                "unknown_node.png^[colorize:" .. spec.color .. ":220", "unknown_node.png^[colorize:" .. spec.color .. ":220",
                "unknown_node.png^[colorize:" .. spec.color .. ":220", "unknown_node.png^[colorize:" .. spec.color .. ":220",
                "unknown_node.png^[colorize:" .. spec.color .. ":220", "unknown_node.png^[colorize:" .. spec.color .. ":220",
            },
            hp_max = spec.hp,
            makes_footstep_sound = true,
            static_save = true,
        },
        on_activate = function(self)
            self._rider = nil
            self._jump_latched = false
            self.object:set_armor_groups({fleshy = 100})
            self.object:set_acceleration({x = 0, y = spec.fly and 0 or -9.81, z = 0})
        end,
        on_deactivate = function(self)
            detach(self)
        end,
        on_rightclick = function(self, clicker)
            if not clicker or not clicker:is_player() then return end
            local name = clicker:get_player_name()
            if self._rider == name then
                detach(self)
                minetest.chat_send_player(name, "Tu descends de " .. spec.name .. ".")
            elseif not self._rider then
                self._rider = name
                clicker:set_attach(self.object, "", {x = 0, y = 9, z = 0}, {x = 0, y = 0, z = 0})
                local controls_hint = spec.fly and "Espace pour monter, Maj pour descendre, Aux1 pour descendre du drake." or "Maj pour descendre."
                minetest.chat_send_player(name, "Monture montée : ZQSD/WASD pour diriger. " .. controls_hint)
            else
                minetest.chat_send_player(name, "Cette monture a déjà un cavalier.")
            end
        end,
        on_step = function(self, dtime)
            if not self._rider then return end
            local rider = minetest.get_player_by_name(self._rider)
            if not rider then self._rider = nil; return end
            local controls = rider:get_player_control()
            if (spec.fly and controls.aux1) or (not spec.fly and controls.sneak) then
                detach(self)
                return
            end
            local yaw = rider:get_look_horizontal()
            self.object:set_yaw(yaw)
            local forward = {x = -math.sin(yaw), y = 0, z = math.cos(yaw)}
            local side = {x = math.cos(yaw), y = 0, z = math.sin(yaw)}
            local velocity = self.object:get_velocity()
            local x, z = 0, 0
            if controls.up then x = x + forward.x; z = z + forward.z end
            if controls.down then x = x - forward.x; z = z - forward.z end
            if controls.left then x = x + side.x; z = z + side.z end
            if controls.right then x = x - side.x; z = z - side.z end
            local magnitude = math.sqrt(x * x + z * z)
            if magnitude > 0 then x, z = x / magnitude, z / magnitude end
            local vertical = spec.fly and 0 or velocity.y
            if spec.fly then
                if controls.jump then vertical = spec.speed * 0.55 end
                if controls.sneak then vertical = -spec.speed * 0.4 end
            elseif controls.jump and not self._jump_latched then
                vertical = spec.jump
            end
            self._jump_latched = controls.jump
            self.object:set_velocity({x = x * spec.speed, y = vertical, z = z * spec.speed})
        end,
    })

    minetest.register_craftitem("gdo_mounts:" .. id .. "_whistle", {
        description = "Sifflet d'appel — " .. spec.name,
        inventory_image = "unknown_node.png^[colorize:" .. spec.color .. ":220",
        on_use = function(itemstack, user)
            if not user or not user:is_player() then return itemstack end
            local pos = vector.add(user:get_pos(), vector.multiply(user:get_look_dir(), 2))
            pos.y = pos.y + 0.5
            minetest.add_entity(pos, entity_name)
            itemstack:take_item()
            return itemstack
        end,
    })
end

for id, spec in pairs(mounts) do register_mount(id, spec) end

minetest.register_chatcommand("gdo_mount", {
    params = "<horse|dragon>",
    description = "Fait apparaître une monture de test (privilège serveur)",
    privs = {server = true},
    func = function(name, param)
        local spec = mounts[(param or ""):lower()]
        if not spec then return false, "Choisis horse ou dragon." end
        local player = minetest.get_player_by_name(name)
        if not player then return false, "Joueur introuvable." end
        local pos = vector.add(player:get_pos(), vector.multiply(player:get_look_dir(), 3))
        minetest.add_entity(pos, "gdo_mounts:" .. param:lower())
        return true, spec.name .. " est apparu devant toi. Clic droit pour monter."
    end,
})

minetest.log("action", "[GDO Mounts] Cheval et drake pilotables enregistrés.")
