-- GDO — Refonte du Château des Brumes
-- Architecture compacte, lisible et praticable. Aucun mod externe requis.

local modname = minetest.get_current_modname()
local S = minetest.get_translator and minetest.get_translator(modname) or function(s) return s end

local M = {
    stone = "gdo_castle:refit_stone",
    trim = "gdo_castle:refit_trim",
    roof = "gdo_castle:refit_roof",
    floor = "gdo_castle:refit_floor",
    wood = "gdo_castle:refit_wood",
    glass = "gdo_castle:refit_glass",
    gold = "gdo_castle:refit_gold",
    grass = "gdo_castle:refit_grass",
    path = "gdo_castle:refit_path",
    leaves = "gdo_castle:refit_leaves",
    water = "gdo_castle:refit_water",
}

local function node(name, desc, color, groups, extra)
    local def = {
        description = S(desc),
        tiles = {name:match(":(.+)$") .. ".png"},
        groups = groups or {cracky = 2},
    }
    if extra then
        for k, v in pairs(extra) do def[k] = v end
    end
    minetest.register_node(name, def)
end

node(M.stone, "Calcaire du Château", "#9a9ba4")
node(M.trim, "Pierre sculptée", "#d0c8b8")
node(M.roof, "Ardoise bleu nuit", "#343d55")
node(M.floor, "Dallage clair", "#b7b2a8")
node(M.wood, "Chêne brun", "#68452f", {choppy = 2})
node(M.glass, "Vitrail doré", "#e9bd62", {cracky = 2}, {
    paramtype = "light", sunlight_propagates = true, light_source = 5,
})
node(M.gold, "Ornement royal", "#d7a844")
node(M.grass, "Gazon du parvis", "#56834a", {crumbly = 3, soil = 1})
node(M.path, "Pavés du royaume", "#817f83")
node(M.leaves, "Feuillage", "#3e7544", {snappy = 3}, {
    drawtype = "allfaces_optional", paramtype = "light", sunlight_propagates = true,
})
node(M.water, "Bassin décoratif", "#527f9b", {cracky = 3}, {
    drawtype = "liquid", paramtype = "light", sunlight_propagates = true,
    walkable = false, pointable = false, buildable_to = true,
    liquidtype = "source", liquid_alternative_flowing = "gdo_castle:refit_water_flowing",
    liquid_alternative_source = "gdo_castle:refit_water",
    liquid_viscosity = 1, liquid_renewable = false,
})
minetest.register_node("gdo_castle:refit_water_flowing", {
    description = S("Eau décorative"), tiles = {"refit_water.png"},
    drawtype = "flowingliquid", paramtype = "light", paramtype2 = "flowingliquid",
    groups = {not_in_creative_inventory = 1}, walkable = false, pointable = false,
    buildable_to = true, drop = "", liquidtype = "flowing",
    liquid_alternative_flowing = "gdo_castle:refit_water_flowing",
    liquid_alternative_source = "gdo_castle:refit_water",
    liquid_viscosity = 1,
})

local HEIGHT_OFFSET = 24
local function put(x,y,z,n)
    minetest.set_node({x=x,y=y + HEIGHT_OFFSET,z=z},{name=n})
end
local function fill(x1,y1,z1,x2,y2,z2,n)
    for x=math.min(x1,x2),math.max(x1,x2) do
        for y=math.min(y1,y2),math.max(y1,y2) do
            for z=math.min(z1,z2),math.max(z1,z2) do put(x,y,z,n) end
        end
    end
end
local function clear(x1,y1,z1,x2,y2,z2)
    fill(x1,y1,z1,x2,y2,z2,"air")
end
local function floor(x1,z1,x2,z2,y,n) fill(x1,y,z1,x2,y,z2,n) end

local function tower(cx,cz,r,h)
    -- Tour carrée à pans coupés, avec corniche et toit pyramidal.
    for y=1,h do
        for x=-r,r do for z=-r,r do
            if math.max(math.abs(x),math.abs(z))==r
                or (math.abs(x)==r-1 and math.abs(z)==r-1) then
                put(cx+x,y,cz+z,M.stone)
            end
        end end
    end
    for y=4,h-3,5 do
        put(cx,y,cz-r,M.glass); put(cx,y,cz+r,M.glass)
        put(cx-r,y,cz,M.glass); put(cx+r,y,cz,M.glass)
    end
    for x=-r,r do for z=-r,r do
        if math.max(math.abs(x),math.abs(z))==r and (x+z)%2==0 then
            put(cx+x,h+1,cz+z,M.trim)
        end
    end end
    for layer=0,r+1 do
        local rr=r-layer
        if rr>=0 then
            for x=-rr,rr do for z=-rr,rr do
                if math.max(math.abs(x),math.abs(z))==rr then
                    put(cx+x,h+2+layer,cz+z,M.roof)
                end
            end end
        end
    end
    put(cx,h+r+3,cz,M.gold)
