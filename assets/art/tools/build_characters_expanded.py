#!/usr/bin/env python3
"""Build reproducible Cangaceiro (Peixeira) and Cabra-Cabriola boss sprites and animations."""

from __future__ import annotations

import argparse
import json
import math
from pathlib import Path
from PIL import Image, ImageChops, ImageDraw, ImageFilter


PALETTE = (
    (0x00, 0x00, 0x00),  # 0: outline black
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

CELL_SIZE = 64
FOOT_ANCHOR = (32, 60)


def without_external_outline(cell: Image.Image) -> Image.Image:
    """Strip pure black (#000000) pixels from the image."""
    content = Image.new("RGBA", cell.size, (0, 0, 0, 0))
    source_pixels = cell.convert("RGBA").load()
    target_pixels = content.load()
    for y in range(cell.height):
        for x in range(cell.width):
            pixel = source_pixels[x, y]
            if pixel[3] > 0 and pixel[:3] != PALETTE[0]:
                target_pixels[x, y] = (*pixel[:3], 255)
    return content


def add_external_outline(content: Image.Image) -> Image.Image:
    """Add 1px pure black outline strictly around the opaque pixels."""
    mask = content.getchannel("A").point(lambda item: 255 if item > 0 else 0)
    dilated = mask.filter(ImageFilter.MaxFilter(3))
    outline_mask = ImageChops.subtract(dilated, mask)
    outline = Image.new("RGBA", content.size, (0, 0, 0, 0))
    outline_pixels = outline.load()
    om_pixels = outline_mask.load()
    for y in range(content.height):
        for x in range(content.width):
            if om_pixels[x, y] > 0:
                outline_pixels[x, y] = (*PALETTE[0], 255)
    result = Image.new("RGBA", content.size, (0, 0, 0, 0))
    result.alpha_composite(outline)
    result.alpha_composite(content)
    return result


def align_to_foot_anchor(image: Image.Image) -> Image.Image:
    """Vertically aligns image so that the lowest opaque pixel reaches FOOT_ANCHOR[1] (y=60)."""
    bounds = image.getchannel("A").getbbox()
    if bounds is None:
        return image
    current_bottom = bounds[3] - 1
    diff = FOOT_ANCHOR[1] - current_bottom
    if diff == 0:
        return image
    aligned = Image.new("RGBA", image.size, (0, 0, 0, 0))
    aligned.paste(image, (0, diff), image)
    return aligned


def build_cangaceiro_peixeira_base(source_cangaceiro: Image.Image) -> Image.Image:
    """
    Transforms the existing approved Cangaceiro base cell (holding rifle)
    into the Peixeira-wielding Cangaceiro variant.
    Preserves exact facial features, skin tones, hat, chest harness, and legs,
    modifying the forward arm to brandish the Peixeira dagger.
    """
    raw = without_external_outline(source_cangaceiro)
    canvas = raw.copy()
    pixels = canvas.load()

    # 1. Erase the long rifle barrel pointing down-right (x: 38..54, y: 32..53)
    for y in range(32, 54):
        for x in range(38, 55):
            pixels[x, y] = (0, 0, 0, 0)

    # Restore torso / right hip that was under the rifle
    for y in range(35, 44):
        for x in range(34, 39):
            if x <= 36:
                pixels[x, y] = (*PALETTE[3], 255)  # Leather vest
            else:
                pixels[x, y] = (*PALETTE[7], 255)  # Shirt / belt
    # Leather cartridge cross strap
    pixels[34, 36] = (*PALETTE[8], 255)
    pixels[35, 37] = (*PALETTE[8], 255)
    pixels[36, 38] = (*PALETTE[8], 255)

    # 2. Draw forward right arm flexed ready with dagger
    # Shoulder & Upper Arm (x: 35..38, y: 28..33)
    for y in range(28, 34):
        for x in range(35, 39):
            pixels[x, y] = (*PALETTE[8], 255)  # Cloth sleeve (sand)
    pixels[38, 30] = (*PALETTE[6], 255)       # Sleeve fold shadow
    pixels[38, 31] = (*PALETTE[6], 255)

    # Forearm / Wrist (x: 39..42, y: 33..36)
    for y in range(33, 37):
        for x in range(39, 43):
            pixels[x, y] = (*PALETTE[7], 255)  # Forearm skin
    pixels[42, 34] = (*PALETTE[5], 255)       # Skin shadow

    # Hand gripping hilt (x: 42..45, y: 34..37)
    for y in range(34, 38):
        for x in range(42, 46):
            pixels[x, y] = (*PALETTE[7], 255)  # Knuckles
    pixels[44, 35] = (*PALETTE[9], 255)       # Skin highlight
    pixels[45, 36] = (*PALETTE[5], 255)

    # Dagger Hilt & Guard (Cabo e Guarda de Latão/Madeira)
    pixels[43, 37] = (*PALETTE[5], 255)  # Dark wood hilt
    pixels[44, 38] = (*PALETTE[3], 255)
    pixels[44, 39] = (*PALETTE[8], 255)  # Pommel
    pixels[42, 33] = (*PALETTE[10], 255) # Dark rust/brass guard
    pixels[43, 33] = (*PALETTE[11], 255)
    pixels[44, 33] = (*PALETTE[10], 255)

    # Peixeira Blade (Lâmina afiada curva para Sudeste)
    blade_points = [
        (44, 32, False), (45, 31, False), (46, 29, False), (47, 27, False),
        (48, 25, False), (49, 24, False), (50, 23, False), (51, 22, True),
        (45, 32, True), (46, 30, True), (47, 28, True), (48, 26, True),
        (49, 25, True), (50, 24, True),
    ]
    for bx, by, is_edge in blade_points:
        if is_edge:
            pixels[bx, by] = (*PALETTE[9], 255)   # Cream gleam on razor edge
        else:
            pixels[bx, by] = (*PALETTE[14], 255)  # Dull metal blade body
    pixels[44, 31] = (*PALETTE[3], 255)
    pixels[45, 30] = (*PALETTE[3], 255)
    pixels[46, 28] = (*PALETTE[3], 255)
    pixels[47, 26] = (*PALETTE[3], 255)
    pixels[48, 24] = (*PALETTE[3], 255)

    # 3. Off-hand (Left hand on hip)
    for y in range(32, 37):
        for x in range(22, 26):
            pixels[x, y] = (*PALETTE[7], 255)
    pixels[24, 34] = (*PALETTE[9], 255)
    pixels[22, 35] = (*PALETTE[5], 255)

    outlined = add_external_outline(canvas)
    return align_to_foot_anchor(outlined)


def build_cabra_cabriola_base() -> Image.Image:
    """
    Builds the mythical Boss Cabra-Cabriola in 64x64 cell.
    A terrifying demonic chimera goat monster with massive twisted horns,
    furious glowing turquoise eyes, sharp snarling teeth, muscular beast torso,
    dark demonic fur, and sharp cloven hooves anchored at (32, 60).
    """
    canvas = Image.new("RGBA", (CELL_SIZE, CELL_SIZE), (0, 0, 0, 0))
    pixels = canvas.load()

    # 1. Back legs & Hocks (Pernas traseiras e jarretes musculosos)
    for y in range(44, 60):
        for x in range(19, 26):
            if x <= 22:
                pixels[x, y] = (*PALETTE[1], 255)
            else:
                pixels[x, y] = (*PALETTE[2], 255)
    pixels[20, 58] = (*PALETTE[14], 255)
    pixels[21, 58] = (*PALETTE[14], 255)
    pixels[20, 59] = (*PALETTE[3], 255)
    pixels[21, 59] = (*PALETTE[3], 255)

    for y in range(43, 60):
        for x in range(37, 44):
            if x >= 41:
                pixels[x, y] = (*PALETTE[1], 255)
            else:
                pixels[x, y] = (*PALETTE[2], 255)
    pixels[40, 58] = (*PALETTE[14], 255)
    pixels[41, 58] = (*PALETTE[14], 255)
    pixels[40, 59] = (*PALETTE[3], 255)
    pixels[41, 59] = (*PALETTE[3], 255)

    # 2. Forelegs (Pernas dianteiras fortes plantadas para combate)
    for y in range(42, 60):
        for x in range(25, 31):
            if x <= 27:
                pixels[x, y] = (*PALETTE[2], 255)
            else:
                pixels[x, y] = (*PALETTE[3], 255)
    pixels[27, 58] = (*PALETTE[14], 255)
    pixels[28, 58] = (*PALETTE[9], 255)
    pixels[27, 59] = (*PALETTE[3], 255)
    pixels[28, 59] = (*PALETTE[3], 255)

    for y in range(41, 60):
        for x in range(32, 38):
            if x <= 34:
                pixels[x, y] = (*PALETTE[3], 255)
            else:
                pixels[x, y] = (*PALETTE[2], 255)
    pixels[34, 58] = (*PALETTE[14], 255)
    pixels[35, 58] = (*PALETTE[9], 255)
    pixels[34, 59] = (*PALETTE[3], 255)
    pixels[35, 59] = (*PALETTE[3], 255)

    # 3. Monstrous Beast Body / Hunched Torso
    for y in range(28, 48):
        for x in range(20, 46):
            dx = (x - 32) / 12.0
            dy = (y - 38) / 9.0
            if dx * dx + dy * dy <= 1.0:
                if x < 30 and y < 38:
                    col = PALETTE[6]
                elif x < 35:
                    col = PALETTE[3]
                elif x < 40:
                    col = PALETTE[2]
                else:
                    col = PALETTE[1]
                pixels[x, y] = (*col, 255)
    for fy in (26, 27, 28):
        pixels[28, fy] = (*PALETTE[6], 255)
        pixels[29, fy] = (*PALETTE[3], 255)
        pixels[33, fy] = (*PALETTE[2], 255)

    # 4. Demonic Goat Head & Snarl
    for y in range(20, 34):
        for x in range(26, 40):
            dx = (x - 33) / 6.5
            dy = (y - 27) / 6.0
            if dx * dx + dy * dy <= 1.0:
                if x <= 31:
                    col = PALETTE[3]
                elif x <= 35:
                    col = PALETTE[2]
                else:
                    col = PALETTE[1]
                pixels[x, y] = (*col, 255)

    for y in range(27, 34):
        for x in range(33, 42):
            if (x - 33) + (y - 27) <= 10:
                pixels[x, y] = (*PALETTE[2], 255)
    # Snarling Mouth & Razor Teeth
    pixels[37, 31] = (*PALETTE[10], 255)
    pixels[38, 31] = (*PALETTE[11], 255)
    pixels[39, 31] = (*PALETTE[10], 255)
    pixels[37, 30] = (*PALETTE[9], 255)
    pixels[39, 30] = (*PALETTE[9], 255)
    pixels[38, 32] = (*PALETTE[9], 255)

    # Beard
    for by in range(33, 39):
        pixels[35, by] = (*PALETTE[1], 255)
        pixels[36, by] = (*PALETTE[2], 255)

    # 5. Glowing Supernatural Turquoise Eyes & Runes
    pixels[30, 24] = (*PALETTE[15], 255)
    pixels[31, 24] = (*PALETTE[15], 255)
    pixels[31, 23] = (*PALETTE[9], 255)
    pixels[36, 25] = (*PALETTE[15], 255)
    pixels[37, 25] = (*PALETTE[15], 255)
    pixels[37, 24] = (*PALETTE[9], 255)

    # 6. Massive Twisted Horns
    left_horn = [
        (27, 20), (26, 18), (24, 16), (22, 14), (20, 12), (18, 11), (16, 10), (14, 11)
    ]
    for i, (hx, hy) in enumerate(left_horn):
        pixels[hx, hy] = (*PALETTE[14], 255)
        pixels[hx + 1, hy] = (*PALETTE[3], 255)
        if i in (1, 3, 5):
            pixels[hx, hy - 1] = (*PALETTE[9], 255)

    right_horn = [
        (35, 19), (37, 17), (39, 15), (41, 13), (43, 11), (45, 10), (47, 10), (49, 12)
    ]
    for i, (hx, hy) in enumerate(right_horn):
        pixels[hx, hy] = (*PALETTE[14], 255)
        pixels[hx, hy + 1] = (*PALETTE[2], 255)
        if i in (1, 3, 5):
            pixels[hx, hy - 1] = (*PALETTE[9], 255)

    outlined = add_external_outline(canvas)
    return align_to_foot_anchor(outlined)


def build_cangaceiro_peixeira_idle_walk_atlas(base_cangaceiro_peixeira: Image.Image) -> Image.Image:
    """Builds the full 10-column Southeast animation row for the Cangaceiro with Peixeira."""
    raw_base = without_external_outline(base_cangaceiro_peixeira)
    atlas_row = Image.new("RGBA", (CELL_SIZE * 10, CELL_SIZE), (0, 0, 0, 0))

    idle_body_offsets = ((0, 0), (0, -1), (1, 0), (-1, 0))
    for col, b_off in enumerate(idle_body_offsets):
        f = Image.new("RGBA", (CELL_SIZE, CELL_SIZE), (0, 0, 0, 0))
        f.alpha_composite(raw_base.crop((0, 43, CELL_SIZE, CELL_SIZE)), (0, 43))
        f.alpha_composite(raw_base.crop((0, 0, CELL_SIZE, 45)), b_off)
        if col in (1, 2):
            px = f.load()
            if 0 <= 51 + b_off[0] < CELL_SIZE and 0 <= 22 + b_off[1] < CELL_SIZE:
                px[51 + b_off[0], 22 + b_off[1]] = (*PALETTE[9], 255)
        outlined = add_external_outline(f)
        aligned = align_to_foot_anchor(outlined)
        atlas_row.alpha_composite(aligned, (col * CELL_SIZE, 0))

    walk_leg_cycle = (
        ((2, 0), (-2, -1)),
        ((1, 0), (-1, -3)),
        ((0, 0), (0, -2)),
        ((-2, -1), (2, 0)),
        ((-1, -3), (1, 0)),
        ((0, -2), (0, 0)),
    )
    walk_body_offsets = ((0, -1), (-1, 0), (-1, -1), (0, -1), (1, 0), (1, -1))
    knife_offsets = ((0, 0), (1, -1), (0, 0), (0, 0), (-1, 1), (0, 0))

    knife_box = (38, 20, 56, 40)
    knife_piece = raw_base.crop(knife_box)

    torso_without_knife = raw_base.copy()
    twk_px = torso_without_knife.load()
    for y in range(knife_box[1], knife_box[3]):
        for x in range(knife_box[0], knife_box[2]):
            twk_px[x, y] = (0, 0, 0, 0)

    for idx, (b_off, (l_off, r_off), k_off) in enumerate(zip(walk_body_offsets, walk_leg_cycle, knife_offsets)):
        col = 4 + idx
        f = Image.new("RGBA", (CELL_SIZE, CELL_SIZE), (0, 0, 0, 0))
        f.alpha_composite(
            raw_base.crop((0, 43, 33, CELL_SIZE)),
            (l_off[0], 43 + l_off[1]),
        )
        f.alpha_composite(
            raw_base.crop((31, 43, CELL_SIZE, CELL_SIZE)),
            (31 + r_off[0], 43 + r_off[1]),
        )
        f.alpha_composite(torso_without_knife.crop((0, 0, CELL_SIZE, 48)), b_off)
        k_dest = (knife_box[0] + b_off[0] + k_off[0], knife_box[1] + b_off[1] + k_off[1])
        f.alpha_composite(knife_piece, k_dest)

        outlined = add_external_outline(f)
        aligned = align_to_foot_anchor(outlined)
        atlas_row.alpha_composite(aligned, (col * CELL_SIZE, 0))

    return atlas_row


def build_cabra_cabriola_idle_attack_atlas(base_cabra: Image.Image) -> Image.Image:
    """Builds the full 10-column Southeast animation row for the Boss Cabra-Cabriola."""
    raw_base = without_external_outline(base_cabra)
    atlas_row = Image.new("RGBA", (CELL_SIZE * 10, CELL_SIZE), (0, 0, 0, 0))

    idle_body_shifts = ((0, 0), (0, -1), (1, 0), (-1, 0))
    for col, shift in enumerate(idle_body_shifts):
        f = Image.new("RGBA", (CELL_SIZE, CELL_SIZE), (0, 0, 0, 0))
        f.alpha_composite(raw_base.crop((0, 45, CELL_SIZE, CELL_SIZE)), (0, 45))
        f.alpha_composite(raw_base.crop((0, 0, CELL_SIZE, 48)), shift)
        px = f.load()
        if col in (1, 2):
            for ex, ey in [(30 + shift[0], 23 + shift[1]), (37 + shift[0], 24 + shift[1])]:
                if 0 <= ex < CELL_SIZE and 0 <= ey < CELL_SIZE:
                    px[ex, ey] = (*PALETTE[9], 255)

        outlined = add_external_outline(f)
        aligned = align_to_foot_anchor(outlined)
        atlas_row.alpha_composite(aligned, (col * CELL_SIZE, 0))

    attack_shifts = [
        ((0, 1), 2, False),
        ((2, 2), 4, True),
        ((3, -1), 0, True),
        ((1, 0), 0, False),
    ]
    for idx, (b_off, h_thrust, maw_open) in enumerate(attack_shifts):
        col = 4 + idx
        f = Image.new("RGBA", (CELL_SIZE, CELL_SIZE), (0, 0, 0, 0))
        f.alpha_composite(raw_base, b_off)
        if maw_open:
            px = f.load()
            for mx in range(36, 42):
                for my in range(29, 34):
                    bx, by = mx + b_off[0], my + b_off[1]
                    if 0 <= bx < CELL_SIZE and 0 <= by < CELL_SIZE:
                        px[bx, by] = (*PALETTE[11], 255)
            for hx, hy in [(14 + b_off[0], 11 + b_off[1]), (49 + b_off[0], 12 + b_off[1])]:
                if 0 <= hx < CELL_SIZE and 0 <= hy < CELL_SIZE:
                    px[hx, hy] = (*PALETTE[15], 255)

        outlined = add_external_outline(f)
        aligned = align_to_foot_anchor(outlined)
        atlas_row.alpha_composite(aligned, (col * CELL_SIZE, 0))

    for idx, shift in enumerate([(-1, -1), (0, 0)]):
        col = 8 + idx
        f = Image.new("RGBA", (CELL_SIZE, CELL_SIZE), (0, 0, 0, 0))
        f.alpha_composite(raw_base, shift)
        px = f.load()
        for rx in range(32, 40):
            for ry in range(26, 32):
                bx, by = rx + shift[0], ry + shift[1]
                if 0 <= bx < CELL_SIZE and 0 <= by < CELL_SIZE:
                    if (rx + ry) % 2 == 0:
                        px[bx, by] = (*PALETTE[15], 255)
        outlined = add_external_outline(f)
        aligned = align_to_foot_anchor(outlined)
        atlas_row.alpha_composite(aligned, (col * CELL_SIZE, 0))

    return atlas_row


def validate_character_palette_and_bounds(image: Image.Image, name: str) -> dict[str, object]:
    """Validate palette compliance, alpha binary, dimensions and foot anchor."""
    allowed_colors = {(*c, 255) for c in PALETTE}
    allowed_colors.add((0, 0, 0, 0))

    used = set(image.convert("RGBA").get_flattened_data())
    invalid = used - allowed_colors
    if invalid:
        raise RuntimeError(f"{name} contains invalid colors outside paleta_sertao_16: {invalid}")

    alpha_vals = {p[3] for p in used}
    if not alpha_vals.issubset({0, 255}):
        raise RuntimeError(f"{name} contains non-binary alpha values: {alpha_vals}")

    bounds = image.getchannel("A").getbbox()
    return {
        "name": name,
        "size": [image.width, image.height],
        "used_colors_count": len(used),
        "bounds": bounds,
        "is_valid": True,
    }


def save_animated_gif(frames: list[Image.Image], output_path: Path, duration_ms: int, scale: int = 4) -> None:
    """Save an animated preview GIF scaled up with NEAREST resampling."""
    scaled_frames = [
        f.resize((f.width * scale, f.height * scale), Image.Resampling.NEAREST)
        for f in frames
    ]
    output_path.parent.mkdir(parents=True, exist_ok=True)
    scaled_frames[0].save(
        output_path,
        save_all=True,
        append_images=scaled_frames[1:],
        duration=duration_ms,
        loop=0,
        disposal=2,
        optimize=False,
    )


def build_all_characters_expanded(
    source_prototype_path: Path,
    char_dir: Path,
    qa_dir: Path,
) -> dict[str, object]:
    """Main builder for expanded characters and boss."""
    proto_dir = char_dir / "prototypes"
    anim_dir = char_dir / "animations"
    proto_dir.mkdir(parents=True, exist_ok=True)
    anim_dir.mkdir(parents=True, exist_ok=True)
    qa_dir.mkdir(parents=True, exist_ok=True)

    report: dict[str, object] = {}

    source_proto = Image.open(source_prototype_path).convert("RGBA")
    cangaceiro_rifle_cell = source_proto.crop((0, 0, CELL_SIZE, CELL_SIZE))
    capanga_cell = source_proto.crop((CELL_SIZE, 0, CELL_SIZE * 2, CELL_SIZE))

    cangaceiro_peixeira_cell = build_cangaceiro_peixeira_base(cangaceiro_rifle_cell)
    cabra_cabriola_cell = build_cabra_cabriola_base()

    path_peixeira_proto = proto_dir / "cangaceiro_peixeira_se_48px_16c.png"
    cangaceiro_peixeira_cell.save(path_peixeira_proto, optimize=True)
    report["cangaceiro_peixeira_prototype"] = validate_character_palette_and_bounds(
        cangaceiro_peixeira_cell, "cangaceiro_peixeira_prototype"
    )

    path_cabra_proto = proto_dir / "cabra_cabriola_se_64px_16c.png"
    cabra_cabriola_cell.save(path_cabra_proto, optimize=True)
    report["cabra_cabriola_prototype"] = validate_character_palette_and_bounds(
        cabra_cabriola_cell, "cabra_cabriola_prototype"
    )

    all_chars_sheet = Image.new("RGBA", (CELL_SIZE * 4, CELL_SIZE), (0, 0, 0, 0))
    all_chars_sheet.alpha_composite(cangaceiro_rifle_cell, (0, 0))
    all_chars_sheet.alpha_composite(capanga_cell, (CELL_SIZE, 0))
    all_chars_sheet.alpha_composite(cangaceiro_peixeira_cell, (CELL_SIZE * 2, 0))
    all_chars_sheet.alpha_composite(cabra_cabriola_cell, (CELL_SIZE * 3, 0))
    path_all_chars = proto_dir / "personagens_completo_se_16c.png"
    all_chars_sheet.save(path_all_chars, optimize=True)
    report["all_characters_prototype"] = validate_character_palette_and_bounds(
        all_chars_sheet, "personagens_completo_se_16c"
    )

    peixeira_anim_row = build_cangaceiro_peixeira_idle_walk_atlas(cangaceiro_peixeira_cell)
    path_peixeira_anim = anim_dir / "cangaceiro_peixeira_se_idle4_walk6_64px_16c.png"
    peixeira_anim_row.save(path_peixeira_anim, optimize=True)
    report["cangaceiro_peixeira_animation"] = validate_character_palette_and_bounds(
        peixeira_anim_row, "cangaceiro_peixeira_animation"
    )

    cabra_anim_row = build_cabra_cabriola_idle_attack_atlas(cabra_cabriola_cell)
    path_cabra_anim = anim_dir / "cabra_cabriola_se_idle4_attack4_64px_16c.png"
    cabra_anim_row.save(path_cabra_anim, optimize=True)
    report["cabra_cabriola_animation"] = validate_character_palette_and_bounds(
        cabra_anim_row, "cabra_cabriola_animation"
    )

    existing_anim = Image.open(char_dir / "animations" / "personagens_se_idle4_walk6_64px_16c.png").convert("RGBA")
    master_anim_atlas = Image.new("RGBA", (CELL_SIZE * 10, CELL_SIZE * 4), (0, 0, 0, 0))
    master_anim_atlas.alpha_composite(existing_anim, (0, 0))
    master_anim_atlas.alpha_composite(peixeira_anim_row, (0, CELL_SIZE * 2))
    master_anim_atlas.alpha_composite(cabra_anim_row, (0, CELL_SIZE * 3))
    path_master_anim = anim_dir / "personagens_completo_se_animacoes_640x256_16c.png"
    master_anim_atlas.save(path_master_anim, optimize=True)
    report["master_animation_atlas"] = validate_character_palette_and_bounds(
        master_anim_atlas, "master_animation_atlas"
    )

    all_chars_sheet.resize((all_chars_sheet.width * 4, all_chars_sheet.height * 4), Image.Resampling.NEAREST).save(
        qa_dir / "personagens_completo_zoom4.png", optimize=True
    )

    master_anim_atlas.resize((master_anim_atlas.width * 4, master_anim_atlas.height * 4), Image.Resampling.NEAREST).save(
        qa_dir / "personagens_completo_animacoes_zoom4.png", optimize=True
    )

    peixeira_idle_frames = [
        peixeira_anim_row.crop((c * CELL_SIZE, 0, (c + 1) * CELL_SIZE, CELL_SIZE))
        for c in range(4)
    ]
    save_animated_gif(peixeira_idle_frames, qa_dir / "cangaceiro_peixeira_idle_4fps.gif", duration_ms=250, scale=4)

    peixeira_walk_frames = [
        peixeira_anim_row.crop((c * CELL_SIZE, 0, (c + 1) * CELL_SIZE, CELL_SIZE))
        for c in range(4, 10)
    ]
    save_animated_gif(peixeira_walk_frames, qa_dir / "cangaceiro_peixeira_walk_10fps.gif", duration_ms=100, scale=4)

    cabra_frames = [
        cabra_anim_row.crop((c * CELL_SIZE, 0, (c + 1) * CELL_SIZE, CELL_SIZE))
        for c in range(8)
    ]
    save_animated_gif(cabra_frames, qa_dir / "cabra_cabriola_anim_preview.gif", duration_ms=150, scale=4)

    arena_w, arena_h = 448, 320
    arena_scene = Image.new("RGBA", (arena_w, arena_h), (*PALETTE[1], 255))

    tiles_dungeon = Image.open(char_dir.parent / "tilesets" / "tileset_masmorra_pedra.png").convert("RGBA")

    d_tile0 = tiles_dungeon.crop((0, 0, 64, 32))
    d_tile1 = tiles_dungeon.crop((64, 0, 128, 32))
    d_tile3 = tiles_dungeon.crop((192, 0, 256, 32))

    for gy in range(8):
        for gx in range(8):
            sx = 192 + (gx - gy) * 32
            sy = 40 + (gx + gy) * 16
            t = d_tile3 if (gx == 4 and gy == 4) else (d_tile0 if (gx + gy) % 2 == 0 else d_tile1)
            arena_scene.alpha_composite(t, (sx, sy))

    c_pos_x = 192 + (2 - 5) * 32
    c_pos_y = 40 + (2 + 5) * 16 - 32
    arena_scene.alpha_composite(cangaceiro_peixeira_cell, (c_pos_x, c_pos_y))

    b_pos_x = 192 + (4 - 4) * 32
    b_pos_y = 40 + (4 + 4) * 16 - 32
    arena_scene.alpha_composite(cabra_cabriola_cell, (b_pos_x, b_pos_y))

    arena_scene.save(qa_dir / "cena_boss_cabra_cabriola_preview.png", optimize=True)
    arena_scene.resize((arena_w * 3, arena_h * 3), Image.Resampling.NEAREST).save(
        qa_dir / "cena_boss_cabra_cabriola_preview_zoom3.png", optimize=True
    )

    return report


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate Cangaceiro Peixeira and Cabra-Cabriola boss assets.")
    parser.add_argument(
        "--source-prototype",
        type=Path,
        default=Path("assets/art/characters/prototypes/personagens_se_48px_16c.png"),
    )
    parser.add_argument("--char-dir", type=Path, default=Path("assets/art/characters"))
    parser.add_argument("--qa-dir", type=Path, default=Path("assets/art/qa"))
    args = parser.parse_args()

    report = build_all_characters_expanded(args.source_prototype, args.char_dir, args.qa_dir)
    print("CHARACTERS_EXPANDED_BUILD_OK")
    print(json.dumps(report, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
