#!/usr/bin/env python3
"""Build reproducible 64 px character proofs and Southeast animation atlases."""

from __future__ import annotations

import argparse
import json
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

CELL_SIZE = 64
CHARACTER_INNER_HEIGHT = 46
FOOT_ANCHOR = (32, 60)
ANIMATION_COLUMNS = 10
ANIMATION_ROWS = 2
IDLE_COLUMNS = range(0, 4)
WALK_COLUMNS = range(4, 10)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path)
    parser.add_argument("--sprites", type=Path)
    parser.add_argument("--preview", type=Path)
    parser.add_argument("--palette", type=Path)
    parser.add_argument("--scene", type=Path)
    parser.add_argument("--scene-test", type=Path)
    parser.add_argument("--base-sprites", type=Path)
    parser.add_argument("--pose-reference", type=Path)
    parser.add_argument("--animation-sprites", type=Path)
    parser.add_argument("--animation-preview", type=Path)
    parser.add_argument("--idle-preview", type=Path)
    parser.add_argument("--walk-preview", type=Path)
    return parser.parse_args()


def validate_argument_groups(args: argparse.Namespace) -> tuple[bool, bool]:
    static_values = (args.input, args.sprites, args.preview, args.palette)
    animation_values = (
        args.base_sprites,
        args.pose_reference,
        args.animation_sprites,
        args.animation_preview,
        args.idle_preview,
        args.walk_preview,
    )
    build_static = any(static_values)
    build_animation = any(animation_values)
    if build_static and not all(static_values):
        raise ValueError("--input, --sprites, --preview and --palette must be provided together.")
    if build_animation and not all(animation_values):
        raise ValueError(
            "--base-sprites, --pose-reference, --animation-sprites, "
            "--animation-preview, --idle-preview and --walk-preview must be provided together."
        )
    if not build_static and not build_animation:
        raise ValueError("Provide a complete static and/or animation output group.")
    if (args.scene or args.scene_test) and not build_static:
        raise ValueError("--scene and --scene-test belong to the static output group.")
    if bool(args.scene) != bool(args.scene_test):
        raise ValueError("--scene and --scene-test must be provided together.")
    return build_static, build_animation


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
    target_height = CHARACTER_INNER_HEIGHT
    sprite = sprite.resize((target_inner_width, target_height), Image.Resampling.NEAREST)
    sprite = remove_tiny_components(sprite)
    sprite = remap_to_palette(sprite)

    cell = Image.new("RGBA", (CELL_SIZE, CELL_SIZE), (0, 0, 0, 0))
    paste_x = FOOT_ANCHOR[0] - sprite.width // 2
    paste_y = FOOT_ANCHOR[1] - sprite.height
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


def _without_external_outline(cell: Image.Image) -> Image.Image:
    content = Image.new("RGBA", cell.size, (0, 0, 0, 0))
    source_pixels = cell.convert("RGBA").load()
    target_pixels = content.load()
    for y in range(cell.height):
        for x in range(cell.width):
            pixel = source_pixels[x, y]
            if pixel[3] and pixel[:3] != PALETTE[0]:
                target_pixels[x, y] = (*pixel[:3], 255)
    return content


def _add_external_outline(content: Image.Image) -> Image.Image:
    mask = content.getchannel("A").point(lambda item: 255 if item else 0)
    dilated = mask.filter(ImageFilter.MaxFilter(3))
    outline_mask = ImageChops.subtract(dilated, mask)
    outline = Image.new("RGBA", content.size, (0, 0, 0, 0))
    outline.putalpha(outline_mask)
    return Image.alpha_composite(outline, content)


def _paste_region(
    canvas: Image.Image,
    source: Image.Image,
    box: tuple[int, int, int, int],
    offset: tuple[int, int],
) -> None:
    region = source.crop(box)
    destination = (box[0] + offset[0], box[1] + offset[1])
    canvas.alpha_composite(region, destination)


def _secondary_part_masks(source: Image.Image, row: int) -> dict[str, Image.Image]:
    masks: dict[str, Image.Image] = {}
    occupied = Image.new("L", source.size, 0)
    for part_name, polygons in SECONDARY_PART_POLYGONS[row].items():
        mask = Image.new("L", source.size, 0)
        draw = ImageDraw.Draw(mask)
        for polygon in polygons:
            draw.polygon(polygon, fill=255)
        mask = ImageChops.multiply(mask, source.getchannel("A"))
        mask = ImageChops.subtract(mask, occupied)
        if mask.getbbox() is None:
            raise RuntimeError(f"Secondary part {part_name} is empty for row {row}.")
        masks[part_name] = mask
        occupied = ImageChops.lighter(occupied, mask)
    return masks


