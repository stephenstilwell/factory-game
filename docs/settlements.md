# Oldbridge restoration: first playable slice

The factory supplies a town that can give something back. There are three restoration projects, a physical-goods contract, and a defendable Town Hall beacon. See [defense.md](defense.md) for voluntary waves, damage, and recovery. Broader population, commerce, transportation, and settlement networks remain future systems.

## Projects

| Project | Initial location / hatch | Repair materials | Crew payment | Reward |
| --- | --- | --- | --- | --- |
| Oldbridge trading post | 3x3 ruin at (30, 13); hatch (30, 14) | 10 stone, 20 iron plates, 5 gears | None | Mira returns; timed supply contracts become available |
| Engineers' workshop | 3x3 ruin at (35, 18); hatch (35, 19) | 20 iron plates, 5 gears, 10 copper plates | 60 trade credits | Oren returns; all burner drills and furnaces get 20% longer active work per new coal |
| Oldbridge Town Hall | 3x3 ruin at (42, 12); hatch (42, 13) | 40 stone, 40 iron plates, 10 gears, 10 wire | None; requires workshop | Ada returns; voluntary beacon defenses; first victory earns a 5% movement bonus |

Coordinates may differ in migrated saves when the original site footprint was occupied. The town panel always reports the actual hatch location.

Press **T** to browse projects. Select a project to see material progress, payment, rewards, and delivery coordinates. A selected landmark has a highlighted footprint and a directional pointer. Walk within six tiles of its hatch to interact. Clicking the landmark also opens its panel.

Before restoration, **Ctrl-click / Deliver repair materials** transfers whatever you have toward the remaining requirements. Excess/unrelated items stay in your pack. Partial deliveries persist. **X / Withdraw unused goods** retrieves uncommitted items when your inventory has room. When the materials and any required credits are available, press **Restore**. The transaction consumes the required materials and credits exactly once. Landmarks cannot be reclaimed, moved, or converted into free machine items.

Restoration visibly replaces broken roofs, boards, and rubble with repaired buildings, lit windows, and working facilities. The reopened trading post has a staffed stall and a greeting from Mira. The workshop has Oren's explanation of the regional bonus.

## Contract: Parts for our neighbors

- Each shipment consumes **4 iron plates and 1 gear**.
- Delivery takes **300 simulation ticks / 30 seconds**.
- Each delivered shipment pays **10 trade credits**.
- The intake buffers at most ten additional batches: 40 plates and 10 gears.
- Maximum sustained earnings are 20 credits per simulated minute, assuming enough supplies.

On dispatch, the goods leave the buffer and become committed. The timer then advances; payout happens once at delivery. The next batch can dispatch on the following tick. Waiting without goods never banks timer progress or creates income. Unused buffer stock can be withdrawn; goods already in transit cannot be withdrawn. A dispatched shipment still arrives if future stock runs out.

**Ctrl-click / Supply one shipment** contributes up to one batch from the engineer's pack, including partial batches. For recurring income while you build elsewhere, automate deliveries:

```text
Chest or belt at (28, 14) -> inserter at (29, 14), facing EAST -> hatch at (30, 14)
```

The hatch also accepts repair goods before reopening. Deliveries elsewhere on the footprint are rejected. Inserters retain their carried item when an intake is full, and filter pickups according to the current repair/contract demand. Empty belts cannot feed the hatch directly; use an inserter.

Repairs are permanent. Supply interruptions stop future income without closing the repaired building, damaging it, or removing regional bonuses. Shipment timers freeze when paused and resume after loading; offline elapsed time does not produce income.

## Spending and the first civic bonus

Six completed shipments earn the workshop's 60-credit crew payment. Deliver its materials and restore it. Money pays for the crew; physical construction goods are still required.

The workshop gives each subsequently consumed coal **96 active work ticks instead of 80**, for every burner drill and furnace in the world. This improves fuel efficiency, not recipe speed. Already-burning coal keeps its remaining energy; rebuilding/inspecting cannot refill it. The bonus is derived from the unique repaired project, so it cannot be purchased repeatedly or stacked by building copies. The HUD and town panel show it as active.

This slice uses an explicit global effect. There is no regional connectivity requirement, power graph, simulated population, player-to-player economy, general-purpose item shop, or offline idle system yet. Further spending choices should be added as functioning projects, rather than showing unavailable purchases as completed features.

## Implementation contracts

- `scripts/data/settlement_catalog.gd`: stable project/contract definitions, repair costs, rewards, footprints, hatch offsets, and effect values.
- `scripts/model/settlement_site.gd`: a site's persistent inventory, position, repair state, shipment timer, and completed-delivery count.
- `scripts/simulation/settlements.gd`: intake quotas, atomic repair transactions, physical-goods shipment economy, derived effects, and spatial indexes.
- `scripts/simulation/world.gd`: interaction reach and player-to-site commands; logistics receiver adapter; burner duration facade.
- `scripts/ui/settlement_panel.gd`: project browser and inspection, emitting intent through the HUD.
- `scripts/view/settlement_view.gd`: procedural ruin/restored landmark drawing and staff representation.
- `scripts/persistence/settlement_save.gd`: settlement extension validation and currency reconciliation.

Settlement processing occurs after inserters and before engineer/crafting/mining in each fixed tick. A newly received complete batch can dispatch during that tick. Settlement receivers share the input interface used by inserters, without being registered as factory entities or appearing in the player's build catalog.

The world-v2 save has an optional `settlements` extension with its own version (currently 1). It stores both projects, uncommitted supplies, shipment timers, completed shipment counts, current credits, and total earned. Validation checks quotas, known IDs, timer ranges, spatial collisions, repair prerequisites, and that earned income minus crew payments equals the wallet. Effects are derived from restored sites rather than serialized twice.

When the extension is absent, ruins are added on vacant land using deterministic relocation if necessary. Existing machines and the engineer's location are preserved. A malformed present extension is rejected rather than silently reset. Contract costs/durations and project IDs are save-compatible data: changing their interpretation requires migration.

Tests include the entire progression from an empty pack through both projects using mined/crafted materials, automated delivery, stock shortages, full buffers, blocked hands, exactly-once payments, save/load during transit, bonus application, currency reconciliation, migration around existing construction, and UI command wiring.
