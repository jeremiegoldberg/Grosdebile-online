# GDO Castle Architecture

The replacement castle is built zone by zone. The modular castle is built incrementally. Zones 00, 10, 20, 30 and the first gatehouse stair implementation in 70 are in code; all still require in-game validation.

## Rules

- Every zone has its own file under `zones/`.
- All coordinates passed to common helpers are absolute world coordinates.
- A zone owns only its declared bounding box. It must not clear or rewrite another zone.
- No zone may run a full-castle cleanup.
- A completed zone stores its own version and any reference elevations in mod storage.
- Later zones are built only after the previous zone has been checked in-game.
- Staircases use the single `gdo_castle:refit_stair` node. A stair tread is never accompanied by a decorative full-cube support block.

## Zone sequence

| ID | Module | Contents | Status |
|---|---|---|---|
| 00 | `00_site.lua` | Natural terrain survey, castle platform, forecourt, level village platform | Implemented; requires in-game validation |
| 10 | `10_enclosure.lua` | Curtain walls, battlements, wall walks | Implemented; requires in-game validation |
| 20 | `20_gatehouse.lua` | Twin gate towers, upper guard gallery, portal, portcullis and drawbridge | Updated with wall tie-ins and walk-in tower doors; requires in-game validation |
| 30 | `30_towers.lua` | Four chamfered corner towers integrated with the curtain walls and wall walks | Implemented; requires in-game validation |
| 40 | `40_keep.lua` | Keep structure, floors, rooms and roof | Not started |
| 50 | `50_residential.lua` | Great hall and lord's residence | Not started |
| 60 | `60_courtyard_buildings.lua` | Chapel, workshops, school and service buildings | Not started |
| 70 | `70_stairs.lua` | Two 2-wide stair flights from the gatehouse ground floor to its +9 first floor; future stair types remain planned | Partially implemented; requires in-game validation |
| 80 | `80_courtyard.lua` | Paving, wells, gardens and props | Not started |
| 90 | `90_village.lua` | Village streets, houses, inn, shops and workshops | Not started |
| 95 | `95_landscape.lua` | Terrain blending, trees, fields, ponds and paths | Not started |
| 99 | `99_connections.lua` | Doors, bridges and final inter-zone links | Not started |

## Zone 00

- Castle platform: X -43..43, Z -54..75.
- Village platform: X -43..43, Z 80..128.
- Each platform gets one independently surveyed elevation.
- Existing castle-prefixed nodes above the target surface are removed from these footprints.
- The player is moved to the castle forecourt only after the site build completes.
- Commands: `/gdo_site` rebuilds zone 00; `/gdo_site_info` reports saved elevations.

## Zone 10

- Bounds: X -39..39, Z -41..39.
- Four curtain-wall runs form the perimeter; the south wall intentionally has an 11-block gap at X -5..5 for the future gatehouse.
- Wall body rises 9 blocks above the site surface; the continuous wall walk is at +10, with alternating crenels at +11 and +12.
- Corner cores are structural only; future towers are separate modules.
- The zone does not construct stairs, towers, gates, roofs, or courtyard buildings.
- Commands: `/gdo_zone10` rebuilds only the enceinte; `/gdo_zone10_info` reports its version and elevation.

## Zone 20

- Bounds: X -18..18, Z 24..61.
- Passage is 7 blocks wide, from X -3..3, and remains open from the floor through Y +8.
- Paired stone jambs are at X -5..-4 and X 4..5; portal frames are at Z 33 and Z 40.
- The raised portcullis is above head height at Z 37; it does not fill the walking passage.
- The drawbridge is a flat 7-wide timber deck from Z 42..58, exactly level with the castle forecourt and approach path. The two end thresholds are flush deck planks; no raised step crosses the walking lane.
- Side moat channels are at X -17..-4 and X 4..17, Z 49..55.
- Includes two integral gate towers (X -17..-7 and 7..17), each with two interior levels, arrow slits, corner quoins and crenellated roof walk. Ground-level 3-wide doorways on the courtyard-facing sides open directly into the lower tower rooms.
- Short connector piers at X=-18 and X=18 close the one-node gaps between the two gate towers and the south curtain wall; the wall-walk and exterior trim continue across these joints.
- Includes an upper guard gallery spanning the portal at Y +15..+26, with windows, interior lights and a crenellated roof terrace.
- The portal has a stepped pointed-arch profile; the ground passage remains 7 blocks wide and 8 blocks high.
- The portcullis is raised above the walking clearance. The drawbridge and both approaches form one continuous, level walking surface.
- Staircases are intentionally excluded; floors are reserved for the independent zone 70 staircase module.
- Commands: `/gdo_zone20` rebuilds only the gatehouse; `/gdo_zone20_info` reports its version and elevation.

## Zone 30

- Four chamfered towers are centered at (-37,-39), (37,-39), (-37,37) and (37,37).
- Each tower replaces the old corner core and the intersecting end of its two curtain walls.
- Courtyard-facing doorways enter the ground-floor chambers.
- Two upper openings per tower connect the two wall-walks that meet at that corner; the exterior-facing sides remain closed.
- The wall-walk floor at +10 continues through both connections. Upper lintels are at +15.
- Commands: `/gdo_zone30` rebuilds the four towers; `/gdo_zone30_info` reports their version and elevation.

## Zone 70 — Gatehouse stair flights

- Two stair flights are built inside the gatehouse towers, each two blocks wide.
- The west tower flight uses X -15..-14; the east tower flight uses X 14..15.
- Both flights rise toward +Z, from Z 27 to Z 35, and reach the first-floor landing at `base_y + 9`.
- Only `gdo_castle:refit_stair` nodes are used for the treads; no full-cube blocks are placed underneath them.
- The stair module owns only its stair columns and the small landing. Rebuilding zone 20 invalidates and regenerates these stairs.
- Commands: `/gdo_stairs` rebuilds the stair flights; `/gdo_stairs_info` reports their version and elevation.
