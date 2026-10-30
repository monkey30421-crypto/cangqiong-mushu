#!/usr/bin/env python3
"""Re-extract and register a game-scale idle candidate without game integration."""

from __future__ import annotations

import json
from collections import deque
from pathlib import Path
from statistics import median

from PIL import Image, ImageChops, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parent
SOURCE = ROOT / "assets" / "player_animations" / "source_v2" / "idle-transparent.png"
OUT = ROOT / "assets" / "player_animations" / "review_pending" / "idle_game_scale_v2"
FRAME_OUT = OUT / "frames"

CANVAS = 500
SOURCE_COLS = 4
SOURCE_ROWS = 2
OVERLAP_X = 80
OVERLAP_Y = 60
TARGET_HEIGHT = 122.0
TARGET_BASELINE = 460.0
TARGET_ANCHOR_X = 250.0
FPS = 8
ALPHA_THRESHOLD = 24


def visible_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    bbox = image.getchannel("A").point(
        lambda value: 255 if value > ALPHA_THRESHOLD else 0
    ).getbbox()
    if bbox is None:
        raise ValueError("Empty idle frame")
    return bbox


def connected_components(mask: Image.Image) -> list[list[tuple[int, int]]]:
    pixels = mask.load()
    width, height = mask.size
    visited = bytearray(width * height)
    neighbours = (
        (-1, -1), (0, -1), (1, -1),
        (-1, 0), (1, 0),
        (-1, 1), (0, 1), (1, 1),
    )
    components: list[list[tuple[int, int]]] = []
    for y in range(height):
        for x in range(width):
            offset = y * width + x
            if visited[offset] or pixels[x, y] == 0:
                continue
            visited[offset] = 1
            queue = deque([(x, y)])
            component: list[tuple[int, int]] = []
            while queue:
                current_x, current_y = queue.popleft()
                component.append((current_x, current_y))
                for dx, dy in neighbours:
                    next_x = current_x + dx
                    next_y = current_y + dy
                    if not (0 <= next_x < width and 0 <= next_y < height):
                        continue
                    next_offset = next_y * width + next_x
                    if visited[next_offset] or pixels[next_x, next_y] == 0:
                        continue
                    visited[next_offset] = 1
                    queue.append((next_x, next_y))
            components.append(component)
    return components


def retain_target_character(
    image: Image.Image, expected_center: tuple[float, float]
) -> tuple[Image.Image, int]:
    """Keep the full character nearest the intended grid-cell centre."""
    alpha = image.getchannel("A")
    binary = alpha.point(lambda value: 255 if value > ALPHA_THRESHOLD else 0)
    components = connected_components(binary)
    candidates = [component for component in components if len(component) >= 500]
    if not candidates:
        raise ValueError("No character-sized component in expanded idle cell")

    def score(component: list[tuple[int, int]]) -> float:
        xs = [point[0] for point in component]
        ys = [point[1] for point in component]
        center_x = (min(xs) + max(xs)) / 2
        center_y = (min(ys) + max(ys)) / 2
        distance = ((center_x - expected_center[0]) ** 2 + (center_y - expected_center[1]) ** 2) ** 0.5
        return len(component) - distance * 45.0

    target = max(candidates, key=score)
    hard_mask = Image.new("L", image.size)
    mask_pixels = hard_mask.load()
    for x, y in target:
        mask_pixels[x, y] = 255
    # Dilating only the keep-mask restores every original antialiased edge
    # without expanding or redrawing the character silhouette.
    keep_mask = hard_mask.filter(ImageFilter.MaxFilter(7))
    cleaned = image.copy()
    cleaned.putalpha(ImageChops.multiply(alpha, keep_mask))

    left, top, right, bottom = visible_bbox(cleaned)
    safe_margin = min(left, top, cleaned.width - right, cleaned.height - bottom)
    return cleaned, safe_margin


