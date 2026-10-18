extends RefCounted
## A rescued specialist's bounded, between-defense service. Ammo is transferred, never created.
const RADIUS := 28
const RESERVE := 100
static func rescued(world: RefCounted) -> bool:
	return world.settlements.enabled and 1 in world.settlements.relief_waves

static func quote(world: RefCounted) -> Dictionary:
	var result := {"reason":"","jobs":[],"rounds":0,"reserve":world.settlements.sites.workshop.inventory.count("ammo"),"shortage":0}
	var shop = world.settlements.sites.workshop
	if not rescued(world): result.reason = "Rescue Nell by winning the first beacon defense."; return result
	if not shop.repaired or shop.health <= 0 or not world.settlements.services_online(): result.reason = "Restore workshop and Town Hall services."; return result
	if world.defense.phase != "idle": result.reason = "Rearming is available between defenses, before signaling."; return result
	if not world.in_reach(shop.port()): result.reason = "Visit Nell at the workshop hatch."; return result
	var candidates: Array = []
	for kind in world.Catalog.Combat.TURRETS:
		for id in world.by_kind[kind]:
			var turret = world.entities[id]
			if turret.health > 0 and shop.origin.distance_squared_to(turret.cell) <= RADIUS*RADIUS: candidates.append(turret)
	candidates.sort_custom(func(a,b): return a.id < b.id)
	var remaining: int = result.reserve
	for turret in candidates:
		var needed: int = maxi(0,world.input_limit(turret,"ammo")-turret.inventory.count("ammo"))
		result.shortage += needed
		var amount := mini(needed,remaining)
		if amount > 0: result.jobs.append({"id":turret.id,"rounds":amount})
		result.rounds += amount
		remaining -= amount
	if result.shortage == 0: result.reason = "No healthy local turret needs ammunition."
	elif result.reserve == 0: result.reason = "Stock ammunition in the workshop reserve first."
	return result

static func stock(world: RefCounted) -> int:
	if not rescued(world): return 0
	return world.transfer_item("ammo",0,{"kind":"player"},{"kind":"site","site_id":"workshop"})

static func dispatch(world: RefCounted) -> bool:
	var plan := quote(world)
	if not plan.reason.is_empty():
		world.message.emit(plan.reason)
		return false
	var shop = world.settlements.sites.workshop
	var moved := 0
	for job in plan.jobs: moved += shop.inventory.move_to(world.entities[job.id].inventory,"ammo",job.rounds)
	world.message.emit("Nell rearmed %d defenses with %d stocked rounds. %d rounds still needed. No ammunition was created." % [plan.jobs.size(),moved,plan.shortage-moved])
	world.feedback_requested.emit("transfer",shop.port())
	world.changed.emit()
	return moved > 0

static func cell(world: RefCounted) -> Vector2i:
	var origin: Vector2i = world.settlements.sites.workshop.origin
	for offset in [Vector2i(3,3),Vector2i(4,2),Vector2i(3,-1),Vector2i(1,4)]:
		var candidate: Vector2i = origin+offset
		if world.at(candidate) == null and world.settlements.at(candidate) == null and world.terrain.tile(candidate).is_empty(): return candidate
	return Vector2i(1000001,1000001)
