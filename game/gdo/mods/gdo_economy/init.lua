-- Économie de départ locale au monde. La synchronisation backend sera une étape séparée.
gdo_economy = {}
local MAX_BALANCE = 1000000000

local function meta(player)
    return player and player:is_player() and player:get_meta() or nil
end

function gdo_economy.get_balance(player)
    local m = meta(player)
    return m and math.max(0, m:get_int("gdo_coins")) or 0
end

function gdo_economy.add_coins(player, amount)
    local m = meta(player)
    if not m or type(amount) ~= "number" or amount <= 0 then return false end
    local balance = math.min(MAX_BALANCE, gdo_economy.get_balance(player) + math.floor(amount))
    m:set_int("gdo_coins", balance)
    return true, balance
end

function gdo_economy.remove_coins(player, amount)
    local m = meta(player)
    amount = math.floor(tonumber(amount) or 0)
    if not m or amount <= 0 or gdo_economy.get_balance(player) < amount then return false end
    m:set_int("gdo_coins", gdo_economy.get_balance(player) - amount)
    return true
end

function gdo_economy.transfer(sender, receiver, amount)
    amount = math.floor(tonumber(amount) or 0)
    if not sender or not receiver or amount <= 0 then return false, "Montant invalide." end
    if gdo_economy.get_balance(sender) < amount then return false, "Solde insuffisant." end
    if gdo_economy.get_balance(receiver) + amount > MAX_BALANCE then
        return false, "Le portefeuille du destinataire est plein."
    end
    if not gdo_economy.remove_coins(sender, amount) then return false, "Solde insuffisant." end
    gdo_economy.add_coins(receiver, amount)
    return true
end

minetest.register_chatcommand("gdo_wallet", {
    description = "Affiche ton portefeuille",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then return false, "Joueur introuvable." end
        return true, "Portefeuille : " .. gdo_economy.get_balance(player) .. " pièces du Nawak."
    end,
})

minetest.register_chatcommand("gdo_pay", {
    params = "<joueur> <montant>",
    description = "Transfère des pièces à un joueur connecté",
    func = function(name, param)
        local target_name, amount = (param or ""):match("^(%S+)%s+(%d+)$")
        local sender = minetest.get_player_by_name(name)
        local receiver = target_name and minetest.get_player_by_name(target_name)
        if not sender or not receiver then return false, "Le destinataire doit être connecté. Syntaxe : /gdo_pay <joueur> <montant>." end
        local ok, message = gdo_economy.transfer(sender, receiver, tonumber(amount))
        if not ok then return false, message end
        minetest.chat_send_player(target_name, name .. " t'a envoyé " .. amount .. " pièces du Nawak.")
        return true, "Transfert envoyé : " .. amount .. " pièces."
    end,
})

minetest.register_craftitem("gdo_economy:coin", {
    description = "Pièce du Nawak",
    inventory_image = "unknown_node.png^[colorize:#e4b83f:240",
    stack_max = 999,
    on_use = function(itemstack, user)
        if not user or not user:is_player() then return itemstack end
        gdo_economy.add_coins(user, 1)
        itemstack:take_item()
        minetest.chat_send_player(user:get_player_name(), "+1 pièce. /gdo_wallet pour consulter ton solde.")
        return itemstack
    end,
})
