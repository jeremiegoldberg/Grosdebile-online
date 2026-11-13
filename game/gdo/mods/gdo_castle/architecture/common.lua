-- GDO Castle Architecture - shared materials and world-space helpers.
-- Every zone uses absolute world coordinates. No hidden Y offsets.
local modname = minetest.get_current_modname()
local S = minetest.get_translator and minetest.get_translator(modname) or function(s) return s end

local A = {}
A.materials = {
    stone="gdo_castle:refit_stone",
    trim="gdo_castle:refit_trim",
    roof="gdo_castle:refit_roof",
    floor="gdo_castle:refit_floor",
    wood="gdo_castle:refit_wood",
    glass="gdo_castle:refit_glass",
    gold="gdo_castle:refit_gold",
    grass="gdo_castle:refit_grass",
    path="gdo_castle:refit_path",
    leaves="gdo_castle:refit_leaves",
    water="gdo_castle:refit_water",
    lamp="gdo_castle:refit_lamp",
    stair="gdo_castle:refit_stair",
    table="gdo_castle:refit_table",
    bench="gdo_castle:refit_bench",
    rug="gdo_castle:refit_rug",
    pillar="gdo_castle:refit_pillar",
    crate="gdo_castle:refit_crate",
    barrel="gdo_castle:refit_barrel",
    banner="gdo_castle:refit_banner",
    flower_red="gdo_castle:refit_flower_red",
    flower_blue="gdo_castle:refit_flower_blue",
    flower_gold="gdo_castle:refit_flower_gold",
}

local T = {
    refit_stone="refit_stone.png", refit_trim="refit_trim.png",
    refit_roof="refit_roof.png", refit_floor="refit_floor.png",
    refit_wood="refit_wood.png", refit_glass="refit_glass.png",
    refit_gold="refit_gold.png", refit_grass="refit_grass.png",
    refit_path="refit_path.png", refit_leaves="refit_leaves.png",
    refit_water="refit_water.png",
}
local function register_textured(name, desc, groups, extra)
    local short=name:match(":(.+)$")
    local def={description=S(desc),tiles={T[short] or T.refit_stone},groups=groups or {cracky=2}}
    if extra then for k,v in pairs(extra) do def[k]=v end end
    minetest.register_node(name,def)
end

local M=A.materials
register_textured(M.stone,"Calcaire du château")
register_textured(M.trim,"Pierre de taille")
register_textured(M.roof,"Ardoise bleue")
register_textured(M.floor,"Dallage intérieur")
register_textured(M.wood,"Chêne ancien",{choppy=2})
register_textured(M.glass,"Vitrail",{cracky=2},{drawtype="glasslike",paramtype="light",
    sunlight_propagates=true,use_texture_alpha="blend"})
register_textured(M.gold,"Ornement doré")
register_textured(M.grass,"Gazon",{crumbly=3,soil=1})
register_textured(M.path,"Pavés",{cracky=2})
register_textured(M.leaves,"Feuillage",{snappy=3},{drawtype="allfaces_optional",
    paramtype="light",sunlight_propagates=true})
register_textured(M.water,"Eau décorative",{cracky=3},{drawtype="glasslike",
    paramtype="light",sunlight_propagates=true,walkable=false,pointable=false})

local function register_flower(name,desc,texture)
    minetest.register_node(name,{
        description=S(desc),drawtype="plantlike",tiles={texture},
        inventory_image=texture,wield_image=texture,paramtype="light",
        sunlight_propagates=true,walkable=false,buildable_to=true,
        groups={snappy=3,oddly_breakable_by_hand=3,flora=1},
        selection_box={type="fixed",fixed={-0.25,-0.5,-0.25,0.25,0.35,0.25}},
    })
end
register_flower(M.flower_red,"Coquelicot",T.refit_roof)
register_flower(M.flower_blue,"Iris bleu",T.refit_glass)
register_flower(M.flower_gold,"Fleur dorée",T.refit_gold)

minetest.register_node(M.lamp,{
    description=S("Lanterne murale"),drawtype="nodebox",tiles={T.refit_gold},
    paramtype="light",sunlight_propagates=true,light_source=14,walkable=false,
    groups={cracky=2,oddly_breakable_by_hand=2},
    node_box={type="fixed",fixed={
        {-0.22,-0.22,-0.22,0.22,0.22,0.22},
        {-0.08,-0.5,-0.08,0.08,-0.22,0.08},
    }},
    selection_box={type="fixed",fixed={-0.22,-0.22,-0.22,0.22,0.22,0.22}},
})

-- A single true stair node. It has only the two conventional stair treads:
-- a lower half-block and an upper rear half-block. No solid support cubes.
minetest.register_node(M.stair,{
    description=S("Escalier en pierre"),drawtype="nodebox",tiles={T.refit_stone},
    paramtype="light",paramtype2="facedir",sunlight_propagates=true,
    groups={cracky=2,stair=1},
    node_box={type="fixed",fixed={
        {-0.5,-0.5,-0.5,0.5,0,0.5},
        {-0.5,0,0,0.5,0.5,0.5},
    }},
    collision_box={type="fixed",fixed={
        {-0.5,-0.5,-0.5,0.5,0,0.5},
        {-0.5,0,0,0.5,0.5,0.5},
    }},
    selection_box={type="fixed",fixed={
        {-0.5,-0.5,-0.5,0.5,0,0.5},
        {-0.5,0,0,0.5,0.5,0.5},
    }},
})

