#!/usr/bin/env python3
"""Rasterize the supplied Spine 3.8 altar-tree data into Godot sprite sheets."""

from __future__ import annotations

import json
from math import ceil
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parent
SOURCE = ROOT / "assets" / "altar_tree"
ATLAS_NAME = "jitanshu_m"
CELL = (384, 307)
COLUMNS = 8
FPS = 30.0
ROOT_ON_CANVAS = (207.0, 286.0)
ANIMATION_NAMES = {"1": "locked", "2": "activate", "3": "ready", "4": "talked"}


def pair(value: str) -> tuple[int, int]:
    left, right = value.split(",", 1)
    return int(left.strip()), int(right.strip())


def read_atlas(path: Path) -> dict[str, dict[str, object]]:
    lines = path.read_text(encoding="utf-8").splitlines()
    regions: dict[str, dict[str, object]] = {}
    current: dict[str, object] | None = None
    for raw_line in lines[5:]:
        line = raw_line.strip()
        if not line:
            continue
        if ":" not in line:
            current = {}
            regions[line] = current
            continue
        if current is None:
            continue
        key, value = (part.strip() for part in line.split(":", 1))
        if key in {"xy", "size", "orig", "offset"}:
            current[key] = pair(value)
        elif key == "rotate":
            current[key] = value == "true"
        else:
            current[key] = value
    return regions


def unpack_region(atlas_image: Image.Image, region: dict[str, object]) -> Image.Image:
    x, y = region["xy"]
    width, height = region["size"]
    rotated = bool(region["rotate"])
    packed_width, packed_height = (height, width) if rotated else (width, height)
    frame = atlas_image.crop((x, y, x + packed_width, y + packed_height))
    if rotated:
        frame = frame.transpose(Image.Transpose.ROTATE_270)
    original_width, original_height = region["orig"]
    offset_x, offset_y = region["offset"]
    canvas = Image.new("RGBA", (original_width, original_height))
    canvas.alpha_composite(frame, (offset_x, original_height - offset_y - height))
    return canvas


def bezier_percent(linear_percent: float, keyframe: dict) -> float:
    curve = keyframe.get("curve")
    if curve is None:
        return linear_percent
    if curve == "stepped":
        return 0.0
    x1 = float(curve)
    y1 = float(keyframe.get("c2", 0.0))
    x2 = float(keyframe.get("c3", 1.0))
    y2 = float(keyframe.get("c4", 1.0))
    low, high = 0.0, 1.0
    for _ in range(14):
        value = (low + high) * 0.5
        inverse = 1.0 - value
        x = 3.0 * inverse * inverse * value * x1 + 3.0 * inverse * value * value * x2 + value**3
        if x < linear_percent:
            low = value
        else:
            high = value
    value = (low + high) * 0.5
    inverse = 1.0 - value
    return 3.0 * inverse * inverse * value * y1 + 3.0 * inverse * value * value * y2 + value**3


def sample_scalar(keys: list[dict], time: float, value_key: str, default: float) -> float:
    if not keys or time < float(keys[0].get("time", 0.0)):
        return default
    for index in range(len(keys) - 1):
        start = keys[index]
        end = keys[index + 1]
        start_time = float(start.get("time", 0.0))
        end_time = float(end.get("time", 0.0))
        if time < end_time:
            span = max(end_time - start_time, 0.000001)
            percent = bezier_percent((time - start_time) / span, start)
            start_value = float(start.get(value_key, default))
            end_value = float(end.get(value_key, default))
            return start_value + (end_value - start_value) * percent
    return float(keys[-1].get(value_key, default))


def active_attachment(animation: dict, slot_name: str, time: float, setup_attachment: str | None = None) -> str | None:
    events = animation.get("slots", {}).get(slot_name, {}).get("attachment", [])
    active = setup_attachment
    for event in events:
        if float(event.get("time", 0.0)) > time + 0.00001:
            break
        active = event.get("name")
    return active


def animation_duration(animation: dict) -> float:
    duration = 0.0
    for slot in animation.get("slots", {}).values():
        for timeline in slot.values():
            for key in timeline:
                duration = max(duration, float(key.get("time", 0.0)))
    for bone in animation.get("bones", {}).values():
        for timeline in bone.values():
            for key in timeline:
                duration = max(duration, float(key.get("time", 0.0)))
    return duration


def transformed_attachment(image: Image.Image, scale_x: float, scale_y: float, rotation: float) -> Image.Image:
    width = max(1, round(image.width * abs(scale_x)))
    height = max(1, round(image.height * abs(scale_y)))
    layer = image.resize((width, height), Image.Resampling.LANCZOS)
    if scale_x < 0:
        layer = layer.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    if scale_y < 0:
        layer = layer.transpose(Image.Transpose.FLIP_TOP_BOTTOM)
    if abs(rotation) > 0.0001:
        layer = layer.rotate(-rotation, resample=Image.Resampling.BICUBIC, expand=True)
    return layer


