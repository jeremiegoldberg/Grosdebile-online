#!/usr/bin/env python3
"""Build the full Sommières GIS payload from the original sommieres3d ZIP.

Run from the repository root:
    python3 tools/build_sommieres_gis.py /path/to/sommieres3d.zip

The generated payload is written directly to the gdo_city data directory.
It is intentionally not committed automatically: check the source-data
redistribution terms before publishing it in a public repository.
"""
from __future__ import annotations

import argparse
import base64
import json
import sys
import zipfile
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_OUTPUT = ROOT / "game/gdo/mods/gdo_city/data/sommieres_full_gis.b64"
REQUIRED = {"buildings", "roads", "terrain", "water", "nature", "pois"}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("archive", type=Path, help="original sommieres3d ZIP archive")
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT,
                        help="output path (default: gdo_city/data/sommieres_full_gis.b64)")
    args = parser.parse_args()

    if not args.archive.is_file():
        parser.error(f"archive not found: {args.archive}")

    with zipfile.ZipFile(args.archive) as archive:
        members = {}
        for name in archive.namelist():
            basename = name.rsplit("/", 1)[-1]
            if basename.endswith(".json") and basename[:-5] in REQUIRED:
                members[basename[:-5]] = name
        missing = REQUIRED - members.keys()
        if missing:
            parser.error("missing GIS layers in ZIP: " + ", ".join(sorted(missing)))

        gis = {key: json.loads(archive.read(members[key])) for key in sorted(REQUIRED)}

    counts = {
        "buildings": len(gis["buildings"]),
        "roads": len(gis["roads"]),
        "trees": len(gis["nature"].get("trees", [])),
        "pois": len(gis["pois"]),
    }
    if counts["buildings"] < 4000 or counts["roads"] < 1000:
        parser.error(f"unexpectedly small source dataset: {counts}")

    payload = json.dumps(gis, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    compressed = zlib.compress(payload, level=9)
    encoded = base64.encodebytes(compressed)

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_bytes(encoded)
    print("Sommières GIS package generated")
    print(f"  Buildings : {counts['buildings']}")
    print(f"  Roads     : {counts['roads']}")
    print(f"  Trees     : {counts['trees']}")
    print(f"  POIs      : {counts['pois']}")
    print(f"  JSON      : {len(payload):,} bytes")
    print(f"  Package   : {len(encoded):,} bytes")
    print(f"  Output    : {args.output}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
