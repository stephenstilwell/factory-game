extends RefCounted
## Shared, read-only production diagnostics for counts and actionable destinations.
const KINDS := ["drill", "furnace", "assembler", "lab", "underground_belt", "watermill", "charcoal_kiln", "lumber_camp", "generator"]
static func stalled(world: RefCounted) -> Array:
	var result: Array = []
	for kind in KINDS:
		for id in world.by_kind[kind]:
			var entity = world.entities[id]
			if entity.health > 0 and (entity.status in ["Working", "Transporting", "Firing", "Generating - supplying district", "Idle - no demand"] or entity.status.begins_with("Mining ") or entity.status.begins_with("Researching") or entity.status.begins_with("Harvesting")): continue
			result.append({"id": id, "cell": entity.cell, "kind": kind, "reason": "Needs repair" if entity.health <= 0 else entity.status, "distance": world.player_position.distance_squared_to(Vector2(entity.cell))})
	result.sort_custom(func(a, b): return a.distance < b.distance if a.distance != b.distance else a.id < b.id)
	return result
