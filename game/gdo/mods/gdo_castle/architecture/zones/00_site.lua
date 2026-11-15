-- Zone 00: raised rocky spur for the medieval castle and lower village terrace.
return function(A)
    local Site = {}
    Site.VERSION = 4

    Site.bounds = {
        castle={x1=-70,x2=70,z1=-72,z2=90},
        village={x1=-43,x2=43,z1=80,z2=128},
    }

    local ELEVATION_RISE = 12
    local function median_for(bounds)
        local y,count,low,high=A.median_surface(bounds,4)
        if not y then return nil end
        minetest.log("action",string.format(
            "[GDO][SITE] Médiane du terrain: %d (%d points, min=%d, max=%d).",
            y,count,low,high))
        return y
    end

    local function build_rocky_motte(base_y)
        -- A broad natural-looking hill: the castle plateau is raised by 12m,
        -- but the slopes extend over roughly 28m instead of forming a cliff.
        local plateau = {x1=-41,x2=41,z1=-43,z2=62}
        for x=Site.bounds.castle.x1,Site.bounds.castle.x2 do
            for z=Site.bounds.castle.z1,Site.bounds.castle.z2 do
                local dx=math.max(plateau.x1-x,0,x-plateau.x2)
                local dz=math.max(plateau.z1-z,0,z-plateau.z2)
                local distance=math.max(dx,dz)
                local rise=math.max(0,ELEVATION_RISE-math.floor(distance/2.4))
                local top_y=base_y+rise
                if rise>0 then
                    A.fill(x,base_y+1,z,x,top_y-1,z,"gdo_core:terre")
                    A.put(x,top_y,z,A.materials.grass)
                    if rise>=3 and (x*17+z*31)%29==0 then
                        A.put(x,top_y,z,A.materials.stone)
                    end
                end
            end
        end
        A.deck(plateau.x1,plateau.z1,plateau.x2,plateau.z2,
            base_y+ELEVATION_RISE,A.materials.grass)
        return base_y+ELEVATION_RISE
    end

    local function build_ramp(castle_y,village_y)
        -- A broad stone approach leaves the gatehouse drawbridge, follows the
        -- east hillside, then eases down to the village level.
        local base_y=castle_y-ELEVATION_RISE
        local z_start,z_hill_end,z_end=58,90,128
        local x1,x2=41,45
        for z=z_start,z_end do
            local level
            if z<=z_hill_end then
                local drop=math.floor(math.max(0,z-62)/2.4)
                level=base_y+math.max(0,ELEVATION_RISE-drop)
            else
                local t=(z-z_hill_end)/(z_end-z_hill_end)
                level=math.floor(base_y+(village_y-base_y)*t+0.5)
            end
            A.fill(x1,level-3,z,x2,level-1,z,"gdo_core:terre")
            A.deck(x1+1,z,x2-1,z,level,A.materials.path)
            A.put(x1,level+1,z,A.materials.trim)
            A.put(x2,level+1,z,A.materials.trim)
            if z%12==0 then A.lamp(x1,level+2,z) end
        end
        A.deck(3,58,42,62,castle_y,A.materials.path)
    end

    function Site.build(saved_levels)
        saved_levels=saved_levels or {}
        local village_y=saved_levels.village_y or median_for(Site.bounds.village)
        local castle_ground
        if saved_levels.castle_y then
            -- Saved castle_y is the top of the mound in version 2; subtract its
            -- fixed rise so /gdo_site can rebuild without raising the castle again.
            castle_ground=saved_levels.castle_y-ELEVATION_RISE
        else
            castle_ground=median_for(Site.bounds.castle)
        end
        if not castle_ground or not village_y then
            return false,"Terrain naturel introuvable: socle non construit."
        end

        -- First restore the natural base, then shape a broad hill below the castle.
        A.flatten_rect(Site.bounds.castle,castle_ground,192)
        local n2=A.flatten_rect(Site.bounds.village,village_y,192)
        local castle_y=build_rocky_motte(castle_ground)

        -- Remove the obsolete straight connection before laying the gentle ramp.
        A.clear(-43,castle_ground+1,76,43,192,79)
        A.fill(-43,castle_ground-4,76,43,castle_ground-1,79,"gdo_core:terre")
        build_ramp(castle_y,village_y)

        A.fix_light({
            x1=Site.bounds.castle.x1,z1=Site.bounds.castle.z1,
            x2=Site.bounds.castle.x2,z2=Site.bounds.village.z2,
        })

        Site.castle_y=castle_y
        Site.village_y=village_y
        Site.ready=true
        minetest.log("action",string.format(
            "[GDO][SITE] Éperon rocheux terminé: base=%d, château Y=%d (+%d), village Y=%d (%d colonnes).",
            castle_ground,castle_y,ELEVATION_RISE,village_y,n2))
        return true,string.format(
            "Éperon rocheux construit. Château niveau %d, village niveau %d.",
            castle_y,village_y)
    end

    function Site.spawn(player)
        if not Site.ready or not player or not player:is_player() then return end
        player:set_pos({x=0,y=Site.castle_y+1,z=60})
        if player.set_velocity then player:set_velocity({x=0,y=0,z=0}) end
    end

    return Site
end
