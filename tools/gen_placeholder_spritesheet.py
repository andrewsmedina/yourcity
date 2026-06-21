#!/usr/bin/env python3
"""Generate a PLACEHOLDER pixel-art spritesheet for TaskbarCity (issue #9).

This is throwaway art so the city has something to render until real pixel art
exists. Re-run to regenerate: `python3 tools/gen_placeholder_spritesheet.py`.

Layout: a single row of 16x16 tiles. Column index == frame index, see
TILE_NAMES for what each frame is. Keep this in sync with the slicing code in
scripts/city_tileset.gd.
"""

from PIL import Image, ImageDraw

TILE = 16
TILE_NAMES = ["ground", "road", "tree", "house", "building_low",
              "building_mid", "building_high", "park"]
OUT = "assets/city_spritesheet.png"

# Limited retro palette.
SKY = (0, 0, 0, 0)          # transparent
GROUND = (74, 99, 64)
ROAD = (60, 60, 68)
ROAD_LINE = (200, 200, 120)
TRUNK = (110, 70, 40)
LEAF = (90, 170, 90)
WALL = (120, 140, 170)
WALL_HI = (150, 170, 200)
WINDOW = (240, 220, 120)
WATER = (70, 130, 190)
OUTLINE = (30, 34, 44)


def _px(d, x, y, c):
    d.point((x, y), fill=c)


def draw_ground(d, ox):
    d.rectangle([ox, 12, ox + TILE - 1, TILE - 1], fill=GROUND)


def draw_road(d, ox):
    d.rectangle([ox, 12, ox + TILE - 1, TILE - 1], fill=GROUND)
    d.rectangle([ox + 2, 12, ox + TILE - 3, TILE - 1], fill=ROAD)
    for y in range(13, TILE, 3):
        _px(d, ox + TILE // 2, y, ROAD_LINE)


def draw_tree(d, ox):
    draw_ground(d, ox)
    d.rectangle([ox + 7, 9, ox + 8, 13], fill=TRUNK)
    d.ellipse([ox + 4, 2, ox + 11, 10], fill=LEAF, outline=OUTLINE)


def _building(d, ox, top):
    draw_ground(d, ox)
    d.rectangle([ox + 2, top, ox + TILE - 3, TILE - 1], fill=WALL, outline=OUTLINE)
    d.rectangle([ox + 2, top, ox + 3, TILE - 1], fill=WALL_HI)
    for wy in range(top + 2, TILE - 2, 3):
        for wx in range(ox + 4, ox + TILE - 3, 3):
            _px(d, wx, wy, WINDOW)


def draw_house(d, ox):
    _building(d, ox, 9)


def draw_building_low(d, ox):
    _building(d, ox, 7)


def draw_building_mid(d, ox):
    _building(d, ox, 4)


def draw_building_high(d, ox):
    _building(d, ox, 1)


def draw_park(d, ox):
    draw_ground(d, ox)
    d.ellipse([ox + 3, 10, ox + 12, 15], fill=WATER, outline=OUTLINE)


DRAWERS = [draw_ground, draw_road, draw_tree, draw_house,
           draw_building_low, draw_building_mid, draw_building_high, draw_park]


def main():
    img = Image.new("RGBA", (TILE * len(DRAWERS), TILE), SKY)
    d = ImageDraw.Draw(img)
    for i, drawer in enumerate(DRAWERS):
        drawer(d, i * TILE)
    img.save(OUT)
    print(f"wrote {OUT} ({img.width}x{img.height}, {len(DRAWERS)} tiles)")


if __name__ == "__main__":
    main()
