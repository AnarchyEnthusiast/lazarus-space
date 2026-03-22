-- Biological Dimension: Schematic Definitions
-- Lua table schematics for skeletons, fleshy mushrooms, and grass patches.
-- Data arrays use z-y-x order (x changes fastest).
-- Index formula: z * H * W + y * W + x + 1

lazarus_space.schematics = {}

-- Shorthand helpers
local AIR_SKIP  = {name = "air", prob = 0}    -- do NOT overwrite existing nodes
local AIR_PLACE = {name = "air", prob = 254}   -- place air (clear existing)

local BONE  = {name = "lazarus_space:bone", prob = 254}
local SKULL = {name = "lazarus_space:bone_block", prob = 254}
local RIB   = {name = "lazarus_space:bone", prob = 254}

local BONE_50  = {name = "lazarus_space:bone", prob = 127}
local RIB_50   = {name = "lazarus_space:bone", prob = 127}

local STEM     = {name = "lazarus_space:flesh_mushroom_stem", prob = 254}
local CAP      = {name = "lazarus_space:flesh", prob = 254}
local CAP_EDGE = {name = "lazarus_space:cartilage", prob = 254}
local GLOW     = {name = "lazarus_space:rotten_bone", prob = 254}

local CAP_70      = {name = "lazarus_space:flesh", prob = 178}
local CAP_EDGE_70 = {name = "lazarus_space:cartilage", prob = 178}

local GRASS_1     = {name = "lazarus_space:bio_grass_1", prob = 178}
local GRASS_3     = {name = "lazarus_space:bio_grass_3", prob = 178}
local GRASS_TALL  = {name = "lazarus_space:bio_grass_tall", prob = 152}

local GRASS_1_50  = {name = "lazarus_space:bio_grass_1", prob = 127}
local GRASS_3_50  = {name = "lazarus_space:bio_grass_3", prob = 127}

local _  = AIR_SKIP   -- shorthand for layout readability
local A  = AIR_PLACE

-- =============================================================================
-- Skeleton Schematics
-- =============================================================================

-- skeleton_small: 5x3x3 (W=5, H=3, D=3)
-- A small curled-up skeleton lying on the ground.
-- Viewed from above (y=0 ground layer):
--   z=0:  _  _  RIB  _  _
--   z=1:  SKULL  RIB  BONE  RIB  BONE_50
--   z=2:  _  _  RIB_50  _  _
-- y=1: Ribs arch up from spine at center
--   z=0:  _  _  _  _  _
--   z=1:  _  _  RIB_50  _  _
--   z=2:  _  _  _  _  _
-- y=2: top layer mostly air
--   z=0:  _  _  _  _  _
--   z=1:  _  _  _  _  _
--   z=2:  _  _  _  _  _
lazarus_space.schematics.skeleton_small = {
	size = {x = 5, y = 3, z = 3},
	data = {
		-- z=0
		-- y=0: ground level
		_, _, RIB, _, _,
		-- y=1
		_, _, _, _, _,
		-- y=2
		_, _, _, _, _,

		-- z=1 (center spine row)
		-- y=0: skull, ribs along spine, bone limb
		SKULL, RIB, BONE, RIB, BONE_50,
		-- y=1: rib arching up from middle
		_, _, RIB_50, _, _,
		-- y=2
		_, _, _, _, _,

		-- z=2
		-- y=0: rib extending from spine, bone limb
		_, _, RIB_50, _, _,
		-- y=1
		_, _, _, _, _,
		-- y=2
		_, _, _, _, _,
	},
}

