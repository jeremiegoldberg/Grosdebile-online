-- GDO — Sommières GIS runtime bootstrap (patch v2).
local modpath = minetest.get_modpath("gdo_city")

local function read_file(relative)
    local path = modpath .. "/" .. relative
    local file = assert(io.open(path, "rb"), "[GDO Sommières] Fichier absent : " .. path)
    local data = file:read("*a")
    file:close()
    return data
end

local function b64decode(data)
    local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    local map = {}
    for i = 1, #alphabet do map[alphabet:sub(i, i)] = i - 1 end
    data = data:gsub("[^%w%+/=]", "")
    local out, buffer, bits = {}, 0, 0
    for i = 1, #data do
        local char = data:sub(i, i)
        if char ~= "=" then
            local value = map[char]
            assert(value ~= nil, "[GDO Sommières] Fragment Base64 invalide.")
            buffer = buffer * 64 + value
            bits = bits + 6
            if bits >= 8 then
                bits = bits - 8
                out[#out + 1] = string.char(math.floor(buffer / 2 ^ bits) % 256)
                buffer = buffer % 2 ^ bits
            end
        end
    end
    return table.concat(out)
end

-- Each base64 fragment decodes to the next part of one continuous DEFLATE stream.
local core_parts = {}
for i = 0, 5 do
    core_parts[#core_parts + 1] = b64decode(read_file(string.format("data/sommieres_core.%03d.b64", i)))
end
local core_006 = read_file("data/sommieres_core.006a.b64") .. read_file("data/sommieres_core.006b.b64")
local core_007 = read_file("data/sommieres_core.007a.b64") .. read_file("data/sommieres_core.007b.b64")
core_parts[#core_parts + 1] = b64decode(core_006)
core_parts[#core_parts + 1] = b64decode(core_007)

local core_json = minetest.decompress(table.concat(core_parts), "deflate")
assert(core_json, "[GDO Sommières] Impossible de décompresser le relevé géographique.")
_G.__gdo_city_embedded_core = minetest.parse_json(core_json)
assert(_G.__gdo_city_embedded_core and _G.__gdo_city_embedded_core.buildings,
    "[GDO Sommières] Relevé géographique invalide.")

-- Restore BD TOPO / OSM building metadata removed from the compact GIS core.
local metadata_raw = minetest.decompress(
    b64decode(read_file("data/sommieres_building_metadata.b64")), "deflate")
assert(metadata_raw, "[GDO Sommières] Métadonnées des bâtiments invalides.")
local building_metadata = minetest.parse_json(metadata_raw)
assert(building_metadata, "[GDO Sommières] Métadonnées des bâtiments illisibles.")
local metadata_matches = 0
for _, b in ipairs(_G.__gdo_city_embedded_core.buildings) do
    local key = string.format("%.1f|%.1f|%.1f|%.1f",
        b.p[1][1], b.p[1][2], b.b, b.h)
    local source = building_metadata[key]
    if source then
        b.t, b.n, b.hist, b.id = source[1], source[2], source[3], source[4]
        metadata_matches = metadata_matches + 1
    else
        b.t = b.t or "yes"
    end
end
minetest.log("action", string.format(
    "[GDO][SOMMIERES] Métadonnées du ZIP restaurées : %d/%d bâtiments.",
    metadata_matches, #_G.__gdo_city_embedded_core.buildings))

local loader = loadstring or load
local function replace_once(source, needle, replacement)
    local first, last = string.find(source, needle, 1, true)
    assert(first, "[GDO Sommières] Patch SIG introuvable : " .. needle)
    local second = string.find(source, needle, last + 1, true)
    assert(not second, "[GDO Sommières] Patch SIG ambigu : " .. needle)
    return string.sub(source, 1, first - 1) .. replacement .. string.sub(source, last + 1)
end

local importer_source = minetest.decompress(read_file("gis_import.deflate"), "deflate")
assert(importer_source, "[GDO Sommières] Importeur GIS compressé invalide.")

local function replace_between(source, start_marker, end_marker, replacement)
    local first = string.find(source, start_marker, 1, true)
    assert(first, "[GDO Sommières] Début de bloc SIG introuvable.")
    local last = string.find(source, end_marker, first + #start_marker, true)
    assert(last, "[GDO Sommières] Fin de bloc SIG introuvable.")
    local second = string.find(source, start_marker, first + #start_marker, true)
    assert(not second, "[GDO Sommières] Bloc SIG ambigu.")
    return string.sub(source, 1, first - 1) .. replacement .. string.sub(source, last)
end

-- Use the measured height as a relative dimension, independent of rounding
-- the absolute elevation datum at the base and at the roof separately.
importer_source = replace_once(
    importer_source,
    "b._base_y = world_y(b.b, cfg)\n        b._top_y = world_y(b.b + b.h, cfg)",
    "b._base_y = world_y(b.b, cfg)\n        b._height_nodes = math.max(1, round(b.h or 0))\n        b._top_y = b._base_y + b._height_nodes"
)

-- OSM building-use class changes façade rhythm; footprint and measured height remain authoritative.
local window_renderer = [=[
local function register_wall_windows(set_block, b, ring, cfg, glass_id, sill_id, shutter_id, door_id)
    local kind = b.t or "yes"
    local spacing, floor_step, first_level = 5.5, 3, 3
    local use_shutters, wide_windows = true, false
    if kind == "tower" then
        spacing, floor_step, first_level = 7, 4, 4
        use_shutters = false
    elseif kind == "church" or kind == "temple" or kind == "castle" then
        spacing, floor_step, first_level = 8, 4, 4
        use_shutters = false
    elseif kind == "industrial" or kind == "retail" or kind == "office"
        or kind == "service" or kind == "greenhouse" then
        spacing, floor_step, first_level = 9, 4, 2
        use_shutters, wide_windows = false, true
    elseif kind == "apartments" or kind == "terrace" then
        spacing, floor_step, first_level = 4, 3, 3
    elseif kind == "detached" or kind == "farm" or kind == "hut" then
        spacing, floor_step, first_level = 7, 3, 3
    elseif kind == "school" or kind == "kindergarten" or kind == "civic"
        or kind == "government" or kind == "public" or kind == "hotel" then
        spacing, floor_step, first_level = 6, 3, 3
        use_shutters = false
    end

    local longest, longest_index = 0, nil
    for i = 1, #ring do
        local a, c = ring[i], ring[i % #ring + 1]
        local length = math.sqrt((c[1] - a[1]) ^ 2 + (c[2] - a[2]) ^ 2)
        if length > longest then longest, longest_index = length, i end
    end
    if longest < 4 or not longest_index then return end

    local floor_y, top_y = b._base_y, b._top_y
    for i = 1, #ring do
        local a, c = ring[i], ring[i % #ring + 1]
        local dx, dz = c[1] - a[1], c[2] - a[2]
        local length = math.sqrt(dx * dx + dz * dz)
        if length >= spacing then
            local count = math.floor(length / spacing)
            for n = 1, count do
                local t = n / (count + 1)
                local x = math.floor(a[1] + dx * t + 0.5)
                local z = math.floor(a[2] + dz * t + 0.5)
                local dominant_x = math.abs(dx) >= math.abs(dz)
                local width = wide_windows and 2 or 1
                for w = 0, width - 1 do
                    local wx, wz = x, z
                    if dominant_x then wx = x + (dx >= 0 and w or -w)
                    else wz = z + (dz >= 0 and w or -w) end
                    for fy = floor_y + first_level, top_y - 2, floor_step do
                        set_block(wx, fy, wz, glass_id)
                        set_block(wx, fy + 1, wz, glass_id)
                        if use_shutters then
                            set_block(wx, fy - 1, wz, sill_id)
                            if n % 2 == 1 then
                                if dominant_x then
                                    set_block(wx, fy, wz + (dz >= 0 and 1 or -1), shutter_id)
                                else
                                    set_block(wx + (dx >= 0 and -1 or 1), fy, wz, shutter_id)
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    local a, c = ring[longest_index], ring[longest_index % #ring + 1]
    local x = math.floor((a[1] + c[1]) / 2 + 0.5)
    local z = math.floor((a[2] + c[2]) / 2 + 0.5)
    set_block(x, floor_y + 1, z, door_id)
    set_block(x, floor_y + 2, z, door_id)
end

]=]
importer_source = replace_between(
    importer_source,
    "local function register_wall_windows(",
    "-- Build a complete GIS tile: RGE ALTI terrain, water, roads, measured buildings and trees.",
    window_renderer .. "-- Build a complete GIS tile: RGE ALTI terrain, water, roads, measured buildings and trees."
)

-- Roofs must be a one-node-thick sloped surface, not a solid mass between
-- the eaves and ridge. Keep the roof within the surveyed building footprint.
importer_source = replace_once(
    importer_source,
    "local W, D = math.max(0.5, w / 2 + 0.4), math.max(0.5, d / 2 + 0.4)",
    "local W, D = math.max(0.5, w / 2), math.max(0.5, d / 2)\n    -- Clip the roof to its surveyed rectangle; do not create fallback eaves outside it.\n    if math.abs(u) > W or math.abs(v) > D then return nil end"
)
importer_source = replace_once(
    importer_source,
    "for y = math.max(y_min, top_y + 1), math.min(y_max, roof_y) do set_block(x, y, z, roof_id) end",
    "if roof_y then set_block(x, roof_y, z, roof_id) end"
)

-- Keep road cells walkable when a surveyed building footprint overlaps them.
importer_source = replace_once(
    importer_source,
    "local tile_cache = {}",
    "local tile_cache = {}\n        local road_mask = {}"
)
importer_source = replace_once(
    importer_source,
    "set_block(x, road_y, z, surface_id)",
    "set_block(x, road_y, z, surface_id)\n                            road_mask[(z - lz1) * (lx2 - lx1 + 1) + (x - lx1) + 1] = true"
)
importer_source = replace_once(
    importer_source,
    "-- 4) Individual building footprints, measured heights and oriented roof planes.",
    "local function set_building_block(x, y, z, id)\n            if x < lx1 or x > lx2 or z < lz1 or z > lz2 then return end\n            local key = (z - lz1) * (lx2 - lx1 + 1) + (x - lx1) + 1\n            if road_mask[key] then return end\n            set_block(x, y, z, id)\n        end\n\n        -- 4) Individual building footprints, measured heights and oriented roof planes."
)

local building_renderer = [=[
-- 4) Individual building footprints: clear first, roof second, façades last.
local visible_buildings = {}
-- Pass 1: clear every footprint before placing any roof or wall. This prevents
-- a neighbour's interior-clearing pass from erasing an already-built façade.
for _, b in ipairs(buildings) do
    if bbox_hits(b._x1, b._x2, b._z1, b._z2, lx1, lx2, lz1, lz2, 1) then
        visible_buildings[#visible_buildings + 1] = b
        local floor_y, top_y = b._base_y, b._top_y
        local ax1, ax2 = math.max(lx1, math.floor(b._x1)), math.min(lx2, math.ceil(b._x2))
        local az1, az2 = math.max(lz1, math.floor(b._z1)), math.min(lz2, math.ceil(b._z2))
        for z = az1, az2 do
            for x = ax1, ax2 do
                if in_building(x + 0.5, z + 0.5, b) then
                    set_block(x, floor_y, z, ids.floor)
                    for y = floor_y + 1, math.min(y_max, top_y) do
                        set_block(x, y, z, ids.air)
                    end
                end
            end
        end
    end
end

-- Pass 2: one roof surface per building, using its measured type, dimensions,
-- orientation and roof rise from r.s, r.o and rh.
for _, b in ipairs(visible_buildings) do
    local ax1, ax2 = math.max(lx1, math.floor(b._x1)), math.min(lx2, math.ceil(b._x2))
    local az1, az2 = math.max(lz1, math.floor(b._z1)), math.min(lz2, math.ceil(b._z2))
    for z = az1, az2 do
        for x = ax1, ax2 do
            if in_building(x + 0.5, z + 0.5, b) then
                local roof_y = make_roof_height(b, x, z)
                if roof_y then set_block(x, roof_y, z, b._roof_id) end
            end
        end
    end
end

-- Pass 3: façades follow the individual polygon rings and the exact measured
-- building top. Type-aware windows are generated only after all clearing.
for _, b in ipairs(visible_buildings) do
    local floor_y, top_y = b._base_y, b._top_y
    local rings = {b.p}
    if b.ho then
        for _, hole in ipairs(b.ho) do rings[#rings + 1] = hole end
    end
    for _, ring in ipairs(rings) do
        for i = 1, #ring do
            local p0, p1 = ring[i], ring[i % #ring + 1]
            local dx, dz = p1[1] - p0[1], p1[2] - p0[2]
            local length = math.sqrt(dx * dx + dz * dz)
            local steps = math.max(1, math.ceil(length * 1.4))
            for step = 0, steps do
                local f = step / steps
                local x = math.floor(p0[1] + dx * f + 0.5)
                local z = math.floor(p0[2] + dz * f + 0.5)
                if x >= lx1 and x <= lx2 and z >= lz1 and z <= lz2 then
                    for y = floor_y - 1, top_y do
                        local wall_id = (y <= floor_y + 1) and ids.ashlar or b._wall_id
                        set_block(x, y, z, wall_id)
                    end
                    if step == 0 then
                        set_block(x, top_y, z, ids.limestone_trim)
                        set_block(x, floor_y + 2, z, ids.limestone_trim)
                    end
                end
            end
        end
    end
    register_wall_windows(set_block, b, b.p, cfg,
        ids.glass, ids.limestone_trim, ids.shutter, ids.door)
end

]=]
importer_source = replace_between(
    importer_source,
    "-- 4) Individual building footprints, measured heights and oriented roof planes.",
    "-- 4b) Covered lanes and passages mapped by OSM are kept open beneath the houses.",
    building_renderer .. "-- 4b) Covered lanes and passages mapped by OSM are kept open beneath the houses."
)
importer_source = replace_once(importer_source, "set_block(x, floor_y, z, ids.floor)", "set_building_block(x, floor_y, z, ids.floor)")
importer_source = replace_once(importer_source, "set_block(x, roof_y, z, roof_id)", "set_building_block(x, roof_y, z, roof_id)")
importer_source = replace_once(importer_source, "set_block(x, y, z, wall_id)", "set_building_block(x, y, z, wall_id)")
importer_source = replace_once(importer_source, "set_block(x, top_y, z, ids.limestone_trim)", "set_building_block(x, top_y, z, ids.limestone_trim)")
importer_source = replace_once(importer_source, "set_block(x, floor_y + 2, z, ids.limestone_trim)", "set_building_block(x, floor_y + 2, z, ids.limestone_trim)")
importer_source = replace_once(
    importer_source,
    "register_wall_windows(set_block, b, b.p, cfg, ids.glass, ids.limestone_trim, ids.shutter, ids.door)",
    "register_wall_windows(set_building_block, b, b.p, cfg, ids.glass, ids.limestone_trim, ids.shutter, ids.door)"
)
local importer_chunk, importer_err = loader(importer_source, "@gdo_city/gis_import.lua")
assert(importer_chunk, importer_err)
_G.__gdo_city_gis_importer = importer_chunk()

local renderer_source = minetest.decompress(read_file("renderer.deflate"), "deflate")
assert(renderer_source, "[GDO Sommières] Renderer GIS compressé invalide.")
renderer_source = replace_once(renderer_source, "local VERSION = 6", "local VERSION = 8")
local renderer_chunk, renderer_err = loader(renderer_source, "@gdo_city/renderer.lua")
assert(renderer_chunk, renderer_err)
renderer_chunk()

_G.__gdo_city_gis_importer = nil
_G.__gdo_city_embedded_core = nil

-- Enable the native Luanti minimap for the city. The client must support it
-- and must not have disabled minimap rendering in its own settings.
local function enable_city_minimap(player)
    if not player or not player.hud_set_flags then
        return
    end
    player:hud_set_flags({
        minimap = true,
        minimap_pos = true,
    })
end

minetest.register_on_joinplayer(enable_city_minimap)
minetest.register_on_respawnplayer(function(player)
    enable_city_minimap(player)
end)
