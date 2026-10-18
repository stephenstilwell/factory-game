extends RefCounted
## Voluntary waves, typed constructs, weighted approaches, and physical ammunition.
const Definitions = preload("res://scripts/data/combat_catalog.gd")
const Navigation = preload("res://scripts/simulation/combat_navigation.gd")
const MAX_WAVES := 10
const WARNING_TICKS := 150
const RANGE := 6.0
const SHOT_DAMAGE := 12
var blocked_entry := false # Transient presentation; recomputed on spawn attempts.
var costs := {"ammo":0,"kits":0,"damage":0}
var last_result: Dictionary = {}
var phase := "idle"
var cleared := 0
var warning := 0
var pending := 0
var spawn_timer := 0
var next_id := 1
var enemies: Dictionary = {}
var shots: Array = [] # Presentation only.
var impacts: Array = []
var misses: Array = []
var navigation := Navigation.new()

func hub(world: RefCounted):
	return world.settlements.sites.town_hall

func lane(world: RefCounted) -> int:
	return hub(world).origin.y + 1

func spawn_cell(world: RefCounted) -> Vector2i:
	return hub(world).origin + Vector2i(22, 1)

func entries(world: RefCounted) -> Array:
	var center := spawn_cell(world)
	return [center] if cleared == 0 else [center, center + Vector2i(0, -4), center + Vector2i(0, 4)]

func wave_size() -> int:
	return 4 + cleared * 2

func enemy_health(kind: String = "scout") -> int:
	return Definitions.maximum(kind, cleared)

func enemy_at(cell: Vector2i) -> int:
	for id in enemies:
		if enemies[id].cell == cell: return id
	return -1

func occupied(cell: Vector2i) -> bool:
	return enemy_at(cell) != -1

func spawn_enemy(kind: String, cell: Vector2i) -> Dictionary:
	var enemy := {"id": next_id, "kind": kind, "cell": cell, "health": enemy_health(kind), "cooldown": 0, "slow": 0, "attack_ticks": 0, "attack_cell": cell, "attack_player": false, "hit_until": 0}
	enemies[next_id] = enemy
	next_id += 1
	return enemy

func reward_preview(world: RefCounted) -> String:
	if cleared >= MAX_WAVES: return "Eastern route secure. All ten arrivals rescued."
	var coverage: int = 8 + mini(4, (cleared + 1) / 2) + world.frontier.hearth_bonus(world)
	return ("FIRST RESCUE: Nell, the quartermaster. Unlock workshop rearming from your stocked ammunition; between defenses only.\n" if cleared == 0 else "") + "ON VICTORY: +%d relief credits and 3 families home.\nCrew services: +5%% movement; hearth coverage %d tiles. Every second arrival extends coverage up to 12, plus restored depot runners. Services require an operational Town Hall.\nSpend credits on civic restoration or supply bundles at the trading post [Y]. Failure pays nothing; repair and retry." % [world.settlements.defense_reward(cleared + 1), coverage]

func ready_reason(world: RefCounted) -> String:
	if not world.settlements.enabled or not hub(world).repaired: return "Restore the Town Hall first."
	if phase != "idle": return "Finish this defense or repair the hall first."
	if cleared >= MAX_WAVES: return "Eastern route secured — all ten defenses complete."
	if hub(world).health != hub(world).max_health(): return "Fully repair the Town Hall before signaling."
	if "logistics" not in world.researched: return "Research Supply routes to unlock defense equipment."
	return ""

func begin(world: RefCounted) -> bool:
	var reason := ready_reason(world)
	if not reason.is_empty():
		world.message.emit(reason)
		return false
	if not world.in_reach(hub(world).port()):
		world.message.emit("Walk to the Town Hall hatch to light its beacon.")
		return false
	costs = {"ammo":0,"kits":0,"damage":0}
	blocked_entry = false
	phase = "warning"
	warning = WARNING_TICKS
	world.feedback_requested.emit("warning", Vector2i(world.player_position.floor()))
	world.message.emit("Encounter: " + Definitions.encounter(cleared+1).name + ". " + Definitions.encounter(cleared+1).lesson)
	world.message.emit("Beacon lit! In 15 seconds: %s. %s" % [Definitions.composition(cleared), "Central eastern gate." if cleared == 0 else "Three eastern gates — cover the flanks."])
	world.changed.emit()
	return true

func cancel(world: RefCounted) -> bool:
	if phase != "warning": return false
	phase = "idle"
	warning = 0
	world.message.emit("Beacon extinguished. No constructs will arrive until you signal again.")
	world.changed.emit()
	return true