-- skeleton_ribcage: 5x4x5 (W=5, H=4, D=5)
-- Exposed ribcage partially buried. yoffset=-1 (sinks 1 block into ground).
-- The bottom layer (y=0) is underground, ribs arch upward.
-- Spine runs along z-axis at x=2.
lazarus_space.schematics.skeleton_ribcage = {
	size = {x = 5, y = 4, z = 5},
	data = {
		-- z=0 (skull end)
		-- y=0 (underground)
		_, _, BONE, _, _,
		-- y=1 (ground level)
		_, _, SKULL, _, _,
		-- y=2
		_, _, _, _, _,
		-- y=3
		_, _, _, _, _,

		-- z=1 (first rib pair)
		-- y=0
		_, _, BONE, _, _,
		-- y=1
		_, RIB, _, RIB, _,
		-- y=2
		RIB_50, _, _, _, RIB_50,
		-- y=3
		_, _, _, _, _,

		-- z=2 (center - tallest ribs)
		-- y=0
		_, _, BONE, _, _,
		-- y=1
		_, RIB, _, RIB, _,
		-- y=2
		RIB, _, _, _, RIB,
		-- y=3
		RIB_50, _, _, _, RIB_50,

		-- z=3 (second rib pair)
		-- y=0
		_, _, BONE, _, _,
		-- y=1
		_, RIB, _, RIB, _,
		-- y=2
		RIB_50, _, _, _, RIB_50,
		-- y=3
		_, _, _, _, _,

		-- z=4 (tail end)
		-- y=0
		_, _, BONE_50, _, _,
		-- y=1
		_, _, _, _, _,
		-- y=2
		_, _, _, _, _,
		-- y=3
		_, _, _, _, _,
	},
}

-- skeleton_large: 7x3x4 (W=7, H=3, D=4)
-- Larger fallen skeleton. Longer spine (5 bone blocks along x), 4 rib arches,
-- skull at x=0, limbs at 2 positions.
lazarus_space.schematics.skeleton_large = {
	size = {x = 7, y = 3, z = 4},
	data = {
		-- z=0 (limb row)
		-- y=0: limbs extend from spine positions
		_, _, BONE_50, _, _, BONE_50, _,
		-- y=1
		_, _, _, _, _, _, _,
		-- y=2
		_, _, _, _, _, _, _,

		-- z=1 (main spine row)
		-- y=0: skull, spine bones, ribs at base
		SKULL, BONE, BONE, BONE, BONE, BONE, _,
		-- y=1: ribs arch up
		_, RIB, _, RIB, _, RIB_50, _,
		-- y=2
		_, _, _, _, _, _, _,

		-- z=2 (rib extension row)
		-- y=0: ribs extend from spine
		_, RIB_50, _, RIB, _, RIB, _,
		-- y=1: ribs arch up
		_, _, _, RIB_50, _, RIB_50, _,
		-- y=2
		_, _, _, _, _, _, _,

		-- z=3 (limb row)
		-- y=0: limbs extend from spine positions
		_, _, BONE_50, _, _, BONE_50, _,
		-- y=1
		_, _, _, _, _, _, _,
		-- y=2
		_, _, _, _, _, _, _,
	},
}

-- =============================================================================
-- Fleshy Mushroom Schematics
-- =============================================================================

-- flesh_mushroom_small: 3x5x3 (W=3, H=5, D=3)
-- Single stem column (1 block, 3 tall) at center x=1,z=1.
-- Cap at y=3 is 3x1x3 with corner air.
-- Glow block under cap center at y=2 (top of stem replaced with glow).
lazarus_space.schematics.flesh_mushroom_small = {
	size = {x = 3, y = 5, z = 3},
	data = {
		-- z=0
		-- y=0 (ground)
		_, _, _,
		-- y=1
		_, _, _,
		-- y=2
		_, _, _,
		-- y=3 (cap layer)
		_, CAP_EDGE, _,
		-- y=4
		_, _, _,

		-- z=1 (center)
		-- y=0 (stem base)
		_, STEM, _,
		-- y=1 (stem middle)
		_, STEM, _,
		-- y=2 (glow under cap)
		_, GLOW, _,
		-- y=3 (cap layer center row)
		CAP_EDGE, CAP, CAP_EDGE,
		-- y=4
		_, _, _,

		-- z=2
		-- y=0
		_, _, _,
		-- y=1
		_, _, _,
		-- y=2
		_, _, _,
		-- y=3 (cap layer)
		_, CAP_EDGE, _,
		-- y=4
		_, _, _,
	},
}

