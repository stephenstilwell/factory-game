# Skills: learning by doing

Press **P → Skills** to see Gathering (saved under the stable `mining` ID), Fabrication, and Exploration. Each starts at level 1, caps at **99**, and has an XP bar, visible XP sources, exact XP and reward for its next milestone, and a full reward ladder. Track a personal goal directly from a skill or equipment card. Successful actions show a small XP notification; level gains also announce the new level. Equipment has its own tab and still requires manufactured materials and existing progression gates.

| Skill | XP sources | Milestone benefits |
| --- | --- | --- |
| Gathering | 3 XP per fallen timber/berry; 6 per felled tree in new timber worlds; 10 per hand-mined stone/coal; 12 per iron/copper ore delivered to the pack | Hand gathering, felling and mining speed, up to +25% |
| Fabrication | Finished, delivered hand-craft batches; XP varies by recipe complexity | Graduated hand-crafting work speed, up to +25% |
| Exploration | 20 XP for entering a new 16×16 area; 40 XP for encountering a previously undiscovered resource patch within two tiles | Graduated movement speed, up to +10%; survey radius increases at 25 and 75 |

Gathering and Fabrication reward levels **5, 10, 15, 20, 25, 35, 50, 65, 75, 85, 90, 95, 99**, granting total work bonuses of **2, 5, 7, 9, 10, 12, 15, 18, 20, 22, 23, 24, 25%**. Exploration rewards levels **5, 10, 15, 25, 35, 50, 65, 75, 85, 99**, granting **1–10%** total movement speed. Experience uses an increasing cumulative curve: `round(50 × (1.10^(level−1) − 1) / 0.10)`. Early levels arrive quickly; 99 is a long-term mastery goal. Current content does not require mastery or additional skill grinding to finish its lessons, research, or town projects. No existing equipment is locked away by the addition of skills.

Skill bonuses multiply the relevant equipment stat; they do not change machine production, resource yields, reach, or carrying capacity. Hand work runs at a fixed 10 Hz. Earned surplus work carries between queued craft jobs so short recipes benefit from skill speed; average batch times are shown. Idle time grants no stored work, and cancellation clears surplus. The crafting panel shows the effective per-batch duration and the XP reward. Automation remains the route to sustained mass production.

## XP ownership and exploit rules

- Mining awards XP only after one real terrain item is extracted into the pack. Unfinished work, exhausted deposits, blocked reach, and full packs award none.
- Fabrication awards once per completed recipe batch, after output delivery. Queuing, canceling, refunding, and waiting for pack room award none. Multiple outputs such as two wire still receive one batch reward.
- Commissioning the first automated extraction of each resource grants 100 Mining XP. The first completed automated batch of each recipe grants 120 Fabrication XP. Deliveries 1, 5, and 10 at each civic site grant 150 Fabrication XP each. These persistent milestones reward new production capabilities; repeat batches, rebuilding machines, and reloading cannot repeat them.
- Labs, building placement/reclamation, transfers, and equipment installation grant no XP. Productive automated lines also earn graduated commissions at 10/50/250/1,000/5,000 real batches per recipe or resource, worth 150/400/1,000/2,500/6,000 XP. Counts are shared across machines and persist. Transfers, blocked machines, rebuilding, and reloading cannot repeat rewards. Civic deliveries add later milestones and neighborhood rewards; see [engineer progression](engineer-progression.md).
- Exploration requires actual player movement. Standing still, camera movement, rendering terrain, and running surveys do not discover areas or patches for XP. Persistent ledgers prevent revisits and cache eviction from repeating rewards.
- Patch identity is its generated center and resource type, so crossing a chunk boundary or discovering another edge of the same patch cannot repeat its reward. Ledger validation also supports legacy overlapping patches.

## Architecture and saves

`skill_catalog.gd` owns skill IDs, thresholds, milestones, and action rewards. `skills.gd` owns XP and discovery ledgers. `World.award_skill` emits presentation events; the simulation invokes it at successful hand-action completion and movement-based discovery. The UI does not grant XP.

Levels and bonuses are derived from XP, capped at 99. Mining and crafting advance in integer hundredths of a work tick, avoiding fractional drift. Craft-job work remainders are saved and validated. Mining cursor intent remains transient and stops when interaction ends, as before.

The optional version-1 `skills` save extension stores XP, visited area coordinates, and discovered patch identities. Loading validates bounds, unique records, and generated patch definitions against the saved terrain seed/version. Older saves start at level 1 without retroactive rewards; their existing inventories, equipment, world, and lessons remain intact. New skill IDs can be added with zero XP defaults while preserving known saved skills; changes to published IDs, thresholds, or discovery geometry require a compatibility strategy.

Discovery tracking is independent of terrain/render caches. It stores at most 100,000 areas and 100,000 patches, matching save validation limits. Ordinary simulation checks only when the player enters a different tile; it does not scan distant regions every frame.

Combat skills can later use the same reward boundary when actual kills, defenses, and repairs exist. Beacon defense exists separately; combat XP is not currently awarded.
