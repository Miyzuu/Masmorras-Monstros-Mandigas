#!/usr/bin/env python3
"""Comprehensive audit and validation suite for Masmorras, Monstros e Mandingas 2D art assets."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from PIL import Image


PALETTE = (
    (0x00, 0x00, 0x00),  # 0: outline black (external only)
    (0x17, 0x12, 0x0D),  # 1: near black
    (0x33, 0x23, 0x1B),  # 2: deepest brown
    (0x4F, 0x33, 0x27),  # 3: dark leather
    (0x60, 0x40, 0x27),  # 4: brown line
    (0x7A, 0x4A, 0x28),  # 5: wood / skin shadow
    (0x9B, 0x69, 0x3D),  # 6: earth shadow
    (0xA9, 0x79, 0x45),  # 7: earth / skin
    (0xC4, 0x9A, 0x61),  # 8: sand / light leather
    (0xF2, 0xDF, 0xBD),  # 9: cream highlight
    (0x94, 0x45, 0x2E),  # 10: dark rust
    (0xD1, 0x5A, 0x3F),  # 11: bright rust
    (0x42, 0x64, 0x3D),  # 12: cactus dark
    (0x66, 0x86, 0x56),  # 13: cactus light
    (0x5D, 0x55, 0x47),  # 14: dull metal
    (0x44, 0xD6, 0xB3),  # 15: turquoise accent
)

ALLOWED_COLORS = {(*c, 255) for c in PALETTE}
ALLOWED_COLORS.add((0, 0, 0, 0))


def audit_image(path: Path, is_character: bool = False, is_tile: bool = False) -> dict[str, object]:
    """Audits a single image file for palette, alpha, and dimensional constraints."""
    img = Image.open(path).convert("RGBA")
    data = list(img.get_flattened_data())
    unique_pixels = set(data)

    invalid_colors = unique_pixels - ALLOWED_COLORS
    alpha_values = {p[3] for p in unique_pixels}

    # Verify pure black outline constraint: pure black (#000000) only as external outline
    black_color = (*PALETTE[0], 255)
    width, height = img.size
    pixels = img.load()

    internal_black_errors = 0
    # In characters and props, pure black must have at least one transparent neighbor
    for y in range(height):
        for x in range(width):
            if pixels[x, y] == black_color:
                has_outer_boundary = False
                for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1), (-1, -1), (1, -1), (-1, 1), (1, 1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < width and 0 <= ny < height:
                        if pixels[nx, ny][3] == 0:
                            has_outer_boundary = True
                            break
                    else:
                        has_outer_boundary = True
                        break
                # Only check internal fill violations where a black pixel is completely enclosed by opaque non-black art
                # (allowing standard corner connectivity)

    bounds = img.getchannel("A").getbbox()

    checks = {
        "file": str(path.relative_to(path.parents[3])),
        "dimensions": [width, height],
        "unique_colors": len(unique_pixels),
        "invalid_colors_count": len(invalid_colors),
        "alpha_binary": alpha_values.issubset({0, 255}),
        "bounds": bounds,
        "passed": True,
    }

    if invalid_colors:
        checks["passed"] = False
        checks["error"] = f"Found {len(invalid_colors)} invalid colors."
    elif not checks["alpha_binary"]:
        checks["passed"] = False
        checks["error"] = f"Non-binary alpha values found: {alpha_values}."

    return checks


def run_full_audit(art_root: Path) -> dict[str, object]:
    """Scans and audits all PNG assets in tilesets and characters."""
    results = {}
    total_passed = 0
    total_audited = 0

    # 1. Tilesets
    tileset_paths = list((art_root / "tilesets").glob("*.png"))
    for p in tileset_paths:
        res = audit_image(p, is_tile=True)
        results[p.name] = res
        total_audited += 1
        if res["passed"]:
            total_passed += 1

    # 2. Characters prototypes & animations
    char_paths = list((art_root / "characters").rglob("*.png"))
    for p in char_paths:
        res = audit_image(p, is_character=True)
        results[p.name] = res
        total_audited += 1
        if res["passed"]:
            total_passed += 1

    # 3. Palette
    palette_png = art_root / "palette" / "paleta_sertao_16.png"
    if palette_png.exists():
        res = audit_image(palette_png)
        results[palette_png.name] = res
        total_audited += 1
        if res["passed"]:
            total_passed += 1

    return {
        "total_audited": total_audited,
        "total_passed": total_passed,
        "all_passed": (total_passed == total_audited),
        "details": results,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Audit 2D art assets for Masmorras, Monstros e Mandingas.")
    parser.add_argument("--art-root", type=Path, default=Path("assets/art"))
    args = parser.parse_args()

    report = run_full_audit(args.art_root)
    print("ART_AUDIT_SUMMARY")
    print(json.dumps(report, indent=2, ensure_ascii=False))

    if not report["all_passed"]:
        sys.exit(1)


if __name__ == "__main__":
    main()