-- flesh_mushroom_medium: 5x8x5 (W=5, H=8, D=5)
-- Stem: 1 block wide, 5 tall at center (x=2, z=2), y=0..4.
-- Glow under cap at y=4 (top stem block replaced).
-- Cap bottom layer at y=5: glow center 3x3 with cap_edge border.
-- Cap top layer at y=6: cap center 3x3 with cap_edge border.
-- Some edge blocks at 70% for irregular shape.
-- y=7: empty
lazarus_space.schematics.flesh_mushroom_medium = {
	size = {x = 5, y = 8, z = 5},
	data = {
		-- z=0
		-- y=0..4: no stem here
		_, _, _, _, _,
		_, _, _, _, _,
		_, _, _, _, _,
		_, _, _, _, _,
		_, _, _, _, _,
		-- y=5 (cap bottom layer): edge blocks on z=0 row
		CAP_EDGE_70, CAP_EDGE, CAP_EDGE, CAP_EDGE, CAP_EDGE_70,
		-- y=6 (cap top layer)
		CAP_70, CAP, CAP, CAP, CAP_70,
		-- y=7
		_, _, _, _, _,

		-- z=1
		-- y=0..4
		_, _, _, _, _,
		_, _, _, _, _,
		_, _, _, _, _,
		_, _, _, _, _,
		_, _, _, _, _,
		-- y=5 (cap bottom): edge + glow center
		CAP_EDGE, GLOW, GLOW, GLOW, CAP_EDGE,
		-- y=6 (cap top): edge + cap center
		CAP, CAP, CAP, CAP, CAP,
		-- y=7
		_, _, _, _, _,

		-- z=2 (center row with stem)
		-- y=0 (stem base)
		_, _, STEM, _, _,
		-- y=1
		_, _, STEM, _, _,
		-- y=2
		_, _, STEM, _, _,
		-- y=3
		_, _, STEM, _, _,
		-- y=4 (glow under cap)
		_, _, GLOW, _, _,
		-- y=5 (cap bottom): edge + glow center
		CAP_EDGE, GLOW, GLOW, GLOW, CAP_EDGE,
		-- y=6 (cap top): edge + cap center
		CAP, CAP, CAP, CAP, CAP,
		-- y=7
		_, _, _, _, _,

		-- z=3
		-- y=0..4
		_, _, _, _, _,
		_, _, _, _, _,
		_, _, _, _, _,
		_, _, _, _, _,
		_, _, _, _, _,
		-- y=5 (cap bottom): edge + glow center
		CAP_EDGE, GLOW, GLOW, GLOW, CAP_EDGE,
		-- y=6 (cap top): edge + cap center
		CAP, CAP, CAP, CAP, CAP,
		-- y=7
		_, _, _, _, _,

		-- z=4
		-- y=0..4
		_, _, _, _, _,
		_, _, _, _, _,
		_, _, _, _, _,
		_, _, _, _, _,
		_, _, _, _, _,
		-- y=5 (cap bottom layer): edge blocks on z=4 row
		CAP_EDGE_70, CAP_EDGE, CAP_EDGE, CAP_EDGE, CAP_EDGE_70,
		-- y=6 (cap top layer)
		CAP_70, CAP, CAP, CAP, CAP_70,
		-- y=7
		_, _, _, _, _,
	},
}

