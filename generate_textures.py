#!/usr/bin/env python3
"""Generate all textures for the Lazarus Space mod.

Requires Pillow: pip install Pillow

Produces 5 device textures (16x16) and 3 animated textures (16x128, 8 frames).
"""

import math
import os
import random
from PIL import Image

TEXTURES_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "textures")
os.makedirs(TEXTURES_DIR, exist_ok=True)
random.seed(42)


def clamp(v):
    return max(0, min(255, int(v)))


# ---- Device textures (16x16) ----

def generate_disrupter_top():
    img = Image.new("RGBA", (16, 16))
    for y in range(16):
        for x in range(16):
            r, g, b = 40, 42, 48
            if x % 4 == 0 or y % 4 == 0:
                r -= 8; g -= 8; b -= 8
            if (x in (2, 3, 12, 13)) and (y in (2, 3, 12, 13)):
                r -= 12; g -= 10; b -= 6
            dx, dy = abs(x - 7.5), abs(y - 7.5)
            if dx < 2 and dy < 2:
                r += 12; g += 15; b += 25
            n = random.randint(-4, 4)
            img.putpixel((x, y), (clamp(r+n), clamp(g+n), clamp(b+n), 255))
    return img


def generate_disrupter_bottom():
    img = Image.new("RGBA", (16, 16))
    for y in range(16):
        for x in range(16):
            r, g, b = 30, 32, 36
            if x == 0 or x == 15 or y == 0 or y == 15:
                r -= 8; g -= 8; b -= 8
            dx = x - 7.5; dy = y - 7.5
            dist = (dx*dx + dy*dy) ** 0.5
            if dist < 3:
                r += 18; g += 12; b += 6
            elif dist < 4:
                r -= 6; g -= 6; b -= 6
            n = random.randint(-3, 3)
            img.putpixel((x, y), (clamp(r+n), clamp(g+n), clamp(b+n), 255))
    return img


def generate_disrupter_side():
    img = Image.new("RGBA", (16, 16))
    for y in range(16):
        for x in range(16):
            r, g, b = 45, 47, 54
            if y == 0 or y == 15:
                r -= 12; g -= 12; b -= 12
            if x == 5 or x == 10:
                r -= 10; g -= 10; b -= 10
            if y == 8:
                r -= 5; g -= 5; b -= 5
            n = random.randint(-3, 3)
            img.putpixel((x, y), (clamp(r+n), clamp(g+n), clamp(b+n), 255))
    return img


def generate_disrupter_front():
    img = Image.new("RGBA", (16, 16))
    for y in range(16):
        for x in range(16):
            r, g, b = 45, 47, 54
            if x == 0 or x == 15 or y == 0 or y == 15:
                r -= 12; g -= 12; b -= 12
            if 3 <= x <= 12 and 2 <= y <= 6:
                r, g, b = 22, 24, 28
                if y == 3 or y == 5:
                    r += 4; g += 4; b += 6
            dx = x - 7.5; dy = y - 10.5
            if dx*dx + dy*dy < 4:
                r, g, b = 26, 28, 30
            if 3 <= x <= 12 and 13 <= y <= 14:
                r -= 6; g -= 6; b -= 4
            n = random.randint(-2, 2)
            img.putpixel((x, y), (clamp(r+n), clamp(g+n), clamp(b+n), 255))
    return img


def generate_disrupter_front_active():
    img = Image.new("RGBA", (16, 16))
    for y in range(16):
        for x in range(16):
            r, g, b = 45, 47, 54
            if x == 0 or x == 15 or y == 0 or y == 15:
                r -= 12; g -= 12; b -= 12
            if 3 <= x <= 12 and 2 <= y <= 6:
                r, g, b = 18, 70, 110
                if y == 3 or y == 5:
                    r += 12; g += 35; b += 45
                cx = abs(x - 7.5)
                if cx < 3:
                    r += 8; g += 18; b += 25
            dx = x - 7.5; dy = y - 10.5
            dist = (dx*dx + dy*dy) ** 0.5
            if dist < 2:
                r, g, b = 45, 190, 230
            elif dist < 3:
                r, g, b = 25, 110, 150
            if 3 <= x <= 12 and 13 <= y <= 14:
                g += 8; b += 12
            cx2 = abs(x - 7.5); cy2 = abs(y - 7.5)
            gd = (cx2*cx2 + cy2*cy2) ** 0.5
            if gd < 7:
                glow = int((7 - gd) * 1.2)
                g += glow; b += int(glow * 1.4)
            n = random.randint(-2, 2)
            img.putpixel((x, y), (clamp(r+n), clamp(g+n), clamp(b+n), 255))
    return img


# ---- Animated textures (16x128, 8 frames) ----

