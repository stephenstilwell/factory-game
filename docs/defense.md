# Oldbridge combat and beacon defense

This guide describes implemented behavior. See the [combat development plan](combat-roadmap.md) for the remaining encounter, reward and campaign backlog. Adding that plan does not change the current opt-in wave rules.

Oldbridge's beacon calls families home and wakes malfunctioning maintenance constructs from its old enchanted network. The engineer can now join a defense with a manufactured service rifle. Waves remain voluntary; new games still start empty.

## Try it

For a prepared interactive sandbox, run:

```powershell
godot --path . --script res://tests/play_defense.gd
```

This fixture supplies a restored town, mixed loaded defenses, a rifle, spare buildings, and ammunition. Its Save/Load slot is **defense_playtest_v2.json**, separate from normal saves. Close the Town panel after signaling, draw the rifle with V, and move toward the marked arrivals during the warning.

In a normal game, restore the trading post, restore the workshop, research Supply routes, and rebuild Town Hall. Craft equipment in C or automate it with assemblers. Walk within reach of the Hall hatch and choose **Signal arrival** in Y → Town Hall. A 15-second warning shows the incoming composition. You may cancel during this warning; once active, defend or recover from a breach.

## Player weapon and health

- Craft a **service rifle** using 8 iron plates, 4 gears, and 4 copper plates. It requires the workshop and Supply routes. Carry it in your pack; drawing it does not consume it.
- **V** draws/holsters. You can also double-click it in the pack or use its equip button.
- While drawn, **hold left mouse or Space** to fire toward the cursor during an active wave. Range is eight tiles, damage 16 before armor, and cooldown 0.3 seconds. The nearest construct intersecting the aim ray takes the hit. Misses consume ammunition. No firing/ammo consumption occurs between waves.
- Selecting a building or starting a blueprint holsters the weapon. Q, right mouse, or Esc also holsters before their normal world action. Menus and focus loss release the trigger; loading never resumes held input.
- The engineer has 100 health. Marked orange cells warn of a melee strike for 0.4 seconds; leave the marked cell to dodge. After five seconds without damage, health regenerates at ten points per simulated second.
- At zero health, retreat to a vacant cell near the Hall with inventory/equipment intact and five seconds of protection. The wave continues: turrets must protect the Hall while you recover.

The combat HUD shows health, available pack ammunition, protection, and the current weapon mode. Enemy hover text shows type, health, armor, and role. Building inspection and selected range rings explain turret coverage.

## Constructs and wave progression

| Construct | Former job / behavior | Base health | Armor | Structure/melee damage |
| --- | --- | --- | --- | --- |
| Signal scout | Road surveyor; fast, routes around isolated walls | 24 | 0 | 6 |
| Dismantler | Demolition machine; favors breaking through blockers | 40 | 2 | 16 |
| Armored hauler | Freight carrier; slow, heavily plated | 72 | 6 | 10 |

Wave one brings four scouts through the central eastern gate. Wave two adds dismantlers and opens the northern/southern gates. Wave three introduces haulers. Each subsequent wave adds two constructs; scouts/dismantlers gain four health per completed wave and haulers gain six. Later waves now use authored rushes, convoys, flank patterns and reinforcement pauses. See [encounter schedules and measured supply costs](combat-encounters.md).

These are machines carrying out a broken salvage order, not human bandits. Their shared fractured relay rune and Oren/Ada's dialogue connect them to the Quiet and the warning found beneath the workshop. Their final cause remains part of the story mystery.

Enemies choose four-direction paths in a bounded 29×15 arena relative to Town Hall. Weighted A* routes scouts around costly structures while dismantlers favor direct demolition. They attack solid obstacles before entering and can threaten a nearby engineer, but the Hall remains their objective. The gate markers show arrivals and general approaches, not immutable lanes. Walls shape routes; one wall does not seal a flank. There is no unlimited roaming-world pursuit.

## Defenses and supplies