-- flesh_mushroom_cluster: 7x6x7 (W=7, H=6, D=7)
-- Three mushrooms at different positions and heights:
--   Mushroom A: stem at (1,1), height 3, cap at y=2 (3x1x3 centered on stem)
--   Mushroom B: stem at (4,3), height 5, cap at y=4
--   Mushroom C: stem at (2,5), height 6, cap at y=5 (tallest)
-- Each stem is 1 block, each cap is 3x1x3 with corners as cap_edge.
lazarus_space.schematics.flesh_mushroom_cluster = {
	size = {x = 7, y = 6, z = 7},
	data = {
		-- z=0
		-- y=0..5: all air-skip for z=0 (mushroom A cap extends here at z=0)
		-- y=0
		_, _, _, _, _, _, _,
		-- y=1
		_, _, _, _, _, _, _,
		-- y=2 (mushA cap at z=0, centered on x=1): edge at x=1
		_, CAP_EDGE, _, _, _, _, _,
		-- y=3
		_, _, _, _, _, _, _,
		-- y=4
		_, _, _, _, _, _, _,
		-- y=5
		_, _, _, _, _, _, _,

		-- z=1 (mushroom A stem row)
		-- y=0 (stem base)
		_, STEM, _, _, _, _, _,
		-- y=1 (stem)
		_, GLOW, _, _, _, _, _,
		-- y=2 (cap center row): edge, cap, edge
		CAP_EDGE, CAP, CAP_EDGE, _, _, _, _,
		-- y=3
		_, _, _, _, _, _, _,
		-- y=4
		_, _, _, _, _, _, _,
		-- y=5
		_, _, _, _, _, _, _,

		-- z=2 (mushA cap extends here)
		-- y=0
		_, _, _, _, _, _, _,
		-- y=1
		_, _, _, _, _, _, _,
		-- y=2: edge at x=1
		_, CAP_EDGE, _, _, _, _, _,
		-- y=3
		_, _, _, _, _, _, _,
		-- y=4 (mushB cap at z=2, centered on x=4): edge at x=4
		_, _, _, _, CAP_EDGE, _, _,
		-- y=5
		_, _, _, _, _, _, _,

		-- z=3 (mushroom B stem row)
		-- y=0 (stem base)
		_, _, _, _, STEM, _, _,
		-- y=1
		_, _, _, _, STEM, _, _,
		-- y=2
		_, _, _, _, STEM, _, _,
		-- y=3
		_, _, _, _, GLOW, _, _,
		-- y=4 (mushB cap center row): edge, cap, edge
		_, _, _, CAP_EDGE, CAP, CAP_EDGE, _,
		-- y=5
		_, _, _, _, _, _, _,

		-- z=4 (mushB cap extends, mushC cap extends)
		-- y=0
		_, _, _, _, _, _, _,
		-- y=1
		_, _, _, _, _, _, _,
		-- y=2
		_, _, _, _, _, _, _,
		-- y=3
		_, _, _, _, _, _, _,
		-- y=4: mushB cap edge at x=4
		_, _, _, _, CAP_EDGE, _, _,
		-- y=5: mushC cap edge at x=2
		_, _, CAP_EDGE, _, _, _, _,

		-- z=5 (mushroom C stem row)
		-- y=0 (stem base)
		_, _, STEM, _, _, _, _,
		-- y=1
		_, _, STEM, _, _, _, _,
		-- y=2
		_, _, STEM, _, _, _, _,
		-- y=3
		_, _, STEM, _, _, _, _,
		-- y=4
		_, _, GLOW, _, _, _, _,
		-- y=5 (mushC cap center row): edge, cap, edge
		_, CAP_EDGE, CAP, CAP_EDGE, _, _, _,

		-- z=6 (mushC cap extends)
		-- y=0
		_, _, _, _, _, _, _,
		-- y=1
		_, _, _, _, _, _, _,
		-- y=2
		_, _, _, _, _, _, _,
		-- y=3
		_, _, _, _, _, _, _,
		-- y=4
		_, _, _, _, _, _, _,
		-- y=5: mushC cap edge at x=2
		_, _, CAP_EDGE, _, _, _, _,
	},
}

-- =============================================================================
-- Tall Grass Schematics
-- =============================================================================

-- grass_patch: 3x1x3 (W=3, H=1, D=3)
-- 3x3 arrangement of bio_grass variants, each at 70% probability.
-- Non-grass positions use air-skip.
lazarus_space.schematics.grass_patch = {
	size = {x = 3, y = 1, z = 3},
	data = {
		-- z=0, y=0
		GRASS_1, GRASS_3, GRASS_1,
		-- z=1, y=0
		GRASS_1, GRASS_1, GRASS_3,
		-- z=2, y=0
		GRASS_3, GRASS_1, GRASS_1,
	},
}

-- grass_tall_patch: 5x1x5 (W=5, H=1, D=5)
-- Center 3x3 has bio_grass_tall at 60% (prob=152).
-- Outer ring has bio_grass_1/bio_grass_3 at 50% (prob=127).
-- Non-grass positions use air-skip.
lazarus_space.schematics.grass_tall_patch = {
	size = {x = 5, y = 1, z = 5},
	data = {
		-- z=0, y=0
		_, GRASS_1_50, GRASS_3_50, GRASS_1_50, _,
		-- z=1, y=0
		GRASS_3_50, GRASS_TALL, GRASS_TALL, GRASS_TALL, GRASS_1_50,
		-- z=2, y=0
		GRASS_1_50, GRASS_TALL, GRASS_TALL, GRASS_TALL, GRASS_3_50,
		-- z=3, y=0
		GRASS_3_50, GRASS_TALL, GRASS_TALL, GRASS_TALL, GRASS_1_50,
		-- z=4, y=0
		_, GRASS_3_50, GRASS_1_50, GRASS_3_50, _,
	},
}

