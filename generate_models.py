#!/usr/bin/env python3
"""Generate .obj mesh files and texture atlas for the reactor guide book.

Uses a texture atlas approach: all block textures are combined into a single
horizontal strip (80x16 pixels, 5 slots of 16x16 each). UV coordinates for
each cube face point to the correct slot in the atlas. This avoids multi-material
issues with Minetest's model[] formspec element.

The atlas PNG (lazarus_space_reactor_atlas.png) is generated at build time by
compositing the 5 source textures side-by-side. This avoids using [combine in
the formspec, whose commas conflict with model[] texture parameter parsing.

Atlas layout (80x16, 5 slots of 16x16):
  Slot 0 (x=0):  lazarus_space_pole_field.png
  Slot 1 (x=16): lazarus_space_toroid_field.png
  Slot 2 (x=32): default_steel_block.png (grey placeholder if unavailable)
  Slot 3 (x=48): lazarus_space_plasma_field.png
  Slot 4 (x=64): lazarus_space_pole_corrector.png

If source textures change, re-run this script to regenerate the atlas.

Requires: Python 3.6+, Pillow (PIL)
"""

import os

MODELS_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "models")
os.makedirs(MODELS_DIR, exist_ok=True)

# ---- Texture atlas slot mapping ----
# Each block type maps to a slot index (0-4) in the 80x16 atlas.
# UV u-coordinate: u_min = slot/5, u_max = (slot+1)/5

SLOT_MAP = {
    "P": 0,   # pole field
    "T": 1,   # toroid field
    "S": 2,   # steelblock
    "L": 3,   # plasma field
    "C": 3,   # plasma field corner (same texture)
    "*": 4,   # pole corrector
}

NUM_SLOTS = 5

# ---- Grid data (same as guide.lua) ----

GRID_FLOOR = [
    "PPPPPPPPPPPPP",
    "PS....S....SP",
    "P.....S.....P",
    "P.....S.....P",
    "P.....S.....P",
    "P....SSS....P",
    "PSSSSSSSSSSSP",
    "P....SSS....P",
    "P.....S.....P",
    "P.....S.....P",
    "P.....S.....P",
    "PS....S....SP",
    "PPPPPPPPPPPPP",
]

GRID_WALLS = [
    ".............",
    ".S..T.T.T..S.",
    "....T.T.T....",
    "....T.T.T....",
    ".TTT..S..TTT.",
    ".....PPP.....",
    ".TTTSPaPSTTT.",
    ".....PPP.....",
    ".TTT..S..TTT.",
    "....T.T.T....",
    "....T.T.T....",
    ".S..T.T.T..S.",
    ".............",
]

GRID_PLASMA = [
    ".............",
    ".SS.T.T.T.SS.",
    ".SLCLLLLLLCS.",
    "..L.T.T.T.L..",
    ".TLT..S..TLT.",
    "..L..PPP..L..",
    ".TLTSP*PSTLT.",
    "..L..PPP..L..",
    ".TLT..S..TLT.",
    "..C.T.T.T.L..",
    ".SLLLLLLCLLS.",
    ".SS.T.T.T.SS.",
    ".............",
]

GRID_ROOF = [
    "PPPPPPPPPPPPP",
    "PS.........SP",
    "P...........P",
    "P...........P",
    "P...........P",
    "P...........P",
    "P...........P",
    "P...........P",
    "P...........P",
    "P...........P",
    "P...........P",
    "PS.........SP",
    "PPPPPPPPPPPPP",
]

# ---- Layer definitions ----

LAYERS = {
    "reactor_layer_floor":  [(GRID_FLOOR, -2)],
    "reactor_layer_walls":  [(GRID_WALLS, -1), (GRID_WALLS, 1)],
    "reactor_layer_middle": [(GRID_PLASMA, 0)],
    "reactor_layer_roof":   [(GRID_ROOF, 2)],
    "reactor_complete":     [
        (GRID_FLOOR, -2),
        (GRID_WALLS, -1),
        (GRID_PLASMA, 0),
        (GRID_WALLS, 1),
        (GRID_ROOF, 2),
    ],
}


def build_occupied_set(layer_grids):
    """Build a set of all occupied (x, y, z) positions."""
    occupied = set()
    for grid, y_off in layer_grids:
        for row_idx, row_str in enumerate(grid):
            for col_idx, ch in enumerate(row_str):
                if ch in SLOT_MAP:
                    x = col_idx - 6
                    z = row_idx - 6
                    occupied.add((x, y_off, z))
    return occupied


# Face definitions: (neighbor_offset, vertex_indices_for_quad, normal_index_1based)
# Vertices of a unit cube at (x, y, z):
#   0: (x,   y,   z)     1: (x+1, y,   z)
#   2: (x+1, y+1, z)     3: (x,   y+1, z)
#   4: (x,   y,   z+1)   5: (x+1, y,   z+1)
#   6: (x+1, y+1, z+1)   7: (x,   y+1, z+1)
FACE_DEFS = [
    # (neighbor_offset, vertex_indices, normal_index_1based)
    ((0, 0, -1), (0, 1, 2, 3), 1),   # front  (-z)
    ((0, 0,  1), (5, 4, 7, 6), 2),   # back   (+z)
    ((0,  1, 0), (3, 2, 6, 7), 3),   # top    (+y)
    ((0, -1, 0), (4, 5, 1, 0), 4),   # bottom (-y)
    (( 1, 0, 0), (1, 5, 6, 2), 5),   # right  (+x)
    ((-1, 0, 0), (4, 0, 3, 7), 6),   # left   (-x)
]