| Defense | Unlock | Range | Effect | Ammunition / interval |
| --- | --- | --- | --- | --- |
| Gun turret | Workshop + Supply routes | 6 | 12 damage, armor applies; prioritizes threats near Hall | 1 / 0.5 s |
| Piercing cannon | Workshop + Foundry craft | 8 | 32 damage ignoring armor; prioritizes haulers | 2 / 1.5 s |
| Pulse turret | Workshop + District distribution | 4.5 | 8 armor-ignoring damage in a 1.8-tile radius, slows for 2.5 s | 2 / 1.2 s |
| Stone wall | Trading post | — | 120 health; shapes routes and delays dismantlers | — |

A cannon costs 8 iron plates, 6 steel, 4 gears, and 4 copper plates; a pulse turret costs 8 iron plates, 6 wire, and 4 gears. Cannons have 140 health; gun/pulse turrets have 100. All defense buildings and rifles have assembler recipes. One batch of two iron plates makes five ammunition items, shared by rifles and all turret types.

Turrets accept ten buffered rounds through normal manual/inserter loading and consume nothing without an in-range target. A cannon/pulse needs two rounds before firing. Combat consumption appears in F → Production. Shots pass over structures and never damage friendly buildings. There is no ballistic wall-occlusion model.

Manufacture ammunition in assemblers, move it through chests/belts/inserters, and keep defensive buffers stocked. Build overlapping coverage: guns handle scouts, cannons counter armor, and pulses keep groups under fire. H consumes a real repair kit to restore up to 50 structure health; it does not heal the engineer.

## Victory, damage, and recovery

Ten defenses secure the eastern route. Each victory records three sheltered families; the first grants +5% movement while the Hall operates. No following wave starts automatically. Families are a progress counter rather than simulated combatants.

At zero health, buildings remain disabled, passable ruins retaining inventories/work. Repair them before reclamation; you cannot repair a solid structure under the engineer or an enemy. A breached Hall withdraws remaining constructs, fails the current wave, and suspends civic services. Repair restores services; full Hall health permits retrying the same wave. Previously won waves, stock, skills, equipment, neighborhoods, and research remain.

Combat itself grants no repeatable skill XP or loot. Defense-supply crafting and first automated recipe commissions use the existing Fabrication rules.

## Foundation and compatibility

combat_catalog.gd defines weapon/enemy roles and deterministic compositions. defense.gd owns waves, attacks, physical-ammo turret behavior, and damage. player_combat.gd owns the rifle, health, retreat, and transient aim/trigger intent. combat_navigation.gd caches one weighted grid per enemy type, invalidating on placement, reclamation, and disabling/repairing structures.

Enemy types, health, slows, windups, targets, turret cooldowns, player health/protection and equipment persist. Aim, input, tracers and path caches are transient. Only the current defense schema is supported; impossible state is rejected.

Checks cover ammunition conservation/misses, armor and piercing, pulse groups/slows, obstacle-routing changes, dodging, safe retreat, input/menu isolation, mid-windup deterministic saves, obsolete-wave rejection, and a resupplied mixed-defense ten-wave campaign. Native captures review the battlefield, briefing, and turret inspection at 1280×800 and 1100×720.

## First-defense specialist and briefing

Winning the first wave rescues Nell, the quartermaster. The Town Hall briefing previews her service and shows live ammo, repairs and advisory range coverage. At the workshop, stock up to 100 ammunition and ask Nell to fill nearby healthy turret buffers between defenses. All rounds come from that reserve; warning/active-wave dispatch is blocked. See [C1 details](combat-readiness.md) for costs, range, recovery and persistence. Authored encounter bands and after-action reporting are now implemented in C2. The signal-station finale remains unimplemented.

## Encounter groups and after-action costs

The Hall briefing names the next encounter and discloses reinforcement pauses. These groups belong to one signaled defense; they do not automatically start another wave. A saved report shows the last attempt’s actual ammunition, in-battle repair kits and structure health lost. See [C2 details and finite-supply benchmarks](combat-encounters.md).
