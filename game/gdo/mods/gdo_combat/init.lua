-- Arsenal de départ. Les dégâts de base sont ensuite complétés par les bonus du RPG
-- dans les entités hostiles de gdo_bestiary.
local function texture(color)
    return "unknown_node.png^[colorize:" .. color .. ":220"
end

local weapons = {
    {id = "wood_sword", name = "Épée en bois", image = "#9a663b", damage = 2, interval = 1.2},
    {id = "stone_sword", name = "Épée de pierre", image = "#888888", damage = 4, interval = 1.25},
    {id = "steel_sword", name = "Épée d'acier", image = "#b4c4cc", damage = 7, interval = 1.1},
    {id = "battle_axe", name = "Hache de bataille", image = "#9c7850", damage = 9, interval = 1.6},
}

for _, weapon in ipairs(weapons) do
    minetest.register_tool("gdo_combat:" .. weapon.id, {
        description = weapon.name,
        inventory_image = texture(weapon.image),
        tool_capabilities = {
            full_punch_interval = weapon.interval,
            max_drop_level = 1,
            groupcaps = {},
            damage_groups = {fleshy = weapon.damage},
        },
    })
end

minetest.register_craftitem("gdo_combat:bandage", {
    description = "Bandage de fortune (+5 PV)",
    inventory_image = texture("#e8e0d2"),
    on_use = function(itemstack, user)
        if not user or not user:is_player() then return itemstack end
        local max_hp = user:get_properties().hp_max or 20
        user:set_hp(math.min(max_hp, user:get_hp() + 5))
        itemstack:take_item()
        return itemstack
    end,
})

minetest.register_craft({
    output = "gdo_combat:wood_sword",
    recipe = {{"gdo_core:bois"}, {"gdo_core:bois"}},
})
minetest.register_craft({
    output = "gdo_combat:stone_sword",
    recipe = {{"gdo_core:pierre"}, {"gdo_core:pierre"}, {"gdo_core:bois"}},
})
minetest.register_craft({
    output = "gdo_combat:bandage",
    recipe = {{"gdo_core:navet", "gdo_core:navet"}},
})

minetest.register_chatcommand("gdo_combat", {
    description = "Affiche les règles du combat GDO",
    func = function(name)
        return true, "Clic gauche pour frapper avec une arme. Le niveau, la race et la classe améliorent les personnages. Les monstres se combattent avec les armes de gdo_combat ; /gdo_stats affiche tes bonus."
    end,
})
