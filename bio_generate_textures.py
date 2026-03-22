#!/usr/bin/env python3
"""Generate all textures for the Lazarus Space biological dimension mod.

Requires Pillow: pip install Pillow

Produces static block textures (16x16), plantlike textures (16x16 with
transparency), and animated liquid textures (16x128, 8 frames).

Run from the mod directory:
    python3 bio_generate_textures.py
"""

import math
import os
import random
from PIL import Image

TEXTURES_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "textures")
os.makedirs(TEXTURES_DIR, exist_ok=True)
random.seed(42)


def clamp(v):
    """Clamp a value to the 0-255 range."""
    return max(0, min(255, int(v)))


# ---------------------------------------------------------------------------
# Helper: solid block with per-pixel noise
# ---------------------------------------------------------------------------

def make_solid_block(r, g, b, a=255, noise=5):
    """Create a 16x16 RGBA image filled with (r,g,b,a) plus per-pixel noise."""
    img = Image.new("RGBA", (16, 16))
    for y in range(16):
        for x in range(16):
            n = random.randint(-noise, noise)
            img.putpixel((x, y), (clamp(r + n), clamp(g + n), clamp(b + n), a))
    return img


def make_solid_block_with_spots(base_rgb, spot_rgb, spot_freq, a=255, noise=5):
    """Create a 16x16 block with scattered spots of a different color."""
    img = Image.new("RGBA", (16, 16))
    br, bg, bb = base_rgb
    sr, sg, sb = spot_rgb
    for y in range(16):
        for x in range(16):
            n = random.randint(-noise, noise)
            if random.random() < spot_freq:
                img.putpixel((x, y), (clamp(sr + n), clamp(sg + n), clamp(sb + n), a))
            else:
                img.putpixel((x, y), (clamp(br + n), clamp(bg + n), clamp(bb + n), a))
    return img


# ---------------------------------------------------------------------------
# Static block textures
# ---------------------------------------------------------------------------

STATIC_BLOCKS = [
    # (node_name, r, g, b, alpha, special)
    # special: None = plain solid, "spots" = scattered spots, "lighter" = lighter scatter
    # Structural
    ("flesh",                   139,   0,   0, 255, None),
    ("rotten_flesh",            100,  60,  30, 255, (70, 40, 20)),
    ("sinew",                   224, 192, 176, 255, None),
    ("bone",                    245, 240, 220, 255, None),
    ("enamel",                  255, 255, 240, 255, None),
    ("bone_block",              235, 225, 200, 255, None),
    ("rotten_bone",             120, 100,  50, 255, (60, 45, 25)),
    ("cartilage",               216, 232, 240, 255, None),
    # Barrier / Congealed
    ("congealed_plasma",        192,  48,  48, 255, None),
    ("congealed_rotten_plasma",  90,  74,  58, 255, None),
    ("congealed_blood",         176,  32,  32, 255, None),
    ("death_space",               0,   0,   0, 255, None),
    # Vascular / Neural / Coral
    ("vein_block",              128,   0,  16, 255, None),
    ("brain_coral",             208, 128,  96, 255, None),
    ("brain_coral_block",       192, 112,  80, 255, None),
    ("nerve_block",             224, 128, 128, 255, None),
    ("fatty_nerve",             200, 184, 184, 255, None),
    ("glowing_nerve",           160, 192, 255, 255, None),
    # Fat / Follicle
    ("fat_tissue",              180, 150,  80, 255, (140, 110, 50)),
    ("keratin",                  40,  30,  20, 255, (60, 45, 30)),
    # Cave / Shared
    ("mucus",                   160, 176,  48, 255, None),
    ("asteroid_shell",           74,  58,  48, 255, None),
    # Mushroom
    ("flesh_mushroom_stem",     180,  60,  60, 255, None),
    # Tungsten
    ("tungsten_block",          130, 135, 145, 255, None),
]


