# Oldbridge beacon defense

The Town Hall is Oldbridge's shelter and signal station. Its beacon guides families home and draws old salvage sentries along the eastern road. This first slice uses **one marked, fixed approach** and **ten voluntary waves**. There are no unannounced raids, character damage, weapons, or general enemy pathfinding yet.

## Playing the first defense

For a quick interactive sandbox with a restored hall, two loaded turrets, a wall, and spare supplies, run:

```powershell
godot --path . --script res://tests/play_defense.gd
```

Its Town Hall panel opens ready to signal. Save/Load use a separate `defense_playtest_v1.json` slot; regular saves and normal new-game progression remain separate. In the main game, earn the setup through the steps below.

1. Reopen the trading post and fund the engineers' workshop as before.
2. Rebuild the Town Hall at **(42, 12)**, hatch **(42, 13)**: **40 stone, 40 iron plates, 10 gears, 10 wire**. It requires the workshop; no additional trade-credit payment.
3. Research **Logistics I**. Craft gun turrets, ammo rounds, stone walls, and repair kits in **C**. Double-click walls/turrets in your pack to equip them for placement. The original eight factory hotbar slots retain their controls.
4. Follow the marked eastern approach. A useful first layout puts turrets at **(51, 11)** and **(51, 15)**, with a wall at **(49, 13)**. Supply ammo through the machine UI, Ctrl-click, or inserters. Stock ten rounds per turret for the first wave and bring repair kits.
5. Return to the Town Hall hatch, click it (or select it in **T → Town Hall**), then choose **Light beacon**. A **15-second warning** gives you time to prepare. You can extinguish it during this warning to cancel the arrival. An active attack must be defended.
6. Turrets fire automatically. Use **H** over damaged structures, or the repair button in their inspection panels, to consume a kit and restore **50 health**.

Coordinates follow the Town Hall if a migrated factory needs its ruin relocated. The route marker and Town UI show the actual approach; enemies always enter 22 tiles east of the hall's origin, on its middle row.

| Item | Material cost | Behavior |
| --- | --- | --- |
| Stone wall | 5 stone | 120 health; blocks the approach |
| Gun turret | 12 iron plates, 5 gears, 5 copper plates | 100 health; range 6; 12 damage per round, one shot per 0.5 seconds |
| 5 ammo rounds | 2 iron plates | Loaded into turrets; assembler production supported |
| Repair kit | 2 iron plates, 1 copper plate | Restores up to 50 health; hand or assembler production |

Walls and repair kits unlock after trading-post restoration. Turrets and ammo require the workshop and Logistics I. Turrets accept up to ten buffered rounds through normal manual/inserter loading. No target means no ammo consumed. Combat does not award Mining/Fabrication/Exploration XP; hand-crafting defense supplies grants ordinary Fabrication XP.

The first wave has **four 24-health scavengers**. Each later wave adds two scavengers and four health per scavenger. A successful defense increases the completed-wave count and records three sheltered families per wave. The first victory earns a persistent **5% movement bonus** from returning road crews while the hall is operational. These families are a progress counter, not a simulated population system. Wave ten secures this approach; no further wave can start.

## Damage and recovery

Scavengers move west along the marked lane. They stop to attack healthy solid buildings and civic landmarks in their way. Belts and inserters do not block them. Turrets prioritize the enemy closest to the hall; walls do not block friendly fire.

At zero health, factory structures remain as **disabled, passable ruins**. Inventories, outputs, inserter hands, stored fuel, and work progress remain owned by those structures. Disabled production/transport stops, and new machine deliveries are rejected. Repair restores operation. Damaged structures must be repaired before reclamation, preventing free repairs by picking them up and replacing them. You cannot rebuild a solid ruin while the engineer or a scavenger occupies its tile.

If the **Town Hall reaches zero health**, the beacon goes dark, remaining enemies withdraw, and the wave fails. Trade shipments and regional workshop bonuses pause. Research, skills, equipment, factory stock, and earlier victories survive. Repairing the hall reactivates services; fully restoring its health allows a retry at the same wave. It takes six kits to repair a completely breached hall. A damaged trading post pauses its own income at zero health, and a disabled workshop suspends its fuel bonus until repaired. This one-route slice only attacks structures on that route.

## Implementation and persistence

`simulation/defense.gd` owns the deterministic wave state machine, stable enemy IDs, lane movement, targeting, ammo consumption, and victory/recovery. It runs after inserters and before settlement economy, so delivered ammo can fire that tick and a breach immediately suspends shipments. Visual shot lines are transient; all authoritative combat timers, enemy positions/health, pending arrivals, and preparation countdowns are saved.

Buildings and civic sites store health. Existing entity records without health load fully healthy; previously restored civic sites also gain full health. Settlement extension version 2 adds the Town Hall and health. Version 1 saves keep their existing landmarks and receive only the missing ruin, placed on vacant land without displacing machines or the engineer. Saves without defense data start idle, so loading an established factory never starts an attack.

`persistence/defense_save.gd` checks phase invariants, unique enemy IDs/positions, route bounds, wave sizes, health, and timers before a decoded world can replace the live one. Mid-warning, active combat, and recovery round-trips are tested along with deterministic continuation, ammo conservation, automated resupply, and old-save placement. Preview defenses live in `tests/fixtures.gd`; normal new games remain empty.
