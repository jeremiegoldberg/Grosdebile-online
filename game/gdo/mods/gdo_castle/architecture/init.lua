-- GDO Castle Architecture bootstrap.
local modpath=minetest.get_modpath("gdo_castle")
local A=dofile(modpath.."/architecture/common.lua")
A.storage=gdo_castle_storage or minetest.get_mod_storage()
A.Site=dofile(modpath.."/architecture/zones/00_site.lua")(A)
A.Enclosure=dofile(modpath.."/architecture/zones/10_enclosure.lua")(A)
A.Gatehouse=dofile(modpath.."/architecture/zones/20_gatehouse.lua")(A)

local storage=A.storage
local SITE_KEY="architecture_site_version"
local LEVEL_CASTLE_KEY="architecture_castle_level"
local LEVEL_VILLAGE_KEY="architecture_village_level"
local ENCLOSURE_KEY="architecture_zone10_version"
local GATEHOUSE_KEY="architecture_zone20_version"
local building=false
local building_enclosure=false
local building_gatehouse=false

local function build_enclosure(force)
    if not A.Site.ready then
        return false,"La zone 00 doit être construite avant l'enceinte."
    end
    if building_enclosure then
        return false,"La génération de la zone 10 est déjà en cours."
    end
    if not force and storage:get_int(ENCLOSURE_KEY)>=A.Enclosure.VERSION then
        A.base_y=A.Site.castle_y
        A.Enclosure.ready=true
        return true,"Zone 10 déjà construite."
    end
    building_enclosure=true
    local ok,message=A.Enclosure.build(A.Site.castle_y)
    if ok then storage:set_int(ENCLOSURE_KEY,A.Enclosure.VERSION) end
    building_enclosure=false
    return ok,message
end

local function build_gatehouse(force)
    if not A.Site.ready then
        return false,"La zone 00 doit être construite avant le châtelet."
    end
    if storage:get_int(ENCLOSURE_KEY)<A.Enclosure.VERSION then
        return false,"La zone 10 doit être construite avant le châtelet."
    end
    if building_gatehouse then
        return false,"La génération de la zone 20 est déjà en cours."
    end
    if not force and storage:get_int(GATEHOUSE_KEY)>=A.Gatehouse.VERSION then
        A.base_y=A.Site.castle_y
        A.Gatehouse.ready=true
        return true,"Zone 20 déjà construite."
    end
    building_gatehouse=true
    local ok,message=A.Gatehouse.build(A.Site.castle_y)
    if ok then storage:set_int(GATEHOUSE_KEY,A.Gatehouse.VERSION) end
    building_gatehouse=false
    return ok,message
end

local function apply_spawn(player)
    if A.Site.ready then A.Site.spawn(player) end
end

local function build_site(saved_levels)
    if building then return false,"La génération du socle est déjà en cours." end
    building=true
    local ok,message=A.Site.build(saved_levels)
    if ok then
        storage:set_int(LEVEL_CASTLE_KEY,A.Site.castle_y)
        storage:set_int(LEVEL_VILLAGE_KEY,A.Site.village_y)
        storage:set_int(SITE_KEY,A.Site.VERSION)
        for _,player in ipairs(minetest.get_connected_players()) do apply_spawn(player) end
        local enclosure_ok,enclosure_message=build_enclosure(false)
        if not enclosure_ok then
            minetest.log("error","[GDO] "..enclosure_message)
        else
            local gate_ok,gate_message=build_gatehouse(false)
            if not gate_ok then minetest.log("error","[GDO] "..gate_message) end
        end
    end
    building=false
    return ok,message
end

minetest.register_chatcommand("gdo_site",{
    description="Reconstruit uniquement la zone 00 : terrain et socle",
    privs={server=true},
    func=function()
        local levels=nil
        if storage:get_int(SITE_KEY)>=A.Site.VERSION then
            -- Zero is a valid world altitude and must not be treated as "unset".
            levels={
                castle_y=storage:get_int(LEVEL_CASTLE_KEY),
                village_y=storage:get_int(LEVEL_VILLAGE_KEY),
            }
        end
        return build_site(levels)
    end,
})