def _partition_secondary_parts(
    source: Image.Image,
    row: int,
) -> tuple[Image.Image, dict[str, Image.Image]]:
    masks = _secondary_part_masks(source, row)
    occupied = Image.new("L", source.size, 0)
    layers: dict[str, Image.Image] = {}

    for part_name, mask in masks.items():
        if ImageChops.multiply(occupied, mask).getbbox() is not None:
            raise RuntimeError(f"Secondary part masks overlap for row {row}: {part_name}.")
        layer = source.copy()
        layer.putalpha(mask)
        layers[part_name] = layer
        occupied = ImageChops.lighter(occupied, mask)

    primary = source.copy()
    primary.putalpha(ImageChops.subtract(source.getchannel("A"), occupied))

    reconstructed = primary.copy()
    for layer in layers.values():
        reconstructed.alpha_composite(layer)
    if reconstructed.tobytes() != source.tobytes():
        raise RuntimeError(f"Secondary part partition duplicated or lost pixels for row {row}.")
    return primary, layers


def build_pixel_pose(
    base_cell: Image.Image,
    row: int,
    leg_top: int,
    body_offset: tuple[int, int],
    left_leg_offset: tuple[int, int] = (0, 0),
    right_leg_offset: tuple[int, int] = (0, 0),
    secondary_offsets: dict[str, tuple[int, int]] | None = None,
) -> Image.Image:
    source = _without_external_outline(base_cell)
    # Idle frames keep the approved composition byte-for-byte at the pixel
    # level. Secondary layers are partitioned only when explicit walk offsets
    # are supplied.
    primary = source
    secondary_layers: dict[str, Image.Image] = {}
    if secondary_offsets is not None:
        primary, secondary_layers = _partition_secondary_parts(source, row)
    pose = Image.new("RGBA", (CELL_SIZE, CELL_SIZE), (0, 0, 0, 0))

    # The two-pixel overlap hides seams while each leg receives its own gait phase.
    _paste_region(pose, primary, (0, leg_top, 33, CELL_SIZE), left_leg_offset)
    _paste_region(pose, primary, (31, leg_top, CELL_SIZE, CELL_SIZE), right_leg_offset)
    _paste_region(pose, primary, (0, 0, CELL_SIZE, leg_top + 5), body_offset)
    if secondary_offsets is not None:
        if set(secondary_offsets) != set(secondary_layers):
            raise RuntimeError(f"Secondary part offsets do not match row {row} layers.")
        for part_name, layer in secondary_layers.items():
            relative_offset = secondary_offsets[part_name]
            layer_offset = (
                body_offset[0] + relative_offset[0],
                body_offset[1] + relative_offset[1],
            )
            pose.alpha_composite(layer, layer_offset)
    outlined = _add_external_outline(pose)
    bounds = outlined.getchannel("A").getbbox()
    if bounds is None:
        raise RuntimeError("Pixel pose became empty during composition.")
    vertical_adjustment = FOOT_ANCHOR[1] - (bounds[3] - 1)
    aligned = Image.new("RGBA", outlined.size, (0, 0, 0, 0))
    aligned.paste(outlined, (0, vertical_adjustment), outlined)
    return aligned


# The generated reference establishes only the cadence: four restrained idle poses
# followed by six alternating walk poses. Final pixels always come from the approved
# static atlas below. Offsets are relative to each leg's grounded position; the
# per-character sole correction is measured from the approved base cell at build time.
SHARED_LEG_CYCLE = (
    ((2, 0), (-2, -1)),  # Contact: screen-left leg reaches Southeast.
    ((1, 0), (-1, -3)),  # Down: screen-left leg supports; free leg lifts.
    ((0, 0), (0, -2)),   # Passing: free leg crosses under the torso.
    ((-2, -1), (2, 0)),  # Contact: screen-right leg reaches Southeast.
    ((-1, -3), (1, 0)),  # Down: screen-right leg supports; free leg lifts.
    ((0, -2), (0, 0)),   # Passing: free leg crosses before the loop closes.
)

IDLE_BODY_OFFSETS = (
    ((0, 0), (0, -1), (1, 0), (-1, 0)),
    ((0, 0), (0, -1), (-1, 0), (1, 0)),
)