def generate_disrupted_space():
    """Dark starfield void, 8 frames with slow star drift."""
    img = Image.new("RGBA", (16, 128))
    # Generate base star positions, shift slightly per frame.
    stars = [(random.randint(0, 15), random.randint(0, 15),
              random.randint(180, 255),
              random.choice([(255, 255, 255), (180, 200, 255), (200, 220, 255)]))
             for _ in range(12)]

    for frame in range(8):
        y_off = frame * 16
        # Black base.
        for y in range(16):
            for x in range(16):
                r, g, b = 2, 2, 5
                n = random.randint(0, 3)
                img.putpixel((x, y_off + y), (r + n, g + n, b + n, 255))
        # Stars with slight drift per frame.
        for sx, sy, brightness, color in stars:
            fx = (sx + frame // 3) % 16
            fy = (sy + frame // 4) % 16
            cr = int(color[0] * brightness / 255)
            cg = int(color[1] * brightness / 255)
            cb = int(color[2] * brightness / 255)
            img.putpixel((fx, y_off + fy), (cr, cg, cb, 255))
        # A few dim background stars.
        for _ in range(5):
            bx = random.randint(0, 15)
            by = random.randint(0, 15)
            bv = random.randint(30, 80)
            img.putpixel((bx, y_off + by), (bv, bv, bv + 10, 255))
    return img


def generate_decaying_uranium():
    """Bright yellow-green crackling energy, 8 frames."""
    img = Image.new("RGBA", (16, 128))

    for frame in range(8):
        y_off = frame * 16
        for y in range(16):
            for x in range(16):
                # Bright yellow-green base.
                r = random.randint(200, 255)
                g = random.randint(220, 255)
                b = random.randint(20, 80)
                # Energy crackling pattern.
                if random.random() < 0.15:
                    r = 255; g = 255; b = random.randint(180, 255)
                if random.random() < 0.08:
                    r = random.randint(100, 180)
                    g = random.randint(200, 255)
                    b = random.randint(0, 40)
                img.putpixel((x, y_off + y), (clamp(r), clamp(g), clamp(b), 255))
    return img


def generate_lazarus_portal():
    """Pure black void — solid 16x16, no animation."""
    img = Image.new("RGBA", (16, 16))
    for y in range(16):
        for x in range(16):
            img.putpixel((x, y), (0, 0, 0, 255))
    return img


def generate_star_near():
    """Bright white star dot with soft falloff, 8x8."""
    img = Image.new("RGBA", (8, 8))
    cx, cy = 3.5, 3.5
    for y in range(8):
        for x in range(8):
            dx, dy = x - cx, y - cy
            dist = (dx * dx + dy * dy) ** 0.5
            if dist < 1.0:
                alpha, bri = 255, 255
            elif dist < 3.5:
                t = (dist - 1.0) / 2.5
                alpha = int(255 * (1 - t))
                bri = int(255 * (1 - t * 0.3))
            else:
                alpha, bri = 0, 0
            img.putpixel((x, y), (bri, bri, min(255, bri + 10), alpha))
    return img


def generate_star_far():
    """Dimmer blue-tinted star dot, 8x8."""
    img = Image.new("RGBA", (8, 8))
    cx, cy = 3.5, 3.5
    for y in range(8):
        for x in range(8):
            dx, dy = x - cx, y - cy
            dist = (dx * dx + dy * dy) ** 0.5
            if dist < 1.2:
                alpha, bri = 160, 200
            elif dist < 3.5:
                t = (dist - 1.2) / 2.3
                alpha = int(160 * (1 - t))
                bri = int(200 * (1 - t * 0.4))
            else:
                alpha, bri = 0, 0
            img.putpixel((x, y), (int(bri * 0.85), int(bri * 0.9), bri, alpha))
    return img


def generate_star_nebula():
    """Pale purple/blue nebula glow, 8x8."""
    img = Image.new("RGBA", (8, 8))
    cx, cy = 3.5, 3.5
    for y in range(8):
        for x in range(8):
            dx, dy = x - cx, y - cy
            dist = (dx * dx + dy * dy) ** 0.5
            if dist < 1.5:
                alpha = 100
            elif dist < 4.0:
                alpha = int(100 * (1 - (dist - 1.5) / 2.5))
            else:
                alpha = 0
            img.putpixel((x, y), (120, 80, 180, alpha))
    return img


def generate_progress_bg():
    """Dark grey progress bar background, 256x16."""
    img = Image.new("RGBA", (256, 16))
    for y in range(16):
        for x in range(256):
            # 1px border in lighter grey.
            if x == 0 or x == 255 or y == 0 or y == 15:
                r, g, b = 0x33, 0x33, 0x33
            else:
                r, g, b = 0x1a, 0x1a, 0x1a
            img.putpixel((x, y), (r, g, b, 255))
    return img


def generate_progress_fill():
    """Teal-to-cyan gradient progress bar fill, 256x16."""
    img = Image.new("RGBA", (256, 16))
    for y in range(16):
        for x in range(256):
            t = x / 255.0
            # Deep teal (#006666) to bright cyan (#00ffcc).
            r = 0
            g = int(0x66 + t * (0xff - 0x66))
            b = int(0x66 + t * (0xcc - 0x66))
            # Slight rounded corners (skip corner pixels).
            if (x <= 1 or x >= 254) and (y == 0 or y == 15):
                img.putpixel((x, y), (0, 0, 0, 0))
            else:
                img.putpixel((x, y), (r, g, b, 255))
    return img


def generate_particle_black():
    """Soft black circle particle, 8x8."""
    img = Image.new("RGBA", (8, 8))
    cx, cy = 3.5, 3.5
    for y in range(8):
        for x in range(8):
            dx, dy = x - cx, y - cy
            dist = (dx * dx + dy * dy) ** 0.5
            if dist < 1.5:
                alpha = 255
            elif dist < 3.5:
                t = (dist - 1.5) / 2.0
                alpha = int(255 * (1 - t))
            else:
                alpha = 0
            img.putpixel((x, y), (0, 0, 0, alpha))
    return img


def generate_particle_white():
    """Soft white circle particle, 8x8."""
    img = Image.new("RGBA", (8, 8))
    cx, cy = 3.5, 3.5
    for y in range(8):
        for x in range(8):
            dx, dy = x - cx, y - cy
            dist = (dx * dx + dy * dy) ** 0.5
            if dist < 1.5:
                alpha = 255
            elif dist < 3.5:
                t = (dist - 1.5) / 2.0
                alpha = int(255 * (1 - t))
            else:
                alpha = 0
            img.putpixel((x, y), (255, 255, 255, alpha))
    return img


def generate_pole_field():
    """Orange industrial metal panel, 16x16. Beveled border, 4x4 subdivision
    grid, rivet dots, brushed metal gradient."""
    img = Image.new("RGBA", (16, 16))
    for y in range(16):
        for x in range(16):
            # Base orange with vertical gradient (lighter top, darker bottom)
            grad = 1.0 - y / 30.0  # subtle top-to-bottom darkening
            r = clamp(int(232 * grad))
            g = clamp(int(100 * grad))
            b = clamp(int(0 * grad + 10))

            # 1px beveled outer border
            if x == 0 or y == 0:
                r = clamp(r + 30); g = clamp(g + 15)  # highlight
            if x == 15 or y == 15:
                r = clamp(r - 40); g = clamp(g - 20)  # shadow

            # 4x4 subdivision grid lines (slightly darker orange)
            if x % 4 == 0 or y % 4 == 0:
                r = clamp(r - 25); g = clamp(g - 12); b = clamp(b - 5)

            # Rivet dots at grid intersections
            if x % 4 == 0 and y % 4 == 0:
                r = clamp(r + 40); g = clamp(g + 25); b = clamp(b + 10)

            # Noise for brushed metal feel
            n = random.randint(-8, 8)
            img.putpixel((x, y), (clamp(r+n), clamp(g+n), clamp(b+n), 255))
    return img


def generate_steel_block():
    """Smooth grey metallic block, 16x16. Matches the default:steelblock
    appearance — uniform light grey with subtle bevel and minimal noise."""
    img = Image.new("RGBA", (16, 16))
    for y in range(16):
        for x in range(16):
            # Light grey base (~#c8c8c8), nearly uniform
            r, g, b = 200, 200, 200

            # Subtle 1px bevel border
            if x == 0 or y == 0:
                r = clamp(r + 15); g = clamp(g + 15); b = clamp(b + 15)
            if x == 15 or y == 15:
                r = clamp(r - 20); g = clamp(g - 20); b = clamp(b - 20)

            # Very subtle noise for smooth brushed metal
            n = random.randint(-3, 3)
            img.putpixel((x, y), (clamp(r+n), clamp(g+n), clamp(b+n), 255))
    return img


def generate_toroid_field():
    """Cyan energy containment panel, 16x16. Semi-translucent glassy look
    with glowing cross pattern and diagonal highlight."""
    img = Image.new("RGBA", (16, 16))
    for y in range(16):
        for x in range(16):
            # Deep teal base
            r, g, b = 0, 0x66, 0x66

            # Bright cyan cross pattern in center (fading to edges)
            cx = abs(x - 7.5)
            cy = abs(y - 7.5)
            # Vertical line
            if cx < 1.5:
                fade = max(0, 1.0 - cy / 8.0)
                r += int(0 * fade)
                g += int(0x99 * fade)
                b += int(0x88 * fade)
            # Horizontal line
            if cy < 1.5:
                fade = max(0, 1.0 - cx / 8.0)
                r += int(0 * fade)
                g += int(0x99 * fade)
                b += int(0x88 * fade)

            # Corners darker
            corner_dist = min(cx, cy)
            if cx > 5 and cy > 5:
                r = clamp(r - 20); g = clamp(g - 20); b = clamp(b - 20)

            # 1px bright cyan border
            if x == 0 or x == 15 or y == 0 or y == 15:
                r, g, b = 0, 0xff, 0xee

            # Diagonal highlight streak (top-left to center)
            if abs(x - y) < 2 and x < 9:
                r = clamp(r + 20); g = clamp(g + 40); b = clamp(b + 35)

            n = random.randint(-5, 5)
            img.putpixel((x, y), (clamp(r+n), clamp(g+n), clamp(b+n), 200))
    return img


def generate_plasma_field():
    """Green glowing plasma conduit, 16x16. Dark green base with bright
    plasma streaks, tube walls, and spark speckles."""
    img = Image.new("RGBA", (16, 16))
    for y in range(16):
        for x in range(16):
            # Dark green base
            r, g, b = 0x1a, 0x66, 0x1a

            # Vertical gradient: center brightest, top/bottom darker (tube shape)
            cy = abs(y - 7.5)
            tube_bright = max(0, 1.0 - cy / 7.5)
            g = clamp(g + int(0x60 * tube_bright))
            r = clamp(r + int(0x10 * tube_bright))

            # 2px dark border on top and bottom (tube walls)
            if y < 2 or y > 13:
                r, g, b = 0x0d, 0x33, 0x0d

            # Plasma streaks (3-4 wavy horizontal lines)
            for streak_y in [4, 7, 10, 12]:
                wave = int(1.5 * (((x + streak_y * 3) % 7) / 7.0 - 0.5))
                if abs(y - streak_y - wave) < 1:
                    brightness = 0.7 + 0.3 * random.random()
                    r = clamp(int(0x44 * brightness))
                    g = clamp(int(0xff * brightness))
                    b = clamp(int(0x44 * brightness))

            # White/light green speckles for sparking plasma
            if random.random() < 0.06 and 2 <= y <= 13:
                r, g, b = 0xaa, 0xff, 0xaa

            n = random.randint(-4, 4)
            img.putpixel((x, y), (clamp(r+n), clamp(g+n), clamp(b+n), 255))
    return img


def generate_pole_corrector():
    """Purple high-energy core, 16x16. Concentric rings radiating from
    bright center with purple-to-dark gradient."""
    img = Image.new("RGBA", (16, 16))
    cx, cy = 7.5, 7.5
    for y in range(16):
        for x in range(16):
            dx = x - cx
            dy = y - cy
            dist = (dx*dx + dy*dy) ** 0.5

            # Dark purple background with radial gradient
            fade = min(1.0, dist / 10.0)
            r = clamp(int(0x33 + (0x33 - 0x33) * fade))
            g = clamp(int(0x11 + (0x11 - 0x11) * fade))
            b = clamp(int(0x55 + (0x55 - 0x55) * fade))

            # Base: dark purple
            r, g, b = 0x33, 0x11, 0x55

            # 3 concentric rings (bright magenta)
            for ring_r in [2.5, 4.5, 6.5]:
                if abs(dist - ring_r) < 0.7:
                    ring_bright = 1.0 - abs(dist - ring_r) / 0.7
                    r = clamp(int(r + 0x99 * ring_bright))
                    g = clamp(int(g + 0x33 * ring_bright))
                    b = clamp(int(b + 0xaa * ring_bright))

            # Bright center (2x2 pixels)
            if 7 <= x <= 8 and 7 <= y <= 8:
                r, g, b = 0xff, 0xaa, 0xff

            # Outermost 1px border
            if x == 0 or x == 15 or y == 0 or y == 15:
                r, g, b = 0x66, 0x22, 0x88

            # Radial gradient overlay (center brighter)
            center_bright = max(0, 1.0 - dist / 9.0) * 0.3
            r = clamp(int(r + 80 * center_bright))
            g = clamp(int(g + 30 * center_bright))
            b = clamp(int(b + 90 * center_bright))

            n = random.randint(-3, 3)
            img.putpixel((x, y), (clamp(r+n), clamp(g+n), clamp(b+n), 255))
    return img


def generate_fusion_control_panel():
    """Pink/magenta control interface, 16x16. Dark grey screen face with
    magenta border, status LEDs, display lines, and button grid."""
    img = Image.new("RGBA", (16, 16))
    for y in range(16):
        for x in range(16):
            # Dark grey base (screen/panel face)
            r, g, b = 0x22, 0x22, 0x22

            # 2px magenta border
            if x < 2 or x > 13 or y < 2 or y > 13:
                r, g, b = 0xcc, 0x33, 0x99

            # Top third: status LED dots (y=3..5)
            if 3 <= y <= 4 and 2 < x < 14:
                # 4 tiny indicator dots
                if x == 4:  # green
                    r, g, b = 0x00, 0xcc, 0x00
                elif x == 6:  # yellow
                    r, g, b = 0xcc, 0xcc, 0x00
                elif x == 8:  # red
                    r, g, b = 0xcc, 0x00, 0x00
                elif x == 10:  # blue
                    r, g, b = 0x00, 0x66, 0xcc

            # Middle section: display readout lines (y=6..8)
            if y == 7 and 3 <= x <= 12:
                r, g, b = 0x88, 0x22, 0x66
            if y == 9 and 3 <= x <= 12:
                r, g, b = 0x88, 0x22, 0x66

            # Bottom third: button grid (y=11..13)
            if 11 <= y <= 13 and 2 < x < 14:
                # 3x2 grid of tiny dark squares
                bx = (x - 3) % 4
                by = (y - 11)
                if bx < 3 and by < 2:
                    r, g, b = 0x11, 0x11, 0x11

            n = random.randint(-2, 2)
            img.putpixel((x, y), (clamp(r+n), clamp(g+n), clamp(b+n), 255))
    return img


def generate_plasma_jumpstarter():
    """Yellow heavy-duty power input, 16x16. Dark yellow-brown base with
    bright yellow chevron, conductor bars, and metallic highlights."""
    img = Image.new("RGBA", (16, 16))
    for y in range(16):
        for x in range(16):
            # Dark yellow-brown base
            r, g, b = 0x66, 0x55, 0x00

            # Corner pixels darker (industrial housing)
            if (x < 2 or x > 13) and (y < 2 or y > 13):
                r = clamp(r - 20); g = clamp(g - 20); b = clamp(b - 5)

            # 1px dark brown border
            if x == 0 or x == 15 or y == 0 or y == 15:
                r, g, b = 0x44, 0x33, 0x00

            # Two horizontal bright yellow conductor bars (top and bottom)
            if (2 <= y <= 3 or 12 <= y <= 13) and 1 <= x <= 14:
                r, g, b = 0xff, 0xcc, 0x00
                # Metallic sheen highlights
                if x % 4 == 0:
                    r, g, b = 0xff, 0xff, 0xaa

            # Upward-pointing chevron/arrow in center
            # Arrow shape: gets narrower as y decreases
            arrow_center = 7.5
            if 5 <= y <= 10:
                half_width = (10 - y) * 0.5 + 0.5
                if abs(x - arrow_center) < half_width:
                    r, g, b = 0xff, 0xcc, 0x00
                # Arrow outline
                if abs(abs(x - arrow_center) - half_width) < 0.8:
                    r = clamp(r + 30); g = clamp(g + 20)

            n = random.randint(-5, 5)
            img.putpixel((x, y), (clamp(r+n), clamp(g+n), clamp(b+n), 255))
    return img


def generate_fusion_power_output():
    """Brown power output transformer, 16x16. Dark brown base with copper
    coil pattern (concentric squares), output bus bars, and contact points."""
    img = Image.new("RGBA", (16, 16))
    for y in range(16):
        for x in range(16):
            # Dark brown base
            r, g, b = 0x44, 0x22, 0x00

            # 1px dark border
            if x == 0 or x == 15 or y == 0 or y == 15:
                r, g, b = 0x33, 0x18, 0x00

            # Two bright orange horizontal bus bars (top and bottom)
            if (1 <= y <= 2 or 13 <= y <= 14) and 1 <= x <= 14:
                r, g, b = 0xff, 0x88, 0x00

            # Concentric square coil rings in center (copper/orange)
            cx, cy_c = abs(x - 7.5), abs(y - 7.5)
            max_d = max(cx, cy_c)  # Chebyshev distance
            # 3 nested squares at distances 2, 3.5, 5
            for ring_d in [2.0, 3.5, 5.0]:
                if abs(max_d - ring_d) < 0.6:
                    r, g, b = 0xcc, 0x66, 0x00

            # Bright spots at coil corners (electrical contacts)
            for sq in [2, 4, 6]:
                for cx2, cy2 in [(7.5-sq, 7.5-sq), (7.5+sq, 7.5-sq),
                                 (7.5-sq, 7.5+sq), (7.5+sq, 7.5+sq)]:
                    if abs(x - cx2) < 0.8 and abs(y - cy2) < 0.8:
                        r = clamp(r + 60); g = clamp(g + 40); b = clamp(b + 20)

            n = random.randint(-4, 4)
            img.putpixel((x, y), (clamp(r+n), clamp(g+n), clamp(b+n), 255))
    return img


def generate_reactor_guide():
    """Book with teal reactor accent, 16x16."""
    img = Image.new("RGBA", (16, 16))
    for y in range(16):
        for x in range(16):
            # Default transparent
            r, g, b, a = 0, 0, 0, 0

            # Book silhouette (x=2..14, y=1..14)
            if 2 <= x <= 14 and 1 <= y <= 14:
                r, g, b, a = 0x33, 0x33, 0x33, 255

            # Spine (left 2px of book)
            if 2 <= x <= 3 and 1 <= y <= 14:
                r, g, b, a = 0x22, 0x22, 0x22, 255

            # Page edges (right side, 1px lighter)
            if x == 4 and 2 <= y <= 13:
                r, g, b, a = 0x55, 0x55, 0x55, 255

            # Teal border inset on cover (right, top, bottom)
            if 5 <= x <= 14 and 1 <= y <= 14:
                # Top border
                if y == 2 and 6 <= x <= 13:
                    r, g, b = 0x00, 0xcc, 0xaa
                # Bottom border
                if y == 13 and 6 <= x <= 13:
                    r, g, b = 0x00, 0xcc, 0xaa
                # Right border
                if x == 13 and 3 <= y <= 12:
                    r, g, b = 0x00, 0xcc, 0xaa

            # Reactor cross/plus symbol in center of cover (3x3 with corners empty)
            cx, cy = 9, 8
            if (x == cx and cy - 1 <= y <= cy + 1) or \
               (y == cy and cx - 1 <= x <= cx + 1):
                if not (abs(x - cx) == 1 and abs(y - cy) == 1):
                    r, g, b = 0x00, 0xcc, 0xaa

            # Title accent (bright teal 2px line near top)
            if y == 4 and 7 <= x <= 11:
                r, g, b = 0x00, 0xff, 0xcc

            if a > 0:
                n = random.randint(-2, 2)
                img.putpixel((x, y), (clamp(r+n), clamp(g+n), clamp(b+n), a))

    return img


def generate_portal_guide():
    """Book with purple/teal portal accent, 16x16."""
    img = Image.new("RGBA", (16, 16))
    for y in range(16):
        for x in range(16):
            # Default transparent
            r, g, b, a = 0, 0, 0, 0

            # Book silhouette (x=2..14, y=1..14)
            if 2 <= x <= 14 and 1 <= y <= 14:
                r, g, b, a = 0x1a, 0x0d, 0x2e, 255  # dark purple

            # Spine (left 2px of book)
            if 2 <= x <= 3 and 1 <= y <= 14:
                r, g, b, a = 0x11, 0x08, 0x22, 255

            # Page edges (right side, 1px lighter)
            if x == 4 and 2 <= y <= 13:
                r, g, b, a = 0x33, 0x22, 0x44, 255

            # Teal border inset on cover
            if 5 <= x <= 14 and 1 <= y <= 14:
                if y == 2 and 6 <= x <= 13:
                    r, g, b = 0x00, 0xcc, 0xaa
                if y == 13 and 6 <= x <= 13:
                    r, g, b = 0x00, 0xcc, 0xaa
                if x == 13 and 3 <= y <= 12:
                    r, g, b = 0x00, 0xcc, 0xaa

            # Portal spiral in center of cover
            cx, cy = 9, 8
            dx, dy = x - cx, y - cy
            dist = math.sqrt(dx * dx + dy * dy)
            if 1.0 < dist < 4.0:
                angle = math.atan2(dy, dx)
                spiral = (angle + dist * 0.8) % (2 * math.pi)
                if spiral < math.pi * 0.7:
                    bright = max(0, 1.0 - abs(dist - 2.5) / 1.5)
                    r = clamp(int(0x00 + 0x33 * bright))
                    g = clamp(int(0xcc * bright))
                    b = clamp(int(0xee * bright))
            # Bright center dot
            if dist < 1.2:
                r, g, b = 0x44, 0xff, 0xcc

            # Star dots on cover
            for sx, sy in [(7, 5), (11, 6), (8, 11), (12, 10)]:
                if x == sx and y == sy:
                    r, g, b = 0xcc, 0xcc, 0xff

            # Title accent (teal line near top)
            if y == 4 and 7 <= x <= 11:
                r, g, b = 0x00, 0xff, 0xcc

            if a > 0:
                n = random.randint(-2, 2)
                img.putpixel((x, y), (clamp(r+n), clamp(g+n), clamp(b+n), a))

    return img


def generate_grid_empty():
    """16x16 dark solid fill for empty slots on inactive layers."""
    img = Image.new("RGBA", (16, 16))
    for y in range(16):
        for x in range(16):
            if x == 0 or x == 15 or y == 0 or y == 15:
                # Subtle grey border
                img.putpixel((x, y), (0x44, 0x44, 0x50, 255))
            else:
                # Dark charcoal fill — visible but dim
                img.putpixel((x, y), (0x1a, 0x1a, 0x22, 255))
    return img


def generate_grid_active():
    """16x16 dark fill with teal border for active layer empty slots."""
    img = Image.new("RGBA", (16, 16))
    for y in range(16):
        for x in range(16):
            if x == 0 or x == 15 or y == 0 or y == 15:
                # Bright teal border
                img.putpixel((x, y), (0x00, 0xcc, 0xaa, 255))
            else:
                # Dark fill with slight teal tint
                img.putpixel((x, y), (0x0a, 0x1a, 0x18, 255))
    return img


def generate_grid_filled():
    """16x16 solid teal fill with bright border for filled slots."""
    img = Image.new("RGBA", (16, 16))
    for y in range(16):
        for x in range(16):
            if x == 0 or x == 15 or y == 0 or y == 15:
                # Bright border
                img.putpixel((x, y), (0x00, 0xff, 0xcc, 255))
            else:
                # Solid teal fill — fully opaque
                img.putpixel((x, y), (0x00, 0xcc, 0xaa, 255))
    return img


def generate_crafting_station_3d():
    """16x16 dark metallic block with teal grid pattern for the crafting station."""
    img = Image.new("RGBA", (16, 16))
    for y in range(16):
        for x in range(16):
            # Dark metallic base
            r, g, b = 0x2a, 0x2a, 0x30

            # 1px bevel border
            if x == 0 or y == 0:
                r = clamp(r + 15); g = clamp(g + 15); b = clamp(b + 15)
            if x == 15 or y == 15:
                r = clamp(r - 15); g = clamp(g - 15); b = clamp(b - 15)

            # Teal grid pattern (3x3 subdivision)
            if x % 5 == 2 or y % 5 == 2:
                r = 0x00; g = 0x66; b = 0x55

            # Brighter teal at grid intersections
            if x % 5 == 2 and y % 5 == 2:
                r = 0x00; g = 0xaa; b = 0x88

            # Center diamond accent
            cx, cy = abs(x - 7.5), abs(y - 7.5)
            if cx + cy < 3:
                r = 0x00; g = 0xcc; b = 0xaa

            n = random.randint(-3, 3)
            img.putpixel((x, y), (clamp(r + n), clamp(g + n), clamp(b + n), 255))
    return img


def generate_disrupted_space_variants():
    """Generate 20 opacity variants of the disrupted space texture.

    Variant 1 = most opaque, variant 20 = most transparent.
    Variants 1-10 (dense patches) have boosted alpha for
    darker, more defined patches. Variants 11-20 (transparent
    areas) are unchanged — near-invisible as intended.
    """
    base = generate_disrupted_space()
    variants = {}
    for i in range(1, 21):
        # Base alpha from 90 (variant 1) to 10 (variant 20)
        alpha = int(90 - (i - 1) * (90 - 10) / 19)
        # Boost variants 1-10 by 50-82% (more boost on denser)
        if i <= 10:
            # Variant 1 gets ~82% boost, variant 10 gets ~59%
            boost = (1.4 - (i - 1) * 0.02) * 1.3
            alpha = min(255, int(alpha * boost))
        img = base.copy()
        # Apply uniform alpha to all pixels.
        r, g, b, _ = img.split()
        a = Image.new("L", img.size, alpha)
        img = Image.merge("RGBA", (r, g, b, a))
        variants[f"lazarus_space_disrupted_space_{i}.png"] = img
    return variants


def generate_plasma_diagnostic():
    """Animated plasma diagnostic visualization — top-down torus cross-section.

    128x128 per frame, 20 frames stacked vertically = 128x2560 sprite sheet.
    Shows rotating plasma blobs, helical field lines, and pulsing correction.
    """
    FRAME_SIZE = 205
    FRAME_COUNT = 40
    CENTER = FRAME_SIZE // 2
    OUTER_R = 80
    INNER_R = 48
    MID_R = (OUTER_R + INNER_R) // 2  # where plasma blobs orbit
    POLE_R = 13

    sheet = Image.new("RGBA", (FRAME_SIZE, FRAME_SIZE * FRAME_COUNT), (8, 8, 8, 255))

    for frame in range(FRAME_COUNT):
        img = Image.new("RGBA", (FRAME_SIZE, FRAME_SIZE), (8, 8, 8, 255))
        phase = frame / FRAME_COUNT * 2 * math.pi

        # 1. Draw torus ring and plasma glow
        for y in range(FRAME_SIZE):
            for x in range(FRAME_SIZE):
                dx, dy = x - CENTER, y - CENTER
                dist = math.sqrt(dx * dx + dy * dy)

                # Torus vessel walls (orange)
                if INNER_R <= dist <= OUTER_R:
                    # Border pixels
                    if dist <= INNER_R + 1.5 or dist >= OUTER_R - 1.5:
                        img.putpixel((x, y), (0xb0, 0x50, 0x00, 255))
                    else:
                        # Plasma glow inside the ring (magenta, blended)
                        r, g, b, _ = img.getpixel((x, y))
                        pr, pg, pb = 0xcc, 0x00, 0xcc
                        alpha = 160
                        r = clamp(int(r * (255 - alpha) / 255 + pr * alpha / 255))
                        g = clamp(int(g * (255 - alpha) / 255 + pg * alpha / 255))
                        b = clamp(int(b * (255 - alpha) / 255 + pb * alpha / 255))
                        img.putpixel((x, y), (r, g, b, 255))

                # Center pole (purple)
                if dist <= POLE_R:
                    if dist <= POLE_R - 1.5:
                        img.putpixel((x, y), (0xcc, 0x44, 0xff, 255))
                    else:
                        img.putpixel((x, y), (0x99, 0x22, 0xcc, 255))

        # 2. Draw helical field lines (yellow traveling wave)
        for t in range(360):
            theta = math.radians(t)
            r_wave = MID_R + 11 * math.sin(4 * theta + phase * 3)
            px = CENTER + int(r_wave * math.cos(theta))
            py = CENTER + int(r_wave * math.sin(theta))
            if 0 <= px < FRAME_SIZE and 0 <= py < FRAME_SIZE:
                img.putpixel((px, py), (0xff, 0xcc, 0x00, 255))

        # 3. Draw green toroidal field arrows (rotating)
        for i in range(6):
            angle = phase * 0.8 + i * (2 * math.pi / 6)
            ax = CENTER + int(MID_R * math.cos(angle))
            ay = CENTER + int(MID_R * math.sin(angle))
            # Draw small arrowhead (5px diamond)
            for dy in range(-3, 4):
                for dx in range(-3, 4):
                    if abs(dx) + abs(dy) <= 3:
                        px, py = ax + dx, ay + dy
                        if 0 <= px < FRAME_SIZE and 0 <= py < FRAME_SIZE:
                            img.putpixel((px, py), (0x33, 0xcc, 0x33, 255))

        # 4. Draw plasma blobs (bright magenta, rotating)
        for i in range(8):
            angle = phase + i * (2 * math.pi / 8)
            bx = CENTER + int(MID_R * math.cos(angle))
            by = CENTER + int(MID_R * math.sin(angle))
            # Draw 5px radius blob
            for dy in range(-5, 6):
                for dx in range(-5, 6):
                    if dx * dx + dy * dy <= 25:
                        px, py = bx + dx, by + dy
                        if 0 <= px < FRAME_SIZE and 0 <= py < FRAME_SIZE:
                            img.putpixel((px, py), (0xff, 0x44, 0xff, 255))

        # 5. Draw correction pulses from center pole (pulsing purple lines)
        pulse = 0.5 + 0.5 * math.sin(phase * 2)
        pulse_alpha = int(pulse * 200)
        for angle_idx in range(4):
            angle = angle_idx * math.pi / 2
            for d in range(POLE_R + 2, INNER_R - 2):
                px = CENTER + int(d * math.cos(angle))
                py = CENTER + int(d * math.sin(angle))
                if 0 <= px < FRAME_SIZE and 0 <= py < FRAME_SIZE:
                    bg_r, bg_g, bg_b, _ = img.getpixel((px, py))
                    pr, pg, pb = 0xcc, 0x44, 0xff
                    r = clamp(int(bg_r * (255 - pulse_alpha) / 255 + pr * pulse_alpha / 255))
                    g = clamp(int(bg_g * (255 - pulse_alpha) / 255 + pg * pulse_alpha / 255))
                    b = clamp(int(bg_b * (255 - pulse_alpha) / 255 + pb * pulse_alpha / 255))
                    img.putpixel((px, py), (r, g, b, 255))

        sheet.paste(img, (0, frame * FRAME_SIZE))

    return sheet


def main():
    textures = {
        "lazarus_space_disrupter_top.png": generate_disrupter_top(),
        "lazarus_space_disrupter_bottom.png": generate_disrupter_bottom(),
        "lazarus_space_disrupter_side.png": generate_disrupter_side(),
        "lazarus_space_disrupter_front.png": generate_disrupter_front(),
        "lazarus_space_disrupter_front_active.png": generate_disrupter_front_active(),
        "lazarus_space_disrupted_space.png": generate_disrupted_space(),
        "lazarus_space_decaying_uranium.png": generate_decaying_uranium(),
        "lazarus_space_lazarus_portal.png": generate_lazarus_portal(),
        "lazarus_space_star_near.png": generate_star_near(),
        "lazarus_space_star_far.png": generate_star_far(),
        "lazarus_space_star_nebula.png": generate_star_nebula(),
        "lazarus_space_progress_bg.png": generate_progress_bg(),
        "lazarus_space_progress_fill.png": generate_progress_fill(),
        "lazarus_space_particle_black.png": generate_particle_black(),
        "lazarus_space_particle_white.png": generate_particle_white(),
        "lazarus_space_pole_field.png": generate_pole_field(),
        "lazarus_space_steel_block.png": generate_steel_block(),
        "lazarus_space_toroid_field.png": generate_toroid_field(),
        "lazarus_space_plasma_field.png": generate_plasma_field(),
        "lazarus_space_pole_corrector.png": generate_pole_corrector(),
        "lazarus_space_fusion_control_panel.png": generate_fusion_control_panel(),
        "lazarus_space_plasma_jumpstarter.png": generate_plasma_jumpstarter(),
        "lazarus_space_fusion_power_output.png": generate_fusion_power_output(),
        "lazarus_space_reactor_guide.png": generate_reactor_guide(),
        "lazarus_space_plasma_diagnostic.png": generate_plasma_diagnostic(),
        "lazarus_space_portal_guide.png": generate_portal_guide(),
        "lazarus_space_grid_empty.png": generate_grid_empty(),
        "lazarus_space_grid_active.png": generate_grid_active(),
        "lazarus_space_grid_filled.png": generate_grid_filled(),
        "lazarus_space_crafting_station_3d.png": generate_crafting_station_3d(),
    }

    # Add 20 disrupted space opacity variants.
    textures.update(generate_disrupted_space_variants())

    for name, img in textures.items():
        path = os.path.join(TEXTURES_DIR, name)
        img.save(path)
        w, h = img.size
        frames = h // 16
        if frames > 1:
            print(f"Generated {name} ({w}x{h}, {frames} frames)")
        else:
            print(f"Generated {name} ({w}x{h})")

    print(f"\nAll textures saved to {TEXTURES_DIR}")


if __name__ == "__main__":
    main()
