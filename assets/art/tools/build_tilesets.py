#!/usr/bin/env python3
"""Build reproducible 64x32 isometric tilesets, walls and vegetation for Masmorras, Monstros e Mandingas."""

from __future__ import annotations

import argparse
import json
import math
import random
from pathlib import Path
from PIL import Image, ImageChops, ImageDraw, ImageFilter


PALETTE = (
    (0x00, 0x00, 0x00),  # 0: outline black (external 1px only)
    (0x17, 0x12, 0x0D),  # 1: near black
    (0x33, 0x23, 0x1B),  # 2: deepest brown
    (0x4F, 0x33, 0x27),  # 3: dark leather / dark wood
    (0x60, 0x40, 0x27),  # 4: brown line
    (0x7A, 0x4A, 0x28),  # 5: wood / skin shadow
    (0x9B, 0x69, 0x3D),  # 6: earth shadow
    (0xA9, 0x79, 0x45),  # 7: earth / skin
    (0xC4, 0x9A, 0x61),  # 8: sand / light leather / dry mud
    (0xF2, 0xDF, 0xBD),  # 9: cream highlight / light dust / spines
    (0x94, 0x45, 0x2E),  # 10: dark rust / terracotta
    (0xD1, 0x5A, 0x3F),  # 11: bright rust / alert / flower
    (0x42, 0x64, 0x3D),  # 12: cactus dark
    (0x66, 0x86, 0x56),  # 13: cactus light
    (0x5D, 0x55, 0x47),  # 14: dull metal / stone
    (0x44, 0xD6, 0xB3),  # 15: turquoise magic / interaction
)

TILE_WIDTH = 64
TILE_HEIGHT = 32
HALF_W = TILE_WIDTH // 2   # 32
HALF_H = TILE_HEIGHT // 2  # 16


def is_inside_iso_diamond(x: int, y: int) -> bool:
    """Return True if (x, y) is inside the 64x32 2:1 isometric diamond."""
    if 0 <= y < 16:
        x_min = 31 - 2 * y
        x_max = 32 + 2 * y
        return x_min <= x <= x_max
    elif 16 <= y < 32:
        y_rel = y - 16
        x_min = 2 * y_rel
        x_max = 63 - 2 * y_rel
        return x_min <= x <= x_max
    return False


def create_iso_diamond_mask() -> Image.Image:
    """Create a 1-bit / 8-bit mask of the exact 64x32 isometric diamond."""
    mask = Image.new("L", (TILE_WIDTH, TILE_HEIGHT), 0)
    pixels = mask.load()
    for y in range(TILE_HEIGHT):
        for x in range(TILE_WIDTH):
            if is_inside_iso_diamond(x, y):
                pixels[x, y] = 255
    return mask


def add_external_outline_1px(image: Image.Image) -> Image.Image:
    """Add a 1px pure black (#000000) outer outline around the opaque pixels."""
    alpha = image.getchannel("A")
    mask = alpha.point(lambda p: 255 if p > 0 else 0)
    dilated = mask.filter(ImageFilter.MaxFilter(3))
    outline_mask = ImageChops.subtract(dilated, mask)

    outline = Image.new("RGBA", image.size, (0, 0, 0, 0))
    outline_pixels = outline.load()
    om_pixels = outline_mask.load()
    for y in range(image.height):
        for x in range(image.width):
            if om_pixels[x, y] > 0:
                outline_pixels[x, y] = (*PALETTE[0], 255)

    result = Image.new("RGBA", image.size, (0, 0, 0, 0))
    result.alpha_composite(outline)
    result.alpha_composite(image)
    return result


