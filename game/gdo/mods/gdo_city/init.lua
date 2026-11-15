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
        "[GDO][SOMMIERES] SIG compact actif. Génère data/sommieres_full_gis.b64 depuis l'archive 3D pour retrouver les 4 500 bâtiments.")
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

-- Select the extended IGN crop outside the compact town DEM.
importer_source = replace_once(
    importer_source,
    "local function get_surface(x, z)\n            return world_y(terrain_sample(t, x + 0.5, z + 0.5), cfg)\n        end",
    "local function get_surface(x, z)\n            local sx, sz = x + 0.5, z + 0.5\n            local ext, grid = data.terrain_extension, t\n            if ext and sx >= ext.xmin and sx <= ext.xmax and sz >= ext.zmin and sz <= ext.zmax\n                and not (sx >= t.xmin and sx <= t.xmax and sz >= t.zmin and sz <= t.zmax) then\n                grid = ext\n            end\n            return world_y(terrain_sample(grid, sx, sz), cfg)\n        end"
)

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

-- Pont Tibère uses dressed stone rather than an asphalt road surface.
importer_source = replace_once(
    importer_source,
    [=[if r.sf == "asphalt" then surface_id = ids.road_asphalt]=],
    [=[if is_bridge and r.n == "Pont Tibère" then surface_id = ids.road_stone
                elseif r.sf == "asphalt" then surface_id = ids.road_asphalt]=]
)

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
    local use_balcony = historic and (b.h or 0) >= 10
    local use_awning = historic and kind == "retail"
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
                -- A narrow transparent pane flush with the facade, not a glass cube.
                for dy = 0, window_height - 1 do
                    set_block(x, fy + dy, z, window_id)
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
    "set_block(x, road_y, z, surface_id)\n                            road_mask[(z - lz1) * (lx2 - lx1 + 1) + (x - lx1) + 1] = true"
)
-- The replacement building renderer declares its own road-aware block writer.

