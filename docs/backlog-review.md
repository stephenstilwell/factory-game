# Backlog review and completion pass — 2026-10-16

The latest pass closes concrete gaps in existing systems. A completed slice means a playable loop with controls, feedback, persistence and verification. It does not mean every future extension is implemented.

## Completed slices

| System | Delivered | Reference |
| --- | --- | --- |
| Development saves | One current schema, one generator/opening; no import or migration. Backups and autosaves retained | [Save policy](development-saves.md) |
| Forestry | Six harvests per tree, shelter-unlocked replanting, visible growth, grove previews and deliberate reforestation | [Managed forestry](managed-forestry.md) |
| Navigation | Up to 32 named saved map pins, tracking and a world compass | Existing map and navigation |
| Map continuity | Explored ore reconstructed after loading/cache eviction, bounded map-only cache, hover stock details | [Map detail](map-detail.md) |
| Hand-crafting | One-click intermediate planning, queued-output reuse, full cost preview, safe refunds and validated dependency saves | [Crafting](craft-dependencies.md) |
| Construction plans | Nearby/all supply checklist, queue-aware shortage crafting, 32-edit ghost undo/redo | [Plan editing](plan-editing.md) |
| Production diagnostics | Locate nearest stalled machine, repair and power diagnostics, actual item rates | Factory production panel |
| Recovery and slots | Validated manual/backup recovery, damaged-primary preservation, four named slots, opt-in separate five-minute autosaves and previous autosave recovery | [Save slots](save-slots.md) |
| Settlement services | Material- and credit-funded local maintenance crew; no free repair stock | [Town services](town-services.md) |
| Greybank biome | Nine physical road-supply loads, three visual restoration stages, bounded rewards and local travel benefit | [Greybank road](greybank-road.md) |
| Farmlands biome | Three paid growing beds, physical fuel/plank inputs and produce output, inserter automation and recurring market sales | [Orchard gardens](orchard-gardens.md) |
| Electricity | Charcoal dynamos, pole networks, optional double-speed electric drives, conserved fuel energy, fair shortages, damage/reconnection, visible wiring and readouts | [Electricity](electricity.md) |
| Creative homes | Placeable cottage entrance, material-funded furnishings, instanced room editor, rotation/pickup/history, discovery finishes and saved layouts | [Personal cottage](personal-cottage.md) |
| Personal protection | Two paid coat tiers, progression gates, clear effects, tracked goals and save validation | [Protection](protection-and-regional-story.md) |
| Regional story | Unread/replayable keeper responses to Orchard trade, completed Greybank road and maintainable local power | [Regional conversations](protection-and-regional-story.md) |
| Audio | Ten locally bundled CC0 recordings, five context playlists, matched levels, rotation and credits | [Audio](audio.md) |

## Remaining validation work

These are playtest tasks, not missing implementations. Keep findings concrete before adding more mechanics.

- Run a full empty-start campaign through Orchard, Greybank, electricity and the ten voluntary arrivals. Record time to each unlock, supply bottlenecks, credit income versus spending and any unclear instructions.
- Test prolonged electric-factory layouts. Verify whether pole service/connection ranges, drive costs, fuel efficiency and brownout feedback make good decisions. Profile representative factories before changing transport architecture.
- Tune coat value, enemy pressure and retreat behavior together. Weapon handling is not yet changed.
- Listen through longer biome visits and transitions; assess repetition and musical fit.
- Exercise named-slot and recovery controls during normal play, including deliberate cancellation and filling several factories.

## Future expansion backlog — still unimplemented

| Priority | Next complete slice | Scope boundary |
| --- | --- | --- |
| Combat — major track | [C3: weapon handling and sidegrades](combat-roadmap.md), followed by sustained rescues and a landmark finale | C1 briefing/Nell and C2 authored encounters/supply-cost baseline are delivered; later slices remain planned. Waves remain individually opt-in |
| Creative settlement building | Outdoor paths, fences, planters and town appearance customization | Cottage interiors are implemented; outdoor decoration is a separate next slice |
| Next substantial content | Playtest the delivered [Homecoming chapter](homecoming-chapter.md), then author a later chapter around a new town problem | Pantry, local power proof, Greybank road, housing, fair and public fuel depot are implemented |
| Biome development | [B3: Glassfields](biome-roadmap.md), plus Reedwater pacing/content playtests | B1 identity and B2 causeway/lodge prototype are delivered; dedicated marsh music/dialogue and broader landscape depth remain open; Cinderwood/Frostmere and excursions remain later proposals |
| Content expansion | Deeper biome identity, additional discoveries and small authored exploration problems | Current Farmlands/Greybank production slices are complete; additional biomes are new content |
| Factory expansion | Alternate generation or energy storage once network playtests expose a useful problem | No accumulators, fluid power, electric turret conversion or priority switching yet |
| Later | Fluids, trains, belt lanes, robots, minimap, enemy overlays and multiplayer | Separate substantial systems; require a specific material, distance, visibility or cooperation need |

This future backlog is deliberately retained. It has not been labeled complete or removed to make the list look empty. The immediate gaps from the earlier review have playable implementations; later chapters and larger systems still require development.

## Verification

Integrated checks cover item and energy conservation, deterministic continuation, malformed saves, topology changes, fair shortages, current-schema validation, map reconstruction without authoritative generation, material-funded upgrades, regional story prerequisites, named-slot isolation and separate recovery copies. Native captures exercise the actual retrofit, protection purchase, save selection, autosave and recovery flows at 1100×720.

Changes are local source work. They do not automatically update GitHub or the published release.

Biome update: B1 existing-region presentation is implemented ([scope](biome-identity.md)); B2 has a playable causeway/lodge loop. See the [biome roadmap](biome-roadmap.md) for remaining regional work.

B2 update: [Reedwater Marsh](reedwater-marsh.md) now has a playable physical crossing/restoration/workshop loop. Remaining marsh work: dedicated recordings, keeper dialogue, shoreline variety and pacing/performance playtests. Glassfields remains the next new biome chapter.

Graphics track: [G1 lighting/material/water foundation](graphics-foundation.md) is implemented. [G2 hero art and furnace batching](hero-art-pilot.md) are implemented. The dense 4K stress case remains slow; broader machine batching and G3 selective normal/specular art/occlusion are next, followed by animation, regional composition and measured quality tiers.
