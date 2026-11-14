-- Zone 20: monumental gatehouse.
-- Includes the two gate towers and upper guard gallery; corner towers are zone 30.
-- No staircases are generated here. Interior levels are reserved for zone 70.
return function(A)
    local Z={}
    Z.VERSION=4
    Z.bounds={x1=-18,x2=18,z1=24,z2=61}
    Z.opening={x1=-3,x2=3,z1=33,z2=40}
    Z.drawbridge={x1=-3,x2=3,z1=42,z2=58}
    Z.height=26

    local M=A.materials
    local function y(offset) return A.base_y+offset end

    local function clear_owned_volume()
        -- Zone 20 owns this footprint, including the part of the south curtain
        -- wall behind the gate towers. Rebuild it deterministically on every run.
        A.clear(Z.bounds.x1,y(1),Z.bounds.z1,
            Z.bounds.x2,y(Z.height),Z.bounds.z2)
    end

    local function build_gate_tower(cx)
        local x1,x2=cx-5,cx+5
        local z1,z2=25,43

        -- Solid 1-node shell around a hollow, two-level watch tower.
        A.fill(x1,y(1),z1,x2,y(18),z2,M.stone)
        A.clear(x1+1,y(2),z1+1,x2-1,y(18),z2-1)
        A.fill(x1+1,y(0),z1+1,x2-1,y(0),z2-1,M.floor)
        A.fill(x1+1,y(9),z1+1,x2-1,y(9),z2-1,M.floor)
        A.fill(x1+1,y(15),z1+1,x2-1,y(15),z2-1,M.floor)

        -- Heavy corner quoins and a projecting lower plinth.
        for _,p in ipairs({
            {x1,z1},{x1,z2},{x2,z1},{x2,z2},
        }) do
            local bx1=(p[1]==x1) and (x1-1) or x2
            local bx2=(p[1]==x1) and x1 or (x2+1)
            local bz1=(p[2]==z1) and (z1-1) or z2
            local bz2=(p[2]==z1) and z1 or (z2+1)
            -- Full-height two-by-two corner buttress, visibly projecting from the tower.
            A.fill(bx1,y(1),bz1,bx2,y(16),bz2,M.trim)
            A.fill(bx1,y(1),bz1,bx2,y(2),bz2,M.gold)
        end

        -- Wide ground-level entrance facing the inner courtyard (north side).
        -- The opening starts at the floor level so the player can actually walk in.
        A.clear(cx-1,y(1),z1,cx+1,y(5),z1)
        A.fill(cx-1,y(0),z1-1,cx+1,y(0),z1+1,M.trim)
        -- A clear stone frame marks the entrance without reducing its 3-node width.
        A.fill(cx-2,y(1),z1,cx-2,y(5),z1,M.trim)
        A.fill(cx+2,y(1),z1,cx+2,y(5),z1,M.trim)
        A.fill(cx-2,y(6),z1,cx+2,y(6),z1,M.trim)

        -- Narrow arrow slits and glazed watch windows on all four faces.
        for _,z in ipairs({z1,z2}) do
            for _,wx in ipairs({cx-2,cx+2}) do
                A.put(wx,y(6),z,M.trim)
                A.put(wx,y(7),z,M.glass)
                A.put(wx,y(8),z,M.trim)
                A.put(wx,y(13),z,M.trim)
                A.put(wx,y(14),z,M.glass)
                A.put(wx,y(15),z,M.trim)
            end
        end
        for _,x in ipairs({x1,x2}) do
            for _,wz in ipairs({30,38}) do
                A.put(x,y(6),wz,M.trim)
                A.put(x,y(7),wz,M.glass)
                A.put(x,y(8),wz,M.trim)
                A.put(x,y(13),wz,M.trim)
                A.put(x,y(14),wz,M.glass)
                A.put(x,y(15),wz,M.trim)
            end
        end

        -- Upper parapet walk and alternating merlons.
        A.fill(x1,y(19),z1,x2,y(19),z1,M.floor)
        A.fill(x1,y(19),z2,x2,y(19),z2,M.floor)
        A.fill(x1,y(19),z1,x1,y(19),z2,M.floor)
        A.fill(x2,y(19),z1,x2,y(19),z2,M.floor)
        for x=x1,x2 do
            if (x-x1)%2==0 then
                A.fill(x,y(20),z1,x,y(21),z1,M.trim)
                A.fill(x,y(20),z2,x,y(21),z2,M.trim)
            end
        end
        for z=z1,z2 do
            if (z-z1)%2==0 then
                A.fill(x1,y(20),z,x1,y(21),z,M.trim)
                A.fill(x2,y(20),z,x2,y(21),z,M.trim)
            end
        end

        -- Machicolation-style corbels above the outer face.
        local outer_z=(z2==43) and z2+1 or z1-1
        for x=x1+1,x2-1,2 do
            A.put(x,y(16),outer_z,M.trim)
            A.put(x,y(17),outer_z,M.floor)
        end

        A.lamp(cx,y(10),z1+1)
        A.lamp(cx,y(10),z2-1)
        A.put(cx,y(22),z2,M.gold)
    end

    local function build_wall_tie_ins()
        -- Zone 10 stops at X=-19 and X=19. These connector piers occupy
        -- the one-block gap and physically bind the south curtain to each tower.
        for _,x in ipairs({-18,18}) do
            A.fill(x,y(1),36,x,y(9),38,M.stone)
            -- Match the exterior trim and wall-walk elevation of the curtain.
            A.fill(x,y(1),38,x,y(2),38,M.trim)
            A.fill(x,y(10),36,x,y(10),38,M.floor)
            A.fill(x,y(11),38,x,y(12),38,M.trim)
        end
    end

    local function build_portal_arch()
        -- Deep stone portal cheeks; the central 7-wide passage stays open.
        for _,x in ipairs({-5,-4,4,5}) do
            A.fill(x,y(1),30,x,y(12),42,M.stone)
            A.fill(x,y(1),33,x,y(2),40,M.trim)
        end
        -- Extra engaged piers bind the arch to the two gate towers.
        A.fill(-6,y(1),33,-6,y(14),40,M.trim)
        A.fill(6,y(1),33,6,y(14),40,M.trim)

        -- Stepped pointed arch profile on both faces, above head clearance.
        for _,z in ipairs({32,41}) do
            for x=-3,3 do
                local rise=3-math.abs(x)
                local arch_y=9+rise
                A.put(x,y(arch_y),z,M.trim)
                if math.abs(x)<=1 then
                    A.put(x,y(arch_y-1),z,M.stone)
                end
            end
            A.fill(-6,y(13),z,6,y(13),z,M.trim)
        end

        -- Carved portal bands and central keystone.
        A.fill(-6,y(2),32,-6,y(12),32,M.trim)
        A.fill(6,y(2),32,6,y(12),32,M.trim)
        A.fill(-6,y(2),41,-6,y(12),41,M.trim)
        A.fill(6,y(2),41,6,y(12),41,M.trim)
        A.put(0,y(14),32,M.gold)
        A.put(0,y(14),41,M.gold)
        A.put(0,y(15),32,M.banner)
        A.put(0,y(15),41,M.banner)

        -- Sconces on the outside faces, clear of the passage.
        A.lamp(-7,y(7),32)
        A.lamp(7,y(7),32)
        A.lamp(-7,y(7),41)
        A.lamp(7,y(7),41)
    end

    local function build_upper_guard_gallery()
        -- A real upper gatehouse building bridges the two gate towers.
        -- Its floor is above the arch; nothing occupies the ground passage.
        A.fill(-7,y(15),26,7,y(15),42,M.floor)
        A.fill(-7,y(16),26,7,y(22),42,M.stone)
        A.clear(-6,y(16),27,6,y(21),41)

        -- Entrance doors connect the gallery with both towers.
        A.clear(-7,y(17),33,-7,y(20),36)
        A.clear(7,y(17),33,7,y(20),36)

        -- Paired narrow windows across the front and rear facades.
        for _,z in ipairs({26,42}) do
            for _,x in ipairs({-4,-2,0,2,4}) do
                A.put(x,y(18),z,M.trim)
                A.put(x,y(19),z,M.glass)
                A.put(x,y(20),z,M.glass)
                A.put(x,y(21),z,M.trim)
            end
            A.fill(-7,y(16),z,7,y(16),z,M.trim)
            A.fill(-7,y(22),z,7,y(22),z,M.trim)
        end

        -- Stone pilasters, timber braces and interior lighting.
        for _,x in ipairs({-7,7}) do
            A.fill(x,y(16),27,x,y(22),41,M.trim)
        end
        A.fill(-5,y(16),27,5,y(16),27,M.wood)
        A.fill(-5,y(16),41,5,y(16),41,M.wood)
        A.lamp(-4,y(20),30)
        A.lamp(4,y(20),30)
        A.lamp(-4,y(20),38)
        A.lamp(4,y(20),38)

        -- Flat defensive roof terrace with a crenellated stone parapet.
        A.fill(-7,y(23),26,7,y(23),42,M.roof)
        for x=-7,7 do
            if (x+7)%2==0 then
                A.fill(x,y(24),26,x,y(25),26,M.trim)
                A.fill(x,y(24),42,x,y(25),42,M.trim)
            end
        end
        for z=27,41 do
            if z%2==1 then
                A.fill(-7,y(24),z,-7,y(25),z,M.trim)
                A.fill(7,y(24),z,7,y(25),z,M.trim)
            end
        end

        -- A prominent heraldic crest identifies the castle entrance.
        A.fill(-1,y(24),42,1,y(24),42,M.gold)
        A.put(0,y(25),42,M.banner)
        A.put(0,y(26),42,M.gold)
    end

    local function build_portcullis()
        -- Grille is lifted above the 8-node walking clearance.
        local z=37
        A.fill(-4,y(13),z,4,y(13),z,M.trim)
        for x=-3,3 do
            A.fill(x,y(9),z,x,y(12),z,M.wood)
            A.put(x,y(12),z,M.gold)
        end
        A.fill(-4,y(14),z,4,y(14),z,M.trim)
        -- Deep guide grooves on the inner faces of the portal jambs.
        A.fill(-4,y(8),z,-4,y(14),z,M.gold)
        A.fill(4,y(8),z,4,y(14),z,M.gold)
    end

    local function build_passage_floor()
        A.fill(-3,y(0),25,3,y(0),48,M.floor)
        A.fill(-3,y(0),32,3,y(0),33,M.trim)
        A.fill(-3,y(0),40,3,y(0),41,M.trim)
        -- Side drainage channels sit outside the 7-wide pedestrian route.
        A.fill(-3,y(-1),30,-3,y(-1),41,M.stone)
        A.fill(3,y(-1),30,3,y(-1),41,M.stone)
    end

    local function build_drawbridge()
        -- The moat continues beneath the bridge on both sides.
        A.fill(-17,y(0),49,-4,y(0),55,M.water)
        A.fill(4,y(0),49,17,y(0),55,M.water)
        A.fill(-18,y(0),48,-4,y(0),48,M.trim)
        A.fill(-18,y(0),56,-4,y(0),56,M.trim)
        A.fill(4,y(0),48,18,y(0),48,M.trim)
        A.fill(4,y(0),56,18,y(0),56,M.trim)

        -- Distinct oak planks make the deck read as a bridge, not a road.
        for z=42,58 do
            -- The deck and the two approaches share exactly the same walking level.
            -- Flush threshold planks mark both ends without creating a raised step.
            local plank=(z==42 or z==58 or z%3==0) and M.trim or M.wood
            A.fill(-3,y(0),z,3,y(0),z,plank)
        end
        -- Structural stone sits below the deck, never above the walking surface.
        A.fill(-4,y(-1),42,4,y(-1),43,M.stone)
        A.fill(-4,y(-1),57,4,y(-1),58,M.stone)

        -- Side chains and anchor posts are outside the walking width.
        for _,x in ipairs({-4,4}) do
            for z=43,57,3 do
                A.fill(x,y(1),z,x,y(2),z,M.wood)
                A.put(x,y(3),z,M.gold)
            end
            A.fill(x,y(3),44,x,y(3),56,M.gold)
        end
        -- Massive hinge towers and winch drums.
        for _,x in ipairs({-5,5}) do
            A.fill(x,y(1),41,x,y(5),43,M.stone)
            A.fill(x-1,y(5),42,x+1,y(5),42,M.trim)
            A.put(x,y(6),42,M.gold)
        end
        A.lamp(-6,y(3),46)
        A.lamp(6,y(3),46)
        A.lamp(-6,y(3),58)
        A.lamp(6,y(3),58)
    end

    function Z.build(base_y)
        if type(base_y)~="number" then
            return false,"Altitude du socle absente : construis d'abord la zone 00."
        end
        A.base_y=base_y

        clear_owned_volume()
        build_passage_floor()
        build_gate_tower(-12)
        build_gate_tower(12)
        build_wall_tie_ins()
        build_portal_arch()
        build_upper_guard_gallery()
        build_portcullis()
        build_drawbridge()

        A.fix_light(Z.bounds)
        Z.ready=true
        minetest.log("action","[GDO][ZONE 20] Châtelet monumental construit: tours jumelles, galerie, herse et pont-levis.")
        return true,"Châtelet monumental reconstruit : tours jumelles, galerie haute, portail, herse et pont-levis."
    end

    return Z
end