def composite_center(canvas: Image.Image, layer: Image.Image, center_x: float, center_y: float) -> None:
    destination = (round(center_x - layer.width * 0.5), round(center_y - layer.height * 0.5))
    canvas.alpha_composite(layer, destination)


def render_frame(
    animation: dict,
    time: float,
    regions: dict[str, dict[str, object]],
    unpacked: dict[str, Image.Image],
    bones: dict[str, dict],
) -> Image.Image:
    tree_attachment = active_attachment(animation, "a", time)
    if tree_attachment is None:
        raise ValueError("altar-tree animation has no active tree attachment")
    canvas = unpacked[tree_attachment].copy()
    for index in range(1, 4):
        bone_name = f"qp{index}"
        glow_name = active_attachment(animation, f"dg{index}", time)
        particle_name = active_attachment(animation, bone_name, time)
        if glow_name is None and particle_name is None:
            continue
        setup = bones[bone_name]
        timelines = animation.get("bones", {}).get(bone_name, {})
        translate_keys = timelines.get("translate", [])
        rotate_keys = timelines.get("rotate", [])
        scale_keys = timelines.get("scale", [])
        x = float(setup.get("x", 0.0)) + sample_scalar(translate_keys, time, "x", 0.0)
        y = float(setup.get("y", 0.0)) + sample_scalar(translate_keys, time, "y", 0.0)
        rotation = float(setup.get("rotation", 0.0)) + sample_scalar(rotate_keys, time, "angle", 0.0)
        scale_x = float(setup.get("scaleX", 1.0)) * sample_scalar(scale_keys, time, "x", 1.0)
        scale_y = float(setup.get("scaleY", 1.0)) * sample_scalar(scale_keys, time, "y", 1.0)
        center_x = ROOT_ON_CANVAS[0] + x
        center_y = ROOT_ON_CANVAS[1] - y
        for attachment_name in (glow_name, particle_name):
            if attachment_name is None:
                continue
            layer = transformed_attachment(unpacked[attachment_name], scale_x, scale_y, rotation)
            composite_center(canvas, layer, center_x, center_y)
    return canvas


def save_sheet(frames: list[Image.Image], output: Path) -> int:
    used_columns = min(COLUMNS, len(frames))
    rows = ceil(len(frames) / used_columns)
    sheet = Image.new("RGBA", (used_columns * CELL[0], rows * CELL[1]))
    for index, frame in enumerate(frames):
        sheet.alpha_composite(frame, ((index % used_columns) * CELL[0], (index // used_columns) * CELL[1]))
    sheet.save(output, optimize=True)
    return used_columns


def main() -> None:
    atlas_image = Image.open(SOURCE / f"{ATLAS_NAME}.png").convert("RGBA")
    regions = read_atlas(SOURCE / f"{ATLAS_NAME}.atlas")
    data = json.loads((SOURCE / f"{ATLAS_NAME}.json").read_text(encoding="utf-8"))
    required = [*(f"jitanshu/{index:03d}" for index in range(1, 53)), "2", "qp"]
    missing = [name for name in required if name not in regions]
    if missing:
        raise ValueError(f"atlas is missing attachments: {missing}")
    unpacked = {name: unpack_region(atlas_image, regions[name]) for name in required}
    bones = {bone["name"]: bone for bone in data["bones"]}
    metadata = {
        "source": f"{ATLAS_NAME}.json",
        "cell": list(CELL),
        "columns": COLUMNS,
        "fps": FPS,
        "supplementary_attachments": ["2", "qp"],
        "animations": {},
    }
    for source_name, runtime_name in ANIMATION_NAMES.items():
        animation = data["animations"][source_name]
        duration = animation_duration(animation)
        looping = runtime_name in {"locked", "ready", "talked"}
        frame_count = max(1, ceil(duration * FPS) + 1)
        frames = [render_frame(animation, index / FPS, regions, unpacked, bones) for index in range(frame_count)]
        filename = f"altar-tree-{runtime_name}.png"
        used_columns = save_sheet(frames, SOURCE / filename)
        metadata["animations"][runtime_name] = {
            "source_animation": source_name,
            "duration": duration,
            "frames": frame_count,
            "columns": used_columns,
            "loop": looping,
            "sheet": filename,
        }
        print(f"OK  {runtime_name}: source={source_name} frames={frame_count} duration={duration:.4f}")
    (SOURCE / "animations.json").write_text(json.dumps(metadata, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("OK  supplementary_attachments=2,qp")


if __name__ == "__main__":
    main()
