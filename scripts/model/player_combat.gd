extends RefCounted
const Definitions = preload("res://scripts/data/combat_catalog.gd")
var health := 100
var invulnerable := 0
var regen_delay := 0
var cooldown := 0
var armed := false
var firing := false # Transient input intent.
var aim := Vector2.ZERO

func toggle(world: RefCounted) -> bool:
	if not armed and (world.player.count("service_rifle") == 0 or not world.content_available("service_rifle") or "logistics" not in world.researched):
		world.message.emit("Craft a service rifle after restoring the workshop and researching Supply routes. [C]")
		return false
	armed = not armed
	firing = false
	world.changed.emit()
	return true

func target(world: RefCounted) -> int:
	var direction: Vector2 = (aim - world.player_position).normalized()
	if direction.is_zero_approx(): return -1
	var chosen := -1
	var nearest := Definitions.RIFLE_RANGE + 1.0
	for id in world.defense.enemies:
		var offset: Vector2 = Vector2(world.defense.enemies[id].cell) + Vector2.ONE * 0.5 - world.player_position
		var along := offset.dot(direction)
		if along < 0 or along > Definitions.RIFLE_RANGE or absf(offset.cross(direction)) > 0.55: continue
		if along < nearest:
			nearest = along
			chosen = id
	return chosen

func sync_carried(world: RefCounted) -> void:
	if world.player.count("service_rifle") == 0:
		armed = false
		firing = false

func step(world: RefCounted) -> void:
	if invulnerable > 0: invulnerable -= 1
	if regen_delay > 0: regen_delay -= 1
	elif health < 100: health += 1
	if cooldown > 0: cooldown -= 1
	sync_carried(world)
	if armed and firing and world.defense.phase == "active" and cooldown == 0: shoot(world)

func shoot(world: RefCounted) -> bool:
	if not armed or cooldown > 0 or world.defense.phase != "active" or world.player.count("service_rifle") == 0: return false
	var direction: Vector2 = (aim - world.player_position).normalized()
	if direction.is_zero_approx() or world.player.remove("ammo") != 1: return false
	cooldown = Definitions.RIFLE_COOLDOWN
	world.metrics.record(world.ticks, "used", "ammo", 1)
	var id := target(world)
	var end: Vector2 = world.player_position + direction * Definitions.RIFLE_RANGE
	if id != -1:
		end = Vector2(world.defense.enemies[id].cell) + Vector2.ONE * 0.5
		world.defense.hit(world, id, Definitions.RIFLE_DAMAGE, false)
	world.defense.add_shot(world, world.player_position, end, "rifle")
	world.feedback_requested.emit("shot", Vector2i(world.player_position.floor()))
	return true

func damage(world: RefCounted, amount: int) -> void:
	if invulnerable > 0: return
	health = maxi(0, health - amount)
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
	for pair in [["health", 1, 100], ["invulnerable", 0, 50], ["regen_delay", 0, 50], ["cooldown", 0, Definitions.RIFLE_COOLDOWN]]:
		var value = data.get(pair[0])
		if not (value is int or value is float) or not is_finite(float(value)) or value != floor(float(value)) or value < pair[1] or value > pair[2]: return false
	if data.armed and (world.player.count("service_rifle") == 0 or not world.content_available("service_rifle") or "logistics" not in world.researched): return false
	health = int(data.health)
	invulnerable = int(data.invulnerable)
	regen_delay = int(data.regen_delay)
	cooldown = int(data.cooldown)
	armed = data.armed
	return true
