-- Zone 00: raised rocky spur for the medieval castle and lower village terrace.
return function(A)
    local Site = {}
    Site.VERSION = 2

    Site.bounds = {
        castle={x1=-43,x2=43,z1=-54,z2=75},
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
        -- A broad stepped rock mound, tapering every three blocks to a strong
        -- plateau wide enough for the complete curtain wall and corner towers.
        for rise=1,ELEVATION_RISE do
            local inset=math.floor((rise-1)/3)
            local x1,x2=Site.bounds.castle.x1+inset,Site.bounds.castle.x2-inset
            local z1,z2=Site.bounds.castle.z1+inset,Site.bounds.castle.z2-inset
            local level=base_y+rise
            A.fill(x1,level,z1,x2,level,z2,"gdo_core:terre")

            -- Exposed limestone courses form the visible retaining cliff.
            for x=x1,x2 do
                A.put(x,level,z1,A.materials.stone)
                A.put(x,level,z2,A.materials.stone)
            end
            for z=z1,z2 do
                A.put(x1,level,z,A.materials.stone)
                A.put(x2,level,z,A.materials.stone)
            end
        end

        local top_y=base_y+ELEVATION_RISE
        local inset=math.floor((ELEVATION_RISE-1)/3)
        A.deck(
            Site.bounds.castle.x1+inset,Site.bounds.castle.z1+inset,
            Site.bounds.castle.x2-inset,Site.bounds.castle.z2-inset,
            top_y,A.materials.grass)

        -- The exposed southern and eastern faces receive broken rock ledges,
        -- like the limestone spur above the Vidourle valley.
        for _,corner in ipairs({
            {Site.bounds.castle.x1+inset,Site.bounds.castle.z1+inset},
            {Site.bounds.castle.x2-inset,Site.bounds.castle.z1+inset},
            {Site.bounds.castle.x1+inset,Site.bounds.castle.z2-inset},
            {Site.bounds.castle.x2-inset,Site.bounds.castle.z2-inset},
        }) do
            A.fill(corner[1]-1,base_y+2,corner[2]-1,
                corner[1]+1,base_y+5,corner[2]+1,A.materials.trim)
        end
        return top_y
    end

    local function build_ramp(castle_y,village_y)
        -- A stepped, stone-paved approach descends the east flank to the village.
        local z_start,z_end=76,128
        local x1,x2=39,43
        for z=z_start,z_end do
            local t=(z-z_start)/(z_end-z_start)
            local level=math.floor(castle_y+(village_y-castle_y)*t+0.5)
            A.fill(x1,level-5,z,x2,level-1,z,"gdo_core:terre")
            A.fill(x1,level-5,z,x1,level-1,z,A.materials.stone)
            A.fill(x2,level-5,z,x2,level-1,z,A.materials.stone)
            A.deck(x1+1,z,x2-1,z,level,A.materials.path)
            A.put(x1,level+1,z,A.materials.trim)
            A.put(x2,level+1,z,A.materials.trim)
            if z%9==0 then
                A.lamp(x1,level+2,z)
                A.lamp(x2,level+2,z)
            end
        end
        -- A level landing joins the gate approach to the first ramp tread.
        A.deck(-5,76,38,79,castle_y,A.materials.path)
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

        -- First restore the natural base, then raise only the castle platform.
        A.flatten_rect(Site.bounds.castle,castle_ground,192)
        local n2=A.flatten_rect(Site.bounds.village,village_y,192)
        local castle_y=build_rocky_motte(castle_ground)

        -- Clear the old straight connection and replace it with a stepped descent.
        A.clear(-43,castle_ground+1,76,43,192,79)
        A.fill(-43,castle_ground-4,76,43,castle_ground-1,79,"gdo_core:terre")
        build_ramp(castle_y,village_y)

        A.fix_light({
            x1=Site.bounds.castle.x1,z1=Site.bounds.castle.z1,
            x2=Site.bounds.village.x2,z2=Site.bounds.village.z2,
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
        player:set_pos({x=0,y=Site.castle_y+1,z=68})
        if player.set_velocity then player:set_velocity({x=0,y=0,z=0}) end
    end

    return Site
end
