extends RefCounted
## Derived maintenance quote, paid atomically at dispatch. No background income or free repairs.
const RADIUS := 28
const KIT_LIMIT := 10
const CREDIT_PER_KIT := 2

static func reason(world: RefCounted) -> String:
	var town: RefCounted = world.settlements
	if not town.enabled or not town.sites.workshop.repaired: return "Restore the Engineers' Workshop to hire its crew."
	if town.sites.workshop.health <= 0: return "Repair the disabled workshop with H first."
	if not town.services_online(): return "Repair the breached Town Hall with H to reopen services."
	if world.defense.phase in ["warning", "active"]: return "Crews work between defenses. Finish or cancel the beacon first."
	if not world.in_reach(town.sites.workshop.port()): return "Walk to the workshop delivery hatch."
	if world.player.count("repair_kit") == 0: return "Bring repair kits, or buy a supply bundle at the market."
	if town.credits < CREDIT_PER_KIT: return "Needs at least 2 trade credits."
	return ""

static func quote(world: RefCounted) -> Dictionary:
	var result := {"reason": reason(world), "jobs": [], "kits": 0, "credits": 0, "health": 0}
	if not result.reason.is_empty(): return result
	var center: Vector2i = world.settlements.sites.workshop.port()
	var targets: Array = []
	for entity in world.entities.values(): _candidate(world, targets, entity, entity.cell, center, entity.id)
	var index := 0
	for site in world.settlements.sites.values():
		index += 1
		if site.repaired: _candidate(world, targets, site, site.port(), center, 2000000000 + index)
	targets.sort_custom(func(a, b):
		if a.fraction != b.fraction: return a.fraction < b.fraction
		if a.distance != b.distance: return a.distance < b.distance
		return a.order < b.order)
	var budget := mini(KIT_LIMIT, mini(world.player.count("repair_kit"), world.settlements.credits / CREDIT_PER_KIT))
	var power: int = world.character.stat("repair_power")
	for target in targets:
		if budget <= 0: break
		var missing: int = target.target.max_health() - target.target.health
		var kits := mini(budget, ceili(float(missing) / power))
		var health := mini(missing, kits * power)
		result.jobs.append({"target": target.target, "cell": target.cell, "health": health})
		result.kits += kits
		result.health += health
		budget -= kits
	result.credits = result.kits * CREDIT_PER_KIT
	if result.jobs.is_empty(): result.reason = "No eligible damage within 28 tiles of the workshop."
	return result

static func _candidate(world: RefCounted, targets: Array, target: RefCounted, cell: Vector2i, center: Vector2i, order: int) -> void:
	if target.health >= target.max_health() or center.distance_squared_to(cell) > RADIUS * RADIUS: return
	if world.defense.occupied(cell): return
	if target.kind != "settlement_port" and world.Catalog.BUILDINGS[target.kind].solid and Rect2(Vector2(cell), Vector2.ONE).grow(0.22).has_point(world.player_position): return
	targets.append({"target": target, "cell": cell, "fraction": float(target.health) / target.max_health(), "distance": center.distance_squared_to(cell), "order": order})

static func dispatch(world: RefCounted) -> bool:
	var plan := quote(world) # Recheck live funds, goods, damage and combat state on click.
	if not plan.reason.is_empty():
		world.message.emit(plan.reason)
		return false
	if world.player.remove("repair_kit", plan.kits) != plan.kits: return false
	world.settlements.credits -= plan.credits
	world.settlements.maintenance_kits += plan.kits
	world.metrics.consume(world.ticks, {"repair_kit": plan.kits})
	for job in plan.jobs:
		if job.target.health == 0: world.navigation_revision += 1
		job.target.health += job.health
		if job.target.kind != "settlement_port": job.target.status = "Repaired"
		world.structure_repaired.emit(job.cell)
	if world.defense.phase == "recovery" and world.settlements.sites.town_hall.health == world.settlements.sites.town_hall.max_health(): world.defense.phase = "idle"
	world.message.emit("Oren's crew repaired %d structures (+%d health). Used %d kits and %d credits." % [plan.jobs.size(), plan.health, plan.kits, plan.credits])
	world.changed.emit()
	return true