local function register_furniture(name,desc,texture,boxes,walkable)
    minetest.register_node(name,{
        description=S(desc),drawtype="nodebox",tiles={texture},paramtype="light",
        sunlight_propagates=true,walkable=walkable~=false,
        groups={cracky=2,oddly_breakable_by_hand=2},
        node_box={type="fixed",fixed=boxes},
        collision_box={type="fixed",fixed=boxes},
        selection_box={type="fixed",fixed=boxes},
    })
end
register_furniture(M.table,"Table de banquet",T.refit_wood,{
    {-0.44,-0.42,-0.44,-0.32,0.16,-0.32},{0.32,-0.42,-0.44,0.44,0.16,-0.32},
    {-0.44,-0.42,0.32,-0.32,0.16,0.44},{0.32,-0.42,0.32,0.44,0.16,0.44},
    {-0.5,0.16,-0.5,0.5,0.28,0.5},
})
register_furniture(M.bench,"Banc de chêne",T.refit_wood,{
    {-0.44,-0.5,-0.36,-0.32,-0.05,-0.24},{0.32,-0.5,-0.36,0.44,-0.05,-0.24},
    {-0.44,-0.5,0.24,-0.32,-0.05,0.36},{0.32,-0.5,0.24,0.44,-0.05,0.36},
    {-0.5,-0.05,-0.42,0.5,0.08,0.42},
})
register_furniture(M.rug,"Tapis",T.refit_roof,{{-0.5,-0.49,-0.5,0.5,-0.45,0.5}},false)
register_furniture(M.pillar,"Colonne",T.refit_trim,{
    {-0.22,-0.5,-0.22,0.22,0.5,0.22},
    {-0.38,-0.5,-0.38,0.38,-0.34,0.38},
    {-0.34,0.34,-0.34,0.34,0.5,0.34},
})
register_furniture(M.crate,"Caisse",T.refit_wood,{{-0.5,-0.5,-0.5,0.5,0.5,0.5}})
register_furniture(M.barrel,"Tonneau",T.refit_wood,{{-0.34,-0.5,-0.34,0.34,0.5,0.34}})
register_furniture(M.banner,"Bannière",T.refit_roof,{{-0.05,-0.5,-0.36,0.05,0.35,0.36}},false)

A.put=function(x,y,z,name,param2)
    minetest.set_node({x=x,y=y,z=z},{name=name,param2=param2 or 0})
end
A.fill=function(x1,y1,z1,x2,y2,z2,name)
    for x=math.min(x1,x2),math.max(x1,x2) do
        for y=math.min(y1,y2),math.max(y1,y2) do
            for z=math.min(z1,z2),math.max(z1,z2) do A.put(x,y,z,name) end
        end
    end
end
A.clear=function(x1,y1,z1,x2,y2,z2)
    A.fill(x1,y1,z1,x2,y2,z2,"air")
end
A.deck=function(x1,z1,x2,z2,y,name)
    A.fill(x1,y,z1,x2,y,z2,name)
end
A.lamp=function(x,y,z) A.put(x,y,z,M.lamp) end

-- Return the natural ground surface, ignoring all castle-generated blocks.
A.find_surface_y=function(x,z)
    for y=192,-32,-1 do
        local node=minetest.get_node_or_nil({x=x,y=y,z=z})
        if node and node.name~="air" and node.name~="ignore"
            and not node.name:match("^gdo_castle:") then
            local def=minetest.registered_nodes[node.name]
            if def and def.walkable and (not def.liquidtype or def.liquidtype=="none") then
                local tree=minetest.get_item_group(node.name,"tree")
                local leaves=minetest.get_item_group(node.name,"leaves")
                local plant=minetest.get_item_group(node.name,"plant")
                if tree==0 and leaves==0 and plant==0 then return y end
            end
        end
    end
    return nil
end

A.median_surface=function(bounds,step)
    local values={}
    step=step or 4
    for x=bounds.x1,bounds.x2,step do
        for z=bounds.z1,bounds.z2,step do
            local y=A.find_surface_y(x,z)
            if y then values[#values+1]=y end
        end
    end
    if #values==0 then return nil end
    table.sort(values)
    return values[math.floor((#values+1)/2)],#values,values[1],values[#values]
end

A.flatten_rect=function(bounds,target_y,clear_to)
    clear_to=clear_to or 192
    local filled=0
    for x=bounds.x1,bounds.x2 do
        for z=bounds.z1,bounds.z2 do
            local natural=A.find_surface_y(x,z)
            if natural then
                -- Cut every old structure and every overhanging terrain column.
                A.clear(x,target_y+1,z,x,clear_to,z)
                if natural<target_y then
                    if target_y-natural>64 then
                        minetest.log("warning","[GDO] Gros remblai au socle ("..(target_y-natural).." blocs) en "..x..","..z)
                    end
                    A.fill(x,natural+1,z,x,target_y-1,z,"gdo_core:terre")
                end
            else
                A.clear(x,target_y+1,z,x,clear_to,z)
                A.fill(x,target_y-4,z,x,target_y-1,z,"gdo_core:terre")
            end
            A.put(x,target_y,z,M.grass)
            filled=filled+1
        end
    end
    return filled
end

A.fix_light=function(bounds)
    if minetest.fix_light then
        minetest.fix_light({x=bounds.x1,y=-32,z=bounds.z1},
            {x=bounds.x2,y=192,z=bounds.z2})
    end
end

return A
