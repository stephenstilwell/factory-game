extends RefCounted
## Optional new-world opening. Old saves remain unrestricted unless this extension exists.
const Definitions = preload("res://scripts/data/early_catalog.gd")
const Frontier = preload("res://scripts/model/frontier.gd")
const Catalog = preload("res://scripts/data/catalog.gd")
var enabled := false
var phase := 0
var gathered: Dictionary = {}
var delivered := 0
var sawn := 0
var charcoal := 0

func active() -> bool: return enabled and phase < 2

func available(id: String) -> bool:
	if id in Definitions.TIMBER_RECIPES: return enabled
	if id in Definitions.STONE_RECIPES: return enabled and phase >= 1
	return not active()

static func water_at(cell: Vector2i) -> bool:
	return cell.y >= 21 and cell.y <= 51 and absi(cell.x - (23 + posmod(cell.y / 12, 3))) <= 1

static func near_water(cell: Vector2i) -> bool:
	for x in range(-1, 2):
		for y in range(-1, 2):
			if water_at(cell + Vector2i(x, y)): return true
	return false

static func forage_cells(chunk: Vector2i, seed_value: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for i in range(3):
		var key := Frontier.hash_cell(chunk, seed_value, 110 + i)
		var cell := chunk * 16 + Vector2i(key % 16, (key / 16) % 16)
		if cell not in cells: cells.append(cell)
	for cell in Definitions.START_FORAGE:
		if Vector2i(floori(cell.x / 16.0), floori(cell.y / 16.0)) == chunk and cell not in cells: cells.append(cell)
	return cells

static func forage_kind(cell: Vector2i, seed_value: int) -> String:
	if Definitions.START_FORAGE.has(cell): return Definitions.START_FORAGE[cell]
	var chunk := Vector2i(floori(cell.x / 16.0), floori(cell.y / 16.0))
	var cells := forage_cells(chunk, seed_value)
	var index := cells.find(cell)
	return ("foraged_food" if index == 2 else "timber") if index >= 0 else ""

func resource_at(world: RefCounted, cell: Vector2i) -> Dictionary:
	if not enabled or water_at(cell): return {}
	var kind := forage_kind(cell, world.terrain.seed_value)
	if kind.is_empty() or world.at(cell) != null or world.settlements.at(cell) != null or world.frontier.at(cell) != "" or not world.terrain.tile(cell).is_empty(): return {}
	var stock := 8 if kind == "foraged_food" else 12
	var remaining := stock - int(gathered.get(cell, 0))
	return {"item": kind, "amount": remaining} if remaining > 0 else {}

func gather(world: RefCounted, cell: Vector2i) -> bool:
	var resource := resource_at(world, cell)
	if not gathered.has(cell) and gathered.size() >= 100000: return false
	if resource.is_empty() or not world.in_reach(cell) or not world.player.can_exchange({}, {resource.item: 1}): return false
	gathered[cell] = int(gathered.get(cell, 0)) + 1
	world.player.add(resource.item)
	produced(world, resource.item, 1)
	world.record("mined:" + resource.item)
	world.award_skill("mining", 3)
	world.hand_resource_extracted.emit(cell, resource.item)
	return true

static func produced(world: RefCounted, item: String, amount: int) -> void:
	world.production[item] = int(world.production.get(item, 0)) + amount
	world.metrics.record(world.ticks, "made", item, amount)
	world.record("produced:" + item, amount)

func hearth(world: RefCounted):
	var nearest = null
	var distance := INF
	for id in world.by_kind.communal_hearth:
		var candidate = world.entities[id]
		var next: float = world.player_position.distance_squared_to(Vector2(candidate.cell) + Vector2.ONE * 0.5)
		if candidate.health > 0 and next < distance:
			nearest = candidate
			distance = next
	return nearest

func project_reason(world: RefCounted) -> String:
	if not active(): return "Iron industry is already available. Continue learning furnaces and drills."
	var home = hearth(world)
	if home == null: return "Craft and place a communal shelter first [C / Buildings]."
	if not world.in_reach(home.cell): return "Walk to your communal shelter to deliver this project."
	if world.defense.phase in ["warning", "active"]: return "Finish the beacon defense first."
	if delivered < 8: return "Place a lumber camp and a handcart post within ten tiles. Let workers deliver 8 timber."
	if phase == 1:
		if not world.frontier.claimed("quarry"): return "Recover Greybank Quarry's mason pattern [L]."
		if sawn < 12: return "Use a waterwheel sawmill to produce 12 planks beside the old watercourse."
		if charcoal < 4: return "Use a charcoal clamp to produce 4 burner fuel."
	var cost: Dictionary = Definitions.SHELTER_COST if phase == 0 else Definitions.CROSSING_COST
	if not world.player.has_all(cost): return "Bring the project supplies shown below in your pack."
	return ""

func advance(world: RefCounted) -> bool:
	var reason := project_reason(world)
	if not reason.is_empty():
		world.message.emit(reason)
		return false
	var cost: Dictionary = Definitions.SHELTER_COST if phase == 0 else Definitions.CROSSING_COST
	if not world.player.exchange(cost, {}): return false
	world.metrics.consume(world.ticks, cost)
	phase += 1
	world.settlements.age = phase
	world.award_skill("fabrication", 150 if phase == 1 else 250)
	world.message.emit("Shelter supplied! The first neighbors have a home. Stone & Water unlocks the waterwheel sawmill and charcoal clamp." if phase == 1 else "The crossing is rebuilt! Iron & Industry unlocks ore mining, furnaces and mechanical logistics. Your charcoal can fuel the first furnace. Copper comes later in the factory lessons.")
	world.feedback_requested.emit("success", hearth(world).cell)
	world.changed.emit()
	return true

func summary(world: RefCounted) -> String:
	var text: String = "TOWN AGE: " + Definitions.NAMES[phase]
	if not active(): return text + "\nTimber and water-powered production keep their value. Restore the market, workshop and Hall with your new industry."
	text += "\nNEXT: " + ("Welcome the first neighbors → Stone & Water" if phase == 0 else "Rebuild the crossing → Iron & Industry")
	text += "\nWorker deliveries: %d / 8 timber" % mini(delivered, 8)
	if phase == 1: text += "\nMason pattern: %s • Water-sawn planks: %d / 12 • Charcoal: %d / 4" % ["recovered" if world.frontier.claimed("quarry") else "[L] Greybank", mini(sawn, 12), mini(charcoal, 4)]
	var cost: Dictionary = Definitions.SHELTER_COST if phase == 0 else Definitions.CROSSING_COST
	text += "\nDELIVER FROM PACK"
	for item in cost: text += "\n%s %d / %d" % ["Charcoal fuel" if item == "coal" else Catalog.item_name(item), world.player.count(item), cost[item]]
	text += "\n" + ("Ready — deliver the project below." if project_reason(world).is_empty() else project_reason(world))
	return text

func objective(world: RefCounted) -> Dictionary:
	if phase == 0:
		if int(world.production.get("timber", 0)) < 6: return {"title": "TIMBER & HEARTH • Gather fallen timber", "hint": "Hold RMB over the fallen logs beside you at (23, 13). C crafts planks and a stone axe; collect a few loose stones for tools.", "cell": Vector2i(23, 13)}
		if world.by_kind.lumber_camp.is_empty(): return {"title": "Build a lumber camp", "hint": "C: make a stone axe (2 timber + 2 stone), then a lumber camp (6 timber + axe). Place it beside a grove using Buildings on the hotbar."}
		if world.by_kind.cart_post.is_empty() or delivered < 8: return {"title": "First logistics • Workers carry the timber", "hint": "Craft a handcart collection post (4 timber + 4 planks). Place within ten tiles of a lumber camp. A worker carries four timber every four seconds. X collects timber at the post."}
		if hearth(world) == null: return {"title": "Give the first neighbors a shelter", "hint": "Craft a communal shelter (8 timber + 4 planks), then place it near your work area. Gather berries at (26, 14). Open Town [Y] for the restoration project."}
		return {"title": "Supply the communal shelter [Y]", "hint": "Deliver 12 timber, 8 planks, 4 gathered berries and 8 stone from your pack. Stand beside your shelter and complete the project in Town [Y].", "cell": hearth(world).cell}
	return {"title": "STONE & WATER • Rebuild the crossing [Y]", "hint": "Place a waterwheel sawmill beside the blue old watercourse south near (24, 28). A nearby handcart post supplies timber automatically. Build a charcoal clamp; recover the Greybank mason pattern [L]. Then complete the crossing project [Y].", "cell": Vector2i(24, 28)}

func step(world: RefCounted) -> void:
	if not enabled: return
	for id in world.by_kind.lumber_camp:
		var camp = world.entities[id]
		if camp.health <= 0: continue
		if not camp.output.can_exchange({}, {"timber": 4}):
			camp.status = "Timber output full — add a handcart post"
			continue
		camp.progress += 1
		if not camp.status.begins_with("Grove exhausted"): camp.status = "Harvesting nearby timber"
		if camp.progress < 40: continue
		camp.progress = 0
		var found := false
		for y in range(-4, 5):
			for x in range(-4, 5):
				var cell: Vector2i = camp.cell + Vector2i(x, y)
				if world.frontier.clear_tree(world, cell, false):
					camp.output.add("timber", 4)
					produced(world, "timber", 4)
					found = true
					break
			if found: break
		if not found: camp.status = "Grove exhausted — pick up and move camp"
	for id in world.by_kind.cart_post:
		var post = world.entities[id]
		if post.health <= 0: continue
		post.progress += 1
		if post.progress < 40: continue
		post.progress = 0
		var source = route_source(world, post)
		post.status = "Waiting for timber within ten tiles"
		if source != null:
			var moved: int = source.output.move_to(post.inventory, "timber", 4)
			var previous := delivered
			delivered += moved
			if previous < 8 and delivered >= 8: world.award_skill("fabrication", 100)
			post.status = "Worker delivered %d timber" % moved
		if phase >= 1:
			for kind in ["watermill", "charcoal_kiln"]:
				for target_id in world.by_kind[kind]:
					var target = world.entities[target_id]
					if target.health > 0 and post.cell.distance_squared_to(target.cell) <= 25:
						post.inventory.move_to(target.inventory, "timber", mini(4, maxi(0, world.input_limit(target, "timber") - target.inventory.count("timber"))))

func route_source(world: RefCounted, post: RefCounted):
	var best = null
	var distance := 101
	for id in world.by_kind.lumber_camp:
		var candidate = world.entities[id]
		var next_distance: int = post.cell.distance_squared_to(candidate.cell)
		if candidate.health > 0 and candidate.output.count("timber") > 0 and next_distance < distance:
			best = candidate
			distance = next_distance
	return best

func serialize() -> Dictionary:
	var removed: Array = []
	for cell in gathered: removed.append([cell.x, cell.y, gathered[cell]])
	return {"version": 1, "enabled": enabled, "phase": phase, "gathered": removed, "delivered": delivered, "sawn": sawn, "charcoal": charcoal}

func restore(world: RefCounted, data) -> bool:
	if not data is Dictionary or data.get("version") != 1 or not data.get("enabled") is bool: return false
	for key in ["phase", "delivered", "sawn", "charcoal"]:
		if not Frontier.integer(data.get(key), 0, 2000000000): return false
	if data.phase > 2 or not data.get("gathered") is Array or data.gathered.size() > 100000: return false
	enabled = data.enabled
	phase = int(data.phase)
	delivered = int(data.delivered)
	sawn = int(data.sawn)
	charcoal = int(data.charcoal)
	for record in data.gathered:
		if not record is Array or record.size() != 3: return false
		if not Frontier.integer(record[0]) or not Frontier.integer(record[1]) or not Frontier.integer(record[2], 1, 12): return false
		var cell := Vector2i(int(record[0]), int(record[1]))
		var kind := forage_kind(cell, world.terrain.seed_value)
		if kind.is_empty() or gathered.has(cell) or (kind == "foraged_food" and record[2] > 8): return false
		gathered[cell] = int(record[2])
	if not enabled and (phase != 0 or delivered != 0 or sawn != 0 or charcoal != 0 or not gathered.is_empty()): return false
	if phase == 0 and (sawn != 0 or charcoal != 0): return false
	if phase > 0 and delivered < 8: return false
	if phase == 2 and (sawn < 12 or charcoal < 4): return false
	return true