local building_renderer = [=[
-- 4) Individual footprints: clear first, then roofs, then historic facades.
local visible_buildings = {}
local building_footprint_mask = {}

local function set_building_block(x, y, z, id)
    if x < lx1 or x > lx2 or z < lz1 or z > lz2 then return end
    local key = (z - lz1) * (lx2 - lx1 + 1) + (x - lx1) + 1
    if road_mask[key] then return end
    set_block(x, y, z, id)
end

-- Pass 1: clear all interiors before drawing any facade, so adjacent houses
-- cannot erase one another. Heights stay tied to each BD TOPO measurement.
for _, b in ipairs(buildings) do
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

-- Pass 2: measured roof planes, followed by the occasional old chimney stack.
for _, b in ipairs(visible_buildings) do
    local ax1, ax2 = math.max(lx1, math.floor(b._x1)), math.min(lx2, math.ceil(b._x2))
    local az1, az2 = math.max(lz1, math.floor(b._z1)), math.min(lz2, math.ceil(b._z2))
    for z = az1, az2 do
        for x = ax1, ax2 do
            if in_building(x + 0.5, z + 0.5, b) then
                local roof_y = make_roof_height(b, x, z)
                if roof_y then
                    for roof_block_y = b._top_y + 1, roof_y do
                        set_building_block(x, roof_block_y, z, b._roof_id)
                    end
                end
            end
        end
    end

    local kind = b.t or "yes"
    local seed = math.floor(math.abs((b.p[1][1] or 0) * 31 + (b.p[1][2] or 0) * 17 + (b.h or 0) * 13))
    local roof = b.r or {}
    if roof.s ~= "flat" and roof.o and kind ~= "tower" and kind ~= "church"
        and kind ~= "castle" and seed % 8 == 0 then
        local o = roof.o
        local angle = o[5] or 0
        local rx = math.floor(o[1] + math.cos(angle) * (o[3] or 0) * 0.18 + 0.5)
        local rz = math.floor(o[2] - math.sin(angle) * (o[3] or 0) * 0.18 + 0.5)
        local ry = make_roof_height(b, rx, rz)
        if ry then
            set_building_block(rx, ry + 1, rz, ids.chimney)
            set_building_block(rx, ry + 2, rz, ids.chimney)
            set_building_block(rx, ry + 3, rz, ids.limestone_trim)
        end
    end
end

-- Pass 3: Languedoc facades. Pale limewash stays visible, the ground floor is
-- stone, corners are dressed, and selective string-courses break up tall walls.
for _, b in ipairs(visible_buildings) do
    local floor_y, top_y = b._base_y, b._top_y
    local kind = b.t or "yes"
    local seed = math.floor(math.abs((b.p[1][1] or 0) * 31 + (b.p[1][2] or 0) * 17 + (b.h or 0) * 13))
    local style = seed % 7
    local dx_core, dz_core = (b._x1 + b._x2) / 2 - 84.76, (b._z1 + b._z2) / 2 - 143.44
    local footprint_area = math.max(0, b._x2 - b._x1) * math.max(0, b._z2 - b._z1)
    local historic_core = dx_core * dx_core + dz_core * dz_core <= 260 * 260
        and footprint_area <= 1400 and kind ~= "industrial" and kind ~= "greenhouse"
        and kind ~= "school" and kind ~= "kindergarten" and kind ~= "office" and kind ~= "service"
    local bands, timber = false, false
    local religious = kind == "church" or kind == "temple"
    local named_gate = b.n == "Porte du Bourguet"
    local named_belfry = b.n == "Beffroi de Sommières"
        or b.n == "La tour de l'horloge" or b.n == "Tour Bermond"
    local fortified = kind == "tower" or kind == "castle" or kind == "city_gate"
        or b.hist == "city_gate" or b.hist == "castle"
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
                    local corner = step == 0 or step == steps
                    for y = floor_y - 1, top_y do
                        local rel = y - floor_y
                        local wall_id = b._wall_id
                        if historic_core then
                            if rel <= 0 then
                                wall_id = ids.ashlar
                            elseif rel == (top_y - floor_y) then
                                wall_id = ids.limestone_trim
                            elseif corner and rel > 0 and rel % 2 == 0 then
                                wall_id = ids.ashlar
                            end
                        elseif rel <= 1 then
                            wall_id = ids.ashlar
                        elseif rel == (top_y - floor_y) then
                            wall_id = ids.limestone_trim
                        elseif corner and rel > 1 and rel % 3 == 0 then
                            wall_id = ids.ashlar
                        end
                        if fortified and rel == (top_y - floor_y) then
                            wall_id = ids.ashlar
                        end
                        set_building_block(x, y, z, wall_id)
                    end
                    -- Buttresses only on actual large religious or defensive buildings.
                    if (kind == "church" or kind == "temple" or fortified)
                        and corner and length >= 7 then
                        for y = floor_y + 2, top_y - 1 do
                            if y % 4 == 0 then set_building_block(x, y, z, ids.ashlar) end
                        end
                    end
                end
            end
        end
    end

    -- Merlons belong to named/typed defensive structures, not ordinary roofs.
    if fortified then
        for _, ring in ipairs({b.p}) do
            for i = 1, #ring do
                local a, d = ring[i], ring[i % #ring + 1]
                local dx, dz = d[1] - a[1], d[2] - a[2]
                local steps = math.max(1, math.ceil(math.sqrt(dx * dx + dz * dz)))
                for step = 0, steps, 2 do
                    local f = step / steps
                    local x = math.floor(a[1] + dx * f + 0.5)
                    local z = math.floor(a[2] + dz * f + 0.5)
                    set_building_block(x, top_y + 1, z, ids.ashlar)
                end
            end
        end
    end

    register_wall_windows(set_building_block, b, b.p, cfg,
        ids.glass, ids.limestone_trim, ids.shutter, ids.door, ids, segments)

    -- Fill the triangular end walls of measured two-pitch roofs.
    local roof = b.r or {}
    if roof.s == "gab" and roof.o and (b.rh or 0) >= 0.5 then
        local o = roof.o
        local rx, rz, rw, rd, angle = o[1], o[2], o[3], o[4], o[5] or 0
        local half_w, half_d = math.max(0.5, rw / 2), math.max(0.5, rd / 2)
        local ca, sa = math.cos(angle), math.sin(angle)
        local steps = math.max(2, math.ceil(half_d * 2))
        for _, side in ipairs({-1, 1}) do
            local u = side * half_w
            for step = 0, steps do
                local v = -half_d + 2 * half_d * step / steps
                local px = math.floor(rx + u * ca - v * sa + 0.5)
                local pz = math.floor(rz + u * sa + v * ca + 0.5)
                local rise = math.max(0, math.floor((b.rh or 0) * (1 - math.abs(v) / half_d) + 0.5))
                for y = top_y + 1, top_y + rise do
                    set_building_block(px, y, pz, b._wall_id)
                end
            end
        end
    elseif roof.s == "flat" and historic_core then
        -- The low acroterion is a 42 cm nodebox, not a full-height modern parapet.
        for i = 1, #b.p do
            local a, c = b.p[i], b.p[i % #b.p + 1]
            local dx, dz = c[1] - a[1], c[2] - a[2]
            local length = math.sqrt(dx * dx + dz * dz)
            local steps = math.max(1, math.ceil(length))
            for step = 0, steps do
                local f = step / steps
                local px = math.floor(a[1] + dx * f + 0.5)
                local pz = math.floor(a[2] + dz * f + 0.5)
                set_building_block(px, top_y + 2, pz, ids.roof_parapet)
            end
        end
    end

    -- Churches and temples receive a compact bell tower and a stepped local
    -- roof cap. Its base remains within the measured building height.
    if religious and (named_belfry or b.n == "Église Saint-Pons") and (b.h or 0) >= 8 then
        local roof = b.r or {}
        local cx = math.floor((roof.o and roof.o[1] or (b._x1 + b._x2) / 2) + 0.5)
        local cz = math.floor((roof.o and roof.o[2] or (b._z1 + b._z2) / 2) + 0.5)
        local tower_base = math.max(floor_y + 3, top_y - 5)
        for y = tower_base, top_y + 1 do
            for dx = -1, 1 do
                for dz = -1, 1 do
                    if math.abs(dx) == 1 or math.abs(dz) == 1 then
                        set_block(cx + dx, y, cz + dz, ids.ashlar)
                    end
                end
            end
        end
        -- Open belfry on the four faces.
        for _, p in ipairs({
            {cx, top_y, cz - 1}, {cx, top_y, cz + 1},
            {cx - 1, top_y, cz}, {cx + 1, top_y, cz},
        }) do
            set_block(p[1], p[2], p[3], ids.glass)
        end
        for layer = 0, 2 do
            local inset = layer
            for dx = -1 + inset, 1 - inset do
                for dz = -1 + inset, 1 - inset do
                    set_block(cx + dx, top_y + 2 + layer, cz + dz, b._roof_id)
                end
            end
        end
        set_block(cx, top_y + 5, cz, ids.limestone_trim)
    end

    -- The Porte du Bourguet is a real passage, not a blind rectangular facade.
    if named_gate then
        local longest, edge = 0, nil
        for i = 1, #b.p do
            local a, d = b.p[i], b.p[i % #b.p + 1]
            local len = math.sqrt((d[1] - a[1])^2 + (d[2] - a[2])^2)
            if len > longest then longest, edge = len, {a, d} end
        end
        if edge and longest >= 4 then
            local a, d = edge[1], edge[2]
            local dx, dz = d[1] - a[1], d[2] - a[2]
            local x = math.floor((a[1] + d[1]) / 2 + 0.5)
            local z = math.floor((a[2] + d[2]) / 2 + 0.5)
            if math.abs(dx) >= math.abs(dz) then
                for off = -1, 1 do
                    for y = floor_y + 1, floor_y + 4 do
                        set_block(x + off, y, z, ids.air)
                    end
                end
                for off = -2, 2 do
                    set_building_block(x + off, floor_y + 5, z, ids.limestone_trim)
                end
                for y = floor_y + 1, floor_y + 4 do
                    set_building_block(x - 2, y, z, ids.ashlar)
                    set_building_block(x + 2, y, z, ids.ashlar)
                end
            else
                for off = -1, 1 do
                    for y = floor_y + 1, floor_y + 4 do
                        set_block(x, y, z + off, ids.air)
                    end
                end
                for off = -2, 2 do
                    set_building_block(x, floor_y + 5, z + off, ids.limestone_trim)
                end
                for y = floor_y + 1, floor_y + 4 do
                    set_building_block(x, y, z - 2, ids.ashlar)
                    set_building_block(x, y, z + 2, ids.ashlar)
                end
            end
        end
    end

    -- Named clock towers and the Beffroi get a visible stone clock face.
    if named_belfry then
        local cx = math.floor((b._x1 + b._x2) / 2 + 0.5)
        local cz = math.floor((b._z1 + b._z2) / 2 + 0.5)
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

-- In the dense old town, narrow residual strips beside attached houses are
-- paved calades, not bright green lawns. Road cells and adjacent plots win.
for _, b in ipairs(visible_buildings) do
    local bx = (b._x1 + b._x2) / 2 - 84.76
    local bz = (b._z1 + b._z2) / 2 - 143.44
    local footprint_area = math.max(0, b._x2 - b._x1) * math.max(0, b._z2 - b._z1)
    local historic = bx * bx + bz * bz <= 260 * 260 and footprint_area <= 1400
        and b.t ~= "industrial" and b.t ~= "greenhouse" and b.t ~= "school"
        and b.t ~= "kindergarten" and b.t ~= "office" and b.t ~= "service"
    if historic then
        local ring = b.p
        local area = 0
        for i = 1, #ring do
            local a, c = ring[i], ring[i % #ring + 1]
            area = area + a[1] * c[2] - c[1] * a[2]
        end
        local orientation = area >= 0 and 1 or -1
        for i = 1, #ring do
            local a, c = ring[i], ring[i % #ring + 1]
            local dx, dz = c[1] - a[1], c[2] - a[2]
            local length = math.sqrt(dx * dx + dz * dz)
            if length > 1.5 then
                local nx, nz = orientation * dz / length, -orientation * dx / length
                local steps = math.max(1, math.ceil(length * 1.5))
                for step = 0, steps do
                    local f = step / steps
                    local ex, ez = a[1] + dx * f, a[2] + dz * f
                    for _, offset in ipairs({1, 2}) do
                        local px = math.floor(ex + nx * offset + 0.5)
                        local pz = math.floor(ez + nz * offset + 0.5)
                        if px >= lx1 and px <= lx2 and pz >= lz1 and pz <= lz2 then
                            local key = (pz - lz1) * (lx2 - lx1 + 1) + (px - lx1) + 1
                            if not road_mask[key] and not building_footprint_mask[key] then
                                local ground = tile_cache[key]
                                if ground then set_building_block(px, ground, pz, ids.road_stone) end
                            end
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

-- The replacement building renderer uses set_building_block directly.
local importer_chunk, importer_err = loader(importer_source, "@gdo_city/gis_import.lua")
assert(importer_chunk, importer_err)
_G.__gdo_city_gis_importer = importer_chunk()

local renderer_source = minetest.decompress(read_file("renderer.deflate"), "deflate")
assert(renderer_source, "[GDO Sommières] Renderer GIS compressé invalide.")
renderer_source = replace_once(renderer_source, "local VERSION = 6", "local VERSION = 19")
renderer_source = replace_once(
    renderer_source,
    [=[center_x, center_z, base_y = candidate[1], candidate[2], ground_y]=],
    [=[center_x, center_z, base_y = candidate[1], candidate[2], math.floor(ref_elevation + 1.5)]=]
)
renderer_source = replace_once(
    renderer_source,
    [=[base_y = storage:get_int("city_y")]=],
    [=[base_y = math.floor(ref_elevation + 1.5)
        storage:set_int("city_y", base_y)]=]
)
renderer_source = replace_once(
    renderer_source,
    [=[local natural = A.find_surface_y(rx, rz)
                            if natural then base_y = natural; storage:set_int("city_y", natural) end]=],
    [=[base_y = math.floor(ref_elevation + 1.5)
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
renderer_source = replace_once(renderer_source, "shutter = cid(\"gdo_city:shutter\"), door = cid(\"gdo_city:wooden_door\"),", "shutter = cid(\"gdo_city:shutter\"), door = cid(\"gdo_city:wooden_door\"),\n        timber = cid(\"gdo_city:timber_beam\"), arch = cid(\"gdo_city:window_arch\"),\n        chimney = cid(\"gdo_city:chimney\"), awning = cid(\"gdo_city:shop_awning\"),\n        roof_parapet = cid(\"gdo_city:roof_parapet\"),\n        balcony_ns = cid(\"gdo_city:iron_balcony_ns\"), balcony_ew = cid(\"gdo_city:iron_balcony_ew\"),\n        window_north = cid(\"gdo_city:window_north\"), window_south = cid(\"gdo_city:window_south\"),\\n        window_west = cid(\"gdo_city:window_west\"), window_east = cid(\"gdo_city:window_east\"),")
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
            walkable = false,
            node_box = {type = "fixed", fixed = fixed},
            selection_box = {type = "fixed", fixed = fixed},
            groups = {cracky = 2, not_in_creative_inventory = 1},
        })
    end
    register_window_plane("gdo_city:window_north", {{-0.30,-0.46,-0.50,0.30,0.46,-0.43}})
    register_window_plane("gdo_city:window_south", {{-0.30,-0.46,0.43,0.30,0.46,0.50}})
    register_window_plane("gdo_city:window_west", {{-0.50,-0.46,-0.30,-0.43,0.46,0.30}})
    register_window_plane("gdo_city:window_east", {{0.43,-0.46,-0.30,0.50,0.46,0.30}})]=]
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
