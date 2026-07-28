#!/usr/bin/env python3
"""Generate forge-ink placeholder→production sprites for CINDERFORGE v1 art pass.
Palette locked to ART-BIBLE.md. Transparent PNG, readable silhouettes.
"""
from __future__ import annotations

from pathlib import Path
import math

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(r"C:\WPAI\Games\Cinderforge\art\sprites")

# ART BIBLE
COAL = (10, 7, 6, 255)
IRON = (28, 20, 16, 255)
IRON_EDGE = (58, 42, 34, 255)
EMBER = (255, 122, 38, 255)
EMBER_DEEP = (232, 69, 28, 255)
GOLD = (255, 179, 71, 255)
BONE = (243, 235, 227, 255)
SILH = (13, 10, 8, 255)
TRANS = (0, 0, 0, 0)


def new(w: int, h: int) -> Image.Image:
    return Image.new("RGBA", (w, h), TRANS)


def save(im: Image.Image, rel: str) -> None:
    path = ROOT / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    im.save(path, "PNG")
    print(f"  {path.relative_to(ROOT.parent.parent)}  {im.size}")


def rim(draw: ImageDraw.ImageDraw, pts, fill, outline=EMBER, width=2):
    draw.polygon(pts, fill=fill, outline=outline)
    # soft outer glow
    pass