-- =============================================================================
-- Ruin Schematics (placeholder — designed for easy hand-editing later)
-- =============================================================================

-- Shorthand helpers for ruin blocks
local PILLAR     = {name = "lazarus_space:bone_block", prob = 254}
local PILLAR_50  = {name = "lazarus_space:bone_block", prob = 127}
local PILLAR_30  = {name = "lazarus_space:bone_block", prob = 76}
local SLAB       = {name = "lazarus_space:bone_slab", prob = 254}
local SLAB_40    = {name = "lazarus_space:bone_slab", prob = 101}
local SLAB_50    = {name = "lazarus_space:bone_slab", prob = 127}
local WALL       = {name = "default:stone", prob = 254}
local WALL_60    = {name = "default:stone", prob = 152}
local WALL_40    = {name = "default:stone", prob = 101}
local WALL_50    = {name = "default:stone", prob = 127}
local ARCH       = {name = "default:dirt", prob = 254}
local STEEL      = {name = "default:steelblock", prob = 254}
local STEEL_50   = {name = "default:steelblock", prob = 127}
local STEEL_40   = {name = "default:steelblock", prob = 101}
local STEEL_30   = {name = "default:steelblock", prob = 76}

-- ruin_small_wall: 5x3x2 (W=5, H=3, D=2)
-- A short crumbling wall segment.
-- Bottom row: 5 ruin_wall in a line. Middle: 3 with gaps. Top: scattered slabs.
lazarus_space.schematics.ruin_small_wall = {
	size = {x = 5, y = 3, z = 2},
	data = {
		-- z=0
		-- y=0 (ground): full wall row
		WALL, WALL, STEEL_30, WALL, WALL,
		-- y=1: gaps at ends
		_, WALL_60, WALL, WALL_60, _,
		-- y=2: scattered slabs
		_, SLAB_40, _, SLAB_40, _,

		-- z=1 (back face — thinner)
		-- y=0
		WALL_60, WALL, WALL, STEEL_30, WALL_60,
		-- y=1
		_, WALL_40, WALL_60, WALL_40, _,
		-- y=2
		_, _, SLAB_40, _, _,
	},
}

-- ruin_pillar_pair: 3x5x3 (W=3, H=5, D=3)
-- Two bone pillars 2 blocks apart, bridged at top with a slab.
lazarus_space.schematics.ruin_pillar_pair = {
	size = {x = 3, y = 5, z = 3},
	data = {
		-- z=0
		-- y=0..4
		_, _, _,
		_, _, _,
		_, _, _,
		_, _, _,
		_, _, _,

		-- z=1 (center row with pillars)
		-- y=0 (base)
		PILLAR, STEEL_50, PILLAR,
		-- y=1
		PILLAR, _, PILLAR,
		-- y=2
		PILLAR, _, PILLAR_50,
		-- y=3
		PILLAR_50, _, PILLAR_30,
		-- y=4 (top: slab bridge)
		SLAB_50, SLAB, SLAB_50,

		-- z=2
		-- y=0..4
		_, _, _,
		_, _, _,
		_, _, _,
		_, _, _,
		_, _, _,
	},
}

-- ruin_archway: 5x4x3 (W=5, H=4, D=3)
-- Two pillars on outer edges with arch bridging top, wall fill on sides.
lazarus_space.schematics.ruin_archway = {
	size = {x = 5, y = 4, z = 3},
	data = {
		-- z=0
		-- y=0..3
		_, _, _, _, _,
		_, _, _, _, _,
		_, _, _, _, _,
		_, _, _, _, _,

		-- z=1 (center row)
		-- y=0 (base)
		PILLAR, STEEL_40, _, STEEL_40, PILLAR,
		-- y=1
		PILLAR, _, _, _, PILLAR,
		-- y=2
		PILLAR_50, _, _, _, PILLAR_50,
		-- y=3 (top: arch)
		WALL_40, SLAB, ARCH, SLAB, WALL_40,

		-- z=2
		-- y=0..3
		_, _, _, _, _,
		_, _, _, _, _,
		_, _, _, _, _,
		_, _, _, _, _,
	},
}

