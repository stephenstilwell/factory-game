# Reedwater Marsh: B2 playable prototype

Implemented 2026-10-17. The next new-region work is [B3 Glassfields](biome-roadmap.md); later marsh depth remains backlog work.

## Player loop

Reedwater Lodge is a seeded discovery southeast of Oldbridge (default anchor near 94,80, shifted with the town and adjusted to vacant land). Open Discoveries [L], select Reedwater, and track its **western bank**. Tracking changes to the lodge entrance once the causeway is complete.

After rebuilding the original Oldbridge crossing:

1. Bring **24 planks and 16 stone** for four causeway spans. Each costs **6 planks + 4 stone**, builds in order and opens an actual walkable water tile.
2. Walk across the causeway and recover Nessa's maintenance ledger: **300 Exploration XP**, once, in addition to the standard **75 discovery XP**.
3. Restore the lodge with **20 planks, 30 stone and 8 wire**. The complete trip costs **44 planks, 46 stone and 8 wire**.
4. Restoration grants **400 Fabrication XP**, permanently improves repair-kit healing by **25%** (rounded to whole health), and opens a regional maintenance workshop.

The keepers maintained the old network's wagons, pumps and roofs. Reconnecting their lodge returns practical maintenance knowledge to Oldbridge. Restored windows, the workbench and a keeper silhouette communicate activity. The ledger story remains available as the regional text tooltip; this prototype does not add a full NPC dialogue chapter.

## Automation and value

Each **60 simulated seconds**, the workshop consumes **4 iron plates, 2 copper plates and 2 planks** to produce **3 repair kits**. This trades extra lumber, a remote logistics route and a slower batch for better metal efficiency than the ordinary two-kit recipe. It is optional; ordinary crafting remains available.

The hatch is the lodge's marked entrance. For a simple island layout:

- Put an input inserter **south** of the hatch facing **north**, with supplies one tile farther south.
- Put an output inserter **north** of the hatch facing **north**, with receiving storage one tile farther north.
- Conveyors and other non-solid infrastructure may cross the completed causeway. Solid buildings may not block its narrow walking lane.

Manual supply, kit collection and input withdrawal are also available at the hatch. Inputs buffer at most three batches; output holds 12 kits. Starting a batch commits its ingredients and reserves room for three outputs. Withdrawing inputs returns only the uncommitted buffer. Full output pauses further consumption.

The repair bonus applies to actual building and civic repairs and stacks with the repair rig. Engineer stats and the regional service panel display the effective health per kit. Restoration creates a celebration and an Updates entry linking back to Discoveries. There is no passive credit grant or free kit generation.

## Physical rules and recovery

Marsh water is a deterministic regional terrain layer derived from the saved landmark origin. The generator finds an ore-free, unoccupied patch, preserving existing structures and settlement land. Its raised island, bounded reed-lined pools and western bank provide one authored crossing problem.

Water blocks player movement and enemy routes and rejects ordinary building placement. Completed spans open the same cells for movement, logistics, map display and enemy navigation; topology changes invalidate cached enemy grids. This does not change the old shallow opening watercourse or make watermills placeable in the marsh.

Before restoring the lodge, reclaim spans in reverse order for their full plank/stone costs. Stand fully west of the last span and pick up infrastructure on it first. Reclamation refuses a full pack, an occupied span, an active defense or a player standing on/beyond the span. Once the lodge is restored its causeway becomes permanent infrastructure.

## Presentation and performance

The first pass includes blue-green wetland ground, reed clusters, drooping willow details, a raised lodge, visible plank spans, a bank sign, sparse mist-like ambient strokes, region naming and charted water/causeway details on the map. Water is drawn in cached terrain chunks; dynamic marsh scenery scans only the intersection of the visible area and a fixed 24×22 tile worksite.

A fourth cached synthesized ambient palette adds soft water/frog-like sounds using the existing single spatial voice. Ambient disable, pause, focus and reduced-motion settings are respected. Marsh music currently uses the existing wilds playlist; no dedicated recorded marsh music has been added.

No fluids, flooding, boats, fisheries, new resource families or distant settler simulation are included.

## Persistence and verification

The current development schema now requires marsh state and the fifth frontier site. Pre-marsh saves are intentionally rejected; **start a new world**. No silent terrain conversion or legacy migration is performed.

Save validation checks span bounds, restoration ownership, timers, permitted stocks, reserved output, water occupancy and solid buildings on the causeway. Saved in-flight batches continue without consuming ingredients twice.

Focused tests cover six seeds, ore/civic preservation, real movement, building rules, payment/refund safety, one-time rewards, effective repairs, buffered production, inserter supply/extraction, interrupted saves, malformed saves, enemy navigation, map tooltips, regional ambience and restoration shortcuts. Native captures cover approach, lodge recovery and service states at minimum window size and 4K. Final regression: 1,603 checks, zero failures, including 60 focused marsh checks. Native marsh presentation and the existing minimum-window/4K workspace regressions also passed.

## Remaining marsh backlog

- Dedicated licensed marsh recordings and subjective long-session listening review.
- More natural shoreline art, larger patch composition and additional environmental storytelling.
- A full keeper conversation and a connection to a later town chapter.
- Playtest the metal-efficiency reward, round-trip travel time and maintenance throughput before adding contracts or more production.
- Wider navigation/logistics layouts and sustained factory performance sampling.

The causeway/lodge loop is playable; these items remain depth and content work, not claims of a finished biome campaign.
