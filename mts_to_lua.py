#!/usr/bin/env python3
"""Parse Minetest .mts schematic files and output Lua S() structure table calls.

Reads reactor1.mts, reactor2.mts, reactor3.mts from reference/ and outputs
the structure definitions matching the format used in reactor.lua.
"""

import os
import struct
import zlib
import sys

REFERENCE_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                             "..", "MGMT", "reference")

# Map schematic node names to reactor.lua aliases
NODE_ALIASES = {
    "lazarus_space:pole_field": "PF",
    "lazarus_space:toroid_field": "TF",
    "lazarus_space:plasma_field": "PLF",
    "lazarus_space:plasma_field_corner": "PLC",
    "lazarus_space:pole_corrector": "PC",
    "default:steelblock": "SB",
    "air": "AIR",
}

SKIP_NODES = {"air", "ignore", "default:stone"}


def parse_mts(filepath):
    """Parse a Minetest v4 schematic file.

    Returns (size_x, size_y, size_z, name_table, node_data).
    node_data is a list of (node_id, param1, param2) tuples.
    """
    with open(filepath, "rb") as f:
        data = f.read()

    offset = 0

    # Header: 4 bytes magic, 2 bytes version
    magic = data[offset:offset+4]
    assert magic == b"MTSM", f"Invalid magic: {magic}"
    offset += 4
    version = struct.unpack_from(">H", data, offset)[0]
    offset += 2

    # Size: 3 x u16 BE
    size_x = struct.unpack_from(">H", data, offset)[0]; offset += 2
    size_y = struct.unpack_from(">H", data, offset)[0]; offset += 2
    size_z = struct.unpack_from(">H", data, offset)[0]; offset += 2

    # Slice probability: size_y bytes
    offset += size_y

    # Node name table: u16 count, then for each: u16 len + string
    name_count = struct.unpack_from(">H", data, offset)[0]; offset += 2
    name_table = []
    for _ in range(name_count):
        name_len = struct.unpack_from(">H", data, offset)[0]; offset += 2
        name = data[offset:offset+name_len].decode("utf-8")
        offset += name_len
        name_table.append(name)

    # Node data: zlib-compressed
    # Layout: all node_ids (u16 BE each), then all param1 (u8), then all param2 (u8)
    compressed = data[offset:]
    decompressed = zlib.decompress(compressed)

    total_nodes = size_x * size_y * size_z
    node_data = []
    for i in range(total_nodes):
        node_id = struct.unpack_from(">H", decompressed, i * 2)[0]
        param1 = decompressed[total_nodes * 2 + i]
        param2 = decompressed[total_nodes * 3 + i]
        node_data.append((node_id, param1, param2))

    return size_x, size_y, size_z, name_table, node_data


def extract_structure(filepath):
    """Extract structure entries from an .mts file.

    Returns a list of (dx, dy, dz, alias) tuples relative to the pole corrector.
    """
    size_x, size_y, size_z, name_table, node_data = parse_mts(filepath)

    print(f"  Size: {size_x}x{size_y}x{size_z}")
    print(f"  Node types: {name_table}")

    # Build 3D grid and find pole corrector
    pc_pos = None
    entries = []

    for i, (node_id, p1, p2) in enumerate(node_data):
        # MTS iteration order: z outer, y middle, x inner
        # index = z * size_y * size_x + y * size_x + x
        x = i % size_x
        y = (i // size_x) % size_y
        z = i // (size_x * size_y)

        name = name_table[node_id]
        if name == "lazarus_space:pole_corrector":
            pc_pos = (x, y, z)

    if not pc_pos:
        print("  ERROR: No pole corrector found!")
        return []

    print(f"  Pole corrector at raw pos: {pc_pos}")

    # Second pass: collect all non-skip nodes relative to PC
    counts = {}
    for i, (node_id, p1, p2) in enumerate(node_data):
        x = i % size_x
        y = (i // size_x) % size_y
        z = i // (size_x * size_y)

        name = name_table[node_id]
        if name in SKIP_NODES:
            continue

        alias = NODE_ALIASES.get(name)
        if not alias:
            print(f"  WARNING: Unknown node '{name}', skipping")
            continue

        dx = x - pc_pos[0]
        dy = y - pc_pos[1]
        dz = z - pc_pos[2]

        entries.append((dx, dy, dz, alias))
        counts[alias] = counts.get(alias, 0) + 1

    # Add enforced air positions adjacent to pole corrector
    air_offsets = [
        (0, -1, 0), (0, 1, 0), (0, -2, 0), (0, 2, 0),  # above/below
    ]
    for adx, ady, adz in air_offsets:
        # Check if this position is NOT already occupied
        occupied = any(e[0] == adx and e[1] == ady and e[2] == adz for e in entries)
        if not occupied:
            entries.append((adx, ady, adz, "AIR"))
            counts["AIR"] = counts.get("AIR", 0) + 1

    print(f"  Block counts: {counts}")
    print(f"  Total entries: {len(entries)}")

    return entries


def group_by_layer(entries):
    """Group entries by y-coordinate for readable output."""
    layers = {}
    for dx, dy, dz, alias in entries:
        if dy not in layers:
            layers[dy] = []
        layers[dy].append((dx, dy, dz, alias))

    # Sort each layer by z then x
    for dy in layers:
        layers[dy].sort(key=lambda e: (e[2], e[0]))

    return layers


def format_lua_structure(entries, tier_num):
    """Format entries as Lua S() calls grouped by layer."""
    layers = group_by_layer(entries)
    lines = []

    layer_names = {}
    ys = sorted(layers.keys())
    if len(ys) == 5:
        layer_names[ys[0]] = "FLOOR"
        layer_names[ys[1]] = "WALL (lower)"
        layer_names[ys[2]] = "MIDDLE"
        layer_names[ys[3]] = "WALL (upper)"
        layer_names[ys[4]] = "ROOF"

    for dy in ys:
        name = layer_names.get(dy, f"y={dy}")
        lines.append(f"-- ---- Tier {tier_num}: {name} (y = {dy}) ----")
        for dx, _, dz, alias in layers[dy]:
            lines.append(f"S({dx:3d},{dy:2d},{dz:3d}, {alias})")
        lines.append("")

    return "\n".join(lines)


def main():
    for tier in [1, 2, 3]:
        filename = f"reactor{tier}.mts"
        filepath = os.path.join(REFERENCE_DIR, filename)
        if not os.path.exists(filepath):
            print(f"Skipping {filename}: not found")
            continue

        print(f"\n{'='*60}")
        print(f"Tier {tier}: {filename}")
        print(f"{'='*60}")

        entries = extract_structure(filepath)
        if entries:
            lua_code = format_lua_structure(entries, tier)
            print(f"\n--- Lua S() calls ---\n")
            print(lua_code)


if __name__ == "__main__":
    main()
