# G3: lighting-aware materials and selective occlusion

Implemented 2026-10-17 as a bounded pilot on the Compatibility renderer.

## Visible changes

Furnace masonry, copper bands and chimneys now respond to nearby light direction. Town Hall roof slopes, wall faces and glass have a restrained material response. Specular masks keep brick dull and reserve highlights for metal and glass. The tree and player remain G2 diffuse artwork pending review of this pilot.

Healthy stone walls and repaired, healthy civic footprints soften/block local warm light. A source inside a civic footprint lights its own building rather than becoming trapped inside it. Ruins, destroyed walls, trees and ordinary machines do not cast local-light occlusion. This is a presentation approximation, not line of sight for combat or a change to construction/collision.

## Implementation and budgets

- Existing one-pass shader and maximum 12 visible sources; no PointLight2D, native shadow maps or per-machine nodes.
- Two shared CanvasTexture resources wrap the furnace and Town Hall atlases. Four additional 2x SVG maps use exactly the existing frame dimensions and pivots. About 5.6 MiB additional uncompressed RGBA asset storage before driver overhead.
- Maps are authored from semantic geometry, not inferred from diffuse brightness. Generate with `node tools/generate-surface-maps.cjs`. Original project artwork; no external asset license.
- Normal RGB stores signed screen-space surface direction with neutral background. Specular grayscale stores reflectivity. Flat/default normal samples bypass material shading, preserving terrain and procedural shapes.
- Visibility is a fixed 192×16 single-channel atlas: 16×16 samples for each of 12 lights, linearly filtered into soft edges. CPU ray/rectangle queries operate only on visible nearby blockers; each source filters blockers to its radius first.
- Source/blocker checks run at most about seven times per second. A content signature prevents rebaking or texture uploads when unchanged. Updates reuse one ImageTexture. Light radius bounds the work; no growing world-wide cache.
- Occlusion uses gameplay footprints and coarse sampling: small corner leaks, soft edges and approximate tall-building shadows are intentional limitations. The shared directional ground projections remain stylistic shadows, independent of these local warm-light masks.
- No simulation clock, game save fields, gameplay dependencies or renderer migration.

## Fallback and accessibility

Pause → Presentation → **Detailed surface lighting** disables both material response and local occlusion while retaining G1 daylight and warm light fields. The preference persists in presentation settings, separate from saves. Ambient off still bypasses the entire world shader. Reduced motion and pause retain static material response without pulsing. HUD and menu canvases remain outside world lighting.

## Verification

`tests/verify_surface_lighting.gd` runs on the native GPU: mapped material pixels differ from the simple path, plain ground remains unchanged, an occluding wall darkens the far side while preserving the near side, and fallback produces the original simple pixels. It also checks actual-world wall destruction invalidation, texture reuse, unchanged save data, and minimum-window pause viewport/last-action reachability.

Existing native hero animation and minimum-window/4K workspace regressions pass. Diagnostic images are generated in `.godot/verification/g3_materials.png` and `g3_occlusion.png`.

Performance measurements are recorded below after running `tests/benchmark_graphics.gd` alone. These short debug fixture timings are not universal frame-rate claims. The dense 4K factory remains an existing rendering bottleneck; wider asset rollout still requires broader batching.

Native debug benchmark (RTX 3070, 240 working furnaces, paused, VSync off):

| Viewport | Simple light field | Detailed surfaces/occlusion | Draw calls, both |
| --- | --- | --- | --- |
| 1100×720 | 41.57 ms/frame | 46.40 ms/frame | 1,721 |
| 3840×2160 | 100.95 ms/frame | 103.18 ms/frame | 3,562 |

One short run; scene and driver load affect timings. G3 adds no draw calls; the optional detailed path has measurable shader/CPU cost. No broader shadow-light rollout is included.
