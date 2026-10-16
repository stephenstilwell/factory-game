# Oldbridge through the ages: Timber to Stone

**New games:** this original civic overlay has been replaced by [the actual timber-to-iron opening](timber-opening.md). The Hall project below remains available to existing saves so their progression is preserved.

This first playable chapter makes town restoration distinct from the machine technology tree. New towns begin in **Timber & Hearth**. Machinery still unlocks through existing research; the civic age describes the settlement's homes, materials and shared prosperity.

## Two landscapes, two reasons to explore

- **Oldbridge Farmlands** surround the Lost Orchard: warm soil, surviving field furrows and light fruit-tree foliage. Recover Iona's cutting for the community garden and the town's food-growing knowledge.
- **Greybank Highlands** surround the new Greybank Quarry northwest of town: cool stone ground, exposed rock details and blue-green groves. Recover a mason's pattern for permanent civic construction (+350 Exploration XP).

These are landmark-centered overworld regions derived from saved landmark origins. They do not replace the ore generator, introduce survival needs, or move existing factories. They establish a biome/restoration relationship before larger regional systems are added.

## Stone & Water project

Open **Town [Y]**, then **View Stone & Water project**. The same project appears at the top of Town Hall details, with prerequisite checks, pack material counts and an explicit completion button.

Requirements:

- Restore the market, workshop and Town Hall through their existing projects.
- Recover the orchard cutting and Greybank mason pattern through Discoveries [L].
- Bring **80 stone, 20 iron plates and 10 gears** to the Hall hatch.
- Complete any warning/active beacon defense and repair a breached Hall first.

The project consumes the entire material cost atomically. It grants **500 Fabrication XP once**, changes repaired civic walls/foundations/roofs and restored cottage materials, and adds **2 credits** to each market shipment completed afterward (12 total). Supplies must still be consumed for every shipment; the age adds no idle or offline income and starts no combat waves. Town service outages pause deliveries under existing rules.

Existing materials, equipment, neighborhoods and technologies retain their roles. Timber and Stone are civic chapters rather than global restrictions on iron machinery. Despite the chapter's name, this first slice does not yet simulate canals or water production.

## Persistence and migration

The settlement extension adds optional `age` (0 or 1) and `stone_shipments` fields. Old saves default to Timber without losing repairs or research. Income validation adds only recorded Stone shipment premiums to the existing exact currency reconciliation. Advancement cannot be repeated, including after reload.

Existing frontier saves receive only missing landmarks. The bounded vacant-space search preserves every existing landmark, factory, live deposit, civic footprint, player position and defense approach. If no safe quarry placement exists in a heavily occupied save, its lead remains unavailable rather than overwriting construction.

Regions and their decoration use the existing cached terrain chunks; trees retain the chunk candidate cache and shared ellipse texture. No per-tile biome nodes or distant wildlife simulation are introduced.

## Direction for later chapters

**Iron & Industry** can reconnect distant settlements through freight and specialized workshops. **Aether & Renewal** can restore damaged ecosystems using understood, carefully maintained magic. These are future chapters, not available upgrades in this build. Waterworks, new regional production chains and additional engineering puzzles can build on the civic age foundation.

Verification covers atomic costs, proximity and defense guards, discovery requirements, one-time XP, income with real supplies, save currency reconciliation, malformed age data, migration preserving existing origins, region placement and new-game reset. Native captures use `tests/capture_ages.gd`.
