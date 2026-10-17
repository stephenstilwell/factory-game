# Factory development roadmap

The playable loop is now: gather timber, establish worker logistics, shelter the first
neighbors, rebuild the crossing with water-powered production, then automate industry
to restore Oldbridge and voluntarily defend its beacon.

See [the backlog review](backlog-review.md) for the latest priorities and the reasons behind them.

| Layer | Implemented | Next useful step |
| --- | --- | --- |
| Simulation | Fixed ticks, stable IDs, item transactions, deterministic save continuation | Profile representative large factories before redesigning transport |
| World | Finite seeded deposits, groves, four discoveries, landmark biomes, exploration map, named pins, persistent ore chart detail, Greybank road logistics and Orchard growing beds | Playtest agricultural and road supply pacing |
| Logistics | Primitive workers, snapshot belts, fair merges, splitter junctions, underground pairs, filtered inserters | Priorities and filters when layouts justify them |
| Production | Timber/water/charcoal opening, smelting, components, dossiers, automated manufacture, actionable stall navigation, district generation/poles and optional electric drives | Playtest network layout, throughput and fuel efficiency before adding storage or alternate generation |
| Progression | Empty start, primitive chapters, industrial lessons, four technologies and banked research | A meaningful next town chapter rather than more passive percentages |
| Settlement | Shelter, crossing, three civic projects, contracts, neighborhoods, buffs and a paid workshop maintenance crew | A distinct regional service or delivery problem tied to the next restoration project |
| Engineer | Nineteen material-funded equipment tiers including protective coats, three skills to 99, commissioning milestones, pinned goals | Weapon handling after defense playtests; later chapters to support higher skill levels |
| Building UX | Custom hotbar, modern inventory/crafting, copy/paste ghosts, nearby/all supply checklist, shortage crafting and bounded ghost undo/redo | Playtest larger construction layouts |
| Defense/story | Three keepers, journal/unread guidance, voluntary ten-wave defense, rifle, retreat, three constructs, turret roles and regional restoration conversations | Encounter tuning and a larger next chapter |
| Audio | Ten CC0 tracks across five rotating context playlists, matched gains, credits, pause/focus behavior | Playtest long-session repetition and musical fit |
| Persistence | Validated v2 extensions, save metadata, explicit backup recovery, damaged-primary protection, old-world compatibility, saved map pins, four named slots and opt-in separate autosaves | Playtest recovery and consider cloud sync only with a concrete need |

## Electricity slice delivered

District dynamos, poles, material-funded drives, demand-based fuel use, fair shortages,
visible connections and validated stored energy are playable. See [electricity](electricity.md).
The next substantial content work is a complete Iron & Industry town chapter using
regional production and power. It needs its own authored objectives and final payoff.

Fluids and trains should follow specific new material and distance problems. The game
has no fluids, trains, belt lanes, construction robots or multiplayer today.