WALK_BODY_OFFSETS = (
    ((0, -1), (-1, 0), (-1, -1), (0, -1), (1, 0), (1, -1)),
    ((0, -1), (-1, 0), (0, -1), (0, -1), (1, 0), (0, -1)),
)

LEG_TOPS = (43, 42)

# Each secondary layer is cut from the approved static sprite before the walk
# is composed. Overlapping selection boxes are de-duplicated before composition
# so no source pixel is cloned.
# The Cangaceiro keeps the hat/scarf separate from the arms/rifle; the Capanga
# keeps the helmet and empty-handed arms/clothing flaps separate from the solid
# center of the armor.
SECONDARY_PART_POLYGONS = (
    {
        "hat_scarf": (
            ((19, 12), (45, 12), (45, 22), (19, 22)),
            ((28, 25), (36, 25), (37, 30), (33, 33), (28, 30)),
        ),
        "arms_rifle": (
            ((19, 27), (27, 27), (31, 35), (28, 40), (19, 38)),
            ((31, 27), (39, 26), (42, 40), (35, 41), (30, 35)),
            ((25, 32), (31, 31), (50, 47), (50, 51), (46, 51), (25, 36)),
        ),
    },
    {
        "helmet": (
            ((22, 12), (46, 12), (46, 22), (22, 22)),
        ),
        "arms_flaps": (
            ((18, 27), (25, 27), (28, 37), (26, 43), (20, 43), (18, 38)),
            ((41, 27), (47, 28), (48, 38), (45, 43), (41, 41)),
            ((22, 38), (30, 38), (31, 44), (25, 46), (21, 43)),
            ((38, 38), (45, 38), (46, 43), (40, 46), (37, 44)),
        ),
    },
)

# Offsets are relative to the torso and never exceed one pixel. Their absolute
# positions remain continuous across the loop. The hat/scarf and helmet reach
# the horizontal extreme one frame after the torso, giving visible follow-through.
SECONDARY_RELATIVE_OFFSETS = (
    {
        "hat_scarf": ((0, 0), (1, 0), (0, 0), (-1, 0), (-1, 0), (0, 0)),
        "arms_rifle": ((0, 0), (1, 0), (0, 0), (0, 0), (-1, 0), (0, 0)),
    },
    {
        "helmet": ((0, 0), (1, 0), (-1, 0), (0, 0), (-1, 0), (1, 0)),
        "arms_flaps": ((0, 0), (1, -1), (0, 1), (0, 0), (-1, -1), (0, 1)),
    },
)

DELAYED_SECONDARY_PARTS = ("hat_scarf", "helmet")


def validate_walk_cycle_definition() -> None:
    if len(SHARED_LEG_CYCLE) != 6:
        raise RuntimeError("Southeast walk cycle must contain exactly six poses.")

    support_legs = (0, 0, 0, 1, 1, 1)
    for frame_index, (left_offset, right_offset) in enumerate(SHARED_LEG_CYCLE):
        offsets = (left_offset, right_offset)
        support_index = support_legs[frame_index]
        free_index = 1 - support_index
        if offsets[support_index][1] != 0:
            raise RuntimeError(f"Walk frame {frame_index} has no grounded support leg.")
        if offsets[free_index][1] >= 0:
            raise RuntimeError(f"Walk frame {frame_index} does not lift the free leg.")

    for phase_start in (0, 3):
        support_index = support_legs[phase_start]
        free_index = 1 - support_index
        phase = SHARED_LEG_CYCLE[phase_start : phase_start + 3]
        support_x = [pose[support_index][0] for pose in phase]
        free_x = [pose[free_index][0] for pose in phase]
        if support_x != [2, 1, 0] or free_x != [-2, -1, 0]:
            raise RuntimeError("Walk phase must advance without foot teleporting.")
        if min(pose[free_index][1] for pose in phase) > -3:
            raise RuntimeError("Walk passing pose must visibly lift the free leg.")

    for row, body_offsets in enumerate(WALK_BODY_OFFSETS):
        left_support_delta = (
            body_offsets[1][0] - body_offsets[0][0],
            body_offsets[1][1] - body_offsets[0][1],
        )
        right_support_delta = (
            body_offsets[4][0] - body_offsets[3][0],
            body_offsets[4][1] - body_offsets[3][1],
        )
        if left_support_delta != (-1, 1) or right_support_delta != (1, 1):
            raise RuntimeError(
                f"Row {row} torso must move one pixel toward the support foot and down."
            )


