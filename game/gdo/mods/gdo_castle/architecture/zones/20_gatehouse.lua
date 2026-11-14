-- Zone 20: gatehouse passage, raised portcullis and drawbridge.
-- Gate towers and all staircases are separate future zones.
return function(A)
    local Z={}
    Z.VERSION=1
    Z.bounds={x1=-18,x2=18,z1=24,z2=61}
    Z.opening={x1=-3,x2=3,z1=33,z2=40}
    Z.drawbridge={x1=-3,x2=3,z1=42,z2=58}

    local M=A.materials
    local function y(offset) return A.base_y+offset end

    local function build_gate_jambs()
        -- Two thick jambs frame the central passage; no block enters its clear width.
        for _,x in ipairs({-5,-4,4,5}) do
            A.fill(x,y(1),31,x,y(9),42,M.stone)
            A.fill(x,y(1),35,x,y(2),39,M.trim)
            A.fill(x,y(8),35,x,y(9),39,M.trim)
        end

        -- Portal faces at the courtyard and moat sides.
        for _,z in ipairs({33,40}) do
            A.fill(-5,y(1),z,-4,y(9),z,M.trim)
            A.fill(4,y(1),z,5,y(9),z,M.trim)
            A.fill(-5,y(10),z,5,y(11),z,M.trim)
            A.fill(-6,y(12),z,6,y(12),z,M.stone)
        end

        -- Decorative voussoirs: a shallow stepped arch profile, leaving
        -- the 7-wide x=-3..3 passage completely open below the lintel.
        for x=-3,3 do
            local height=11+math.floor((3-math.abs(x))*0.45)
            A.put(x,y(height),33,M.stone)
            A.put(x,y(height),40,M.stone)
        end

        -- Heraldic keystones and lamps are outside the walking clearance.
        A.put(0,y(13),33,M.gold)
        A.put(0,y(13),40,M.gold)
        A.lamp(-6,y(7),34)
        A.lamp(6,y(7),34)
        A.lamp(-6,y(7),41)
        A.lamp(6,y(7),41)
    end

    local function build_portcullis()
        -- Raised grille sits above head height at the outer face of the portal.
        -- The central passage from y+1 through y+8 remains free.
        local z=37
        A.fill(-4,y(13),z,4,y(13),z,M.wood)
        for x=-3,3,2 do
            A.fill(x,y(9),z,x,y(12),z,M.wood)
            A.put(x,y(13),z,M.gold)
        end
        A.fill(-4,y(14),z,4,y(14),z,M.trim)
    end

    local function build_passage_floor()
        -- A continuous, level stone floor crosses the wall line.
        A.fill(-3,y(0),25,3,y(0),48,M.floor)
        -- Darker threshold strips mark the two faces without making steps.
        A.fill(-3,y(0),32,3,y(0),33,M.trim)
        A.fill(-3,y(0),40,3,y(0),41,M.trim)
    end

    local function build_drawbridge()
        -- Side channels form the visible moat; the central drawbridge remains
        -- a level, uninterrupted 7-wide route.
        A.fill(-17,y(0),49,-4,y(0),55,M.water)
        A.fill(4,y(0),49,17,y(0),55,M.water)

        -- Stone retaining edges around the moat.
        A.fill(-18,y(0),48,-4,y(0),48,M.trim)
        A.fill(-18,y(0),56,-4,y(0),56,M.trim)
        A.fill(4,y(0),48,18,y(0),48,M.trim)
        A.fill(4,y(0),56,18,y(0),56,M.trim)

        -- Seven-wide oak deck, laid as individual transverse planks.
        for z=42,58 do
            local material=(z%4==0) and M.trim or M.wood
            A.fill(-3,y(0),z,3,y(0),z,material)
        end

        -- Hinge beam and end beam, below the walking surface.
        A.fill(-4,y(-1),42,4,y(-1),43,M.stone)
        A.fill(-4,y(-1),57,4,y(-1),58,M.stone)
        A.fill(-4,y(1),42,4,y(1),42,M.trim)
        A.fill(-4,y(1),58,4,y(1),58,M.trim)

        -- Low edge posts and chain-like gold links stay outside the 7-wide deck.
        for _,x in ipairs({-4,4}) do
            for z=43,57,4 do
                A.put(x,y(1),z,M.wood)
                A.put(x,y(2),z,M.gold)
            end
            for z=45,55,4 do
                A.put(x,y(2),z,M.gold)
            end
        end

        -- Road transitions on both sides of the bridge.
        A.fill(-3,y(0),40,3,y(0),41,M.path)
        A.fill(-3,y(0),59,3,y(0),61,M.path)
        A.lamp(-6,y(2),45)
        A.lamp(6,y(2),45)
        A.lamp(-6,y(2),58)
        A.lamp(6,y(2),58)
    end

    function Z.build(base_y)
        if type(base_y)~="number" then
            return false,"Altitude du socle absente : construis d'abord la zone 00."
        end
        A.base_y=base_y

        build_passage_floor()
        build_gate_jambs()
        build_portcullis()
        build_drawbridge()

        A.fix_light(Z.bounds)
        Z.ready=true
        minetest.log("action","[GDO][ZONE 20] Châtelet construit; tours et escaliers exclus.")
        return true,"Zone 20 construite : passage, portail, herse relevée, fossés latéraux et pont-levis."
    end

    return Z
end
