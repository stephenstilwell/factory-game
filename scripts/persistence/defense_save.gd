extends RefCounted
const Defense = preload("res://scripts/simulation/defense.gd")

static func integer(value, minimum: int, maximum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value)) and value >= minimum and value <= maximum

static func restore(world: RefCounted, data) -> bool:
	if not data is Dictionary or data.get("version") != 1 or data.get("phase") not in ["idle", "warning", "active", "recovery"]: return false
	if not integer(data.get("cleared"), 0, Defense.MAX_WAVES) or not integer(data.get("warning"), 0, Defense.WARNING_TICKS) or not integer(data.get("pending"), 0, 22) or not integer(data.get("spawn_timer"), 0, 14) or not integer(data.get("next_id"), 1, 10000): return false
	if not data.get("enemies") is Array or data.enemies.size() > 22: return false
	var state := Defense.new()
	state.phase = data.phase
	state.cleared = int(data.cleared)
	state.warning = int(data.warning)
	state.pending = int(data.pending)
	state.spawn_timer = int(data.spawn_timer)
	state.next_id = int(data.next_id)
	var hall = world.settlements.sites.town_hall
	if state.phase != "idle" or state.cleared > 0:
		if not world.settlements.enabled or not hall.repaired or "logistics" not in world.researched: return false
	if state.cleared == Defense.MAX_WAVES and state.phase != "idle": return false
	if state.phase == "warning":
		if state.warning == 0 or state.pending != 0 or not data.enemies.is_empty() or state.spawn_timer != 0 or hall.health != hall.max_health(): return false
	elif state.warning != 0: return false
	if state.phase != "active" and (state.pending != 0 or not data.enemies.is_empty() or state.spawn_timer != 0): return false
	if state.phase == "active" and (hall.health == 0 or state.pending + data.enemies.size() == 0 or state.pending + data.enemies.size() > state.wave_size()): return false
	if state.phase == "recovery" and hall.health == hall.max_health(): return false
	if hall.repaired and hall.health == 0 and state.phase != "recovery": return false
	var occupied: Dictionary = {}
	var records: Array = data.enemies.duplicate()
	records.sort_custom(func(a, b): return int(a.get("id", 0)) < int(b.get("id", 0)) if a is Dictionary and b is Dictionary else false)
	for record in records:
		if not record is Dictionary or not integer(record.get("id"), 1, state.next_id - 1) or not integer(record.get("x"), hall.origin.x + 3, hall.origin.x + 22) or not integer(record.get("y"), hall.origin.y + 1, hall.origin.y + 1) or not integer(record.get("health"), 1, state.enemy_health()) or not integer(record.get("cooldown"), 0, 9): return false
		var cell := Vector2i(int(record.x), int(record.y))
		if state.enemies.has(int(record.id)) or occupied.has(cell): return false
		occupied[cell] = true
		state.enemies[int(record.id)] = {"id": int(record.id), "cell": cell, "health": int(record.health), "cooldown": int(record.cooldown)}
	world.defense = state
	return true