def extract_complete_frames() -> tuple[list[Image.Image], list[int]]:
    sheet = Image.open(SOURCE).convert("RGBA")
    frames: list[Image.Image] = []
    source_margins: list[int] = []
    for row in range(SOURCE_ROWS):
        for col in range(SOURCE_COLS):
            base_left = round(col * sheet.width / SOURCE_COLS)
            base_top = round(row * sheet.height / SOURCE_ROWS)
            base_right = round((col + 1) * sheet.width / SOURCE_COLS)
            base_bottom = round((row + 1) * sheet.height / SOURCE_ROWS)
            crop_left = max(0, base_left - OVERLAP_X)
            crop_top = max(0, base_top - OVERLAP_Y)
            crop_right = min(sheet.width, base_right + OVERLAP_X)
            crop_bottom = min(sheet.height, base_bottom + OVERLAP_Y)
            expanded = sheet.crop((crop_left, crop_top, crop_right, crop_bottom))
            expected_center = (
                (base_left + base_right) / 2 - crop_left,
                (base_top + base_bottom) / 2 - crop_top,
            )
            character, margin = retain_target_character(expanded, expected_center)
            frames.append(character)
            source_margins.append(margin)
    return frames, source_margins


def core_anchor(image: Image.Image) -> tuple[float, float, tuple[int, int, int, int]]:
    """Use the dense chest/waist core, not feet, hair or swinging equipment."""
    bbox = visible_bbox(image)
    left, top, right, bottom = bbox
    height = bottom - top
    alpha = image.getchannel("A")
    pixels = alpha.load()

    upper_xs = [
        x
        for y in range(round(top + height * 0.12), round(top + height * 0.56))
        for x in range(left, right)
        if pixels[x, y] > 96
    ]
    upper_xs.sort()
    body_x = float(upper_xs[len(upper_xs) // 2]) if upper_xs else (left + right) / 2

    x0 = max(left, round(body_x - height * 0.15))
    x1 = min(right, round(body_x + height * 0.15))
    y0 = round(top + height * 0.34)
    y1 = round(top + height * 0.62)
    points = [
        (x, y)
        for y in range(y0, y1)
        for x in range(x0, x1)
        if pixels[x, y] > 96
    ]
    if not points:
        return body_x, top + height * 0.5, bbox
    xs = sorted(point[0] for point in points)
    ys = sorted(point[1] for point in points)
    return float(xs[len(xs) // 2]), float(ys[len(ys) // 2]), bbox


def build_frames() -> tuple[list[Image.Image], list[int], tuple[float, float]]:
    sources, source_margins = extract_complete_frames()
    anchors = [core_anchor(frame) for frame in sources]
    heights = [bbox[3] - bbox[1] for _, _, bbox in anchors]
    scale = TARGET_HEIGHT / float(median(heights))
    root_to_bottom = median(bbox[3] - anchor_y for _, anchor_y, bbox in anchors)
    target_anchor = (TARGET_ANCHOR_X, TARGET_BASELINE - root_to_bottom * scale)

    FRAME_OUT.mkdir(parents=True, exist_ok=True)
    for stale in FRAME_OUT.glob("*.png"):
        stale.unlink()

    frames: list[Image.Image] = []
    for index, (source, (anchor_x, anchor_y, bbox)) in enumerate(zip(sources, anchors)):
        crop = source.crop(bbox)
        resized = crop.resize(
            (max(1, round(crop.width * scale)), max(1, round(crop.height * scale))),
            Image.Resampling.LANCZOS,
        )
        position = (
            round(target_anchor[0] - (anchor_x - bbox[0]) * scale),
            round(target_anchor[1] - (anchor_y - bbox[1]) * scale),
        )
        output = Image.new("RGBA", (CANVAS, CANVAS))
        output.alpha_composite(resized, position)
        output.save(FRAME_OUT / f"idle-{index:02d}.png", optimize=True)
        frames.append(output)

    manifest = {
        "status": "pending_review_not_integrated",
        "canvas": [CANVAS, CANVAS],
        "visible_character_height": TARGET_HEIGHT,
        "baseline_y": TARGET_BASELINE,
        "core_anchor": [round(target_anchor[0], 3), round(target_anchor[1], 3)],
        "fps": FPS,
        "loop": True,
        "playback_order": [f"idle-{index:02d}.png" for index in range(len(frames))],
        "extraction": "overlapping_cells_main_character_component",
    }
    (OUT / "manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    return frames, source_margins, target_anchor


def quantized_gif_frames(frames: list[Image.Image], size: tuple[int, int]) -> list[Image.Image]:
    return [
        frame.resize(size, Image.Resampling.LANCZOS).convert(
            "P", palette=Image.Palette.ADAPTIVE, colors=256
        )
        for frame in frames
    ]


def save_gif(path: Path, frames: list[Image.Image]) -> None:
    frames[0].save(
        path,
        save_all=True,
        append_images=frames[1:],
        duration=round(1000 / FPS),
        loop=0,
        disposal=2,
        optimize=False,
    )


def save_previews(frames: list[Image.Image], target_anchor: tuple[float, float]) -> None:
    canvas_previews = []
    for frame in frames:
        background = Image.new("RGBA", frame.size, "#f4e6c6")
        background.alpha_composite(frame)
        canvas_previews.append(background)
    save_gif(OUT / "idle-game-scale-500.gif", quantized_gif_frames(canvas_previews, (500, 500)))

    # A close preview makes it possible to inspect the recovered outer contour.
    zoom_box = (175, 325, 330, 480)
    zoomed = [frame.crop(zoom_box).resize((465, 465), Image.Resampling.NEAREST) for frame in canvas_previews]
    for frame in zoomed:
        draw = ImageDraw.Draw(frame)
        anchor_x = round((target_anchor[0] - zoom_box[0]) * 3)
        anchor_y = round((target_anchor[1] - zoom_box[1]) * 3)
        draw.line((anchor_x - 8, anchor_y, anchor_x + 8, anchor_y), fill="#e74c3c", width=2)
        draw.line((anchor_x, anchor_y - 8, anchor_x, anchor_y + 8), fill="#e74c3c", width=2)
    save_gif(OUT / "idle-edge-alignment-zoom.gif", quantized_gif_frames(zoomed, (465, 465)))

    city = Image.open(ROOT / "assets" / "backgrounds" / "city.png").convert("RGBA")
    crop_box = (0, 350, 900, 750)
    paste_position = (round(260 - CANVAS / 2), round(645 - TARGET_BASELINE - crop_box[1]))
    scene_previews = []
    for frame in frames:
        preview = city.crop(crop_box)
        preview.alpha_composite(frame, paste_position)
        scene_previews.append(preview)
    save_gif(OUT / "idle-in-game-proportion.gif", quantized_gif_frames(scene_previews, (900, 400)))


def validate(
    frames: list[Image.Image], source_margins: list[int], target_anchor: tuple[float, float]
) -> None:
    heights = []
    output_margins = []
    measured_anchors = []
    for frame in frames:
        bbox = visible_bbox(frame)
        heights.append(bbox[3] - bbox[1])
        output_margins.append(min(bbox[0], bbox[1], CANVAS - bbox[2], CANVAS - bbox[3]))
        anchor_x, anchor_y, _ = core_anchor(frame)
        measured_anchors.append((anchor_x, anchor_y))

    anchor_x_spread = max(point[0] for point in measured_anchors) - min(
        point[0] for point in measured_anchors
    )
    anchor_y_spread = max(point[1] for point in measured_anchors) - min(
        point[1] for point in measured_anchors
    )
    lines = [
        f"OK  frames={len(frames)} playback=idle-00..idle-{len(frames) - 1:02d}",
        f"OK  canvas={CANVAS}x{CANVAS} RGBA",
        f"OK  visible_height_range={min(heights)}..{max(heights)}px target={TARGET_HEIGHT}px",
        f"OK  source_safe_margin_min={min(source_margins)}px (overlap extraction)",
        f"OK  output_safe_margin_min={min(output_margins)}px",
        f"OK  requested_core_anchor={target_anchor[0]:.2f},{target_anchor[1]:.2f}",
        f"OK  measured_core_anchor_spread={anchor_x_spread:.2f}px,{anchor_y_spread:.2f}px",
        f"OK  baseline_y={TARGET_BASELINE}px fps={FPS} loop=true",
        "OK  integration_status=pending_review_not_integrated",
    ]
    (OUT / "validation_report.txt").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("\n".join(lines))


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    frames, source_margins, target_anchor = build_frames()
    save_previews(frames, target_anchor)
    validate(frames, source_margins, target_anchor)


if __name__ == "__main__":
    main()
