"""Render the brand mark (assets/brand/mark.svg geometry) as launcher icon sources.

Outputs, at 1024 px:
  icon.png             opaque: #0a0d14 background + mark (iOS / legacy Android)
  icon_foreground.png  transparent background, mark scaled into the adaptive safe zone
"""
import sys

from PIL import Image, ImageDraw

OUT = sys.argv[1]
BG = (10, 13, 20, 255)
RING = (152, 168, 255, 255)
DOT = (233, 236, 242, 255)
SIZE = 1024
SS = 4  # supersample for smooth edges


def draw_mark(scale, canvas):
    """Draw the mark from the 256-unit SVG geometry scaled by `scale`, centered."""
    big = canvas.size[0]
    c = big / 2
    u = scale * big / 256  # one SVG unit in pixels
    d = ImageDraw.Draw(canvas)
    stroke = 21 * u
    r = 74 * u
    d.ellipse([c - r, c - r, c + r, c + r], outline=RING, width=round(stroke))
    half = stroke / 2
    for (x1, y1, x2, y2) in [(128, 22, 128, 64), (128, 192, 128, 234), (22, 128, 64, 128), (192, 128, 234, 128)]:
        p1 = (c + (x1 - 128) * u, c + (y1 - 128) * u)
        p2 = (c + (x2 - 128) * u, c + (y2 - 128) * u)
        d.line([p1, p2], fill=RING, width=round(stroke))
        for (px, py) in (p1, p2):
            d.ellipse([px - half, py - half, px + half, py + half], fill=RING)
    rd = 21 * u
    d.ellipse([c - rd, c - rd, c + rd, c + rd], fill=DOT)


def render(scale, background):
    big = Image.new("RGBA", (SIZE * SS, SIZE * SS), background)
    draw_mark(scale, big)
    return big.resize((SIZE, SIZE), Image.LANCZOS)


# Full icon: mark fills the tile like the SVG (scale 1 => 256 units across).
render(1.0, BG).save(f"{OUT}/icon.png")
# Adaptive foreground: Android masks to the central 66%, and flutter_launcher_icons insets the foreground 16% per side, so 0.92 lands the mark at ~63% of the canvas.
render(0.92, (0, 0, 0, 0)).save(f"{OUT}/icon_foreground.png")
print("ok")
