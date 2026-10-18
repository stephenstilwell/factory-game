extends RefCounted
## Advisory live briefing; no readiness score and no new permission gate.
static func describe(world: RefCounted) -> String:
	var hub = world.settlements.sites.town_hall
	var healthy := 0
	var loaded := 0
	var ammo := 0
	var damaged := 0
	var turrets: Array = []
	for kind in world.Catalog.Combat.TURRETS:
		for id in world.by_kind[kind]:
			var turret = world.entities[id]
			if turret.cell.distance_squared_to(hub.origin) > 28*28: continue
			if turret.health < turret.max_health(): damaged += 1
			if turret.health <= 0: continue
			healthy += 1
			ammo += turret.inventory.count("ammo")
			turrets.append(turret)
			if turret.inventory.count("ammo") >= world.Catalog.Combat.TURRETS[kind].ammo: loaded += 1
	var covered := 0
	var gates: Array = world.defense.entries(world)
	for gate in gates:
		var sample := Vector2(gate).lerp(Vector2(hub.origin)+Vector2(1,1),0.65)
		for turret in turrets:
			if Vector2(turret.cell).distance_to(sample) <= world.Catalog.Combat.TURRETS[turret.kind].range:
				covered += 1
				break
	var warnings := PackedStringArray()
	if healthy == 0: warnings.append("No healthy local turrets; a rifle-only attempt is risky.")
	elif loaded < healthy: warnings.append("%d local turrets cannot fire yet." % (healthy-loaded))
	if damaged > 0: warnings.append("%d damaged or disabled turrets need attention." % damaged)
	if world.player.count("repair_kit") == 0: warnings.append("No repair kits carried.")
	if covered < gates.size(): warnings.append("Some approach checkpoints lack turret range.")
	if world.defense.phase == "recovery": warnings.append("Repair the Hall fully to retry this same wave; earlier rewards are safe.")
	return "HALL %d/%d • Loaded turrets %d/%d • Local turret ammo %d\nPack ammo %d • Repair kits %d • Nell's workshop reserve %d\nApproach checkpoints in turret range: %d/%d (range samples only, not route or victory predictions).\n%s" % [hub.health,hub.max_health(),loaded,healthy,ammo,world.player.count("ammo"),world.player.count("repair_kit"),world.settlements.sites.workshop.inventory.count("ammo"),covered,gates.size()," ".join(warnings) if not warnings.is_empty() else "Basic supplies are present. This is guidance, not a guarantee."]
