-- GDO — Château des Brumes : architecture monumentale v4
-- Génération au-dessus du terrain, façade tournée vers le sud (+Z).
-- Textures fournies dans textures/refit_*.png.

local modname = minetest.get_current_modname()
local S = minetest.get_translator and minetest.get_translator(modname) or function(s) return s end

local M = {
    stone = "gdo_castle:refit_stone", trim = "gdo_castle:refit_trim",
    roof = "gdo_castle:refit_roof", floor = "gdo_castle:refit_floor",
    wood = "gdo_castle:refit_wood", glass = "gdo_castle:refit_glass",
    gold = "gdo_castle:refit_gold", grass = "gdo_castle:refit_grass",
    path = "gdo_castle:refit_path", leaves = "gdo_castle:refit_leaves",
    water = "gdo_castle:refit_water",
}
local OFFSET = 24
local function pos(x,y,z) return {x=x,y=y+OFFSET,z=z} end
local function put(x,y,z,n) minetest.set_node(pos(x,y,z), {name=n}) end
local function fill(x1,y1,z1,x2,y2,z2,n)
    for x=math.min(x1,x2),math.max(x1,x2) do
        for y=math.min(y1,y2),math.max(y1,y2) do
            for z=math.min(z1,z2),math.max(z1,z2) do put(x,y,z,n) end
        end
    end
end
local function clear(x1,y1,z1,x2,y2,z2) fill(x1,y1,z1,x2,y2,z2,"air") end
local function deck(x1,z1,x2,z2,y,n) fill(x1,y,z1,x2,y,z2,n) end
local function wall_x(x1,x2,y1,y2,z,n,t)
    fill(x1,y1,z,x2,y2,z+(t or 1)-1,n)
end
local function wall_z(z1,z2,y1,y2,x,n,t)
    fill(x,y1,z1,x+(t or 1)-1,y2,z2,n)
end

-- Textures autonomes : aucun fichier PNG externe n'est requis.
local palette = {
    refit_stone = "refit_stone.png",
    refit_trim = "refit_trim.png",
    refit_roof = "refit_roof.png",
    refit_floor = "refit_floor.png",
    refit_wood = "refit_wood.png",
    refit_glass = "refit_glass.png",
    refit_gold = "refit_gold.png",
    refit_grass = "refit_grass.png",
    refit_path = "refit_path.png",
    refit_leaves = "refit_leaves.png",
    refit_water = "refit_water.png",
}
local function register_texture_node(name, desc, groups, extra)
    local short = name:match(":(.+)$")
    local def = {description=S(desc), tiles={palette[short] or "unknown_node.png"}, groups=groups or {cracky=2}}
    if extra then for k,v in pairs(extra) do def[k]=v end end
    minetest.register_node(name, def)
end

register_texture_node(M.stone,"Calcaire du Château")
register_texture_node(M.trim,"Pierre sculptée")
register_texture_node(M.roof,"Ardoise bleu nuit")
register_texture_node(M.floor,"Dallage clair")
register_texture_node(M.wood,"Chêne ancien",{choppy=2})
register_texture_node(M.glass,"Vitrail royal",{cracky=2},{
    paramtype="light", sunlight_propagates=true, light_source=5, drawtype="glasslike",
    use_texture_alpha="blend",})
register_texture_node(M.gold,"Ornement royal")
register_texture_node(M.grass,"Gazon du parvis",{crumbly=3,soil=1})
register_texture_node(M.path,"Pavés du royaume")
register_texture_node(M.leaves,"Feuillage",{snappy=3},{
    drawtype="allfaces_optional",paramtype="light",sunlight_propagates=true})
register_texture_node(M.water,"Eau décorative",{cracky=3},{
    drawtype="liquid",paramtype="light",sunlight_propagates=true,walkable=false,
    pointable=false,buildable_to=true,liquidtype="source",
    liquid_alternative_flowing="gdo_castle:refit_water_flowing",
    liquid_alternative_source="gdo_castle:refit_water",liquid_viscosity=1,
    liquid_renewable=false})
