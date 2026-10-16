extends RefCounted
## XP and discovery ledgers are authoritative; levels and bonuses are derived.
const Definitions = preload("res://scripts/data/skill_catalog.gd")
var xp: Dictionary = {}
var visited: Dictionary = {}
var patches: Dictionary = {}
var commissions: Dictionary = {}
const Catalog = preload("res://scripts/data/catalog.gd")
var last_cell := Vector2i(2000000, 2000000)

func _init() -> void:
	for id in Definitions.SKILLS: xp[id] = 0

func level(id: String) -> int:
	return Definitions.level_for(int(xp.get(id, 0)))

func multiplier(id: String) -> float:
	return 1.0 + bonus_percent(id) / 100.0

func work_units(id: String) -> int:
	return 100 + bonus_percent(id)

func bonus_percent(id: String, at_level: int = -1) -> int:
	var count := Definitions.milestone_count(level(id) if at_level < 0 else at_level, id)
	return 0 if count == 0 else int((Definitions.MOVE_BONUSES if id == "exploration" else Definitions.WORK_BONUSES)[count - 1])

func commission(world: RefCounted, key: String, skill: String) -> void:
	var count: int = int(commissions.get(key, 0)) + 1
	commissions[key] = mini(2000000000, count)
	var index: int = Definitions.COMMISSIONS.find(count)
	if index < 0: return
	var reward: int = Definitions.COMMISSION_XP[index]
	world.award_skill(skill, reward)
	var item: String = key.get_slice(":", 1)
	world.message.emit("Working supply line: %s • %d automated batches • +%d %s XP [P]" % [Catalog.item_name(item), count, reward, Definitions.SKILLS[skill].name])

func survey_radius() -> int:
	return 3 + (1 if level("exploration") >= 25 else 0) + (1 if level("exploration") >= 75 else 0)

func gain(id: String, amount: int) -> Dictionary:
	if not xp.has(id) or amount <= 0: return {}
	var before := int(xp[id])
	var previous := level(id)
	xp[id] = mini(Definitions.threshold(99), before + amount)
	if xp[id] == before: return {}
	return {"amount": int(xp[id]) - before, "previous": previous, "level": level(id)}

func observe(world: RefCounted) -> void:
	if world.player_position == world.previous_position: return
	var cell := Vector2i(world.player_position.floor())
	if cell == last_cell: return
	last_cell = cell
	var chunk: Vector2i = world.terrain.chunk_at(cell)
	if not visited.has(chunk) and visited.size() < 100000:
		visited[chunk] = true
		world.award_skill("exploration", 20)
	# Actual proximity discovers patches; camera rendering and surveys do not.
	for x in range(-2, 3):
		for y in range(-2, 3):
			var nearby := cell + Vector2i(x, y)
			if world.terrain.tile(nearby).is_empty(): continue
			var patch: Dictionary = world.terrain.patch_at(nearby)
			if patch.is_empty() or patches.has(patch.center) or patches.size() >= 100000: continue
			patches[patch.center] = patch.item
			world.award_skill("exploration", 40)

func serialize() -> Dictionary:
	var areas: Array = []
	for coordinate in visited: areas.append([coordinate.x, coordinate.y])
	var discoveries: Array = []
	for center in patches: discoveries.append([center.x, center.y, patches[center]])
	return {"version": 1, "xp": xp.duplicate(), "visited": areas, "patches": discoveries, "commissions": commissions.duplicate()}

func _integer(value, minimum: int, maximum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value)) and value >= minimum and value <= maximum

func restore(data, terrain: RefCounted) -> bool:
	if not data is Dictionary or data.get("version") != 1 or not data.get("xp") is Dictionary or data.xp.size() > Definitions.SKILLS.size(): return false
	var restored_xp: Dictionary = {}
	for id in Definitions.SKILLS: restored_xp[id] = 0
	for id in data.xp:
		if not Definitions.SKILLS.has(id) or not _integer(data.xp[id], 0, Definitions.threshold(99)): return false
		restored_xp[id] = int(data.xp[id])
	if not data.get("visited") is Array or data.visited.size() > 100000 or not data.get("patches") is Array or data.patches.size() > 100000: return false
	var restored_areas: Dictionary = {}
	for entry in data.visited:
		if not entry is Array or entry.size() != 2 or not _integer(entry[0], -62500, 62500) or not _integer(entry[1], -62500, 62500): return false
		var coordinate := Vector2i(int(entry[0]), int(entry[1]))
		if restored_areas.has(coordinate): return false
		restored_areas[coordinate] = true
	var restored_patches: Dictionary = {}
	for entry in data.patches:
		if not entry is Array or entry.size() != 3 or not _integer(entry[0], -1000000, 1000000) or not _integer(entry[1], -1000000, 1000000) or entry[2] not in terrain.RESOURCE_IDS: return false
		var center := Vector2i(int(entry[0]), int(entry[1]))
		if restored_patches.has(center) or not terrain.has_patch(center, entry[2]): return false
		restored_patches[center] = entry[2]
	var saved_commissions = data.get("commissions", {})
	if not saved_commissions is Dictionary or saved_commissions.size() > Catalog.RECIPES.size() + terrain.RESOURCE_IDS.size(): return false
	var restored_commissions := {}
	for key in saved_commissions:
		if not key is String or not _integer(saved_commissions[key], 1, 2000000000): return false
		var parts: PackedStringArray = key.split(":")
		if parts.size() != 2 or not ((parts[0] == "mine" and parts[1] in terrain.RESOURCE_IDS) or (parts[0] == "line" and Catalog.RECIPES.has(parts[1]))): return false
		restored_commissions[key] = int(saved_commissions[key])
	commissions = restored_commissions
	xp = restored_xp
	visited = restored_areas
	patches = restored_patches
	last_cell = Vector2i(2000000, 2000000)
	return true
