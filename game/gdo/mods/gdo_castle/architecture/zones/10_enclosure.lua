-- Zone 10: defensive curtain walls and wall walks.
-- Towers, gatehouse, decorations and all staircases are separate future zones.
return function(A)
    local Z={}
    Z.VERSION=1
    Z.bounds={x1=-39,x2=39,z1=-41,z2=39}
    Z.wall_walk_y_offset=10
    Z.gate_gap={x1=-5,x2=5,z1=36,z2=38}

    local M=A.materials

    local function crenels_ns(x1,x2,z_outer,step_direction)
        for x=x1,x2 do
            local index=x-x1
            -- Two merlons, then one open crenel.
            if index%3~=2 then
                A.fill(x,A.base_y+11,z_outer,x,A.base_y+12,z_outer,M.trim)
            end
        end
    end

    local function crenels_ew(z1,z2,x_outer)
        for z=z1,z2 do
            local index=z-z1
            if index%3~=2 then
                A.fill(x_outer,A.base_y+11,z,x_outer,A.base_y+12,z,M.trim)
            end
        end
    end

    local function wall_ns(x1,x2,z_outer,inner_sign)
        local z1,z2
        if inner_sign>0 then
            z1,z2=z_outer,z_outer+2
        else
            z1,z2=z_outer-2,z_outer
        end
        -- Main curtain wall, ten blocks high above the site platform.
        A.fill(x1,A.base_y+1,z1,x2,A.base_y+9,z2,M.stone)
        -- Continuous upper wall walk, three blocks wide.
        A.fill(x1,A.base_y+10,z1,x2,A.base_y+10,z2,M.floor)
        -- Lower plinth course on the exterior face.
        A.fill(x1,A.base_y+1,z_outer,x2,A.base_y+2,z_outer,M.trim)
        crenels_ns(x1,x2,z_outer,inner_sign)

        -- Vertical stone piers reinforce long curtain-wall spans.
        for x=x1+7,x2-1,8 do
            A.fill(x,A.base_y+3,z_outer,x,A.base_y+9,z_outer,M.trim)
        end
    end

    local function wall_ew(z1,z2,x_outer,inner_sign)
        local x1,x2
        if inner_sign>0 then
            x1,x2=x_outer,x_outer+2
        else
            x1,x2=x_outer-2,x_outer
        end
        A.fill(x1,A.base_y+1,z1,x2,A.base_y+9,z2,M.stone)
        A.fill(x1,A.base_y+10,z1,x2,A.base_y+10,z2,M.floor)
        A.fill(x_outer,A.base_y+1,z1,x_outer,A.base_y+2,z2,M.trim)
        crenels_ew(z1,z2,x_outer)

        for z=z1+7,z2-1,8 do
            A.fill(x_outer,A.base_y+3,z,x_outer,A.base_y+9,z,M.trim)
        end
    end

    function Z.build(base_y)
        if type(base_y)~="number" then
            return false,"Altitude du socle absente : construis d'abord la zone 00."
        end
        A.base_y=base_y

        -- North curtain.
        wall_ns(-36,36,-40,1)
        -- West and east curtains.
        wall_ew(-38,38,-38,1)
        wall_ew(-38,38,38,-1)
        -- South curtain deliberately leaves an 11-block opening for zone 20.
        wall_ns(-36,-6,38,-1)
        wall_ns(6,36,38,-1)

        -- Corner blocks tie the four curtain walls together; future towers
        -- will surround these cores without requiring destructive cleanup.
        for _,p in ipairs({{-37,-39},{37,-39},{-37,37},{37,37}}) do
            A.fill(p[1]-1,A.base_y+1,p[2]-1,
                p[1]+1,A.base_y+12,p[2]+1,M.stone)
            A.fill(p[1]-1,A.base_y+10,p[2]-1,
                p[1]+1,A.base_y+10,p[2]+1,M.floor)
        end

        A.fix_light(Z.bounds)
        Z.ready=true
        minetest.log("action","[GDO][ZONE 10] Enceinte construite; passage sud réservé au châtelet.")
        return true,"Zone 10 construite : courtines, chemins de ronde et créneaux. Ouverture sud réservée."
    end

    return Z
end