minetest.register_node("gdo_castle:refit_water_flowing",{
    description=S("Eau décorative"),tiles={palette.refit_water},
    drawtype="flowingliquid",paramtype="light",paramtype2="flowingliquid",
    groups={not_in_creative_inventory=1},walkable=false,pointable=false,
    buildable_to=true,drop="",liquidtype="flowing",
    liquid_alternative_flowing="gdo_castle:refit_water_flowing",
    liquid_alternative_source=M.water,liquid_viscosity=1})

local function lantern(x,y,z)
    put(x,y,z,"gdo_castle:castle_lantern")
end

-- Tour octogonale massive, avec ouvertures, mâchicoulis et toit conique étagé.
local function round_tower(cx,cz,r,h)
    for y=1,h do
        for x=-r,r do for z=-r,r do
            local d=x*x+z*z
            if d <= r*r and d >= (r-1.35)*(r-1.35) then
                put(cx+x,y,cz+z,M.stone)
            end
        end end
    end
    -- Planchers intérieurs et fenêtres hautes.
    for y=7,h-4,7 do
        deck(cx-r+1,cz-r+1,cx+r-1,cz+r-1,y,M.wood)
        put(cx,y,cz-r,M.glass); put(cx,y,cz+r,M.glass)
        put(cx-r,y,cz,M.glass); put(cx+r,y,cz,M.glass)
        lantern(cx,y+1,cz)
    end
    -- Corniche en pierre claire.
    for x=-r-1,r+1 do for z=-r-1,r+1 do
        if x*x+z*z <= (r+1)*(r+1) and x*x+z*z >= (r-2)*(r-2) then
            put(cx+x,h+1,cz+z,M.trim)
        end
    end end
    -- Toit conique bleu, chaque rang est légèrement resserré.
    for layer=0,r+2 do
        local rr=r+1-layer
        if rr>=0 then
            for x=-rr,rr do for z=-rr,rr do
                if x*x+z*z <= rr*rr and x*x+z*z >= math.max(0,(rr-1.7)*(rr-1.7)) then
                    put(cx+x,h+2+layer,cz+z,M.roof)
                end
            end end
        end
    end
    fill(cx-1,h+r+4,cz-1,cx+1,h+r+5,cz+1,M.gold)
    put(cx,h+r+6,cz,M.gold)
end

local function battlement_x(x1,x2,y,z)
    for x=x1,x2 do
        if x%2==0 then fill(x,y,z,x,y+1,z,M.trim) end
    end
end
local function battlement_z(z1,z2,y,x)
    for z=z1,z2 do
        if z%2==0 then fill(x,y,z,x,y+1,z,M.trim) end
    end
end

local function gable(xc,base_y,zfront,width,height,depth)
    for y=0,height do
        local half=math.floor(width*(1-y/height)/2)
        if half>=0 then
            fill(xc-half,base_y+y,zfront-depth,xc+half,base_y+y,zfront,M.roof)
        end
    end
end

