#!/usr/bin/env python3
"""Generate .obj mesh files for the reactor guide book 3D models.

Produces face-culled .obj files and a shared .mtl material file
in the models/ directory. Each model is built from the same grid
data used by the guide book's 2D blueprint pages.

Requires: Python 3.6+ (no external dependencies)
"""

import os

MODELS_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "models")
os.makedirs(MODELS_DIR, exist_ok=True)

# ---- Block type to material mapping ----
# Order here determines the usemtl output order in .obj files.
# The Lua MODEL_TEXTURES string must match this order.

MATERIAL_ORDER = [
    ("P",  "pole_field",     "lazarus_space_pole_field.png"),
    ("T",  "toroid_field",   "lazarus_space_toroid_field.png"),
    ("S",  "steelblock",     "default_steel_block.png"),
    ("L",  "plasma_field",   "lazarus_space_plasma_field.png"),
    ("C",  "plasma_field",   "lazarus_space_plasma_field.png"),  # corner = same
    ("*",  "pole_corrector", "lazarus_space_pole_corrector.png"),
]

# Character to material name
CHAR_TO_MATERIAL = {}
for ch, mat_name, _ in MATERIAL_ORDER:
    CHAR_TO_MATERIAL[ch] = mat_name

# Unique materials in order (for .mtl and texture list)
UNIQUE_MATERIALS = []
_seen = set()
for _, mat_name, tex_file in MATERIAL_ORDER:
    if mat_name not in _seen:
        UNIQUE_MATERIALS.append((mat_name, tex_file))
        _seen.add(mat_name)

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


# Face definitions: (dx, dy, dz, vertex indices for quad, normal index)
# Vertices of a unit cube at (x, y, z):
#   0: (x,   y,   z)     1: (x+1, y,   z)
#   2: (x+1, y+1, z)     3: (x,   y+1, z)
#   4: (x,   y,   z+1)   5: (x+1, y,   z+1)
#   6: (x+1, y+1, z+1)   7: (x,   y+1, z+1)
FACE_DEFS = [
    # (neighbor_offset, vertex_indices_for_quad, normal_index_1based, uv_indices_1based)
    ((0, 0, -1), (0, 1, 2, 3), 1, (1, 2, 3, 4)),   # front  (-z)
    ((0, 0,  1), (5, 4, 7, 6), 2, (1, 2, 3, 4)),   # back   (+z)
    ((0,  1, 0), (3, 2, 6, 7), 3, (1, 2, 3, 4)),   # top    (+y)
    ((0, -1, 0), (4, 5, 1, 0), 4, (1, 2, 3, 4)),   # bottom (-y)
    (( 1, 0, 0), (1, 5, 6, 2), 5, (1, 2, 3, 4)),   # right  (+x)
    ((-1, 0, 0), (4, 0, 3, 7), 6, (1, 2, 3, 4)),   # left   (-x)
]


def generate_obj(name, layer_grids):
    """Generate a face-culled .obj file for the given layer grids."""
    occupied = build_occupied_set(layer_grids)

    # Collect vertices and faces grouped by material
    vertices = []
    # faces_by_material: material_name -> list of (v1,v2,v3,v4, uv1,uv2,uv3,uv4, normal_idx)
    faces_by_material = {}
    for mat_name, _ in UNIQUE_MATERIALS:
        faces_by_material[mat_name] = []

    vert_offset = 1  # .obj is 1-indexed

    for grid, y_off in layer_grids:
        for row_idx, row_str in enumerate(grid):
            for col_idx, ch in enumerate(row_str):
                if ch not in CHAR_TO_MATERIAL:
                    continue

                mat_name = CHAR_TO_MATERIAL[ch]
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
                for (dx, dy, dz), vi, ni, uvi in FACE_DEFS:
                    if (x + dx, y + dy, z + dz) not in occupied:
                        faces_by_material[mat_name].append((
                            vert_offset + vi[0],
                            vert_offset + vi[1],
                            vert_offset + vi[2],
                            vert_offset + vi[3],
                            uvi[0], uvi[1], uvi[2], uvi[3],
                            ni,
                        ))

                vert_offset += 8

    # Write .obj file
    lines = []
    lines.append("mtllib reactor_guide.mtl")
    lines.append("")

    # Vertices
    for vx, vy, vz in vertices:
        lines.append(f"v {vx} {vy} {vz}")
    lines.append("")

    # UV coordinates (4 standard coords for all faces)
    lines.append("vt 0 0")
    lines.append("vt 1 0")
    lines.append("vt 1 1")
    lines.append("vt 0 1")
    lines.append("")

    # Normals (6 directions)
    lines.append("vn  0  0 -1")
    lines.append("vn  0  0  1")
    lines.append("vn  0  1  0")
    lines.append("vn  0 -1  0")
    lines.append("vn  1  0  0")
    lines.append("vn -1  0  0")
    lines.append("")

    # Faces grouped by material
    total_faces = 0
    for mat_name, _ in UNIQUE_MATERIALS:
        mat_faces = faces_by_material[mat_name]
        if not mat_faces:
            continue
        lines.append(f"usemtl {mat_name}")
        for v1, v2, v3, v4, t1, t2, t3, t4, ni in mat_faces:
            lines.append(
                f"f {v1}/{t1}/{ni} {v2}/{t2}/{ni} {v3}/{t3}/{ni} {v4}/{t4}/{ni}"
            )
        lines.append("")
        total_faces += len(mat_faces)

    obj_path = os.path.join(MODELS_DIR, f"{name}.obj")
    with open(obj_path, "w") as f:
        f.write("\n".join(lines))

    vert_count = len(vertices)
    print(f"Generated {name}.obj ({vert_count} vertices, {total_faces} faces)")


def generate_mtl():
    """Generate the shared .mtl material file."""
    lines = ["# reactor_guide.mtl", ""]
    for mat_name, tex_file in UNIQUE_MATERIALS:
        lines.append(f"newmtl {mat_name}")
        lines.append(f"map_Kd {tex_file}")
        lines.append("")

    mtl_path = os.path.join(MODELS_DIR, "reactor_guide.mtl")
    with open(mtl_path, "w") as f:
        f.write("\n".join(lines))
    print(f"Generated reactor_guide.mtl ({len(UNIQUE_MATERIALS)} materials)")


def main():
    generate_mtl()
    for name, layer_grids in LAYERS.items():
        generate_obj(name, layer_grids)
    print(f"\nAll models saved to {MODELS_DIR}")


if __name__ == "__main__":
    main()
