#!/usr/bin/env python3
"""Build the 20-frame Godot atlas for the main-city teleport effect."""

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets" / "vfx" / "source" / "main-city-teleport-yellow.gif"
ATLAS = ROOT / "assets" / "vfx" / "main-city-teleport-yellow-sheet.png"
PREVIEW = ROOT / "assets" / "vfx" / "main-city-teleport-yellow-preview.gif"

FRAME_COUNT = 20
FRAME_SIZE = 512
COLUMNS = 5
ROWS = 4


def suppress_black_noise(frame: Image.Image) -> Image.Image:
    """Keep the additive glow while forcing compressed near-black pixels to zero."""
    return frame.point(
        lambda value: 0 if value < 8 else round((value - 8) * 255 / 247)
    )


def build() -> None:
    source = Image.open(SOURCE)
    source_frame_count = getattr(source, "n_frames", 1)
    total_duration_ms = 0
    for source_index in range(source_frame_count):
        source.seek(source_index)
        total_duration_ms += source.info.get("duration", 70)

    frames: list[Image.Image] = []
    for frame_index in range(FRAME_COUNT):
        # Do not duplicate the first frame at the end. The final-to-first gap is
        # the same size as every other sample interval in the original loop.
        source_index = round(frame_index * source_frame_count / FRAME_COUNT)
        source.seek(source_index)
        frame = suppress_black_noise(source.convert("RGB")).resize(
            (FRAME_SIZE, FRAME_SIZE), Image.Resampling.LANCZOS
        )
        frames.append(frame)

    atlas = Image.new("RGB", (FRAME_SIZE * COLUMNS, FRAME_SIZE * ROWS), (0, 0, 0))
    for frame_index, frame in enumerate(frames):
        atlas.paste(
            frame,
            ((frame_index % COLUMNS) * FRAME_SIZE, (frame_index // COLUMNS) * FRAME_SIZE),
        )
    atlas.save(ATLAS, optimize=True)

    frame_duration_ms = round(total_duration_ms / FRAME_COUNT)
    frames[0].save(
        PREVIEW,
        save_all=True,
        append_images=frames[1:],
        duration=frame_duration_ms,
        loop=0,
        disposal=2,
        optimize=True,
    )


if __name__ == "__main__":
    build()