-- ruin_foundation: 7x2x7 (W=7, H=2, D=7)
-- Square foundation outline: bone_slab border, occasional wall at corners/midpoints.
lazarus_space.schematics.ruin_foundation = {
	size = {x = 7, y = 2, z = 7},
	data = {
		-- z=0 (south edge)
		-- y=0 (ground): full perimeter
		SLAB, SLAB, SLAB, SLAB, SLAB, SLAB, SLAB,
		-- y=1: walls at corners/midpoints
		WALL_50, _, _, WALL_50, _, _, WALL_50,

		-- z=1
		-- y=0: side edges only
		SLAB, _, _, _, _, _, SLAB,
		-- y=1
		_, _, _, _, _, _, _,

		-- z=2
		-- y=0: side edges only
		SLAB, _, STEEL_30, _, _, _, SLAB,
		-- y=1
		_, _, _, _, _, _, _,

		-- z=3 (center)
		-- y=0: side edges + midpoint
		SLAB, _, _, STEEL_30, _, _, SLAB,
		-- y=1
		WALL_50, _, _, _, _, _, WALL_50,

		-- z=4
		-- y=0: side edges only
		SLAB, _, _, _, STEEL_30, _, SLAB,
		-- y=1
		_, _, _, _, _, _, _,

		-- z=5
		-- y=0: side edges only
		SLAB, _, _, _, _, _, SLAB,
		-- y=1
		_, _, _, _, _, _, _,

		-- z=6 (north edge)
		-- y=0: full perimeter
		SLAB, SLAB, SLAB, SLAB, SLAB, SLAB, SLAB,
		-- y=1: walls at corners/midpoints
		WALL_50, _, _, WALL_50, _, _, WALL_50,
	},
}

-- =============================================================================
-- Y-Offset Lookup
-- =============================================================================

lazarus_space.schematic_yoffsets = {
	skeleton_small = 0,
	skeleton_ribcage = -1,
	skeleton_large = 0,
	flesh_mushroom_small = 0,
	flesh_mushroom_medium = 0,
	flesh_mushroom_cluster = 0,
	grass_patch = 0,
	grass_tall_patch = 0,
	ruin_small_wall = 0,
	ruin_pillar_pair = 0,
	ruin_archway = 0,
	ruin_foundation = 0,
	outpost_shelter = 0,
	outpost_watchtower = 0,
	outpost_ruin = 0,
}

-- =============================================================================
-- Outpost Schematics (evidence of past visitors in Vein Flats)
-- =============================================================================

-- Shorthand helpers for outpost blocks
local MUSCLE      = {name = "lazarus_space:flesh", prob = 254}
local MUSCLE_80   = {name = "lazarus_space:flesh", prob = 203}
local MUSCLE_40   = {name = "lazarus_space:flesh", prob = 101}
local BEAM        = {name = "default:stone", prob = 254}
local BEAM_70     = {name = "default:stone", prob = 178}
local BONE_60     = {name = "lazarus_space:bone", prob = 152}
local SLAB_60     = {name = "lazarus_space:bone_slab", prob = 152}
local SLAB_70     = {name = "lazarus_space:bone_slab", prob = 178}
local WALL_30     = {name = "default:stone", prob = 76}

