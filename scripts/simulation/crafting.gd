extends RefCounted
## Plans reserve pack inputs atomically; produced intermediates move directly into dependent jobs.
const Catalog = preload("res://scripts/data/catalog.gd")
const MAX_QUEUE := 20
static func available(world: RefCounted, id: String) -> bool:
	var recipe: Dictionary = Catalog.RECIPES.get(id, {})
	return recipe.get("hand", false) and world.unlocked(recipe) and world.content_available(id)
static func _add(goods: Dictionary, item: String, count: int) -> void:
	goods[item] = int(goods.get(item, 0)) + count
static func reserved(job: Dictionary) -> Dictionary:
	return job.reserved
static func ready(job: Dictionary) -> bool:
	return job.dependencies.is_empty() and reserved(job) == Catalog.RECIPES[job.recipe]["in"]
static func plan(world: RefCounted, id: String, count: int = 1) -> Dictionary:
	var state := {"jobs": [], "cost": {}, "queued": {}, "pool": [], "pack": world.player.contents.duplicate(), "error": "", "limit": MAX_QUEUE - world.craft_queue.size(), "next": world.next_craft_id}
	if count <= 0 or count > MAX_QUEUE or not available(world, id):
		state.error = "This recipe is not available to hand-craft."
		return state
	var claimed: Dictionary = {}
	for job in world.craft_queue:
		for dependency in job.dependencies:
			if not claimed.has(dependency.id): claimed[dependency.id] = {}
			for item in dependency.items: _add(claimed[dependency.id], item, int(dependency.items[item]))
	for job in world.craft_queue:
		for item in Catalog.RECIPES[job.recipe]["out"]:
			var free: int = int(Catalog.RECIPES[job.recipe]["out"][item]) - int(claimed.get(job.id, {}).get(item, 0))
			if free > 0: state.pool.append({"id": int(job.id), "item": item, "count": free, "existing": true})
	for i in range(count):
		if not _schedule(world, state, id, []): break
	return state
static func _schedule(world: RefCounted, state: Dictionary, id: String, visiting: Array) -> bool:
	if id in visiting:
		state.error = "This recipe has a circular hand-crafting dependency."
		return false
	if state.jobs.size() >= state.limit:
		state.error = "Not enough queue space for this craft and its intermediates (20 jobs maximum)."
		return false
	var path := visiting.duplicate()
	path.append(id)
	var job := {"recipe": id, "reserved": {}, "dependencies": [], "remaining": int(Catalog.RECIPES[id].get("ticks", 5)), "work": 0}
	for item in Catalog.RECIPES[id]["in"]:
		if not _supply(world, state, item, int(Catalog.RECIPES[id]["in"][item]), job, path): return false
	if state.jobs.size() >= state.limit:
		state.error = "Not enough queue space for this craft and its intermediates (20 jobs maximum)."
		return false
	job.id = int(state.next) + state.jobs.size()
	state.jobs.append(job)
	for item in Catalog.RECIPES[id]["out"]:
		state.pool.append({"id": int(job.id), "item": item, "count": int(Catalog.RECIPES[id]["out"][item]), "existing": false})
	return true
static func _take_pool(state: Dictionary, item: String, need: int, job: Dictionary) -> int:
	for lot in state.pool:
		if lot.item != item or int(lot.count) == 0: continue
		var amount := mini(need, int(lot.count))
		if amount <= 0: break
		lot.count -= amount
		need -= amount
		var dependency: Dictionary = {}
		for candidate in job.dependencies:
			if int(candidate.id) == int(lot.id): dependency = candidate; break
		if dependency.is_empty():
			dependency = {"id": int(lot.id), "items": {}}
			job.dependencies.append(dependency)
		_add(dependency.items, item, amount)
		if lot.existing: _add(state.queued, item, amount)
	return need
static func _producer(world: RefCounted, item: String) -> String:
	if available(world, item) and Catalog.RECIPES[item]["out"].has(item): return item
	for candidate in Catalog.RECIPES:
		if Catalog.RECIPES[candidate]["out"].has(item) and available(world, candidate): return candidate
	return ""
static func free_outputs(world: RefCounted) -> Dictionary:
	var result: Dictionary = {}
	for job in world.craft_queue:
		for item in Catalog.RECIPES[job.recipe]["out"]: _add(result, item, int(Catalog.RECIPES[job.recipe]["out"][item]))
	for job in world.craft_queue:
		for dependency in job.dependencies:
			for item in dependency.items: result[item] -= int(dependency.items[item])
	return result
static func _supply(world: RefCounted, state: Dictionary, item: String, amount: int, job: Dictionary, visiting: Array) -> bool:
	var take := mini(amount, int(state.pack.get(item, 0)))
	if take > 0:
		state.pack[item] -= take
		_add(state.cost, item, take)
		_add(job.reserved, item, take)
	var need := _take_pool(state, item, amount - take, job)
	while need > 0:
		var recipe_id := _producer(world, item)
		if recipe_id.is_empty():
			state.error = "Need %d %s. Gather it or supply it first; it cannot be hand-crafted yet." % [need, Catalog.item_name(item)]
			return false
		if not _schedule(world, state, recipe_id, visiting): return false
		need = _take_pool(state, item, need, job)
	return true