def glow_circle(im: Image.Image, cx, cy, r, color, alpha=120):
    layer = new(*im.size)
    d = ImageDraw.Draw(layer)
    c = (*color[:3], alpha)
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=c)
    layer = layer.filter(ImageFilter.GaussianBlur(radius=max(1, r // 3)))
    return Image.alpha_composite(im, layer)


# --- Player revenant ---
def gen_player() -> None:
    # Idle frame + attack frame + dash afterimage style
    for name, pose in [
        ("player_idle.png", "idle"),
        ("player_attack.png", "attack"),
        ("player_dash.png", "dash"),
    ]:
        im = new(64, 64)
        d = ImageDraw.Draw(im)
        cx, cy = 32, 36
        # legs
        if pose == "dash":
            d.polygon([(cx - 6, cy + 8), (cx - 14, cy + 22), (cx - 4, cy + 22)], fill=SILH)
            d.polygon([(cx + 4, cy + 10), (cx + 16, cy + 18), (cx + 8, cy + 22)], fill=SILH)
        else:
            d.polygon([(cx - 8, cy + 6), (cx - 10, cy + 24), (cx - 2, cy + 24)], fill=SILH)
            d.polygon([(cx + 2, cy + 6), (cx + 4, cy + 24), (cx + 12, cy + 24)], fill=SILH)
        # torso armor
        d.polygon(
            [(cx - 12, cy + 8), (cx + 12, cy + 8), (cx + 10, cy - 10), (cx, cy - 16), (cx - 10, cy - 10)],
            fill=IRON,
            outline=EMBER,
        )
        # ember core
        d.ellipse((cx - 4, cy - 6, cx + 4, cy + 4), fill=EMBER_DEEP)
        d.ellipse((cx - 2, cy - 4, cx + 2, cy + 1), fill=GOLD)
        # head
        d.ellipse((cx - 7, cy - 26, cx + 7, cy - 12), fill=SILH, outline=EMBER)
        # eyes
        d.rectangle((cx - 4, cy - 21, cx - 1, cy - 18), fill=EMBER)
        d.rectangle((cx + 1, cy - 21, cx + 4, cy - 18), fill=EMBER)
        # weapon
        if pose == "attack":
            d.polygon(
                [(cx + 8, cy - 4), (cx + 28, cy - 18), (cx + 26, cy - 10), (cx + 10, cy + 2)],
                fill=IRON_EDGE,
                outline=GOLD,
            )
            d.line([(cx + 10, cy), (cx + 26, cy - 14)], fill=EMBER, width=2)
        else:
            d.polygon(
                [(cx + 10, cy - 2), (cx + 14, cy - 2), (cx + 16, cy + 18), (cx + 8, cy + 18)],
                fill=IRON_EDGE,
                outline=EMBER,
            )
        im = glow_circle(im, cx, cy - 2, 18, EMBER, 40)
        save(im, f"player/{name}")


def gen_enemy(name: str, kind: str) -> None:
    im = new(64, 64)
    d = ImageDraw.Draw(im)
    cx, cy = 32, 36
    if kind == "wretch":
        # hunched small
        d.ellipse((cx - 14, cy - 4, cx + 14, cy + 18), fill=SILH, outline=EMBER_DEEP)
        d.ellipse((cx - 10, cy - 18, cx + 8, cy), fill=IRON, outline=EMBER)
        d.ellipse((cx - 6, cy - 14, cx - 2, cy - 10), fill=EMBER)  # eye
        d.polygon([(cx + 8, cy + 4), (cx + 22, cy + 10), (cx + 10, cy + 12)], fill=IRON_EDGE)  # claw
        d.polygon([(cx - 8, cy + 6), (cx - 20, cy + 12), (cx - 6, cy + 14)], fill=IRON_EDGE)
    elif kind == "archer":
        d.polygon(
            [(cx - 6, cy + 20), (cx + 6, cy + 20), (cx + 5, cy - 16), (cx - 5, cy - 16)],
            fill=IRON,
            outline=EMBER,
        )
        d.ellipse((cx - 6, cy - 26, cx + 6, cy - 14), fill=SILH, outline=EMBER)
        d.arc((cx + 4, cy - 18, cx + 28, cy + 10), 200, 340, fill=GOLD, width=3)  # bow
        d.line([(cx + 8, cy - 4), (cx + 24, cy - 4)], fill=EMBER, width=2)  # arrow
    elif kind == "guard":
        d.rectangle((cx - 14, cy - 12, cx + 8, cy + 20), fill=IRON, outline=EMBER)
        d.rectangle((cx + 6, cy - 16, cx + 20, cy + 18), fill=IRON_EDGE, outline=GOLD)  # shield
        d.ellipse((cx - 8, cy - 24, cx + 4, cy - 10), fill=SILH, outline=EMBER)
        d.rectangle((cx - 18, cy - 8, cx - 10, cy + 16), fill=IRON_EDGE)  # hammer handle
        d.ellipse((cx - 22, cy - 14, cx - 8, cy - 2), fill=EMBER_DEEP)  # hammer head
    elif kind == "boss":
        im = new(96, 96)
        d = ImageDraw.Draw(im)
        cx, cy = 48, 52
        d.polygon(
            [(cx - 28, cy + 28), (cx + 28, cy + 28), (cx + 24, cy - 8), (cx, cy - 28), (cx - 24, cy - 8)],
            fill=IRON,
            outline=EMBER,
        )
        # furnace chest
        d.ellipse((cx - 14, cy - 6, cx + 14, cy + 16), fill=EMBER_DEEP)
        d.ellipse((cx - 8, cy, cx + 8, cy + 10), fill=GOLD)
        # head
        d.ellipse((cx - 12, cy - 40, cx + 12, cy - 16), fill=SILH, outline=EMBER)
        d.rectangle((cx - 6, cy - 32, cx - 2, cy - 26), fill=EMBER)
        d.rectangle((cx + 2, cy - 32, cx + 6, cy - 26), fill=EMBER)
        # hammer arm
        d.rectangle((cx + 20, cy - 10, cx + 28, cy + 20), fill=IRON_EDGE)
        d.rectangle((cx + 12, cy - 22, cx + 36, cy - 8), fill=EMBER_DEEP, outline=GOLD)
        im = glow_circle(im, cx, cy + 4, 28, EMBER, 50)
        save(im, "enemies/boss_first_hammer.png")
        return
    im = glow_circle(im, cx, cy, 14, EMBER, 35)
    save(im, f"enemies/{name}")


def gen_tiles() -> None:
    # 64x64 tiles
    for name, fn in [
        ("tile_floor.png", _tile_floor),
        ("tile_floor_b.png", lambda: _tile_floor(seed=1)),
        ("tile_wall.png", _tile_wall),
        ("tile_lava.png", _tile_lava),
        ("tile_grate.png", _tile_grate),
        ("prop_anvil.png", _prop_anvil),
        ("prop_chain.png", _prop_chain),
    ]:
        save(fn(), f"env/{name}")


def _tile_floor(seed: int = 0) -> Image.Image:
    im = new(64, 64)
    d = ImageDraw.Draw(im)
    d.rectangle((0, 0, 63, 63), fill=IRON)
    # cracks
    for i in range(4):
        x = 8 + (i * 13 + seed * 7) % 48
        d.line([(x, 4), (x + 3, 60)], fill=COAL, width=1)
    # ember flecks
    for i in range(6):
        x = (i * 11 + seed * 3) % 60
        y = (i * 17 + seed * 5) % 60
        d.point((x, y), fill=EMBER)
    d.rectangle((0, 0, 63, 63), outline=IRON_EDGE)
    return im


def _tile_wall() -> Image.Image:
    im = new(64, 64)
    d = ImageDraw.Draw(im)
    d.rectangle((0, 0, 63, 63), fill=SILH)
    for y in (16, 32, 48):
        d.line([(0, y), (63, y)], fill=IRON_EDGE, width=2)
    d.rectangle((20, 8, 44, 56), fill=IRON, outline=EMBER)
    return im


def _tile_lava() -> Image.Image:
    im = new(64, 64)
    d = ImageDraw.Draw(im)
    d.rectangle((0, 0, 63, 63), fill=EMBER_DEEP)
    for i in range(8):
        x = i * 8
        d.ellipse((x, 10 + (i % 3) * 12, x + 14, 28 + (i % 3) * 12), fill=GOLD)
    d.rectangle((0, 0, 63, 63), outline=EMBER)
    im = im.filter(ImageFilter.GaussianBlur(0.6))
    return im.convert("RGBA")


def _tile_grate() -> Image.Image:
    im = new(64, 64)
    d = ImageDraw.Draw(im)
    d.rectangle((0, 0, 63, 63), fill=COAL)
    for i in range(0, 64, 8):
        d.line([(i, 0), (i, 63)], fill=IRON_EDGE, width=2)
        d.line([(0, i), (63, i)], fill=IRON_EDGE, width=2)
    # glow under
    for i in range(4):
        d.ellipse((10 + i * 12, 20, 20 + i * 12, 40), fill=(*EMBER_DEEP[:3], 180))
    return im


def _prop_anvil() -> Image.Image:
    im = new(64, 48)
    d = ImageDraw.Draw(im)
    d.rectangle((18, 28, 46, 44), fill=SILH)
    d.polygon([(10, 28), (54, 28), (48, 16), (16, 16)], fill=IRON, outline=EMBER)
    d.rectangle((8, 12, 24, 20), fill=IRON_EDGE)
    return im


def _prop_chain() -> Image.Image:
    im = new(16, 64)
    d = ImageDraw.Draw(im)
    for y in range(0, 64, 10):
        d.ellipse((2, y, 14, y + 12), outline=IRON_EDGE, width=2)
    return im


def gen_vfx() -> None:
    # hit spark
    im = new(32, 32)
    d = ImageDraw.Draw(im)
    cx = cy = 16
    for ang in range(0, 360, 45):
        rad = math.radians(ang)
        x2 = cx + int(14 * math.cos(rad))
        y2 = cy + int(14 * math.sin(rad))
        d.line([(cx, cy), (x2, y2)], fill=GOLD, width=2)
    d.ellipse((10, 10, 22, 22), fill=EMBER)
    save(im, "vfx/hit_spark.png")

    # perfect beat ring
    im = new(64, 64)
    d = ImageDraw.Draw(im)
    d.ellipse((4, 4, 60, 60), outline=EMBER, width=3)
    d.ellipse((12, 12, 52, 52), outline=GOLD, width=2)
    save(im, "vfx/beat_ring.png")

    # death sparks
    im = new(48, 48)
    d = ImageDraw.Draw(im)
    for i in range(12):
        ang = i * 30
        rad = math.radians(ang)
        x = 24 + int(18 * math.cos(rad))
        y = 24 + int(18 * math.sin(rad))
        d.ellipse((x - 2, y - 2, x + 2, y + 2), fill=EMBER if i % 2 == 0 else GOLD)
    save(im, "vfx/death_sparks.png")


def gen_ui() -> None:
    # heat bar fill (9-slice friendly bar segment)
    im = new(128, 16)
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((0, 0, 127, 15), radius=4, fill=EMBER_DEEP, outline=GOLD)
    for x in range(4, 124, 6):
        d.line([(x, 3), (x, 12)], fill=EMBER, width=1)
    save(im, "ui/heat_fill.png")

    im = new(128, 16)
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((0, 0, 127, 15), radius=4, fill=COAL, outline=IRON_EDGE)
    save(im, "ui/heat_bg.png")

    # beat pip
    im = new(24, 24)
    d = ImageDraw.Draw(im)
    d.ellipse((2, 2, 22, 22), fill=EMBER, outline=GOLD)
    d.ellipse((8, 8, 16, 16), fill=GOLD)
    save(im, "ui/beat_pip.png")

    # hp pip
    im = new(12, 12)
    d = ImageDraw.Draw(im)
    d.ellipse((1, 1, 11, 11), fill=EMBER_DEEP, outline=BONE)
    save(im, "ui/hp_pip.png")


def main() -> None:
    print("Generating CINDERFORGE forge-ink sprites...")
    gen_player()
    gen_enemy("wretch.png", "wretch")
    gen_enemy("archer.png", "archer")
    gen_enemy("guard.png", "guard")
    gen_enemy("boss.png", "boss")
    gen_tiles()
    gen_vfx()
    gen_ui()
    print("Done.")


if __name__ == "__main__":
    main()
