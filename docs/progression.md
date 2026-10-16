# Progression design

## Direction

Use **guided learning milestones for the opening, followed by a branching science-funded research tree**. Material-funded engineer equipment and optional 1–99 skills complement research. One-time automation commissions reward replacing manual work with production lines; no free item rewards are used.

Milestones teach a specific action and reveal the next relevant recipe/tool. Research consumes produced resources and unlocks lasting capabilities. Keep the two systems separate, so adding onboarding text does not change technology costs or network behavior.

The first non-tutorial objective is now implemented: restore Oldbridge's trading post, supply manufactured goods to earn trade credits, and use those credits plus materials to restore the engineers' workshop. Its permanent global fuel-efficiency bonus makes the settlement contribute back to the factory. The town panel is available during learning; the regional objective takes the main objective line after learning is complete. See [settlements.md](settlements.md).

## Implemented opening

New games start near stone with an empty pack, no working machines, no technologies, and no queued crafts. Abandoned civic landmarks wait to be restored. Hand mining is an innate action. A furnace costs only stone, so it can be crafted before any metal exists; the player then supplies hand-mined ore and coal to produce the first plates. No seeded inventories, hidden starter fuel, or reward items are used.

The 15 current lessons introduce:

1. Mine 5 stone.
2. Craft a stone furnace.
3. Place it.
4. Gather 5 iron ore and 2 coal.
5. Load/fuel the furnace.
6. Smelt 5 plates.
7. Collect them; reveal gears and drills.
8. Craft 3 gears.
9. Craft a drill with 5 additional plates and 5 stone.
10. Run a fueled drill on iron; reveal belts, inserters, and chests.
11. Deliver 5 plates automatically into a chest; reveal assemblers and copper wire.
12. Smelt 5 copper plates.
13. Produce a gear in an assembler; reveal engineering dossiers and labs.
14. Produce 10 engineering dossiers.
15. Consume them in a lab to research Supply routes; reveal fast belts.

Only the current lesson and relevant recipes/tools are displayed. Controls, ingredient quantities, progress counts, resource coordinates, a target ring, and a direction arrow provide contextual instruction. Completed lessons remain complete when materials are consumed or machines reclaimed. Actions completed ahead of their lesson are retained, so the player does not have to repeat them. Cancelled crafts do not count as completed production.

Definitions live in `scripts/simulation/onboarding.gd`. Its counters are fed by successful world commands and simulation events, not UI clicks or current inventory counts. Guide state is saved and validated independently of research. The entire resource-only path through first research is covered by an integration test. Test-only worlds can omit onboarding to exercise individual systems directly. Existing saves without guide state remain unrestricted.

## Implemented research branches

Supply routes (10 engineering dossiers) opens both Foundry craft (20, steel) and District distribution (20, splitters and underground conveyors). Homes for Oldbridge (25, construction kits) follows Foundry craft. Press T to choose an available project; switching preserves invested dossiers. Drafting benches consume real dossiers. Completion leaves benches idle until you choose the next project.

Construction kits feed Town Hall housing deliveries: each three deliveries restores a neighborhood, up to three, each adding +5% base coal working time. This gives the steel branch a settlement purpose. Routing improves distribution and reuse of layouts. All placeable buildings can now be manufactured in assemblers. See [factory expansion](factory-expansion.md) for controls, costs, metrics, and saved construction plans.

Future work should add real capabilities:

| Future branch work | Capabilities |
| --- | --- |
| Logistics | Filter/priority routing and better inserters |
| Energy | Electricity, poles, generation, storage, improved energy systems |
| Production | New materials and recipes, advanced assemblers |
| Chemistry | Fluids, oil processing, plastics, chemical science |
| Transportation | Rails, trains, stations, automated supply networks |
| Engineer equipment | Better tools, inventory capacity, movement and construction aids |

Prioritize unlocks that change layouts and decisions over repeated percentage bonuses. Efficiency/speed upgrades can follow once the systems they modify exist. Research definitions must reference real implemented content; planned branches should not appear as functional unlocks before those systems are built.

Introductory milestones may remain linear to control teaching order. Research branches should provide choices without letting the player bypass the material dependencies needed to bootstrap a factory. Remote construction and broader exploration should grow from actual factory-scale needs; configuration copy/paste and finite resource exploration are already available.
