# PROMPTS_005_UPDATE_044 — Fix Congealed Rotten Plasma, Extend Plasma Ocean, Livable Asteroid Spheroid Noise

SpecSwarm command: `/modify`

This update makes congealed_rotten_plasma breakable, extends the plasma ocean deeper with a noisy underside, and applies noise displacement to both the top and bottom of livable asteroid spheroids so they aren't flat.

---

## Prompt 1 of 3 — Fix Congealed Rotten Plasma Interaction

### Files: `bio_nodes.lua`

The `lazarus_space:congealed_rotten_plasma` node cannot be interacted with or deleted by the player. This is likely because it was inherited from `ceiling_membrane` which was designed as an unbreakable barrier, or its groups are missing/incorrect.

Find the node registration for `lazarus_space:congealed_rotten_plasma` in `bio_nodes.lua` and fix:

1. **Add breakable groups**: Ensure the node has groups that allow players to dig it. Set:
   ```lua
   groups = {cracky = 2, crumbly = 1}
   ```
   If it currently has `not_in_creative_inventory` or no digging groups, add the above. If it has `diggable = false` or similar blocking properties, remove them.

2. **Remove unbreakable flags**: Check for any of these properties that would prevent interaction and remove them:
   - `diggable = false` → remove
   - `pointable = false` → remove or set to `true`
   - Empty `groups = {}` → replace with breakable groups
   - `on_blast = function() end` or similar blast resistance → remove

3. **Verify sounds**: Make sure it has dig/place sounds (stone sounds are appropriate):
   ```lua
   sounds = default.node_sound_stone_defaults()
   ```

4. **Check other congealed variants**: While fixing this, also verify that `congealed_plasma` and `congealed_blood` are both breakable and interactable. If either has the same problem, apply the same fix.

5. **Exception — death_space**: `death_space` should remain unbreakable. Do NOT modify death_space.

---

## Prompt 2 of 3 — Extend Plasma Ocean Downward with Noisy Underside

### Files: `bio_mapgen.lua`

The plasma ocean (currently y=27712-27775) needs to extend 10 blocks deeper and have a noise-displaced underside instead of a flat bottom.

#### Extend Depth

Move the plasma ocean bottom boundary down by 10 blocks:
- **Old bottom**: y=27712
- **New bottom**: y=27702

This extends the plasma layer down through the upper portion of the jelly/membrane transition zone and slightly into the top of the cave system. The plasma now seeps deeper.

Update all constants and y-range checks that reference the plasma ocean bottom boundary.

#### Noisy Underside

The bottom surface of the plasma ocean is currently a flat horizontal cutoff. Add 2D Perlin noise displacement:

- **Noise**: 2D Perlin sampled at (x, z)
  - Spread: 20-35 (medium scale)
  - Octaves: 3
  - Persistence: 0.6
  - Amplitude: ±8 blocks of vertical displacement

- **Effect**: The effective bottom of the plasma at each (x, z) = `27702 + noise_displacement`. The underside of the ocean undulates between approximately y=27694 and y=27710. Some spots the plasma hangs lower, creating dripping pockets. Other spots are cut higher, creating air gaps beneath the ocean.

- **Plasma placement**: Fill with `plasma_source` above the displaced bottom at each position. Below the displaced bottom: air (or whatever the underlying terrain generates — jelly membrane, cave material, etc.).

- **Interaction with existing layers**: Where the extended plasma overlaps with what was previously the jelly/membrane layer (y=27697-27712), the plasma takes priority — replace jelly/membrane blocks with `plasma_source` in the overlap zone. The jelly layer effectively gets thinner or disappears in spots where the plasma hangs low.

---

## Prompt 3 of 3 — Livable Asteroid Spheroid Top/Bottom Noise

### Files: `bio_mapgen.lua`

The livable (hollow) asteroid spheroids in the upper asteroid field are being generated as smooth geometric spheres, which means their top and bottom surfaces are unnaturally round and clean. The top and bottom of each spheroid need noise displacement so they look like rough organic masses, not perfect spheres.

#### Apply Noise to Spheroid Shape

When generating each livable asteroid spheroid, modify the distance-from-center calculation that determines the sphere boundary:

**Current approach** (assumed): A block is inside the asteroid if its distance from the spheroid center is less than the radius.

**New approach**: Add a 3D noise displacement to the radius check:

```
effective_radius = base_radius + noise3d(x, y, z) * displacement_amplitude
```

Where:
- `noise3d` is a 3D Perlin noise with:
  - Spread: 6-10 (small relative to asteroid size — creates chunky bumps)
  - Octaves: 2
  - Persistence: 0.5
- `displacement_amplitude`: ±3-5 blocks (scales with asteroid size — larger asteroids get more displacement)

This deforms the entire spheroid surface, including the top and bottom, creating an irregular organic blob shape instead of a perfect sphere.

#### Stronger Displacement on Top and Bottom

The flat-looking top and bottom are the most noticeable problem. Apply extra displacement to the polar regions:

- Calculate the vertical angle of each block relative to the spheroid center. Blocks near the top pole (directly above center) and bottom pole (directly below center) get **1.5× the displacement amplitude**.
- Blocks near the equator (horizontal ring around the middle) get the normal 1.0× amplitude.
- Interpolate smoothly between 1.0× at equator and 1.5× at poles using the absolute value of the y-offset normalized by the radius.

This specifically roughens up the top and bottom of each spheroid while keeping the sides at normal roughness.

#### Preserve Interior

The noise displacement affects only the outer shell boundary. The interior cavity (where dirt, grass, water, and air exist) should NOT be affected by this noise. The interior cavity keeps its own shape (already has aggressive deformation from UPDATE_038).

If the outer shell noise would push the shell inward past the interior cavity boundary at any point, clamp it — the shell thickness should never be less than 2 blocks.

---

## Summary

| Prompt | Changes |
|--------|---------|
| 1 | Fix `congealed_rotten_plasma` to be breakable — add `{cracky=2, crumbly=1}`, remove any unbreakable flags. Also verify congealed_plasma and congealed_blood are breakable. |
| 2 | Plasma ocean bottom extended 10 blocks (27712→27702) with ±8 block noise displacement on underside (spread 20-35, 3 octaves). Plasma overrides jelly layer in overlap zone. |
| 3 | Livable asteroid spheroids get 3D noise displacement on outer shell (spread 6-10, ±3-5 blocks), with 1.5× extra displacement at top/bottom poles. Interior cavity preserved with min 2-block shell thickness. |
