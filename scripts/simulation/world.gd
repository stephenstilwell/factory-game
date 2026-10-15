extends RefCounted
## Authoritative state and commands. No scene tree, drawing, input, or file access.

const Catalog = preload("res://scripts/data/catalog.gd")
const Inventory = preload("res://scripts/model/inventory.gd")
const Entity = preload("res://scripts/model/entity.gd")
const Terrain = preload("res://scripts/model/terrain.gd")
const Onboarding = preload("res://scripts/simulation/onboarding.gd")
const Settlements = preload("res://scripts/simulation/settlements.gd")
const Transfers = preload("res://scripts/simulation/inventory_transfers.gd")
const Crafting = preload("res://scripts/simulation/crafting.gd")
const Character = preload("res://scripts/model/character_progression.gd")
const Skills = preload("res://scripts/model/skills.gd")
const Defense = preload("res://scripts/simulation/defense.gd")
const DIRS := [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]
const TICK_SECONDS := 0.1

signal changed
signal message(text: String)
signal skill_progressed(id: String, amount: int, level: int, leveled: bool)
signal hand_resource_extracted(cell: Vector2i, item: String)
signal structure_repaired(cell: Vector2i)

var terrain: RefCounted
var character: RefCounted
var skills: RefCounted
var player: RefCounted
var guide: RefCounted
var settlements: RefCounted
var defense: RefCounted
var player_position := Vector2(18.5, 18.5)
var previous_position := Vector2(18.5, 18.5)
var move_direction := Vector2.ZERO
var entities: Dictionary = {}
var occupancy: Dictionary = {}
var by_kind: Dictionary = {}
var next_id := 1
var ticks := 0
var production: Dictionary = {}
var researched: Array = []
var research_progress := 0
var craft_queue: Array = []
var next_craft_id := 1
var mining_cell := Vector2i.ZERO
var mining_progress := 0 # Hundredths of a work tick, avoiding fractional drift.
var mining := false

func _init(world_seed: int = 74103) -> void:
	terrain = Terrain.new(world_seed)
	character = Character.new()
	skills = Skills.new()
	player = Inventory.new()
	guide = Onboarding.new()
	settlements = Settlements.new()
	defense = Defense.new()
	for kind in Catalog.BUILDINGS: by_kind[kind] = []

func start() -> void:
	# A new game has no possessions or construction. All content must be earned.
	terrain = Terrain.new(terrain.seed_value)
	terrain.generator_version = Terrain.GENERATOR_VERSION
	character = Character.new()
	skills = Skills.new()
	player.capacity = int(character.stat("inventory_capacity"))
	player.contents.clear()
	entities.clear()
	occupancy.clear()
	for kind in by_kind: by_kind[kind].clear()
	guide = Onboarding.new()
	guide.enabled = true
	settlements = Settlements.new(true)
	defense = Defense.new()
	player_position = Vector2(24.5, 12.5)
	previous_position = player_position
	move_direction = Vector2.ZERO
	next_id = 1
	ticks = 0
	production.clear()
	researched.clear()
	research_progress = 0
	craft_queue.clear()
	next_craft_id = 1
	mining = false
	mining_progress = 0
	changed.emit()

func content_available(id: String) -> bool:
	if id in ["wall", "repair_kit"]: return settlements.enabled and settlements.sites.trading_post.repaired
	if id in ["turret", "ammo"]: return settlements.enabled and settlements.sites.workshop.repaired
	return guide.available(id)

func record(key: String, amount: int = 1) -> void:
	var completed: Array = guide.record(key, amount)
	if not completed.is_empty():
		message.emit("Learned: " + ", ".join(completed))
		changed.emit()

func at(cell: Vector2i):
	return entities.get(occupancy.get(cell, -1))

func in_reach(cell: Vector2i) -> bool:
	return player_position.distance_to(Vector2(cell) + Vector2.ONE * 0.5) <= interaction_reach()

func interaction_reach() -> float:
	return float(character.stat("interaction_reach"))

func mining_duration() -> int:
	return int(character.stat("mining_ticks"))

func upgrade_character(id: String, expected_rank: int) -> bool:
	return character.purchase(self, id, expected_rank)