local function main_keep()
    -- Corps central haut, derrière la porte.
    fill(-17,1,-48,17,25,-17,M.stone)
    clear(-15,2,-46,15,23,-19)
    deck(-15,-46,15,-19,1,M.floor)
    deck(-15,-46,15,-19,9,M.wood)
    deck(-15,-46,15,-19,17,M.wood)
    -- Façade sud et entrée axiale du donjon.
    clear(-4,1,-18,4,12,-17)
    fill(-6,12,-18,6,13,-17,M.trim)
    fill(-5,13,-18,5,14,-17,M.roof)
    -- Fenêtres symétriques sur la façade.
    for x=-13,13,4 do
        for y=6,21,7 do
            put(x,y,-18,M.glass)
            fill(x-1,y-1,-19,x+1,y-1,-19,M.trim)
            fill(x-1,y+1,-19,x+1,y+1,-19,M.trim)
        end
    end
    -- Bandeaux horizontaux et pilastres.
    for x=-16,16,8 do
        fill(x,2,-48,x+1,24,-17,M.trim)
    end
    for y=8,16,8 do wall_x(-16,16,y,y,-19,M.trim,1) end
    -- Toit principal à quatre pans, largement débordant.
    for layer=0,8 do
        local inset=layer*2
        fill(-19+inset,26+layer,-50+inset,19-inset,26+layer,-15-inset,M.roof)
    end
    -- Lucarnes et fenêtres de toit.
    for _,x in ipairs({-10,0,10}) do
        gable(x,27,-18,7,5,7)
        put(x,29,-18,M.glass)
        put(x,32,-18,M.gold)
    end
    -- Quatre tours d'angle du donjon.
    round_tower(-17,-48,5,33)
    round_tower(17,-48,5,37)
    round_tower(-17,-17,5,29)
    round_tower(17,-17,5,32)
    -- Tour centrale supérieure, plus haute que les autres.
    round_tower(0,-35,4,43)
    -- Balcon royal sous les fenêtres.
    fill(-8,15,-16,8,15,-13,M.trim)
    for x=-8,8,2 do put(x,16,-13,M.wood); put(x,17,-13,M.trim) end
    fill(-9,18,-17,9,18,-14,M.roof)
    -- Bannière centrale.
    fill(-1,12,-16,1,15,-16,M.gold)
    fill(-1,10,-16,1,11,-16,M.roof)
end

local function front_gate()
    -- Muraille basse au pied du donjon, avec portail central ouvert.
    wall_x(-43,43,1,13,-8,M.stone,3)
    clear(-6,1,-9,6,10,-5)
    -- Deux grandes tours rondes de part et d'autre du portail.
    round_tower(-20,-5,6,28)
    round_tower(20,-5,6,28)
    -- Arc supérieur et voussoirs contrastés.
    fill(-8,11,-9,8,13,-5,M.trim)
    fill(-7,14,-9,7,15,-5,M.roof)
    for x=-7,7 do
        local y=10+math.floor(3*(1-math.abs(x)/7))
        put(x,y,-9,M.gold)
    end
    -- Petites tours secondaires aux extrémités des ailes.
    round_tower(-37,-19,4,21)
    round_tower(37,-19,4,21)
    -- Chemin de ronde et créneaux.
    deck(-42,-5,42,-4,14,M.floor)
    battlement_x(-42,42,15,-5)
    wall_z(-8,25,1,12,-43,M.stone,2)
    wall_z(-8,25,1,12,42,M.stone,2)
    battlement_z(-7,24,13,-42); battlement_z(-7,24,13,42)
    -- Tours de flanquement arrière.
    round_tower(-43,25,5,23)
    round_tower(43,25,5,23)
end

local function side_wings()
    -- Ailes basses à colombages, pignons et toitures rouges/ardoise.
    for _,side in ipairs({-1,1}) do
        local x1,x2 = side<0 and -36 or 22, side<0 and -22 or 36
        fill(x1,1,-39,x2,13,-12,M.stone)
        clear(x1+2,2,-37,x2-2,11,-14)
        deck(x1+2,-37,x2-2,-14,1,M.floor)
        for z=-34,-18,8 do
            wall_x(x1+1,x2-1,2,9,z,M.wood,1)
            put(x1+1,5,z-1,M.glass); put(x2-1,5,z-1,M.glass)
        end
        -- Toiture à deux pans, pignon côté cour.
        gable(math.floor((x1+x2)/2),13,-12,18,8,27)
        for z=-35,-17,6 do
            put(side<0 and x2 or x1,6,z,M.glass)
            lantern(side<0 and x2-1 or x1+1,7,z)
        end
    end
end

