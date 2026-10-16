# Art direction: a warm industrial frontier

Oldbridge should feel like a place worth bringing back: mossy ground, weathered masonry, painted steel, copper roofs, warm windows, and small signs of returning life. This first visual pass establishes that language using native, antialiased Godot shapes. It is an illustrated vector foundation, not a finished sprite/animation asset set.

## Visual rules

- **Nature:** muted olive and moss, subtle broad ground variation, small grass clumps, pale flowers, and occasional pebbles. Decorative scenery is passable and never implies new solid trees or rocks.
- **Production:** cool teal steel, brass/copper mechanisms, ivory highlights, and consistent bottom-right shadows. Machines have distinct silhouettes rather than sharing one colored square.
- **Home:** warm stone, patinated roofs, amber windows, flagstone courtyards, winding tracks, planters, awnings, and residents on restored porches. Ruins keep broken rafters, boarded windows, rubble, and ivy. Disabled civic buildings lose their working lights and activity.
- **Threat:** rust-colored salvage machines, restrained amber tracers and impact flashes, clear health bars, and an eastern approach that stays readable against the grass. The beacon is dim while idle, and pulses warmly only during preparation or combat.
- **Interface:** cream text, sage selection, amber objectives, quiet dark surfaces, and consistent dropdowns/progress bars. Building icons reuse the actual machine renderer so silhouettes learned in the pack match the world.

The permanent terrain grid is removed. Equipping a building reveals a local grid around the engineer, a translucent preview of the actual building, and facing/reach feedback. Invalid previews tint red. Resource colors and all gameplay tile boundaries remain unchanged.

## Motion and feedback

The engineer has boots, work clothes, a pack, goggles, a brass helmet, a scarf, and a small lantern. Walking animates the stride; active hand mining uses a directional pick swing. Successful extraction throws a small resource-colored chip burst; successful repair throws warm sparks.

Drills turn their augers and gears and throw restrained dust while working. Furnaces have brick bodies, chimneys, warm animated fire, and light smoke only when producing. Belts move their slats and interpolate carried goods when the next belt is open. Inserter arms and their carried items share the same travel position. Assemblers have turning gears; labs have glass highlights and reagent motion. Turrets track targets, recoil, flash, and display short shot/impact effects.

Smoke, particles, and motion pause with the simulation. These are visual approximations of authoritative work/transport; they do not grant items, move inventories, or change timers. Restored residents are decorative characters, not a population simulation.

## Renderer ownership

| File | Purpose |
| --- | --- |
| `view/art.gd` | Shared materials, rounded shapes, elliptical shadows, light halos, and smoke |
| `view/terrain_chunk.gd` | Cached seed-stable ground decoration and faceted ore clusters |
| `view/landscape_view.gd` | Courtyards and cached decorative road curves |
| `view/machine_art.gd` | Machine silhouettes and state-driven motion, shared with inventory icons |
| `view/engineer_art.gd` | Character appearance and tool poses |
| `view/placement_preview.gd` | One reusable, translucent building preview with valid/invalid tint |
| `view/settlement_view.gd` | Ruined/restored civic variants, porch details, residents, and beacon |
| `view/defense_view.gd` | Approach, scavengers, shot tracers, and impacts |
| `view/visual_effects.gd` | Bounded action-particle pool, maximum 96 particles |
| `view/world_view.gd` | Visible-object depth ordering, contextual grid, and presentation orchestration |

World-space objects sort by their ground contact depth so elevated machines and roofs can cover characters behind them. Terrain stays cached by chunk; only visible dynamic objects are drawn. Ground noise uses the saved world seed through its own visual noise source. Particle RNG is local and does not consume simulation randomness. Roads and decorative details never affect collisions or resource generation.

The view listens to successful `hand_resource_extracted` and `structure_repaired` events, disconnecting from the old world when rebinding. These action signals can later support sound as well. Particles, draw order, noise, and animation state are never saved.

## Review captures

```powershell
godot --path . --script res://tests/capture_art.gd
```

This renders working factory machinery, a second animation frame, inventory icons, placement-grid context, and matching ruined/restored Oldbridge views at 1280×800. It also checks that rendering leaves authoritative factory state unchanged. Files appear under `.godot/verification/art_*.png`. The existing `capture_preview.gd` covers menus and active defense scenes; `verify_display.gd` checks fullscreen switching.

Next art work should add more character directions and explicit interaction poses, refine terrain transitions, and explore a small set of authored landmark details. Keep the existing state-driven renderer and clear silhouettes as the reference before expanding the asset library.

## Interface and atmosphere pass

Panels, selected tabs, focus outlines, tooltips, dropdowns, and scrollbars share teal and warm gold materials. Subtle interaction/menu transitions preserve input geometry. Warm furnace/settlement light, ground shadows, world-anchored motes, and bounded placement feedback reinforce the existing illustrated world. Esc offers reduced-motion and ambient-effects controls. See [interface polish](interface-polish.md) for visual budgets, accessibility, and verification.
