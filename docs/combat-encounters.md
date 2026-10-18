# C2: authored encounters and supply-cost tuning

Implemented 2026-10-17. C2 replaces the repeating composition formula with ten named, deterministic encounters. It does not add automatic raids, new enemy classes, a new arena or multi-wave operations.

## Encounter progression

The first three encounters retain the established introduction order and spawn cadence. Enemy health scaling remains unchanged; this pass varies composition, gate ordering, cadence and reinforcement timing.

| Arrival | Encounter | Count | Design |
| --- | --- | --- | --- |
| 1 | First signal | 4 | Scouts through the central approach |
| 2 | The split road | 6 | Dismantlers and three approaches |
| 3 | Freight from the Quiet | 8 | First armored hauler |
| 4 | Survey rush | 10 | Fast scout-heavy flanking arrivals |
| 5 | Broken convoy | 12 | Armored freight; two groups with a 6-second pause |
| 6 | Hold the crossing | 14 | Mixed groups with a 10-second resupply pause |
| 7 | Scouts ahead of steel | 16 | Scout screens and armored pairs; 8-second pause |
| 8 | The flanking sweep | 18 | Rapid flank packets; 8-second pause |
| 9 | The long freight | 20 | Heavy mixed traffic; 10-second pause |
| 10 | Last eastern arrival | 22 | Three mixed groups with 10-second pauses |

All groups belong to the one wave the player signaled. Defeating an opening group does not end that wave while scheduled reinforcements remain. The HUD explicitly identifies reinforcement countdowns, and the briefing explains the pattern before commitment. The 15-second initial warning and its cancellation remain unchanged. Subsequent waves never start themselves. C4's longer rescue operations and C6's signal-station finale remain future work.

Entry handling now waits visibly when both permitted entry cells are obstructed, instead of spawning a construct inside a building. Clearing the entry resumes the same pending wave. Enemy count and pathfinding bounds remain unchanged.

## After-action reporting

The Hall briefing retains the latest completed attempt's result: wave, victory/breach, ammunition actually fired, repair kits used during active combat, and actual structure health lost. Rifle and turret expenditure share the same count. Damage is capped by real health removed, not requested overkill damage.

Beginning a new attempt resets current counters while retaining the last completed report. Warning cancellation does not replace that report. Post-battle recovery repairs are excluded from the explicitly labeled in-battle kit total. The tuning benchmark records those costs separately.

Save validation preserves current counters, the last result and reinforcement pauses. It checks bounded numeric data, outcome/wave consistency and whether the remaining delay fits the particular scheduled group. As with other current-development-schema changes, pre-C2 saves missing the required cost/report fields require a new world.

## Finite supply benchmark

Run:

    godot --headless --path . --script res://tests/benchmark_defense.gd

Results are written to .godot/verification/defense_tuning.json. No test injects free rounds each simulation tick. Chest-fed layouts have fixed starting ammunition. The production layout starts with zero ammunition and uses normal assemblers/inserters to turn a bounded stock of iron plates into ammunition. All cases check conservation: rounds fired plus remaining physical ammunition equals starting ammunition plus actual production.

These are reproducible prepared layouts, not normal-campaign playtests or equal-budget comparisons. The mixed layout has seven defenses; the gun layout has two. The rifle case uses a simple stationary aiming helper, without intelligent dodging or repositioning. Its outcome must not be treated as a verdict on human rifle play. Between victorious attempts, Oren can spend the finite repair-kit and credit budget on repairs.

The production reference is intentionally overprovisioned with seven local ammo assemblers and 560 iron plates. It establishes viability, not a minimum-cost layout. The next balance pass should test a shared production line, more novice layouts and actual campaign unlock times.


### Recorded baseline

| Layout | Starting rounds | Starting iron | Defenses cleared | Rounds fired, including failed attempt | Rounds left |
| --- | ---: | ---: | ---: | ---: | ---: |
| two_guns | 200 | 0 | 5/10 | 200 | 0 |
| mixed | 700 | 0 | 9/10 | 694 | 6 |
| mixed_with_reserve | 800 | 0 | 9/10 | 759 | 41 |
| mixed_production | 0 | 560 | 10/10 | 767 | 88 |
| rifle_and_guns | 300 | 0 | 4/10 | 203 | 97 |

Production-fed reference: 855 rounds manufactured, 342 plates consumed in completed ammo batches, 88 rounds retained. No structural damage or repair kits were required in this particular maintained layout.

| Arrival | Rounds fired | Seconds including warning | In-battle kits | Structural damage |
| --- | ---: | ---: | ---: | ---: |
| 1 | 8 | 21.6 | 0 | 0 |
| 2 | 16 | 28.6 | 0 | 0 |
| 3 | 28 | 30.3 | 0 | 0 |
| 4 | 37 | 27.3 | 0 | 0 |
| 5 | 68 | 43.9 | 0 | 0 |
| 6 | 73 | 43.6 | 0 | 0 |
| 7 | 102 | 47.7 | 0 | 0 |
| 8 | 105 | 41.3 | 0 | 0 |
| 9 | 143 | 58.7 | 0 | 0 |
| 10 | 187 | 63.6 | 0 | 0 |

### Interpretation

The early scout lessons are affordable: the two-gun first defense uses eight rounds and no repairs. Later mixed roles and repeated arrivals expose stock and distribution problems. More stored ammo does not guarantee that the correct gun receives it. The production-fed reference clears all ten, demonstrating a complete physical supply route without an unlimited-stock cheat.

These results support keeping the first introduction approachable and making later fights test sustained supply. They do not justify a new enemy-health multiplier or an automatic threat director. Weapon feedback, efficient shared supply layouts, retreat behavior and normal-campaign player testing remain important tuning work.

## Verification

encounter_tests.gd checks every schedule, bounded role/gate data, role introduction, exact reinforcement boundaries, no premature victory, obstruction recovery, actual ammo/repair/damage accounting, breach/retry reporting, save continuation and briefing presentation.

Existing combat checks still cover armor, piercing, slowing, routing, rifle input, repair recovery and a resupplied ten-wave campaign. Native captures include the encounter plan, reinforcement countdown and after-action summary. The minimum-window/fullscreen layout regression remains required.
