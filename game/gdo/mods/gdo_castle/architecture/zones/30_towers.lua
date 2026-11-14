-- Zone 30: four integrated corner towers of the curtain-wall enceinte.
-- Their wall-walk entrances align with the zone 10 parapet at base_y + 10.
return function(A)
    local Z={}
    Z.VERSION=1
    Z.bounds={x1=-44,x2=44,z1=-46,z2=44}
    Z.height=21

    local M=A.materials
    local function y(offset) return A.base_y+offset end

    local function in_outer(dx,dz)
        return math.max(math.abs(dx),math.abs(dz))<=6
            and math.abs(dx)+math.abs(dz)<=10
    end

    local function in_inner(dx,dz)
        return math.max(math.abs(dx),math.abs(dz))<=4
            and math.abs(dx)+math.abs(dz)<=7
    end

    local function build_tower(cx,cz,courtyard_side)
        -- Clear only this tower's 13x13 footprint. The overlap with zone 10
        -- is deliberate: the tower replaces the old corner core and absorbs
        -- the ends of both adjoining curtain walls.
        A.clear(cx-6,y(1),cz-6,cx+6,y(Z.height),cz+6)

        -- Chamfered octagonal shell, two blocks thick, around a hollow chamber.
        for level=1,17 do
            local material=(level<=2 or level==17) and M.trim or M.stone
            for dx=-6,6 do
                for dz=-6,6 do
                    if in_outer(dx,dz) and not in_inner(dx,dz) then
                        A.put(cx+dx,y(level),cz+dz,material)
                    end
                end
            end
        end

        -- Ground floor, connected wall-walk floor and roof terrace.
        for dx=-4,4 do
            for dz=-4,4 do
                if in_inner(dx,dz) then
                    A.put(cx+dx,y(0),cz+dz,M.floor)
                    A.put(cx+dx,y(10),cz+dz,M.floor)
                    A.put(cx+dx,y(18),cz+dz,M.roof)
                end
            end
        end
        -- Cornice overhang and crenellated roof parapet.
        for dx=-6,6 do
            for dz=-6,6 do
                if in_outer(dx,dz) and not in_inner(dx,dz) then
                    A.put(cx+dx,y(18),cz+dz,M.trim)
                    if (dx+dz)%2==0 then
                        A.put(cx+dx,y(19),cz+dz,M.trim)
                        A.put(cx+dx,y(20),cz+dz,M.trim)
                    end
                end
            end
        end

        -- Entry from the courtyard into the lower tower chamber.
        -- North-corner towers open south; south-corner towers open north.
        local front_z1,front_z2
        if courtyard_side=="south" then
            front_z1,front_z2=cz+5,cz+6
        else
            front_z1,front_z2=cz-6,cz-5
        end
        A.clear(cx-1,y(1),front_z1,cx+1,y(5),front_z2)
        A.fill(cx-1,y(0),front_z1,cx+1,y(0),front_z2,M.trim)
        for _,z in ipairs({front_z1,front_z2}) do
            A.fill(cx-2,y(1),z,cx-2,y(5),z,M.trim)
            A.fill(cx+2,y(1),z,cx+2,y(5),z,M.trim)
        end
        A.fill(cx-2,y(6),front_z1,cx+2,y(6),front_z2,M.trim)

        -- Four open galleries at parapet height connect both perpendicular
        -- curtain walks through the tower. Each opening is 3 wide x 4 high.
        A.clear(cx-6,y(11),cz-1,cx-5,y(14),cz+1)
        A.clear(cx+5,y(11),cz-1,cx+6,y(14),cz+1)
        A.clear(cx-1,y(11),cz-6,cx+1,y(14),cz-5)
        A.clear(cx-1,y(11),cz+5,cx+1,y(14),cz+6)

        -- Stone lintels above the four parapet connections.
        A.fill(cx-2,y(15),cz-6,cx+2,y(15),cz-5,M.trim)
        A.fill(cx-2,y(15),cz+5,cx+2,y(15),cz+6,M.trim)
        A.fill(cx-6,y(15),cz-2,cx-5,y(15),cz+2,M.trim)
        A.fill(cx+5,y(15),cz-2,cx+6,y(15),cz+2,M.trim)

        -- Arrow slits on the lower storey and glazed watch windows above.
        for _,offset in ipairs({-3,3}) do
            for _,zsign in ipairs({-1,1}) do
                local z=cz+zsign*6
                A.put(cx+offset,y(6),z,M.trim)
                A.put(cx+offset,y(7),z,M.glass)
                A.put(cx+offset,y(8),z,M.trim)
                A.put(cx+offset,y(15),z,M.trim)
                A.put(cx+offset,y(16),z,M.glass)
                A.put(cx+offset,y(17),z,M.trim)
            end
            for _,xsign in ipairs({-1,1}) do
                local x=cx+xsign*6
                A.put(x,y(6),cz+offset,M.trim)
                A.put(x,y(7),cz+offset,M.glass)
                A.put(x,y(8),cz+offset,M.trim)
                A.put(x,y(15),cz+offset,M.trim)
                A.put(x,y(16),cz+offset,M.glass)
                A.put(x,y(17),cz+offset,M.trim)
            end
        end

        -- Small corner quoins make the chamfered silhouette legible at a distance.
        for _,dx in ipairs({-4,4}) do
            for _,dz in ipairs({-4,4}) do
                A.fill(cx+dx,y(3),cz+dz,cx+dx,y(16),cz+dz,M.trim)
            end
        end

        A.lamp(cx,y(6),cz)
        A.lamp(cx,y(14),cz)
        A.put(cx,y(21),cz,M.gold)
    end

    function Z.build(base_y)
        if type(base_y)~="number" then
            return false,"Altitude du socle absente : construis d'abord la zone 00."
        end
        A.base_y=base_y

        build_tower(-37,-39,"south") -- north-west corner
        build_tower(37,-39,"south")  -- north-east corner
        build_tower(-37,37,"north")  -- south-west corner
        build_tower(37,37,"north")   -- south-east corner

        A.fix_light(Z.bounds)
        Z.ready=true
        minetest.log("action","[GDO][ZONE 30] Quatre tours d'angle intégrées aux courtines.")
        return true,"Zone 30 construite : quatre tours d'angle, entrées de cour et accès aux chemins de ronde."
    end

    return Z
end
