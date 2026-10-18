# Biome and frontier roadmap

Updated 2026-10-17. B1’s first presentation slice is implemented; see [verification and scope](biome-identity.md). B2’s [playable Reedwater prototype](reedwater-marsh.md) is implemented; B3–B6 remain planned.

## Direction

Regions should feel like different parts of one ruined civilization, not interchangeable resource palettes. Each needs a landscape silhouette, an audio identity, a reason to travel, a different production/logistics problem, a local story, and visible restoration. Most regions belong in the shared overworld; small instanced ruins or engineering puzzles can supplement it without disconnecting regional factories.

Use existing simulation systems before adding resource families or survival meters. Keep readable machine/ore silhouettes, shared architectural materials and recoverable settlement problems. Do not make decoration look like a solid obstacle unless collision and navigation support it.

## Delivery slices

| Order | Slice | Identity and gameplay | Completion criteria |
| --- | --- | --- | --- |
| B1 — first | Deepen Lost Orchard and Greybank | Blossom terraces, old fences and tended plots versus weathered stone, quarry works and restored road activity | Shared region presentation definitions; gradual ground transitions; distinct scenery/vegetation/ambience; visible changes tied to existing beds/road progress; region/location cues; bounded rendering; readable building/ore overlays; no new resource or save rules |
| B2 — prototype implemented | Reedwater Marsh prototype | Mist, reeds, raised ruins and scattered dry land; connecting a waterside settlement | Seeded region placement, navigable water/buildable ground rules, boardwalk/causeway construction, safe routes, map representation and a complete restoration project using existing supplies |
| B3 | Glassfields story chapter | Pale vegetation, shattered aether towers and crystalline remains; discovery and careful reactivation | Connect to a completed industrial town chapter; one authored ruin/puzzle, a keeper/history thread, useful recovered pattern and visible observatory restoration; define magic's costs and limits before adding an aether economy |
| B4 | Cinderwood | Charred forest with surviving green clearings; reclaiming damaged land | Managed forestry adaptation, readable burned/restored states, material-funded recovery project, distinctive ambience and useful regional output; no mandatory spreading-fire simulation in the first slice |
| B5 | Frostmere | Snowbound workshops and warm refuge windows; dependable winter supply | A bounded fuel-delivery/refuge-restoration loop, winter terrain/audio/visibility, safe failure/recovery and a reason to connect it to the town; no global hunger/freezing meter by default |
| B6 | Deeper regional excursions | Small puzzles, ruins and discoveries that explain the old network | Each excursion has an authored purpose, clear exit/recovery, finite rewards, distinct interaction and permanent regional/town consequence; decide instancing per encounter |

B2 has a playable causeway/lodge slice; its remaining depth work is tracked in [Reedwater](reedwater-marsh.md). B3 is the next major story frontier. B4/B5 are optional future expansions, not prerequisites for finishing current Oldbridge.

## B1 scope

Keep current Orchard growing beds, produce sales, Greybank road shipments, Homecoming links, landmark positions, ore generator and existing music playlists. Add presentation around those loops, rather than silently replacing them.

Ground transitions should blend near borders. Trees and low scenery should give each region a silhouette: orchard blossoms, planted rows and old farm furniture; Greybank fir-like silhouettes, slate fragments and masonry equipment. Scenery is non-blocking and should yield to actual buildings, ore, landmark hatches and managed-tree plots.

Restoration changes should come from authoritative existing counters. Tended beds should make the Orchard worksite look active; completed Greybank road stages should improve its worksite. No cosmetic state should invent produce, XP, settlers, power or progress.

Ambience should differ through sound character, not only pitch shifts on one loop. Retain an option to disable ambience, honor pause/focus behavior and bound sound voices. Keep current licensed region music; selecting additional recordings is a separate audio/content pass.

## B2 implementation and continuing guardrails

The [delivered prototype](reedwater-marsh.md) uses a deterministic regional water layer, four sequential causeway spans and a material-funded maintenance lodge. Keep the following rules as its terrain and content expand.

- Water must agree across world rendering, building placement, player movement, enemy navigation, maps and saved continuation.
- Author a safe walking entrance and prevent terrain generation from trapping the player, severing current town logistics or occupying existing construction.
- Start with boardwalk/causeway construction and reeds as scenery. Add harvestable reeds or processing only when a concrete restoration recipe needs them.
- Define a waterside settlement project: who lived there, what failed, what Oldbridge supplies, and the distinct service recovered.
- Keep the first marsh loop bounded. Boats, fluid networks, tides, fishing and dynamic flooding are separate decisions.
- Disclose terrain and bridge costs before commitment. Provide pickup/refunds and a recovery route.
- Fit the visual language to Oldbridge while introducing a misty, reed-framed silhouette and water soundscape.

No new biome may be labeled complete solely because it has a color palette or appears on the map.

## Transitions and exploration

Provide approach cues before a region title: changing ground, vegetation, skyline and ambience. Existing region music can follow its established context logic. A location cue should help the player name a place without interrupting building or combat.

Avoid continuous full-screen tinting, dense fog that hides ore, forced camera motion and entrance cutscenes on every visit. Respect reduced motion and ambient settings. Restoration should leave recognizable ruins and regional character rather than turning every place into the same green meadow.

## Performance and persistence

Use data-driven region definitions, seed-stable decoration and visible-area bounds. No node per grass blade, distant wildlife simulation or scan of the whole world per frame. Cap decoration and sound voices. Reuse terrain chunk caching and invalidate only when a presentation change actually requires it.

Presentation-only B1 state should derive from existing saved data. New-region gameplay in B2 and later needs explicit schema validation, placement rules and deterministic save/load tests. Follow the current development save policy without building an unrequested legacy migration framework.

## Verification and playtesting

Check multiple seeds, walking transitions, edge overlap, exploration guidance, ore/depletion masks, crowded factories, managed forestry, reduced motion, ambient disabled, pause/focus, region music context and native captures at minimum window/fullscreen sizes.

B1 acceptance includes reviewing unrecovered, claimed and restored region states and confirming that rendering changes neither authoritative saves nor resource stocks. B2 acceptance includes the complete physical causeway/delivery loop and safe navigation, not only screenshots.

Playtest whether players can identify a region without reading its name, explain what it contributes to Oldbridge, find its entrance, and notice how their work changed it. Record frame cost before expanding scenery density.
