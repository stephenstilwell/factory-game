# Oldbridge pacing and civic logistics

This pass makes expanding a settlement the reason for automation. Workshops produce engineering dossiers at drafting benches, housing deliveries restore visible neighborhoods, and voluntary beacon arrivals bring families and practical crew services.

## Less routine fuel work

Coal supplies 240 active ticks, three times the previous 80. A repaired workshop adds 48 ticks (+20% of base); each restored neighborhood adds 12 (+5%). Existing burning energy is preserved, not refilled.

The Supply Hearth becomes available with storage after the first working drill. Its recipe uses 10 iron plates, 4 gears, and 10 stone; assemblers can manufacture it. Load all coal with one action, or feed it continuously by inserter. Capacity is 200 coal; only coal is accepted.

Healthy drills and furnaces within eight tiles receive actual coal, with a small three-coal reserve. Scarce deliveries rotate by stable entity ID; the cursor persists across saves. Distribution uses bounded local occupancy lookups, skips empty stores, and does not scan the whole factory for every hearth. Overlapping hearths respect the same reserve. Disabled buildings do not receive supplies. Select a hearth to see its coverage.

## Resources that support longer projects

Deposits have generous but finite stock. Saving preserves exact remaining amounts, including exhausted tiles. No resource-richness migration occurs.

## Interfaces and controls

- C / E opens crafting with a seven-column palette using the full workspace, including extra height. All current hand recipes fit at 1100x720 and 1280x800; search, category, and ready filters remain.
- T opens Technology. Four project cards show purpose, prerequisites by name, investment, and unlocks.
- Y opens settlement projects.
- F opens production and construction plans.
- Benches wait for the next project choice. Supply routes starts selected; switching projects banks invested dossiers. Current saves store selection and investment explicitly.

Stable IDs remain unchanged for save compatibility. Engineering dossier and drafting bench replace the science flask / lab presentation, including their vector art. New project names are Supply routes, Foundry craft, District distribution, and Homes for Oldbridge.

## Arrivals worth preparing for

Before signaling, Town Hall shows composition and concrete victory rewards alongside the action. Waves remain voluntary, with a cancelable 15-second warning.

Each successful arrival shelters three families and pays 25 + 5 times its wave number in relief credits (30 for the first, 75 for the tenth). First victory enables +5% movement while Town Hall operates. Every second victory extends hearth coverage by one tile, capped at twelve tiles after eight victories. A breached Hall suspends the crew extensions; base hearth service continues.

Trade and relief credits share a wallet. At the repaired trading post, after restoring the workshop, buy a supply bundle for 20 credits: 20 coal, 10 ammunition, and 2 repair kits. Reach, services, funds, and pack capacity are checked before spending; delivery is atomic. This gives credits a recurring use after civic restoration. Relief payments and bundle spending have saved ledgers reconciled against income, completed waves, and restoration costs. Failed waves pay nothing, duplicate completion callbacks cannot pay twice, and old victories receive no retroactive cash.

## Playtest

1. Start empty, reach the working-drill lesson, and craft a hearth. Place it near a drill and furnace, load coal once, and watch both work. Feed its store by inserter.
2. Reload partially mined and exhausted deposits; verify exact remaining stock.
3. Open C at 1100x720. Inspect recipes, ingredients, queue jobs, and filters.
4. Press T, complete a project, choose a branch, switch away and back, then save/load.
5. Inspect Town Hall with Y. Compare its promised first reward with the wallet after victory.
6. Buy a supply bundle at the trading post. Defend a second arrival and inspect a hearth's increased coverage.