def generate_static_blocks():
    """Generate all static 16x16 block textures."""
    textures = {}
    for entry in STATIC_BLOCKS:
        name, r, g, b, a, special = entry
        filename = f"lazarus_space_{name}.png"

        if special == "lighter_scatter":
            # flesh_wet: base color with 10% lighter pixels
            img = Image.new("RGBA", (16, 16))
            for y in range(16):
                for x in range(16):
                    n = random.randint(-5, 5)
                    if random.random() < 0.10:
                        # Lighter pixel
                        img.putpixel((x, y), (
                            clamp(r + 40 + n),
                            clamp(g + 20 + n),
                            clamp(b + 20 + n),
                            a
                        ))
                    else:
                        img.putpixel((x, y), (
                            clamp(r + n), clamp(g + n), clamp(b + n), a
                        ))
        elif special == "dark_pores":
            # spongy_bone: cream with 15% darker pores
            img = make_solid_block_with_spots(
                (r, g, b), (200, 190, 170), 0.15, a=a
            )
        elif isinstance(special, tuple) and len(special) == 3:
            # Tuple of (r,g,b) = scattered spots of that color (25% frequency)
            img = make_solid_block_with_spots(
                (r, g, b), special, 0.25, a=a
            )
        else:
            img = make_solid_block(r, g, b, a=a)

        textures[filename] = img
    return textures


# ---------------------------------------------------------------------------
# Grass textures (plantlike with transparency, blade silhouettes)
# ---------------------------------------------------------------------------

GRASS_DEFS = [
    # (name, color, description of shape)
    ("bio_grass_1", (140, 30, 30), "short_single"),
    ("bio_grass_3", (130, 25, 35), "tall_triple"),
    ("bio_grass_tall", (120, 20, 20), "thick_bundle"),
]


def draw_blade(img, base_x, base_y, height, width, color, sway=0):
    """Draw a single grass blade from base upward with optional sway."""
    r, g, b = color
    for dy in range(height):
        y = base_y - dy
        if y < 0 or y >= 16:
            continue
        # Apply sway: offset x based on height
        offset = int(sway * dy / max(height, 1))
        for w in range(width):
            x = base_x + w + offset
            if 0 <= x < 16:
                n = random.randint(-5, 5)
                img.putpixel((x, y), (clamp(r + n), clamp(g + n), clamp(b + n), 255))


def generate_grass_textures():
    """Generate grass plantlike textures with transparent backgrounds."""
    textures = {}
    for name, color, style in GRASS_DEFS:
        filename = f"lazarus_space_{name}.png"
        img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))

        if style == "short_single":
            # Single blade, 4px wide, ~8px tall, centered
            draw_blade(img, 6, 15, 8, 4, color, sway=0)

        elif style == "medium_double":
            # Two blades, 12px tall
            draw_blade(img, 5, 15, 12, 2, color, sway=0)
            draw_blade(img, 9, 15, 10, 2, color, sway=1)

        elif style == "tall_triple":
            # Three blades filling 16px height
            draw_blade(img, 3, 15, 16, 2, color, sway=-1)
            draw_blade(img, 7, 15, 14, 2, color, sway=0)
            draw_blade(img, 11, 15, 13, 2, color, sway=1)

        elif style == "thick_bundle":
            # Thick bundle filling 16px
            draw_blade(img, 2, 15, 16, 3, color, sway=-1)
            draw_blade(img, 6, 15, 15, 3, color, sway=0)
            draw_blade(img, 10, 15, 14, 3, color, sway=1)

        textures[filename] = img
    return textures


# ---------------------------------------------------------------------------
# Plantlike textures (16x16 with transparency, shaped silhouettes)
# ---------------------------------------------------------------------------

