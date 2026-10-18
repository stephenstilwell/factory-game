extends RefCounted
const Defense = preload("res://scripts/simulation/defense.gd")

static func integer(value, minimum: int, maximum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value)) and value >= minimum and value <= maximum

static func restore(world: RefCounted, data) -> bool:
	if not data is Dictionary or data.get("version") != 2 or data.get("phase") not in ["idle", "warning", "active", "recovery"]: return false
	if not integer(data.get("cleared"), 0, Defense.MAX_WAVES) or not integer(data.get("warning"), 0, Defense.WARNING_TICKS) or not integer(data.get("pending"), 0, 22) or not integer(data.get("spawn_timer"), 0, Defense.Definitions.MAX_SPAWN_DELAY) or not integer(data.get("next_id"), 1, 2000000000): return false
	if not data.get("enemies") is Array or data.enemies.size() > 22: return false
	var state := Defense.new()
	state.phase = data.phase
	state.cleared = int(data.cleared)
	state.warning = int(data.warning)
	state.pending = int(data.pending)
	state.spawn_timer = int(data.spawn_timer)
	state.next_id = int(data.next_id)
	if not data.get("costs") is Dictionary or data.costs.size() != 3: return false
	for key in ["ammo","kits","damage"]:
		if not integer(data.costs.get(key),0,2000000000): return false
	state.costs = {"ammo":int(data.costs.ammo),"kits":int(data.costs.kits),"damage":int(data.costs.damage)}
	if not data.get("last_result") is Dictionary: return false
	if not data.last_result.is_empty():
		var report: Dictionary = data.last_result
		if report.size() != 5 or not report.get("victory") is bool or not integer(report.get("wave"),1,Defense.MAX_WAVES): return false
		for key in ["ammo","kits","damage"]:
			if not integer(report.get(key),0,2000000000): return false
		if report.victory and report.wave != state.cleared: return false
		if not report.victory and report.wave != state.cleared+1: return false
		state.last_result = {"wave":int(report.wave),"victory":report.victory,"ammo":int(report.ammo),"kits":int(report.kits),"damage":int(report.damage)}
	var hall = world.settlements.sites.town_hall
	if state.phase != "idle" or state.cleared > 0:
		if not world.settlements.enabled or not hall.repaired or "logistics" not in world.researched: return false
	if state.cleared == Defense.MAX_WAVES and state.phase != "idle": return false
	if state.phase == "warning":
		if state.warning == 0 or state.pending != 0 or not data.enemies.is_empty() or state.spawn_timer != 0 or hall.health != hall.max_health(): return false
	elif state.warning != 0: return false
	if state.phase != "active" and (state.pending != 0 or not data.enemies.is_empty() or state.spawn_timer != 0): return false
	if state.phase == "active" and (hall.health == 0 or state.pending + data.enemies.size() == 0 or state.pending + data.enemies.size() > state.wave_size()): return false
	if state.phase == "active":
		if state.pending == 0 and state.spawn_timer != 0: return false
		if state.pending > 0 and state.spawn_timer > Defense.Definitions.spawn_delay(state.cleared+1,state.wave_size()-state.pending): return false
	if state.phase == "recovery" and hall.health == hall.max_health(): return false
	if hall.repaired and hall.health == 0 and state.phase != "recovery": return false
	var occupied: Dictionary = {}
	var records: Array = data.enemies.duplicate()
	records.sort_custom(func(a, b): return int(a.get("id", 0)) < int(b.get("id", 0)) if a is Dictionary and b is Dictionary else false)
	for record in records:
		if not record is Dictionary: return false
		for key in ["id", "kind", "x", "y", "health", "cooldown", "slow", "attack_ticks", "attack_x", "attack_y", "attack_player"]:
			if not record.has(key): return false
		var kind = record.kind
		if not kind is String or not Defense.Definitions.ENEMIES.has(kind): return false
		if not integer(record.get("id"), 1, state.next_id - 1) or not integer(record.get("x"), hall.origin.x - 5, hall.origin.x + 23) or not integer(record.get("y"), hall.origin.y - 6, hall.origin.y + 8) or not integer(record.get("health"), 1, state.enemy_health(kind)) or not integer(record.get("cooldown"), 0, 11): return false
		if not integer(record.slow, 0, 25) or not integer(record.attack_ticks, 0, 4) or not record.attack_player is bool: return false
		if not integer(record.attack_x, -1000000, 1000000) or not integer(record.attack_y, -1000000, 1000000): return false
		var cell := Vector2i(int(record.x), int(record.y))
		var attack_cell := Vector2i(int(record.attack_x), int(record.attack_y))
		if int(record.attack_ticks) > 0:
			var distance := Vector2(attack_cell - cell).length()
			if distance > (2.5 if record.attack_player else 1.0): return false
		if state.enemies.has(int(record.id)) or occupied.has(cell): return false
		occupied[cell] = true
		state.enemies[int(record.id)] = {"id": int(record.id), "kind": kind, "cell": cell, "health": int(record.health), "cooldown": int(record.cooldown), "slow": int(record.slow), "attack_ticks": int(record.attack_ticks), "attack_cell": attack_cell, "attack_player": bool(record.attack_player), "hit_until": 0}
	world.defense = state
	return true
