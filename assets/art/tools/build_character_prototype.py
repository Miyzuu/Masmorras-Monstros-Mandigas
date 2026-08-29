#!/usr/bin/env python3
"""Build an exact 64 px character scale proof from an approved concept image."""

from __future__ import annotations

import argparse
from collections import deque
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter


PALETTE = (
    (0x00, 0x00, 0x00),  # outline black
    (0x17, 0x12, 0x0D),  # near black
    (0x33, 0x23, 0x1B),  # deepest brown
    (0x4F, 0x33, 0x27),  # dark leather
    (0x60, 0x40, 0x27),  # brown line
    (0x7A, 0x4A, 0x28),  # wood / skin shadow
    (0x9B, 0x69, 0x3D),  # earth shadow
    (0xA9, 0x79, 0x45),  # earth / skin
    (0xC4, 0x9A, 0x61),  # sand / light leather
    (0xF2, 0xDF, 0xBD),  # cream highlight
    (0x94, 0x45, 0x2E),  # dark rust
    (0xD1, 0x5A, 0x3F),  # bright rust
    (0x42, 0x64, 0x3D),  # cactus dark
    (0x66, 0x86, 0x56),  # cactus light
    (0x5D, 0x55, 0x47),  # dull metal
    (0x44, 0xD6, 0xB3),  # turquoise accent
)

# Character pixels do not consume colors reserved for outlines, vegetation or
# interaction feedback. Pure black is applied only to the external silhouette.
CHARACTER_PALETTE = tuple(PALETTE[index] for index in range(1, 12)) + (PALETTE[14],)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--sprites", required=True, type=Path)
    parser.add_argument("--preview", required=True, type=Path)
    parser.add_argument("--palette", required=True, type=Path)
    parser.add_argument("--scene", type=Path)
    parser.add_argument("--scene-test", type=Path)
    return parser.parse_args()


