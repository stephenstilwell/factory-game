# Backlog review and completion pass — 2026-10-16

The latest pass closes concrete gaps in existing systems. A completed slice means a playable loop with controls, feedback, persistence and verification. It does not mean every future extension is implemented.

## Completed slices

| System | Delivered | Reference |
| --- | --- | --- |
| Navigation | Up to 32 named saved map pins, tracking and a world compass | Existing map and navigation |
| Map continuity | Explored ore reconstructed after loading/cache eviction, bounded map-only cache, hover stock details | [Map detail](map-detail.md) |
| Construction plans | Nearby/all supply checklist, queue-aware shortage crafting, 32-edit ghost undo/redo | [Plan editing](plan-editing.md) |
| Production diagnostics | Locate nearest stalled machine, repair and power diagnostics, actual item rates | Factory production panel |
| Recovery and slots | Validated manual/backup recovery, damaged-primary preservation, four named slots, opt-in separate five-minute autosaves and previous autosave recovery | [Save slots](save-slots.md) |
| Settlement services | Material- and credit-funded local maintenance crew; no free repair stock | [Town services](town-services.md) |
| Greybank biome | Nine physical road-supply loads, three visual restoration stages, bounded rewards and local travel benefit | [Greybank road](greybank-road.md) |
| Farmlands biome | Three paid growing beds, physical fuel/plank inputs and produce output, inserter automation and recurring market sales | [Orchard gardens](orchard-gardens.md) |
| Electricity | Charcoal dynamos, pole networks, optional double-speed electric drives, conserved fuel energy, fair shortages, damage/reconnection, visible wiring and readouts | [Electricity](electricity.md) |
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
| Next substantial content | Author an Iron & Industry town chapter that uses regional supplies and power, with a visible final civic payoff | New objectives, balancing and narrative; do not pad levels with grind |
| Content expansion | Deeper biome identity, additional discoveries and small authored exploration problems | Current Farmlands/Greybank production slices are complete; additional biomes are new content |
| Factory expansion | Alternate generation or energy storage once network playtests expose a useful problem | No accumulators, fluid power, electric turret conversion or priority switching yet |
| Later | Fluids, trains, belt lanes, robots, minimap, enemy overlays and multiplayer | Separate substantial systems; require a specific material, distance, visibility or cooperation need |

This future backlog is deliberately retained. It has not been labeled complete or removed to make the list look empty. The immediate gaps from the earlier review have playable implementations; later chapters and larger systems still require development.

## Verification

Integrated checks cover item and energy conservation, deterministic continuation, malformed saves, topology changes, fair shortages, legacy migration, map reconstruction without authoritative generation, material-funded upgrades, regional story prerequisites, named-slot isolation and separate recovery copies. Native captures exercise the actual retrofit, protection purchase, save selection, autosave and recovery flows at 1100×720.

Changes are local source work. They do not automatically update GitHub or the published release.
