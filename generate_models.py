#!/usr/bin/env python3
"""Generate .obj mesh files for the reactor guide book.

Uses a multi-material approach: each block type has its own named material
in the .obj file. The formspec model[] element maps comma-separated textures
to mesh material groups by index. Every .obj file declares all 5 materials
in the same order (even if some have 0 faces) to ensure consistent
texture-to-buffer index mapping.

Material order (must match MODEL_TEXTURE in guide.lua):
  0: mat_pole_field      -> lazarus_space_pole_field.png
  1: mat_toroid_field    -> lazarus_space_toroid_field.png
  2: mat_steelblock      -> default_steel_block.png (Minetest default mod)
  3: mat_plasma_field    -> lazarus_space_plasma_field.png
  4: mat_pole_corrector  -> lazarus_space_pole_corrector.png

Requires: Python 3.6+
"""

import os

MODELS_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "models")
os.makedirs(MODELS_DIR, exist_ok=True)

# ---- Multi-material mapping ----
# Material names in fixed order — index determines texture mapping in model[].

MATERIAL_ORDER = [
    "mat_pole_field",      # index 0
    "mat_toroid_field",    # index 1
    "mat_steelblock",      # index 2
    "mat_plasma_field",    # index 3
    "mat_pole_corrector",  # index 4
]

CHAR_TO_MATERIAL = {
    "P": "mat_pole_field",
    "T": "mat_toroid_field",
    "S": "mat_steelblock",
    "L": "mat_plasma_field",
    "C": "mat_plasma_field",       # corner uses same as plasma
    "*": "mat_pole_corrector",
}

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
                if ch in CHAR_TO_MATERIAL:
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
    """Generate a face-culled .obj file with multi-material groups."""
    occupied = build_occupied_set(layer_grids)

    vertices = []
    # Collect faces per material
    material_faces = {m: [] for m in MATERIAL_ORDER}

    vert_offset = 1  # .obj is 1-indexed

    for grid, y_off in layer_grids:
        for row_idx, row_str in enumerate(grid):
            for col_idx, ch in enumerate(row_str):
                if ch not in CHAR_TO_MATERIAL:
                    continue

                mat = CHAR_TO_MATERIAL[ch]
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

                # Emit only exposed faces (face culling)
                for (dx, dy, dz), vi, ni in FACE_DEFS:
                    if (x + dx, y + dy, z + dz) not in occupied:
                        material_faces[mat].append((
                            vert_offset + vi[0],
                            vert_offset + vi[1],
                            vert_offset + vi[2],
                            vert_offset + vi[3],
                            ni,
                        ))

                vert_offset += 8

    # Write .obj file
    lines = []
    lines.append("# Reactor guide model — multi-material approach")
    lines.append("# 5 materials in fixed order, textures mapped by model[] index")
    lines.append("")

    # Vertices
    for vx, vy, vz in vertices:
        lines.append(f"v {vx} {vy} {vz}")
    lines.append("")

    # UV coordinates — simple full-tile UVs (shared by all faces)
    lines.append("vt 0.000000 0.000000")
    lines.append("vt 1.000000 0.000000")
    lines.append("vt 1.000000 1.000000")
    lines.append("vt 0.000000 1.000000")
    lines.append("")

    # Normals (6 directions)
    lines.append("vn  0  0 -1")
    lines.append("vn  0  0  1")
    lines.append("vn  0  1  0")
    lines.append("vn  0 -1  0")
    lines.append("vn  1  0  0")
    lines.append("vn -1  0  0")
    lines.append("")

    # Emit all 5 material groups in fixed order (even if empty)
    total_faces = 0
    for mat_name in MATERIAL_ORDER:
        lines.append(f"usemtl {mat_name}")
        for v1, v2, v3, v4, ni in material_faces[mat_name]:
            lines.append(
                f"f {v1}/1/{ni} {v2}/2/{ni} {v3}/3/{ni} {v4}/4/{ni}"
            )
            total_faces += 1
        lines.append("")

    obj_path = os.path.join(MODELS_DIR, f"{name}.obj")
    with open(obj_path, "w") as f:
        f.write("\n".join(lines))

    print(f"Generated {name}.obj ({len(vertices)} vertices, {total_faces} faces)")


def main():
    # Remove old files if present
    mtl_path = os.path.join(MODELS_DIR, "reactor_guide.mtl")
    if os.path.exists(mtl_path):
        os.remove(mtl_path)
        print("Removed old reactor_guide.mtl")

    tex_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "textures")
    atlas_path = os.path.join(tex_dir, "lazarus_space_reactor_atlas.png")
    if os.path.exists(atlas_path):
        os.remove(atlas_path)
        print("Removed old lazarus_space_reactor_atlas.png (no longer needed)")

    # Generate mesh files
    for name, layer_grids in LAYERS.items():
        generate_obj(name, layer_grids)

    print(f"\nAll models saved to {MODELS_DIR}")
    print("Lua texture reference: 5 comma-separated textures (see guide.lua)")


if __name__ == "__main__":
    main()
