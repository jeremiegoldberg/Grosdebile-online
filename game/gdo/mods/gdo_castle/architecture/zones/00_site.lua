-- Zone 00: site, castle foundation and entry forecourt. No buildings here.
return function(A)
    local Site = {}
    Site.VERSION = 1

    Site.bounds = {
        castle={x1=-43,x2=43,z1=-54,z2=75},
        village={x1=-43,x2=43,z1=80,z2=128},
    }

    local function median_for(bounds)
        local y,count,low,high=A.median_surface(bounds,4)
        if not y then return nil end
        minetest.log("action",string.format(
            "[GDO][SITE] Médiane du terrain: %d (%d points, min=%d, max=%d).",
            y,count,low,high))
        return y
    end

    function Site.build(saved_levels)
        saved_levels=saved_levels or {}
        local castle_y=saved_levels.castle_y or median_for(Site.bounds.castle)
        local village_y=saved_levels.village_y or median_for(Site.bounds.village)
        if not castle_y or not village_y then
            return false,"Terrain naturel introuvable: socle non construit."
        end

        -- Build the principal castle pad first, then the independent village terrace.
        -- Both use a fixed surface elevation; individual buildings never sample slopes.
        local n1=A.flatten_rect(Site.bounds.castle,castle_y,192)
        local n2=A.flatten_rect(Site.bounds.village,village_y,192)

        -- Clear the narrow strip between the two terraces; its final road belongs
        -- to a later zone and must not be mistaken for an accidental raised ceiling.
        A.clear(-43,castle_y+1,76,43,192,79)
        A.fill(-43,castle_y-4,76,43,castle_y-1,79,"gdo_core:terre")
        A.deck(-43,76,43,79,castle_y,A.materials.grass)

        A.fix_light({
            x1=Site.bounds.castle.x1,z1=Site.bounds.castle.z1,
            x2=Site.bounds.village.x2,z2=Site.bounds.village.z2,
        })

        Site.castle_y=castle_y
        Site.village_y=village_y
        Site.ready=true
        minetest.log("action",string.format(
            "[GDO][SITE] Socle terminé: château Y=%d (%d colonnes), village Y=%d (%d colonnes).",
            castle_y,n1,village_y,n2))
        return true,string.format("Socle construit. Château niveau %d, village niveau %d.",castle_y,village_y)
    end

    function Site.spawn(player)
        if not Site.ready or not player or not player:is_player() then return end
        player:set_pos({x=0,y=Site.castle_y+1,z=68})
        if player.set_velocity then player:set_velocity({x=0,y=0,z=0}) end
    end

    return Site
end
