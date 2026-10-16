extends RefCounted
## Bounded spatial lookup: hearth cost depends on its local footprint, not factory size.
static func step(world: RefCounted) -> void:
	var radius: int = world.supply_radius()
	for id in world.by_kind.fuel_depot:
		var hearth = world.entities[id]
		if hearth.health <= 0:
			hearth.status = "Disabled - repair with H"
			continue
		if hearth.inventory.count("coal") == 0:
			hearth.status = "Needs coal - load here or feed by inserter"
			continue
		var targets: Array = []
		for x in range(-radius, radius + 1):
			for y in range(-radius, radius + 1):
				if x * x + y * y > radius * radius: continue
				var target = world.at(hearth.cell + Vector2i(x, y))
				if target != null and target.kind in ["drill", "furnace"] and target.health > 0 and target.inventory.count("coal") < 3 and target.inventory.total() < target.inventory.capacity:
					targets.append(target.id)
		targets.sort()
		var ordered: Array = targets.filter(func(target_id): return target_id > hearth.supply_cursor)
		ordered.append_array(targets.filter(func(target_id): return target_id <= hearth.supply_cursor))
		for target_id in ordered:
			if hearth.inventory.count("coal") == 0: break
			if hearth.inventory.move_to(world.entities[target_id].inventory, "coal", 1) == 1: hearth.supply_cursor = target_id
		hearth.status = "Supplying burners within %d tiles" % radius