def validate_secondary_motion_definition() -> dict[str, object]:
    motion: dict[str, object] = {}
    for row, character in enumerate(("cangaceiro", "capanga")):
        profiles = SECONDARY_RELATIVE_OFFSETS[row]
        if set(profiles) != set(SECONDARY_PART_POLYGONS[row]):
            raise RuntimeError(f"Secondary layer definitions do not match for {character}.")

        absolute_profiles: dict[str, tuple[tuple[int, int], ...]] = {}
        for part_name, relative_offsets in profiles.items():
            if len(relative_offsets) != len(SHARED_LEG_CYCLE):
                raise RuntimeError(f"Secondary part {part_name} must contain six offsets.")
            if any(abs(x) > 1 or abs(y) > 1 for x, y in relative_offsets):
                raise RuntimeError(f"Secondary part {part_name} exceeds one pixel from the torso.")
            absolute = tuple(
                (
                    WALK_BODY_OFFSETS[row][index][0] + relative[0],
                    WALK_BODY_OFFSETS[row][index][1] + relative[1],
                )
                for index, relative in enumerate(relative_offsets)
            )
            for index, current in enumerate(absolute):
                following = absolute[(index + 1) % len(absolute)]
                if abs(following[0] - current[0]) > 1 or abs(following[1] - current[1]) > 1:
                    raise RuntimeError(f"Secondary part {part_name} does not close smoothly.")
            absolute_profiles[part_name] = absolute

        if len({tuple(profile) for profile in absolute_profiles.values()}) != len(absolute_profiles):
            raise RuntimeError(f"Secondary parts must move independently for {character}.")

        delayed_part = DELAYED_SECONDARY_PARTS[row]
        body_x = [offset[0] for offset in WALK_BODY_OFFSETS[row]]
        part_x = [offset[0] for offset in absolute_profiles[delayed_part]]
        for extreme in (min, max):
            body_frame = body_x.index(extreme(body_x))
            part_frame = part_x.index(extreme(part_x))
            if part_frame != (body_frame + 1) % len(body_x):
                raise RuntimeError(
                    f"Secondary part {delayed_part} must peak one frame after the {character} torso."
                )

        motion[character] = {
            "body_offsets": WALK_BODY_OFFSETS[row],
            "secondary_relative_offsets": profiles,
            "secondary_absolute_offsets": absolute_profiles,
            "delayed_extreme_part": delayed_part,
        }
    return motion


def grounded_leg_corrections(
    base_cell: Image.Image,
    leg_top: int,
) -> tuple[int, int]:
    """Return the vertical offsets that place either sole at anchor y=60."""

    source = _without_external_outline(base_cell)
    corrections: list[int] = []
    for box in ((0, leg_top, 33, CELL_SIZE), (31, leg_top, CELL_SIZE, CELL_SIZE)):
        bounds = source.crop(box).getchannel("A").getbbox()
        if bounds is None:
            raise RuntimeError("One leg region is empty in the approved base cell.")
        content_bottom = leg_top + bounds[3] - 1
        outlined_bottom = content_bottom + 1
        corrections.append(FOOT_ANCHOR[1] - outlined_bottom)
    return (corrections[0], corrections[1])


def validate_pose_reference(reference_path: Path) -> tuple[int, int]:
    reference = Image.open(reference_path).convert("RGBA")
    if reference.width < ANIMATION_COLUMNS or reference.height < ANIMATION_ROWS:
        raise RuntimeError("Pose reference does not contain the expected 10x2 visual layout.")
    if reference.getchannel("A").getbbox() is None:
        raise RuntimeError("Pose reference is empty.")
    return reference.size