func award_skill(id: String, amount: int) -> void:
	var reward: Dictionary = skills.gain(id, amount)
	if reward.is_empty(): return
	var leveled: bool = reward.level > reward.previous
	skill_progressed.emit(id, int(reward.amount), int(reward.level), leveled)
	if leveled: message.emit("%s level %d! Open Engineer [P] to see your skills and milestones." % [Skills.Definitions.SKILLS[id].name, reward.level])

func movement_speed() -> float:
	return float(character.stat("movement_speed")) * skills.multiplier("exploration") * defense.morale_multiplier(self)

func unlocked(definition: Dictionary) -> bool:
	return not definition.has("technology") or definition.technology in researched

func can_build(kind: String, cell: Vector2i) -> String:
	if not Catalog.BUILDINGS.has(kind): return "Unknown building."
	if not in_reach(cell): return "Out of reach. Walk closer with WASD."
	if at(cell) != null: return "Tile is occupied."
	if defense.occupied(cell): return "A scavenger occupies this tile."
	if settlements.at(cell) != null: return "This land belongs to a settlement project."
	if not unlocked(Catalog.BUILDINGS[kind]): return "Research Logistics I first."
	if not content_available(kind): return "Follow the current learning objective to discover this building."
	if player.count(kind) == 0: return "Craft more %s (C)." % Catalog.item_name(kind)
	if Catalog.BUILDINGS[kind].solid and Rect2(Vector2(cell), Vector2.ONE).grow(0.22).has_point(player_position): return "Move away from the construction tile."
	if kind == "drill" and terrain.tile(cell).is_empty(): return "Drills require a resource deposit."
	return ""

func build(kind: String, cell: Vector2i, direction: int) -> bool:
	var reason := can_build(kind, cell)
	if not reason.is_empty():
		message.emit(reason)
		return false
	player.remove(kind)
	spawn(kind, cell, direction)
	record("placed:" + kind)
	changed.emit()
	return true

func spawn(kind: String, cell: Vector2i, direction: int):
	var entity = Entity.new(next_id, kind, cell, direction)
	next_id += 1
	register(entity)
	return entity

func register(entity: RefCounted) -> void:
	entities[entity.id] = entity
	occupancy[entity.cell] = entity.id
	by_kind[entity.kind].append(entity.id)

func reclaim(cell: Vector2i) -> bool:
	if settlements.at(cell) != null:
		message.emit("Town landmarks stay in the world. Inspect the hatch to restore or withdraw supplies.")
		return false
	var entity = at(cell)
	if entity == null or not in_reach(cell): return false
	if entity.health < entity.max_health():
		message.emit("Repair damaged structures before reclaiming them [H].")
		return false
	var returns: Dictionary = entity.inventory.contents.duplicate()
	for item in entity.output.contents: returns[item] = int(returns.get(item, 0)) + entity.output.count(item)
	returns[entity.kind] = int(returns.get(entity.kind, 0)) + 1
	if not entity.carried.is_empty(): returns[entity.carried] = int(returns.get(entity.carried, 0)) + 1
	if not player.exchange({}, returns):
		message.emit("Inventory full. Empty it before reclaiming.")
		return false
	by_kind[entity.kind].erase(entity.id)
	entities.erase(entity.id)
	occupancy.erase(cell)
	changed.emit()
	return true

func craft(recipe_id: String) -> bool:
	return Crafting.enqueue(self, recipe_id, 1)

func craft_many(recipe_id: String, count: int) -> bool:
	return Crafting.enqueue(self, recipe_id, count)

func craft_maximum(recipe_id: String) -> int:
	return Crafting.maximum(self, recipe_id)

func cancel_craft_job(id: int) -> bool:
	return Crafting.cancel(self, id)

func cancel_all_crafts() -> bool:
	return Crafting.cancel_all(self)

func transfer_item(item: String, quantity: int, source: Dictionary, target: Dictionary, token: int = 0) -> int:
	return Transfers.execute(self, item, quantity, source, target, token)

func transfer_limit(item: String, source: Dictionary, target: Dictionary, token: int = 0) -> int:
	return int(Transfers.inspect(self, item, source, target, token).limit)

func collect_output(cell: Vector2i) -> void:
	var entity = at(cell)
	if entity == null: return
	if entity.kind == "inserter":
		if entity.carried != "": transfer_item(entity.carried, 0, {"kind": "hand", "entity_id": entity.id}, {"kind": "player"})
		return
	var kind := "input" if entity.kind in ["chest", "belt", "fast_belt", "turret"] else "output"
	var storage = entity.inventory if kind == "input" else entity.output
	for item in storage.contents.keys(): transfer_item(item, 0, {"kind": kind, "entity_id": entity.id}, {"kind": "player"})

