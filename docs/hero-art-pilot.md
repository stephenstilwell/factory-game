# Hero artwork and batching pilot: G2

Implemented 2026-10-17. This is the four-asset pilot from the [graphics roadmap](graphics-roadmap.md), not a replacement for every existing building and biome asset.

## Delivered artwork

- **Furnace:** masonry, copper bands, iron flue and chamber detail. Six shared frames cover cold idle, four working flame/smoke poses and damaged/disabled state.
- **Trees:** two mature woodland palettes plus blossom/fruit Orchard variants, with shaped canopy layers, bark and branch highlights. Existing seedlings, forestry growth and region-specific Greybank fir/Marsh willow art remain intact.
- **Player:** front, back and left/right restoration-worker views: moss utility clothing, a weather cap, scarf, satchel and brass lantern. Existing walking feet, body bob, mining tool and rifle aiming remain gameplay-driven.
- **Town Hall:** shared ruin, wood/stone restored and wood/stone disabled variants. Materials, boarded openings, roof damage, steps, warm windows and planters distinguish states. Existing beacon, entrance, selection, health bars and civic gameplay remain separate.

The common palette is weathered stone, patinated copper, moss cloth/foliage and warm brass. Existing world lighting and projected shadows still apply. No collision, resource, timer, progression or save changes are made.

## Rendering contract

Four authored SVG atlases are rasterized once by Godot at **2× logical resolution** and shared through HeroArt. A furnace body, fire and smoke now require one atlas-region draw instead of reconstructing all its shapes for every machine each frame. No per-machine textures, SubViewports or sprite nodes are allocated.

Logical dimensions and pivots:

| Atlas | Cell size | Pivot | Frames |
| --- | --- | --- | --- |
| Furnace | 64×112 | 32,84 | 6 |
| Mature tree | 96×112 | 48,96 | 4 |
| Player body | 32×44 | 16,29 | 4 |
| Town Hall | 160×176 | 8,24 relative to civic origin | 5 |

The source rectangles use actual imported texture sizes. Transparent padding keeps neighboring atlas cells away from visible edges. Use linear filtering, lossless texture import and no mipmaps for this pilot. Four RGBA atlas images total approximately **3.55 MiB**, before engine/import overhead.

Furnace animation uses a deterministic four-frame cycle at five poses per second, with a stable entity phase. Pause freezes world animation time; reduced motion freezes the furnace pose while preserving a visibly hot working chamber. Machine outputs, status indicators, electricity marks and health bars remain outside the body texture and reflect live state.

The first pilot does not batch drills, assemblers, turrets, belts or every other machine. Those remain further rendering/content work.

## Source and provenance

Sources: assets/art/hero/*.svg. They were authored directly for this project from native vector shapes and gradients; no third-party graphics package or raster reference asset was incorporated.

The editable generator is tools/generate-hero-art.cjs. Node is a development convenience for regenerating these four files; the game and exported builds only need Godot and the checked-in SVG/import settings. The generator uses explicit SVG fill-opacity rather than eight-digit hexadecimal colors to keep alpha rendering consistent with the importer.

Future artist replacements should retain the documented pivots, atlas frame semantics, transparent margins, approximate world footprint and imported resolution. Keep original sources and record any external license before expanding the set. UI civic portraits remain their independent illustration system; furnace world/placement/crafting artwork shares the new furnace atlas.

## Verification and diagnostic results

Focused checks cover imported resolution, all atlas frame bounds, shared resources, animation/state separation, civic age/state variants, node reuse, unchanged gameplay footprint and unchanged saves. Native image checks verify actual idle/working/damaged furnace differences and pixel stability while paused. Captures review a street scene, Orchard/player and restored/disabled/ruined Hall.

A 240-working-furnace diagnostic was run before and after this pilot with the same benchmark script and camera. Simulation was paused to isolate rendering.

| Window | G1 draw calls, ambient on | G2 draw calls, ambient on | Reduction |
| --- | --- | --- | --- |
| 1100×720 | 7,282 | 1,721 | ~76% |
| 3840×2160 | 9,545 | 3,562 | ~63% |

Short uncapped development samples on the RTX 3070 / Compatibility setup measured roughly 168–199 ms/frame before and 39–46 ms after at minimum size, and roughly 245–247 ms before and 98–99 ms after at 4K. These are diagnostic samples, affected by driver/compositor/background work, not universal FPS guarantees. The deliberately dense 4K scene remains slow and is not considered performance-complete.

Final regression: 1,637 checks, zero failures (including 15 focused hero-art checks). Native hero pixel checks and minimum-window/4K workspace layout checks also passed. The four checked-in atlases match deterministic generator output.

## Remaining work

- Extend body caching/batching to other expensive machine types and streamline repeated shadow/status drawing.
- Profile live simulation, mixed factories and longer sessions separately from this paused furnace stress fixture.
- Review artist quality and silhouettes at multiple zoom levels before expanding the whole set.
- G3: evaluate aligned normal/specular art and selective occlusion within the existing shader/performance budget.
- G4/G5: richer motion, regional trees/architecture and more organic scenery; keep biome personalities distinct.
