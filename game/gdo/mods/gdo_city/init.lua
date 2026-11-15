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

-- Optional full-resolution GIS package generated from the original Sommières 3D ZIP.
-- The compact fallback is kept for installations that have not installed the full package.
local full_gis_file = io.open(modpath .. "/data/sommieres_full_gis.b64", "rb")
if full_gis_file then
    local packed_full_gis = full_gis_file:read("*a")
    full_gis_file:close()
    local full_gis_raw = minetest.decompress(b64decode(packed_full_gis), "deflate")
    assert(full_gis_raw, "[GDO Sommières] Archive SIG complète illisible.")
    local full_gis = minetest.parse_json(full_gis_raw)
    assert(full_gis and full_gis.buildings and full_gis.roads and full_gis.terrain
        and full_gis.water and full_gis.nature and full_gis.pois,
        "[GDO Sommières] Archive SIG complète incomplète.")
    local core = _G.__gdo_city_embedded_core
    for _, layer in ipairs({"buildings", "roads", "terrain", "water", "nature", "pois"}) do
        core[layer] = full_gis[layer]
    end
    minetest.log("action", string.format(
        "[GDO][SOMMIERES] SIG haute résolution chargé : %d bâtiments, %d routes, %d arbres, %d POI.",
        #core.buildings, #core.roads, #(core.nature.trees or {}), #core.pois))
else
    minetest.log("warning",
        "[GDO][SOMMIERES] ATTENTION : SIG compact actif (815 empreintes simplifiées). Le village détaillé exige game/gdo/mods/gdo_city/data/sommieres_full_gis.b64 ; génère-le avec : python3 tools/build_sommieres_gis.py /chemin/vers/sommieres3d.zip")
end
-- Extended Vidourle corridor and matching IGN terrain crop from the Sommières 3D archive.
local hydrology_raw = minetest.decompress(
    b64decode(read_file("data/sommieres_hydrology.b64")), "deflate")
assert(hydrology_raw, "[GDO Sommières] Extension hydrologique invalide.")
local hydrology = minetest.parse_json(hydrology_raw)
assert(hydrology and hydrology.terrain and hydrology.lines and hydrology.lines[1],
    "[GDO Sommières] Tracé du Vidourle ou terrain étendu manquant.")
_G.__gdo_city_embedded_core.terrain_extension = hydrology.terrain
local retained_water_lines = {}
for _, line in ipairs((_G.__gdo_city_embedded_core.water and _G.__gdo_city_embedded_core.water.lines) or {}) do
    if line.n ~= "Le Vidourle" then
        retained_water_lines[#retained_water_lines + 1] = line
    end
end
for _, line in ipairs(hydrology.lines) do
    retained_water_lines[#retained_water_lines + 1] = line
end
_G.__gdo_city_embedded_core.water = _G.__gdo_city_embedded_core.water or {}
_G.__gdo_city_embedded_core.water.lines = retained_water_lines
minetest.log("action", string.format(
    "[GDO][SOMMIERES] Vidourle étendu : %d points ; DEM IGN %dx%d.",
    #hydrology.lines[1].p, hydrology.terrain.nx, hydrology.terrain.nz))


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
    "[GDO][SOMMIERES] Typologies/noms connus du ZIP restaurés : %d/%d bâtiments (les autres n'ont pas de fiche typologique distincte).",
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
    return string.sub(source, 1, first - 1) .. replacement .. string.sub(source, last)
end

-- Include both contiguous Pont Tibère GIS segments: six main spans plus the short approach span.
importer_source = replace_once(
    importer_source,
    "if length > 30 then pont_tibere[#pont_tibere + 1] = {road = r, length = length} end",
    "if length > 5 then pont_tibere[#pont_tibere + 1] = {road = r, length = length} end"
)

-- Terrain crop selection and transition blending are applied together below.

-- Add small 32m map tiles touched by the river line; no large rectangular extension.
local base_tile_loop = [=[    for z0 = tz0, tz1 - 1, tile do
        for x0 = tx0, tx1 - 1, tile do
            tiles[#tiles + 1] = {x0, math.min(x0 + tile - 1, math.ceil(x2)), z0, math.min(z0 + tile - 1, math.ceil(z2))}
        end
    end]=]
local extended_tile_loop = [=[    for z0 = tz0, tz1 - 1, tile do
        for x0 = tx0, tx1 - 1, tile do
            tiles[#tiles + 1] = {x0, math.min(x0 + tile - 1, math.ceil(x2)), z0, math.min(z0 + tile - 1, math.ceil(z2))}
        end
    end

    -- Add only narrow 32m tiles intersecting the surveyed river corridor.
    local tile_seen = {}
    for _, td in ipairs(tiles) do tile_seen[td[1] .. ":" .. td[3]] = true end
    for _, line in ipairs((data.water and data.water.lines) or {}) do
        if line.n == "Le Vidourle" and line.p and #line.p > 1 then
            local margin = 40
            for i = 1, #line.p - 1 do
                local a, b = line.p[i], line.p[i + 1]
                local gx1 = math.max(data.terrain_extension.xmin, math.min(a[1], b[1]) - margin)
                local gx2 = math.min(data.terrain_extension.xmax, math.max(a[1], b[1]) + margin)
                local gz1 = math.max(data.terrain_extension.zmin, math.min(a[2], b[2]) - margin)
                local gz2 = math.min(data.terrain_extension.zmax, math.max(a[2], b[2]) + margin)
                if gx1 <= gx2 and gz1 <= gz2 then
                    local x0, xlast = math.floor(gx1 / tile) * tile, math.floor(gx2 / tile) * tile
                    local z0, zlast = math.floor(gz1 / tile) * tile, math.floor(gz2 / tile) * tile
                    for tz = z0, zlast, tile do
                        for tx = x0, xlast, tile do
                            local key = tx .. ":" .. tz
                            if not tile_seen[key] then
                                tiles[#tiles + 1] = {tx, tx + tile - 1, tz, tz + tile - 1, true}
                                tile_seen[key] = true
                            end
                        end
                    end
                end
            end
        end
    end]=]
importer_source = replace_once(importer_source, base_tile_loop, extended_tile_loop)
-- Water follows the surveyed river centerline and elevations; adjoining banks become gravel shelves.
local road_marker = "-- 3) Street and square surfaces. Elevation values come from the GIS road centre-lines."
local river_layer = [=[
        -- 2b) Extended Vidourle, rasterised from its measured centerline and per-point elevations.
        for _, line in ipairs((data.water and data.water.lines) or {}) do
            if line.n == "Le Vidourle" and line.p and #line.p > 1 then
                local radius = 32
                local radius2, bank2 = radius * radius, (radius + 5) * (radius + 5)
                for i = 1, #line.p - 1 do
                    local a, b = line.p[i], line.p[i + 1]
                    local margin = radius + 5
                    local ax1 = math.max(lx1, math.floor(math.min(a[1], b[1]) - margin))
                    local ax2 = math.min(lx2, math.ceil(math.max(a[1], b[1]) + margin))
                    local az1 = math.max(lz1, math.floor(math.min(a[2], b[2]) - margin))
                    local az2 = math.min(lz2, math.ceil(math.max(a[2], b[2]) + margin))
                    if ax1 <= ax2 and az1 <= az2 then
                        local ya = (line.y and line.y[i]) or 20.5
                        local yb = (line.y and line.y[i + 1]) or 20.5
                        for z = az1, az2 do
                            for x = ax1, ax2 do
                                local dist2, f = nearest_segment(x + 0.5, z + 0.5,
                                    a[1], a[2], b[1], b[2])
                                local elev = ya + (yb - ya) * f
                                local water_y = world_y(elev, cfg)
                                if not (x + 0.5 >= t.xmin and x + 0.5 <= t.xmax and z + 0.5 >= t.zmin and z + 0.5 <= t.zmax) and dist2 <= radius2 then
                                    local ground = get_surface(x, z)
                                    local bed = math.max(y_min + 1, math.min(ground - 1, water_y - 4))
                                    set_block(x, bed, z, ids.riverbed)
                                    for y = bed + 1, math.min(y_max, water_y) do
                                        set_block(x, y, z, ids.water)
                                    end
                                    for y = water_y + 1, math.min(y_max, ground) do
                                        set_block(x, y, z, ids.air)
                                    end
                                elseif not (x + 0.5 >= t.xmin and x + 0.5 <= t.xmax and z + 0.5 >= t.zmin and z + 0.5 <= t.zmax) and dist2 <= bank2 then
                                    local ground = get_surface(x, z)
                                    if ground >= water_y and ground <= water_y + 5 then
                                        set_block(x, ground, z, ids.river_pebbles)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

]=]
importer_source = replace_once(importer_source, road_marker, river_layer .. road_marker)

-- Bridge and historic street surfaces are selected in one consolidated road pass.

-- Rebuild the Roman bridge as a sequence of open arches, piers and pointed cutwaters.
local bridge_start = "-- 3b) Pont Tibère : arches maçonnées sous le tablier, dans son axe diagonal relevé."
local bridge_end = "-- 4) Individual building footprints, measured heights and oriented roof planes."
local bridge_renderer = [=[
-- 3b) Pont Tibère : arches romaines ouvertes, piles massives et avant-becs.
        for _, bridge in ipairs(pont_tibere) do
            local r, pts, length = bridge.road, bridge.road.p, bridge.length
            local count = clamp(round(length / 12), 1, 8)
            local span = length / count
            local cumulative, walked = {}, 0
            for i = 1, #pts - 1 do
                local a, b = pts[i], pts[i + 1]
                local dx, dz = b[1] - a[1], b[2] - a[2]
                local seglen = math.sqrt(dx * dx + dz * dz)
                cumulative[#cumulative + 1] = {
                    a = a, b = b, start = walked, finish = walked + seglen,
                    len = seglen, dx = dx, dz = dz,
                }
                walked = walked + seglen
            end

            local function sample_bridge(distance)
                local seg = cumulative[#cumulative]
                for _, candidate in ipairs(cumulative) do
                    if distance <= candidate.finish then seg = candidate; break end
                end
                local f = clamp((distance - seg.start) / math.max(0.01, seg.len), 0, 1)
                local tx, tz = seg.dx / math.max(0.01, seg.len), seg.dz / math.max(0.01, seg.len)
                local elev = (seg.a[3] or 25.18) + ((seg.b[3] or 25.18) - (seg.a[3] or 25.18)) * f
                return seg.a[1] + seg.dx * f, seg.a[2] + seg.dz * f, tx, tz, elev
            end

            local half_width = math.max(3, math.floor((r.w or 7.2) / 2))
            local bed_y = world_y(17.5, cfg)
            local spring_y = bed_y + 2
            local arch_rise = 3

            -- Abutments tie both ends into the river banks.
            for _, distance in ipairs({0, length}) do
                local cx, cz, tx, tz = sample_bridge(distance)
                local nx, nz = -tz, tx
                for along = -2, 2 do
                    for lateral = -half_width - 1, half_width + 1 do
                        local px = round(cx + tx * along + nx * lateral)
                        local pz = round(cz + tz * along + nz * lateral)
                        if px >= lx1 and px <= lx2 and pz >= lz1 and pz <= lz2 then
                            for y = bed_y, spring_y + 1 do
                                set_block(px, y, pz, ids.bridge_stone)
                            end
                        end
                    end
                end
            end

            -- Spandrels sit above a real curved intrados; water openings stay hollow.
            for arch = 0, count - 1 do
                local steps = math.max(8, math.ceil(span * 2))
                for step = 0, steps do
                    local t = step / steps
                    local distance = arch * span + t * span
                    local cx, cz, tx, tz, deck_elev = sample_bridge(distance)
                    local nx, nz = -tz, tx
                    local deck_y = world_y(deck_elev, cfg)
                    local curve = math.sqrt(math.max(0, 1 - (2 * t - 1) ^ 2))
                    local intrados = spring_y + round(arch_rise * curve)
                    for lateral = -half_width, half_width do
                        local px = round(cx + nx * lateral)
                        local pz = round(cz + nz * lateral)
                        if px >= lx1 and px <= lx2 and pz >= lz1 and pz <= lz2 then
                            if step % 2 == 0 then
                                set_block(px, intrados, pz, ids.limestone_trim)
                                set_block(px, intrados + 1, pz, ids.bridge_stone)
                            else
                                set_block(px, intrados, pz, ids.bridge_stone)
                            end
                            for y = intrados + 2, deck_y - 1 do
                                set_block(px, y, pz, ids.bridge_stone)
                            end
                        end
                    end
                end
            end

            -- Transverse piers at the springing points and triangular cutwaters on both sides.
            for pier = 0, count do
                local cx, cz, tx, tz = sample_bridge(pier * span)
                local nx, nz = -tz, tx
                for along = -1, 1 do
                    for lateral = -half_width, half_width do
                        local px = round(cx + tx * along + nx * lateral)
                        local pz = round(cz + tz * along + nz * lateral)
                        if px >= lx1 and px <= lx2 and pz >= lz1 and pz <= lz2 then
                            for y = bed_y, spring_y + arch_rise do
                                set_block(px, y, pz, ids.bridge_stone)
                            end
                        end
                    end
                end
                for _, side in ipairs({-1, 1}) do
                    for projection = 1, 3 do
                        local half_along = 3 - projection
                        for along = -half_along, half_along do
                            local px = round(cx + tx * along + nx * side * (half_width + projection))
                            local pz = round(cz + tz * along + nz * side * (half_width + projection))
                            if px >= lx1 and px <= lx2 and pz >= lz1 and pz <= lz2 then
                                for y = bed_y, bed_y + 2 do
                                    set_block(px, y, pz, ids.bridge_stone)
                                end
                            end
                        end
                    end
                end
            end

            -- Stone parapets and regularly spaced posts.
            for _, seg in ipairs(cumulative) do
                local steps = math.max(1, math.ceil(seg.len))
                for i = 0, steps do
                    local f = i / steps
                    local cx = seg.a[1] + seg.dx * f
                    local cz = seg.a[2] + seg.dz * f
                    local nx, nz = -seg.dz / math.max(0.01, seg.len), seg.dx / math.max(0.01, seg.len)
                    local deck_y = world_y((seg.a[3] or 25.18) + ((seg.b[3] or 25.18) - (seg.a[3] or 25.18)) * f, cfg)
                    for _, side in ipairs({-1, 1}) do
                        local rx = round(cx + nx * side * (half_width + 0.5))
                        local rz = round(cz + nz * side * (half_width + 0.5))
                        set_block(rx, deck_y + 1, rz, ids.limestone_trim)
                        if i % 4 == 0 then
                            set_block(rx, deck_y + 2, rz, ids.bridge_stone)
                            set_block(rx, deck_y + 3, rz, ids.limestone_trim)
                        end
                    end
                end
            end
        end

]=]
importer_source = replace_between(
    importer_source,
    bridge_start,
    bridge_end,
    bridge_renderer .. bridge_end
)


-- Use the measured height as a relative dimension, independent of rounding
-- the absolute elevation datum at the base and at the roof separately.
importer_source = replace_once(
    importer_source,
    "b._base_y = world_y(b.b, cfg)\n        b._top_y = world_y(b.b + b.h, cfg)",
    "b._base_y = world_y(b.b, cfg)\n        b._height_nodes = math.max(1, round(b.h or 0))\n        b._top_y = b._base_y + b._height_nodes"
)

-- OSM building-use class changes façade rhythm; footprint and measured height remain authoritative.
local window_renderer = [=[
local function register_wall_windows(set_block, b, ring, cfg, glass_id, sill_id, shutter_id, door_id, ids, road_segments)
    local kind = b.t or "yes"
    local cx, cz = (b._x1 + b._x2) / 2, (b._z1 + b._z2) / 2
    local dx, dz = cx - 84.76, cz - 143.44
    local footprint_area = math.max(0, b._x2 - b._x1) * math.max(0, b._z2 - b._z1)
    local historic = dx * dx + dz * dz <= 260 * 260 and footprint_area <= 1400
        and kind ~= "industrial" and kind ~= "greenhouse" and kind ~= "school"
        and kind ~= "kindergarten" and kind ~= "office" and kind ~= "service"
    local spacing = historic and 5.2 or 7.0
    local floor_step, first_level, window_height = historic and 3 or 4, 3, 2
    local use_balcony = false
    local use_shutters = historic or kind == "detached" or kind == "farm"
    local use_awning = false
    local floor_y, top_y = b._base_y, b._top_y

    -- Choose the frontage closest to a surveyed street; skip party walls
    -- and short polygon fragments that cannot hold a believable opening.
    local edges = {}
    for i = 1, #ring do
        local a, c = ring[i], ring[i % #ring + 1]
        local dx, dz = c[1] - a[1], c[2] - a[2]
        local length = math.sqrt(dx * dx + dz * dz)
        if length >= 7.0 then
            local mx, mz = (a[1] + c[1]) / 2, (a[2] + c[2]) / 2
            local road_distance = math.huge
            for _, seg in ipairs(road_segments or {}) do
                if mx >= seg.x1 - 12 and mx <= seg.x2 + 12
                    and mz >= seg.z1 - 12 and mz <= seg.z2 + 12 then
                    local d2 = nearest_segment(mx, mz, seg.a[1], seg.a[2], seg.b[1], seg.b[2])
                    local clear = math.max(0, math.sqrt(d2) - (seg.road.w or 3) / 2)
                    if clear < road_distance then road_distance = clear end
                end
            end
            edges[#edges + 1] = {a = a, c = c, length = length, distance = road_distance}
        end
    end
    if #edges == 0 then return end
    table.sort(edges, function(a, c)
        if a.distance == c.distance then return a.length > c.length end
        return a.distance < c.distance
    end)
    if edges[1].distance == math.huge then
        table.sort(edges, function(a, c) return a.length > c.length end)
    end

    local chosen = {}
    for i, edge in ipairs(edges) do
        local near_street = edge.distance <= 12
        local same_frontage = i == 1 or edge.distance <= edges[1].distance + 2.5
        if i == 1 or (near_street and same_frontage and #chosen < 2) then
            chosen[#chosen + 1] = edge
        end
    end
    local front = chosen[1]

    for edge_index, edge in ipairs(chosen) do
        local a, c, length = edge.a, edge.c, edge.length
        local dx, dz = c[1] - a[1], c[2] - a[2]
        local nx, nz = dz / length, -dx / length
        local dominant_x = math.abs(dx) >= math.abs(dz)
        local window_id
        if dominant_x then
            window_id = (nz < 0) and ids.window_north or ids.window_south
        else
            window_id = (nx < 0) and ids.window_west or ids.window_east
        end
        local ox, oz = math.floor(nx + 0.5), math.floor(nz + 0.5)
        local count = math.max(1, math.floor((length - 2.4) / spacing))
        for n = 1, count do
            local t = n / (count + 1)
            local x = math.floor(a[1] + dx * t + 0.5)
            local z = math.floor(a[2] + dz * t + 0.5)
            local balcony_done = false
            for fy = floor_y + first_level, top_y - window_height, floor_step do
                -- Thin panes and slim closed shutters sit flush with the facade; no AC or HVAC hardware.
                for dy = 0, window_height - 1 do
                    set_block(x, fy + dy, z, window_id)
                    if use_shutters then
                        local shutter_id
                        if window_id == ids.window_north then shutter_id = ids.window_shutter_north
                        elseif window_id == ids.window_south then shutter_id = ids.window_shutter_south
                        elseif window_id == ids.window_west then shutter_id = ids.window_shutter_west
                        else shutter_id = ids.window_shutter_east end
                        if dominant_x then
                            set_block(x - 1, fy + dy, z, shutter_id)
                            set_block(x + 1, fy + dy, z, shutter_id)
                        else
                            set_block(x, fy + dy, z - 1, shutter_id)
                            set_block(x, fy + dy, z + 1, shutter_id)
                        end
                    end
                end
                if use_balcony and edge_index == 1 and not balcony_done
                    and fy >= floor_y + floor_step * 2 and n == math.ceil(count / 2) then
                    set_block(x, fy - 1, z, dominant_x and ids.balcony_ns or ids.balcony_ew)
                    balcony_done = true
                end
                if use_awning and edge_index == 1 and fy == floor_y + first_level
                    and n == math.ceil(count / 2) then
                    set_block(x + ox, fy + 2, z + oz, ids.awning)
                end
            end
        end
    end

    -- One discreet wooden entrance on the street-facing frontage.
    local a, c = front.a, front.c
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
    "local W, D = math.max(0.5, w / 2 + 0.4), math.max(0.5, d / 2 + 0.4)"
)
-- Roof cells are emitted only by the replacement three-pass building renderer below.
-- Do not patch the old per-building loop: it has been removed from this importer.

-- Keep road cells walkable when a surveyed building footprint overlaps them.
importer_source = replace_once(
    importer_source,
    "local tile_cache = {}",
    "local tile_cache = {}\n        local road_mask = {}"
)
importer_source = replace_once(
    importer_source,
    "set_block(x, road_y, z, surface_id)",
    "set_block(x, road_y, z, surface_id)\n                            local road_key = (z - lz1) * (lx2 - lx1 + 1) + (x - lx1) + 1\n                            road_mask[road_key] = math.max(road_mask[road_key] or -math.huge, road_y)"
)
-- The replacement building renderer declares its own road-aware block writer.

local building_renderer = [=[
-- 4) Parcel-faithful, stylised medieval village buildings.
-- Cadastral footprints and measured wall heights are kept unchanged. Only
-- the architectural treatment is simplified into a coherent voxel style.
local visible_buildings = {}
local building_footprint_mask = {}

local function set_building_block(x, y, z, id)
    if x < lx1 or x > lx2 or z < lz1 or z > lz2 then return end
    local key = (z - lz1) * (lx2 - lx1 + 1) + (x - lx1) + 1
    local road_y = road_mask[key]\n    -- Roads protect only their walking surface: never suppress an entire wall column.\n    if road_y and y <= road_y then return end
    set_block(x, y, z, id)
end

local function is_height_landmark(b)
    local kind = string.lower(b.t or "yes")
    return kind == "church" or kind == "temple" or kind == "castle"
        or kind == "tower" or kind == "city_gate"
        or b.hist == "castle" or b.hist == "city_gate"
        or b.n == "Beffroi de Sommières" or b.n == "Porte du Bourguet"
        or b.n == "Église Saint-Pons" or b.n == "Château de Villevieille"
end

local function is_simple_house(b)
    return not is_height_landmark(b)
end

-- Turn every ordinary GIS building footprint into a small cottage set back
-- inside its existing footprint. This keeps the street plan and town extent,
-- while opening green gaps between neighbouring houses.
local function set_back_house_footprint(b)
    if not is_simple_house(b) then return end
    local min_x, max_x, min_z, max_z = math.huge, -math.huge, math.huge, -math.huge
    local cx, cz = 0, 0
    for _, p in ipairs(b.p) do
        cx, cz = cx + p[1], cz + p[2]
        min_x, max_x = math.min(min_x, p[1]), math.max(max_x, p[1])
        min_z, max_z = math.min(min_z, p[2]), math.max(max_z, p[2])
    end
    cx, cz = cx / #b.p, cz / #b.p
    local narrow = math.max(4, math.min(max_x - min_x, max_z - min_z))
    local broad = math.max(max_x - min_x, max_z - min_z)
    -- Even very large former blocks become cottages, never apartment slabs.
    local scale = math.min(clamp(1 - 2.6 / narrow, 0.58, 0.82), 15 / math.max(1, broad))
    scale = math.max(0.28, scale)
    b._house_scale = scale
    for _, p in ipairs(b.p) do
        p[1] = cx + (p[1] - cx) * scale
        p[2] = cz + (p[2] - cz) * scale
    end
    b._x1, b._x2, b._z1, b._z2 = math.huge, -math.huge, math.huge, -math.huge
    for _, p in ipairs(b.p) do
        b._x1, b._x2 = math.min(b._x1, p[1]), math.max(b._x2, p[1])
        b._z1, b._z2 = math.min(b._z1, p[2]), math.max(b._z2, p[2])
    end
end

local function prepare_house_roof(b, seed)
    local o = b.r and b.r.o
    local cx, cz, w, d, angle
    if o then
        cx, cz, w, d, angle = o[1], o[2], o[3], o[4], o[5] or 0
    else
        cx, cz = (b._x1 + b._x2) * 0.5, (b._z1 + b._z2) * 0.5
        w, d, angle = b._x2 - b._x1, b._z2 - b._z1, 0
    end
    w, d = math.max(2, w or 2), math.max(2, d or 2)
    local setback = b._house_scale or 0.72
    w, d = w * setback, d * setback
    -- Keep the ridge on the longer axis, which makes small houses read as
    -- proper cottages rather than square flat-roofed boxes.
    if w < d then
        w, d = d, w
        angle = angle + math.pi / 2
    end
    local source_shape = (b.r and b.r.s) or "gab"
    local shape = "gab"
    if source_shape == "hip" or source_shape == "pyr" then shape = "hip" end
    local rise = math.max(3, math.min(4, round(math.max(2.2, b.rh or 1.5) * 1.15)))
    b._house_roof = {cx, cz, w, d, angle, shape, rise}
    -- A warm terracotta majority, with some surveyed roof colours retained.
    b._house_roof_id = (seed % 3 == 0) and b._roof_id or ids.roof_default
    b._house_timber = seed % 4 == 0
end

local function house_roof_height(b, x, z)
    local o = b._house_roof
    local cx, cz, w, d, angle, shape, rise = o[1], o[2], o[3], o[4], o[5], o[6], o[7]
    local dx, dz = x + 0.5 - cx, z + 0.5 - cz
    local ca, sa = math.cos(angle), math.sin(angle)
    local u = dx * ca + dz * sa
    local v = -dx * sa + dz * ca
    local W, D = math.max(0.75, w / 2 + 0.45), math.max(0.75, d / 2 + 0.45)
    local slope = math.abs(v) / D
    if shape == "hip" then
        local ridge = math.max(0.8, w / 2 - d / 2)
        local hip = math.max(0, (math.abs(u) - ridge) / math.max(0.5, W - ridge))
        slope = math.max(slope, hip)
    end
    return b._top_y + 1 + round(rise * clamp(1 - slope, 0, 1))
end

-- Pass 1: clear only the exact surveyed parcel interiors. No footprint is
-- expanded, contracted, squared-off or moved to fit the new house style.
for _, b in ipairs(buildings) do
    if not is_height_landmark(b) then
        -- One or two inhabited storeys, three only for the largest houses.
        local wall_height = math.max(4, math.min(7, round((b.h or 5) * 0.72)))
        b._top_y = b._base_y + wall_height
        set_back_house_footprint(b)
    end
    if bbox_hits(b._x1, b._x2, b._z1, b._z2, lx1, lx2, lz1, lz2, 1) then
        visible_buildings[#visible_buildings + 1] = b
        local floor_y, top_y = b._base_y, b._top_y
        local ax1, ax2 = math.max(lx1, math.floor(b._x1)), math.min(lx2, math.ceil(b._x2))
        local az1, az2 = math.max(lz1, math.floor(b._z1)), math.min(lz2, math.ceil(b._z2))
        for z = az1, az2 do
            for x = ax1, ax2 do
                if in_building(x + 0.5, z + 0.5, b) then
                    building_footprint_mask[(z - lz1) * (lx2 - lx1 + 1) + (x - lx1) + 1] = true
                    set_building_block(x, floor_y, z, ids.floor)
                    for y = floor_y + 1, math.min(y_max, top_y) do
                        set_building_block(x, y, z, ids.air)
                    end
                end
            end
        end
    end
end

-- Pass 2: short, thick, stepped roofs. The roof volume is only two blocks
-- deep, not a solid pyramid filling the whole space below the ridge.
for _, b in ipairs(visible_buildings) do
    local seed = math.floor(math.abs((b.p[1][1] or 0) * 31 + (b.p[1][2] or 0) * 17 + (b.h or 0) * 13))
    local simple_house = is_simple_house(b)
    if simple_house then prepare_house_roof(b, seed) end

    local ax1, ax2 = math.max(lx1, math.floor(b._x1)), math.min(lx2, math.ceil(b._x2))
    local az1, az2 = math.max(lz1, math.floor(b._z1)), math.min(lz2, math.ceil(b._z2))
    for z = az1, az2 do
        for x = ax1, ax2 do
            if in_building(x + 0.5, z + 0.5, b) then
                local roof_y = simple_house and house_roof_height(b, x, z) or make_roof_height(b, x, z)
                local roof_id = simple_house and b._house_roof_id or b._roof_id
                -- A thin, single-node tiled roof; no oversized solid roof mass.
                set_building_block(x, roof_y, z, roof_id)
            end
        end
    end

    -- Restrained timber fascia; most cottages use lime plaster and stone.
    if simple_house and b._house_timber then
        for i = 1, #b.p do
            local a, c = b.p[i], b.p[i % #b.p + 1]
            local dx, dz = c[1] - a[1], c[2] - a[2]
            local length = math.sqrt(dx * dx + dz * dz)
            local steps = math.max(1, math.ceil(length))
            for step = 0, steps do
                local f = step / steps
                local x = round(a[1] + dx * f)
                local z = round(a[2] + dz * f)
                set_building_block(x, b._top_y + 1, z, ids.wood)
            end
        end
    else
        -- The larger monuments retain their measured roof and sparse chimney.
        local kind = b.t or "yes"
        if not simple_house and b.r and b.r.s ~= "flat" and b.r.o
            and kind ~= "tower" and kind ~= "church" and kind ~= "castle" and seed % 8 == 0 then
            local o = b.r.o
            local angle = o[5] or 0
            local rx = round(o[1] + math.cos(angle) * (o[3] or 0) * 0.18)
            local rz = round(o[2] - math.sin(angle) * (o[3] or 0) * 0.18)
            local ry = make_roof_height(b, rx, rz)
            set_building_block(rx, ry + 1, rz, ids.wood)
        end
    end
end

-- Pass 3: compact cottage façades. Stone plinth, warm plaster, restrained
-- exposed timber, small openings and real measured heights.
for _, b in ipairs(visible_buildings) do
    local floor_y, top_y = b._base_y, b._top_y
    local kind = b.t or "yes"
    local simple_house = b._house_roof ~= nil
    local seed = math.floor(math.abs((b.p[1][1] or 0) * 31 + (b.p[1][2] or 0) * 17 + (b.h or 0) * 13))
    local timber_frame = simple_house and b._house_timber
    local named_gate = b.n == "Porte du Bourguet"
    local named_belfry = b.n == "Beffroi de Sommières"
        or b.n == "La tour de l'horloge" or b.n == "Tour Bermond"
    local religious = kind == "church" or kind == "temple"
    local fortified = kind == "tower" or kind == "castle" or kind == "city_gate"
        or b.hist == "city_gate" or b.hist == "castle"
    local rings = {b.p}
    if b.ho then for _, hole in ipairs(b.ho) do rings[#rings + 1] = hole end end

    for _, ring in ipairs(rings) do
        for i = 1, #ring do
            local p0, p1 = ring[i], ring[i % #ring + 1]
            local dx, dz = p1[1] - p0[1], p1[2] - p0[2]
            local length = math.sqrt(dx * dx + dz * dz)
            local steps = math.max(1, math.ceil(length * 1.5))
            for step = 0, steps do
                local f = step / steps
                local x, z = round(p0[1] + dx * f), round(p0[2] + dz * f)
                if x >= lx1 and x <= lx2 and z >= lz1 and z <= lz2 then
                    local corner = step == 0 or step == steps
                    for y = floor_y - 1, top_y do
                        local rel = y - floor_y
                        local wall_id = (rel <= 1) and ids.ashlar or b._wall_id
                        if timber_frame and rel > 1 and (rel == 3 or rel == 6 or rel == top_y - floor_y) then
                            wall_id = ids.wood
                        elseif timber_frame and corner and rel > 1 then
                            wall_id = ids.wood
                        elseif not simple_house and fortified then
                            wall_id = ids.ashlar
                        elseif not simple_house and corner and rel > 1 and rel % 3 == 0 then
                            wall_id = ids.limestone_trim
                        end
                        set_building_block(x, y, z, wall_id)
                    end
                    if simple_house and timber_frame and corner then
                        for y = floor_y + 1, top_y do
                            set_building_block(x, y, z, ids.wood)
                        end
                    elseif simple_house and corner and not timber_frame then
                        for y = floor_y + 1, top_y - 1, 2 do
                            set_building_block(x, y, z, ids.limestone_trim)
                        end
                    end
                end
            end
        end
    end

    -- Small gable infill closes the end walls below the steep tiled roof.
    if simple_house and b._house_roof[6] == "gab" then
        local o = b._house_roof
        local cx, cz, w, d, angle, rise = o[1], o[2], o[3], o[4], o[5], o[7]
        local ca, sa = math.cos(angle), math.sin(angle)
        local half_w, half_d = w / 2, d / 2
        local steps = math.max(2, math.ceil(d))
        for _, side in ipairs({-1, 1}) do
            local u = side * half_w
            for step = 0, steps do
                local v = -half_d + 2 * half_d * step / steps
                local x = round(cx + u * ca - v * sa)
                local z = round(cz + u * sa + v * ca)
                local h = round(rise * (1 - math.abs(v) / math.max(0.5, half_d)))
                for y = top_y + 1, top_y + h do
                    set_building_block(x, y, z, b._wall_id)
                end
                if timber_frame and h > 0 then
                    set_building_block(x, top_y + h, z, ids.wood)
                end
            end
        end
    end

    register_wall_windows(set_building_block, b, b.p, cfg,
        ids.glass, ids.limestone_trim, ids.shutter, ids.door, ids, segments)

    -- Defensive and religious landmarks remain visually distinct from houses.
    if fortified then
        for i = 1, #b.p do
            local a, c = b.p[i], b.p[i % #b.p + 1]
            local dx, dz = c[1] - a[1], c[2] - a[2]
            local steps = math.max(1, math.ceil(math.sqrt(dx * dx + dz * dz)))
            for step = 0, steps, 2 do
                local f = step / steps
                set_building_block(round(a[1] + dx * f), top_y + 1, round(a[2] + dz * f), ids.ashlar)
            end
        end
    end

    if religious and named_belfry and (b.h or 0) >= 8 then
        local roof = b.r or {}
        local cx = round((roof.o and roof.o[1]) or ((b._x1 + b._x2) / 2))
        local cz = round((roof.o and roof.o[2]) or ((b._z1 + b._z2) / 2))
        local tower_base = math.max(floor_y + 3, top_y - 5)
        for y = tower_base, top_y + 1 do
            for dx = -1, 1 do
                for dz = -1, 1 do
                    if math.abs(dx) == 1 or math.abs(dz) == 1 then
                        set_building_block(cx + dx, y, cz + dz, ids.ashlar)
                    end
                end
            end
        end
        for _, p in ipairs({{cx, top_y, cz - 1}, {cx, top_y, cz + 1},
            {cx - 1, top_y, cz}, {cx + 1, top_y, cz}}) do
            set_building_block(p[1], p[2], p[3], ids.glass)
        end
        for layer = 0, 2 do
            for dx = -1 + layer, 1 - layer do
                for dz = -1 + layer, 1 - layer do
                    set_building_block(cx + dx, top_y + 2 + layer, cz + dz, b._roof_id)
                end
            end
        end
        set_building_block(cx, top_y + 5, cz, ids.limestone_trim)
    end

    -- The Porte du Bourguet keeps its open passage and stone arch.
    if named_gate then
        local longest, edge = 0, nil
        for i = 1, #b.p do
            local a, c = b.p[i], b.p[i % #b.p + 1]
            local len = math.sqrt((c[1] - a[1])^2 + (c[2] - a[2])^2)
            if len > longest then longest, edge = len, {a, c} end
        end
        if edge and longest >= 4 then
            local a, c = edge[1], edge[2]
            local dx, dz = c[1] - a[1], c[2] - a[2]
            local x, z = round((a[1] + c[1]) / 2), round((a[2] + c[2]) / 2)
            if math.abs(dx) >= math.abs(dz) then
                for off = -1, 1 do
                    for y = floor_y + 1, floor_y + 4 do set_block(x + off, y, z, ids.air) end
                end
                for off = -2, 2 do set_building_block(x + off, floor_y + 5, z, ids.limestone_trim) end
            else
                for off = -1, 1 do
                    for y = floor_y + 1, floor_y + 4 do set_block(x, y, z + off, ids.air) end
                end
                for off = -2, 2 do set_building_block(x, floor_y + 5, z + off, ids.limestone_trim) end
            end
        end
    end

    if named_belfry then
        local cx, cz = round((b._x1 + b._x2) / 2), round((b._z1 + b._z2) / 2)
        local clock_y = math.max(floor_y + 4, top_y - 5)
        for _, face in ipairs({"north", "south", "east", "west"}) do
            if face == "north" or face == "south" then
                local fz = cz + ((face == "north") and -1 or 1)
                for off = -1, 1 do
                    set_building_block(cx + off, clock_y - 1, fz, ids.limestone_trim)
                    set_building_block(cx + off, clock_y + 1, fz, ids.limestone_trim)
                end
                set_building_block(cx - 1, clock_y, fz, ids.limestone_trim)
                set_building_block(cx + 1, clock_y, fz, ids.limestone_trim)
                set_building_block(cx, clock_y, fz, ids.glass)
            else
                local fx = cx + ((face == "west") and -1 or 1)
                for off = -1, 1 do
                    set_building_block(fx, clock_y - 1, cz + off, ids.limestone_trim)
                    set_building_block(fx, clock_y + 1, cz + off, ids.limestone_trim)
                end
                set_building_block(fx, clock_y, cz - 1, ids.limestone_trim)
                set_building_block(fx, clock_y, cz + 1, ids.limestone_trim)
                set_building_block(fx, clock_y, cz, ids.glass)
            end
        end
    end
end

-- In the dense centre, tiny residual strips beside attached houses are paved,
-- not bright lawn. The actual building footprints and street cells take priority.
for _, b in ipairs(visible_buildings) do
    local bx = (b._x1 + b._x2) / 2 - 84.76
    local bz = (b._z1 + b._z2) / 2 - 143.44
    local area = math.max(0, b._x2 - b._x1) * math.max(0, b._z2 - b._z1)
    if bx * bx + bz * bz <= 260 * 260 and area <= 1400 then
        for i = 1, #b.p do
            local a, c = b.p[i], b.p[i % #b.p + 1]
            local dx, dz = c[1] - a[1], c[2] - a[2]
            local length = math.sqrt(dx * dx + dz * dz)
            if length > 1.5 then
                local area_sum = 0
                for j = 1, #b.p do
                    local p, q = b.p[j], b.p[j % #b.p + 1]
                    area_sum = area_sum + p[1] * q[2] - q[1] * p[2]
                end
                local orientation = area_sum >= 0 and 1 or -1
                local nx, nz = orientation * dz / length, -orientation * dx / length
                local steps = math.max(1, math.ceil(length * 1.5))
                for step = 0, steps do
                    local f = step / steps
                    for offset = 1, 2 do
                        local x = round(a[1] + dx * f + nx * offset)
                        local z = round(a[2] + dz * f + nz * offset)
                        if x >= lx1 and x <= lx2 and z >= lz1 and z <= lz2 then
                            local key = (z - lz1) * (lx2 - lx1 + 1) + (x - lx1) + 1
                            if not road_mask[key] and not building_footprint_mask[key] then
                                local ground = tile_cache[key]
                                if ground then set_building_block(x, ground, z, ids.road_stone) end
                            end
                        end
                    end
                end
            end
        end
    end
end

]=]
importer_source = replace_between(
    importer_source,
    "-- 4) Individual building footprints, measured heights and oriented roof planes.",
    "-- 4b) Covered lanes and passages mapped by OSM are kept open beneath the houses.",
    building_renderer .. "-- 4b) Covered lanes and passages mapped by OSM are kept open beneath the houses."
)
-- Recalculate lighting independently for river-only tiles outside the compact town bounds.
importer_source = replace_once(
    importer_source,
    "vm:write_to_map(true)\n        completed = completed + 1",
    "vm:write_to_map(true)\n        if tile_data[5] and minetest.fix_light then\n            minetest.fix_light(\n                {x = wX(lx1), y = y_min, z = wZ(lz1)},\n                {x = wX(lx2), y = y_max, z = wZ(lz2)})\n        end\n        completed = completed + 1"
)

-- Trees must not occupy roads, footways, bridge decks or their clearance envelope.
local tree_ingest = [=[for _, tr in ipairs(data.nature.trees or {}) do
        trees[#trees + 1] = tr
    end]=]
local tree_filter = [=[for _, tr in ipairs(data.nature.trees or {}) do
        trees[#trees + 1] = tr
    end

    -- Keep trunks and full crowns clear of every mapped road and bridge.
    -- Index the road segments spatially to avoid an O(trees x roads) scan.
    local tree_cell_size = 32
    local max_tree_radius = 0
    for _, tr in ipairs(trees) do
        max_tree_radius = math.max(max_tree_radius, tr[6] or 0)
    end
    local tree_road_index = {}
    for _, seg in ipairs(segments) do
        local a, b = seg.a, seg.b
        local margin = (seg.road.w or 3) / 2 + max_tree_radius + 1.5
        local cx1 = math.floor((math.min(a[1], b[1]) - margin) / tree_cell_size)
        local cx2 = math.floor((math.max(a[1], b[1]) + margin) / tree_cell_size)
        local cz1 = math.floor((math.min(a[2], b[2]) - margin) / tree_cell_size)
        local cz2 = math.floor((math.max(a[2], b[2]) + margin) / tree_cell_size)
        for cz = cz1, cz2 do
            for cx = cx1, cx2 do
                local key = cx .. ":" .. cz
                tree_road_index[key] = tree_road_index[key] or {}
                tree_road_index[key][#tree_road_index[key] + 1] = seg
            end
        end
    end

    local safe_trees, blocked_tree_count = {}, 0
    for _, tr in ipairs(trees) do
        local x, z, radius = tr[1], tr[2], tr[6] or 0
        local key = math.floor(x / tree_cell_size) .. ":" .. math.floor(z / tree_cell_size)
        local candidates = tree_road_index[key] or {}
        local blocked = false
        for _, seg in ipairs(candidates) do
            local a, b = seg.a, seg.b
            local dx, dz = b[1] - a[1], b[2] - a[2]
            local length2 = dx * dx + dz * dz
            local f = 0
            if length2 > 0 then
                f = clamp(((x - a[1]) * dx + (z - a[2]) * dz) / length2, 0, 1)
            end
            local px, pz = a[1] + dx * f, a[2] + dz * f
            local clearance = (seg.road.w or 3) / 2 + radius + 1.5
            local ox, oz = x - px, z - pz
            if ox * ox + oz * oz < clearance * clearance then
                blocked = true
                break
            end
        end
        if blocked then
            blocked_tree_count = blocked_tree_count + 1
        else
            safe_trees[#safe_trees + 1] = tr
        end
    end
    trees = safe_trees
    minetest.log("action", string.format(
        "[GDO][SOMMIERES] Arbres protégés des routes et ponts : %d retirés ; %d conservés.",
        blocked_tree_count, #trees))]=]
importer_source = replace_once(importer_source, tree_ingest, tree_filter)

-- Road materials are selected by the GIS renderer itself. Avoid a brittle
-- text replacement against one exact formatting of the compressed importer.

-- Extend the importer over a transition apron and join the surveyed DEM to mapgen terrain.
importer_source = replace_once(
    importer_source,
    "local x1, x2, z1, z2 = data.meta.bbox[1], data.meta.bbox[3], data.meta.bbox[2], data.meta.bbox[4]",
    "local transition_margin = cfg.transition_margin or 0\n    local x1 = math.floor(math.min(data.meta.bbox[1], t.xmin) - transition_margin)\n    local x2 = math.ceil(math.max(data.meta.bbox[3], t.xmax) + transition_margin)\n    local z1 = math.floor(math.min(data.meta.bbox[2], t.zmin) - transition_margin)\n    local z2 = math.ceil(math.max(data.meta.bbox[4], t.zmax) + transition_margin)"
)
importer_source = replace_once(
    importer_source,
    "local function get_surface(x, z)\n            return world_y(terrain_sample(t, x + 0.5, z + 0.5), cfg)\n        end",
    "local function get_surface(x, z)\n            return world_y(transition_elevation(x + 0.5, z + 0.5), cfg)\n        end"
)

local terrain_blend = [=[
local function wZ(z) return cfg.center_z + z + cfg.shift_z end
local ext = data.terrain_extension
local river_source_buckets, river_cell_size = {}, 64
for _, line in ipairs((data.water and data.water.lines) or {}) do
    if line.n == "Le Vidourle" and line.p then
        for i = 1, #line.p - 1 do
            local a, b = line.p[i], line.p[i + 1]
            local margin = 48
            local cx1 = math.floor((math.min(a[1], b[1]) - margin) / river_cell_size)
            local cx2 = math.floor((math.max(a[1], b[1]) + margin) / river_cell_size)
            local cz1 = math.floor((math.min(a[2], b[2]) - margin) / river_cell_size)
            local cz2 = math.floor((math.max(a[2], b[2]) + margin) / river_cell_size)
            local segment = {a = a, b = b}
            for cz = cz1, cz2 do
                for cx = cx1, cx2 do
                    local key = cx .. ":" .. cz
                    river_source_buckets[key] = river_source_buckets[key] or {}
                    river_source_buckets[key][#river_source_buckets[key] + 1] = segment
                end
            end
        end
    end
end
local function near_vidourle(x, z)
    local key = math.floor(x / river_cell_size) .. ":" .. math.floor(z / river_cell_size)
    for _, seg in ipairs(river_source_buckets[key] or {}) do
        if nearest_segment(x, z, seg.a[1], seg.a[2], seg.b[1], seg.b[2]) <= 48 * 48 then
            return true
        end
    end
    return false
end
local function source_grid_at(x, z)
    if x >= t.xmin and x <= t.xmax and z >= t.zmin and z <= t.zmax then
        return t, true, 0, 0
    end
    if ext and x >= ext.xmin and x <= ext.xmax and z >= ext.zmin and z <= ext.zmax
        and near_vidourle(x, z) then
        return ext, true, 0, 0
    end
    local dx = math.max(t.xmin - x, 0, x - t.xmax)
    local dz = math.max(t.zmin - z, 0, z - t.zmax)
    return t, false, dx, dz
end

local sample_step = 16
local sample_x0 = math.floor(x1 / sample_step) * sample_step
local sample_z0 = math.floor(z1 / sample_step) * sample_step
local sample_x1 = math.ceil(x2 / sample_step) * sample_step
local sample_z1 = math.ceil(z2 / sample_step) * sample_step
local sample_nx = math.floor((sample_x1 - sample_x0) / sample_step) + 1
local sample_nz = math.floor((sample_z1 - sample_z0) / sample_step) + 1
local ambient_grid = {}

for iz = 0, sample_nz - 1 do
    local sz = sample_z0 + iz * sample_step
    for ix = 0, sample_nx - 1 do
        local sx = sample_x0 + ix * sample_step
        local grid, inside = source_grid_at(sx, sz)
        local elevation
        if inside then
            elevation = terrain_sample(grid, sx, sz)
        else
            local natural_y
            if cfg.find_surface_y then natural_y = cfg.find_surface_y(wX(sx), wZ(sz)) end
            if natural_y then
                elevation = cfg.ref_elevation + natural_y - cfg.base_y
            else
                elevation = terrain_sample(grid,
                    clamp(sx, grid.xmin, grid.xmax),
                    clamp(sz, grid.zmin, grid.zmax))
            end
        end
        ambient_grid[iz * sample_nx + ix + 1] = elevation
    end
end

local function ambient_surface_elevation(x, z)
    local fx = clamp((x - sample_x0) / sample_step, 0, sample_nx - 1)
    local fz = clamp((z - sample_z0) / sample_step, 0, sample_nz - 1)
    local x0, z0 = math.floor(fx), math.floor(fz)
    local x1s, z1s = math.min(sample_nx - 1, x0 + 1), math.min(sample_nz - 1, z0 + 1)
    local tx, tz = fx - x0, fz - z0
    local i0, i1 = z0 * sample_nx, z1s * sample_nx
    local a = ambient_grid[i0 + x0 + 1]
    local b = ambient_grid[i0 + x1s + 1]
    local c = ambient_grid[i1 + x0 + 1]
    local d = ambient_grid[i1 + x1s + 1]
    local upper = a + (b - a) * tx
    local lower = c + (d - c) * tx
    return upper + (lower - upper) * tz
end

local function transition_elevation(x, z)
    local grid, inside, dx, dz = source_grid_at(x, z)
    if inside then return terrain_sample(grid, x, z) end
    local edge_elevation = terrain_sample(grid,
        clamp(x, grid.xmin, grid.xmax),
        clamp(z, grid.zmin, grid.zmax))
    local ambient_elevation = ambient_surface_elevation(x, z)
    local distance = math.sqrt(dx * dx + dz * dz)
    local fade = transition_margin > 0 and clamp(distance / transition_margin, 0, 1) or 1
    return edge_elevation + (ambient_elevation - edge_elevation) * fade
end

local function is_surveyed_terrain(x, z)
    local _, inside = source_grid_at(x, z)
    return inside
end]=]
importer_source = replace_once(
    importer_source,
    "local function wZ(z) return cfg.center_z + z + cfg.shift_z end",
    terrain_blend
)

importer_source = replace_once(
    importer_source,
    [=[        -- 1) Clear this tile, then reconstruct the natural RGE ALTI terrain at one metre.
        for z = lz1, lz2 do
            for x = lx1, lx2 do
                local sx, sz = wX(x), wZ(z)
                for y = y_min, y_max do
                    vmdata[area:index(sx, y, sz)] = ids.air
                end
                local ground = get_surface(x, z)
                ground = clamp(ground, y_min + 1, y_max - 1)
                for y = y_min, ground - 4 do
                    vmdata[area:index(sx, y, sz)] = ids.stone
                end
                for y = math.max(y_min, ground - 3), ground - 1 do
                    vmdata[area:index(sx, y, sz)] = ids.soil
                end
                vmdata[area:index(sx, ground, sz)] = ids.grass
                tile_cache[(z - lz1) * (lx2 - lx1 + 1) + (x - lx1) + 1] = ground
            end
        end]=],
    [=[        -- 1) Exact RGE ALTI in the survey; gradual terrain connection outside.
        for z = lz1, lz2 do
            for x = lx1, lx2 do
                local sx, sz = wX(x), wZ(z)
                local ground = clamp(get_surface(x, z), y_min + 1, y_max - 1)
                if is_surveyed_terrain(x + 0.5, z + 0.5) then
                    for y = y_min, y_max do
                        vmdata[area:index(sx, y, sz)] = ids.air
                    end
                    for y = y_min, ground - 4 do
                        vmdata[area:index(sx, y, sz)] = ids.stone
                    end
                    for y = math.max(y_min, ground - 3), ground - 1 do
                        vmdata[area:index(sx, y, sz)] = ids.soil
                    end
                    vmdata[area:index(sx, ground, sz)] = ids.grass
                else
                    local native_ground = clamp(
                        world_y(ambient_surface_elevation(x + 0.5, z + 0.5), cfg),
                        y_min + 1, y_max - 1)
                    local delta = ground - native_ground
                    if math.abs(delta) >= 1 then
                        local clear_from = math.min(ground, native_ground) + 1
                        local clear_to = math.min(y_max, math.max(ground, native_ground) + 24)
                        for y = clear_from, clear_to do
                            vmdata[area:index(sx, y, sz)] = ids.air
                        end
                        if ground > native_ground then
                            for y = native_ground + 1, ground - 3 do
                                vmdata[area:index(sx, y, sz)] = ids.stone
                            end
                        end
                        for y = math.max(y_min, ground - 2), ground - 1 do
                            vmdata[area:index(sx, y, sz)] = ids.soil
                        end
                        vmdata[area:index(sx, ground, sz)] = ids.grass
                    end
                end
                tile_cache[(z - lz1) * (lx2 - lx1 + 1) + (x - lx1) + 1] = ground
            end
        end]=]
)
local importer_chunk, importer_err = loader(importer_source, "@gdo_city/gis_import.lua")
assert(importer_chunk, importer_err)
_G.__gdo_city_gis_importer = importer_chunk()

local renderer_source = minetest.decompress(read_file("renderer.deflate"), "deflate")
assert(renderer_source, "[GDO Sommières] Renderer GIS compressé invalide.")
renderer_source = replace_once(renderer_source, "local VERSION = 6", "local VERSION = 28")
renderer_source = replace_once(
    renderer_source,
    [=[center_x, center_z, base_y = candidate[1], candidate[2], ground_y]=],
    [=[center_x, center_z, base_y = candidate[1], candidate[2], math.floor(ref_elevation + (tonumber(minetest.get_mapgen_setting("water_level")) or 1) + 0.5)]=]
)
renderer_source = replace_once(
    renderer_source,
    [=[base_y = storage:get_int("city_y")]=],
    [=[base_y = math.floor(ref_elevation + (tonumber(minetest.get_mapgen_setting("water_level")) or 1) + 0.5)
        storage:set_int("city_y", base_y)]=]
)
renderer_source = replace_once(
    renderer_source,
    [=[local natural = A.find_surface_y(rx, rz)
                            if natural then base_y = natural; storage:set_int("city_y", natural) end]=],
    [=[base_y = math.floor(ref_elevation + (tonumber(minetest.get_mapgen_setting("water_level")) or 1) + 0.5)
                        storage:set_int("city_y", base_y)]=]
)
renderer_source = replace_once(
    renderer_source,
    [=[atlas_tile(0, 0) .. "^[multiply:" .. color]=],
    [=["sommieres_plaster.png^[multiply:" .. color]=]
)


renderer_source = replace_once(renderer_source,
    "local importer = assert(_G.__gdo_city_gis_importer, \"[GDO Sommières] Importeur SIG absent.\")",
    "local function emerge_river_corridor(y_min, y_max, callback)\n    local tile_size, margin = 32, 40\n    local tiles, seen = {}, {}\n    for _, line in ipairs((data.water and data.water.lines) or {}) do\n        if line.n == \"Le Vidourle\" and line.p and #line.p > 1 then\n            for i = 1, #line.p - 1 do\n                local a, b = line.p[i], line.p[i + 1]\n                local x1 = math.floor((math.min(a[1], b[1]) - margin) / tile_size) * tile_size\n                local x2 = math.floor((math.max(a[1], b[1]) + margin) / tile_size) * tile_size\n                local z1 = math.floor((math.min(a[2], b[2]) - margin) / tile_size) * tile_size\n                local z2 = math.floor((math.max(a[2], b[2]) + margin) / tile_size) * tile_size\n                for z = z1, z2, tile_size do\n                    for x = x1, x2, tile_size do\n                        local key = x .. \":\" .. z\n                        if not seen[key] then\n                            seen[key] = true\n                            tiles[#tiles + 1] = {x, z}\n                        end\n                    end\n                end\n            end\n        end\n    end\n\n    if #tiles == 0 then callback(false); return end\n    local pending, failed = #tiles, false\n    for _, tile in ipairs(tiles) do\n        minetest.emerge_area(\n            {x = world_x(tile[1]), y = y_min, z = world_z(tile[2])},\n            {x = world_x(tile[1] + tile_size - 1), y = y_max, z = world_z(tile[2] + tile_size - 1)},\n            function(_, action, remaining)\n                if action == minetest.EMERGE_ERRORED or action == minetest.EMERGE_CANCELLED then\n                    failed = true\n                end\n                if remaining == 0 then\n                    pending = pending - 1\n                    if pending == 0 then callback(failed) end\n                end\n            end\n        )\n    end\nend\n\nlocal importer = assert(_G.__gdo_city_gis_importer, \"[GDO Sommières] Importeur SIG absent.\")"
)

renderer_source = replace_once(
    renderer_source,
    [=[    local pending, failed = #tiles, false
    for _, tile in ipairs(tiles) do
        minetest.emerge_area(
            {x = world_x(tile[1]), y = y_min, z = world_z(tile[2])},
            {x = world_x(tile[1] + tile_size - 1), y = y_max, z = world_z(tile[2] + tile_size - 1)},
            function(_, action, remaining)
                if action == minetest.EMERGE_ERRORED or action == minetest.EMERGE_CANCELLED then
                    failed = true
                end
                if remaining == 0 then
                    pending = pending - 1
                    if pending == 0 then callback(failed) end
                end
            end
        )
    end
end]=],
    [=[    local failed, next_index, active = false, 1, 0
    local launch_batch
    launch_batch = function()
        while active < 8 and next_index <= #tiles do
            local tile = tiles[next_index]
            next_index = next_index + 1
            active = active + 1
            minetest.emerge_area(
                {x = world_x(tile[1]), y = y_min, z = world_z(tile[2])},
                {x = world_x(tile[1] + tile_size - 1), y = y_max, z = world_z(tile[2] + tile_size - 1)},
                function(_, action, remaining)
                    if action == minetest.EMERGE_ERRORED or action == minetest.EMERGE_CANCELLED then
                        failed = true
                    end
                    if remaining == 0 then
                        active = active - 1
                        if next_index > #tiles and active == 0 then
                            callback(failed)
                        else
                            launch_batch()
                        end
                    end
                end
            )
        end
    end
    launch_batch()
end]=]
)
renderer_source = replace_once(renderer_source, "emerge_box(BOUNDS, y_min, y_max, function(failed)", "emerge_river_corridor(y_min, y_max, function(river_failed)\n        if river_failed then\n            building = false\n            minetest.log(\"error\", \"[GDO][SOMMIERES] Échec de l'émergence des tuiles du Vidourle.\")\n            minetest.after(10, build_city)\n            return\n        end\n        emerge_box(BOUNDS, y_min, y_max, function(failed)")
renderer_source = replace_once(renderer_source, "        end)\n    end)\nend\n\nlocal function dry_reference_y", "        end)\n    end)\n    end)\nend\n\nlocal function dry_reference_y")

renderer_source = replace_once(renderer_source, "local wall_ids, roof_ids = {}, {}", "    -- Architectural relief for medieval Languedoc facades.\n    register_node(\"gdo_city:timber_beam\", \"Poutre de chêne ancien\", atlas_tile(1, 0))\n    register_node(\"gdo_city:window_arch\", \"Claveau de fenêtre\", atlas_tile(3, 0))\n    register_node(\"gdo_city:roof_parapet\", \"Acrotère de toiture\", atlas_tile(2, 0), {\n        drawtype = \"nodebox\", walkable = false,\n        node_box = {type = \"fixed\", fixed = {\n            {-0.5, -0.5, -0.5, 0.5, -0.08, 0.5},\n        }},\n    })\n    register_node(\"gdo_city:chimney\", \"Souche de cheminée ancienne\", atlas_tile(0, 3), {\n        drawtype = \"nodebox\", node_box = {type = \"fixed\", fixed = {\n            {-0.28, -0.5, -0.28, 0.28, 0.5, 0.28},\n        }},\n    })\n    register_node(\"gdo_city:shop_awning\", \"Store de boutique\", atlas_tile(0, 2), {\n        drawtype = \"nodebox\", walkable = false,\n        node_box = {type = \"fixed\", fixed = {\n            {-0.5, -0.45, -0.52, 0.5, -0.31, 0.42},\n            {-0.5, -0.50, 0.38, 0.5, -0.43, 0.48},\n        }},\n    })\n    register_node(\"gdo_city:iron_balcony_ns\", \"Balcon en ferronnerie\", atlas_tile(2, 2), {\n        drawtype = \"nodebox\", walkable = false,\n        node_box = {type = \"fixed\", fixed = {\n            {-0.5, -0.48, -0.52, 0.5, -0.40, 0.52},\n            {-0.5, -0.40, -0.52, -0.44, 0.08, -0.45},\n            {0.44, -0.40, -0.52, 0.5, 0.08, -0.45},\n            {-0.5, 0.03, -0.52, 0.5, 0.08, -0.45},\n            {-0.28, -0.40, -0.52, -0.23, 0.05, -0.45},\n            {0.23, -0.40, -0.52, 0.28, 0.05, -0.45},\n        }},\n    })\n    register_node(\"gdo_city:iron_balcony_ew\", \"Balcon en ferronnerie latéral\", atlas_tile(2, 2), {\n        drawtype = \"nodebox\", walkable = false,\n        node_box = {type = \"fixed\", fixed = {\n            {-0.52, -0.48, -0.5, 0.52, -0.40, 0.5},\n            {-0.52, -0.40, -0.5, -0.45, 0.08, 0.5},\n            {-0.52, 0.03, -0.5, -0.45, 0.08, 0.5},\n            {-0.52, -0.40, -0.28, -0.45, 0.05, -0.23},\n            {-0.52, -0.40, 0.23, -0.45, 0.05, 0.28},\n        }},\n    })\nlocal wall_ids, roof_ids = {}, {}")
renderer_source = replace_once(renderer_source, "shutter = cid(\"gdo_city:shutter\"), door = cid(\"gdo_city:wooden_door\"),", "shutter = cid(\"gdo_city:shutter\"), door = cid(\"gdo_city:wooden_door\"),\n        timber = cid(\"gdo_city:timber_beam\"), arch = cid(\"gdo_city:window_arch\"),\n        chimney = cid(\"gdo_city:chimney\"), awning = cid(\"gdo_city:shop_awning\"),\n        roof_parapet = cid(\"gdo_city:roof_parapet\"),\n        balcony_ns = cid(\"gdo_city:iron_balcony_ns\"), balcony_ew = cid(\"gdo_city:iron_balcony_ew\"),\n        window_north = cid(\"gdo_city:window_north\"), window_south = cid(\"gdo_city:window_south\"),\n        window_west = cid(\"gdo_city:window_west\"), window_east = cid(\"gdo_city:window_east\"),\n        window_shutter_north = cid(\"gdo_city:window_shutter_north\"),\n        window_shutter_south = cid(\"gdo_city:window_shutter_south\"),\n        window_shutter_west = cid(\"gdo_city:window_shutter_west\"),\n        window_shutter_east = cid(\"gdo_city:window_shutter_east\"),")
renderer_source = replace_once(
    renderer_source,
    [=[register_node("gdo_city:window_arch", "Claveau de fenêtre", atlas_tile(3, 0))]=],
    [=[register_node("gdo_city:window_arch", "Claveau de fenêtre", atlas_tile(3, 0))
    local glass_def = minetest.registered_nodes[M.glass] or {}
    local glass_tiles = glass_def.tiles or {}
    local glass_texture = glass_tiles[1] or atlas_tile(1, 2)
    local function register_window_plane(name, fixed)
        minetest.register_node(name, {
            description = "Fenêtre ancienne",
            drawtype = "nodebox",
            tiles = {glass_texture},
            paramtype = "light",
            sunlight_propagates = true,
            use_texture_alpha = "blend",
            walkable = true,
            node_box = {type = "fixed", fixed = fixed},
            selection_box = {type = "fixed", fixed = fixed},
            groups = {cracky = 2, not_in_creative_inventory = 1},
        })
    end
    register_window_plane("gdo_city:window_north", {{-0.30,-0.46,-0.50,0.30,0.46,-0.43}})
    register_window_plane("gdo_city:window_south", {{-0.30,-0.46,0.43,0.30,0.46,0.50}})
    register_window_plane("gdo_city:window_west", {{-0.50,-0.46,-0.30,-0.43,0.46,0.30}})
    register_window_plane("gdo_city:window_east", {{0.43,-0.46,-0.30,0.50,0.46,0.30}})
    local shutter_texture = atlas_tile(1, 2) .. "^[multiply:#60756d"
    local function register_window_shutter(name, fixed)
        minetest.register_node(name, {
            description = "Volet ancien",
            drawtype = "nodebox",
            tiles = {shutter_texture},
            paramtype = "light",
            sunlight_propagates = true,
            walkable = true,
            node_box = {type = "fixed", fixed = fixed},
            selection_box = {type = "fixed", fixed = fixed},
            groups = {cracky = 2, not_in_creative_inventory = 1},
        })
    end
    register_window_shutter("gdo_city:window_shutter_north", {{-0.40,-0.46,-0.50,0.40,0.46,-0.43}})
    register_window_shutter("gdo_city:window_shutter_south", {{-0.40,-0.46,0.43,0.40,0.46,0.50}})
    register_window_shutter("gdo_city:window_shutter_west", {{-0.50,-0.46,-0.40,-0.43,0.46,0.40}})
    register_window_shutter("gdo_city:window_shutter_east", {{0.43,-0.46,-0.40,0.50,0.46,0.40}})]=]
)
renderer_source = replace_once(
    renderer_source,
    [=[local bbox = data.meta.bbox
local LOCAL_BOUNDS = {
    x1 = math.floor(bbox[1] - 5), x2 = math.ceil(bbox[3] + 5),
    z1 = math.floor(bbox[2] - 5), z2 = math.ceil(bbox[4] + 40),
}]=],
    [=[local bbox = data.meta.bbox
local TRANSITION_MARGIN = 384
local terrain = data.terrain
local LOCAL_BOUNDS = {
    x1 = math.floor(math.min(bbox[1], terrain.xmin) - TRANSITION_MARGIN),
    x2 = math.ceil(math.max(bbox[3], terrain.xmax) + TRANSITION_MARGIN),
    z1 = math.floor(math.min(bbox[2], terrain.zmin) - TRANSITION_MARGIN),
    z2 = math.ceil(math.max(bbox[4], terrain.zmax) + TRANSITION_MARGIN),
}]=]
)
renderer_source = replace_once(
    renderer_source,
    "local CITY_Y_BELOW, CITY_Y_ABOVE = 18, 110",
    "local CITY_Y_BELOW, CITY_Y_ABOVE = 18, 180"
)
renderer_source = replace_once(
    renderer_source,
    [=[            ids = node_ids,]=],
    [=[            ids = node_ids,
            transition_margin = TRANSITION_MARGIN,
            find_surface_y = A.find_surface_y,]=]
)
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
