extends RefCounted
## Permanent manufactured improvements, separate from factory recipe research.
const BASE_STATS := {"movement_speed": 4.0, "mining_ticks": 8, "interaction_reach": 6.0, "inventory_capacity": 10000}
const UPGRADES := {
	"boots": {"name": "Surveyor boots", "description": "Cover more ground while surveying and running supply routes.", "stat": "movement_speed", "values": [4.6, 5.2, 5.8], "costs": [{"iron_plate": 10, "gear": 3, "copper_plate": 5}, {"iron_plate": 25, "gear": 10, "wire": 10}, {"steel": 15, "gear": 20, "wire": 20}]},
	"pickaxe": {"name": "Powered mining tools", "description": "Mine faster by hand. Automated drills keep their own production rates.", "stat": "mining_ticks", "values": [6, 5, 4], "costs": [{"iron_plate": 10, "gear": 5}, {"iron_plate": 30, "gear": 10, "copper_plate": 10}, {"steel": 20, "gear": 15, "wire": 20}]},
	"reach": {"name": "Utility harness", "description": "Reach farther to build, mine, and interact with machines and civic hatches.", "stat": "interaction_reach", "values": [7.0, 8.0], "costs": [{"iron_plate": 15, "gear": 5, "copper_plate": 5}, {"iron_plate": 30, "gear": 10, "wire": 20}]},
	"pack": {"name": "Expedition pack", "description": "Carry more individual items. Each inventory tile still groups one item type.", "stat": "inventory_capacity", "values": [12500, 15000], "costs": [{"iron_plate": 20, "gear": 5}, {"iron_plate": 40, "gear": 10, "copper_plate": 15}]},
}

static func gate(world: RefCounted, rank: int) -> String:
	if world.guide.enabled and "drill_online" not in world.guide.completed: return "Finish the first working-drill lesson."
	if rank >= 2 and "logistics" not in world.researched: return "Research Supply routes."
	if rank >= 3:
		if "metallurgy" not in world.researched: return "Research Foundry craft."
		if not world.settlements.enabled or not world.settlements.sites.workshop.repaired: return "Restore the engineers' workshop."
	return ""

static func format_stat(stat: String, value) -> String:
	match stat:
		"movement_speed": return "%.1f tiles/sec" % float(value)
		"mining_ticks": return "%.2f items/sec (%.1fs/item)" % [10.0 / float(value), float(value) / 10.0]
		"interaction_reach": return "%.0f tiles" % float(value)
		"inventory_capacity": return "%d items" % int(value)
	return str(value)
