#!/usr/bin/env python3
"""Installs the launcher icon into the generated Android host project.

`flutter create` writes its default icons into android/app/src/main/res, and the
Android project itself is not checked in, so the icon is applied here instead of
being committed five times. Needs Pillow (`pip install pillow`), which the
workflow installs next to it.
"""

from __future__ import annotations

import pathlib
import sys

try:
    from PIL import Image
except ImportError:  # pragma: no cover - CI installs Pillow before this runs
    print("Pillow is required: pip install pillow", file=sys.stderr)
    raise SystemExit(1)

ROOT = pathlib.Path(__file__).resolve().parents[2]
ICON = ROOT / "assets" / "icon.png"
RES = ROOT / "android" / "app" / "src" / "main" / "res"

# Legacy launcher sizes in dp: 48/72/96/144/192.
DENSITIES = {
    "mdpi": 48,
    "hdpi": 72,
    "xhdpi": 96,
    "xxhdpi": 144,
    "xxxhdpi": 192,
}

# Adaptive icons are a 108dp canvas; the artwork must stay inside the middle
# 72dp circle, so it is drawn at 66% and centred.
ADAPTIVE = {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}
BACKGROUND = "#F5EFDF"


def save(image: Image.Image, path: pathlib.Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, format="PNG", optimize=True)


def main() -> int:
    if not ICON.is_file():
        print("assets/icon.png is missing", file=sys.stderr)
        return 1
    if not RES.is_dir():
        print("android res is missing: run `flutter create .` first", file=sys.stderr)
        return 1

    source = Image.open(ICON).convert("RGBA")

    for density, size in DENSITIES.items():
        folder = RES / f"mipmap-{density}"
        save(source.resize((size, size), Image.LANCZOS), folder / "ic_launcher.png")
        save(source.resize((size, size), Image.LANCZOS), folder / "ic_launcher_round.png")

        canvas_size = ADAPTIVE[density]
        layer = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
        inner = int(canvas_size * 0.66)
        art = source.resize((inner, inner), Image.LANCZOS)
        offset = (canvas_size - inner) // 2
        layer.paste(art, (offset, offset), art)
        save(layer, folder / "ic_launcher_foreground.png")

    anydpi = RES / "mipmap-anydpi-v26"
    anydpi.mkdir(parents=True, exist_ok=True)
    for name in ("ic_launcher.xml", "ic_launcher_round.xml"):
        (anydpi / name).write_text(
            '<?xml version="1.0" encoding="utf-8"?>\n'
            '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
            '    <background android:drawable="@color/ic_launcher_background" />\n'
            '    <foreground android:drawable="@mipmap/ic_launcher_foreground" />\n'
            "</adaptive-icon>\n",
            encoding="utf-8",
        )

    values = RES / "values"
    values.mkdir(parents=True, exist_ok=True)
    (values / "ic_launcher_background.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        "<resources>\n"
        f'    <color name="ic_launcher_background">{BACKGROUND}</color>\n'
        "</resources>\n",
        encoding="utf-8",
    )

    print("launcher icons installed (adaptive background %s)" % BACKGROUND)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
