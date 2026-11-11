-- GDO — Château des Brumes
-- Nouvelle génération inspirée du plan historique du château de Dourdan.
-- Modules de construction indépendants : enceinte, logis, donjon, châtelet,
-- cour et parvis. Les liaisons sont taillées dans une passe finale.
-- Dimensions en nodes ; origine au centre de la cour.

local modname = minetest.get_current_modname()
local S = minetest.get_translator and minetest.get_translator(modname) or function(s) return s end

-- Altitude absolue du plateau. Toutes les coordonnées du plan restent relatives.
local BASE_Y = 0

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
    lamp = "gdo_castle:refit_lamp",
    stair = "gdo_castle:refit_stair",
    stair_low = "gdo_castle:refit_stair_low",
    stair_high = "gdo_castle:refit_stair_high",
    table = "gdo_castle:refit_table",
    bench = "gdo_castle:refit_bench",
    rug = "gdo_castle:refit_rug",
    pillar = "gdo_castle:refit_pillar",
}

local textures = {
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

local function register_textured(name, description, groups, extra)
    local short = name:match(":(.+)$")
    local def = {
        description = S(description),
        tiles = {textures[short] or textures.refit_stone},
        groups = groups or {cracky = 2},
    }
    if extra then
        for k,v in pairs(extra) do def[k] = v end
    end
    minetest.register_node(name, def)
end

register_textured(M.stone, "Calcaire du château")
register_textured(M.trim, "Pierre de taille")
register_textured(M.roof, "Ardoise bleue")
register_textured(M.floor, "Dallage intérieur")
register_textured(M.wood, "Chêne ancien", {choppy = 2})
register_textured(M.glass, "Vitrail", {cracky = 2}, {
    drawtype = "glasslike",
    paramtype = "light",
    sunlight_propagates = true,
    use_texture_alpha = "blend",
})
register_textured(M.gold, "Ornement doré")
register_textured(M.grass, "Gazon", {crumbly = 3, soil = 1})
register_textured(M.path, "Pavés", {cracky = 2})
register_textured(M.leaves, "Feuillage", {snappy = 3}, {
    drawtype = "allfaces_optional",
    paramtype = "light",
    sunlight_propagates = true,
})
register_textured(M.water, "Eau du fossé", {cracky = 3}, {
    drawtype = "glasslike",
    paramtype = "light",
    sunlight_propagates = true,
    walkable = false,
    pointable = false,
})
-- Lanterne compacte en nodebox : source lumineuse visible, sans occuper
-- tout le bloc ni gêner la circulation. Compatible Luanti 5.4.1.
minetest.register_node(M.lamp, {
    description = S("Lanterne murale"),
    drawtype = "nodebox",
    tiles = {textures.refit_gold},
    paramtype = "light",
    sunlight_propagates = true,
    light_source = 14,
    walkable = false,
    groups = {cracky = 2, oddly_breakable_by_hand = 2},
    node_box = {
        type = "fixed",
        fixed = {
            {-0.22,-0.22,-0.22,0.22,0.22,0.22},
            {-0.08,-0.5,-0.08,0.08,-0.22,0.08},
        },
    },
    selection_box = {
        type = "fixed",
        fixed = {-0.22,-0.22,-0.22,0.22,0.22,0.22},
    },
})

-- Deux vantaux de chêne représentés ouverts contre les piédroits :
-- ils restent visibles, mais ne barrent jamais le passage central.
local function register_open_gate_leaf(name, side)
    local x1,x2
    if side == "left" then
        x1,x2 = 0.28,0.46
    else
        x1,x2 = -0.46,-0.28
    end
    minetest.register_node(name, {
        description = S("Vantail de porte ouvert"),
        drawtype = "nodebox",
        tiles = {textures.refit_wood},
        paramtype = "light",
        sunlight_propagates = true,
        walkable = false,
        groups = {choppy = 2, not_in_creative_inventory = 1},
        node_box = {type = "fixed", fixed = {x1,-0.5,-0.5,x2,0.5,0.5}},
        selection_box = {type = "fixed", fixed = {x1,-0.5,-0.5,x2,0.5,0.5}},
    })
end
register_open_gate_leaf("gdo_castle:open_gate_left", "left")
register_open_gate_leaf("gdo_castle:open_gate_right", "right")
local function register_step_node(name, description, box)
    minetest.register_node(name, {
        description = S(description),
        drawtype = "nodebox",
        tiles = {textures.refit_trim},
        paramtype = "light",
        sunlight_propagates = true,
        walkable = true,
        groups = {cracky = 2},
        node_box = {type = "fixed", fixed = {box}},
        collision_box = {type = "fixed", fixed = {box}},
        selection_box = {type = "fixed", fixed = {box}},
    })
end

-- Deux demi-blocs complémentaires : le joueur monte de 0,5 node par palier.
register_step_node(M.stair_low, "Marche basse en pierre",
    {-0.5,-0.5,-0.5,0.5,0,0.5})
register_step_node(M.stair_high, "Marche haute en pierre",
    {-0.5,0,-0.5,0.5,0.5,0.5})

-- Marche de progression à hauteur variable : base pleine, surface réglée par
-- param2 (32 = demi-bloc, 64 = bloc plein). Pas de demi-bloc flottant.
minetest.register_node(M.stair, {
    description = S("Marche de tour en pierre"),
    drawtype = "nodebox",
    tiles = {textures.refit_trim},
    paramtype = "light",
    paramtype2 = "leveled",
    leveled_max = 64,
    sunlight_propagates = true,
    walkable = true,
    groups = {cracky = 2},
    node_box = {
        type = "leveled",
        fixed = {-0.5,-0.5,-0.5,0.5,0,0.5},
    },
    collision_box = {
        type = "leveled",
        fixed = {-0.5,-0.5,-0.5,0.5,0,0.5},
    },
    selection_box = {
        type = "leveled",
        fixed = {-0.5,-0.5,-0.5,0.5,0,0.5},
    },
})

local function register_furniture(name, description, texture, boxes, walkable)
    minetest.register_node(name, {
        description = S(description),
        drawtype = "nodebox",
        tiles = {texture},
        paramtype = "light",
        sunlight_propagates = true,
        walkable = walkable ~= false,
        groups = {cracky = 2, oddly_breakable_by_hand = 2},
        node_box = {type = "fixed", fixed = boxes},
        collision_box = {type = "fixed", fixed = boxes},
        selection_box = {type = "fixed", fixed = boxes},
    })
end

register_furniture(M.table, "Table de banquet", textures.refit_wood, {
    {-0.44,-0.42,-0.44,-0.32,0.16,-0.32},
    {0.32,-0.42,-0.44,0.44,0.16,-0.32},
    {-0.44,-0.42,0.32,-0.32,0.16,0.44},
    {0.32,-0.42,0.32,0.44,0.16,0.44},
    {-0.5,0.16,-0.5,0.5,0.28,0.5},
})
register_furniture(M.bench, "Banc de chêne", textures.refit_wood, {
    {-0.44,-0.5,-0.36,-0.32,-0.05,-0.24},
    {0.32,-0.5,-0.36,0.44,-0.05,-0.24},
    {-0.44,-0.5,0.24,-0.32,-0.05,0.36},
    {0.32,-0.5,0.24,0.44,-0.05,0.36},
    {-0.5,-0.05,-0.42,0.5,0.08,0.42},
})
register_furniture(M.rug, "Tapis du seigneur", textures.refit_roof, {
    {-0.5,-0.49,-0.5,0.5,-0.45,0.5},
}, false)
register_furniture(M.pillar, "Colonne sculptée", textures.refit_trim, {
    {-0.22,-0.5,-0.22,0.22,0.5,0.22},
    {-0.38,-0.5,-0.38,0.38,-0.34,0.38},
    {-0.34,0.34,-0.34,0.34,0.5,0.34},
})

local function put(x,y,z,name,param2)
    minetest.set_node({x=x,y=y+BASE_Y,z=z}, {name=name, param2=param2 or 0})
end

local function fill(x1,y1,z1,x2,y2,z2,name)
    for x=math.min(x1,x2),math.max(x1,x2) do
        for y=math.min(y1,y2),math.max(y1,y2) do
            for z=math.min(z1,z2),math.max(z1,z2) do
                put(x,y,z,name)
            end
        end
    end
end

local function clear(x1,y1,z1,x2,y2,z2)
    fill(x1,y1,z1,x2,y2,z2,"air")
end

local function deck(x1,z1,x2,z2,y,name)
    fill(x1,y,z1,x2,y,z2,name)
end

local function wall_x(x1,x2,y1,y2,z,name,thickness)
    fill(x1,y1,z,x2,y2,z+(thickness or 1)-1,name)
end

local function wall_z(z1,z2,y1,y2,x,name,thickness)
    fill(x,y1,z1,x+(thickness or 1)-1,y2,z2,name)
end

local function disk_floor(cx,cz,r,y,name)
    for x=-r,r do
        for z=-r,r do
            -- Surface strictement intérieure : ne jamais remplacer l'anneau porteur.
            if x*x+z*z < r*r then put(cx+x,y,cz+z,name) end
        end
    end
end

local function lamp(x,y,z)
    put(x,y,z,M.lamp)
end

local function round_number(n)
    if n >= 0 then return math.floor(n+0.5) end
    return math.ceil(n-0.5)
end

-- Trace une ligne en 4-connexité : aucune marche diagonale isolée.
local function append_line(path, ax, az, bx, bz, skip_finish)
    local dx, dz = bx-ax, bz-az
    local count = math.max(math.abs(dx), math.abs(dz))
    local px, pz = ax, az
    for step=1,count do
        local nx = round_number(ax + dx*step/count)
        local nz = round_number(az + dz*step/count)
        local ddx, ddz = nx-px, nz-pz
        if math.abs(ddx) == 1 and math.abs(ddz) == 1 then
            local mx, mz = nx, pz
            if #path == 0 or path[#path].x ~= mx or path[#path].z ~= mz then
                path[#path+1] = {x=mx,z=mz}
            end
        end
        local is_finish = step == count
        if not (skip_finish and is_finish) then
            if #path == 0 or path[#path].x ~= nx or path[#path].z ~= nz then
                path[#path+1] = {x=nx,z=nz}
            end
        end
        px, pz = nx, nz
    end
end

local function make_octagonal_ring(radius, entry_side)
    local diagonal = math.max(1, math.floor(radius*0.707+0.5))
    local vertices = {
        {x=0,z=-radius}, {x=diagonal,z=-diagonal},
        {x=radius,z=0}, {x=diagonal,z=diagonal},
        {x=0,z=radius}, {x=-diagonal,z=diagonal},
        {x=-radius,z=0}, {x=-diagonal,z=-diagonal},
    }
    local first = {north=1,east=3,south=5,west=7}
    local start = first[entry_side] or 5
    local path = {}
    for k=0,7 do
        local ai = ((start+k-1)%8)+1
        local bi = ((start+k)%8)+1
        local a,b = vertices[ai],vertices[bi]
        local final_segment = k == 7
        append_line(path,a.x,a.z,b.x,b.z,final_segment)
    end

    -- append_line omet le sommet de départ pour éviter un doublon.
    -- On referme explicitement l'anneau avec les cellules orthogonales manquantes.
    local first = path[1]
    local last = path[#path]
    local dx,dz = first.x-last.x,first.z-last.z
    while math.abs(dx)+math.abs(dz) > 1 do
        if dx ~= 0 then
            last = {x=last.x+(dx>0 and 1 or -1),z=last.z}
        else
            last = {x=last.x,z=last.z+(dz>0 and 1 or -1)}
        end
        path[#path+1] = last
        dx,dz = first.x-last.x,first.z-last.z
    end
    return path
end

local staircase_cells = {}

local function place_spiral_stair(cx,cz,r,height,entry_side)
    local radius = r-3
    local ring = make_octagonal_ring(radius,entry_side)
    local count = #ring
    if count < 16 then
        minetest.log("error","[GDO] Anneau d'escalier trop court pour une tour.")
        return
    end
    for i,p in ipairs(ring) do
        local q = ring[(i % count)+1]
        local distance = math.abs(p.x-q.x)+math.abs(p.z-q.z)
        if distance ~= 1 then
            minetest.log("error","[GDO] Escalier refusé : rupture de "..distance..
                " nodes dans la boucle de la tour.")
            return
        end
    end

    -- Une seule vis continue. Chaque marche a un support plein et une hauteur
    -- réelle de 0,5 ou 1 node via paramtype2=leveled.
    local max_halfsteps = 2*(height-1)
    local cycle = 0
    while 1 + cycle*14 <= max_halfsteps do
        for i,p in ipairs(ring) do
            local halfsteps = 1 + cycle*14 + math.floor((i-1)*14/count)
            local target_height = 1.5 + 0.5*halfsteps
            local node_y = math.floor(target_height)
            local level = (target_height-node_y > 0.25) and 64 or 32
            local x,z = cx+p.x,cz+p.z

            -- Dégagement de 2,5 blocs au-dessus de chaque marche.
            clear(x,node_y+1,z,x,node_y+2,z)
            put(x,node_y,z,M.stair,level)
            staircase_cells[#staircase_cells+1] = {x=x,y=node_y,z=z}
        end
        cycle = cycle+1
    end
end

local function tower_door(cx,cz,r,side,level,threshold_steps)
    local y1,y2 = level+1,level+4
    local reach = r+1
    local inner = r-2
    if side == "north" then
        clear(cx-1,y1,cz-reach,cx+1,y2,cz-inner)
    elseif side == "south" then
        clear(cx-1,y1,cz+inner,cx+1,y2,cz+reach)
    elseif side == "east" then
        clear(cx+inner,y1,cz-1,cx+reach,y2,cz+1)
    elseif side == "west" then
        clear(cx-reach,y1,cz-1,cx-inner,y2,cz+1)
    end

    -- Deux demi-marches raccordent le sol de la cour au plancher du rez-de-chaussée.
    if level == 1 and threshold_steps ~= false then
        for lateral=-1,1 do
            if side == "east" then
                put(cx+reach,1,cz+lateral,M.stair_low)
                put(cx+reach-1,1,cz+lateral,M.stair_high)
                put(cx+inner+1,1,cz+lateral,M.floor)
                put(cx+inner,1,cz+lateral,M.floor)
            elseif side == "west" then
                put(cx-reach,1,cz+lateral,M.stair_low)
                put(cx-reach+1,1,cz+lateral,M.stair_high)
                put(cx-inner-1,1,cz+lateral,M.floor)
                put(cx-inner,1,cz+lateral,M.floor)
            elseif side == "north" then
                put(cx+lateral,1,cz-reach,M.stair_low)
                put(cx+lateral,1,cz-reach+1,M.stair_high)
                put(cx+lateral,1,cz-inner-1,M.floor)
                put(cx+lateral,1,cz-inner,M.floor)
            elseif side == "south" then
                put(cx+lateral,1,cz+reach,M.stair_low)
                put(cx+lateral,1,cz+reach-1,M.stair_high)
                put(cx+lateral,1,cz+inner+1,M.floor)
                put(cx+lateral,1,cz+inner,M.floor)
            end
        end
    end
end

local function tower_window(cx,cz,r,side,y)
    if side == "north" then
        clear(cx-1,y,cz-r,cx+1,y+1,cz-r)
        put(cx,y,cz-r,M.glass)
        put(cx,y+1,cz-r,M.glass)
    elseif side == "south" then
        clear(cx-1,y,cz+r,cx+1,y+1,cz+r)
        put(cx,y,cz+r,M.glass)
        put(cx,y+1,cz+r,M.glass)
    elseif side == "east" then
        clear(cx+r, y,cz-1,cx+r,y+1,cz+1)
        put(cx+r,y,cz,M.glass)
        put(cx+r,y+1,cz,M.glass)
    else
        clear(cx-r,y,cz-1,cx-r,y+1,cz+1)
        put(cx-r,y,cz,M.glass)
        put(cx-r,y+1,cz,M.glass)
    end
end

local function build_round_tower(spec)
    local cx,cz,r,h = spec.x,spec.z,spec.r,spec.h
    local inner = r-2
    -- Mur circulaire de deux nodes d'épaisseur.
    for y=1,h do
        for x=-r,r do
            for z=-r,r do
                local d=x*x+z*z
                if d <= r*r and d >= inner*inner then
                    put(cx+x,y,cz+z,M.stone)
                end
            end
        end
    end

    -- Planchers de niveaux ; la spirale découpe sa propre trémie ensuite.
    for y=1,h,7 do
        disk_floor(cx,cz,inner,y,M.floor)
        -- Une lanterne centrale par niveau ; le noyau reste libre de la spirale.
        if y+3 < h then lamp(cx,y+3,cz) end
    end

    place_spiral_stair(cx,cz,r,h,spec.entry)

    -- Le plancher du dernier niveau (y=h) sert de terrasse sommitale.
    -- On ne pose pas de seconde dalle : elle créerait une marche d'un node.
    
    -- Porte de pied et sorties de circulation aux niveaux de rempart.
    tower_door(cx,cz,r,spec.entry,1,spec.threshold_steps)
    if spec.wall_side then
        tower_door(cx,cz,r,spec.wall_side,15)
    end
    if spec.extra_doors then
        for _,level in ipairs(spec.extra_doors) do
            tower_door(cx,cz,r,spec.entry,level)
        end
    end

    -- Baies étroites opposées à la porte, étagées sur le fût.
    local window_side = spec.window_side or "north"
    for y=5,h-3,7 do
        tower_window(cx,cz,r,window_side,y)
    end

    -- Terrasse sommitale crénelée, sans toit bas qui condamnerait l'escalier.
    for x=-r-1,r+1 do
        for z=-r-1,r+1 do
            local d=x*x+z*z
            if d <= (r+1)*(r+1) and d >= (r-1)*(r-1) then
                put(cx+x,h+1,cz+z,M.trim)
                if (x+z)%2 == 0 then
                    put(cx+x,h+2,cz+z,M.trim)
                end
            end
        end
    end
    lamp(cx,h-1,cz)
end

-- ZONE 1 : enceinte quadrangulaire et chemins de ronde.
local function build_enclosure()
    wall_x(-34,34,1,14,-30,M.stone,3)
    wall_x(-34,-5,1,14,32,M.stone,3)
    wall_x(5,34,1,14,32,M.stone,3)
    wall_z(-30,34,1,14,-34,M.stone,3)
    wall_z(-30,34,1,14,32,M.stone,3)

    -- Chemin de ronde à 3 nodes de largeur, posé au-dessus des courtines.
    deck(-33,-29,33,-27,15,M.floor)
    deck(-33,31,-5,33,15,M.floor)
    deck(5,31,33,33,15,M.floor)
    deck(-33,-27,-31,31,15,M.floor)
    deck(31,-27,33,31,15,M.floor)

    -- Merlons réguliers, mais interrompus au droit de la porte.
    for x=-34,34,2 do
        fill(x,16,-30,x,17,-30,M.trim)
        if x < -5 or x > 5 then
            fill(x,16,34,x,17,34,M.trim)
        end
    end
    for z=-30,34,2 do
        fill(-34,16,z,-34,17,z,M.trim)
        fill(34,16,z,34,17,z,M.trim)
    end
    -- Corbeaux sous les chemins de ronde.
    for x=-32,32,4 do
        fill(x,13,-28,x,14,-28,M.trim)
        fill(x,13,32,x,14,32,M.trim)
    end
    for z=-26,30,4 do
        fill(-32,13,z,-32,14,z,M.trim)
        fill(32,13,z,32,14,z,M.trim)
    end
end

-- ZONE 2 : logis seigneurial, au nord-ouest de la cour.
local function register_room_action(name, description, message)
    minetest.register_node(name, {
        description = S(description),
        tiles = {textures.refit_wood},
        groups = {choppy = 2, oddly_breakable_by_hand = 2},
        on_rightclick = function(pos, node, player)
            if player and player:is_player() then
                minetest.chat_send_player(player:get_player_name(), message)
            end
        end,
    })
end

register_room_action("gdo_castle:library_catalog", "Catalogue de la bibliothèque",
    "La bibliothèque rassemble les chroniques, les cartes et les grimoires du royaume.")
register_room_action("gdo_castle:kitchen_station", "Comptoir des cuisines",
    "Les cuisines du château sont ouvertes. Le ragoût du jour est au navet.")
register_room_action("gdo_castle:forge_station", "Enclume de l'armurerie",
    "L'atelier du forgeron attend les matériaux et les commandes.")

local function place_logis_switchback()
    -- Escalier principal du logis : deux volées parallèles en U.
    -- 14 cellules par étage, 0,5 node de montée par cellule.
    local path = {}
    for z=-24,-18 do path[#path+1] = {x=8,z=z} end
    for z=-18,-24,-1 do path[#path+1] = {x=9,z=z} end

    for cycle=0,1 do
        for i,p in ipairs(path) do
            local target_height = 2 + cycle*7 + (i-1)*0.5
            local node_y = math.floor(target_height)
            local level = (target_height-node_y > 0.25) and 64 or 32
            clear(p.x,node_y+1,p.z,p.x,node_y+2,p.z)
            put(p.x,node_y,p.z,M.stair,level)
            staircase_cells[#staircase_cells+1] = {x=p.x,y=node_y,z=p.z}
        end
    end
end

local function build_logis()
    fill(-28,1,-27,14,17,-11,M.stone)
    clear(-26,2,-25,12,16,-13)
    deck(-26,-25,12,-13,1,M.floor)
    deck(-26,-25,12,-13,8,M.wood)
    deck(-26,-25,12,-13,15,M.wood)

    -- Porte principale ouverte sur la cour, avec deux demi-marches de seuil.
    clear(-6,2,-12,-1,5,-10)
    for x=-5,-2 do
        put(x,1,-11,M.stair_low)
        put(x,1,-12,M.stair_high)
    end
    -- Encadrement sculpté et linteau au-dessus de la porte du logis.
    fill(-7,2,-12,-7,6,-10,M.trim)
    fill(0,2,-12,0,6,-10,M.trim)
    fill(-7,6,-12,0,6,-10,M.trim)
    fill(-4,7,-12,-3,7,-10,M.gold)
    -- Deux vantaux en chêne ouverts contre les jambages de l'entrée du logis.
    for y=2,5 do
        for z=-12,-10 do
            put(-6,y,z,"gdo_castle:open_gate_left")
            put(-1,y,z,"gdo_castle:open_gate_right")
        end
    end
    for y=2,4,2 do
        put(-6,y,-11,M.gold)
        put(-1,y,-11,M.gold)
    end
    -- Grande salle au rez-de-chaussée, cloison de cuisine au nord-est.
    wall_z(-24,-14,2,7,-3,M.trim,1)
    clear(-3,2,-20,-3,5,-18)
    fill(-24,2,-24,-20,4,-22,M.wood)
    for x=-23,-20,1 do put(x,5,-23,M.gold) end
    -- Cheminée et foyer, adossés au mur nord.
    fill(-18,2,-25,-15,6,-25,M.trim)
    fill(-17,3,-24,-16,5,-24,M.roof)
    lamp(-16,6,-24)
    -- Éclairage réparti au-dessus des espaces de réception.
    for _,p in ipairs({
        {-20,6,-22},{-12,6,-22},{0,6,-22},{8,6,-22},
        {-20,6,-16},{-12,6,-16},{0,6,-16},{8,6,-16},
        {-16,13,-22},{-10,13,-22},{-2,13,-22},{8,13,-22},
        {-16,13,-16},{-10,13,-16},{-2,13,-16},{8,13,-16},
        {-16,16,-22},{-10,16,-22},{-2,16,-22},{8,16,-22},
    }) do
        lamp(p[1],p[2],p[3])
    end
    -- Grande table de banquet et bancs : le centre de la salle reste dégagé.
    for x=-21,-12 do
        put(x,2,-20,M.table)
    end
    for x=-20,-14,2 do
        put(x,2,-22,M.bench)
        put(x,2,-18,M.bench)
    end
    -- Tapis bleu et or qui guide vers l'estrade sans barrer l'entrée.
    for x=-10,-7 do
        for z=-24,-15 do
            put(x,2,z,M.rug)
        end
    end
    for z=-24,-15 do
        put(-11,2,z,M.gold)
        put(-6,2,z,M.gold)
    end

    -- Piliers engagés, tapisseries héraldiques et appliques sur les murs.
    for _,p in ipairs({{-24,-24},{-24,-15},{10,-24},{10,-15}}) do
        for y=2,7 do put(p[1],y,p[2],M.pillar) end
        put(p[1],8,p[2],M.gold)
    end
    for _,z in ipairs({-23,-17}) do
        fill(-25,3,z-1,-25,7,z+1,M.roof)
        fill(-24,4,z,-24,6,z,M.gold)
        put(-24,7,z,M.trim)
        lamp(-24,6,z)
    end

    -- Foyer monumental : socle, manteau et blason au-dessus de la cheminée.
    fill(-19,2,-25,-14,2,-25,M.trim)
    fill(-19,6,-25,-14,6,-25,M.wood)
    fill(-19,3,-25,-19,5,-25,M.gold)
    fill(-14,3,-25,-14,5,-25,M.gold)
    fill(-17,7,-25,-16,8,-25,M.roof)
    put(-17,6,-24,M.gold)
    put(-16,6,-24,M.gold)

    -- Réfectoire et cuisine regroupés au sud-est ; la cage d'escalier reste libre.
    for x=3,6 do put(x,2,-24,M.table) end
    for x=4,6,2 do put(x,2,-18,M.bench) end
    put(5,3,-22,"gdo_castle:kitchen_station")
    -- Étagères et garde-manger en alcôve.
    fill(3,3,-17,3,5,-15,M.wood)
    fill(4,2,-16,6,3,-16,M.trim)
    lamp(4,6,-16)
    -- Étage noble : bibliothèque et chambre seigneuriale.
    wall_z(-24,-14,9,14,-4,M.trim,1)
    clear(-4,9,-20,-4,12,-18)
    for z=-23,-15,2 do
        fill(-24,9,z,-23,13,z,M.wood)
        fill(-21,9,z,-20,13,z,M.wood)
    end
    put(-22,10,-15,"gdo_castle:library_catalog")
    -- Bibliothèque : rayonnages, pupitre de lecture et tapis.
    fill(-25,10,-23,-25,13,-17,M.wood)
    for z=-22,-18,2 do
        put(-24,11,z,M.gold)
        put(-24,12,z,M.trim)
    end
    put(-18,10,-18,M.table)
    put(-18,10,-17,M.bench)
    for x=-17,-13 do
        for z=-22,-19 do put(x,10,z,M.rug) end
    end
    lamp(-23,14,-20)
    lamp(-16,14,-20)
    -- Balcon intérieur sur la grande salle.
    deck(-18,-24,-7,-14,15,M.floor)
    for x=-17,-8,3 do
        put(x,16,-14,M.trim)
    end

    -- L'escalier U est posé après les meubles et avant la toiture.
    place_logis_switchback()

    -- Baies vitrées et encadrements de façade.
    for x=-22,10,8 do
        clear(x,5,-11,x+1,8,-11)
        put(x,6,-11,M.glass)
        put(x,7,-11,M.glass)
        fill(x-1,4,-12,x+2,4,-11,M.trim)
        fill(x-1,9,-12,x+2,9,-11,M.trim)
    end
    -- Toiture à deux pans, faîtage est-ouest.
    for layer=0,6 do
        local inset=layer
        fill(-29+inset,18+layer,-28+inset,15-inset,18+layer,-10-inset,M.roof)
    end
    fill(-8,25,-27,-5,25,-11,M.trim)
    -- Lucarnes et cheminées.
    for x=-20,-4,8 do
        fill(x-2,21,-12,x+2,24,-12,M.trim)
        put(x,22,-12,M.glass)
        put(x,25,-12,M.gold)
    end
end

-- ZONE 3 : donjon circulaire au nord-est, inspiré du plan de Dourdan.
local function build_keep()
    build_round_tower({
        x=24,z=-20,r=10,h=29,
        entry="west",wall_side="north",threshold_steps=false,
        extra_doors={8},window_side="east",
    })
end

-- ZONE 4 : châtelet sud, herse et pont.
local function build_gatehouse()
    -- Deux tours de porte épaisses, reliées par un passage couvert.
    fill(-4,1,24,4,16,38,M.stone)
    clear(-3,2,25,3,10,42)
    -- Piédroits et arc du portail.
    fill(-5,1,25,-4,11,38,M.trim)
    fill(4,1,25,5,11,38,M.trim)
    fill(-5,11,25,5,12,38,M.trim)
    fill(-4,13,25,4,14,38,M.roof)
    -- Passage traversant intégral : inclure z=24, qui est le mur nord
    -- du volume du châtelet. Sans cette rangée, le tunnel finit en cul-de-sac.
    clear(-2,2,23,2,10,42)
    -- Vantaux massifs ouverts le long des piédroits : porte visible, passage libre.
    for y=2,7 do
        for z=28,34 do
            put(-3,y,z,"gdo_castle:open_gate_left")
            put(3,y,z,"gdo_castle:open_gate_right")
        end
    end
    -- Ferrures et clous dorés sur les vantaux.
    for y=2,6,2 do
        put(-3,y,31,M.gold)
        put(3,y,31,M.gold)
    end

    -- Herse relevée au-dessus du volume de passage, jamais à hauteur du joueur.
    for x=-2,2,2 do
        fill(x,11,31,x,13,31,M.wood)
        put(x,14,31,M.gold)
    end
    -- Lanternes encastrées dans les deux murs du tunnel.
    for z=27,39,6 do
        lamp(-4,8,z)
        lamp(4,8,z)
    end
    -- Galerie supérieure de garde.
    deck(-9,27,9,37,15,M.wood)
    fill(-9,16,27,-9,18,37,M.trim)
    fill(9,16,27,9,18,37,M.trim)
    -- Terrasse supérieure ouverte : pas de plafond bas au-dessus du parcours.
    for x=-5,5,2 do
        fill(x,16,25,x,17,25,M.trim)
        fill(x,16,38,x,17,38,M.trim)
    end
end

-- ZONE 5 : bâtiments de service et chapelle dans la cour.
local function small_building(x1,x2,z1,z2,height,door_side,roof_material)
    fill(x1,1,z1,x2,height,z2,M.stone)
    clear(x1+1,2,z1+1,x2-1,height-1,z2-1)
    deck(x1+1,z1+1,x2-1,z2-1,1,M.floor)
    local mid = math.floor((x1+x2)/2)
    local midz = math.floor((z1+z2)/2)
    if door_side == "east" then
        clear(x2-1,2,midz-1,x2+1,5,midz+1)
    elseif door_side == "west" then
        clear(x1-1,2,midz-1,x1+1,5,midz+1)
    elseif door_side == "north" then
        clear(mid-1,2,z1-1,mid+1,5,z1+1)
    else
        clear(mid-1,2,z2-1,mid+1,5,z2+1)
    end
    local roof = roof_material or M.roof
    local half = math.floor((x2-x1)/2)
    for layer=0,4 do
        fill(mid-half+layer,height+1+layer,z1-1,mid+half-layer,height+1+layer,z2+1,roof)
    end
    fill(mid-1,height+5,z1+1,mid+1,height+5,z2-1,M.trim)
end

local function build_courtyard_buildings()
    -- Bâtiment ouest : cuisine et ateliers.
    small_building(-28,-16,-7,15,9,"east",M.roof)
    fill(-26,2,-5,-18,2,-3,M.wood)
    put(-18,3,-5,"gdo_castle:forge_station")
    lamp(-17,7,0)
    for _,p in ipairs({{-24,7,-4},{-20,7,-4},{-24,7,8},{-20,7,8}}) do
        lamp(p[1],p[2],p[3])
    end

    -- Chapelle et salle des novices au sud-est.
    small_building(16,28,2,19,11,"west",M.roof)
    fill(18,2,5,26,2,7,M.trim)
    fill(20,3,5,24,4,7,M.gold)
    for z=9,15,3 do
        put(16,6,z,M.glass)
        lamp(17,7,z)
    end
    for _,p in ipairs({{20,8,5},{24,8,5},{20,8,15},{24,8,15}}) do
        lamp(p[1],p[2],p[3])
    end
    -- Chapelle meublée : nef, bancs alignés et autel sous le vitrail.
    for z=5,13,2 do
        put(20,2,z,M.bench)
        put(24,2,z,M.bench)
    end
    for x=21,23 do
        for z=15,17 do put(x,2,z,M.rug) end
    end
    fill(21,2,17,23,3,17,M.trim)
    fill(21,4,17,23,4,17,M.gold)
    put(22,5,17,M.gold)
    lamp(22,9,17)
    -- Confessionnal et lutrin près de l'entrée.
    put(18,2,4,M.table)
    put(18,3,4,M.gold)

    -- Puits central décalé de l'axe de circulation.
    fill(-13,1,1,-9,2,5,M.trim)
    fill(-12,3,2,-10,3,4,M.water)
    fill(-12,4,2,-10,4,4,M.water)
    fill(-13,3,1,-9,3,1,M.wood)
    fill(-13,3,5,-9,3,5,M.wood)
    lamp(-11,5,3)
    -- Fontaine à bassin dans le secteur est de la cour ; l'axe central reste libre.
    fill(7,1,7,11,1,11,M.trim)
    clear(8,2,8,10,2,10)
    fill(8,2,8,10,2,10,M.water)
    fill(9,2,9,9,3,9,M.trim)
    fill(8,3,8,10,3,8,M.gold)
    fill(8,3,10,10,3,10,M.gold)
    fill(8,3,9,8,3,9,M.gold)
    fill(10,3,9,10,3,9,M.gold)
    lamp(9,4,9)
    -- Bancs de promenade face à la fontaine.
    put(6,2,9,M.bench)
    put(12,2,9,M.bench)
    -- Jardins bas, arbres et bordures dans les coins de la cour.
    for x=-17,-11 do
        put(x,1,17,M.wood)
        put(x,1,23,M.wood)
    end
    for z=17,23 do
        put(-17,1,z,M.wood)
        put(-11,1,z,M.wood)
    end
    for x=-16,-12 do
        for z=18,22 do
            if x==-16 or x==-12 or z==18 or z==22 then put(x,2,z,M.leaves) end
        end
    end
    put(-14,2,20,"gdo_core:arbre")
    for x=-16,-12 do for z=18,22 do
        if (x-14)^2+(z-20)^2 <= 5 then put(x,5,z,"gdo_core:feuilles") end
    end end

    -- Trois navets héroïques du tutoriel, replacés dans le jardin de la cour.
    put(-8,1,21,"gdo_core:navet_sur_pied")
    put(-10,1,22,"gdo_core:navet_sur_pied")
    put(-7,1,23,"gdo_core:navet_sur_pied")
    -- Appliques au niveau des galeries et des portes de la cour.
    for _,p in ipairs({{-20,5,-5},{20,5,-5},{-20,5,20},{20,5,20},
                       {-30,8,0},{30,8,0},{-30,8,25},{30,8,25}}) do
        lamp(p[1],p[2],p[3])
    end
end

local function build_gardens_and_approach()
    -- Cour en pavés avec axe de circulation dégagé.
    deck(-31,-27,31,31,0,M.path)
    deck(-4,-10,4,31,0,M.floor)
    for z=-8,29,6 do
        put(-6,1,z,M.trim)
        put(6,1,z,M.trim)
    end

    -- Parvis extérieur et allée vers la herse.
    deck(-17,44,17,72,0,M.floor)
    deck(-4,34,4,72,0,M.path)
    -- Fossé latéral ; le pont central reste libre et à niveau.
    fill(-18,0,38,-5,0,43,M.water)
    fill(5,0,38,18,0,43,M.water)
    deck(-4,38,4,47,0,M.wood)
    for x=-4,4 do
        put(x,1,38,M.trim)
        put(x,1,47,M.trim)
    end
    for z=50,68,6 do
        fill(-13,1,z,-12,3,z,M.trim)
        fill(12,1,z,13,3,z,M.trim)
        lamp(-12,4,z)
        lamp(12,4,z)
    end
    -- Lumières du chemin d'accès et de la herse.
    lamp(-3,5,42); lamp(3,5,42)
    lamp(-3,5,55); lamp(3,5,55)
    -- Plateforme de spawn entièrement dégagée.
    deck(-4,64,4,72,0,M.floor)
    clear(-3,1,64,3,5,72)
    put(0,1,71,"gdo_castle:arrival_sign")
end

local function build_towers()
    -- Trois tours d'angle ; la quatrième est le grand donjon nord-est.
    build_round_tower({
        x=-31,z=-27,r=7,h=22,
        entry="east",window_side="west",
    })
    build_round_tower({
        x=-31,z=31,r=7,h=22,
        entry="east",window_side="west",
    })
    build_round_tower({
        x=31,z=31,r=7,h=22,
        entry="west",window_side="east",
    })
    -- Tours jumelles du châtelet.
    build_round_tower({
        x=-10,z=32,r=7,h=22,
        entry="north",window_side="west",
    })
    build_round_tower({
        x=10,z=32,r=7,h=22,
        entry="north",window_side="east",
    })
end

local function final_connections()
    -- Portail traversant : dégager aussi le mur intérieur du châtelet (z=24)
    -- et une courte sortie dans la cour. Les vantaux restent sur les côtés.
    clear(-2,2,23,2,10,42)
    -- Accès du logis depuis la cour, sans effacer les vantaux.
    clear(-5,2,-13,-2,5,-10)
    -- Liaison logis/donjon à chaque niveau habitable.
    clear(13,2,-22,18,5,-18)
    clear(13,9,-22,18,12,-18)
    clear(13,16,-22,18,19,-18)
    -- Petits paliers de raccord entre le logis et le noyau du donjon.
    deck(13,-22,16,-18,1,M.floor)
    deck(13,-22,16,-18,8,M.floor)
    deck(13,-22,16,-18,15,M.floor)
    -- Entrée des tours d'angle après construction des courtines et bâtiments.
    tower_door(-31,-27,7,"east",1)
    tower_door(-31,31,7,"east",1)
    tower_door(31,31,7,"west",1)
    -- Tours du portail : accès depuis la cour et vers la galerie de garde.
    tower_door(-10,32,7,"north",1)
    tower_door(10,32,7,"north",1)
    -- Refaire les fenêtres/portes du donjon en dernier pour garder les seuils nets.
    tower_door(24,-20,10,"west",1,false)
    tower_door(24,-20,10,"west",8,false)
    tower_door(24,-20,10,"north",15,false)

    -- Dégagement vertical et horizontal des passages vitaux.
    clear(-2,2,23,2,10,42)
    clear(-5,2,-13,-2,5,-10)
    clear(13,2,-22,18,5,-18)
    clear(13,9,-22,18,12,-18)
    clear(13,16,-22,18,19,-18)
end

local function audit_geometry()
    local repaired = 0
    -- Vérification du dégagement de chaque marche : 2 nodes libres au-dessus.
    for _,p in ipairs(staircase_cells) do
        for dy=1,2 do
            local q = {x=p.x,y=p.y+dy,z=p.z}
            local node = minetest.get_node({x=q.x,y=q.y+BASE_Y,z=q.z})
            if node and node.name ~= "air" then
                put(q.x,q.y,q.z,"air")
                repaired = repaired + 1
            end
        end
    end

    -- Contrôle des trois traversées principales après assemblage des zones.
    local corridors = {
        {name="portail", x1=-2,y1=2,z1=23,x2=2,y2=10,z2=42},
        {name="entrée du logis", x1=-5,y1=2,z1=-13,x2=-2,y2=5,z2=-10},
        {name="liaison logis-donjon", x1=13,y1=2,z1=-22,x2=18,y2=5,z2=-18},
    }
    local blocked = 0
    for _,c in ipairs(corridors) do
        for x=c.x1,c.x2 do
            for y=c.y1,c.y2 do
                for z=c.z1,c.z2 do
                    local n = minetest.get_node({x=x,y=y+BASE_Y,z=z})
                    if not n or n.name ~= "air" then blocked = blocked + 1 end
                end
            end
        end
    end

    minetest.log("action","[GDO] Audit géométrique : "..#staircase_cells..
        " cellules d'escalier contrôlées, "..repaired..
        " dégagements corrigés, "..blocked.." blocs dans les couloirs.")
end

local function ensure_gerard()
    local pos = {x=3,y=BASE_Y+1,z=20}
    for _,object in ipairs(minetest.get_objects_inside_radius(pos,8)) do
        local entity = object:get_luaentity()
        if entity and entity.name == "gdo_core:gerard" then
            object:remove()
        end
    end
    if minetest.registered_entities["gdo_core:gerard"] then
        minetest.add_entity(pos,"gdo_core:gerard")
    end
end

local function safe_spawn(player)
    if not player or not player:is_player() then return end
    player:set_pos({x=0,y=BASE_Y+1,z=68})
    if player.set_velocity then player:set_velocity({x=0,y=0,z=0}) end
end

local function find_surface_y(x,z)
    for y=80,-16,-1 do
        local node = minetest.get_node_or_nil({x=x,y=y,z=z})
        if node and node.name ~= "air" and node.name ~= "ignore" then
            local def = minetest.registered_nodes[node.name]
            if def and def.walkable and (not def.liquidtype or def.liquidtype == "none")
                and minetest.get_item_group(node.name,"tree") == 0
                and minetest.get_item_group(node.name,"leaves") == 0
                and minetest.get_item_group(node.name,"plant") == 0 then
                return y
            end
        end
    end
    return nil
end

local function choose_base_y()
    local heights = {}
    for x=-32,32,8 do
        for z=-24,32,8 do
            local y = find_surface_y(x,z)
            if y then heights[#heights+1] = y end
        end
    end
    if #heights == 0 then
        minetest.log("warning","[GDO] Terrain introuvable pour le plateau ; altitude 0 utilisée.")
        return 0
    end
    table.sort(heights)
    local median = heights[math.floor((#heights+1)/2)]
    minetest.log("action","[GDO] Altitude du plateau choisie : "..median..
        " (échantillons "..#heights..", min "..heights[1]..", max "..heights[#heights]..").")
    return median
end

local function prepare_level_pad()
    -- Plateau ovale sous l'enceinte : 94 x 104 nodes environ.
    -- En dehors, le relief généré par la carte est conservé.
    local rx,rz,cz = 47,52,2
    for x=-50,50 do
        for z=-56,76 do
            local d = (x/rx)*(x/rx) + ((z-cz)/rz)*((z-cz)/rz)
            local apron = math.abs(x) <= 17 and z >= 44 and z <= 72
            if d <= 1 or apron then
                clear(x,1,z,x,82,z)
                fill(x,-5,z,x,-1,z,"gdo_core:terre")
                put(x,0,z,M.grass)
            elseif d <= 1.18 then
                -- Talus enherbé de cinq niveaux : raccord du plateau au relief.
                local drop = math.min(5,math.max(1,math.floor((d-1)*28)+1))
                local top = -drop
                clear(x,top+1,z,x,82,z)
                fill(x,top-4,z,x,top-1,z,"gdo_core:terre")
                put(x,top,z,M.grass)
            end
        end
    end
end

local function build()
    -- Les joueurs sont déplacés au-dessus de la zone pendant les travaux.
    for _,player in ipairs(minetest.get_connected_players()) do
        player:set_pos({x=0,y=BASE_Y+95,z=90})
        if player.set_velocity then player:set_velocity({x=0,y=0,z=0}) end
    end

    -- Aplanir seulement l'emprise bâtie et le parvis ; garder collines et plaines autour.
    prepare_level_pad()

    -- Construction par zones, dans l'ordre des structures porteuses.
    build_enclosure()
    build_logis()
    build_keep()
    build_gatehouse()
    build_courtyard_buildings()
    build_towers()
    build_gardens_and_approach()

    -- La passe d'assemblage intervient après toutes les zones.
    final_connections()
    audit_geometry()
    ensure_gerard()

    if minetest.fix_light then
        minetest.fix_light({x=-50,y=BASE_Y-6,z=-56},{x=50,y=BASE_Y+82,z=76})
    end
    if minetest.set_timeofday then minetest.set_timeofday(0.5) end

    for _,player in ipairs(minetest.get_connected_players()) do safe_spawn(player) end
    minetest.log("action","[GDO] Plan Dourdan assemblé : enceinte, châtelet, cour, logis et donjon.")
end

local storage = gdo_castle_storage or minetest.get_mod_storage()
local VERSION = 20

local generation_started = false
local function generate_if_needed()
    if generation_started then return end
    if not storage or storage:get_int("dourdan_plan_version") < VERSION then
        local mapgen = minetest.get_mapgen_setting and minetest.get_mapgen_setting("mg_name")
        if mapgen == "flat" then
            minetest.log("warning","[GDO] Cette sauvegarde utilise encore le mapgen flat. "..
                "Pour les paysages naturels, crée une nouvelle carte GDO avec le mapgen v6.")
            return
        end
        generation_started = true
        -- Faire générer le terrain classique avant de choisir l'altitude du plateau.
        local emerge_failed = false
        minetest.emerge_area(
            {x=-56,y=-16,z=-64},
            {x=56,y=160,z=96},
            function(blockpos, action, calls_remaining)
                if action == minetest.EMERGE_ERRORED or action == minetest.EMERGE_CANCELLED then
                    emerge_failed = true
                end
                if calls_remaining == 0 then
                    if emerge_failed then
                        minetest.log("error","[GDO] Impossible de générer le terrain autour du château.")
                        generation_started = false
                        return
                    end
                    BASE_Y = choose_base_y()
                    build()
                    if storage then storage:set_int("dourdan_plan_version",VERSION) end
                end
            end
        )
    end
end

minetest.register_on_mods_loaded(function()
    minetest.after(5,generate_if_needed)
end)

minetest.register_on_joinplayer(function(player)
    minetest.after(2,function()
        if player and player:is_player() then safe_spawn(player) end
    end)
end)

minetest.register_on_respawnplayer(function(player)
    safe_spawn(player)
    return true
end)

minetest.register_chatcommand("chateau_pos", {
    description = "Affiche les coordonnées et les blocs devant le joueur",
    privs = {interact = true},
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then return false, "Joueur introuvable." end
        local p = player:get_pos()
        local d = player:get_look_dir()
        minetest.chat_send_player(name, string.format(
            "[GDO] Position : x=%.2f y=%.2f z=%.2f | direction : x=%.2f y=%.2f z=%.2f",
            p.x,p.y,p.z,d.x,d.y,d.z))
        for step=1,5 do
            local q = {
                x=math.floor(p.x+d.x*step+0.5),
                y=math.floor(p.y+1.2+d.y*step+0.5),
                z=math.floor(p.z+d.z*step+0.5),
            }
            local n = minetest.get_node_or_nil(q)
            minetest.chat_send_player(name, string.format(
                "[GDO] Devant %d : (%d,%d,%d) = %s",
                step,q.x,q.y,q.z,n and n.name or "ignore"))
        end
        return true, "Diagnostic affiché dans le chat."
    end,
})

minetest.register_chatcommand("refairechateau",{
    description = "Reconstruit le château selon le plan Dourdan",
    privs = {interact=true},
    func = function()
        local mapgen = minetest.get_mapgen_setting and minetest.get_mapgen_setting("mg_name")
        if mapgen == "flat" then
            return false,"Cette carte utilise le générateur flat. Crée un nouveau monde avec le mapgen v6 pour obtenir les collines et les plaines."
        end
        BASE_Y = choose_base_y()
        build()
        if storage then storage:set_int("dourdan_plan_version",VERSION) end
        return true,"Château reconstruit sur le plateau naturel. Tu es sur le parvis sud."
    end,
})
