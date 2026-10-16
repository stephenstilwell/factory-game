extends RefCounted
## One deterministic eastern approach. No scene nodes or automatic wave starts.
const MAX_WAVES := 10
const WARNING_TICKS := 150
const RANGE := 6.0
const SHOT_DAMAGE := 12
var phase := "idle"
var cleared := 0
var warning := 0
var pending := 0
var spawn_timer := 0
var next_id := 1
var enemies: Dictionary = {}
var shots: Array = [] # Presentation only; never saved.

func hub(world: RefCounted):
	return world.settlements.sites.town_hall

func lane(world: RefCounted) -> int:
	return hub(world).origin.y + 1

func spawn_cell(world: RefCounted) -> Vector2i:
	return hub(world).origin + Vector2i(22, 1)

func wave_size() -> int:
	return 4 + cleared * 2

func enemy_health() -> int:
	return 24 + cleared * 4

func ready_reason(world: RefCounted) -> String:
	if not world.settlements.enabled or not hub(world).repaired: return "Restore the Town Hall first."
	if phase != "idle": return "Finish this defense or repair the hall first."
	if cleared >= MAX_WAVES: return "Eastern route secured — all ten defenses complete."
	if hub(world).health != hub(world).max_health(): return "Fully repair the Town Hall before signaling."
	if "logistics" not in world.researched: return "Research Logistics I to unlock gun turrets and ammunition."
	return ""

func begin(world: RefCounted) -> bool:
	var reason := ready_reason(world)
	if not reason.is_empty():
		world.message.emit(reason)
		return false
	if not world.in_reach(hub(world).port()):
		world.message.emit("Walk to the Town Hall hatch to light its beacon.")
		return false
	phase = "warning"
	warning = WARNING_TICKS
	world.feedback_requested.emit("warning", Vector2i(world.player_position.floor()))
	world.message.emit("Beacon lit! %d salvage scavengers approach from the EAST in 15 seconds. Load your turrets!" % wave_size())
	world.changed.emit()
	return true

func cancel(world: RefCounted) -> bool:
	if phase != "warning": return false
	phase = "idle"
	warning = 0
	world.message.emit("Beacon extinguished. No wave will arrive until you signal again.")
	world.changed.emit()
	return true

func occupied(cell: Vector2i) -> bool:
	for enemy in enemies.values():
		if enemy.cell == cell: return true
	return false

func step(world: RefCounted) -> void:
	shots = shots.filter(func(shot): return int(shot.until) > world.ticks)
	if phase == "recovery":
		if hub(world).health == hub(world).max_health(): phase = "idle"
		return
	if phase == "warning":
		warning -= 1
		if warning > 0: return
		phase = "active"
		pending = wave_size()
		spawn_timer = 0
		world.message.emit("Scavengers on the eastern approach! Defend the Town Hall.")
	if phase != "active": return
	if pending > 0:
		if spawn_timer > 0: spawn_timer -= 1
		elif not occupied(spawn_cell(world)):
			enemies[next_id] = {"id": next_id, "cell": spawn_cell(world), "health": enemy_health(), "cooldown": 0}
			next_id += 1
			pending -= 1
			spawn_timer = 14
	_fire_turrets(world)
	for id in enemies.keys():
		var enemy: Dictionary = enemies[id]
		if int(enemy.cooldown) > 0:
			enemy.cooldown -= 1
			continue
		var next: Vector2i = enemy.cell + Vector2i.LEFT
		var site = world.settlements.at(next)
		var building = world.at(next)
		if site != null and site.repaired and site.health > 0:
			world.damage_structure(next, 8)
			enemy.cooldown = 9
		elif building != null and building.health > 0 and world.Catalog.BUILDINGS[building.kind].solid:
			world.damage_structure(next, 8)
			enemy.cooldown = 9
		elif not occupied(next):
			enemy.cell = next
			enemy.cooldown = 4
		if hub(world).health == 0:
			phase = "recovery"
			enemies.clear()
			pending = 0
			spawn_timer = 0
			world.message.emit("Town Hall breached. The beacon is dark and town services are suspended. Repair the hall with kits [H]; your goods, research, and skills are preserved.")
			world.changed.emit()
			return
	if pending == 0 and enemies.is_empty():
		cleared += 1
		world.feedback_requested.emit("success", Vector2i(world.player_position.floor()))
		phase = "idle"
		spawn_timer = 0
		world.message.emit("Defense %d complete! %d families sheltered. Road crews grant +5%% movement while the Town Hall is operational. The next wave waits for your signal." % [cleared, cleared * 3])
		world.changed.emit()

func _fire_turrets(world: RefCounted) -> void:
	for id in world.by_kind.turret:
		var turret = world.entities[id]
		if turret.health <= 0:
			turret.status = "Disabled — repair with H"
			continue
		if turret.attack_cooldown > 0:
			turret.attack_cooldown -= 1
			continue
		turret.status = "No ammunition" if turret.inventory.count("ammo") == 0 else "Watching eastern approach"
		if turret.inventory.count("ammo") == 0: continue
		var target := -1
		for enemy_id in enemies:
			if Vector2(turret.cell).distance_to(Vector2(enemies[enemy_id].cell)) > RANGE: continue
			if target == -1 or enemies[enemy_id].cell.x < enemies[target].cell.x: target = enemy_id
		if target == -1: continue
		turret.inventory.remove("ammo")
		world.feedback_requested.emit("shot", turret.cell)
		turret.attack_cooldown = 4
		turret.status = "Firing"
		shots.append({"from": turret.cell, "to": enemies[target].cell, "until": world.ticks + 2})
		enemies[target].health -= SHOT_DAMAGE
		if int(enemies[target].health) <= 0: enemies.erase(target)

func morale_multiplier(world: RefCounted) -> float:
	return 1.05 if cleared > 0 and world.settlements.enabled and hub(world).repaired and hub(world).health > 0 else 1.0

func summary() -> String:
	match phase:
		"warning": return "EAST WAVE %d • %.1fs to arrival" % [cleared + 1, warning / 10.0]
		"active": return "DEFEND THE HALL • %d scavengers remaining" % (enemies.size() + pending)
		"recovery": return "HALL BREACHED • Repair with kits [H]"
	return "Eastern route secured — all ten defenses complete" if cleared == MAX_WAVES else "Beacon idle • %d/10 defenses complete • Awaiting your signal" % cleared

func serialize() -> Dictionary:
	var records: Array = []
	for enemy in enemies.values(): records.append({"id": enemy.id, "x": enemy.cell.x, "y": enemy.cell.y, "health": enemy.health, "cooldown": enemy.cooldown})
	return {"version": 1, "phase": phase, "cleared": cleared, "warning": warning, "pending": pending, "spawn_timer": spawn_timer, "next_id": next_id, "enemies": records}