def remove_connected_light_background(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    hsv = rgba.convert("RGB").convert("HSV")
    _, saturation, value = hsv.split()
    low_saturation = saturation.point(lambda item: 255 if item < 46 else 0)
    high_value = value.point(lambda item: 255 if item > 175 else 0)
    candidate = ImageChops.multiply(low_saturation, high_value)
    flooded = candidate.copy()
    ImageDraw.floodfill(flooded, (0, 0), 128, thresh=0)
    background = flooded.point(lambda item: 255 if item == 128 else 0)
    alpha = ImageChops.invert(background)
    alpha = alpha.point(lambda item: 255 if item else 0)
    rgba.putalpha(alpha)
    return rgba


def remove_tiny_components(image: Image.Image, minimum_area: int = 2) -> Image.Image:
    alpha = image.getchannel("A")
    width, height = image.size
    pixels = alpha.load()
    seen: set[tuple[int, int]] = set()
    keep: set[tuple[int, int]] = set()

    for y in range(height):
        for x in range(width):
            if not pixels[x, y] or (x, y) in seen:
                continue
            component: list[tuple[int, int]] = []
            queue = deque([(x, y)])
            seen.add((x, y))
            while queue:
                point = queue.popleft()
                component.append(point)
                px, py = point
                for neighbor in ((px - 1, py), (px + 1, py), (px, py - 1), (px, py + 1)):
                    nx, ny = neighbor
                    if 0 <= nx < width and 0 <= ny < height and pixels[nx, ny] and neighbor not in seen:
                        seen.add(neighbor)
                        queue.append(neighbor)
            if len(component) >= minimum_area:
                keep.update(component)

    cleaned_alpha = Image.new("L", image.size, 0)
    cleaned_pixels = cleaned_alpha.load()
    for x, y in keep:
        cleaned_pixels[x, y] = 255
    cleaned = image.copy()
    cleaned.putalpha(cleaned_alpha)
    return cleaned


def nearest_palette_color(red: int, green: int, blue: int) -> tuple[int, int, int]:
    return min(
        CHARACTER_PALETTE,
        key=lambda color: (
            2 * (red - color[0]) ** 2
            + 3 * (green - color[1]) ** 2
            + (blue - color[2]) ** 2
        ),
    )


def remap_to_palette(image: Image.Image) -> Image.Image:
    mapped = Image.new("RGBA", image.size, (0, 0, 0, 0))
    source_pixels = image.load()
    mapped_pixels = mapped.load()
    cache: dict[tuple[int, int, int], tuple[int, int, int]] = {}
    for y in range(image.height):
        for x in range(image.width):
            red, green, blue, alpha = source_pixels[x, y]
            if not alpha:
                continue
            source_color = (red, green, blue)
            target_color = cache.setdefault(source_color, nearest_palette_color(*source_color))
            mapped_pixels[x, y] = (*target_color, 255)
    return mapped


def build_cell(
    source: Image.Image,
    bounds: tuple[int, int, int, int],
    target_inner_width: int,
) -> Image.Image:
    sprite = source.crop(bounds)
    target_height = 46
    sprite = sprite.resize((target_inner_width, target_height), Image.Resampling.NEAREST)
    sprite = remove_tiny_components(sprite)
    sprite = remap_to_palette(sprite)

    cell = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    paste_x = 32 - sprite.width // 2
    paste_y = 60 - sprite.height
    cell.alpha_composite(sprite, (paste_x, paste_y))

    mask = cell.getchannel("A").point(lambda item: 255 if item else 0)
    dilated = mask.filter(ImageFilter.MaxFilter(3))
    outline_mask = ImageChops.subtract(dilated, mask)
    outline = Image.new("RGBA", cell.size, (0, 0, 0, 0))
    outline.putalpha(outline_mask)
    return Image.alpha_composite(outline, cell)


def character_bounds(source: Image.Image, x_start: int, x_end: int) -> tuple[int, int, int, int]:
    half = source.crop((x_start, 0, x_end, source.height))
    bounds = half.getchannel("A").getbbox()
    if bounds is None:
        raise RuntimeError("No character pixels found in one half of the concept image.")
    return (bounds[0] + x_start, bounds[1], bounds[2] + x_start, bounds[3])


def save_palette(path: Path) -> None:
    swatches = Image.new("RGBA", (64, 64), (0, 0, 0, 255))
    draw = ImageDraw.Draw(swatches)
    for index, color in enumerate(PALETTE):
        column = index % 4
        row = index // 4
        draw.rectangle((column * 16, row * 16, column * 16 + 15, row * 16 + 15), fill=(*color, 255))
    path.parent.mkdir(parents=True, exist_ok=True)
    swatches.save(path, optimize=True)


def save_scene_test(scene_path: Path, sprites: Image.Image, output_path: Path) -> None:
    scene = Image.open(scene_path).convert("RGBA")
    camera_zoom = 1.45
    scaled_size = round(64 * camera_zoom)
    anchor_offset = (round(32 * camera_zoom), round(60 * camera_zoom))
    screen_anchors = ((384, 256), (570, 256))

    for index, screen_anchor in enumerate(screen_anchors):
        cell = sprites.crop((index * 64, 0, index * 64 + 64, 64))
        cell = cell.resize((scaled_size, scaled_size), Image.Resampling.NEAREST)
        position = (
            screen_anchor[0] - anchor_offset[0],
            screen_anchor[1] - anchor_offset[1],
        )
        scene.alpha_composite(cell, position)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    scene.save(output_path, optimize=True)


def main() -> None:
    args = parse_args()
    if bool(args.scene) != bool(args.scene_test):
        raise ValueError("--scene and --scene-test must be provided together.")
    source = remove_connected_light_background(Image.open(args.input))
    midpoint = source.width // 2
    left = build_cell(source, character_bounds(source, 0, midpoint), target_inner_width=22)
    right = build_cell(source, character_bounds(source, midpoint, source.width), target_inner_width=24)

    sprites = Image.new("RGBA", (128, 64), (0, 0, 0, 0))
    sprites.alpha_composite(left, (0, 0))
    sprites.alpha_composite(right, (64, 0))

    args.sprites.parent.mkdir(parents=True, exist_ok=True)
    args.preview.parent.mkdir(parents=True, exist_ok=True)
    sprites.save(args.sprites, optimize=True)
    sprites.resize((1024, 512), Image.Resampling.NEAREST).save(args.preview, optimize=True)
    save_palette(args.palette)
    if args.scene and args.scene_test:
        save_scene_test(args.scene, sprites, args.scene_test)


if __name__ == "__main__":
    main()
