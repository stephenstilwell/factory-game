# C3: weapon handling, sidegrades, and combat feedback

Implemented 2026-10-17. C3 expands the combat loop with authored weapon sidegrades, tactical defensive barriers, and clear readable battlefield feedback without changing opt-in wave activation or forcing combat progression onto peaceful players.

## Equipment sidegrades

Rather than simple numeric damage upgrades, C3 introduces distinct weapon and defensive roles with explicit tactical tradeoffs:

| Equipment | Category | Unlock | Cost | Key attributes | Role & tradeoff |
| --- | --- | --- | --- | --- | --- |
| **Service rifle** | Hand weapon | Workshop + Supply routes (`logistics`) | 8 iron plates, 4 gears, 4 copper plates | Range 8.0, 16 damage (kinetic), 0.3s cooldown, 1 ammo/shot | Rapid-fire carbine. Highly efficient against fast swarms of signal scouts (16 dmg kills in 2 shots); enemy armor reduces damage against haulers and dismantlers. |
| **Precision rifle** | Hand weapon | Workshop + Foundry craft (`metallurgy`) | 6 steel, 4 gears, 6 wire | Range 11.0, 36 damage (armor-piercing), 0.9s cooldown, 2 ammo/shot | Heavy long-rifle. Pierces armor to eliminate armored haulers in 2 shots (36 dmg vs 72 HP); 3x slower fire rate and double ammo cost make it risky and wasteful against swarms of fast scouts. |
| **Stone wall** | Barrier | Trading post | 5 stone | 120 health | Inexpensive early obstacle. Shapes construct pathfinding and delays scouts and dismantlers. |
| **Reinforced barricade** | Barrier | Workshop + Foundry craft (`metallurgy`) | 4 stone, 2 steel | 320 health | Heavy steel-plated defense. 2.6x the durability of stone walls; withstands sustained dismantler demolition at critical chokepoints. |

Both rifle types and both wall types have full automated assembler recipes as well as manual hand-crafting support once unlocked.

## Weapon handling & controls

- **Equipping & Drawing [V]**:
  - Pressing **V** draws the active carried rifle.
  - If carrying multiple rifles (e.g. both a service rifle and a precision rifle), pressing **V** while drawn seamlessly switches to the next carried weapon, announcing its range, damage, piercing type, and ammo cost. Pressing **V** after cycling holsters the weapon.
  - In your pack (Inventory workspace **I**), selecting any rifle displays its full combat dossier and offers **Draw / equip [V]**. Double-clicking either rifle in the pack immediately equips and arms that specific weapon.
  - The HUD weapon button displays the active weapon name, range, damage, and fire mode, and indicates when switching between multiple carried rifles is available via `[V]`.
- **Targeting & Reticle**:
  - The in-world aiming circle and maximum range arc automatically adjust to the active weapon (8.0 tiles for the service rifle, 11.0 tiles for the precision rifle).
  - The engineer's drawn weapon sprite visually reflects the equipped model: the precision rifle shows an extended steel barrel, reinforced receiver, and mounted optics.
  - Holding **LMB** or **Space** while armed during an active wave fires toward the cursor. Opening any workspace, entering blueprint mode, selecting a building to place, or losing application focus safely holsters the weapon and clears firing intent.

## Readable battlefield feedback

Combat feedback clearly distinguishes full damage, armor resistance, armor piercing, and misses:

- **Armor resistance (`Resisted`)**: When an enemy's armor reduces damage (e.g. standard service rifle bullets hitting an armored hauler with 6 armor), the floating damage indicator visibly reports both actual damage and absorbed armor damage (e.g. `-10 [Armor -6]`) in warm copper text, accompanied by a metallic deflection cue.
- **Armor piercing (`Pierced`)**: When an armor-piercing weapon (precision rifle or piercing cannon) ignores enemy armor, a bright teal floating indicator displays the full damage with a `PIERCE` marker (e.g. `-36 PIERCE`).
- **Standard hit (`Hit`)**: Clean damage against unarmored targets (such as signal scouts) appears as a bright cream floating counter (e.g. `-16`).
- **Missed shots (`Miss`)**: When a shot fails to intersect any construct along its trajectory, an expanding puff and `MISS` marker appear at the ray's terminus. Missed shots strictly consume ammunition from your pack and are counted in after-action ammo costs.
- **Tracers**: Standard rifle rounds leave crisp warm amber tracers; heavy precision rifle rounds cast high-velocity cyan/steel tracers matching their armor-piercing impact.
- All floating text, particle bursts, and tracer glows honor the ambient lighting toggle and reduced-motion preferences.

## Ammunition conservation & recovery

- **Strict conservation**: Every shot removes the exact ammunition cost (1 round for the service rifle, 2 rounds for the precision rifle) from the engineer's pack. Total ammunition is strictly conserved:
  $$\text{Rounds Fired} + \text{Remaining Ammo} = \text{Starting Ammo} + \text{Manufactured Ammo}$$
- **Protective coat integration**: Warden protective coats (rank 1: 15%, rank 2: 30%) reliably mitigate incoming construct melee damage, always guaranteeing at least 1 point of damage per damaging strike.
- **Defeat & Safe Retreat**: When engineer health reaches zero during a battle, the engineer retreats safely to an unobstructed cell adjacent to Town Hall. Pack supplies, carried weapons, and equipment are completely preserved. The engineer receives 5.0 seconds (50 ticks) of protective invulnerability, health regenerates to 100, and firing stops while the voluntary wave continues.

## Verification

The test suite in `tests/weapon_handling_tests.gd` exercises:
1. Weapon definitions, range, damage, rate of fire, ammo cost, and piercing properties.
2. Gated crafting and assembler manufacturing for both rifles and reinforced barricades.
3. Weapon drawing, switching between multiple carried rifles, direct pack double-click equipping, and automatic holstering upon storing weapons.
4. Armor resistance calculation on haulers (`-10 [Armor -6]`), piercing bypass (`-36 PIERCE`), and clean scout damage.
5. Terminal miss indicators, trace dissipation, and strict ammunition accounting across hits and misses.
6. Reinforced barricade durability (320 health), dismantler demolition pathfinding, and material repair with kits.
7. Save/load roundtrip persistence of active weapon, cooldowns, and defense costs in the current schema.
8. Native HUD weapon controls, switching tooltips, and keyboard shortcuts at standard resolution.

