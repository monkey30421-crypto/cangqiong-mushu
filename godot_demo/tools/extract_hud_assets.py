#!/usr/bin/env python3
"""Extract the approved HUD pixels using a background-removal mask as alpha only."""

from __future__ import annotations

import argparse
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image


# Crop rectangles are exact coordinates in the approved 1800×750 v3 mockup.
# Seed coordinates identify the matching component in the temporary chroma-key mask.
ASSETS = {
    "hud-currency": ((1475, 50, 1710, 103), (1700, 76)),
    "hud-joystick": ((55, 587, 201, 731), (139, 670)),
    "hud-status-button": ((197, 619, 280, 713), (278, 681)),
    "hud-backpack-button": ((278, 619, 363, 713), (381, 681)),
    "hud-skill1": ((1383, 635, 1462, 729), (1522, 704)),
    "hud-skill2": ((1380, 563, 1461, 661), (1524, 615)),
    "hud-skill3": ((1435, 500, 1508, 593), (1578, 544)),
    "hud-skill4": ((1506, 492, 1584, 592), (1680, 530)),
    "hud-jump": ((1582, 498, 1660, 593), (1782, 545)),
    "hud-dodge": ((1628, 565, 1713, 661), (1826, 616)),
    "hud-attack": ((1471, 568, 1621, 736), (1678, 654)),
}

# In the extraction reference, the skill 1 and skill 2 ornaments touch by one edge.
# Split their shared connected component at the visual midpoint.
MASK_BOX_OVERRIDES = {
    "hud-skill1": (1474, 663, 1569, 748),
    "hud-skill2": (1474, 573, 1569, 663),
}

ASPECT_PRESERVED_ASSETS = {
    "hud-skill1",
    "hud-skill2",
    "hud-skill3",
    "hud-skill4",
    "hud-jump",
    "hud-dodge",
    "hud-attack",
}


def connected_component(alpha: np.ndarray, seed: tuple[int, int]) -> np.ndarray:
    foreground = alpha >= 48
    x, y = seed
    if not foreground[y, x]:
        raise ValueError(f"Mask seed {seed} is transparent")

    component = np.zeros(foreground.shape, dtype=np.uint8)
    queue = deque([(x, y)])
    component[y, x] = 255
    height, width = foreground.shape
    while queue:
        current_x, current_y = queue.popleft()
        for next_y in range(max(0, current_y - 1), min(height, current_y + 2)):
            for next_x in range(max(0, current_x - 1), min(width, current_x + 2)):
                if foreground[next_y, next_x] and component[next_y, next_x] == 0:
                    component[next_y, next_x] = 255
                    queue.append((next_x, next_y))
    return component


def extract(source: Path, mask_source: Path, output_dir: Path, use_extraction_pixels: bool) -> None:
    approved = Image.open(source).convert("RGB")
    mask_image = Image.open(mask_source).convert("RGBA")
    mask_alpha = np.asarray(mask_image.getchannel("A"))
    output_dir.mkdir(parents=True, exist_ok=True)

    for name, (source_box, seed) in ASSETS.items():
        component = connected_component(mask_alpha, seed)
        component_image = Image.fromarray(component, mode="L")
        component_box = MASK_BOX_OVERRIDES.get(name, component_image.getbbox())
        if component_box is None:
            raise ValueError(f"No alpha component found for {name}")

        source_crop = approved.crop(source_box).convert("RGBA")
        if use_extraction_pixels and name in ASPECT_PRESERVED_ASSETS:
            target_size = source_crop.size
            extracted_crop = mask_image.crop(component_box)
            extracted_alpha = component_image.crop(component_box)
            uniform_scale = min(
                target_size[0] / extracted_crop.width,
                target_size[1] / extracted_crop.height,
            )
            fitted_size = (
                max(1, round(extracted_crop.width * uniform_scale)),
                max(1, round(extracted_crop.height * uniform_scale)),
            )
            extracted_crop = extracted_crop.resize(fitted_size, Image.Resampling.LANCZOS)
            extracted_alpha = extracted_alpha.resize(fitted_size, Image.Resampling.LANCZOS)
            extracted_alpha = extracted_alpha.point(lambda value: 0 if value < 12 else value)
            extracted_crop.putalpha(extracted_alpha)

            source_crop = Image.new("RGBA", target_size, (0, 0, 0, 0))
            paste_position = (
                (target_size[0] - fitted_size[0]) // 2,
                (target_size[1] - fitted_size[1]) // 2,
            )
            source_crop.alpha_composite(extracted_crop, paste_position)
        elif use_extraction_pixels:
            source_crop = mask_image.crop(component_box).resize(source_crop.size, Image.Resampling.LANCZOS)
            alpha_crop = component_image.crop(component_box).resize(source_crop.size, Image.Resampling.LANCZOS)
            alpha_crop = alpha_crop.point(lambda value: 0 if value < 12 else value)
            source_crop.putalpha(alpha_crop)
        else:
            alpha_crop = component_image.crop(component_box).resize(source_crop.size, Image.Resampling.LANCZOS)
            # Keep faint antialiased edge pixels without bringing chroma/background into the asset.
            alpha_crop = alpha_crop.point(lambda value: 0 if value < 12 else value)
            source_crop.putalpha(alpha_crop)
        if use_extraction_pixels:
            pixels = np.asarray(source_crop).copy()
            red = pixels[:, :, 0]
            green = pixels[:, :, 1]
            blue = pixels[:, :, 2]
            chroma_fringe = (
                (red > 180)
                & (blue > 180)
                & (green < 105)
                & (np.abs(red.astype(np.int16) - blue.astype(np.int16)) < 85)
            )
            pixels[chroma_fringe, 3] = 0
            source_crop = Image.fromarray(pixels, mode="RGBA")
        output_path = output_dir / f"{name}.png"
        source_crop.save(output_path, optimize=True)
        print(f"{output_path.name}: {source_crop.size}, mask={component_box}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--mask-source", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--use-extraction-pixels", action="store_true")
    args = parser.parse_args()
    extract(args.source, args.mask_source, args.output_dir, args.use_extraction_pixels)


if __name__ == "__main__":
    main()
