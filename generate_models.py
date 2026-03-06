#!/usr/bin/env python3
"""Generate .obj mesh files for the reactor guide book.

Uses a single-material atlas UV approach: each cube face gets UV coordinates
pointing to the correct slot in an 80x16 virtual atlas (5 slots of 16x16).
The atlas is built at runtime using Minetest's [combine texture modifier
with escaped commas (\\,) in the formspec, so no pre-generated atlas PNG
is needed. This allows referencing default_steel_block.png directly from
Minetest's default mod at runtime.

Atlas layout (80x16, 5 slots of 16x16):
  Slot 0 (u=0.0-0.2):  lazarus_space_pole_field.png
  Slot 1 (u=0.2-0.4):  lazarus_space_toroid_field.png
  Slot 2 (u=0.4-0.6):  default_steel_block.png (resolved from default mod)
  Slot 3 (u=0.6-0.8):  lazarus_space_plasma_field.png
  Slot 4 (u=0.8-1.0):  lazarus_space_pole_corrector.png

Requires: Python 3.6+
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

# ---- Grid data: Tier 1 (9×9) ----

GRID_FLOOR_T1 = [
    "PPPPPPPPP",
    "PS..S..SP",
    "P...S...P",
    "P...S...P",
    "PSSSSSSSP",
    "P...S...P",
    "P...S...P",
    "PS..S..SP",
    "PPPPPPPPP",
]

GRID_WALLS_T1 = [
    ".........",
    ".S..T..S.",
    "....T....",
    "....T....",
    ".TTTaTTT.",
    "....T....",
    "....T....",
    ".S..T..S.",
    ".........",
]

GRID_PLASMA_T1 = [
    ".........",
    ".SS.T.SS.",
    ".SCLLLCS.",
    "..L.T.L..",
    ".TLT*TLT.",
    "..L.T.L..",
    ".SCLLLCS.",
    ".SS.T.SS.",
    ".........",
]

GRID_ROOF_T1 = [
    "PPPPPPPPP",
    "PS.....SP",
    "P.......P",
    "P.......P",
    "P.......P",
    "P.......P",
    "P.......P",
    "PS.....SP",
    "PPPPPPPPP",
]

# ---- Grid data: Tier 2 (13×13) ----

GRID_FLOOR_T2 = [
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

GRID_WALLS_T2 = [
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

GRID_PLASMA_T2 = [
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

GRID_ROOF_T2 = [
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

# ---- Grid data: Tier 3 (17×17) ----

GRID_FLOOR_T3 = [
    "PPPPPPPPPPPPPPPPP",
    "PSSSSSSSSSSSSSSSP",
    "PS......S......SP",
    "PS......S......SP",
    "PS......S......SP",
    "PS......S......SP",
    "PS......S......SP",
    "PS.....SSS.....SP",
    "PSSSSSSSSSSSSSSSP",
    "PS.....SSS.....SP",
    "PS......S......SP",
    "PS......S......SP",
    "PS......S......SP",
    "PS......S......SP",
    "PS......S......SP",
    "PSSSSSSSSSSSSSSSP",
    "PPPPPPPPPPPPPPPPP",
]

GRID_WALLS_T3 = [
    ".................",
    ".SS.T.T.T.T.T.SS.",
    ".S..T.T.T.T.T..S.",
    "....T.T.T.T.T....",
    ".TTT....S....TTT.",
    "........S........",
    ".TTT....S....TTT.",
    ".......PPP.......",
    ".TTTSSSPaPSSSTTT.",
    ".......PPP.......",
    ".TTT....S....TTT.",
    "........S........",
    ".TTT....S....TTT.",
    "....T.T.T.T.T....",
    ".S..T.T.T.T.T..S.",
    ".SS.T.T.T.T.T.SS.",
    ".................",
]

GRID_PLASMA_T3 = [
    ".................",
    ".SS.T.T.T.T.T.SS.",
    ".SCLLLLLLLLLLLCS.",
    "..L.T.T.T.T.T.L..",
    ".TLT....S....TLT.",
    "..L.....S.....L..",
    ".TLT....S....TLT.",
    "..L....PPP....L..",
    ".TLTSSSP*PSSSTLT.",
    "..L....PPP....L..",
    ".TLT....S....TLT.",
    "..L.....S.....L..",
    ".TLT....S....TLT.",
    "..L.T.T.T.T.T.L..",
    ".SCLLLLLLLLLLLCS.",
    ".SS.T.T.T.T.T.SS.",
    ".................",
]

GRID_ROOF_T3 = [
    "PPPPPPPPPPPPPPPPP",
    "PSSS.........SSSP",
    "PS.............SP",
    "PS.............SP",
    "P...............P",
    "P...............P",
    "P...............P",
    "P...............P",
    "P...............P",
    "P...............P",
    "P...............P",
    "P...............P",
    "P...............P",
    "PS.............SP",
    "PS.............SP",
    "PSSS.........SSSP",
    "PPPPPPPPPPPPPPPPP",
]

# ---- Layer definitions per tier ----

LAYERS = {
    # Tier 1
    "reactor_t1_floor":    [(GRID_FLOOR_T1, -2)],
    "reactor_t1_walls":    [(GRID_WALLS_T1, -1), (GRID_WALLS_T1, 1)],
    "reactor_t1_middle":   [(GRID_PLASMA_T1, 0)],
    "reactor_t1_roof":     [(GRID_ROOF_T1, 2)],
    "reactor_t1_complete": [
        (GRID_FLOOR_T1, -2),
        (GRID_WALLS_T1, -1),
        (GRID_PLASMA_T1, 0),
        (GRID_WALLS_T1, 1),
        (GRID_ROOF_T1, 2),
    ],
    # Tier 2
    "reactor_t2_floor":    [(GRID_FLOOR_T2, -2)],
    "reactor_t2_walls":    [(GRID_WALLS_T2, -1), (GRID_WALLS_T2, 1)],
    "reactor_t2_middle":   [(GRID_PLASMA_T2, 0)],
    "reactor_t2_roof":     [(GRID_ROOF_T2, 2)],
    "reactor_t2_complete": [
        (GRID_FLOOR_T2, -2),
        (GRID_WALLS_T2, -1),
        (GRID_PLASMA_T2, 0),
        (GRID_WALLS_T2, 1),
        (GRID_ROOF_T2, 2),
    ],
    # Tier 3
    "reactor_t3_floor":    [(GRID_FLOOR_T3, -2)],
    "reactor_t3_walls":    [(GRID_WALLS_T3, -1), (GRID_WALLS_T3, 1)],
    "reactor_t3_middle":   [(GRID_PLASMA_T3, 0)],
    "reactor_t3_roof":     [(GRID_ROOF_T3, 2)],
    "reactor_t3_complete": [
        (GRID_FLOOR_T3, -2),
        (GRID_WALLS_T3, -1),
        (GRID_PLASMA_T3, 0),
        (GRID_WALLS_T3, 1),
        (GRID_ROOF_T3, 2),
    ],
}


def build_occupied_set(layer_grids):
    """Build a set of all occupied (x, y, z) positions."""
    occupied = set()
    for grid, y_off in layer_grids:
        center = len(grid[0]) // 2
        for row_idx, row_str in enumerate(grid):
            for col_idx, ch in enumerate(row_str):
                if ch in SLOT_MAP:
                    x = col_idx - center
                    z = row_idx - center
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
    """Generate a face-culled .obj file using atlas UV coordinates."""
    occupied = build_occupied_set(layer_grids)

    vertices = []
    uvs = []
    faces = []  # list of (v1,v2,v3,v4, uv1,uv2,uv3,uv4, normal_idx)

    vert_offset = 1  # .obj is 1-indexed
    uv_offset = 1

    for grid, y_off in layer_grids:
        center = len(grid[0]) // 2
        for row_idx, row_str in enumerate(grid):
            for col_idx, ch in enumerate(row_str):
                if ch not in SLOT_MAP:
                    continue

                slot = SLOT_MAP[ch]
                x = col_idx - center
                y = y_off
                z = row_idx - center

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
    lines.append("# Reactor guide model — single material, atlas UV approach")
    lines.append("# UV coords select tile in [combine atlas built at runtime")
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


def main():
    # Remove old un-prefixed files
    old_names = [
        "reactor_layer_floor.obj",
        "reactor_layer_walls.obj",
        "reactor_layer_middle.obj",
        "reactor_layer_roof.obj",
        "reactor_complete.obj",
        "reactor_guide.mtl",
    ]
    for old_name in old_names:
        old_path = os.path.join(MODELS_DIR, old_name)
        if os.path.exists(old_path):
            os.remove(old_path)
            print(f"Removed old {old_name}")

    tex_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "textures")
    atlas_path = os.path.join(tex_dir, "lazarus_space_reactor_atlas.png")
    if os.path.exists(atlas_path):
        os.remove(atlas_path)
        print("Removed old lazarus_space_reactor_atlas.png (no longer needed)")

    # Generate mesh files for all tiers
    for name, layer_grids in LAYERS.items():
        generate_obj(name, layer_grids)

    print(f"\nAll models saved to {MODELS_DIR}")
    print("Lua texture: [combine:80x16 with escaped commas (see guide.lua)")


if __name__ == "__main__":
    main()