func take_all(cell: Vector2i) -> void:
	var entity = at(cell)
	if entity == null or not in_reach(cell): return
	for storage in [entity.output, entity.inventory]:
		for item in storage.contents.keys():
			var moved: int = storage.move_to(player, item, storage.count(item))
			record("collected:" + item, moved)
	changed.emit()

func deposit(cell: Vector2i, item: String, amount: int = 5) -> void:
	var entity = at(cell)
	if entity == null or not in_reach(cell) or not Catalog.ITEMS.has(item): return
	if not accepts(entity, item):
		message.emit("This machine does not accept " + Catalog.item_name(item) + ".")
		return
	var limit := amount
	if entity.kind not in ["chest", "belt", "fast_belt"]: limit = mini(amount, maxi(0, 10 - entity.inventory.count(item)))
	var moved: int = player.move_to(entity.inventory, item, limit)
	if entity.kind == "furnace": record("fed:" + item, moved)
	message.emit("Inserted %d %s." % [moved, Catalog.item_name(item)])
	changed.emit()

func cancel_craft() -> void:
	if craft_queue.is_empty(): return
	Crafting.cancel(self, int(craft_queue.back().id))

func supply(cell: Vector2i) -> void:
	var entity = at(cell)
	if entity == null or not in_reach(cell): return
	if entity.kind == "chest":
		var stacked := 0
		for item in entity.inventory.contents.keys():
			if player.count(item) > 0: stacked += transfer_item(item, 0, {"kind": "player"}, {"kind": "input", "entity_id": entity.id})
		message.emit("Stacked %d matching items. Drag an item into the chest to store a new type." % stacked)
		changed.emit()
		return
	var accepted := 0
	for item in Catalog.ITEMS:
		if accepts(entity, item):
			var moved: int = player.move_to(entity.inventory, item, mini(5, maxi(0, 10 - entity.inventory.count(item))))
			accepted += moved
			if entity.kind == "furnace": record("fed:" + item, moved)
	message.emit("Supplied %d items." % accepted)
	changed.emit()

func cycle_recipe(cell: Vector2i) -> void:
	var entity = at(cell)
	if entity == null or not in_reach(cell): return
	var recipes: Array = Catalog.BUILDINGS[entity.kind].get("recipes", []).filter(func(id): return unlocked(Catalog.RECIPES[id]) and content_available(id))
	if recipes.size() < 2: return
	set_recipe(cell, recipes[(recipes.find(entity.recipe) + 1) % recipes.size()])

func set_recipe(cell: Vector2i, recipe_id: String) -> bool:
	var entity = at(cell)
	if entity == null or not in_reach(cell): return false
	if recipe_id not in Catalog.BUILDINGS[entity.kind].get("recipes", []) or not unlocked(Catalog.RECIPES[recipe_id]) or not content_available(recipe_id): return false
	if entity.recipe == recipe_id: return true
	var refund: Dictionary = entity.inventory.contents.duplicate()
	if Catalog.BUILDINGS[entity.kind].get("fuel", false): refund.erase("coal")
	if not player.exchange({}, refund):
		message.emit("Inventory full.")
		return false
	entity.inventory.exchange(refund, {})
	entity.recipe = recipe_id
	entity.progress = 0
	changed.emit()
	return true

func accepts(entity: RefCounted, item: String) -> bool:
	if entity.kind == "settlement_port": return settlements.receiving_limit(entity.id, item) > 0
	if entity.health <= 0: return false
	if entity.kind == "turret": return item == "ammo" and entity.inventory.count(item) < 10
	if entity.kind in ["belt", "fast_belt", "chest"]: return true
	if entity.kind == "lab": return item == "science" and researched.size() < Catalog.TECHNOLOGIES.size()
	if item == "coal" and Catalog.BUILDINGS[entity.kind].get("fuel", false): return entity.inventory.count("coal") < 10
	if not entity.recipe.is_empty(): return Catalog.RECIPES[entity.recipe]["in"].has(item) and entity.inventory.count(item) < 10
	return false

func transfer_source(entity: RefCounted):
	return entity.inventory if entity.kind in ["belt", "fast_belt", "chest"] else entity.output