local function house(cx,cz,roof)
    fill(cx-6,1,cz-5,cx+6,8,cz+5,M.wood)
    clear(cx-5,2,cz-4,cx+5,7,cz+4)
    deck(cx-5,cz-4,cx+5,cz+4,1,M.floor)
    -- Socle en pierre et colombages apparents.
    wall_x(cx-6,cx+6,2,2,cz-5,M.trim,1)
    wall_x(cx-6,cx+6,7,7,cz-5,M.trim,1)
    for x=cx-5,cx+5,5 do
        wall_x(x,x,2,7,cz-5,M.wood,1)
        put(x,4,cz-5,M.glass)
    end
    -- Porte et toit pentu.
    clear(cx-1,2,cz-5,cx+1,4,cz-5)
    for layer=0,3 do
        fill(cx-7+layer,9+layer,cz-6+layer,cx+7-layer,9+layer,cz+6-layer,roof)
    end
    fill(cx-1,12,cz-1,cx+1,13,cz+1,M.gold)
    lantern(cx,5,cz-4)
end

local function gardens_and_plaza()
    -- Parvis principal en pavés, aligné sur le portail.
    deck(-27,0,27,58,0,M.path)
    deck(-21,2,21,54,0,M.floor)
    -- Motif axial de la place.
    for z=2,54,2 do
        put(-2,1,z,M.trim); put(2,1,z,M.trim)
    end
    for x=-20,20,4 do
        put(x,1,4,M.trim); put(x,1,52,M.trim)
    end
    -- Bassin et fontaine à gauche de l'axe, dégagés de l'allée.
    deck(-16,22,-7,31,0,M.trim)
    fill(-14,23,24,-9,23,29,M.water)
    fill(-13,24,26,-10,26,27,M.trim)
    lantern(-12,27,26)
    -- Jardinières fleuries en bandes.
    for _,x in ipairs({-24,24}) do
        for z=7,47,8 do
            fill(x-2,1,z-2,x+2,1,z+2,M.trim)
            fill(x-1,2,z-1,x+1,2,z+1,M.leaves)
            put(x,3,z,M.gold)
        end
    end
    -- Haies, arbres et lanternes.
    local trees={{-31,8},{31,8},{-31,35},{31,35},{-27,51},{27,51},{-40,42},{40,42}}
    for _,p in ipairs(trees) do
        fill(p[1],1,p[2],p[1],5,p[2],M.wood)
        for dx=-3,3 do for dz=-3,3 do for dy=3,7 do
            if dx*dx+dz*dz+(dy-5)*(dy-5)<=12 then put(p[1]+dx,dy,p[2]+dz,M.leaves) end
        end end end
    end
    for _,p in ipairs({{-18,10},{18,10},{-18,43},{18,43},{-9,55},{9,55}}) do
        fill(p[1]-1,1,p[2]-1,p[1]+1,4,p[2]+1,M.trim)
        lantern(p[1],5,p[2]); put(p[1],6,p[2],M.gold)
    end
    -- Maisons de guilde et échoppes bordant la place.
    house(-30,17,M.roof)
    house(30,17,M.roof)
    house(-30,43,M.roof)
    house(30,43,M.roof)
    -- Bancs et petits étals.
    for _,p in ipairs({{-12,13},{12,13},{-12,42},{12,42}}) do
        fill(p[1]-2,1,p[2],p[1]+2,1,p[2],M.wood)
        put(p[1]-2,2,p[2],M.trim); put(p[1]+2,2,p[2],M.trim)
    end
end

local function entrance_details()
    -- Deux bannières bleues et or suspendues aux tours de la porte.
    for _,x in ipairs({-13,13}) do
        fill(x-2,17,-7,x+2,18,-7,M.gold)
        fill(x-1,12,-7,x+1,16,-7,M.roof)
        put(x,11,-7,M.gold)
        lantern(x,19,-7)
    end
    -- Fenêtres éclairées sur la façade des tours.
    for _,x in ipairs({-20,20}) do
        for y=8,24,8 do
            put(x,y,-11,M.glass)
            put(x,y+1,-11,M.gold)
        end
    end
    -- Escalier large et praticable devant le portail.
    for step=0,4 do
        deck(-8-step, -step+1, 8+step, -step+1, step, M.floor)
    end
    -- Pavillons de guilde avec leurs enseignes.
    for _,p in ipairs({{-30,17},{30,17},{-30,43},{30,43}}) do
        fill(p[1]-1,5,p[2]-6,p[1]+1,7,p[2]-6,M.gold)
        fill(p[1]-1,3,p[2]-6,p[1]+1,4,p[2]-6,M.roof)
    end