static func maximum(world: RefCounted, id: String) -> int:
	if not available(world, id): return 0
	var low := 0
	var high: int = MAX_QUEUE - world.craft_queue.size()
	var ingredients: Dictionary = Catalog.RECIPES[id]["in"]
	if not ingredients.keys().any(func(item): return not _producer(world, item).is_empty()):
		var queued := free_outputs(world)
		for item in ingredients: high = mini(high, (world.player.count(item) + int(queued.get(item, 0))) / int(ingredients[item]))
		return high
	while low < high:
		var middle := (low + high + 1) / 2
		if plan(world, id, middle).error.is_empty(): low = middle
		else: high = middle - 1
	return low
static func enqueue(world: RefCounted, id: String, count: int) -> bool:
	var planned := plan(world, id, count)
	if not planned.error.is_empty():
		world.message.emit(planned.error)
		return false
	if not world.player.exchange(planned.cost, {}): return false
	world.craft_queue.append_array(planned.jobs)
	world.next_craft_id += planned.jobs.size()
	world.changed.emit()
	return true
static func complete(world: RefCounted, entry: Dictionary) -> bool:
	if not ready(entry): return false
	var output: Dictionary = Catalog.RECIPES[entry.recipe]["out"].duplicate()
	for job in world.craft_queue:
		for dependency in job.dependencies:
			if int(dependency.id) != int(entry.id): continue
			for item in dependency.items:
				if int(output.get(item, 0)) < int(dependency.items[item]): return false
				output[item] -= int(dependency.items[item])
	for item in output.keys():
		if output[item] == 0: output.erase(item)
	if not world.player.exchange({}, output): return false
	for job in world.craft_queue:
		var dependencies: Array = job.dependencies
		for index in range(dependencies.size() - 1, -1, -1):
			var dependency: Dictionary = dependencies[index]
			if int(dependency.id) != int(entry.id): continue
			for item in dependency.items: _add(job.reserved, item, int(dependency.items[item]))
			dependencies.remove_at(index)
	if not output.is_empty(): world.hand_craft_completed.emit(entry.recipe, output.duplicate())
	return true
static func cancellation(world: RefCounted, job_id: int = -1) -> Dictionary:
	var ids: Array = []
	var refund: Dictionary = {}
	for job in world.craft_queue:
		var include: bool = job_id == -1 or int(job.id) == job_id
		for dependency in job.dependencies:
			if int(dependency.id) in ids: include = true
		if not include: continue
		ids.append(int(job.id))
		for item in reserved(job): _add(refund, item, int(reserved(job)[item]))
	return {"ids": ids, "refund": refund}
static func _cancel(world: RefCounted, report: Dictionary) -> bool:
	if report.ids.is_empty(): return false
	if not world.player.exchange({}, report.refund):
		world.message.emit("Make pack space to refund this craft and its dependent jobs.")
		return false
	world.craft_queue = world.craft_queue.filter(func(job): return int(job.id) not in report.ids)
	world.craft_credit = 0
	world.changed.emit()
	return true
static func cancel(world: RefCounted, job_id: int) -> bool:
	if job_id <= 0: return false
	return _cancel(world, cancellation(world, job_id))
static func cancel_all(world: RefCounted) -> bool:
	return _cancel(world, cancellation(world))
static func validate_queue(world: RefCounted) -> bool:
	var sources: Dictionary = {}
	var claims: Dictionary = {}
	for job in world.craft_queue:
		var recipe: Dictionary = Catalog.RECIPES[job.recipe]
		if not job.has("reserved") or not job.has("dependencies"): return false
		if not job.reserved is Dictionary or not job.dependencies is Array or job.dependencies.size() > MAX_QUEUE: return false
		var provided: Dictionary = {}
		for item in job.reserved:
			if not recipe["in"].has(item) or not world.frontier.integer(job.reserved[item], 1, int(recipe["in"][item])): return false
			job.reserved[item] = int(job.reserved[item])
			_add(provided, item, int(job.reserved[item]))
		var seen: Array = []
		for dependency in job.dependencies:
			if not dependency is Dictionary or not world.frontier.integer(dependency.get("id"), 1) or not dependency.get("items") is Dictionary or dependency.items.is_empty(): return false
			var id: int = int(dependency.id)
			if not sources.has(id) or id in seen: return false
			seen.append(id)
			dependency.id = id
			if not claims.has(id): claims[id] = {}
			for item in dependency.items:
				if not recipe["in"].has(item) or not sources[id].has(item) or not world.frontier.integer(dependency.items[item], 1, int(sources[id][item])): return false
				dependency.items[item] = int(dependency.items[item])
				_add(claims[id], item, int(dependency.items[item]))
				if int(claims[id][item]) > int(sources[id][item]): return false
				_add(provided, item, int(dependency.items[item]))
		if provided != recipe["in"]: return false
		sources[int(job.id)] = recipe["out"]
	return true
static func describe_plan(planned: Dictionary) -> String:
	if not planned.error.is_empty(): return planned.error
	var steps: Array = []
	for job in planned.jobs:
		if not steps.is_empty() and steps.back().recipe == job.recipe: steps.back().count += 1
		else: steps.append({"recipe": job.recipe, "count": 1})
	var names := PackedStringArray()
	for step in steps: names.append("%s x%d" % [Catalog.item_name(step.recipe), step.count])
	var text := "Queue: " + " -> ".join(names)
	text += "\nReserve from pack: " + Catalog.describe(planned.cost)
	if not planned.queued.is_empty(): text += "\nUses already queued output: " + Catalog.describe(planned.queued)
	text += "\n%d new jobs; intermediates are supplied automatically." % planned.jobs.size()
	return text