-- outpost_shelter: 5x4x5 (W=5, H=4, D=5)
-- A simple roofed shelter with corner bone posts, one muscle wall, bone_slab floor.
lazarus_space.schematics.outpost_shelter = {
	size = {x = 5, y = 4, z = 5},
	data = {
		-- z=0
		-- y=0 (floor level)
		BONE, SLAB_60, SLAB_60, SLAB_60, BONE,
		-- y=1
		BONE, A, A, A, BONE,
		-- y=2
		BONE, A, A, A, BONE,
		-- y=3 (roof)
		SLAB, SLAB, SLAB, SLAB, SLAB,

		-- z=1
		-- y=0
		SLAB_60, SLAB_60, SLAB_60, SLAB_60, SLAB_60,
		-- y=1 (muscle wall on one side)
		MUSCLE_80, A, A, A, _,
		-- y=2
		MUSCLE_80, A, A, A, _,
		-- y=3 (roof)
		SLAB, _, _, _, SLAB,

		-- z=2
		-- y=0
		SLAB_60, SLAB_60, STEEL_40, SLAB_60, SLAB_60,
		-- y=1
		MUSCLE_80, A, A, A, _,
		-- y=2
		MUSCLE_80, A, A, A, _,
		-- y=3 (roof)
		SLAB, _, _, _, SLAB,

		-- z=3
		-- y=0
		SLAB_60, SLAB_60, SLAB_60, STEEL_40, SLAB_60,
		-- y=1
		_, A, A, A, _,
		-- y=2
		_, A, A, A, _,
		-- y=3 (roof)
		SLAB, _, _, _, SLAB,

		-- z=4
		-- y=0
		BONE, SLAB_60, SLAB_60, SLAB_60, BONE,
		-- y=1
		BONE, A, A, A, BONE,
		-- y=2
		BONE, A, A, A, BONE,
		-- y=3 (roof)
		SLAB, SLAB, SLAB, SLAB, SLAB,
	},
}

-- outpost_watchtower: 3x8x3 (W=3, H=8, D=3)
-- A tall narrow lookout with central bone_pillar column, platform at top.
lazarus_space.schematics.outpost_watchtower = {
	size = {x = 3, y = 8, z = 3},
	data = {
		-- z=0
		-- y=0 (base)
		BONE_60, _, BONE_60,
		-- y=1
		_, _, _,
		-- y=2
		_, _, _,
		-- y=3 (cross-brace level)
		_, BEAM_70, _,
		-- y=4
		_, _, _,
		-- y=5
		_, _, _,
		-- y=6 (platform)
		SLAB, SLAB, SLAB,
		-- y=7
		_, _, _,

		-- z=1 (center column)
		-- y=0
		STEEL_50, PILLAR, _,
		-- y=1
		_, PILLAR, _,
		-- y=2
		_, PILLAR, _,
		-- y=3
		BEAM_70, PILLAR, BEAM_70,
		-- y=4
		_, PILLAR, _,
		-- y=5
		_, PILLAR, _,
		-- y=6 (platform)
		SLAB, SLAB, SLAB,
		-- y=7
		_, _, _,

		-- z=2
		-- y=0
		BONE_60, _, BONE_60,
		-- y=1
		_, _, _,
		-- y=2
		_, _, _,
		-- y=3
		_, BEAM_70, _,
		-- y=4
		_, _, _,
		-- y=5
		_, _, _,
		-- y=6 (platform)
		SLAB, SLAB, SLAB,
		-- y=7
		_, _, _,
	},
}

-- outpost_ruin: 7x3x7 (W=7, H=3, D=7)
-- A collapsed larger structure: perimeter foundation, partial walls, debris.
lazarus_space.schematics.outpost_ruin = {
	size = {x = 7, y = 3, z = 7},
	data = {
		-- z=0 (south edge)
		-- y=0 (ground)
		SLAB_70, SLAB_70, SLAB_70, SLAB_70, SLAB_70, SLAB_70, SLAB_70,
		-- y=1
		BONE, _, _, _, _, _, _,
		-- y=2
		BONE, _, _, _, _, _, _,

		-- z=1
		-- y=0
		SLAB_70, _, _, _, _, _, SLAB_70,
		-- y=1
		_, _, _, _, _, _, MUSCLE_40,
		-- y=2
		_, _, _, _, _, _, MUSCLE_40,

		-- z=2
		-- y=0
		SLAB_70, _, WALL_30, STEEL_30, SLAB_40, _, SLAB_70,
		-- y=1
		_, _, _, _, _, _, _,
		-- y=2
		_, _, _, _, _, _, _,

		-- z=3
		-- y=0
		SLAB_70, _, STEEL_30, _, _, _, SLAB_70,
		-- y=1
		MUSCLE_40, _, _, SLAB_40, _, _, _,
		-- y=2
		_, _, _, _, _, _, _,

		-- z=4
		-- y=0
		SLAB_70, _, WALL_30, _, STEEL_30, _, SLAB_70,
		-- y=1
		_, _, _, _, _, _, _,
		-- y=2
		_, _, _, _, _, _, _,

		-- z=5
		-- y=0
		SLAB_70, _, _, _, STEEL_30, _, SLAB_70,
		-- y=1
		_, _, _, _, _, _, MUSCLE_40,
		-- y=2
		_, _, _, _, _, _, _,

		-- z=6 (north edge)
		-- y=0
		SLAB_70, SLAB_70, SLAB_70, SLAB_70, SLAB_70, SLAB_70, SLAB_70,
		-- y=1
		_, _, _, _, _, _, BONE,
		-- y=2
		_, _, _, _, _, _, BONE,
	},
}

