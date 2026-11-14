# GDO Castle Architecture

The replacement castle is built zone by zone. The replacement castle is active only through the current validated construction step; zones 00 and 10 are implemented.

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
| 20 | `20_gatehouse.lua` | Gate passage, drawbridge, portcullis, moat | Not started |
| 30 | `30_towers.lua` | Independent corner and gate towers | Not started |
| 40 | `40_keep.lua` | Keep structure, floors, rooms and roof | Not started |
| 50 | `50_residential.lua` | Great hall and lord's residence | Not started |
| 60 | `60_courtyard_buildings.lua` | Chapel, workshops, school and service buildings | Not started |
| 70 | `70_stairs.lua` | Straight stair, U stair, spiral stair as separately testable modules | Not started |
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