func step(world: RefCounted) -> void:
	shots = shots.filter(func(shot): return int(shot.until) > world.ticks)
	impacts = impacts.filter(func(impact): return int(impact.until) > world.ticks)
	misses = misses.filter(func(miss): return int(miss.until) > world.ticks)
	if phase == "recovery":
		if hub(world).health == hub(world).max_health(): phase = "idle"
		return
	if phase == "warning":
		warning -= 1
		if warning > 0: return
		phase = "active"
		pending = wave_size()
		spawn_timer = 0
		world.message.emit("Old-network constructs approaching! Defend the Town Hall. [V] Rifle • Hold left mouse to fire.")
	if phase != "active": return
	if pending > 0:
		if spawn_timer > 0: spawn_timer -= 1
		if spawn_timer == 0:
			var index := wave_size() - pending
			var gates: Array = entries(world)
			var cell: Vector2i = gates[Definitions.gate_index(cleared+1,index)]
			if world.solid(cell): cell += Vector2i.RIGHT
			blocked_entry = occupied(cell) or world.solid(cell)
			if not blocked_entry:
				spawn_enemy(Definitions.kind_at(cleared + 1, index), cell)
				pending -= 1
				spawn_timer = Definitions.spawn_delay(cleared+1,index+1) if pending > 0 else 0
	_fire_turrets(world)
	for id in enemies.keys():
		_advance_enemy(world, enemies[id])
		if hub(world).health == 0:
			finish_report(false)
			phase = "recovery"
			enemies.clear()
			pending = 0
			spawn_timer = 0
			world.combat.firing = false
			world.message.emit("Town Hall breached. Repair it with kits [H] to restore services. Your factory, equipment, and earlier victories are safe.")
			world.changed.emit()
			return
	if pending == 0 and enemies.is_empty():
		finish_report(true)
		cleared += 1
		var reward: int = world.settlements.award_defense(cleared)
		world.feedback_requested.emit("success", Vector2i(world.player_position.floor()))
		phase = "idle"
		world.defense_won.emit(cleared)
		spawn_timer = 0
		world.message.emit("Arrival %d secured! +%d relief credits; %d families sheltered. Returning crews: +5%% movement and %d-tile hearth coverage while Town Hall operates. Choose the next arrival when ready." % [cleared, reward, cleared * 3, world.supply_radius()])
		world.changed.emit()
		if cleared == 1: world.request_story("first_homecoming")

func _advance_enemy(world: RefCounted, enemy: Dictionary) -> void:
	var stats: Dictionary = Definitions.ENEMIES[enemy.kind]
	if enemy.slow > 0: enemy.slow -= 1
	if enemy.attack_ticks > 0:
		enemy.attack_ticks -= 1
		if enemy.attack_ticks == 0:
			if enemy.attack_player:
				if (Vector2(enemy.cell) + Vector2.ONE * 0.5).distance_to(world.player_position) <= 1.6 and Rect2(Vector2(enemy.attack_cell), Vector2.ONE).grow(0.08).has_point(world.player_position):
					world.combat.damage(world, int(stats.damage))
			else:
				world.damage_structure(enemy.attack_cell, int(stats.damage))
			enemy.cooldown = 5
		return
	if enemy.cooldown > 0:
		enemy.cooldown -= 1
		return
	if world.combat.invulnerable == 0 and (Vector2(enemy.cell) + Vector2.ONE * 0.5).distance_to(world.player_position) <= 1.5:
		enemy.attack_ticks = 4
		enemy.attack_player = true
		enemy.attack_cell = Vector2i(world.player_position.floor())
		return
	var next: Vector2i = navigation.next_cell(world, enemy)
	if next == enemy.cell: return
	if world.solid(next):
		enemy.attack_ticks = 4
		enemy.attack_player = false
		enemy.attack_cell = next
	elif not occupied(next):
		enemy.cell = next
		enemy.cooldown = int(stats.move) + (4 if enemy.slow > 0 else 0)

func add_shot(world: RefCounted, from: Vector2, to: Vector2, kind: String) -> void:
	if shots.size() >= 64: shots.pop_front()
	shots.append({"from": from - Vector2.ONE * 0.5, "to": to - Vector2.ONE * 0.5, "kind": kind, "until": world.ticks + 2})

func add_miss(world: RefCounted, point: Vector2) -> void:
	if misses.size() >= 32: misses.pop_front()
	misses.append({"point": point, "until": world.ticks + 4})
	world.feedback_requested.emit("miss", Vector2i(point.floor()))

func hit(world: RefCounted, id: int, amount: int, piercing: bool) -> void:
	if not enemies.has(id): return
	var enemy: Dictionary = enemies[id]
	var base_armor: int = int(Definitions.ENEMIES[enemy.kind].armor)
	var armor: int = 0 if piercing else base_armor
	var dealt: int = maxi(1, amount - armor)
	var absorbed: int = (amount - dealt) if not piercing else 0
	enemy.last_damage = dealt
	enemy.last_absorbed = absorbed
	enemy.hit_kind = "pierce" if (piercing and base_armor > 0) else ("resisted" if absorbed > 0 else "hit")
	enemy.health -= dealt
	enemy.hit_until = world.ticks + 3
	if enemy.hit_kind == "resisted":
		world.feedback_requested.emit("armor_clink", enemy.cell)
	elif enemy.hit_kind == "pierce":
		world.feedback_requested.emit("pierce", enemy.cell)
	else:
		world.feedback_requested.emit("hit", enemy.cell)
	if enemy.health <= 0:
		if impacts.size() >= 32: impacts.pop_front()
		impacts.append({"cell": enemy.cell, "until": world.ticks + 4, "color": Definitions.ENEMIES[enemy.kind].color})
		enemies.erase(id)