def generate_mushroom_shape(color, cap_width, cap_height, stem_width, stem_height):
    """Generate a mushroom silhouette on a transparent 16x16 image."""
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    r, g, b = color
    cx = 7  # center x

    # Draw stem (bottom)
    stem_left = cx - stem_width // 2
    stem_top = 16 - stem_height
    for y in range(stem_top, 16):
        for x in range(stem_left, stem_left + stem_width):
            if 0 <= x < 16 and 0 <= y < 16:
                n = random.randint(-5, 5)
                # Slightly darker stem
                img.putpixel((x, y), (
                    clamp(r - 20 + n), clamp(g - 20 + n), clamp(b - 20 + n), 255
                ))

    # Draw cap (dome above stem)
    cap_bottom = stem_top
    cap_top = cap_bottom - cap_height
    cap_center_y = (cap_top + cap_bottom) / 2.0
    cap_rx = cap_width / 2.0
    cap_ry = cap_height / 2.0

    for y in range(max(0, cap_top), min(16, cap_bottom)):
        for x in range(16):
            # Ellipse test
            dx = (x - cx) / cap_rx
            dy = (y - cap_center_y) / cap_ry
            if dx * dx + dy * dy <= 1.0:
                n = random.randint(-5, 5)
                img.putpixel((x, y), (clamp(r + n), clamp(g + n), clamp(b + n), 255))

    return img


def generate_sprout(color):
    """Single blade, 2px wide, 10px tall, centered."""
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    r, g, b = color
    base_x = 7
    for y in range(6, 16):  # 10 pixels tall, from row 6 to 15
        for x in range(base_x, base_x + 2):
            n = random.randint(-5, 5)
            img.putpixel((x, y), (clamp(r + n), clamp(g + n), clamp(b + n), 255))
    return img


def generate_tendril(color):
    """Curving tendril, 2px wide, 14px tall, slight S-curve."""
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    r, g, b = color
    # S-curve: sine wave offset
    for row in range(14):
        y = 15 - row  # from bottom up
        # S-curve: offset from center based on sine
        t = row / 13.0
        offset = int(2.0 * math.sin(t * math.pi * 2))
        base_x = 7 + offset
        for dx in range(2):
            x = base_x + dx
            if 0 <= x < 16 and 0 <= y < 16:
                n = random.randint(-5, 5)
                img.putpixel((x, y), (clamp(r + n), clamp(g + n), clamp(b + n), 255))
    return img


def generate_polyp_plant(color):
    """Stubby Y-shape, 4px wide base splitting into 2 arms."""
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    r, g, b = color

    # Base: 4px wide, rows 10-15 (6px tall)
    for y in range(10, 16):
        for x in range(6, 10):
            n = random.randint(-5, 5)
            img.putpixel((x, y), (clamp(r + n), clamp(g + n), clamp(b + n), 255))

    # Split point at row 9
    for x in range(6, 10):
        n = random.randint(-5, 5)
        img.putpixel((x, 9), (clamp(r + n), clamp(g + n), clamp(b + n), 255))

    # Left arm: rows 4-8, drifting left
    for row_i, y in enumerate(range(8, 3, -1)):
        x_start = 5 - row_i
        for dx in range(2):
            x = x_start + dx
            if 0 <= x < 16:
                n = random.randint(-5, 5)
                img.putpixel((x, y), (clamp(r + n), clamp(g + n), clamp(b + n), 255))

    # Right arm: rows 4-8, drifting right
    for row_i, y in enumerate(range(8, 3, -1)):
        x_start = 10 + row_i
        for dx in range(2):
            x = x_start + dx
            if 0 <= x < 16:
                n = random.randint(-5, 5)
                img.putpixel((x, y), (clamp(r + n), clamp(g + n), clamp(b + n), 255))

    return img


