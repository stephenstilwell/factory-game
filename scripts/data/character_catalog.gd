extends RefCounted
## Permanent manufactured improvements, separate from factory recipe research.
const BASE_STATS := {"movement_speed": 4.0, "mining_ticks": 8, "interaction_reach": 6.0, "inventory_capacity": 10000, "repair_power": 50, "survey_bonus": 0, "damage_reduction": 0}
const UPGRADES := {
	"armor": {"name": "Warden protective coat", "description": "Reduce damage to the engineer by 15%, then 30%. Does not protect buildings or replace defenses. Always takes at least one damage per hit.", "stat": "damage_reduction", "values": [15, 30], "costs": [{"iron_plate": 20, "wire": 10}, {"steel": 20, "gear": 10}]},
	"repair": {"name": "Warden repair rig", "description": "Restore more structure health per repair kit. Useful on the hall, walls, and factory buildings.", "stat": "repair_power", "values": [65, 80, 100], "costs": [{"steel": 10, "gear": 8, "wire": 10}, {"steel": 20, "gear": 15, "construction_kit": 4}, {"steel": 35, "gear": 25, "construction_kit": 8}]},
	"scanner": {"name": "Frontier survey instruments", "description": "Search farther for finite resource patches. Adds to Exploration survey bonuses.", "stat": "survey_bonus", "values": [1, 2], "costs": [{"steel": 12, "wire": 20, "gear": 10}, {"steel": 30, "wire": 40, "construction_kit": 6}]},
	"boots": {"name": "Surveyor boots", "description": "Cover more ground while surveying and running supply routes.", "stat": "movement_speed", "values": [4.6, 5.2, 5.8, 6.2], "costs": [{"iron_plate": 10, "gear": 3, "copper_plate": 5}, {"iron_plate": 25, "gear": 10, "wire": 10}, {"steel": 15, "gear": 20, "wire": 20}, {"steel": 40, "gear": 30, "construction_kit": 8}]},
	"pickaxe": {"name": "Powered mining tools", "description": "Mine faster by hand. Automated drills keep their own production rates.", "stat": "mining_ticks", "values": [6, 5, 4, 3], "costs": [{"iron_plate": 10, "gear": 5}, {"iron_plate": 30, "gear": 10, "copper_plate": 10}, {"steel": 20, "gear": 15, "wire": 20}, {"steel": 40, "gear": 30, "construction_kit": 8}]},
	"reach": {"name": "Utility harness", "description": "Reach farther to build, mine, and interact with machines and civic hatches.", "stat": "interaction_reach", "values": [7.0, 8.0], "costs": [{"iron_plate": 15, "gear": 5, "copper_plate": 5}, {"iron_plate": 30, "gear": 10, "wire": 20}]},
	"pack": {"name": "Expedition pack", "description": "Carry more individual items. Each inventory tile still groups one item type.", "stat": "inventory_capacity", "values": [12500, 15000], "costs": [{"iron_plate": 20, "gear": 5}, {"iron_plate": 40, "gear": 10, "copper_plate": 15}]},
}

static func gate(world: RefCounted, rank: int, id: String = "") -> String:
	if world.guide.enabled and "drill_online" not in world.guide.completed: return "Finish the first working-drill lesson."
	if rank >= 2 and "logistics" not in world.researched: return "Research Supply routes."
	if rank >= 3:
		if "metallurgy" not in world.researched: return "Research Foundry craft."
		if not world.settlements.enabled or not world.settlements.sites.workshop.repaired: return "Restore the engineers' workshop."
	if id == "armor":
		if "logistics" not in world.researched: return "Research Supply routes."
		if not world.settlements.enabled or not world.settlements.sites.workshop.repaired: return "Restore the engineers' workshop."
		if rank >= 2 and "metallurgy" not in world.researched: return "Research Foundry craft."
	if id in ["repair", "scanner"]:
		if not world.settlements.enabled or not world.settlements.sites.town_hall.repaired: return "Rebuild Oldbridge Town Hall."
		if id == "repair" and rank >= 2 and world.settlements.district_level() < 1: return "Restore the first neighborhood."
		if id == "repair" and rank >= 3 and world.defense.cleared < 3: return "Rescue 3 beacon arrivals."
		if id == "scanner" and rank >= 2 and world.settlements.district_level() < 2: return "Restore two neighborhoods."
	if rank >= 4:
		if world.settlements.district_level() < 3: return "Restore all three neighborhoods."
		if world.defense.cleared < 5: return "Rescue 5 beacon arrivals."
	return ""

static func format_stat(stat: String, value) -> String:
	match stat:
		"damage_reduction": return "%d%% less personal damage" % int(value)
		"movement_speed": return "%.1f tiles/sec" % float(value)
		"mining_ticks": return "%.2f items/sec (%.1fs/item)" % [10.0 / float(value), float(value) / 10.0]
		"interaction_reach": return "%.0f tiles" % float(value)
		"inventory_capacity": return "%d items" % int(value)
		"repair_power": return "%d health / repair kit" % int(value)
		"survey_bonus": return "+%d survey regions" % int(value)
	return str(value)
