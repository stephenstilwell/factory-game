extends RefCounted
const LEVEL_CAP := 99
const MILESTONES := [5, 10, 15, 20, 25, 35, 50, 65, 75, 85, 90, 95, 99]
const WORK_BONUSES := [2, 5, 7, 9, 10, 12, 15, 18, 20, 22, 23, 24, 25]
const EXPLORATION_MILESTONES := [5, 10, 15, 25, 35, 50, 65, 75, 85, 99]
const MOVE_BONUSES := [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
const COMMISSIONS := [10, 50, 250, 1000, 5000]
const COMMISSION_XP := [150, 400, 1000, 2500, 6000]
const DELIVERY_MILESTONES := [1, 5, 10, 25, 50, 100, 250, 500]
const DELIVERY_XP := [150, 150, 150, 300, 600, 1200, 2500, 5000]
const SKILLS := {
	"mining": {"name": "Gathering", "description": "Earn XP from finite timber, berries, tree felling, hand mining and commissioning your first drill for each resource. Milestones gradually grant up to +25% hand-mining work speed. Productive drill commissions also earn XP."},
	"fabrication": {"name": "Fabrication", "description": "Earn XP from completed hand crafts, commissioning each automated recipe, and reliable settlement deliveries. Milestones gradually grant up to +25% hand-crafting work speed. Useful automated batches and deliveries earn graduated commissions."},
	"exploration": {"name": "Exploration", "description": "Earn 20 XP per new 16x16 area and 40 XP per resource patch encountered nearby. Milestones gradually grant up to +10% movement speed; levels 25 and 75 expand surveys."},
}
const MINING_XP := {"stone": 10, "coal": 10, "iron_ore": 12, "copper_ore": 12}
const CRAFT_XP := {"generator": 90, "power_pole": 12, "stone_axe": 8, "plank": 3, "lumber_camp": 25, "cart_post": 20, "communal_hearth": 30, "watermill": 40, "charcoal_kiln": 25, "fuel_depot": 60, "service_rifle": 65, "cannon_turret": 90, "pulse_turret": 85, "splitter": 32, "underground_belt": 40, "wall": 10, "turret": 75, "ammo": 10, "repair_kit": 16, "gear": 12, "wire": 6, "science": 30, "belt": 8, "drill": 60, "furnace": 20, "inserter": 20, "chest": 16, "assembler": 80, "lab": 100, "fast_belt": 24}

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

static func milestones(id: String) -> Array:
	return EXPLORATION_MILESTONES if id == "exploration" else MILESTONES

static func milestone_count(level: int, id: String = "") -> int:
	var count := 0
	for milestone in milestones(id):
		if level >= milestone: count += 1
	return count
