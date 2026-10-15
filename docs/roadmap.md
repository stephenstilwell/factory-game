# Toward a fuller factory game

The prototype lacked both the material economy and the separation needed to extend it. Work is ordered by dependencies: stable state and item ownership first, logistics and production next, progression after that, then networks and world pressure.

| Layer | Implemented now | Next step |
| --- | --- | --- |
| Simulation foundation | Scene-independent world, fixed ticks, stable entity IDs, occupancy/type indexes, catalog definitions, behavioral tests | Command queue/replay if multiplayer or replays become a real requirement |
| World | Seeded chunk generation, negative coordinates, finite iron/copper/coal/stone, cached visible terrain | Biomes, water, collision terrain, map/minimap and resource preview |
| Engineer and economy | Walking/collision, interaction reach, hand mining, bounded inventory, material-based construction, queued crafting and refunds | Slot/stack inventory, individual withdrawals, equipment and crafting dependencies |
| Logistics | Snapshot belts with backpressure, inserter hands and input filters, storage, two belt speeds, lossless reclaim | Splitters and fair merge policies, underground belts, two lanes and sub-tile item spacing |
| Production | Fuel/energy budgets, input/output buffers, iron/copper/steel smelting, configurable assemblers, gear/wire/science recipes | Electricity and a consistent energy contract for powered machines |
| Progression | Empty start, 15 guided learning milestones, gradual recipe/tool disclosure, automated science consumption, two technologies, persisted learning counters | Branching research graph with selectable projects, science tiers, equipment upgrades and production-rate graphs; see progression.md |
| Settlement restoration | Oldbridge trading post, physical-goods supply contract, recurring trade credits, engineers' workshop crew payment, global burner-efficiency bonus | More project choices and spending goals, specialist services, distinct settlement needs and transport connections; see settlements.md |
| Persistence | Validated schema, complete in-progress state, backup writes, v1 import | Multiple named slots, autosave rotation, backup recovery UI |
| Usability | Inspector with wait reasons, construction ghost/reach, continuous painting, recipe and inventory controls | Recipe picker instead of cycling, hotbar rebinding, alerts, blueprint ghosts, copy/paste, undo |
| Later networks | Extension points in model and tick phases | Fluids before oil processing; rails before trains; pollution before enemies |

## Recommended next implementation: electricity

Add generation, consumption, and connectivity as a separate simulation system with explicit definitions for fuel energy, power production, and work energy demand. Introduce poles and a network graph updated when a pole/machine is placed, rotated, or removed. Calculate network supply/demand before production and gate recipe progress using the allocated work budget. Keep topology, energy buffers, and powered state separate from UI indicators. Tests should cover disconnected machines, insufficient generation, graph splitting/merging, energy conservation, and in-progress save/load.

After electricity, expand transport with splitters/underground belts and inventory UX. Add fluids only when solid-item production and network behavior are stable. Trains, combat, pollution, and multiplayer each introduce substantial state and performance requirements; keep them out of the core inventory/recipe code until their own models and tests are designed.
