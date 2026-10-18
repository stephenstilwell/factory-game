# Factory development roadmap

The playable loop is now: gather timber, establish worker logistics, shelter the first
neighbors, rebuild the crossing with water-powered production, then automate industry
to restore Oldbridge and voluntarily defend its beacon.

See [the backlog review](backlog-review.md) for the latest priorities and the reasons behind them.

| Layer | Implemented | Next useful step |
| --- | --- | --- |
| Simulation | Fixed ticks, stable IDs, item transactions, deterministic continuation and one current save schema | Profile representative large factories before redesigning transport |
| World | Finite seeded deposits, renewable managed forestry, four discoveries, landmark biomes, exploration map, named pins, persistent ore chart detail, Greybank road logistics and Orchard growing beds | Playtest agricultural and road supply pacing |
| Logistics | Primitive workers, snapshot belts, fair merges, splitter junctions, underground pairs, filtered inserters | Priorities and filters when layouts justify them |
| Production | Timber/water/charcoal opening, smelting, components, dossiers, automated manufacture, actionable stall navigation, district generation/poles and optional electric drives | Playtest network layout, throughput and fuel efficiency before adding storage or alternate generation |
| Progression | Empty start, primitive chapters, industrial lessons, four technologies and banked research | Homecoming chapter delivered; playtest its combined regional/industrial pacing |
| Settlement | Shelter, crossing, three civic projects, contracts, neighborhoods, buffs and a paid workshop maintenance crew | Homecoming pantry, local-power proof, fair and public fuel depot delivered; tune supply pacing |
| Engineer | Nineteen material-funded equipment tiers including protective coats, three skills to 99, commissioning milestones, pinned goals | Weapon handling after defense playtests; later chapters to support higher skill levels |
| Building UX | Custom hotbar, modern inventory/crafting, copy/paste ghosts, nearby/all supply checklist, shortage crafting, dependency-aware hand-crafting and bounded ghost undo/redo, optional cottage interiors and furniture editing | Outdoor landscaping and town decoration using the home collection/placement patterns |
| Defense/story | Three keepers, journal/unread guidance, voluntary ten-wave defense, rifle, retreat, three constructs, turret roles and regional restoration conversations | [Combat plan](combat-roadmap.md): C1 briefing and specialist service delivered; C2 encounter bands and finite-supply baseline delivered; C3 weapon handling and sidegrades delivered; next C4 sustained rescue operations |
| Audio | Ten CC0 tracks across five rotating context playlists, matched gains, credits, pause/focus behavior | Playtest long-session repetition and musical fit |
| Persistence | Validated v2 extensions, save metadata, explicit backup recovery, damaged-primary protection, old-world compatibility, saved map pins, four named slots and opt-in separate autosaves | Playtest recovery and consider cloud sync only with a concrete need |

## Electricity slice delivered

District dynamos, poles, material-funded drives, demand-based fuel use, fair shortages,
visible connections and validated stored energy are playable. See [electricity](electricity.md).
The Iron & Industry [Homecoming chapter](homecoming-chapter.md) now connects regional
supplies, useful local electric work, housing and the completed Greybank road to a
visible fair and a public fuel depot. Playtest the combined loop before adding a later age.

Fluids and trains should follow specific new material and distance problems. The game
has no fluids, trains, belt lanes, construction robots or multiplayer today.

## Homecoming chapter delivered

See [A Town Worth Returning To](homecoming-chapter.md). Orchard produce, Greybank roadbuilding, actual local electric work and housing now contribute to a finite civic chapter. Its visible fair, Ada conversation and material-backed public fuel depot provide a payoff without mandatory combat.

## Combat — major development track

Combat needs to become a meaningful factory, logistics and settlement loop. See the
[dedicated combat roadmap](combat-roadmap.md) for proposed specialist rescues,
material-backed services, encounter bands, sustained operations and the eastern
signal-station finale. C1 briefing/Nell and C2 authored encounters/cost reporting are playable; later operations, rewards and the finale remain planned.

Delivered: **C1 — briefing and first-defense specialist reward**, including readiness
guidance, Nell and a stocked between-operation rearm service. Delivered: **C2 — distinct
encounter bands, after-action reports and a finite-supply benchmark**. Next: **C3 —
weapon handling and meaningful equipment sidegrades**.
Keep current opt-in behavior while validating the loop. Automatic pressure and
campaign threat settings require a later explicit design decision.

## Biomes — regional identity and new frontiers

See the [biome roadmap](biome-roadmap.md). B1’s first slice deepens Orchard and Greybank through terrain transitions, scenery, ambience and visible restoration ([implemented scope](biome-identity.md)). B2 adds Reedwater Marsh with a playable causeway/lodge loop; B3 is the next Glassfields story frontier. Cinderwood, Frostmere and instanced excursions remain later proposals. No new region is implemented in B1.

B2 delivered as a [playable Reedwater Marsh prototype](reedwater-marsh.md): physical water, refundable causeway, maintenance-lodge restoration, effective repair bonus and automated kit production. Dedicated marsh music, dialogue and broader landscape depth remain open. B3 Glassfields is the next major biome slice.

## Graphics modernization

See the [graphics roadmap](graphics-roadmap.md). G1 delivers [daylight, bounded shader illumination, consistent shadows, baked terrain texture and water polish](graphics-foundation.md). G2 delivers a [tree/furnace/player/Town Hall pilot and shared furnace-body rendering](hero-art-pilot.md). G3 normal/specular art and selective occlusion are next; broader machine batching, animation, regional composition and quality tiers remain planned.