def build_animation_atlas(base_sprites_path: Path, reference_path: Path) -> Image.Image:
    validate_walk_cycle_definition()
    validate_secondary_motion_definition()
    validate_pose_reference(reference_path)
    base_sprites = Image.open(base_sprites_path).convert("RGBA")
    if base_sprites.size != (CELL_SIZE * 2, CELL_SIZE):
        raise RuntimeError("Approved static atlas must be 128x64 pixels.")
    atlas = Image.new(
        "RGBA",
        (ANIMATION_COLUMNS * CELL_SIZE, ANIMATION_ROWS * CELL_SIZE),
        (0, 0, 0, 0),
    )
    for row in range(ANIMATION_ROWS):
        base_cell = base_sprites.crop((row * CELL_SIZE, 0, (row + 1) * CELL_SIZE, CELL_SIZE))
        left_ground_correction, right_ground_correction = grounded_leg_corrections(
            base_cell,
            LEG_TOPS[row],
        )
        for idle_column, body_offset in enumerate(IDLE_BODY_OFFSETS[row]):
            cell = build_pixel_pose(base_cell, row, LEG_TOPS[row], body_offset)
            atlas.alpha_composite(cell, (idle_column * CELL_SIZE, row * CELL_SIZE))
        for walk_index, body_offset in enumerate(WALK_BODY_OFFSETS[row]):
            left_leg_offset, right_leg_offset = SHARED_LEG_CYCLE[walk_index]
            left_leg_offset = (
                left_leg_offset[0],
                left_leg_offset[1] + left_ground_correction,
            )
            right_leg_offset = (
                right_leg_offset[0],
                right_leg_offset[1] + right_ground_correction,
            )
            cell = build_pixel_pose(
                base_cell,
                row,
                LEG_TOPS[row],
                body_offset,
                left_leg_offset,
                right_leg_offset,
                {
                    part_name: offsets[walk_index]
                    for part_name, offsets in SECONDARY_RELATIVE_OFFSETS[row].items()
                },
            )
            atlas.alpha_composite(cell, ((walk_index + 4) * CELL_SIZE, row * CELL_SIZE))
    return atlas


def _animation_cell(atlas: Image.Image, row: int, column: int) -> Image.Image:
    return atlas.crop(
        (
            column * CELL_SIZE,
            row * CELL_SIZE,
            (column + 1) * CELL_SIZE,
            (row + 1) * CELL_SIZE,
        )
    )


def _pixel_difference(left: Image.Image, right: Image.Image) -> int:
    difference = ImageChops.difference(left, right)
    return sum(
        any(channel > 0 for channel in pixel)
        for pixel in difference.convert("RGBA").get_flattened_data()
    )


def _ground_contact_span(frame: Image.Image) -> tuple[int, int]:
    alpha = frame.getchannel("A")
    contact_x = [x for x in range(CELL_SIZE) if alpha.getpixel((x, FOOT_ANCHOR[1]))]
    if not contact_x:
        raise RuntimeError("Animation frame has no foot contact at the shared anchor.")
    if contact_x != list(range(contact_x[0], contact_x[-1] + 1)):
        raise RuntimeError("Animation frame has a split or disconnected ground contact.")
    return (contact_x[0], contact_x[-1])


def _opaque_component_count(frame: Image.Image) -> int:
    alpha = frame.getchannel("A")
    opaque = {
        (x, y)
        for y in range(frame.height)
        for x in range(frame.width)
        if alpha.getpixel((x, y))
    }
    components = 0
    while opaque:
        components += 1
        queue = deque([opaque.pop()])
        while queue:
            x, y = queue.popleft()
            for neighbor in (
                (x - 1, y - 1), (x, y - 1), (x + 1, y - 1),
                (x - 1, y),                     (x + 1, y),
                (x - 1, y + 1), (x, y + 1), (x + 1, y + 1),
            ):
                if neighbor in opaque:
                    opaque.remove(neighbor)
                    queue.append(neighbor)
    return components