def generate_obj(name, layer_grids):
    """Generate a face-culled .obj file using texture atlas UVs."""
    occupied = build_occupied_set(layer_grids)

    vertices = []
    uvs = []
    faces = []  # list of (v1,v2,v3,v4, uv1,uv2,uv3,uv4, normal_idx)

    vert_offset = 1  # .obj is 1-indexed
    uv_offset = 1

    for grid, y_off in layer_grids:
        for row_idx, row_str in enumerate(grid):
            for col_idx, ch in enumerate(row_str):
                if ch not in SLOT_MAP:
                    continue

                slot = SLOT_MAP[ch]
                x = col_idx - 6
                y = y_off
                z = row_idx - 6

                # 8 corner vertices
                corners = [
                    (x,   y,   z),
                    (x+1, y,   z),
                    (x+1, y+1, z),
                    (x,   y+1, z),
                    (x,   y,   z+1),
                    (x+1, y,   z+1),
                    (x+1, y+1, z+1),
                    (x,   y+1, z+1),
                ]
                vertices.extend(corners)

                # 4 UV coords for this block's atlas slot
                u_min = slot / NUM_SLOTS
                u_max = (slot + 1) / NUM_SLOTS
                uvs.append((u_min, 0.0))
                uvs.append((u_max, 0.0))
                uvs.append((u_max, 1.0))
                uvs.append((u_min, 1.0))

                # Emit only exposed faces (face culling)
                for (dx, dy, dz), vi, ni in FACE_DEFS:
                    if (x + dx, y + dy, z + dz) not in occupied:
                        faces.append((
                            vert_offset + vi[0],
                            vert_offset + vi[1],
                            vert_offset + vi[2],
                            vert_offset + vi[3],
                            uv_offset + 0,  # bottom-left of tile
                            uv_offset + 1,  # bottom-right
                            uv_offset + 2,  # top-right
                            uv_offset + 3,  # top-left
                            ni,
                        ))

                vert_offset += 8
                uv_offset += 4

    # Write .obj file
    lines = []
    lines.append("# Reactor guide model — texture atlas approach")
    lines.append("# Single material, UV coords select tile in [combine atlas")
    lines.append("")

    # Vertices
    for vx, vy, vz in vertices:
        lines.append(f"v {vx} {vy} {vz}")
    lines.append("")

    # UV coordinates (per-cube, 4 per block)
    for u, v in uvs:
        lines.append(f"vt {u:.6f} {v:.6f}")
    lines.append("")

    # Normals (6 directions)
    lines.append("vn  0  0 -1")
    lines.append("vn  0  0  1")
    lines.append("vn  0  1  0")
    lines.append("vn  0 -1  0")
    lines.append("vn  1  0  0")
    lines.append("vn -1  0  0")
    lines.append("")

    # All faces under a single material
    lines.append("usemtl reactor_atlas")
    for v1, v2, v3, v4, t1, t2, t3, t4, ni in faces:
        lines.append(
            f"f {v1}/{t1}/{ni} {v2}/{t2}/{ni} {v3}/{t3}/{ni} {v4}/{t4}/{ni}"
        )
    lines.append("")

    obj_path = os.path.join(MODELS_DIR, f"{name}.obj")
    with open(obj_path, "w") as f:
        f.write("\n".join(lines))

    print(f"Generated {name}.obj ({len(vertices)} vertices, {len(faces)} faces)")


def generate_atlas():
    """Generate the 80x16 texture atlas PNG from source textures."""
    from PIL import Image

    tex_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "textures")

    # Source textures in slot order (must match SLOT_MAP indices)
    sources = [
        ("lazarus_space_pole_field.png", None),
        ("lazarus_space_toroid_field.png", None),
        ("default_steel_block.png", "#888888"),  # fallback grey if missing
        ("lazarus_space_plasma_field.png", None),
        ("lazarus_space_pole_corrector.png", None),
    ]

    atlas = Image.new("RGBA", (80, 16))

    for slot, (filename, fallback_color) in enumerate(sources):
        path = os.path.join(tex_dir, filename)
        if os.path.exists(path):
            tile = Image.open(path).convert("RGBA").resize((16, 16))
        elif fallback_color:
            # Generate solid color tile
            r = int(fallback_color[1:3], 16)
            g = int(fallback_color[3:5], 16)
            b = int(fallback_color[5:7], 16)
            tile = Image.new("RGBA", (16, 16), (r, g, b, 255))
            print(f"  Using fallback {fallback_color} for missing {filename}")
        else:
            raise FileNotFoundError(f"Required texture not found: {path}")
        atlas.paste(tile, (slot * 16, 0))

    atlas_path = os.path.join(tex_dir, "lazarus_space_reactor_atlas.png")
    atlas.save(atlas_path)
    print(f"Generated texture atlas: lazarus_space_reactor_atlas.png (80x16)")
    return atlas_path


def main():
    # Remove old .mtl file if present (no longer needed)
    mtl_path = os.path.join(MODELS_DIR, "reactor_guide.mtl")
    if os.path.exists(mtl_path):
        os.remove(mtl_path)
        print("Removed old reactor_guide.mtl (no longer needed)")

    # Generate texture atlas
    generate_atlas()

    # Generate mesh files
    for name, layer_grids in LAYERS.items():
        generate_obj(name, layer_grids)
    print(f"\nAll models saved to {MODELS_DIR}")
    print(f"Lua texture reference: lazarus_space_reactor_atlas.png")


if __name__ == "__main__":
    main()
