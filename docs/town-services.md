# Workshop maintenance crew

Restore the Engineers' Workshop, then open it in Town [Y] while standing beside its
delivery hatch. Oren's maintenance crew provides a practical use for trade and relief
credits after reconstruction.

The button previews the exact structures helped, health restored, repair kits consumed,
and credit fee. Dispatch uses the displayed kits from your pack and **2 credits per kit**.
Each order uses at most ten kits, limited by actual funds, available kits and repair needs.
Your engineer's repair-power upgrades also improve the crew's work per kit.

The crew repairs eligible factory structures and already-restored civic buildings within
28 tiles of the workshop hatch. Lowest health percentage comes first, then distance and
stable identity. Health never exceeds its maximum. A small budget can partially repair a
structure. Full-health structures, distant factories, enemy-occupied tiles and solid
structures occupied by the player are skipped.

Crews work between defenses. The beacon warning and active waves block dispatch, and a
disabled workshop must first be repaired manually. A breached Hall must be stabilized
with H before town services reopen; the crew can then finish its recovery. Manual H
repairs remain available without the credit fee.

Orders are immediate and explicit. There are no ongoing wages, automatic purchases, new
background actors or offline repairs. Crews do not restore ruins for free, generate goods,
or grant repeatable repair XP. The market's existing supply bundle remains a source of
repair kits alongside crafting.

## Persistence and verification

Settlement saves add an optional maintenance_kits ledger (zero for older saves).
Currency validation includes the fee for every consumed service kit, alongside existing
restoration and supply-order spending. Damaged-structure health and blocker navigation
updates use the existing repair conventions.

tests/town_services_tests.gd checks prioritization, radius, exact spending, partial
affordability, stale quotes, combat/reach restrictions, Hall recovery, ledger validation,
old saves and UI availability. Native verification clicks the actual workshop button
through the UI intent chain and checks both repair and payment at 1100×720.
