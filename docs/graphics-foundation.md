# Graphics foundation: G1

Implemented 2026-10-17. See the [graphics roadmap](graphics-roadmap.md) for the larger art overhaul.

## Visible changes

- A cooler fixed daylight profile with warm localized illumination around operational civic buildings, restored Reedwater, cottages, communal hearths and working burners.
- Shared southeast shadow projection for trees, buildings, machines and the player, with softer contact shadows.
- Continuous corner-sampled ground colors, subtle reusable material grain and preserved ore silhouettes.
- Depth-colored marsh water, readable bank edges and sparse animated surface highlights that avoid causeways.
- World lighting excludes the HUD canvas. Ambient off restores neutral material rendering; reduced motion and pause freeze decorative flicker and water motion.

This is a foundation pass using existing artwork. New detailed building sprites, normal maps, real light occlusion, reflections, a gameplay day/night cycle and weather are still future work.

## Rendering architecture

An initial native-light prototype proved expensive with the current immediate-mode WorldView: a native light can repeat large sets of drawing commands. The delivered version instead uses one shared unshaded canvas shader with a fixed 12-source light field. Local light contributions and daylight are evaluated in that shader, preserving alpha and using world coordinates. Sources are culled to visible cells, ordered by distance and refreshed at most every 0.15 seconds unless topology, visible bounds, preferences or the bound world change. Small optional intensity variation does not create nodes.

This is stylized illumination, not physical lighting or native shadow-map occlusion. Terrain sprites inherit the same world material, while UI, placement guides and particle layers retain their own materials. Ambient off removes the world shader entirely.

Terrain command lists are baked into 768×768 SubViewport textures, one per 16×16 chunk, rather than replaying detailed grass/ore commands every frame. The textures update once initially and again when depletion marks their chunk dirty. Hidden cached surfaces are evicted beyond the existing visible-area cache policy with a 32-entry retention threshold; all currently visible chunks remain available. A color attachment alone uses approximately 2.25 MiB per surface, so GPU memory is a deliberate tradeoff and needs broader hardware testing.

One deterministic 128×128 grain texture and reusable shadow gradients serve all terrain and art. No renderer switch, external asset package, new game clock or save-schema change is required.

## Verification

Focused checks cover source caps and culling, disabled emitters, deterministic water masks, causeway exclusion, settings, node reuse, pause/reduced motion, HUD isolation, border sampling and unchanged authoritative saves.

Native captures compare town, orchard and marsh before/after. A native cache test changes a real ore deposit, verifies that the baked texture stays unchanged without invalidation, then confirms 1,696 changed pixels after refresh and returns to a stable cached image. Minimum-window and 4K workspace layout checks pass.

Full regression: 1,622 checks, zero failures (including 19 focused graphics checks). Native terrain-cache pixel tests and minimum-window/4K workspace checks also passed.

## Profiling and remaining risk

A diagnostic scene contains 240 simultaneously working furnaces, with simulation paused to concentrate on drawing. On the development RTX 3070 / Compatibility setup, the first unbaked G1 prototype reported roughly 14,900 draw calls at 1100×720. The cached shader prototype reported approximately 7,300 at 1100×720 and 9,500 at 4K. Those are iteration diagnostics, not an old-release versus new-release benchmark.

The dense scene still measured roughly 140–200 ms per frame in short uncapped development runs. That is a serious remaining rendering bottleneck in procedural machine art, not a claim of acceptable factory-scale performance. The final ambient-off path bypasses the neutral shader; longer isolated profiling is still needed. Driver/compositor effects, first-use baking, debug builds and a short sample window limit generalization.

The [G2 pilot](hero-art-pilot.md) now shares furnace-body art and substantially reduces this diagnostic’s draw calls; broader machine batching still needs work. Add quality tiers and measure sustained large-factory behavior before expanding expensive effects. Current terrain caching trades GPU memory and first-use bake cost for fewer repeated draw commands.

## Next

The [G2 tree/furnace/player/Town Hall pilot](hero-art-pilot.md) is delivered. G3 evaluates lighting-aware assets and selective occlusion; broader machine batching remains a performance priority.