func _fire_turrets(world: RefCounted) -> void:
	for kind in Definitions.TURRETS:
		var weapon: Dictionary = Definitions.TURRETS[kind]
		for id in world.by_kind[kind]:
			var turret = world.entities[id]
			if turret.health <= 0:
				turret.status = "Disabled — repair with H"
				continue
			if turret.attack_cooldown > 0:
				turret.attack_cooldown -= 1
				continue
			turret.status = "No ammunition" if turret.inventory.count("ammo") < int(weapon.ammo) else "Watching approaches"
			if turret.inventory.count("ammo") < int(weapon.ammo): continue
			var target := -1
			var best := INF
			for enemy_id in enemies:
				if Vector2(turret.cell).distance_to(Vector2(enemies[enemy_id].cell)) > float(weapon.range): continue
				var distance := Vector2(enemies[enemy_id].cell - hub(world).origin).length_squared()
				# Piercing cannon prefers haulers; other weapons stop threats nearest the Hall.
				if kind == "cannon_turret" and enemies[enemy_id].kind == "hauler": distance -= 10000
				if distance < best:
					best = distance
					target = enemy_id
			if target == -1: continue
			var point: Vector2i = enemies[target].cell
			turret.inventory.remove("ammo", int(weapon.ammo))
			costs.ammo += int(weapon.ammo)
			world.metrics.record(world.ticks, "used", "ammo", int(weapon.ammo))
			world.feedback_requested.emit("shot", turret.cell)
			turret.attack_cooldown = int(weapon.cooldown)
			turret.status = "Firing"
			add_shot(world, Vector2(turret.cell) + Vector2.ONE * 0.5, Vector2(point) + Vector2.ONE * 0.5, kind)
			var victims: Array = [target]
			if float(weapon.splash) > 0:
				victims = []
				for enemy_id in enemies:
					if Vector2(enemies[enemy_id].cell - point).length() <= float(weapon.splash): victims.append(enemy_id)
			for enemy_id in victims:
				if kind == "pulse_turret": enemies[enemy_id].slow = 25
				hit(world, enemy_id, int(weapon.damage), bool(weapon.piercing))

func morale_multiplier(world: RefCounted) -> float:
	return 1.05 if cleared > 0 and world.settlements.enabled and hub(world).repaired and hub(world).health > 0 else 1.0

func summary() -> String:
	match phase:
		"warning": return "EAST WAVE %d • %.1fs to arrival" % [cleared + 1, warning / 10.0]
		"active":
			if blocked_entry and pending > 0: return "EAST ENTRY OBSTRUCTED • Clear marked entry tiles; arrivals are waiting"
			var next_index := wave_size()-pending
			if pending > 0 and spawn_timer > 0 and next_index in Definitions.encounter(cleared+1).breaks:
				return "REINFORCEMENTS IN %.1fs • %d constructs remaining" % [spawn_timer/10.0,enemies.size()+pending]
			return "DEFEND THE HALL • %d constructs remaining" % (enemies.size()+pending)
		"recovery": return "HALL BREACHED • Repair with kits [H]"
	return "Eastern route secured — all ten defenses complete" if cleared == MAX_WAVES else "Beacon idle • %d/10 defenses complete • Awaiting your signal" % cleared

func serialize() -> Dictionary:
	var records: Array = []
	for enemy in enemies.values():
		records.append({"id": enemy.id, "kind": enemy.kind, "x": enemy.cell.x, "y": enemy.cell.y, "health": enemy.health, "cooldown": enemy.cooldown, "slow": enemy.slow, "attack_ticks": enemy.attack_ticks, "attack_x": enemy.attack_cell.x, "attack_y": enemy.attack_cell.y, "attack_player": enemy.attack_player})
	return {"version": 2, "phase": phase, "cleared": cleared, "warning": warning, "pending": pending, "spawn_timer": spawn_timer, "next_id": next_id, "costs":costs.duplicate(), "last_result":last_result.duplicate(), "enemies": records}

func finish_report(victory: bool) -> void:
	last_result = {"wave":cleared+1,"victory":victory,"ammo":int(costs.ammo),"kits":int(costs.kits),"damage":int(costs.damage)}

func cost_summary() -> String:
	if last_result.is_empty(): return ""
	return "LAST DEFENSE • Arrival %d • %s • %d rounds fired • %d in-battle repair kits • %d structure health lost" % [last_result.wave,"Victory" if last_result.victory else "Hall breached",last_result.ammo,last_result.kits,last_result.damage]