def generate_cracked_earth_tile(variant_seed: int) -> Image.Image:
    """Generate a single 64x32 isometric tile of cracked Caatinga earth."""
    rng = random.Random(variant_seed)
    tile = Image.new("RGBA", (TILE_WIDTH, TILE_HEIGHT), (0, 0, 0, 0))
    pixels = tile.load()

    # 1. Base terrain dithering and elevation noise
    for y in range(TILE_HEIGHT):
        for x in range(TILE_WIDTH):
            if not is_inside_iso_diamond(x, y):
                continue

            val = rng.random()
            if val < 0.45:
                color = PALETTE[7]  # Earth base
            elif val < 0.80:
                color = PALETTE[6]  # Earth shadow
            elif val < 0.95:
                color = PALETTE[8]  # Light sand / dry dust
            else:
                color = PALETTE[5]  # Deeper shade
            pixels[x, y] = (*color, 255)

    # 2. Draw procedural cracks based on variant seed
    crack_patterns = {
        0: [  # Fissuras leves centrais
            [(28, 6), (30, 10), (33, 14), (35, 18), (38, 22), (37, 26)],
            [(33, 14), (28, 17), (25, 20), (22, 22)],
            [(35, 18), (41, 19), (46, 21)],
        ],
        1: [  # Fendas profundas do sertão
            [(16, 12), (22, 14), (27, 13), (34, 16), (42, 17), (50, 14)],
            [(34, 16), (36, 20), (33, 24), (30, 28)],
            [(27, 13), (25, 9), (22, 7)],
            [(42, 17), (44, 22), (47, 25)],
        ],
        2: [  # Terra ressecada com placas poligonais
            [(31, 3), (33, 8), (31, 13), (24, 15), (18, 16)],
            [(31, 13), (38, 16), (44, 15), (52, 17)],
            [(38, 16), (36, 22), (39, 27)],
            [(24, 15), (26, 21), (23, 27)],
        ],
        3: [  # Fissuras ramificadas e cascalho
            [(20, 14), (26, 15), (32, 15), (38, 14), (45, 16)],
            [(26, 15), (29, 20), (31, 25)],
            [(38, 14), (40, 10), (43, 6)],
            [(32, 15), (34, 9), (32, 5)],
        ]
    }

    selected_cracks = crack_patterns.get(variant_seed % 4, crack_patterns[0])
    for branch in selected_cracks:
        for i in range(len(branch) - 1):
            p1, p2 = branch[i], branch[i + 1]
            steps = max(abs(p2[0] - p1[0]), abs(p2[1] - p1[1])) * 2
            if steps == 0:
                continue
            for s in range(steps + 1):
                t = s / steps
                cx = int(round(p1[0] + t * (p2[0] - p1[0])))
                cy = int(round(p1[1] + t * (p2[1] - p1[1])))
                if is_inside_iso_diamond(cx, cy):
                    pixels[cx, cy] = (*PALETTE[2], 255)
                    if is_inside_iso_diamond(cx, cy - 1) and rng.random() > 0.4:
                        pixels[cx, cy - 1] = (*PALETTE[8], 255)
                    if is_inside_iso_diamond(cx + 1, cy) and rng.random() > 0.5:
                        pixels[cx + 1, cy] = (*PALETTE[4], 255)

    # 3. Add dry sand flecks / small pebbles
    num_pebbles = rng.randint(4, 8)
    for _ in range(num_pebbles):
        px = rng.randint(6, 57)
        py = rng.randint(4, 27)
        if is_inside_iso_diamond(px, py):
            pixels[px, py] = (*PALETTE[9], 255)
            if is_inside_iso_diamond(px + 1, py + 1):
                pixels[px + 1, py + 1] = (*PALETTE[3], 255)

    return tile


def generate_beaten_path_tile(variant_seed: int) -> Image.Image:
    """Generate a single 64x32 isometric tile of beaten dirt/sand path (caminho batido)."""
    rng = random.Random(variant_seed + 100)
    tile = Image.new("RGBA", (TILE_WIDTH, TILE_HEIGHT), (0, 0, 0, 0))
    pixels = tile.load()

    mode = variant_seed % 4

    for y in range(TILE_HEIGHT):
        for x in range(TILE_WIDTH):
            if not is_inside_iso_diamond(x, y):
                continue

            d_center = abs((x - 32) + 2 * (y - 16)) / 32.0
            rand = rng.random()
            if mode == 3:
                if d_center > 0.7:
                    color = PALETTE[6] if rand < 0.6 else PALETTE[7]
                else:
                    color = PALETTE[8] if rand < 0.7 else PALETTE[9]
            elif mode == 0:
                if rand < 0.60:
                    color = PALETTE[8]
                elif rand < 0.85:
                    color = PALETTE[9]
                else:
                    color = PALETTE[7]
            elif mode == 1:
                if rand < 0.50:
                    color = PALETTE[8]
                elif rand < 0.75:
                    color = PALETTE[9]
                elif rand < 0.90:
                    color = PALETTE[7]
                else:
                    color = PALETTE[6]
            else:
                if rand < 0.55:
                    color = PALETTE[8]
                elif rand < 0.75:
                    color = PALETTE[7]
                elif rand < 0.90:
                    color = PALETTE[14]
                else:
                    color = PALETTE[9]

            pixels[x, y] = (*color, 255)

    if mode in (1, 2):
        track_points = [(18, 10), (26, 12), (34, 15), (42, 18), (50, 20)]
        for tx, ty in track_points:
            dx, dy = rng.randint(-1, 1), rng.randint(-1, 1)
            cx, cy = tx + dx, ty + dy
            if is_inside_iso_diamond(cx, cy):
                pixels[cx, cy] = (*PALETTE[6], 255)
                if is_inside_iso_diamond(cx, cy - 1):
                    pixels[cx, cy - 1] = (*PALETTE[9], 255)

    return tile