def generate_plantlike_textures():
    """Generate all plantlike textures with transparency."""
    textures = {}

    # Glowing mushroom: dome top, thin stem bottom
    textures["lazarus_space_glowing_mushroom.png"] = generate_mushroom_shape(
        (170, 255, 128), cap_width=10, cap_height=6, stem_width=2, stem_height=8
    )

    # Bio sprout
    textures["lazarus_space_bio_sprout.png"] = generate_sprout((160, 32, 32))

    # Bio tendril
    textures["lazarus_space_bio_tendril.png"] = generate_tendril((192, 64, 96))

    # Bio polyp plant
    textures["lazarus_space_bio_polyp_plant.png"] = generate_polyp_plant((208, 96, 64))

    # Cave shroom small: 8px wide cap, 6px stem
    textures["lazarus_space_cave_shroom_small.png"] = generate_mushroom_shape(
        (160, 192, 64), cap_width=8, cap_height=4, stem_width=2, stem_height=6
    )

    # Cave shroom bright: 10px wide cap, 4px stem, bright
    textures["lazarus_space_cave_shroom_bright.png"] = generate_mushroom_shape(
        (64, 224, 160), cap_width=10, cap_height=5, stem_width=2, stem_height=4
    )

    # Cave vine: dark red-green tendril with red veins
    vine_img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    rng_vine = random.Random(77)
    for vy in range(16):
        for vx in range(6, 10):  # thin vertical strip
            n = rng_vine.randint(-5, 5)
            # Base dark green-red
            r, g, b = 50 + n, 70 + n, 40 + n
            # Red vein streaks
            if rng_vine.random() < 0.2:
                r, g, b = 100 + n, 30 + n, 20 + n
            vine_img.putpixel((vx, vy), (clamp(r), clamp(g), clamp(b), 255))
        # Slight wispy edges
        for vx in [5, 10]:
            if rng_vine.random() < 0.3:
                n = rng_vine.randint(-5, 5)
                vine_img.putpixel((vx, vy), (clamp(45 + n), clamp(60 + n), clamp(35 + n), 180))
    textures["lazarus_space_cave_vine.png"] = vine_img

    return textures


# ---------------------------------------------------------------------------
# Animated liquid textures (16x128, 8 frames of 16x16)
# ---------------------------------------------------------------------------

def generate_liquid_source(base_rgb, variation, pattern="wave"):
    """Generate an animated liquid source texture (16x128, 8 frames).

    pattern: "wave" = brightness wave with moving dark spots
             "bubble" = shifting green with bubble spots
             "cloudy" = minimal variation with cloudy spots
             "swirl" = shifting red/orange with swirl
    """
    img = Image.new("RGBA", (16, 128))
    br, bg, bb = base_rgb

    # Pre-generate some spot positions for consistency across frames
    spots = [(random.randint(0, 15), random.randint(0, 15)) for _ in range(3)]

    for frame in range(8):
        y_off = frame * 16

        # Calculate frame-specific color shift
        if pattern == "wave":
            # Brightness wave +-10
            wave = int(10 * math.sin(frame * math.pi / 4))
            fr, fg, fb = br + wave, bg + wave, bb + wave
        elif pattern == "bubble":
            # Green shift +-15
            shift = int(15 * math.sin(frame * math.pi / 4))
            fr, fg, fb = br, bg + shift, bb
        elif pattern == "cloudy":
            # Minimal +-5 brightness
            shift = int(5 * math.sin(frame * math.pi / 4))
            fr, fg, fb = br + shift, bg + shift, bb + shift
        elif pattern == "swirl":
            # Red/orange shift +-10
            rshift = int(10 * math.sin(frame * math.pi / 4))
            gshift = int(8 * math.cos(frame * math.pi / 4))
            fr, fg, fb = br + rshift, bg + gshift, bb

        for y in range(16):
            for x in range(16):
                n = random.randint(-3, 3)
                img.putpixel((x, y_off + y), (
                    clamp(fr + n), clamp(fg + n), clamp(fb + n), 220
                ))

        # Draw moving spots
        for si, (sx, sy) in enumerate(spots):
            # Spots move down by 2 per frame
            spot_y = (sy + frame * 2) % 16
            spot_x = sx
            for dy in range(-1, 2):
                for dx in range(-1, 2):
                    px = (spot_x + dx) % 16
                    py = (spot_y + dy) % 16
                    # Darken spot pixels
                    existing = img.getpixel((px, y_off + py))
                    img.putpixel((px, y_off + py), (
                        clamp(existing[0] - 20),
                        clamp(existing[1] - 20),
                        clamp(existing[2] - 20),
                        existing[3]
                    ))

    return img