end


-- Éclairage intérieur dédié : les lanternes de décoration héritées ne suffisent
-- pas à éclairer les volumes fermés du donjon.
minetest.register_node("gdo_castle:refit_lamp", {
    description = S("Lanterne du château"),
    drawtype = "glasslike",
    tiles = {palette.refit_gold},
    paramtype = "light",
    sunlight_propagates = true,
    light_source = 14,
    groups = {cracky = 2, oddly_breakable_by_hand = 2},
})
minetest.register_node("gdo_castle:refit_chandelier", {
    description = S("Lustre royal"),
    tiles = {palette.refit_gold},
    paramtype = "light",
    sunlight_propagates = true,
    light_source = 15,
    groups = {cracky = 2},
})

local function lamp(x,y,z)
    put(x,y,z,"gdo_castle:refit_lamp")
end
local function chandelier(x,y,z)
    put(x,y,z,"gdo_castle:refit_chandelier")
    put(x,y+1,z,M.gold)
end
local function table_block(x1,y,z1,x2,z2)
    fill(x1,y,z1,x2,y,z2,M.wood)
    for x=x1,x2,math.max(1,x2-x1) do
        put(x,y-1,z1,M.trim); put(x,y-1,z2,M.trim)
    end
end

local function register_room_action(name, description, message, action)
    minetest.register_node(name, {
        description = S(description), tiles = {palette.refit_wood},
        groups = {choppy = 2, oddly_breakable_by_hand = 2},
        on_rightclick = function(pos, node, player)
            if not player or not player:is_player() then return end
            if action then action(player)
            else minetest.chat_send_player(player:get_player_name(), message) end
        end,
    })
end
register_room_action("gdo_castle:library_catalog", "Catalogue de la bibliothèque",
    "Catalogue : histoire du Royaume, bestiaire, recettes, cartes et grimoires. Les rayonnages sont encore en cours de classement.")
register_room_action("gdo_castle:training_dummy", "Mannequin d'entraînement",
    "Entraînement : frappe le mannequin pour t'exercer. Les compétences de combat seront reliées au système de progression.")
register_room_action("gdo_castle:forge_station", "Enclume de l'armurerie",
    "Forge : l'atelier est prêt à recevoir les recettes d'équipement. Pour l'instant, inspecte les râteliers et prépare tes matériaux.")
register_room_action("gdo_castle:kitchen_station", "Comptoir des cuisines",
    "Cuisine : le chef prépare le fameux ragoût de navet. Il soigne les aventuriers dès que le système de nourriture sera activé.")
register_room_action("gdo_castle:throne", "Trône du Royaume",
    "Le trône grince. Une voix murmure : « Le pouvoir, c'est surtout remplir des formulaires. »")
register_room_action("gdo_castle:healing_fountain", "Fontaine de soin", "",
    function(player)
        local hp = player:get_hp()
        player:set_hp(math.min(20, hp + 4), {type = "set_hp", from = "gdo_castle:healing_fountain"})
        minetest.chat_send_player(player:get_player_name(), "La fontaine apaise tes blessures. +4 PV (dans la limite de 20).")
    end)

