-- Zone 40: Brukenthal-inspired central citadel.
-- The design uses a towering keep, unequal spired turrets, inhabited side wings,
-- an enclosed inner court and a covered entrance range. It is an original
-- adaptation for the GDO castle plan, not a block-for-block reproduction.
return function(A)
    local Z={}
    Z.VERSION=2
    Z.bounds={x1=-27,x2=27,z1=-38,z2=-4}
    Z.height=48

    local M=A.materials
    local function y(offset) return A.base_y+offset end

    local function build_round_tower(cx,cz,radius,height,door_side)
        -- Chamfered shell with a hollow core, strong plinth and projecting bands.
        for level=1,height do
            local outer_material=(level<=2 or level==8 or level==16 or level==height)
                and M.trim or M.stone
            for dx=-radius,radius do
                for dz=-radius,radius do
                    local ax,az=math.abs(dx),math.abs(dz)
                    local inside_outer=math.max(ax,az)<=radius
                        and ax+az<=radius*2-1
                    local inside_inner=math.max(ax,az)<=radius-1
                        and ax+az<=(radius-1)*2-1
                    if inside_outer and not inside_inner then
                        A.put(cx+dx,y(level),cz+dz,outer_material)
                    end
                end
            end
        end

        -- Three walkable levels inside the tower.
        for _,floor_level in ipairs({0,8,16,24}) do
            if floor_level<height then
                for dx=-(radius-1),radius-1 do
                    for dz=-(radius-1),radius-1 do
                        local ax,az=math.abs(dx),math.abs(dz)
                        if math.max(ax,az)<=radius-1
                            and ax+az<=(radius-1)*2-1 then
                            A.put(cx+dx,y(floor_level),cz+dz,M.floor)
                        end
                    end
                end
            end
        end

        -- Door opening connects the turret to its adjoining room or wing.
        if door_side=="east" then
            A.clear(cx+radius,y(1),cz-1,cx+radius,y(5),cz+1)
        elseif door_side=="west" then
            A.clear(cx-radius,y(1),cz-1,cx-radius,y(5),cz+1)
        elseif door_side=="north" then
            A.clear(cx-1,y(1),cz-radius,cx+1,y(5),cz-radius)
        elseif door_side=="south" then
            A.clear(cx-1,y(1),cz+radius,cx+1,y(5),cz+radius)
        end

        -- Slender paired windows on the exposed faces at several levels.
        for _,offset in ipairs({-1,1}) do
            if door_side~="north" then
                A.put(cx+offset,y(6),cz-radius,M.trim)
                A.put(cx+offset,y(7),cz-radius,M.glass)
                A.put(cx+offset,y(8),cz-radius,M.trim)
            end
            if door_side~="south" then
                A.put(cx+offset,y(6),cz+radius,M.trim)
                A.put(cx+offset,y(7),cz+radius,M.glass)
                A.put(cx+offset,y(8),cz+radius,M.trim)
            end
            if door_side~="west" then
                A.put(cx-radius,y(6),cz+offset,M.trim)
                A.put(cx-radius,y(7),cz+offset,M.glass)
                A.put(cx-radius,y(8),cz+offset,M.trim)
            end
            if door_side~="east" then
                A.put(cx+radius,y(6),cz+offset,M.trim)
                A.put(cx+radius,y(7),cz+offset,M.glass)
                A.put(cx+radius,y(8),cz+offset,M.trim)
            end
        end
        for _,floor_level in ipairs({14,22}) do
            for _,offset in ipairs({-1,1}) do
                local wz=cz+offset
                if door_side~="west" then
                    A.put(cx-radius,y(floor_level),wz,M.trim)
                    A.put(cx-radius,y(floor_level+1),wz,M.glass)
                    A.put(cx-radius,y(floor_level+2),wz,M.trim)
                end
                if door_side~="east" then
                    A.put(cx+radius,y(floor_level),wz,M.trim)
                    A.put(cx+radius,y(floor_level+1),wz,M.glass)
                    A.put(cx+radius,y(floor_level+2),wz,M.trim)
                end
            end
        end

        -- Strong corbels and an increasingly narrow slate spire.
        A.fill(cx-radius-1,y(height),cz-radius-1,
            cx+radius+1,y(height),cz+radius+1,M.trim)
        for layer=0,radius+2 do
            local inset=math.max(0,radius-layer)
            A.fill(cx-inset,y(height+1+layer),cz-inset,
                cx+inset,y(height+1+layer),cz+inset,M.roof)
        end
        A.put(cx,y(height+radius+4),cz,M.gold)
        A.lamp(cx,y(9),cz)
        A.lamp(cx,y(18),cz)
    end

    local function build_main_keep()
        -- High central block: a great hall below and two upper galleries.
        A.fill(-10,y(0),-36,10,y(0),-19,M.floor)
        A.fill(-10,y(1),-36,10,y(25),-19,M.stone)
        A.clear(-9,y(2),-35,9,y(25),-20)

        for _,floor_level in ipairs({8,16,24}) do
            A.fill(-9,y(floor_level),-35,9,y(floor_level),-20,M.floor)
        end

        -- Deep entrance to the keep, opening toward the inner courtyard.
        A.clear(-2,y(1),-19,2,y(6),-19)
        A.fill(-4,y(1),-19,-3,y(6),-19,M.trim)
        A.fill(3,y(1),-19,4,y(6),-19,M.trim)
        A.fill(-4,y(7),-19,4,y(7),-19,M.trim)
        A.put(0,y(8),-19,M.gold)

        -- Side doors lead into the two residential wings.
        A.clear(-10,y(1),-29,-10,y(5),-26)
        A.clear(10,y(1),-29,10,y(5),-26)
        A.fill(-11,y(1),-30,-11,y(5),-30,M.trim)
        A.fill(11,y(1),-30,11,y(5),-30,M.trim)

        -- Deep-set windows and horizontal string courses.
        for _,z in ipairs({-33,-29,-25,-21}) do
            if z~=-29 then
                for _,level in ipairs({6,14,22}) do
                    A.put(-10,y(level),z,M.trim)
                    A.put(-10,y(level+1),z,M.glass)
                    A.put(-10,y(level+2),z,M.trim)
                    A.put(10,y(level),z,M.trim)
                    A.put(10,y(level+1),z,M.glass)
                    A.put(10,y(level+2),z,M.trim)
                end
            end
        end
        for _,level in ipairs({8,16,24}) do
            A.fill(-10,y(level),-36,10,y(level),-36,M.trim)
            A.fill(-10,y(level),-19,10,y(level),-19,M.trim)
        end

        -- Massive inner columns and cross-vault supports.
        for _,x in ipairs({-7,-3,3,7}) do
            for _,z in ipairs({-32,-25}) do
                A.fill(x,y(1),z,x,y(23),z,M.trim)
                A.lamp(x,y(7),z)
                A.lamp(x,y(15),z)
            end
        end
        A.fill(-8,y(1),-30,8,y(1),-28,M.roof)
        A.fill(-6,y(2),-30,6,y(2),-28,M.trim)
        A.fill(-4,y(2),-29,4,y(2),-29,M.gold)
    end

    local function build_side_wing(side)
        local x1,x2
        if side=="west" then x1,x2=-25,-12 else x1,x2=12,25 end
        local z1,z2=-35,-7

        -- Two-storey residential wing. The upper storey uses plaster and
        -- exposed dark timber to contrast with the heavy central keep.
        A.fill(x1,y(0),z1,x2,y(0),z2,M.floor)
        A.fill(x1,y(1),z1,x2,y(14),z2,M.stone)
        A.clear(x1+1,y(2),z1+1,x2-1,y(13),z2-1)
        A.fill(x1+1,y(7),z1+1,x2-1,y(7),z2-1,M.floor)

        -- Outer walls are lighter on the upper storey, with timber framing.
        A.fill(x1+1,y(8),z1+1,x2-1,y(12),z1+1,M.plaster)
        A.fill(x1+1,y(8),z2-1,x2-1,y(12),z2-1,M.plaster)
        A.fill(x1+1,y(8),z1+1,x1+1,y(12),z2-1,M.plaster)
        A.fill(x2-1,y(8),z1+1,x2-1,y(12),z2-1,M.plaster)
        for _,x in ipairs({x1+1,x1+4,x2-4,x2-1}) do
            A.fill(x,y(8),z1+1,x,y(12),z1+1,M.wood)
            A.fill(x,y(8),z2-1,x,y(12),z2-1,M.wood)
        end
        A.fill(x1+1,y(8),z1+1,x2-1,y(8),z1+1,M.wood)
        A.fill(x1+1,y(12),z1+1,x2-1,y(12),z1+1,M.wood)
        A.fill(x1+1,y(8),z2-1,x2-1,y(8),z2-1,M.wood)
        A.fill(x1+1,y(12),z2-1,x2-1,y(12),z2-1,M.wood)

        -- Real doorways from each wing into the inner court.
        if side=="west" then
            A.clear(x2,y(1),-17,x2,y(5),-14)
            A.clear(x2,y(1),-29,x2,y(5),-26)
            A.clear(x2,y(8),-17,x2,y(11),-14)
        else
            A.clear(x1,y(1),-17,x1,y(5),-14)
            A.clear(x1,y(1),-29,x1,y(5),-26)
            A.clear(x1,y(8),-17,x1,y(11),-14)
        end

        -- Ground-level windows, upper casements and occasional stone piers.
        for _,z in ipairs({-32,-25,-19,-11}) do
            local face_x=(side=="west") and x1 or x2
            A.put(face_x,y(4),z,M.trim)
            A.put(face_x,y(5),z,M.glass)
            A.put(face_x,y(6),z,M.trim)
        end
        for _,z in ipairs({-31,-24,-10}) do
            local face_x=(side=="west") and x1 or x2
            A.put(face_x,y(9),z,M.wood)
            A.put(face_x,y(10),z,M.glass)
            A.put(face_x,y(11),z,M.wood)
        end
        for _,z in ipairs({-31,-23,-15}) do
            local x=(side=="west") and x2-2 or x1+2
            A.fill(x,y(1),z,x,y(13),z,M.trim)
            A.lamp(x,y(6),z)
        end

        -- Steep slate roof with long eaves and a raised ridge.
        for layer=0,6 do
            local level=15+layer
            local left=x1+layer
            local right=x2-layer
            A.fill(left,y(level),z1-1,left+1,y(level),z2+1,M.roof)
            A.fill(right-1,y(level),z1-1,right,y(level),z2+1,M.roof)
        end
        A.fill(math.floor((x1+x2)/2)-1,y(22),z1-1,
            math.floor((x1+x2)/2)+1,y(22),z2+1,M.trim)

        -- Gabled ends and timber bargeboards.
        for _,z in ipairs({z1-1,z2+1}) do
            for layer=0,5 do
                local half=6-layer
                A.fill(math.floor((x1+x2)/2)-half,y(15+layer),z,
                    math.floor((x1+x2)/2)+half,y(15+layer),z,
                    (layer%2==0) and M.trim or M.stone)
            end
            A.fill(math.floor((x1+x2)/2)-1,y(21),z,
                math.floor((x1+x2)/2)+1,y(21),z,M.wood)
            A.put(math.floor((x1+x2)/2),y(22),z,M.gold)
        end
        A.fill(x1,y(14),z1-1,x1+1,y(14),z2+1,M.wood)
        A.fill(x2-1,y(14),z1-1,x2,y(14),z2+1,M.wood)
    end

    local function build_south_range()
        -- Low entrance range closes the inner court on its southern side.
        A.fill(-12,y(0),-10,12,y(0),-4,M.floor)
        A.fill(-12,y(1),-10,12,y(12),-4,M.stone)
        A.clear(-11,y(2),-9,11,y(11),-5)

        A.fill(-11,y(7),-9,11,y(7),-5,M.floor)
        -- Main arch from the outer courtyard into the citadel.
        A.clear(-2,y(1),-4,2,y(6),-4)
        A.fill(-4,y(1),-4,-3,y(6),-4,M.trim)
        A.fill(3,y(1),-4,4,y(6),-4,M.trim)
        A.fill(-4,y(7),-4,4,y(7),-4,M.trim)
        A.put(0,y(8),-4,M.gold)

        -- Inner arch opens directly from the entrance range to the inner court.
        A.clear(-2,y(1),-10,2,y(6),-10)
        A.fill(-4,y(1),-10,-3,y(6),-10,M.trim)
        A.fill(3,y(1),-10,4,y(6),-10,M.trim)
        A.fill(-4,y(7),-10,4,y(7),-10,M.trim)

        -- Guard room windows and a roof terrace with merlons.
        for _,x in ipairs({-9,-6,6,9}) do
            A.put(x,y(4),-4,M.trim)
            A.put(x,y(5),-4,M.glass)
            A.put(x,y(4),-10,M.trim)
            A.put(x,y(5),-10,M.glass)
        end
        A.fill(-13,y(13),-11,13,y(13),-3,M.roof)
        A.fill(-13,y(14),-11,13,y(14),-3,M.trim)
        for x=-12,12,2 do
            if x%4==0 then A.fill(x,y(15),-11,x,y(16),-11,M.trim) end
            if x%4==0 then A.fill(x,y(15),-3,x,y(16),-3,M.trim) end
        end
        A.lamp(-8,y(10),-7)
        A.lamp(8,y(10),-7)
    end

    local function build_inner_court()
        -- An enclosed, open-air court between the main keep and the entrance range.
        A.fill(-10,y(0),-18,10,y(0),-11,M.path)
        A.fill(-10,y(0),-18,-9,y(0),-11,M.trim)
        A.fill(9,y(0),-18,10,y(0),-11,M.trim)
        A.fill(-1,y(0),-16,1,y(0),-13,M.trim)
        A.fill(0,y(1),-15,0,y(2),-14,M.water)
        A.put(-4,y(1),-15,M.lamp)
        A.put(4,y(1),-15,M.lamp)

        -- The courtyard remains open to the sky; upper circulation is planned
        -- as interior galleries in the wings and towers, not a roofed bridge.
    end

    function Z.build(base_y)
        if type(base_y)~="number" then
            return false,"Altitude du socle absente : construis d'abord la zone 00."
        end
        A.base_y=base_y

        -- Zone 40 owns only this compact citadel footprint, never the outer walls.
        A.clear(Z.bounds.x1,y(1),Z.bounds.z1,Z.bounds.x2,y(Z.height),Z.bounds.z2)

        build_main_keep()
        build_side_wing("west")
        build_side_wing("east")
        build_south_range()
        build_inner_court()

        -- One-block covered thresholds connect the main keep and wings.
        A.fill(-11,y(0),-30,-11,y(0),-14,M.floor)
        A.fill(11,y(0),-30,11,y(0),-14,M.floor)
        A.fill(-11,y(0),-18,-11,y(0),-11,M.path)
        A.fill(11,y(0),-18,11,y(0),-11,M.path)

        -- Four unequal spires on the keep and four lower turrets on the wings
        -- create the stepped skyline visible in the Brukenthal reference.
        build_round_tower(-10,-35,3,35,"east")
        build_round_tower(10,-35,3,40,"west")
        build_round_tower(-10,-20,3,30,"east")
        build_round_tower(10,-20,3,33,"west")
        build_round_tower(-23,-31,3,22,"east")
        build_round_tower(23,-31,3,25,"west")
        build_round_tower(-23,-9,3,19,"east")
        build_round_tower(23,-9,3,23,"west")

        A.fix_light(Z.bounds)
        Z.ready=true
        minetest.log("action","[GDO][ZONE 40] Citadelle gothique construite : donjon monumental, ailes, huit tours et cour intérieure.")
        return true,"Citadelle construite : donjon élancé, ailes habitées, huit tours, galerie haute et cour intérieure."
    end

    return Z
end
