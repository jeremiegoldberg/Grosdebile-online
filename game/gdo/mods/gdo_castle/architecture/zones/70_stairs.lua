-- Zone 70: real stair flights for the first floor of the gatehouse.
-- Each flight climbs from the ground-floor room to the +9 tower floor.
-- Stair nodes are the project's two-tread nodebox; no full-cube support blocks.
return function(A)
    local Z={}
    Z.VERSION=1
    Z.bounds={x1=-15,x2=15,z1=27,z2=37}
    Z.rise=9
    Z.width=2

    local M=A.materials

    local function y(offset) return A.base_y+offset end

    local function build_flight(cx,side)
        local x1,x2
        if side=="west" then
            x1,x2=cx-3,cx-2
        else
            x1,x2=cx+2,cx+3
        end

        -- This module owns only the two stair columns. The +9 floor is
        -- opened by replacing its blocks with the final stair nodes.
        A.clear(x1,y(1),27,x2,y(Z.rise),35)

        -- Ascend toward +Z (from the courtyard-facing doorway toward the
        -- inner rear wall). The raised half of the nodebox faces +Z at param2=0.
        for step=1,Z.rise do
            local z=26+step
            for x=x1,x2 do
                A.put(x,y(step),z,M.stair,0)
            end
        end

        -- Level landing at the top, continuous with the first-floor surface.
        A.fill(x1,y(Z.rise),36,x2,y(Z.rise),37,M.trim)
        A.lamp(cx,y(Z.rise+2),37)
    end

    function Z.build(base_y)
        if type(base_y)~="number" then
            return false,"Altitude du socle absente : construis d'abord la zone 00."
        end
        A.base_y=base_y

        -- The west tower uses its west side; the east tower uses its east side.
        build_flight(-12,"west")
        build_flight(12,"east")

        A.fix_light(Z.bounds)
        Z.ready=true
        minetest.log("action","[GDO][ZONE 70] Deux escaliers de châtelet raccordent le rez-de-chaussée au premier étage.")
        return true,"Escaliers du châtelet construits : deux volées de deux blocs de large vers le premier étage."
    end

    return Z
end