local function build_interiors()
    -- REZ-DE-CHAUSSÉE : vestibule, salle du trône et salle du conseil.
    deck(-14,-45,14,-20,1,M.floor)
    -- Tapis d'apparat menant au trône.
    fill(-2,2,-44,2,2,-22,M.roof)
    fill(-1,2,-44,1,2,-22,M.gold)
    -- Colonnes jumelées et arcs décoratifs.
    for _,x in ipairs({-12,-8,8,12}) do
        fill(x,2,-43,x,7,-43,M.trim)
        fill(x,2,-23,x,7,-23,M.trim)
        put(x,8,-43,M.gold); put(x,8,-23,M.gold)
    end
    -- Estrade et trône au nord.
    put(0,4,-44,"gdo_castle:throne")
    fill(-5,2,-45,5,3,-41,M.trim)
    fill(-2,4,-45,2,5,-44,M.wood)
    fill(-2,6,-45,2,7,-45,M.gold)
    fill(-1,4,-43,1,5,-43,M.roof)
    -- Bancs latéraux et tables de réception.
    for z=-38,-28,5 do
        table_block(-11,3,z,-6,z+1)
        table_block(6,3,z,11,z+1)
    end
    -- Cloisons basses avec passages pour créer des espaces lisibles.
    wall_z(-40,-39,2,7,-14,M.trim,1)
    wall_z(-40,-39,2,7,14,M.trim,1)
    clear(-2,2,-40,2,4,-39)
    -- Lustres suspendus et appliques.
    for _,p in ipairs({{-8,6,-34},{0,6,-34},{8,6,-34},{-8,6,-25},{0,6,-25},{8,6,-25}}) do
        chandelier(p[1],p[2],p[3])
    end
    for _,p in ipairs({{-14,4,-35},{14,4,-35},{-14,4,-25},{14,4,-25}}) do lamp(p[1],p[2],p[3]) end
    -- Étage noble : bibliothèque à gauche, armurerie à droite, salle du conseil au fond.
    deck(-14,-45,14,-20,9,M.floor)
    wall_x(-14,14,10,15,-33,M.trim,1)
    clear(-2,10,-33,2,12,-33)
    wall_z(-32,-20,10,15,0,M.trim,1)
    clear(-2,10,-25,2,12,-20)
    -- Bibliothèque : rayonnages, échelle et tables de lecture.
    put(-8,11,-26,"gdo_castle:library_catalog")
    for z=-43,-35,3 do
        fill(-13,10,z,-12,14,z+1,M.wood)
        fill(-10,10,z,-9,14,z+1,M.wood)
    end
    for x=-11,-9,2 do
        fill(x,10,-30,x,14,-29,M.wood)
    end
    table_block(-11,11,-26,-6,-25)
    lamp(-8,14,-28); lamp(-13,14,-38)
    -- Armurerie : râteliers, coffres et mannequins stylisés.
    put(11,10,-28,"gdo_castle:training_dummy")
    put(8,10,-28,"gdo_castle:forge_station")
    for z=-43,-35,4 do
        fill(9,10,z,13,11,z,M.wood)
        for x=10,12 do put(x,12,z,M.gold) end
    end
    fill(7,10,-29,13,11,-27,M.wood)
    lamp(12,14,-30); lamp(8,14,-40)
    -- Salle du conseil : grande table, sièges et lustre central.
    table_block(-5,11,-24,5,-22)
    for x=-4,4,2 do
        put(x,10,-26,M.wood); put(x,10,-20,M.wood)
    end
    chandelier(0,14,-23)
    -- Niveau supérieur : observatoire et chapelle des novices.
    deck(-14,-45,14,-20,17,M.floor)
    wall_x(-14,14,18,22,-33,M.trim,1)
    clear(-2,18,-33,2,20,-33)
    -- Chapelle : autel, vitraux et rangées de bancs.
    fill(-11,18,-43,11,19,-41,M.trim)
    fill(-3,20,-43,3,21,-42,M.gold)
    for z=-38,-34,2 do
        fill(-9,18,z,-5,18,z,M.wood)
        fill(5,18,z,9,18,z,M.wood)
    end
    for x=-10,-6,4 do put(x,21,-44,M.glass) end
    for x=6,10,4 do put(x,21,-44,M.glass) end
    chandelier(0,21,-32); lamp(-12,21,-25); lamp(12,21,-25)
    -- Passerelles de circulation, portes ouvertes et garde-corps.
    fill(-14,18,-31,-4,18,-30,M.wood)
    fill(4,18,-31,14,18,-30,M.wood)
    for x=-14,14,2 do
        put(x,19,-30,M.trim)
    end

    -- AILE OUEST : cuisine, cellier et réfectoire.
    deck(-34,-37,-24,-14,1,M.floor)
    fill(-33,2,-36,-25,2,-35,M.wood)
    fill(-33,2,-19,-25,2,-18,M.wood)
    -- Four et cheminée (lumière chaude).
    put(-28,3,-30,"gdo_castle:kitchen_station")
    fill(-33,2,-33,-30,4,-30,M.trim)
    fill(-32,3,-32,-31,4,-31,M.roof)
    lamp(-31,5,-31)
    -- Plans de travail, tonneaux et tables.
    table_block(-29,3,-32,-25,-31)
    table_block(-33,3,-25,-29,-24)
    for _,p in ipairs({{-25,-35},{-25,-21},{-33,-21}}) do
        fill(p[1],2,p[2],p[1]+1,4,p[2]+1,M.wood)
    end
    chandelier(-29,7,-25); lamp(-26,7,-35)
    -- AILE EST : dortoir, lits et coffres.
    deck(24,-37,34,-14,1,M.floor)
    for z=-34,-18,5 do
        fill(25,2,z,27,2,z+2,M.roof)
        fill(25,3,z,27,3,z,M.trim)
        fill(31,2,z,33,2,z+2,M.roof)
        fill(31,3,z,33,3,z,M.trim)
        put(26,4,z+1,M.gold); put(32,4,z+1,M.gold)
    end
    fill(28,2,-28,30,3,-27,M.wood)
    fill(28,2,-20,30,3,-19,M.wood)
    chandelier(29,7,-26); lamp(25,7,-16); lamp(33,7,-36)

    -- Les lampes sont volontairement réparties dans chaque pièce, pas seulement
    -- sur les façades : recalcul lumière effectué après la génération.
