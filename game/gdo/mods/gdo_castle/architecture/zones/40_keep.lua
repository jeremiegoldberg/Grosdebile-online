-- Zone 40: central keep of the fortified castle-town.
-- A tall stone residence with four attached turrets and a steep gabled roof.
return function(A)
    local Z={}
    Z.VERSION=1
    Z.bounds={x1=-16,x2=16,z1=-37,z2=-5}
    Z.height=32

    local M=A.materials
    local function y(offset) return A.base_y+offset end

    local function build_turret(cx,cz,height)
        -- Octagonal turret shell; its hollow center merges with the keep rooms.
        for level=1,height do
            local material=(level<=2 or level==height) and M.trim or M.stone
            for dx=-3,3 do
                for dz=-3,3 do
                    local ax,az=math.abs(dx),math.abs(dz)
                    local edge=(math.max(ax,az)==3) and not (ax==3 and az==3)
                    if edge then A.put(cx+dx,y(level),cz+dz,material) end
                end
            end
        end

        -- Corbelled cap and a steep stepped roof, not a flat stone lid.
        A.fill(cx-3,y(height),cz-3,cx+3,y(height),cz+3,M.trim)
        for layer=0,3 do
            local radius=3-layer
            for dx=-radius,radius do
                for dz=-radius,radius do
                    if math.max(math.abs(dx),math.abs(dz))==radius then
                        A.put(cx+dx,y(height+1+layer),cz+dz,M.roof)
                    end
                end
            end
        end
        A.put(cx,y(height+5),cz,M.gold)

        -- Narrow windows on the exposed faces.
        for _,offset in ipairs({-1,1}) do
            A.put(cx+offset,y(6),cz-3,M.glass)
            A.put(cx+offset,y(6),cz+3,M.glass)
            A.put(cx-3,y(6),cz+offset,M.glass)
            A.put(cx+3,y(6),cz+offset,M.glass)
            A.put(cx+offset,y(13),cz-3,M.glass)
            A.put(cx+offset,y(13),cz+3,M.glass)
        end
        A.lamp(cx,y(9),cz)
    end

    local function build_keep_shell()
        -- Main rectangular keep: two habitable floors above the ground hall.
        A.fill(-12,y(0),-33,12,y(0),-9,M.floor)
        A.fill(-12,y(1),-33,12,y(18),-9,M.stone)
        A.clear(-11,y(2),-32,11,y(18),-10)

        -- Upper floors are continuous, but their rooms remain open and legible.
        A.fill(-11,y(8),-32,11,y(8),-10,M.floor)
        A.fill(-11,y(16),-32,11,y(16),-10,M.floor)

        -- Main entrance from the south courtyard.
        A.clear(-2,y(1),-9,2,y(6),-9)
        A.fill(-3,y(1),-9,-3,y(6),-9,M.trim)
        A.fill(3,y(1),-9,3,y(6),-9,M.trim)
        A.fill(-3,y(7),-9,3,y(7),-9,M.trim)
        -- Framed porch and shallow approach; the walking surface stays level.
        A.fill(-4,y(0),-8,4,y(0),-6,M.trim)
        for _,x in ipairs({-4,4}) do
            A.fill(x,y(1),-8,x,y(5),-8,M.trim)
            A.put(x,y(6),-8,M.gold)
        end
        A.fill(-4,y(6),-8,4,y(6),-8,M.wood)

        -- Tall front windows, paired to either side of the portal.
        for _,x in ipairs({-8,-6,6,8}) do
            A.put(x,y(5),-9,M.trim)
            A.put(x,y(6),-9,M.glass)
            A.put(x,y(7),-9,M.trim)
            A.put(x,y(12),-9,M.trim)
            A.put(x,y(13),-9,M.glass)
            A.put(x,y(14),-9,M.trim)
        end

        -- Recessed side windows on both long facades.
        for _,z in ipairs({-29,-24,-19,-14}) do
            for _,x in ipairs({-12,12}) do
                A.put(x,y(5),z,M.trim)
                A.put(x,y(6),z,M.glass)
                A.put(x,y(7),z,M.trim)
                A.put(x,y(12),z,M.trim)
                A.put(x,y(13),z,M.glass)
                A.put(x,y(14),z,M.trim)
            end
        end

        -- Rear windows overlook the northern curtain.
        for _,x in ipairs({-7,-3,3,7}) do
            A.put(x,y(6),-33,M.trim)
            A.put(x,y(7),-33,M.glass)
            A.put(x,y(13),-33,M.trim)
            A.put(x,y(14),-33,M.glass)
        end

        -- Interior pillars and warm lighting give the great room readable scale.
        for _,x in ipairs({-8,8}) do
            for _,z in ipairs({-28,-20,-12}) do
                A.fill(x,y(1),z,x,y(7),z,M.trim)
                A.lamp(x,y(7),z)
            end
        end
        A.fill(-5,y(1),-24,5,y(1),-18,M.roof)
        A.fill(-4,y(1),-23,4,y(1),-19,M.trim)
        A.fill(-3,y(1),-22,3,y(1),-20,M.gold)

        -- Upper gallery balustrade and central heraldic wall.
        A.fill(-10,y(9),-11,10,y(9),-11,M.trim)
        A.clear(-2,y(10),-11,2,y(13),-11)
        A.fill(-3,y(14),-11,3,y(14),-11,M.trim)
        A.put(0,y(13),-11,M.banner)
        A.lamp(0,y(14),-12)
    end

    local function build_gabled_roof()
        -- Steep two-pitch roof. Each course steps inward by one block,
        -- leaving a continuous ridge along the long axis of the building.
        for layer=0,11 do
            local west=-12+layer
            local east=11-layer
            local level=19+layer
            A.fill(west,y(level),-34,west+1,y(level),-8,M.roof)
            A.fill(east,y(level),-34,east+1,y(level),-8,M.roof)
        end
        A.fill(-1,y(30),-34,1,y(30),-8,M.trim)
        A.fill(-1,y(31),-34,1,y(31),-8,M.roof)

        -- Gable ends and timber braces on the south and north faces.
        for _,z in ipairs({-34,-8}) do
            for level=0,10 do
                local half=11-level
                A.fill(-half,y(19+level),z,half,y(19+level),z,
                    (level%2==0) and M.trim or M.stone)
            end
            A.fill(-2,y(30),z,2,y(30),z,M.wood)
            A.put(0,y(31),z,M.gold)
        end

        -- Eaves, ridge finials and roof lanterns.
        A.fill(-13,y(18),-34,-12,y(18),-8,M.wood)
        A.fill(12,y(18),-34,13,y(18),-8,M.wood)
        for _,z in ipairs({-31,-25,-17,-11}) do
            A.put(-6,y(24),z,M.gold)
            A.put(6,y(24),z,M.gold)
        end
        for _,z in ipairs({-30,-12}) do
            A.put(0,y(32),z,M.gold)
        end
    end

    function Z.build(base_y)
        if type(base_y)~="number" then
            return false,"Altitude du socle absente : construis d'abord la zone 00."
        end
        A.base_y=base_y

        -- The keep is separated from the northern curtain by a short forecourt
        -- and stays clear of the four corner towers.
        A.clear(Z.bounds.x1,y(1),Z.bounds.z1,Z.bounds.x2,y(Z.height),Z.bounds.z2)
        build_keep_shell()
        build_gabled_roof()
        -- Turrets are placed last so their roofs remain distinct above the
        -- main gabled roof instead of being overwritten by its roof courses.
        build_turret(-11,-32,23)
        build_turret(11,-32,25)
        build_turret(-11,-10,21)
        build_turret(11,-10,23)

        A.fix_light(Z.bounds)
        Z.ready=true
        minetest.log("action","[GDO][ZONE 40] Donjon central construit avec quatre tourelles et toiture à deux pans.")
        return true,"Zone 40 construite : donjon central, deux niveaux habitables, quatre tourelles et toit pentu."
    end

    return Z
end