func solid(cell: Vector2i) -> bool:
	var entity = at(cell)
	return settlements.at(cell) != null or (entity != null and entity.health > 0 and Catalog.BUILDINGS[entity.kind].solid)

func damage_structure(cell: Vector2i, damage: int) -> void:
	if damage <= 0: return
	var target = settlements.at(cell)
	if target != null and not target.repaired: return
	if target == null: target = at(cell)
	if target == null: return
	target.health = maxi(0, target.health - damage)
	if target.kind != "settlement_port" and target.health == 0: target.status = "Disabled — repair with H"

func repair_at(cell: Vector2i) -> bool:
	if not in_reach(cell):
		message.emit("Walk closer to repair this structure.")
		return false
	var target = settlements.at(cell)
	if target != null and not target.repaired:
		message.emit("Restore this landmark through Town projects first.")
		return false
	if target == null: target = at(cell)
	if target == null or target.health >= target.max_health(): return false
	if defense.occupied(cell) or (target.kind != "settlement_port" and Catalog.BUILDINGS[target.kind].solid and Rect2(Vector2(cell), Vector2.ONE).grow(0.22).has_point(player_position)):
		message.emit("Clear the damaged tile before repairing.")
		return false
	if player.remove("repair_kit") != 1:
		message.emit("Craft a repair kit first (C).")
		return false
	target.health = mini(target.max_health(), target.health + 50)
	structure_repaired.emit(cell)
	if target.kind != "settlement_port": target.status = "Repaired"
	if defense.phase == "recovery" and settlements.sites.town_hall.health == settlements.sites.town_hall.max_health(): defense.phase = "idle"
	message.emit("Repaired: %d / %d health." % [target.health, target.max_health()])
	changed.emit()
	return true

func logistics_receiver(cell: Vector2i):
	var entity = at(cell)
	return entity if entity != null else settlements.receiver(cell)

func burner_fuel_duration() -> int:
	return 80 + settlements.effect("burner_ticks")

func _site_in_reach(id: String) -> bool:
	if not settlements.enabled or not settlements.sites.has(id): return false
	if not in_reach(settlements.sites[id].port()):
		message.emit("Walk within %.0f tiles of the marked delivery hatch." % interaction_reach())
		return false
	return true

func supply_site(id: String) -> void:
	if not _site_in_reach(id): return
	var site = settlements.sites[id]
	var definition: Dictionary = Settlements.Definitions.SITES[id]
	var wanted: Dictionary = definition.repair
	if site.repaired:
		if site.health == 0:
			message.emit("This landmark is disabled. Repair it with kits [H].")
			return
		if not definition.has("contract"):
			message.emit("This project is complete. Its regional bonus is active.")
			return
		wanted = Settlements.Definitions.CONTRACTS[definition.contract].goods
	var moved := 0
	for item in wanted:
		var amount: int = mini(int(wanted[item]), settlements.receiving_limit(id, item))
		moved += player.move_to(site.inventory, item, amount)
	message.emit("Delivered %d items to %s." % [moved, definition.name])
	changed.emit()

func restore_site(id: String) -> bool:
	if not _site_in_reach(id): return false
	var reason: String = settlements.restore(id)
	if not reason.is_empty():
		message.emit(reason)
		return false
	message.emit("Restored: " + Settlements.Definitions.SITES[id].name + ". " + Settlements.Definitions.SITES[id].reward)
	changed.emit()
	return true

func withdraw_site(id: String) -> void:
	if not _site_in_reach(id): return
	var site = settlements.sites[id]
	var moved := 0
	for item in site.inventory.contents.keys(): moved += site.inventory.move_to(player, item, site.inventory.count(item))
	message.emit("Retrieved %d unused items. Goods in a dispatched shipment stay committed." % moved)
	changed.emit()

func move_player() -> void:
	previous_position = player_position
	var movement := move_direction.limit_length(1.0) * movement_speed() * TICK_SECONDS
	for i in range(4):
		var step := movement / 4
		var next := player_position + Vector2(step.x, 0)
		if _walkable(next): player_position = next
		next = player_position + Vector2(0, step.y)
		if _walkable(next): player_position = next

func _walkable(position: Vector2) -> bool:
	for offset in [Vector2(-0.22, -0.22), Vector2(0.22, -0.22), Vector2(-0.22, 0.22), Vector2(0.22, 0.22)]:
		if solid(Vector2i((position + offset).floor())): return false
	return true
