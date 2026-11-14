-- Zone 50: compact residential quarter inside the castle walls.
-- Inspired by the dense, varied timber-and-stone houses of a medieval walled town.
return function(A)
    local Z={}
    Z.VERSION=1
    Z.bounds={x1=-35,x2=35,z1=-33,z2=33}
    Z.house_height=14

    local M=A.materials
    local function y(offset) return A.base_y+offset end

    local function build_house(def)
        local cx,cz=def.x,def.z
        local w,d=def.w or 9,def.d or 9
        local x1,x2=cx-math.floor(w/2),cx+math.floor(w/2)
        local z1,z2=cz-math.floor(d/2),cz+math.floor(d/2)
        local roof_z1,roof_z2=z1-1,z2+1

        -- The house owns only its own footprint and vertical volume.
        A.clear(x1,y(1),z1,x2,y(Z.house_height),z2)
        A.fill(x1,y(0),z1,x2,y(0),z2,M.floor)

        -- Ground floor: a solid stone perimeter around a real walkable room.
        A.fill(x1,y(1),z1,x2,y(5),z1,M.stone)
        A.fill(x1,y(1),z2,x2,y(5),z2,M.stone)
        A.fill(x1,y(1),z1,x1,y(5),z2,M.stone)
        A.fill(x2,y(1),z1,x2,y(5),z2,M.stone)
        A.clear(x1+1,y(2),z1+1,x2-1,y(4),z2-1)

        -- First-floor joists and upper storey.
        A.fill(x1+1,y(5),z1+1,x2-1,y(5),z2-1,M.wood)
        A.fill(x1,y(6),z1,x2,y(9),z1,M.plaster)
        A.fill(x1,y(6),z2,x2,y(9),z2,M.plaster)
        A.fill(x1,y(6),z1,x1,y(9),z2,M.plaster)
        A.fill(x2,y(6),z1,x2,y(9),z2,M.plaster)

        -- Timber framing: corner posts, intermediate posts and strong storey rails.
        A.fill(x1,y(6),z1,x2,y(6),z1,M.wood)
        A.fill(x1,y(9),z1,x2,y(9),z1,M.wood)
        A.fill(x1,y(6),z2,x2,y(6),z2,M.wood)
        A.fill(x1,y(9),z2,x2,y(9),z2,M.wood)
        A.fill(x1,y(6),z1,x1,y(9),z2,M.wood)
        A.fill(x2,y(6),z1,x2,y(9),z2,M.wood)
        for x=x1+2,x2-2,3 do
            A.fill(x,y(6),z1,x,y(9),z1,M.wood)
            A.fill(x,y(6),z2,x,y(9),z2,M.wood)
        end
        for z=z1+2,z2-2,3 do
            A.fill(x1,y(6),z,x1,y(9),z,M.wood)
            A.fill(x2,y(6),z,x2,y(9),z,M.wood)
        end

        -- Open doorway on the facade that faces the nearest inner street.
        local door_x1,door_x2,door_z1,door_z2
        if def.front=="east" then
            door_x1,door_x2,door_z1,door_z2=x2,x2,c z-1,c z+1
        elseif def.front=="west" then
            door_x1,door_x2,door_z1,door_z2=x1,x1,c z-1,c z+1
        elseif def.front=="north" then
            door_x1,door_x2,door_z1,door_z2=cx-1,cx+1,z1,z1
        else
            door_x1,door_x2,door_z1,door_z2=cx-1,cx+1,z2,z2
        end
        A.clear(door_x1,y(1),door_z1,door_x2,y(4),door_z2)
        if def.front=="east" or def.front=="west" then
            local face_x=(def.front=="east") and x2 or x1
            A.fill(face_x,y(1),cz-2,face_x,y(4),cz-2,M.trim)
            A.fill(face_x,y(1),cz+2,face_x,y(4),cz+2,M.trim)
            A.fill(face_x,y(5),cz-2,face_x,y(5),cz+2,M.wood)
        else
            local face_z=(def.front=="north") and z1 or z2
            A.fill(cx-2,y(1),face_z,cx-2,y(4),face_z,M.trim)
            A.fill(cx+2,y(1),face_z,cx+2,y(4),face_z,M.trim)
            A.fill(cx-2,y(5),face_z,cx+2,y(5),face_z,M.wood)
        end

        -- Ground-level windows on the walls not occupied by the door.
        for _,x in ipairs({cx-3,cx+3}) do
            if def.front~="north" then
                A.put(x,y(3),z1,M.trim)
                A.put(x,y(4),z1,M.glass)
            end
            if def.front~="south" then
                A.put(x,y(3),z2,M.trim)
                A.put(x,y(4),z2,M.glass)
            end
        end
        for _,z in ipairs({cz-3,cz+3}) do
            if def.front~="west" then
                A.put(x1,y(3),z,M.trim)
                A.put(x1,y(4),z,M.glass)
            end
            if def.front~="east" then
                A.put(x2,y(3),z,M.trim)
                A.put(x2,y(4),z,M.glass)
            end
        end

        -- Upper windows with dark wooden surrounds.
        if def.front=="east" or def.front=="west" then
            local face_x=(def.front=="east") and x2 or x1
            for _,z in ipairs({cz-2,cz+2}) do
                A.put(face_x,y(7),z,M.wood)
                A.put(face_x,y(8),z,M.glass)
                A.put(face_x,y(9),z,M.wood)
            end
        else
            local face_z=(def.front=="north") and z1 or z2
            for _,x in ipairs({cx-2,cx+2}) do
                A.put(x,y(7),face_z,M.wood)
                A.put(x,y(8),face_z,M.glass)
                A.put(x,y(9),face_z,M.wood)
            end
        end
        for _,x in ipairs({x1,x2}) do
            for _,z in ipairs({cz-2,cz+2}) do
                A.put(x,y(7),z,M.wood)
                A.put(x,y(8),z,M.glass)
                A.put(x,y(9),z,M.wood)
            end
        end

        -- Gabled terracotta roof, stepped inward toward a raised ridge.
        for layer=0,3 do
            local level=10+layer
            local west=x1+layer
            local east=x2-layer
            A.fill(west,y(level),roof_z1,west+1,y(level),roof_z2,M.tile_red)
            A.fill(east-1,y(level),roof_z1,east,y(level),roof_z2,M.tile_red)
        end
        A.fill(cx-1,y(14),roof_z1,cx+1,y(14),roof_z2,M.tile_red)

        -- Gable ends, visible wooden bargeboards and ridge caps.
        for _,z in ipairs({roof_z1,roof_z2}) do
            for layer=0,3 do
                local half=math.floor(w/2)-layer
                A.fill(cx-half,y(10+layer),z,cx+half,y(10+layer),z,M.plaster)
            end
            A.fill(cx-1,y(14),z,cx+1,y(14),z,M.wood)
            A.put(cx,y(15),z,M.gold)
        end
        A.fill(x1-1,y(9),z1-1,x1,y(9),z2+1,M.wood)
        A.fill(x2,y(9),z1-1,x2+1,y(9),z2+1,M.wood)

        -- A small chimney and a dormer-like roof accent distinguish each house.
        local chimney_x=(def.chimney=="west") and x1+1 or x2-1
        local chimney_z=(def.chimney=="north") and z1+1 or z2-1
        A.fill(chimney_x,y(11),chimney_z,chimney_x,y(15),chimney_z,M.stone)
        A.put(chimney_x,y(16),chimney_z,M.trim)

        -- Furnish the lower room without blocking its entrance.
        A.put(cx,y(1),cz,M.table)
        A.put(cx-2,y(1),cz+1,M.bench)
        A.put(cx+2,y(1),cz+1,M.bench)
        A.put(cx,y(4),cz,M.lamp)
        A.put(x1+1,y(1),z1+1,M.crate)

        -- Each roof and facade gets a different small heraldic detail.
        A.put(cx,y(9),roof_z2,M.banner)
    end

    function Z.build(base_y)
        if type(base_y)~="number" then
            return false,"Altitude du socle absente : construis d'abord la zone 00."
        end
        A.base_y=base_y

        local houses={
            {x=-27,z=-26,w=9,d=9,front="east",chimney="west"},
            {x=27,z=-26,w=9,d=9,front="west",chimney="east"},
            {x=-27,z=-8,w=9,d=8,front="east",chimney="north"},
            {x=27,z=-8,w=9,d=8,front="west",chimney="south"},
            {x=-27,z=10,w=9,d=9,front="east",chimney="west"},
            {x=27,z=10,w=9,d=9,front="west",chimney="east"},
            {x=-17,z=-1,w=9,d=9,front="east",chimney="north"},
            {x=17,z=-1,w=9,d=9,front="west",chimney="south"},
            {x=-27,z=27,w=9,d=9,front="east",chimney="north"},
            {x=27,z=27,w=9,d=9,front="west",chimney="south"},
        }
        for _,house in ipairs(houses) do build_house(house) end

        A.fix_light(Z.bounds)
        Z.ready=true
        minetest.log("action","[GDO][ZONE 50] Dix maisons à pans de bois et toitures en tuiles rouges.")
        return true,"Quartier résidentiel construit : dix maisons à pans de bois, pièces accessibles et toitures en pente."
    end

    return Z
end
