extends RefCounted
## Batch reservation is atomic; job IDs keep queue cancellation stable between ticks.

const Catalog = preload("res://scripts/data/catalog.gd")
const MAX_QUEUE := 20

static func available(world: RefCounted, id: String) -> bool:
	var recipe: Dictionary = Catalog.RECIPES.get(id, {})
	return recipe.get("hand", false) and world.unlocked(recipe) and world.content_available(id)

static func maximum(world: RefCounted, id: String) -> int:
	if not available(world, id): return 0
	var limit: int = MAX_QUEUE - world.craft_queue.size()
	for item in Catalog.RECIPES[id]["in"]: limit = mini(limit, world.player.count(item) / int(Catalog.RECIPES[id]["in"][item]))
	return limit

static func enqueue(world: RefCounted, id: String, count: int) -> bool:
	if count <= 0 or count > MAX_QUEUE or not available(world, id): return false
	if count > MAX_QUEUE - world.craft_queue.size():
		world.message.emit("Not enough room in the craft queue (20 jobs maximum).")
		return false
	var required: Dictionary = {}
	for item in Catalog.RECIPES[id]["in"]: required[item] = int(Catalog.RECIPES[id]["in"][item]) * count
	if not world.player.exchange(required, {}):
		world.message.emit("Missing ingredients: " + Catalog.describe(required))
		return false
	for i in range(count):
		world.craft_queue.append({"id": world.next_craft_id, "recipe": id, "remaining": int(Catalog.RECIPES[id].get("ticks", 5)), "work": 0})
		world.next_craft_id += 1
	world.changed.emit()
	return true

static func cancel(world: RefCounted, job_id: int) -> bool:
	for i in range(world.craft_queue.size()):
		var job: Dictionary = world.craft_queue[i]
		if int(job.id) != job_id: continue
		if not world.player.exchange({}, Catalog.RECIPES[job.recipe]["in"]):
			world.message.emit("Make pack space to refund this craft's ingredients.")
			return false
		world.craft_queue.remove_at(i)
		world.craft_credit = 0
		world.changed.emit()
		return true
	return false

static func cancel_all(world: RefCounted) -> bool:
	var refund: Dictionary = {}
	for job in world.craft_queue:
		for item in Catalog.RECIPES[job.recipe]["in"]: refund[item] = int(refund.get(item, 0)) + int(Catalog.RECIPES[job.recipe]["in"][item])
	if not world.player.exchange({}, refund):
		world.message.emit("Make pack space to refund the queued ingredients.")
		return false
	world.craft_queue.clear()
	world.craft_credit = 0
	world.changed.emit()
	return true