def validate_animation_atlas(atlas: Image.Image) -> dict[str, object]:
    expected_size = (ANIMATION_COLUMNS * CELL_SIZE, ANIMATION_ROWS * CELL_SIZE)
    if atlas.size != expected_size:
        raise RuntimeError(f"Animation atlas must be {expected_size[0]}x{expected_size[1]} pixels.")

    allowed_pixels = {(*color, 255) for color in PALETTE}
    allowed_pixels.add((0, 0, 0, 0))
    used_pixels = set(atlas.get_flattened_data())
    unexpected_pixels = used_pixels - allowed_pixels
    if unexpected_pixels:
        raise RuntimeError(f"Animation atlas contains {len(unexpected_pixels)} colors outside Sertao 16.")
    alpha_values = {pixel[3] for pixel in used_pixels}
    if not alpha_values.issubset({0, 255}):
        raise RuntimeError("Animation atlas alpha must be binary.")

    frame_bounds: list[tuple[int, int, int, int]] = []
    for row in range(ANIMATION_ROWS):
        for column in range(ANIMATION_COLUMNS):
            cell = _animation_cell(atlas, row, column)
            bounds = cell.getchannel("A").getbbox()
            if bounds is None:
                raise RuntimeError(f"Animation frame {row}:{column} is empty.")
            visible_height = bounds[3] - bounds[1]
            if not 46 <= visible_height <= 49:
                raise RuntimeError(
                    f"Animation frame {row}:{column} has invalid visible height {visible_height}."
                )
            if bounds[3] - 1 != FOOT_ANCHOR[1]:
                raise RuntimeError(
                    f"Animation frame {row}:{column} does not end at foot anchor y={FOOT_ANCHOR[1]}."
                )
            if _opaque_component_count(cell) != 1:
                raise RuntimeError(f"Animation frame {row}:{column} contains a detached piece.")
            frame_bounds.append(bounds)

    loop_stats: dict[str, dict[str, object]] = {}
    for row, character in enumerate(("cangaceiro", "capanga")):
        for loop_name, columns in (("idle", IDLE_COLUMNS), ("walk", WALK_COLUMNS)):
            frames = [_animation_cell(atlas, row, column) for column in columns]
            unique_frames = len({frame.tobytes() for frame in frames})
            required_unique = len(frames)
            if unique_frames != required_unique:
                raise RuntimeError(
                    f"{character} {loop_name} loop must have {required_unique} distinct frames; "
                    f"found {unique_frames}."
                )
            transitions = [
                _pixel_difference(frames[index], frames[(index + 1) % len(frames)])
                for index in range(len(frames))
            ]
            stats: dict[str, object] = {
                "unique_frames": unique_frames,
                "transition_pixels": transitions,
            }
            if loop_name == "walk":
                contact_spans = [_ground_contact_span(frame) for frame in frames]
                if any(span[1] >= FOOT_ANCHOR[0] for span in contact_spans[:3]):
                    raise RuntimeError(f"{character} first walk phase lost its screen-left support.")
                if any(span[0] <= FOOT_ANCHOR[0] for span in contact_spans[3:]):
                    raise RuntimeError(f"{character} second walk phase lost its screen-right support.")
                for phase_start in (0, 3):
                    phase = contact_spans[phase_start : phase_start + 3]
                    for previous, current in zip(phase, phase[1:]):
                        if abs(current[0] - previous[0]) > 1 or abs(current[1] - previous[1]) > 1:
                            raise RuntimeError(
                                f"{character} planted foot drifts more than one pixel per frame."
                            )
                stats["ground_contact_spans"] = contact_spans
            loop_stats[f"{character}_{loop_name}"] = stats

    return {
        "size": atlas.size,
        "used_rgba_colors": len(used_pixels),
        "alpha_values": sorted(alpha_values),
        "frame_bounds": frame_bounds,
        "loops": loop_stats,
        "motion": validate_secondary_motion_definition(),
    }


def save_loop_preview(
    atlas: Image.Image,
    columns: range,
    output_path: Path,
    duration_ms: int,
) -> None:
    scale = 6
    gap = 16
    frames: list[Image.Image] = []
    for column in columns:
        canvas = Image.new("RGBA", (CELL_SIZE * 2 + gap, CELL_SIZE), (*PALETTE[1], 255))
        canvas.alpha_composite(_animation_cell(atlas, 0, column), (0, 0))
        canvas.alpha_composite(_animation_cell(atlas, 1, column), (CELL_SIZE + gap, 0))
        frames.append(canvas.resize((canvas.width * scale, canvas.height * scale), Image.Resampling.NEAREST))
    output_path.parent.mkdir(parents=True, exist_ok=True)
    frames[0].save(
        output_path,
        save_all=True,
        append_images=frames[1:],
        duration=duration_ms,
        loop=0,
        disposal=2,
        optimize=False,
    )


def save_animation_outputs(args: argparse.Namespace) -> dict[str, object]:
    atlas = build_animation_atlas(args.base_sprites, args.pose_reference)
    validation = validate_animation_atlas(atlas)
    args.animation_sprites.parent.mkdir(parents=True, exist_ok=True)
    args.animation_preview.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(args.animation_sprites, optimize=True)
    atlas.resize(
        (atlas.width * 4, atlas.height * 4),
        Image.Resampling.NEAREST,
    ).save(args.animation_preview, optimize=True)
    save_loop_preview(atlas, IDLE_COLUMNS, args.idle_preview, duration_ms=250)
    save_loop_preview(atlas, WALK_COLUMNS, args.walk_preview, duration_ms=100)
    return validation


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


def save_static_outputs(args: argparse.Namespace) -> None:
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


def main() -> None:
    args = parse_args()
    build_static, build_animation = validate_argument_groups(args)
    if build_static:
        save_static_outputs(args)
    if build_animation:
        validation = save_animation_outputs(args)
        print("ANIMATION_ATLAS_OK")
        print(json.dumps(validation, ensure_ascii=False, sort_keys=True))


if __name__ == "__main__":
    main()