def generate_liquid_flowing(base_rgb):
    """Generate an animated liquid flowing texture (16x128, 8 frames).

    Creates directional streaks that shift down 2px per frame.
    """
    img = Image.new("RGBA", (16, 128))
    br, bg, bb = base_rgb

    # Pre-generate streak positions (vertical streaks)
    streak_xs = [random.randint(0, 15) for _ in range(5)]

    for frame in range(8):
        y_off = frame * 16

        for y in range(16):
            for x in range(16):
                n = random.randint(-3, 3)
                # Add directional feel: slight brightness gradient top to bottom
                grad = int((y / 15.0) * 8 - 4)
                img.putpixel((x, y_off + y), (
                    clamp(br + n + grad),
                    clamp(bg + n + grad),
                    clamp(bb + n + grad),
                    210
                ))

        # Draw streaks that move down
        for sx in streak_xs:
            streak_start = (frame * 2) % 16
            for dy in range(6):  # 6px long streaks
                sy = (streak_start + dy) % 16
                for dx in range(-1, 1):
                    px = (sx + dx) % 16
                    existing = img.getpixel((px, y_off + sy))
                    # Lighten streaks
                    img.putpixel((px, y_off + sy), (
                        clamp(existing[0] + 15),
                        clamp(existing[1] + 15),
                        clamp(existing[2] + 15),
                        existing[3]
                    ))

    return img


LIQUID_DEFS = [
    # (name, base_rgb, source_pattern)
    ("plasma",  (96,   0,   0), "wave"),
    ("bile",     (128, 138,   0), "bubble"),
    ("pus",      (176, 168,  48), "cloudy"),
    ("marrow",   (160, 100,  32), "swirl"),
]


def generate_liquid_textures():
    """Generate all animated liquid textures."""
    textures = {}
    for name, base_rgb, pattern in LIQUID_DEFS:
        source_file = f"lazarus_space_{name}_source_animated.png"
        flowing_file = f"lazarus_space_{name}_flowing_animated.png"
        textures[source_file] = generate_liquid_source(base_rgb, 10, pattern=pattern)
        textures[flowing_file] = generate_liquid_flowing(base_rgb)
    return textures


# ---------------------------------------------------------------------------
# Warp glow textures (from existing generate_textures.py references)
# ---------------------------------------------------------------------------

def generate_warp_glow_textures():
    """Generate 4 warp glow animated textures for the portal effect."""
    textures = {}
    colors = [
        (160, 0, 0),     # Red
        (200, 40, 40),   # Brighter red
        (140, 20, 20),   # Dark red
        (180, 60, 60),   # Medium red
    ]
    for i, (cr, cg, cb) in enumerate(colors, 1):
        img = Image.new("RGBA", (16, 128))
        for frame in range(8):
            y_off = frame * 16
            phase = frame * math.pi / 4
            brightness = int(20 * math.sin(phase))
            for y in range(16):
                for x in range(16):
                    dx = x - 7.5
                    dy = y - 7.5
                    dist = math.sqrt(dx * dx + dy * dy)
                    # Radial glow falloff
                    if dist < 8:
                        intensity = 1.0 - (dist / 8.0)
                        alpha = int(200 * intensity)
                    else:
                        alpha = 0
                    n = random.randint(-3, 3)
                    img.putpixel((x, y_off + y), (
                        clamp(cr + brightness + n),
                        clamp(cg + brightness + n),
                        clamp(cb + brightness + n),
                        clamp(alpha)
                    ))
        textures[f"lazarus_space_warp_glow_{i}.png"] = img
    return textures


# ---------------------------------------------------------------------------
# Skybox textures (128x128)
# ---------------------------------------------------------------------------