def generate_dungeon_stone_tile(variant_seed: int) -> Image.Image:
    """Generate a single 64x32 isometric tile of dungeon stone slabs (lajotas de pedra)."""
    rng = random.Random(variant_seed + 200)
    tile = Image.new("RGBA", (TILE_WIDTH, TILE_HEIGHT), (0, 0, 0, 0))
    pixels = tile.load()

    mode = variant_seed % 4

    for y in range(TILE_HEIGHT):
        for x in range(TILE_WIDTH):
            if not is_inside_iso_diamond(x, y):
                continue

            rand = rng.random()
            if rand < 0.55:
                color = PALETTE[14]  # Dull metal / stone gray
            elif rand < 0.80:
                color = PALETTE[2]   # Deepest brown / dark stone
            elif rand < 0.92:
                color = PALETTE[3]   # Dark leather
            else:
                color = PALETTE[8]   # Light stone edge
            pixels[x, y] = (*color, 255)

    if mode in (0, 1):
        for y in range(TILE_HEIGHT):
            for x in range(TILE_WIDTH):
                if not is_inside_iso_diamond(x, y):
                    continue
                if abs(y - (x // 2)) <= 0:
                    pixels[x, y] = (*PALETTE[1], 255)
                    if is_inside_iso_diamond(x, y + 1):
                        pixels[x, y + 1] = (*PALETTE[8], 255)
                if abs(y - ((63 - x) // 2)) <= 0:
                    pixels[x, y] = (*PALETTE[1], 255)
                    if is_inside_iso_diamond(x, y + 1):
                        pixels[x, y + 1] = (*PALETTE[8], 255)

    if mode == 1:
        crack = [(20, 8), (24, 11), (29, 13), (33, 17), (35, 22)]
        for i in range(len(crack) - 1):
            p1, p2 = crack[i], crack[i + 1]
            steps = max(abs(p2[0] - p1[0]), abs(p2[1] - p1[1])) * 2
            for s in range(steps + 1):
                t = s / steps
                cx = int(round(p1[0] + t * (p2[0] - p1[0])))
                cy = int(round(p1[1] + t * (p2[1] - p1[1])))
                if is_inside_iso_diamond(cx, cy):
                    pixels[cx, cy] = (*PALETTE[1], 255)
                    if is_inside_iso_diamond(cx, cy - 1):
                        pixels[cx, cy - 1] = (*PALETTE[9], 255)

    elif mode == 2:
        for y in range(8, 24):
            for x in range(16, 48):
                y_inner = y - 8
                if 0 <= y_inner < 8:
                    if 31 - 2 * y_inner <= x <= 32 + 2 * y_inner:
                        if x in (31 - 2 * y_inner, 32 + 2 * y_inner) or y == 8:
                            pixels[x, y] = (*PALETTE[8], 255)
                        else:
                            pixels[x, y] = (*PALETTE[2], 255)
                elif 8 <= y_inner < 16:
                    y_rel = y_inner - 8
                    if 2 * y_rel <= x - 16 <= 31 - 2 * y_rel:
                        if x - 16 in (2 * y_rel, 31 - 2 * y_rel) or y == 23:
                            pixels[x, y] = (*PALETTE[1], 255)
                        else:
                            pixels[x, y] = (*PALETTE[2], 255)

    elif mode == 3:
        rune_points = [
            (32, 10), (36, 13), (32, 16), (28, 13), (32, 10),
            (32, 22), (26, 18), (38, 18)
        ]
        for rx, ry in rune_points:
            if is_inside_iso_diamond(rx, ry):
                pixels[rx, ry] = (*PALETTE[15], 255)
                if is_inside_iso_diamond(rx, ry - 1):
                    pixels[rx, ry - 1] = (*PALETTE[9], 255)
        for gx, gy in [(30, 12), (34, 12), (31, 17), (33, 17)]:
            if is_inside_iso_diamond(gx, gy):
                pixels[gx, gy] = (*PALETTE[15], 255)

    return tile


def generate_taipa_wall_tile(variant: int) -> Image.Image:
    """Generate an isometric wattle-and-daub (taipa) wall tile in a 64x64 cell."""
    cell = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    pixels = cell.load()
    rng = random.Random(variant + 300)
    wall_height = 28

    if variant == 0:  # NE wall
        for h in range(wall_height):
            for t in range(32):
                x = t * 2
                y = 32 + t // 2 - h
                if 0 <= x < 64 and 0 <= y < 64:
                    is_wood_post = (t % 8 in (0, 1))
                    is_wattle_weave = (h % 5 == 0)
                    if is_wood_post:
                        col = PALETTE[5] if h > wall_height - 3 else PALETTE[3]
                    elif is_wattle_weave:
                        col = PALETTE[4]
                    else:
                        rand = rng.random()
                        col = PALETTE[8] if rand < 0.6 else (PALETTE[7] if rand < 0.85 else PALETTE[6])
                    pixels[x, y] = (*col, 255)
                    if x + 1 < 64:
                        pixels[x + 1, y] = (*col, 255)
        for t in range(32):
            x = t * 2
            y = 32 + t // 2 - wall_height
            if 0 <= x < 64 and 0 <= y < 64:
                pixels[x, y] = (*PALETTE[10], 255)
                if 0 <= y - 1 < 64:
                    pixels[x, y - 1] = (*PALETTE[11], 255)
                if x + 1 < 64:
                    pixels[x + 1, y] = (*PALETTE[10], 255)

    elif variant == 1:  # NW wall
        for h in range(wall_height):
            for t in range(32):
                x = 63 - t * 2
                y = 32 + t // 2 - h
                if 0 <= x < 64 and 0 <= y < 64:
                    is_wood_post = (t % 8 in (0, 1))
                    is_wattle_weave = (h % 5 == 0)
                    if is_wood_post:
                        col = PALETTE[3] if h > 3 else PALETTE[2]
                    elif is_wattle_weave:
                        col = PALETTE[2]
                    else:
                        rand = rng.random()
                        col = PALETTE[7] if rand < 0.7 else PALETTE[6]
                    pixels[x, y] = (*col, 255)
                    if x - 1 >= 0:
                        pixels[x - 1, y] = (*col, 255)
        for t in range(32):
            x = 63 - t * 2
            y = 32 + t // 2 - wall_height
            if 0 <= x < 64 and 0 <= y < 64:
                pixels[x, y] = (*PALETTE[10], 255)
                if 0 <= y - 1 < 64:
                    pixels[x, y - 1] = (*PALETTE[11], 255)
                if x - 1 >= 0:
                    pixels[x - 1, y] = (*PALETTE[10], 255)

    elif variant == 2:  # South Corner
        for h in range(wall_height):
            for t in range(16):
                x = 32 - t * 2
                y = 48 - t - h
                if 0 <= x < 64 and 0 <= y < 64:
                    col = PALETTE[7] if rng.random() < 0.6 else PALETTE[6]
                    pixels[x, y] = (*col, 255)
                    if x + 1 < 64:
                        pixels[x + 1, y] = (*col, 255)
            for t in range(16):
                x = 32 + t * 2
                y = 48 - t - h
                if 0 <= x < 64 and 0 <= y < 64:
                    col = PALETTE[8] if rng.random() < 0.7 else PALETTE[9]
                    pixels[x, y] = (*col, 255)
                    if x + 1 < 64:
                        pixels[x + 1, y] = (*col, 255)
            pixels[32, 48 - h] = (*PALETTE[5], 255)
            pixels[33, 48 - h] = (*PALETTE[3], 255)

        for cx in range(24, 41):
            cy = 48 - wall_height - abs(cx - 32) // 2
            if 0 <= cx < 64 and 0 <= cy < 64:
                pixels[cx, cy] = (*PALETTE[11], 255)
                if cy + 1 < 64:
                    pixels[cx, cy + 1] = (*PALETTE[10], 255)

    elif variant == 3:  # Pillar / Post
        for h in range(wall_height + 4):
            y = 52 - h
            for px in range(26, 38):
                if 0 <= px < 64 and 0 <= y < 64:
                    if px in (26, 37) or h % 6 == 0:
                        col = PALETTE[3]
                    elif px < 32:
                        col = PALETTE[5]
                    else:
                        col = PALETTE[4]
                    pixels[px, y] = (*col, 255)
        pixels[31, 32] = (*PALETTE[15], 255)
        pixels[32, 32] = (*PALETTE[9], 255)

    return add_external_outline_1px(cell)


def generate_vegetation_tile(variant: int) -> Image.Image:
    """Generate an isometric vegetation prop in a 64x64 cell with foot anchor at (32, 60)."""
    cell = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    pixels = cell.load()
    rng = random.Random(variant + 400)

    if variant == 0:  # Mandacaru
        for y in range(16, 59):
            for x in range(29, 35):
                if x <= 30:
                    col = PALETTE[13]
                elif x in (31, 32):
                    col = PALETTE[12]
                else:
                    col = PALETTE[2]
                if y % 3 == 0 and x in (29, 34):
                    col = PALETTE[9]
                pixels[x, y] = (*col, 255)

        for x in range(22, 29):
            pixels[x, 36] = (*PALETTE[13], 255)
            pixels[x, 37] = (*PALETTE[12], 255)
        for y in range(24, 37):
            for x in range(21, 25):
                col = PALETTE[13] if x <= 22 else PALETTE[12]
                if y % 3 == 0 and x == 21:
                    col = PALETTE[9]
                pixels[x, y] = (*col, 255)

        for x in range(35, 42):
            pixels[x, 42] = (*PALETTE[12], 255)
            pixels[x, 43] = (*PALETTE[2], 255)
        for y in range(28, 43):
            for x in range(39, 43):
                col = PALETTE[12] if x <= 40 else PALETTE[2]
                if y % 3 == 0 and x == 42:
                    col = PALETTE[9]
                pixels[x, y] = (*col, 255)

        for bx in range(26, 38):
            by = 59 + (bx % 2)
            if by <= 60:
                pixels[bx, by] = (*PALETTE[7], 255)

    elif variant == 1:  # Xique-xique
        stems = [
            (32, 45, 6, 14),
            (25, 48, 5, 11),
            (39, 49, 5, 10),
            (21, 52, 4, 8),
            (44, 53, 4, 7),
            (32, 38, 4, 9),
        ]
        for cx, cy, radius_x, height in stems:
            for dy in range(height):
                y = cy - dy
                if y < 0 or y >= 64:
                    continue
                w = int(radius_x * math.cos((dy / height - 0.5) * math.pi * 0.8))
                for x in range(cx - w, cx + w + 1):
                    if 0 <= x < 64:
                        col = (PALETTE[13] if rng.random() > 0.3 else PALETTE[9]) if x < cx else (PALETTE[12] if rng.random() > 0.4 else PALETTE[2])
                        if rng.random() < 0.15:
                            col = PALETTE[9]
                        pixels[x, y] = (*col, 255)

    elif variant == 2:  # Arbusto seco
        branches = [
            [(32, 59), (32, 50), (30, 44), (25, 38), (19, 32), (15, 28)],
            [(30, 44), (34, 38), (38, 30), (45, 24), (50, 22)],
            [(34, 38), (31, 32), (28, 25), (27, 20)],
            [(25, 38), (24, 30), (22, 24)],
            [(38, 30), (39, 23), (41, 18)],
        ]
        for branch in branches:
            for i in range(len(branch) - 1):
                p1, p2 = branch[i], branch[i + 1]
                steps = max(abs(p2[0] - p1[0]), abs(p2[1] - p1[1])) * 2
                for s in range(steps + 1):
                    t = s / steps
                    bx = int(round(p1[0] + t * (p2[0] - p1[0])))
                    by = int(round(p1[1] + t * (p2[1] - p1[1])))
                    if 0 <= bx < 64 and 0 <= by < 64:
                        col = PALETTE[3] if bx > 30 else PALETTE[5]
                        pixels[bx, by] = (*col, 255)
                        if rng.random() < 0.3 and by > 30:
                            pixels[bx + 1, by] = (*PALETTE[2], 255)
        for tx, ty in [(15, 28), (50, 22), (27, 20), (41, 18), (22, 24)]:
            if 0 <= tx < 64 and 0 <= ty < 64:
                pixels[tx, ty] = (*PALETTE[8], 255)

    elif variant == 3:  # Cacto jovem com flor
        for y in range(32, 59):
            w = int(7 * math.sin((y - 32) / 27 * math.pi))
            for x in range(32 - w, 32 + w + 1):
                if 0 <= x < 64:
                    col = PALETTE[13] if x < 32 else PALETTE[12]
                    if (x + y) % 4 == 0:
                        col = PALETTE[9]
                    pixels[x, y] = (*col, 255)
        for fy in range(28, 32):
            for fx in range(30, 35):
                if 0 <= fx < 64 and 0 <= fy < 64:
                    col = PALETTE[11] if fy == 28 else PALETTE[10]
                    pixels[fx, fy] = (*col, 255)
        pixels[32, 29] = (*PALETTE[9], 255)

    return add_external_outline_1px(cell)


def assemble_tileset_strip(tiles: list[Image.Image], horizontal: bool = True) -> Image.Image:
    """Combine a list of tile images into a clean strip."""
    if not tiles:
        raise ValueError("Tile list cannot be empty.")
    w, h = tiles[0].size
    if horizontal:
        strip = Image.new("RGBA", (w * len(tiles), h), (0, 0, 0, 0))
        for i, t in enumerate(tiles):
            strip.alpha_composite(t, (i * w, 0))
    else:
        strip = Image.new("RGBA", (w, h * len(tiles)), (0, 0, 0, 0))
        for i, t in enumerate(tiles):
            strip.alpha_composite(t, (0, i * h))
    return strip


def validate_palette_strict(image: Image.Image, name: str) -> dict[str, object]:
    """Validate that every single pixel in the image belongs strictly to paleta_sertao_16."""
    allowed_colors = {(*c, 255) for c in PALETTE}
    allowed_colors.add((0, 0, 0, 0))

    used = set(image.convert("RGBA").get_flattened_data())
    invalid = used - allowed_colors

    if invalid:
        raise RuntimeError(f"{name} contains {len(invalid)} invalid colors not in paleta_sertao_16: {invalid}")

    black_color = (*PALETTE[0], 255)
    width, height = image.size
    pixels = image.load()

    non_outline_black = 0
    for y in range(height):
        for x in range(width):
            if pixels[x, y] == black_color:
                has_transparent_neighbor = False
                for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1), (-1, -1), (1, -1), (-1, 1), (1, 1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < width and 0 <= ny < height:
                        if pixels[nx, ny][3] == 0:
                            has_transparent_neighbor = True
                            break
                    else:
                        has_transparent_neighbor = True
                        break
                if not has_transparent_neighbor:
                    non_outline_black += 1

    return {
        "name": name,
        "size": [image.width, image.height],
        "unique_colors": len(used),
        "pure_black_pixels": sum(1 for p in image.convert("RGBA").get_flattened_data() if p == black_color),
        "non_outline_black_pixels": non_outline_black,
        "is_valid": True,
    }


def build_all_tilesets(output_dir: Path, qa_dir: Path) -> dict[str, object]:
    """Generate all tilesets and QA zoom previews deterministically."""
    output_dir.mkdir(parents=True, exist_ok=True)
    qa_dir.mkdir(parents=True, exist_ok=True)

    report: dict[str, object] = {}

    # 1. Terra Rachada da Caatinga (4 variations: 256x32 strip)
    cracked_tiles = [generate_cracked_earth_tile(i) for i in range(4)]
    tileset_cracked = assemble_tileset_strip(cracked_tiles, horizontal=True)
    path_cracked = output_dir / "tileset_caatinga_terra_rachada.png"
    tileset_cracked.save(path_cracked, optimize=True)
    report["caatinga_terra_rachada"] = validate_palette_strict(tileset_cracked, "tileset_caatinga_terra_rachada")

    # 2. Caminho Batido (4 variations: 256x32 strip)
    path_tiles = [generate_beaten_path_tile(i) for i in range(4)]
    tileset_path = assemble_tileset_strip(path_tiles, horizontal=True)
    path_path = output_dir / "tileset_caminho_batido.png"
    tileset_path.save(path_path, optimize=True)
    report["caminho_batido"] = validate_palette_strict(tileset_path, "tileset_caminho_batido")

    # 3. Lajotas de Pedra da Masmorra (4 variations: 256x32 strip)
    dungeon_tiles = [generate_dungeon_stone_tile(i) for i in range(4)]
    tileset_dungeon = assemble_tileset_strip(dungeon_tiles, horizontal=True)
    path_dungeon = output_dir / "tileset_masmorra_pedra.png"
    tileset_dungeon.save(path_dungeon, optimize=True)
    report["masmorra_pedra"] = validate_palette_strict(tileset_dungeon, "tileset_masmorra_pedra")

    # 4. Paredes de Taipa (4 variations: 256x64 strip)
    taipa_tiles = [generate_taipa_wall_tile(i) for i in range(4)]
    tileset_taipa = assemble_tileset_strip(taipa_tiles, horizontal=True)
    path_taipa = output_dir / "tileset_paredes_taipa.png"
    tileset_taipa.save(path_taipa, optimize=True)
    report["paredes_taipa"] = validate_palette_strict(tileset_taipa, "tileset_paredes_taipa")

    # 5. Vegetação da Caatinga (4 variations: 256x64 strip)
    veg_tiles = [generate_vegetation_tile(i) for i in range(4)]
    tileset_veg = assemble_tileset_strip(veg_tiles, horizontal=True)
    path_veg = output_dir / "tileset_vegetacao_caatinga.png"
    tileset_veg.save(path_veg, optimize=True)
    report["vegetacao_caatinga"] = validate_palette_strict(tileset_veg, "tileset_vegetacao_caatinga")

    # 6. Master Tileset Atlas (256x224 containing all sheets)
    master_atlas = Image.new("RGBA", (256, 224), (0, 0, 0, 0))
    master_atlas.alpha_composite(tileset_cracked, (0, 0))
    master_atlas.alpha_composite(tileset_path, (0, 32))
    master_atlas.alpha_composite(tileset_dungeon, (0, 64))
    master_atlas.alpha_composite(tileset_taipa, (0, 96))
    master_atlas.alpha_composite(tileset_veg, (0, 160))
    path_master = output_dir / "tileset_master_sertao_64x32.png"
    master_atlas.save(path_master, optimize=True)
    report["master_tileset"] = validate_palette_strict(master_atlas, "tileset_master_sertao_64x32")

    # 7. QA Previews (Zoom 4x)
    master_atlas.resize((master_atlas.width * 4, master_atlas.height * 4), Image.Resampling.NEAREST).save(
        qa_dir / "tilesets_master_zoom4.png", optimize=True
    )

    # Isometric Sample Scene Assembly for QA
    scene_w, scene_h = 384, 256
    sample_scene = Image.new("RGBA", (scene_w, scene_h), (*PALETTE[1], 255))

    for grid_y in range(8):
        for grid_x in range(8):
            iso_screen_x = 160 + (grid_x - grid_y) * 32
            iso_screen_y = 30 + (grid_x + grid_y) * 16

            if grid_x in (3, 4):
                tile = path_tiles[(grid_x + grid_y) % 4]
            elif grid_x >= 6 and grid_y <= 2:
                tile = dungeon_tiles[(grid_x + grid_y) % 4]
            else:
                tile = cracked_tiles[(grid_x * 3 + grid_y) % 4]

            sample_scene.alpha_composite(tile, (iso_screen_x, iso_screen_y))

    props = [
        (1, 1, veg_tiles[0], -32),
        (2, 6, veg_tiles[1], -32),
        (5, 5, veg_tiles[2], -32),
        (0, 4, taipa_tiles[0], -32),
        (0, 5, taipa_tiles[0], -32),
        (5, 1, taipa_tiles[2], -32),
        (6, 1, taipa_tiles[1], -32),
    ]
    props.sort(key=lambda item: item[0] + item[1])
    for gx, gy, prop_img, y_off in props:
        px = 160 + (gx - gy) * 32
        py = 30 + (gx + gy) * 16 + y_off
        sample_scene.alpha_composite(prop_img, (px, py))

    sample_scene.save(qa_dir / "cena_isometrika_tilesets_preview.png", optimize=True)
    sample_scene.resize((scene_w * 3, scene_h * 3), Image.Resampling.NEAREST).save(
        qa_dir / "cena_isometrika_tilesets_preview_zoom3.png", optimize=True
    )

    return report


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate Masmorras, Monstros e Mandingas tilesets.")
    parser.add_argument("--output-dir", type=Path, default=Path("assets/art/tilesets"))
    parser.add_argument("--qa-dir", type=Path, default=Path("assets/art/qa"))
    args = parser.parse_args()

    report = build_all_tilesets(args.output_dir, args.qa_dir)
    print("TILESETS_BUILD_OK")
    print(json.dumps(report, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
