# Engineer progression

The Engineer workspace now separates **Skills** (use-based Mining, Fabrication, and Exploration levels 1–99) from **Equipment upgrades** (the purchased tiers below). Skill milestones add modest bonuses to equipment-derived stats; they do not introduce new requirements for existing equipment. See [skills.md](skills.md).

Press **P**, or choose **Engineer** inside the inventory workspace. The panel shows current stats, the next improvement, exact material counts, and any missing milestone. Installing a tier consumes manufactured goods from the pack immediately. Upgrades are permanent; there are no XP points, random rolls, free unlock rewards, or recurring fuel costs.

| Upgrade | Base | Tier 1 | Tier 2 | Tier 3 |
| --- | --- | --- | --- | --- |
| Surveyor boots | 4 tiles/sec | 4.6 | 5.2 | 5.8 |
| Powered mining tools | 0.8 sec/item | 0.6 | 0.5 | 0.4 |
| Utility harness | 6-tile reach | 7 | 8 | — |
| Expedition pack | 10,000 items | 12,500 | 15,000 | — |

Tier 1 becomes available after the first working-drill lesson. Tier 2 requires Logistics I. Tier 3 requires Metallurgy and the restored engineers' workshop. Old factories with introductory lessons disabled can buy the first tier immediately, while research and workshop requirements still apply. Each upgrade track progresses independently and in order. Exact costs live in `scripts/data/character_catalog.gd`: early tiers use plates and gears; advanced tiers add copper, wire, and steel.

Movement upgrades retain collision and normalized diagonal movement. Mining upgrades improve hand mining only and still consume one unit of finite terrain stock per item; a full pack stops mining. Reach affects construction, mining, machines, and civic hatches through one shared validation method. Increased pack capacity applies to transfers, crafting output, refunds, and saving. Base stats and empty-start progression remain unchanged.

## Model and saves

`CharacterProgression` owns purchased ranks, validates progression and costs, and applies purchases atomically through `World.upgrade_character(id, expected_rank)`. The expected rank rejects stale purchase requests. Views emit purchase intent; they do not grant stats or remove goods.

Consumers read derived stats rather than repeating constants. The movement system uses tiles per second, mining uses integer simulation ticks, and world commands use effective interaction reach. Each current track owns one stat. Definitions, purchasing, simulation, and UI stay separate so new tracks can be added without rewriting input handling.

The optional `character` save extension stores version 1 plus purchased ranks. Effective stats and capacity are recomputed. Loading validates known IDs, integer rank bounds, progression prerequisites, and inventory size against derived capacity. Saves without this extension receive unchanged base stats. Starting a new world clears upgrades. Personal upgrades do not spend trade credits or alter settlement accounting.

## Preparing for light combat and settlement defense

The next useful character tracks are protective equipment (health/armor), weapon handling, and field repairs. Add these alongside actual damage, enemies, weapons, and repair interactions so every upgrade has an observable use. A later equipment layer can feed modifiers into the same derived-stat boundary; save equipment identities and ranks rather than cached final values.

Factory research should unlock ammunition, turrets, walls, and repair supplies; personal upgrades should improve the engineer's ability to scout, fight, and maintain defenses. Town restoration can provide specialist trainers, equipment tiers, and regional support. This keeps factory production and settlement protection connected instead of introducing a separate XP grind. Enemy waves, engineer health/retreat, a service rifle, three turret roles, and structure repairs are implemented; personal armor and weapon-handling upgrade tracks remain future work. See [defense.md](defense.md).