minetest.register_chatcommand("gdo_zone10",{
    description="Reconstruit uniquement la zone 10 : enceinte et chemins de ronde",
    privs={server=true},
    func=function()
        return build_enclosure(true)
    end,
})

minetest.register_chatcommand("gdo_zone10_info",{
    description="Affiche l'état de l'enceinte fortifiée",
    func=function()
        return true,string.format("Zone 10: version %d/%d, prête=%s, altitude=%d",
            storage:get_int(ENCLOSURE_KEY),A.Enclosure.VERSION,
            A.Enclosure.ready and "oui" or "non",storage:get_int(LEVEL_CASTLE_KEY))
    end,
})

minetest.register_chatcommand("gdo_zone20",{
    description="Reconstruit uniquement la zone 20 : châtelet, herse et pont-levis",
    privs={server=true},
    func=function()
        return build_gatehouse(true)
    end,
})

minetest.register_chatcommand("gdo_zone20_info",{
    description="Affiche l'état du châtelet",
    func=function()
        return true,string.format("Zone 20: version %d/%d, prête=%s, altitude=%d",
            storage:get_int(GATEHOUSE_KEY),A.Gatehouse.VERSION,
            A.Gatehouse.ready and "oui" or "non",storage:get_int(LEVEL_CASTLE_KEY))
    end,
})

minetest.register_chatcommand("gdo_site_info",{
    description="Affiche l'état du socle architectural",
    func=function()
        return true,string.format("Zone 00: version %d, château Y=%d, village Y=%d, prêt=%s",
            storage:get_int(SITE_KEY),storage:get_int(LEVEL_CASTLE_KEY),
            storage:get_int(LEVEL_VILLAGE_KEY),A.Site.ready and "oui" or "non")
    end,
})

minetest.register_on_joinplayer(function(player)
    minetest.after(3,function() apply_spawn(player) end)
end)
minetest.register_on_respawnplayer(function(player)
    apply_spawn(player)
    return true
end)

local function prepare_site()
    if building then return end
    local saved_version=storage:get_int(SITE_KEY)
    if saved_version>=A.Site.VERSION then
        A.Site.castle_y=storage:get_int(LEVEL_CASTLE_KEY)
        A.Site.village_y=storage:get_int(LEVEL_VILLAGE_KEY)
        A.Site.ready=true
        A.base_y=A.Site.castle_y
        for _,player in ipairs(minetest.get_connected_players()) do apply_spawn(player) end
        local enclosure_ok,enclosure_message=build_enclosure(false)
        if not enclosure_ok then
            minetest.log("error","[GDO] "..enclosure_message)
        else
            local gate_ok,gate_message=build_gatehouse(false)
            if not gate_ok then minetest.log("error","[GDO] "..gate_message) end
        end
        minetest.log("action","[GDO] Zone 00 déjà construite; altitude restaurée.")
        return
    end

    building=true
    local failed=false
    minetest.emerge_area(
        {x=-48,y=-32,z=-60},
        {x=48,y=192,z=132},
        function(_,action,remaining)
            if action==minetest.EMERGE_ERRORED or action==minetest.EMERGE_CANCELLED then failed=true end
            if remaining==0 then
                building=false
                if failed then
                    minetest.log("error","[GDO] Échec du chargement du terrain pour la zone 00.")
                    return
                end
                local ok,message=build_site()
                if not ok then minetest.log("error","[GDO] "..message) end
            end
        end
    )
end

minetest.register_on_mods_loaded(function()
    minetest.after(3,prepare_site)
end)

minetest.log("action","[GDO] Architecture modulaire chargée. Zone active: 00_site.")
