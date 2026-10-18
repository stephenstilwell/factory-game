# Graphics modernization roadmap

Updated 2026-10-17. G1’s [foundation pass](graphics-foundation.md) and G2’s [hero-art/batching pilot](hero-art-pilot.md) are implemented; G3’s [material/occlusion pilot](graphics-materials.md) is implemented; G4–G6 remain backlog work.

## Art direction

Oldbridge should look like an illustrated industrial settlement: textured natural ground, cool outdoor shadows, warm occupied buildings and machinery with readable material edges. Restoration should be visually rewarding. Keep clean silhouettes, legible ore and transport direction, and a UI isolated from world lighting.

The largest eventual change is richer authored artwork. Lighting can improve the current vector foundations, but it cannot supply missing building geometry, material design or character animation.

## Delivery order

| Slice | Work | Acceptance |
| --- | --- | --- |
| G1 — implemented | Fixed daylight, bounded shader light fields, shared shadow direction, softer contact shadows, baked terrain texture and water edges/surface detail | Native before/after captures, unchanged simulation/saves, bounded lights/scenery, restored versus ruined contrast, ambient/reduced-motion controls, minimum-window/4K regression |
| G2 — pilot implemented | Hero asset pilot: tree, furnace, player and Town Hall | Reusable/batched machine-body rendering before expanding per-machine detail; one cohesive material/shape language; clear zoomed-out silhouettes; layered working/ruined/restored variants; compare a finished small scene before expanding the asset set |
| G3 — pilot implemented | Lighting-aware assets and selective occlusion | Evaluate sprite normal/specular maps and limited light occluders against G2 assets; profile before expanding shadow-casting lights; keep a low-cost fallback |
| G4 | Machine and settlement life | Strong working/idle/blocked animations, better smoke/heat, readable transport handoffs, richer restored-building activity; bounded visible effects and reduced-motion support |
| G5 | Regional composition and water depth | More organic shores, shallow/deep transitions, restrained reflections, canopy variation and regional atmospheric layers; effects must match physical terrain and preserve construction readability |
| G6 | Quality tiers and presentation finish | Measured budgets at 1100×720 and 4K; optional antialiasing/post-processing where supported; accessible brightness/effects controls; test representative large factories |

G2’s four-asset pilot is implemented. G3 adds furnace/Town Hall surface maps and bounded local-light occlusion; G4 is next. Do not add normal maps and occluders across the existing shape library before reviewing their value.

## G1 scope and boundaries

Use the current Compatibility renderer and existing artwork. Establish a static daylight treatment and one shared sun/shadow direction; no new gameplay clock, night attacks, weather simulation or saved visual state.

Use a capped single-pass shader light field for operational windows/hearths and working burners. Native-light profiling exposed excessive redraw work in the current immediate-mode world; avoid a node or shadow map per machine. The first directional silhouettes are inexpensive layered projections; they are not geometry-accurate real-time occlusion.

Texture the cached ground and soften lighting transitions without hiding ore or turning every empty cell into a decorative object. Water surface highlights must follow real marsh water and leave causeways readable. Shore treatment must agree at chunk borders.

Honor the ambient toggle and reduced motion. The HUD and menus remain outside the world-lighting canvas. Animation must stop with pause; static material/shadow improvements remain useful when ambience is disabled.

## Backlog guardrails

- Do not switch renderers as a substitute for art direction. Reassess only for a concrete feature with measured value.
- No mandatory full-screen blur, chromatic aberration, heavy bloom, opaque fog or extreme darkness.
- Preserve machine status cues, ore colors, target highlights and readable bridge edges.
- Reuse textures and fixed light data; gather only visible sources. Validate worst-case factories rather than only empty scenes.
- Asset licensing, import filtering, atlas/pivot conventions and resolution budgets must be recorded for G2.
- Day/night and weather are separate design decisions because they affect readability, music, schedules and potentially combat.
- Keep technical effects out of save data unless they become actual gameplay systems.

## Verification

Native captures compare town, orchard and marsh before/after the first slice. Model/UI checks verify light selection and caps, settings, water masking, node reuse and unchanged saves. Record native rendering observations separately from simulation checks; screenshots and pass counts are not an FPS benchmark. G2 reduces the paused furnace diagnostic draw calls by about 76% at minimum size and 63% at 4K. The dense 4K scene remains slow; broader machine-body batching must continue before increasing rendering cost.
