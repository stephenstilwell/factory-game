extends RefCounted
## Own only purchased ranks. Effective stats are derived, never trusted from a save.
const Definitions = preload("res://scripts/data/character_catalog.gd")
var levels: Dictionary = {}

func level(id: String) -> int:
	return int(levels.get(id, 0))

func stat(id: String):
	var value = Definitions.BASE_STATS.get(id, 0)
	for upgrade in Definitions.UPGRADES:
		var definition: Dictionary = Definitions.UPGRADES[upgrade]
		if definition.stat == id and level(upgrade) > 0: value = definition.values[level(upgrade) - 1]
	return value

func error(world: RefCounted, id: String, expected_rank: int) -> String:
	if not Definitions.UPGRADES.has(id): return "Unknown engineer upgrade."
	var definition: Dictionary = Definitions.UPGRADES[id]
	if level(id) >= definition.values.size(): return "This upgrade is complete."
	if expected_rank != level(id) + 1: return "Upgrade selection changed. Review the next tier."
	var locked := Definitions.gate(world, expected_rank, id)
	if not locked.is_empty(): return locked
	if not world.player.has_all(definition.costs[level(id)]): return "Missing upgrade materials."
	return ""

func purchase(world: RefCounted, id: String, expected_rank: int) -> bool:
	var reason := error(world, id, expected_rank)
	if not reason.is_empty():
		world.message.emit(reason)
		return false
	var definition: Dictionary = Definitions.UPGRADES[id]
	if not world.player.exchange(definition.costs[level(id)], {}): return false
	levels[id] = expected_rank
	world.player.capacity = int(stat("inventory_capacity"))
	world.message.emit("Engineer upgrade installed: %s %d." % [definition.name, expected_rank])
	world.changed.emit()
	return true

func restore(data) -> bool:
	if not data is Dictionary or data.get("version") != 1 or not data.get("levels") is Dictionary: return false
	var restored: Dictionary = {}
	for id in data.levels:
		if not Definitions.UPGRADES.has(id): return false
		var rank = data.levels[id]
		if not (rank is int or rank is float) or not is_finite(float(rank)) or float(rank) != floor(float(rank)) or rank < 1 or rank > Definitions.UPGRADES[id].values.size(): return false
		restored[id] = int(rank)
	levels = restored
	return true

func valid_progress(world: RefCounted) -> bool:
	for id in levels:
		if not Definitions.gate(world, level(id), id).is_empty(): return false
	return true

func serialize() -> Dictionary:
	return {"version": 1, "levels": levels.duplicate()}
