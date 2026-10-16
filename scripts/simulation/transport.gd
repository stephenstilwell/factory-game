extends RefCounted
## One item per cell; snapshot moves, output alternation, and receiver-based fair merges.
const KINDS := ["belt", "fast_belt", "splitter", "underground_belt"]
const DIRS := [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]
const UNDERGROUND_SPAN := 6

static func partner(world: RefCounted, entry: RefCounted):
	for distance in range(1, UNDERGROUND_SPAN + 1):
		var other = world.at(entry.cell + DIRS[entry.direction] * distance)
		if other != null and other.kind == "underground_belt" and other.direction == entry.direction:
			return other if other.underground_exit and other.health > 0 else null
	return null

static func outputs(world: RefCounted, entity: RefCounted) -> Array:
	if entity.kind == "underground_belt" and not entity.underground_exit:
		var exit = partner(world, entity)
		return [exit.cell] if exit != null else []
	if entity.kind == "splitter":
		var options := [entity.cell + DIRS[entity.direction], entity.cell + DIRS[posmod(entity.direction + 1, 4)]]
		return options if entity.routing_cursor == 0 else [options[1], options[0]]
	return [entity.cell + DIRS[entity.direction]]

static func step(world: RefCounted) -> void:
	var ids: Array = []
	for kind in KINDS: ids.append_array(world.by_kind[kind])
	ids.sort()
	var occupied: Dictionary = {}
	for id in ids:
		var entity = world.entities[id]
		if entity.inventory.total() > 0: occupied[entity.cell] = true
	var proposals: Dictionary = {}
	for id in ids:
		var source = world.entities[id]
		if source.health <= 0: continue
		if source.kind != "fast_belt" and world.ticks % 2 != 0: continue
		if source.inventory.total() == 0:
			source.status = "Waiting for items"
			continue
		source.status = "Output blocked"
		var destinations: Array = outputs(world, source)
		if destinations.is_empty(): source.status = "No matching exit within six tiles"
		for cell in destinations:
			var target = world.at(cell)
			if target == null or target.kind not in KINDS or target.health <= 0 or occupied.has(cell): continue
			# Surface conveyors can feed entrances; exits receive only their paired underground entrance.
			if target.kind == "underground_belt" and target.underground_exit:
				if source.kind != "underground_belt" or source.underground_exit or partner(world, source) != target: continue
			if not proposals.has(target.id): proposals[target.id] = []
			proposals[target.id].append(source)
	# Resolve output preferences in rounds. A losing splitter can use its other free branch.
	var used_sources: Dictionary = {}
	var used_targets: Dictionary = {}
	var moves: Array = []
	for round_index in range(2):
		for target_id in ids:
			if used_targets.has(target_id) or not proposals.has(target_id): continue
			var target = world.entities[target_id]
			var eligible: Array = []
			for source in proposals[target_id]:
				if used_sources.has(source.id): continue
				var routes: Array = outputs(world, source)
				var preferred = null
				for cell in routes:
					var candidate = world.at(cell)
					if candidate != null and proposals.has(candidate.id) and not used_targets.has(candidate.id) and proposals[candidate.id].has(source):
						preferred = candidate
						break
				if preferred == target or round_index == 1: eligible.append(source)
			if eligible.is_empty(): continue
			eligible.sort_custom(func(a, b): return a.id < b.id)
			var winner = eligible[0]
			for candidate in eligible:
				if candidate.id > target.merge_cursor:
					winner = candidate
					break
			used_sources[winner.id] = true
			used_targets[target_id] = true
			moves.append([winner, target, winner.inventory.contents.keys()[0]])
	for move in moves:
		var source = move[0]
		var target = move[1]
		if source.inventory.move_to(target.inventory, move[2]) != 1: continue
		target.merge_cursor = source.id
		source.status = "Transporting"
		if source.kind == "splitter":
			source.routing_cursor = 1 if target.cell == source.cell + DIRS[source.direction] else 0
