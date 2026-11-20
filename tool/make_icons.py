#!/usr/bin/env python3
"""Generates the launcher icon PNGs (emerald background, gold eight-pointed star).

Usage: python3 tool/make_icons.py <android/app/src/main/res directory>
Requires Pillow (pip install pillow). Uses only drawing primitives plus the
bundled KFGQPC font for the Arabic-Indic digits.
"""
import math
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
FONT = ROOT / "assets" / "fonts" / "KFGQPC_Uthmanic_Script_Hafs.otf"

EMERALD_DARK = (6, 62, 49)
EMERALD_LIGHT = (14, 122, 96)
GOLD = (233, 200, 118)
GOLD_SOFT = (201, 162, 75)


def star_points(cx, cy, r, rotation=0.0):
    """Corners of a square of circumradius r (used twice, 45 degrees apart)."""
    return [
        (cx + r * math.cos(rotation + k * math.pi / 2),
         cy + r * math.sin(rotation + k * math.pi / 2))
        for k in range(4)
    ]


def render(size=1024):
    scale = 2  # supersample for smooth edges
    s = size * scale
    img = Image.new("RGB", (s, s), EMERALD_DARK)
    px = img.load()
    cx = cy = s / 2
    maxd = math.hypot(cx, cy)
    for y in range(s):
        for x in range(s):
            t = min(1.0, math.hypot(x - cx, y - cy) / maxd)
            k = 1.0 - t
            px[x, y] = tuple(int(EMERALD_DARK[i] + (EMERALD_LIGHT[i] - EMERALD_DARK[i]) * k * 0.9)
                             for i in range(3))
    d = ImageDraw.Draw(img)
    r = s * 0.30
    w = max(2, int(s * 0.012))
    for rot in (math.pi / 4, 0.0):
        d.polygon(star_points(cx, cy, r * 1.414, rot), outline=GOLD, width=w)
    d.ellipse([cx - r * 0.78, cy - r * 0.78, cx + r * 0.78, cy + r * 0.78],
              outline=GOLD_SOFT, width=max(2, w // 2))
    try:
        font = ImageFont.truetype(str(FONT), int(s * 0.36))
        text = "٣٠"  # Arabic-Indic 3 and 0
        bbox = d.textbbox((0, 0), text, font=font)
        tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
        d.text((cx - tw / 2 - bbox[0], cy - th / 2 - bbox[1]), text, font=font, fill=GOLD)
    except Exception as exc:  # icon still fine without the number
        print("warning: could not draw digits:", exc, file=sys.stderr)
    return img.resize((size, size), Image.LANCZOS)


def main():
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(2)
    res = Path(sys.argv[1])
    base = render(1024)
    for folder, px in (("mipmap-mdpi", 48), ("mipmap-hdpi", 72), ("mipmap-xhdpi", 96),
                       ("mipmap-xxhdpi", 144), ("mipmap-xxxhdpi", 192)):
        out = res / folder
        out.mkdir(parents=True, exist_ok=True)
        base.resize((px, px), Image.LANCZOS).save(out / "ic_launcher.png")
    base.save(ROOT / "assets" / "icon-1024.png")
    print("icons written to", res)


if __name__ == "__main__":
    main()