end

local function build()
    -- Nettoyage de l'ancienne emprise, y compris l'ancien château enterré.
    clear(-54,-12,-60,54,82,82)
    fill(-54,-1,-60,54,-1,82,"gdo_core:terre")
    deck(-54,-60,54,82,0,M.grass)

    -- Le château est posé au niveau du sol naturel (y=0), pas sur un plateau aérien.
    gardens_and_plaza()
    side_wings()
    main_keep()
    build_interiors()
    front_gate()
    entrance_details()

    -- Sol et cheminement depuis le point d'arrivée historique (0,64).
    deck(-15,56,15,78,0,M.floor)
    deck(-3,40,3,64,0,M.path)
    for z=57,74,3 do
        put(-12,1,z,M.trim); put(12,1,z,M.trim)
    end
    -- Accès ouvert : aucun mur transversal ne ferme la sortie.
    clear(-5,1,36,5,8,39)
    -- Panneau d'accueil et jardinet des navets.
    put(0,1,75,"gdo_castle:arrival_sign")
    deck(-16,37,-9,47,0,M.grass)
    put(-13,1,40,"gdo_core:navet_sur_pied")
    put(-13,1,42,"gdo_core:navet_sur_pied")
    put(-15,1,41,"gdo_core:navet_sur_pied")

    if minetest.fix_light then
        minetest.fix_light({x=-54,y=OFFSET-2,z=-60},{x=54,y=OFFSET+82,z=82})
        minetest.fix_light({x=-40,y=OFFSET+1,z=-52},{x=40,y=OFFSET+60,z=64})
    end
    if minetest.set_timeofday then minetest.set_timeofday(0.5) end
    minetest.log("action","[GDO] Château des Brumes v5 généré : donjon, tours rondes, porte monumentale et parvis.")
end

local storage = gdo_castle_storage
local VERSION = 8
local function generate_if_needed()
    if not storage or storage:get_int("refit_version") < VERSION then
        build()
        if storage then storage:set_int("refit_version",VERSION) end
    end
end

minetest.register_on_mods_loaded(function()
    minetest.after(5,generate_if_needed)
end)

minetest.register_chatcommand("refairechateau",{
    description="Reconstruit le Château des Brumes (version architecturale 5)",
    privs={server=true},
    func=function()
        build()
        if storage then storage:set_int("refit_version",VERSION) end
        return true,"Château des Brumes v5 reconstruit. Retourne sur le parvis sud."
    end,
})
