extends RefCounted
const Definitions = preload("res://scripts/data/combat_catalog.gd")
var health := 100
var invulnerable := 0
var regen_delay := 0
var cooldown := 0
var armed := false
var firing := false # Transient input intent.
var aim := Vector2.ZERO
var active_weapon := "service_rifle"

func has_weapon(world: RefCounted, id: String) -> bool:
	if not Definitions.WEAPONS.has(id): return false
	var required_tech: String = str(Definitions.WEAPONS[id].technology)
	return world.player.count(id) > 0 and world.content_available(id) and required_tech in world.researched

func carried_weapons(world: RefCounted) -> Array:
	var result: Array = []
	for id in Definitions.WEAPONS:
		if has_weapon(world, id): result.append(id)
	return result

func current_weapon(world: RefCounted = null) -> Dictionary:
	return Definitions.WEAPONS.get(active_weapon, Definitions.WEAPONS.service_rifle)

func toggle(world: RefCounted, specific_weapon: String = "") -> bool:
	if not specific_weapon.is_empty():
		if not has_weapon(world, specific_weapon):
			var req_tech: String = str(Definitions.WEAPONS.get(specific_weapon, {}).get("technology", "logistics"))
			world.message.emit("Craft a %s after restoring the workshop and researching %s. [C]" % [Definitions.WEAPONS.get(specific_weapon, {}).get("name", "rifle"), "Supply routes" if req_tech == "logistics" else "Foundry craft"])
			return false
		if not armed or active_weapon != specific_weapon:
			active_weapon = specific_weapon
			armed = true
			firing = false
			world.changed.emit()
			return true
		armed = false
		firing = false
		world.changed.emit()
		return true
	if not armed:
		var available := carried_weapons(world)
		if available.is_empty():
			world.message.emit("Craft a service rifle after restoring the workshop and researching Supply routes. [C]")
			return false
		if not has_weapon(world, active_weapon): active_weapon = available[0]
		armed = true
		firing = false
		world.changed.emit()
		return true
	var carried := carried_weapons(world)
	if carried.size() > 1:
		var current_index := carried.find(active_weapon)
		var next_index := (current_index + 1) % carried.size()
		if next_index != 0:
			active_weapon = carried[next_index]
			var def: Dictionary = current_weapon(world)
			world.message.emit("Equipped %s: Range %.0f, %d dmg%s, %d ammo. %s" % [def.name, def.range, def.damage, " (armor-piercing)" if def.piercing else "", def.ammo, def.role])
			world.changed.emit()
			return true
	armed = false
	firing = false
	world.changed.emit()
	return true

func target(world: RefCounted) -> int:
	var weapon: Dictionary = current_weapon(world)
	var weapon_range: float = float(weapon.range)
	var direction: Vector2 = (aim - world.player_position).normalized()
	if direction.is_zero_approx(): return -1
	var chosen := -1
	var nearest := weapon_range + 1.0
	for id in world.defense.enemies:
		var offset: Vector2 = Vector2(world.defense.enemies[id].cell) + Vector2.ONE * 0.5 - world.player_position
		var along := offset.dot(direction)
		if along < 0 or along > weapon_range or absf(offset.cross(direction)) > 0.55: continue
		if along < nearest:
			nearest = along
			chosen = id
	return chosen

func sync_carried(world: RefCounted) -> void:
	if not has_weapon(world, active_weapon):
		var carried := carried_weapons(world)
		if carried.is_empty():
			armed = false
			firing = false
		else:
			active_weapon = carried[0]

func step(world: RefCounted) -> void:
	if invulnerable > 0: invulnerable -= 1
	if regen_delay > 0: regen_delay -= 1
	elif health < 100: health += 1
	if cooldown > 0: cooldown -= 1
	sync_carried(world)
	if armed and firing and world.defense.phase == "active" and cooldown == 0: shoot(world)

func shoot(world: RefCounted) -> bool:
	if not armed or cooldown > 0 or world.defense.phase != "active": return false
	if not has_weapon(world, active_weapon): return false
	var weapon: Dictionary = current_weapon(world)
	var ammo_cost: int = int(weapon.ammo)
	if world.player.count("ammo") < ammo_cost: return false
	var direction: Vector2 = (aim - world.player_position).normalized()
	if direction.is_zero_approx(): return false
	if world.player.remove("ammo", ammo_cost) != ammo_cost: return false
	world.defense.costs.ammo += ammo_cost
	cooldown = int(weapon.cooldown)
	world.metrics.record(world.ticks, "used", "ammo", ammo_cost)
	var id := target(world)
	var end: Vector2 = world.player_position + direction * float(weapon.range)
	if id != -1:
		end = Vector2(world.defense.enemies[id].cell) + Vector2.ONE * 0.5
		world.defense.hit(world, id, int(weapon.damage), bool(weapon.piercing))
	else:
		world.defense.add_miss(world, end)
	world.defense.add_shot(world, world.player_position, end, active_weapon)
	world.feedback_requested.emit("shot", Vector2i(world.player_position.floor()))
	return true

func damage(world: RefCounted, amount: int) -> void:
	if invulnerable > 0 or amount <= 0: return
	var received := maxi(1, roundi(amount * (100 - int(world.character.stat("damage_reduction"))) / 100.0))
	health = maxi(0, health - received)
	regen_delay = 50
	invulnerable = 5
	world.feedback_requested.emit("damage", Vector2i(world.player_position.floor()))
	if health == 0:
		var home: Vector2i = world.settlements.sites.town_hall.origin - Vector2i(1, 0)
		var safe: Vector2 = world.player_position
		var found := false
		for radius in range(16):
			for x in range(-radius, radius + 1):
				for y in range(-radius, radius + 1):
					if found: break
					var cell := home + Vector2i(x, y)
					if not world.solid(cell) and not world.defense.occupied(cell):
						safe = Vector2(cell) + Vector2.ONE * 0.5
						found = true
				if found: break
			if found: break
		world.player_position = safe
		world.previous_position = safe
		health = 100
		invulnerable = 50
		firing = false
		world.message.emit("Forced to retreat! Your pack and equipment are safe. Five seconds of protection; the defense continues.")
	world.changed.emit()

func serialize() -> Dictionary:
	return {"health": health, "invulnerable": invulnerable, "regen_delay": regen_delay, "cooldown": cooldown, "armed": armed}

func restore(data: Variant, world: RefCounted) -> bool:
	if not data is Dictionary or not data.get("armed") is bool: return false
	for pair in [["health", 1, 100], ["invulnerable", 0, 50], ["regen_delay", 0, 50], ["cooldown", 0, Definitions.MAX_WEAPON_COOLDOWN]]:
		var value = data.get(pair[0])
		if not (value is int or value is float) or not is_finite(float(value)) or value != floor(float(value)) or value < pair[1] or value > pair[2]: return false
	var carried := carried_weapons(world)
	if data.armed and carried.is_empty(): return false
	health = int(data.health)
	invulnerable = int(data.invulnerable)
	regen_delay = int(data.regen_delay)
	cooldown = int(data.cooldown)
	armed = data.armed
	if not carried.is_empty() and not has_weapon(world, active_weapon):
		active_weapon = carried[0]
	sync_carried(world)
	return true
