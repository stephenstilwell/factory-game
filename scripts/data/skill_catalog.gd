extends RefCounted
const LEVEL_CAP := 99
const MILESTONES := [10, 25, 50, 75, 99]
const SKILLS := {
	"mining": {"name": "Mining", "description": "Earn XP from hand mining and commissioning your first drill for each resource. Each milestone grants +5% hand-mining work speed."},
	"fabrication": {"name": "Fabrication", "description": "Earn XP from completed hand crafts, commissioning each automated recipe, and reliable settlement deliveries. Each milestone grants +5% hand-crafting work speed."},
	"exploration": {"name": "Exploration", "description": "Earn 20 XP per new 16x16 area and 40 XP per resource patch encountered nearby. Milestones grant +2% movement speed; levels 25 and 75 expand surveys."},
}
const MINING_XP := {"stone": 10, "coal": 10, "iron_ore": 12, "copper_ore": 12}
const CRAFT_XP := {"service_rifle": 65, "cannon_turret": 90, "pulse_turret": 85, "splitter": 32, "underground_belt": 40, "wall": 10, "turret": 75, "ammo": 10, "repair_kit": 16, "gear": 12, "wire": 6, "science": 30, "belt": 8, "drill": 60, "furnace": 20, "inserter": 20, "chest": 16, "assembler": 80, "lab": 100, "fast_belt": 24}

static func threshold(level: int) -> int:
	# Cumulative XP, with approachable early levels and a long mastery tail.
	return roundi(50.0 * (pow(1.10, clampi(level, 1, LEVEL_CAP) - 1) - 1.0) / 0.10)

static func level_for(xp: int) -> int:
	var low := 1
	var high := LEVEL_CAP
	while low < high:
		var middle := (low + high + 1) / 2
		if threshold(middle) <= xp: low = middle
		else: high = middle - 1
	return low

static func milestone_count(level: int) -> int:
	var count := 0
	for milestone in MILESTONES:
		if level >= milestone: count += 1
	return count