end

local function tree(x,z)
    fill(x,1,z,x,5,z,M.wood)
    for dx=-2,2 do for dz=-2,2 do for dy=3,6 do
        if dx*dx+dz*dz+(dy-4)*(dy-4)<=9 then
            put(x+dx,dy,z+dz,M.leaves)
        end
    end end end
end

local function build()
    -- Nettoyage strict du chantier : retire les anciens volumes et les pièges.
    clear(-52,-8,-58,52,70,85)
    fill(-52,-1,-58,52,-1,85,"gdo_core:terre")
    floor(-52,-58,52,85,0,M.grass)

    -- Grande enceinte et cour au même niveau que le terrain.
    floor(-38,-34,38,28,0,M.floor)
    floor(-4,28,4,68,0,M.path)
    floor(-13,54,13,75,0,M.floor)
    for x=-38,38 do
        if x < -5 or x > 5 then
            fill(x,1,30,x,9,31,M.stone)
            if x%4==0 then fill(x,10,30,x,11,31,M.trim) end
        end
    end
    fill(-38,1,-48,-37,10,31,M.stone)
    fill(37,1,-48,38,10,31,M.stone)
    fill(-38,1,-48,38,1,-47,M.stone)
    for x=-38,38,2 do
        put(x,11,31,M.trim)
        put(x,11,-47,M.trim)
    end
    for z=-46,30,2 do
        put(-38,11,z,M.trim); put(38,11,z,M.trim)
    end

    -- Porte ouverte : deux tours et un arc haut, aucun bloc dans le passage.
    fill(-8,1,28,-6,17,33,M.stone)
    fill(6,1,28,8,17,33,M.stone)
    fill(-8,17,28,8,19,33,M.trim)
    fill(-5,1,28,5,7,33,"air")
    for x=-5,5 do put(x,8,28,M.gold); put(x,8,33,M.gold) end
    tower(-7,30,3,18); tower(7,30,3,18)
    -- Remparts crénelés.
    for x=-36,36,2 do
        if x < -5 or x > 5 then put(x,12,31,M.trim) end
    end

    -- Donjon principal : volumes creux, fenêtres alignées, façade sud.
    fill(-15,1,-44,15,20,-14,M.stone)
    clear(-13,2,-42,13,18,-16)
    floor(-13,-42,13,-16,1,M.floor)
    floor(-13,-42,13,-16,9,M.wood)
    floor(-13,-42,13,-16,16,M.wood)
    -- Façade sud ouverte et encadrée.
    clear(-3,1,-14,3,8,-13)
    fill(-5,8,-14,5,9,-13,M.trim)
    for x=-11,11,4 do
        put(x,5,-14,M.glass); put(x,12,-14,M.glass)
    end
    for z=-40,-18,4 do
        put(-15,5,z,M.glass); put(15,5,z,M.glass)
        put(-15,12,z,M.glass); put(15,12,z,M.glass)
    end
    -- Toit à quatre pans en retraits successifs.
    for layer=0,7 do
        local inset=layer*2
        fill(-16+inset,21+layer,-45+inset,16-inset,21+layer,-13-inset,M.roof)
    end
    for x=-14,14,2 do put(x,21,-13,M.trim) end

    -- Quatre tours du donjon, légèrement décalées en hauteur.
    tower(-15,-44,4,27); tower(15,-44,4,31)
    tower(-15,-14,4,24); tower(15,-14,4,28)

    -- Ailes basses, plus larges, avec pignons et galeries.
    fill(-29,1,-39,-19,13,-17,M.stone)
    clear(-27,2,-37,-21,11,-19)
    floor(-27,-37,-21,-19,1,M.floor)
    fill(19,1,-39,29,13,-17,M.stone)
    clear(21,2,-37,27,11,-19)
    floor(21,-37,27,-19,1,M.floor)
    tower(-24,-38,3,18); tower(-24,-17,3,16)
    tower(24,-38,3,20); tower(24,-17,3,17)

    -- Arcades et piliers qui relient les ailes à la cour.
    for z=-12,20,8 do
        fill(-30,1,z,-30,7,z,M.trim)
        fill(30,1,z,30,7,z,M.trim)
        fill(-30,8,z,-30,8,z+3,M.roof)
        fill(30,8,z,30,8,z+3,M.roof)
    end

    -- Pavillons des quatre maisons, de part et d'autre de la cour.
    local houses={{-25,-3,"#b84a35"},{25,-3,"#536eb5"},{-25,15,"#4d986a"},{25,15,"#c49b39"}}
    for _,p in ipairs(houses) do
        local x,z=p[1],p[2]
        fill(x-5,1,z-4,x+5,7,z+4,M.stone)
        clear(x-4,2,z-3,x+4,6,z+3)
        floor(x-4,z-3,x+4,z+3,1,M.floor)
        fill(x-5,7,z-4,x+5,7,z+4,M.roof)
        put(x,4,z-4,M.gold)
        put(x,4,z+4,M.gold)
    end

    -- Place centrale, fontaines et jardins.
    floor(-8,-8,8,8,0,M.trim)
    for x=-6,6 do put(x,1,0,M.gold) end
    for z=-6,6 do put(0,1,z,M.gold) end
    for _,x in ipairs({-27,27}) do
        floor(x-3,-2,x+3,2,0,M.trim)
        fill(x-2,1,-1,x+2,1,1,M.water)
        put(x,2,0,M.gold)
    end
    for _,p in ipairs({{-33,-28},{33,-28},{-33,20},{33,20},{-18,24},{18,24}}) do
        tree(p[1],p[2])
    end
    -- Haies et massifs, sans obstruer les allées.
    for x=-32,32,4 do
        if math.abs(x)>10 then
            put(x,1,22,M.leaves); put(x,2,22,M.leaves)
        end
    end

    -- Place d'arrivée dégagée au sud, avec allée continue vers la porte.
    floor(-12,55,12,75,0,M.floor)
    floor(-3,32,3,56,0,M.path)
    for x=-9,9,3 do
        put(x,1,59,M.gold); put(x,1,71,M.gold)
    end
    for _,x in ipairs({-10,10}) do
        fill(x-1,1,62,x+1,4,64,M.trim)
        put(x,5,63,"gdo_castle:castle_lantern")
        put(x,6,63,M.gold)
    end
    put(0,1,73,"gdo_castle:arrival_sign")

    -- Petit jardin des navets à côté de l'entrée, sur un sol praticable.
    floor(-12,35,-6,44,0,M.grass)
    put(-9,1,38,"gdo_core:navet_sur_pied")
    put(-9,1,40,"gdo_core:navet_sur_pied")
    put(-11,1,39,"gdo_core:navet_sur_pied")

    -- Détails architecturaux : contreforts, bandeaux, fenêtres profondes,
    -- balcons, enseignes et éclairage régulier pour casser les grands aplats.
    -- Donjon : soubassement, corniches et pilastres verticaux.
    for x=-16,16,8 do
        fill(x,1,-45,x+1,4,-14,M.trim)
        fill(x,19,-45,x+1,20,-14,M.trim)
        for y=5,15,5 do
            put(x,y,-14,M.gold)
        end
    end
    for z=-40,-18,6 do
        fill(-16,8,z,-16,9,z+2,M.trim)
        fill(16,8,z,16,9,z+2,M.trim)
    end
    -- Fenêtres en alcôve avec linteaux et appuis.
    for x=-12,12,4 do
        for _,y in ipairs({5,12}) do
            fill(x-1,y-1,-15,x+1,y-1,-15,M.trim)
            fill(x-1,y+1,-15,x+1,y+1,-15,M.trim)
            put(x,y,-15,M.glass)
        end
    end
    -- Balcon royal au-dessus de l'entrée du donjon.
    fill(-7,10,-12,7,10,-10,M.trim)
    for x=-7,7,2 do
        put(x,11,-10,M.wood)
        put(x,12,-10,M.trim)
    end
    fill(-8,13,-12,8,13,-10,M.roof)
    -- Pignons et lucarnes du toit.
    for _,x in ipairs({-9,0,9}) do
        fill(x-2,22,-30,x+2,22,-26,M.trim)
        fill(x-1,23,-29,x+1,24,-27,M.roof)
        put(x,25,-28,M.gold)
    end

    -- Remparts : merlons alternés et chemins de ronde lisibles.
    for x=-36,36,2 do
        if x < -5 or x > 5 then
            fill(x,12,30,x,13,31,M.trim)
            if x%6==0 then put(x,14,30,M.gold) end
        end
    end
    for z=-44,28,4 do
        fill(-37,12,z,-37,13,z,M.trim)
        fill(37,12,z,37,13,z,M.trim)
    end

    -- Porte monumentale : voussoirs contrastés et deux lanternes.
    for x=-5,5 do
        local arch_y = 8 + math.floor(3 * (1 - math.abs(x)/5))
        put(x,arch_y,28,M.trim)
        put(x,arch_y,33,M.trim)
    end
    for _,x in ipairs({-9,9}) do
        fill(x-1,1,29,x+1,15,32,M.trim)
        for y=4,12,4 do put(x,y,28,M.glass) end
        put(x,16,30,M.gold)
        put(x,17,30,"gdo_castle:castle_lantern")
    end

    -- Cour : bandes de pavés, bancs, jardinières et lanternes.
    for z=-30,24,6 do
        for x=-34,34 do
            if math.abs(x)>10 and x%2==0 then put(x,1,z,M.path) end
        end
    end
    for _,p in ipairs({{-16,-4},{16,-4},{-16,17},{16,17}}) do
        local x,z=p[1],p[2]
        fill(x-2,1,z-2,x+2,1,z+2,M.trim)
        fill(x-1,2,z-1,x+1,2,z+1,M.leaves)
        put(x,3,z,"gdo_castle:castle_lantern")
    end
    -- Bancs près de la fontaine.
    for _,x in ipairs({-11,11}) do
        fill(x-2,1,-2,x+2,1,-2,M.wood)
        put(x-2,2,-2,M.trim); put(x+2,2,-2,M.trim)
    end

    -- Façades des pavillons : colombages, enseignes et petites toitures à pignons.
    for _,p in ipairs({{-25,-3},{25,-3},{-25,15},{25,15}}) do
        local x,z=p[1],p[2]
        for dx=-4,4,4 do
            fill(x+dx,2,z-4,x+dx,6,z-4,M.wood)
        end
        fill(x-5,6,z-5,x+5,6,z-4,M.trim)
        fill(x-3,8,z-3,x+3,8,z+3,M.roof)
        fill(x-2,9,z-2,x+2,9,z+2,M.roof)
        put(x,10,z,M.gold)
        put(x,4,z-5,M.glass)
        put(x,5,z-5,M.gold)
        put(x,3,z+5,"gdo_castle:castle_lantern")
    end

    -- Jardins d'entrée : haies, fleurs stylisées et lampadaires.
    for _,z in ipairs({57,73}) do
        for x=-8,8,4 do
            put(x,1,z,M.leaves)
            put(x,2,z,M.leaves)
            put(x,3,z,"gdo_castle:castle_lantern")
        end
    end
    for _,p in ipairs({{-11,55},{11,55},{-11,74},{11,74}}) do
        put(p[1],1,p[2],M.gold)
        put(p[1],2,p[2],"gdo_castle:castle_lantern")
    end

    -- Le terrain autour du château reste horizontal et dégagé.
    fill(-52,-1,-58,52,-1,85,"gdo_core:terre")
    if minetest.fix_light then
        minetest.fix_light({x=-52,y=16,z=-58},{x=52,y=94,z=85})
    end
    if minetest.set_timeofday then minetest.set_timeofday(0.5) end
    minetest.log("action","[GDO] Refonte du Château des Brumes construite au-dessus du terrain (version 3).")
end

local storage = minetest.get_mod_storage and minetest.get_mod_storage() or nil
minetest.register_on_mods_loaded(function()
    minetest.after(5,function()
        if not storage or storage:get_int("refit_version") < 3 then
            build()
            if storage then storage:set_int("refit_version",3) end
        end
    end)
end)

minetest.register_chatcommand("refairechateau", {
    description = "Reconstruit le Château des Brumes",
    privs = {server = true},
    func = function()
        build()
        if storage then storage:set_int("refit_version",3) end
        return true, "Le Château des Brumes a été reconstruit."
    end,
})