def generate_skybox_textures():
    """Generate 6 skybox face textures for the red twilight biological dimension."""
    textures = {}
    size = 128

    # Top: deep dark red, nearly black
    rng = random.Random(42)
    img = Image.new("RGBA", (size, size))
    for y in range(size):
        for x in range(size):
            n = rng.randint(-5, 5)
            img.putpixel((x, y), (clamp(30 + n), clamp(5 + n), clamp(5 + n), 255))
    textures["lazarus_space_sky_top.png"] = img

    # Bottom: very dark red-brown
    rng = random.Random(46)
    img = Image.new("RGBA", (size, size))
    for y in range(size):
        for x in range(size):
            n = rng.randint(-5, 5)
            img.putpixel((x, y), (clamp(25 + n), clamp(8 + n), clamp(3 + n), 255))
    textures["lazarus_space_sky_bottom.png"] = img

    # Side faces: vertical gradient with horizontal streaks
    side_names = ["front", "back", "left", "right"]
    side_seeds = [42, 43, 44, 45]

    # Gradient colors (top -> horizon -> bottom)
    top_r, top_g, top_b = 40, 8, 8
    mid_r, mid_g, mid_b = 80, 25, 10
    bot_r, bot_g, bot_b = 35, 10, 5

    for side_name, seed in zip(side_names, side_seeds):
        rng = random.Random(seed)
        img = Image.new("RGBA", (size, size))

        # Pre-generate streak positions: 5-10 horizontal streaks
        num_streaks = rng.randint(5, 10)
        streaks = []
        for _ in range(num_streaks):
            sy = rng.randint(0, size - 1)
            sx_start = rng.randint(0, size // 3)
            sx_end = rng.randint(size // 3, size - 1)
            s_height = rng.randint(1, 2)
            s_brightness = rng.randint(5, 10)
            streaks.append((sy, sx_start, sx_end, s_height, s_brightness))

        horizon = size // 2  # vertical center

        for y in range(size):
            # Compute gradient
            if y <= horizon:
                frac = y / horizon
                r = top_r + (mid_r - top_r) * frac
                g = top_g + (mid_g - top_g) * frac
                b = top_b + (mid_b - top_b) * frac
            else:
                frac = (y - horizon) / (size - 1 - horizon)
                r = mid_r + (bot_r - mid_r) * frac
                g = mid_g + (bot_g - mid_g) * frac
                b = mid_b + (bot_b - mid_b) * frac

            for x in range(size):
                n = rng.randint(-5, 5)
                sr, sg, sb = 0, 0, 0
                # Check if pixel falls on a streak
                for sy, sx_start, sx_end, s_height, s_brightness in streaks:
                    if sy <= y < sy + s_height and sx_start <= x <= sx_end:
                        sr = s_brightness
                        sg = s_brightness // 3
                        sb = s_brightness // 4
                        break
                img.putpixel((x, y), (
                    clamp(int(r) + n + sr),
                    clamp(int(g) + n + sg),
                    clamp(int(b) + n + sb),
                    255
                ))

        textures[f"lazarus_space_sky_{side_name}.png"] = img

    return textures


# ---------------------------------------------------------------------------
# Tungsten textures (ore with specks, inventory items)
# ---------------------------------------------------------------------------

def generate_tungsten_textures():
    """Generate tungsten ore texture and inventory item images."""
    textures = {}

    # Tungsten ore: dark grey base with metallic blue-grey specks
    img = Image.new("RGBA", (16, 16))
    for y in range(16):
        for x in range(16):
            n = random.randint(-4, 4)
            if random.random() < 0.15:
                # Metallic blue-grey specks
                img.putpixel((x, y), (
                    clamp(140 + n + random.randint(-10, 10)),
                    clamp(145 + n + random.randint(-10, 10)),
                    clamp(160 + n + random.randint(-5, 15)),
                    255
                ))
            else:
                # Dark grey host rock
                img.putpixel((x, y), (
                    clamp(70 + n), clamp(70 + n), clamp(75 + n), 255
                ))
    textures["lazarus_space_tungsten_ore.png"] = img

    # Tungsten lump: small rough nugget on transparent background
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    # Draw an irregular nugget shape (centered, ~8x7 pixels)
    nugget_pixels = [
        (5, 6), (6, 6), (7, 6), (8, 6), (9, 6),
        (4, 7), (5, 7), (6, 7), (7, 7), (8, 7), (9, 7), (10, 7),
        (4, 8), (5, 8), (6, 8), (7, 8), (8, 8), (9, 8), (10, 8), (11, 8),
        (5, 9), (6, 9), (7, 9), (8, 9), (9, 9), (10, 9),
        (5, 10), (6, 10), (7, 10), (8, 10), (9, 10), (10, 10),
        (6, 11), (7, 11), (8, 11), (9, 11),
    ]
    for px, py in nugget_pixels:
        n = random.randint(-8, 8)
        # Highlight top-left for 3D effect
        if py <= 8 and px <= 7:
            img.putpixel((px, py), (clamp(160 + n), clamp(165 + n), clamp(175 + n), 255))
        else:
            img.putpixel((px, py), (clamp(100 + n), clamp(105 + n), clamp(115 + n), 255))
    textures["lazarus_space_tungsten_lump.png"] = img

    # Tungsten ingot: refined bar on transparent background
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    # Draw a bar shape (wider than tall, centered)
    for py in range(6, 12):
        for px in range(2, 14):
            n = random.randint(-5, 5)
            # Top face highlight (rows 6-7)
            if py <= 7:
                img.putpixel((px, py), (clamp(180 + n), clamp(185 + n), clamp(195 + n), 255))
            # Front face (rows 8-11)
            elif py <= 9:
                img.putpixel((px, py), (clamp(140 + n), clamp(145 + n), clamp(155 + n), 255))
            else:
                img.putpixel((px, py), (clamp(120 + n), clamp(125 + n), clamp(135 + n), 255))
    textures["lazarus_space_tungsten_ingot.png"] = img

    return textures


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    textures = {}

    # Static block textures
    print("Generating static block textures...")
    static = generate_static_blocks()
    textures.update(static)
    for name in sorted(static.keys()):
        print(f"  {name}")

    # Grass textures (plantlike with transparency)
    print("\nGenerating grass textures...")
    grass = generate_grass_textures()
    textures.update(grass)
    for name in sorted(grass.keys()):
        print(f"  {name}")

    # Plantlike textures
    print("\nGenerating plantlike textures...")
    plantlike = generate_plantlike_textures()
    textures.update(plantlike)
    for name in sorted(plantlike.keys()):
        print(f"  {name}")

    # Animated liquid textures
    print("\nGenerating animated liquid textures...")
    liquids = generate_liquid_textures()
    textures.update(liquids)
    for name in sorted(liquids.keys()):
        print(f"  {name}")

    # Tungsten textures (ore, lump, ingot)
    print("\nGenerating tungsten textures...")
    tungsten = generate_tungsten_textures()
    textures.update(tungsten)
    for name in sorted(tungsten.keys()):
        print(f"  {name}")

    # Skybox textures (128x128)
    print("\nGenerating skybox textures...")
    skybox = generate_skybox_textures()
    textures.update(skybox)
    for name in sorted(skybox.keys()):
        print(f"  {name}")

    # Save all textures
    print(f"\nSaving {len(textures)} textures to {TEXTURES_DIR}...")
    for name, img in sorted(textures.items()):
        path = os.path.join(TEXTURES_DIR, name)
        img.save(path)
        w, h = img.size
        frames = h // 16
        if frames > 1:
            print(f"  Saved {name} ({w}x{h}, {frames} frames)")
        else:
            print(f"  Saved {name} ({w}x{h})")

    print(f"\nDone! {len(textures)} textures generated in {TEXTURES_DIR}")


if __name__ == "__main__":
    main()
