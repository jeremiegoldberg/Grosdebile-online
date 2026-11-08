#!/usr/bin/env python3
"""Generate the seamless pixel-art texture set used by GDO's Castle of Mists.
Uses only Python's standard library; no Pillow dependency.
Run from the repository root:
    python3 tools/generate_castle_textures.py
"""
from pathlib import Path
import math, random, struct, zlib

OUT = Path("game/gdo/mods/gdo_castle/textures")
SIZE = 32
random.seed(2408)

def png(path, pixels):
    raw = b"".join(b"\x00" + bytes(v for px in row for v in px) for row in pixels)
    def chunk(tag, data):
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xffffffff)
    data = (b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack(">2I5B", SIZE, SIZE, 8, 2, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))
    path.write_bytes(data)

def texture(kind, base, accent, dark):
    img=[]
    for y in range(SIZE):
        row=[]
        for x in range(SIZE):
            n=random.randint(-8,8)
            col=base
            if kind == "stone":
                mortar = (y % 8 == 0) or ((x + (4 if (y//8)%2 else 0)) % 16 == 0)
                col = dark if mortar else (accent if random.random()<0.13 else base)
            elif kind == "trim":
                edge = x in (2,3,28,29) or y in (2,3,28,29)
                col = accent if edge else (dark if random.random()<0.08 else base)
            elif kind == "roof":
                seam = y % 8 == 0 or (x + (y//8%2)*8) % 16 == 0
                col = dark if seam else (accent if random.random()<0.12 else base)
            elif kind in ("floor","path"):
                seam = (x % 8 == 0) or (y % 8 == 0)
                if kind == "path":
                    seam = (x % 8 == 0) or ((y + (x//8%2)*4) % 8 == 0)
                col = dark if seam else (accent if random.random()<0.10 else base)
            elif kind == "wood":
                col = accent if (x + random.randint(0,2)) % 9 in (0,1) else base
                if y in (7,23) and random.random()<0.6: col=dark
            elif kind == "glass":
                col = accent if (x+y)%11 < 2 else base
                if x==y or x+y==31: col=dark
            elif kind == "gold":
                col = accent if (x+y)%13 < 2 else base
                if x in (0,31) or y in (0,31): col=dark
            elif kind == "grass":
                col = accent if random.random()<0.22 else base
                if random.random()<0.035: col=dark
            elif kind == "leaves":
                col = accent if random.random()<0.35 else base
                if random.random()<0.10: col=dark
            elif kind == "water":
                col = accent if (y + (x//6))%9 in (0,1) else base
                if random.random()<0.04: col=(210,235,245)
            row.append(tuple(max(0,min(255,c+n)) for c in col))
        img.append(row)
    png(OUT/f"refit_{kind}.png", img)

def main():
    OUT.mkdir(parents=True, exist_ok=True)
    specs = {
      "stone":((105,113,130),(151,158,169),(57,64,79)),
      "trim":((190,185,171),(231,222,199),(112,108,103)),
      "roof":((34,52,83),(66,88,125),(16,25,43)),
      "floor":((177,169,151),(211,203,183),(113,108,99)),
      "wood":((105,67,42),(151,99,58),(54,35,25)),
      "glass":((86,151,190),(178,222,238),(38,77,113)),
      "gold":((205,151,44),(248,207,91),(116,77,22)),
      "grass":((74,126,55),(104,158,67),(43,84,39)),
      "path":((133,130,122),(173,167,151),(82,80,78)),
      "leaves":((43,111,50),(85,157,64),(24,69,35)),
      "water":((40,119,173),(93,184,218),(20,70,117)),
    }
    for name, colors in specs.items():
        texture(name, *colors)
    print(f"{len(specs)} textures PNG créées dans {OUT}")

if __name__ == "__main__":
    main()