-- =============================================================================
-- Placement Configuration Table
-- =============================================================================

lazarus_space.schematic_placement = {
	-- Surface grass placements (all surface biomes)
	grass = {
		biomes = {
			"rib_fields", "molar_peaks", "vein_flats",
			"coral_cliffs", "nerve_thicket", "abscess_marsh",
		},
		schematics = {
			{name = "grass_patch", chance = 120},       -- 1 in 120 (was 30)
			{name = "grass_tall_patch", chance = 320},  -- 1 in 320 (was 80)
		},
	},

	-- Skeleton placements (biome-specific chances and variant restrictions)
	skeleton = {
		biome_chances = {
			rib_fields = 1600,      -- 1 in 1600 (was 400)
			abscess_marsh = 2000,   -- 1 in 2000 (was 500), skeleton_small only
			molar_peaks = 2400,     -- 1 in 2400 (was 600), skeleton_ribcage only
			vein_flats = 3200,      -- 1 in 3200 (was 800), skeleton_small only
		},
		variants = {"skeleton_small", "skeleton_ribcage", "skeleton_large"},
		biome_variants = {
			abscess_marsh = {"skeleton_small"},
			molar_peaks = {"skeleton_ribcage"},
			vein_flats = {"skeleton_small"},
		},
	},

	-- Mushroom placements (biome-specific chances and variant restrictions)
	mushroom = {
		biome_chances = {
			nerve_thicket = 400,    -- 1 in 400 (was 100)
			coral_cliffs = 800,     -- 1 in 800 (was 200)
			abscess_marsh = 600,    -- 1 in 600 (was 150)
			rib_fields = 1000,      -- 1 in 1000 (was 250)
			vein_flats = 1200,      -- 1 in 1200 (was 300)
		},
		variants = {"flesh_mushroom_small", "flesh_mushroom_medium", "flesh_mushroom_cluster"},
		biome_variants = {
			coral_cliffs = {"flesh_mushroom_small", "flesh_mushroom_medium"},
			abscess_marsh = {"flesh_mushroom_small"},
			vein_flats = {"flesh_mushroom_small"},
		},
	},

	-- Ruin placements (biome-specific, placeholder schematics)
	ruin = {
		biome_chances = {
			rib_fields = 1500,      -- 1 in 1500, any ruin variant (was 3000)
			abscess_marsh = 2000,   -- 1 in 2000, foundation/wall only (was 4000)
			nerve_thicket = 1750,   -- 1 in 1750, pillar_pair/archway only (was 3500)
			vein_flats = 2500,      -- 1 in 2500, foundation only (was 5000)
		},
		variants = {"ruin_small_wall", "ruin_pillar_pair", "ruin_archway", "ruin_foundation"},
		biome_variants = {
			abscess_marsh = {"ruin_foundation", "ruin_small_wall"},
			nerve_thicket = {"ruin_pillar_pair", "ruin_archway"},
			vein_flats = {"ruin_foundation"},
		},
	},

	-- Outpost placements (Vein Flats only — evidence of past visitors)
	outpost = {
		biome_chances = {
			vein_flats = 1750,      -- 1 in 1750, flat terrain only (was 3500)
		},
		variants = {"outpost_shelter", "outpost_watchtower", "outpost_ruin"},
	},

	-- Cave placements (all cave biomes)
	cave = {
		mushroom_chance = 800,     -- 1 in 800 (was 200)
		skeleton_chance = 3200,    -- 1 in 3200 (was 800)
	},
}
