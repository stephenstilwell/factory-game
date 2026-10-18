extends RefCounted
## Authoritative state and commands. No scene tree, drawing, input, or file access.

const Catalog = preload("res://scripts/data/catalog.gd")
const Inventory = preload("res://scripts/model/inventory.gd")
const Entity = preload("res://scripts/model/entity.gd")
const Terrain = preload("res://scripts/model/terrain.gd")
const Onboarding = preload("res://scripts/simulation/onboarding.gd")
const TownServices = preload("res://scripts/simulation/town_services.gd")
const Settlements = preload("res://scripts/simulation/settlements.gd")
const Transfers = preload("res://scripts/simulation/inventory_transfers.gd")
const Crafting = preload("res://scripts/simulation/crafting.gd")
const Character = preload("res://scripts/model/character_progression.gd")
const Skills = preload("res://scripts/model/skills.gd")
const Transport = preload("res://scripts/simulation/transport.gd")
const Metrics = preload("res://scripts/model/production_metrics.gd")
const Plans = preload("res://scripts/simulation/construction_plans.gd")
const Early = preload("res://scripts/model/early_progression.gd")
const Frontier = preload("res://scripts/model/frontier.gd")
const Guidance = preload("res://scripts/model/player_guidance.gd")
const Story = preload("res://scripts/simulation/story_state.gd")
const PlayerCombat = preload("res://scripts/model/player_combat.gd")
const Defense = preload("res://scripts/simulation/defense.gd")
const DIRS := [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]
const TICK_SECONDS := 0.1

signal defense_won(wave: int)
signal chapter_progressed(stage: int)
signal technology_completed(id: String)
signal hand_craft_completed(recipe_id: String, delivered: Dictionary)
signal equipment_upgraded(id: String, rank: int)
signal settlement_restored(id: String)
signal region_restored(id: String)
signal changed
signal message(text: String)
signal skill_progressed(id: String, amount: int, level: int, leveled: bool)
signal hand_resource_extracted(cell: Vector2i, item: String)
signal structure_repaired(cell: Vector2i)
signal feedback_requested(cue: String, cell: Vector2i)
signal story_requested(chapter: String)

var terrain: RefCounted
var character: RefCounted
var skills: RefCounted
var player: RefCounted
var guide: RefCounted
var settlements: RefCounted
var combat := PlayerCombat.new()
var navigation_revision := 0
var defense: RefCounted
var orchard_project := preload("res://scripts/simulation/orchard_project.gd").new()
var quarry_project := preload("res://scripts/simulation/quarry_project.gd").new()
var navigation := preload("res://scripts/model/navigation.gd").new()
var exploration := preload("res://scripts/model/exploration.gd").new()
var frontier := Frontier.new()
var early := Early.new()
var guidance := Guidance.new()
var story := Story.new()
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
var research_target := "logistics"
var research_banks: Dictionary = {}
var automation_awards: Dictionary = {}
var metrics := Metrics.new()
var home := preload("res://scripts/model/player_home.gd").new()
var power := preload("res://scripts/simulation/power_grid.gd").new()
var plans := Plans.new()
var craft_queue: Array = []
var craft_credit := 0 # Earned work carried only between queued jobs.
var next_craft_id := 1
var mining_cell := Vector2i.ZERO
var mining_progress := 0 # Hundredths of a work tick, avoiding fractional drift.
var mining := false

func _init(world_seed: int = 74103) -> void:
	message.connect(_remember_message)
	terrain = Terrain.new(world_seed)
	character = Character.new()
	skills = Skills.new()
	player = Inventory.new()
	guide = Onboarding.new()
	settlements = Settlements.new()
	defense = Defense.new()
	for kind in Catalog.BUILDINGS: by_kind[kind] = []

func _remember_message(text: String) -> void:
	guidance.remember(text, ticks)

func start() -> void:
	# A new game has no possessions or construction. All content must be earned.
	terrain = Terrain.new(terrain.seed_value)
	character = Character.new()
	skills = Skills.new()
	player.capacity = int(character.stat("inventory_capacity"))
	player.contents.clear()
	entities.clear()
	occupancy.clear()
	for kind in by_kind: by_kind[kind].clear()
	guide = Onboarding.new()
	guide.enabled = true
	early = Early.new()
	early.enabled = true
	settlements = Settlements.new(true)
	defense = Defense.new()
	combat = PlayerCombat.new()
	navigation_revision += 1
	home = preload("res://scripts/model/player_home.gd").new()
	power = preload("res://scripts/simulation/power_grid.gd").new()
	orchard_project = preload("res://scripts/simulation/orchard_project.gd").new()
	quarry_project = preload("res://scripts/simulation/quarry_project.gd").new()
	navigation = preload("res://scripts/model/navigation.gd").new()
	exploration = preload("res://scripts/model/exploration.gd").new()
	frontier = Frontier.new()
	guidance = Guidance.new()
	story = Story.new()
	story.fresh()
	player_position = Vector2(24.5, 12.5)
	previous_position = player_position
	move_direction = Vector2.ZERO
	next_id = 1
	ticks = 0
	production.clear()
	researched.clear()
	research_progress = 0
	research_target = "logistics"
	research_banks.clear()
	automation_awards.clear()
	metrics = Metrics.new()
	plans = Plans.new()
	craft_queue.clear()
	craft_credit = 0
	next_craft_id = 1
	mining = false
	mining_progress = 0
	frontier.install(self)
	changed.emit()

func content_available(id: String) -> bool:
	if id == "cottage": return home.unlocked(self)
	if not early.available(id): return false
	if id in early.Definitions.TIMBER_RECIPES or id in early.Definitions.STONE_RECIPES: return true
	if id == "fuel_depot": return guide.available("chest")
	if id in ["wall", "repair_kit"]: return settlements.enabled and settlements.sites.trading_post.repaired
	if id in ["turret", "ammo", "service_rifle", "marksman_rifle", "cannon_turret", "pulse_turret", "reinforced_wall"]: return settlements.enabled and settlements.sites.workshop.repaired
	if id in ["splitter", "underground_belt", "construction_kit"]: return guide.available("assembler")
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

func survey_radius() -> int:
	return skills.survey_radius() + int(character.stat("survey_bonus")) + (1 if frontier.claimed("camp") else 0)

func mining_duration() -> int:
	return int(character.stat("mining_ticks"))

func upgrade_character(id: String, expected_rank: int) -> bool:
	return character.purchase(self, id, expected_rank)

func award_skill(id: String, amount: int) -> void:
	var reward: Dictionary = skills.gain(id, amount)
	if reward.is_empty(): return
	var leveled: bool = reward.level > reward.previous
	skill_progressed.emit(id, int(reward.amount), int(reward.level), leveled)
	if leveled:
		var extra := ""
		if skills.bonus_percent(id, reward.level) > skills.bonus_percent(id, reward.previous): extra = " Reward: +%d%% %s speed total." % [skills.bonus_percent(id), "movement" if id == "exploration" else "hand-work"]
		if id == "exploration" and ((reward.previous < 25 and reward.level >= 25) or (reward.previous < 75 and reward.level >= 75)): extra += " Survey range expanded."
		message.emit("%s level %d!%s Engineer [P] shows rewards and equipment." % [Skills.Definitions.SKILLS[id].name, reward.level, extra])

func movement_speed() -> float:
	return float(character.stat("movement_speed")) * skills.multiplier("exploration") * defense.morale_multiplier(self) * quarry_project.movement_multiplier(self)

func unlocked(definition: Dictionary) -> bool:
	return not definition.has("technology") or definition.technology in researched

func can_build(kind: String, cell: Vector2i, require_item: bool = true) -> String:
	if not Catalog.BUILDINGS.has(kind): return "Unknown building."
	if not in_reach(cell): return "Out of reach. Walk closer with WASD."
	if kind == "cottage" and not by_kind.cottage.is_empty(): return "One personal cottage per world. Pick up its entrance to move it; the interior stays saved."
	if at(cell) != null: return "Tile is occupied."
	if frontier.marsh.blocked(frontier,cell): return "Reedwater water: build the marked causeway in Discoveries [L]; ordinary buildings need dry land."
	if frontier.marsh.boardwalk(frontier,cell) and Catalog.BUILDINGS[kind].solid: return "Keep the narrow causeway open. Place solid buildings on the island or shore."
	if defense.occupied(cell): return "A construct occupies this tile."
	if settlements.at(cell) != null: return "This land belongs to a settlement project."
	if frontier.at(cell) != "": return "This land belongs to a frontier landmark."
	if not unlocked(Catalog.BUILDINGS[kind]): return "Research " + Catalog.technology(Catalog.BUILDINGS[kind].technology).name + " first."
	if not content_available(kind): return "Follow the current learning objective to discover this building."
	if require_item and player.count(kind) == 0: return "Craft more %s (C)." % Catalog.item_name(kind)
	if Catalog.BUILDINGS[kind].solid and Rect2(Vector2(cell), Vector2.ONE).grow(0.22).has_point(player_position): return "Move away from the construction tile."
	if kind == "watermill" and not early.near_water(cell): return "Place the sawmill beside the old watercourse south near (24, 28)."
	if kind == "drill" and terrain.tile(cell).is_empty(): return "Drills require a resource deposit."
	return ""

func build(kind: String, cell: Vector2i, direction: int, exit_mode: bool = false) -> bool:
	var reason := can_build(kind, cell)
	if not reason.is_empty():
		message.emit(reason)
		return false
	frontier.clear_tree(self, cell, false)
	player.remove(kind)
	metrics.record(ticks, "used", kind, 1)
	var entity = spawn(kind, cell, direction)
	entity.underground_exit = exit_mode if kind == "underground_belt" else false
	plans.forget(cell)
	record("placed:" + kind)
	feedback_requested.emit("build", cell)
	changed.emit()
	return true

func spawn(kind: String, cell: Vector2i, direction: int):
	var entity = Entity.new(next_id, kind, cell, direction)
	next_id += 1
	register(entity)
	return entity

func register(entity: RefCounted) -> void:
	navigation_revision += 1
	entities[entity.id] = entity
	occupancy[entity.cell] = entity.id
	by_kind[entity.kind].append(entity.id)

func _reclaim_returns(entity: RefCounted) -> Dictionary:
	var returns: Dictionary = entity.inventory.contents.duplicate()
	for item in entity.output.contents: returns[item] = int(returns.get(item, 0)) + entity.output.count(item)
	if entity.electric_mode:
		for item in power.COST: returns[item] = int(returns.get(item, 0)) + int(power.COST[item])
	returns[entity.kind] = int(returns.get(entity.kind, 0)) + 1
	if not entity.carried.is_empty(): returns[entity.carried] = int(returns.get(entity.carried, 0)) + 1
	return returns

func reclaim_reason(cell: Vector2i) -> String:
	if settlements.at(cell) != null:
		return "Town landmarks stay in the world. Inspect the hatch to restore or withdraw supplies."
	var entity = at(cell)
	if entity == null: return "There is no building to pick up here."
	if not in_reach(cell): return "Walk closer to pick up this building."
	if entity.health < entity.max_health(): return "Repair damaged structures before reclaiming them [H]."
	if not player.can_exchange({}, _reclaim_returns(entity)): return "Inventory full. Make room for the building and its contents."
	return ""

func reclaim(cell: Vector2i) -> bool:
	var reason := reclaim_reason(cell)
	if not reason.is_empty():
		message.emit(reason)
		return false
	var entity = at(cell)
	if not player.exchange({}, _reclaim_returns(entity)): return false
	by_kind[entity.kind].erase(entity.id)
	entities.erase(entity.id)
	occupancy.erase(cell)
	navigation_revision += 1
	message.emit("Picked up " + Catalog.item_name(entity.kind) + " and its stored items.")
	feedback_requested.emit("pickup", cell)
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
	var kind := "input" if entity.kind in (["chest", "cart_post", "fuel_depot", "generator"] + Catalog.Combat.TURRETS.keys() + Catalog.TRANSPORT) else "output"
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
	if entity.kind not in (["chest", "cart_post"] + Catalog.TRANSPORT): limit = mini(amount, maxi(0, input_limit(entity, item) - entity.inventory.count(item)))
	var moved: int = player.move_to(entity.inventory, item, limit)
	if entity.kind == "furnace": record("fed:" + item, moved)
	combat.sync_carried(self)
	message.emit("Inserted %d %s." % [moved, Catalog.item_name(item)])
	changed.emit()

func cancel_craft() -> void:
	if craft_queue.is_empty(): return
	Crafting.cancel(self, int(craft_queue.back().id))

func supply(cell: Vector2i) -> void:
	var entity = at(cell)
	if entity == null or not in_reach(cell): return
	if entity.kind == "lumber_camp":
		frontier.forestry.replant(self, entity)
		return
	if entity.kind == "communal_hearth":
		early.advance(self)
		return
	if entity.kind in ["chest", "cart_post"]:
		var stacked := 0
		for item in entity.inventory.contents.keys():
			if player.count(item) > 0: stacked += transfer_item(item, 0, {"kind": "player"}, {"kind": "input", "entity_id": entity.id})
		message.emit("Stacked %d matching items. Drag an item into the chest to store a new type." % stacked)
		changed.emit()
		return
	if entity.kind in ["fuel_depot", "generator"]:
		transfer_item("coal", 0, {"kind": "player"}, {"kind": "input", "entity_id": entity.id})
		return
	var accepted := 0
	for item in Catalog.ITEMS:
		if accepts(entity, item):
			var moved: int = player.move_to(entity.inventory, item, mini(5, maxi(0, input_limit(entity, item) - entity.inventory.count(item))))
			accepted += moved
			if entity.kind == "furnace": record("fed:" + item, moved)
	combat.sync_carried(self)
	message.emit("Supplied %d items." % accepted)
	if accepted > 0: feedback_requested.emit("transfer", cell)
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
	feedback_requested.emit("transfer", cell)
	changed.emit()
	return true

func input_limit(entity: RefCounted, item: String) -> int:
	if entity.kind == "cart_post": return 100
	if entity.kind == "generator": return 50 if item == "coal" else 0
	if entity.kind == "fuel_depot": return 200 if item == "coal" else 0
	if item == "coal" and not entity.electric_mode and Catalog.BUILDINGS[entity.kind].get("fuel", false): return 10
	if not entity.recipe.is_empty(): return maxi(10, int(Catalog.RECIPES[entity.recipe]["in"].get(item, 0)) * 2)
	return 10

func set_underground_exit(cell: Vector2i, enabled: bool) -> bool:
	var entity = at(cell)
	if entity == null or entity.kind != "underground_belt" or not in_reach(cell): return false
	entity.underground_exit = enabled
	changed.emit()
	return true

func research_available(id: String) -> bool:
	var definition: Dictionary = Catalog.technology(id)
	if definition.is_empty() or id in researched: return false
	for required in definition.requires:
		if required not in researched: return false
	return true

func current_research() -> String:
	if research_available(research_target): return research_target
	return ""

func select_research(id: String) -> bool:
	if not research_available(id) or not content_available("lab"): return false
	var previous := current_research()
	if previous == id: return true
	if not previous.is_empty() and research_progress > 0: research_banks[previous] = research_progress
	research_target = id
	research_progress = int(research_banks.get(id, 0))
	research_banks.erase(id)
	changed.emit()
	return true

func award_automation(key: String, skill: String, xp_amount: int) -> void:
	if automation_awards.has(key): return
	automation_awards[key] = true
	award_skill(skill, xp_amount)
	message.emit("Automation milestone! +%d %s XP. Your factory is doing the work." % [xp_amount, Skills.Definitions.SKILLS[skill].name])

func accepts(entity: RefCounted, item: String) -> bool:
	if entity.kind == "marsh_port": return frontier.marsh.receiving_limit(self,item) > 0
	if entity.kind == "orchard_port": return orchard_project.receiving_limit(self, item) > 0
	if entity.kind == "regional_port": return quarry_project.receiving_limit(self, item) > 0
	if entity.kind == "generator": return entity.health > 0 and item == "coal" and entity.inventory.count("coal") < 50
	if entity.kind == "fuel_depot": return entity.health > 0 and item == "coal" and entity.inventory.count("coal") < 200
	if entity.kind == "settlement_port": return settlements.receiving_limit(entity.id, item, self) > 0
	if entity.health <= 0: return false
	if Catalog.Combat.TURRETS.has(entity.kind): return item == "ammo" and entity.inventory.count(item) < 10
	if entity.kind in (Catalog.TRANSPORT + ["chest", "cart_post"]): return true
	if entity.kind == "lab": return item == "science" and not current_research().is_empty()
	if item == "coal" and not entity.electric_mode and Catalog.BUILDINGS[entity.kind].get("fuel", false): return entity.inventory.count("coal") < 10
	if not entity.recipe.is_empty(): return Catalog.RECIPES[entity.recipe]["in"].has(item) and entity.inventory.count(item) < input_limit(entity, item)
	return false

func transfer_source(entity: RefCounted):
	if entity.kind in ["orchard_port","marsh_port"]: return entity.output
	return entity.inventory if entity.kind in (Catalog.TRANSPORT + ["chest", "cart_post", "fuel_depot", "generator"]) else entity.output

func solid(cell: Vector2i) -> bool:
	var entity = at(cell)
	return frontier.marsh.blocked(frontier,cell) or settlements.at(cell) != null or frontier.blocks(cell) or (entity != null and entity.health > 0 and Catalog.BUILDINGS[entity.kind].solid)

func damage_structure(cell: Vector2i, damage: int) -> void:
	if damage <= 0: return
	var target = settlements.at(cell)
	if target != null and not target.repaired: return
	if target == null: target = at(cell)
	if target == null: return
	var previous_health: int = target.health
	target.health = maxi(0, target.health - damage)
	if defense.phase == "active": defense.costs.damage += previous_health-target.health
	if previous_health > 0 and target.health == 0: navigation_revision += 1
	if target.health != previous_health: feedback_requested.emit("damage", cell)
	if target.kind != "settlement_port" and target.health == 0: target.status = "Disabled — repair with H"

func repair_power() -> int:
	return roundi(float(character.stat("repair_power"))*(1.25 if frontier.marsh.restored else 1.0))

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
	if defense.phase == "active": defense.costs.kits += 1
	if target.health == 0: navigation_revision += 1
	target.health = mini(target.max_health(), target.health + repair_power())
	structure_repaired.emit(cell)
	if target.kind != "settlement_port": target.status = "Repaired"
	if defense.phase == "recovery" and settlements.sites.town_hall.health == settlements.sites.town_hall.max_health(): defense.phase = "idle"
	message.emit("Repaired: %d / %d health." % [target.health, target.max_health()])
	changed.emit()
	return true

func logistics_receiver(cell: Vector2i):
	var entity = at(cell)
	if entity != null: return entity
	if frontier.sites.has("marsh") and cell == frontier.port("marsh"): return frontier.marsh
	if frontier.sites.has("quarry") and cell == frontier.port("quarry"): return quarry_project
	if frontier.sites.has("orchard") and cell == frontier.port("orchard"): return orchard_project
	return settlements.receiver(cell)

func logistics_source(cell: Vector2i):
	var entity = at(cell)
	if entity != null: return entity
	if frontier.sites.has("marsh") and cell == frontier.port("marsh"): return frontier.marsh
	return orchard_project if frontier.sites.has("orchard") and cell == frontier.port("orchard") else null

func burner_fuel_duration() -> int:
	return Catalog.FUEL_TICKS + settlements.effect("burner_ticks")

func supply_radius() -> int:
	return 8 + mini(4, defense.cleared / 2) + frontier.hearth_bonus(self) if settlements.enabled and settlements.services_online() else 8

func _site_in_reach(id: String) -> bool:
	if not settlements.enabled or not settlements.sites.has(id): return false
	if not in_reach(settlements.sites[id].port()):
		message.emit("Walk within %.0f tiles of the marked delivery hatch." % interaction_reach())
		return false
	return true

func supply_site(id: String) -> void:
	if early.active():
		message.emit("Supply your communal shelter through Town [Y] first. Rebuild the crossing before restoring the industrial landmarks.")
		return
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
	if moved > 0: feedback_requested.emit("transfer", site.port())
	changed.emit()

func request_story(chapter: String) -> void:
	if story.available(self, chapter) and not story.seen.has(chapter): story_requested.emit(chapter)

func talk_to_site(id: String) -> bool:
	if not settlements.enabled or not Story.Definitions.NPCS.has(id): return false
	if not in_reach(story.npc_cell(self, id)) and not in_reach(settlements.sites[id].port()):
		message.emit("Walk closer to " + Story.Definitions.NPCS[id].name + " to talk.")
		return false
	var chapter: String = story.conversation(self, id)
	if chapter.is_empty(): return false
	story_requested.emit(chapter)
	return true

func restore_site(id: String) -> bool:
	if early.active():
		message.emit("Rebuild the crossing through Town [Y] before restoring this industrial landmark.")
		return false
	if not _site_in_reach(id): return false
	var reason: String = settlements.restore(id)
	if not reason.is_empty():
		message.emit(reason)
		return false
	message.emit("Restored: " + Settlements.Definitions.SITES[id].name + ". " + Settlements.Definitions.SITES[id].reward)
	if id == "trading_post" and frontier.claimed("orchard"): message.emit("Iona can restore growing beds at the Lost Orchard. Discoveries [L] shows costs, supplies and produce trading.")
	if id == "trading_post" and frontier.claimed("quarry"): message.emit("Greybank roadbuilders need stone and planks. Discoveries [L] shows shipments, rewards and the quarry hatch.")
	feedback_requested.emit("success", settlements.sites[id].port())
	settlement_restored.emit(id)
	changed.emit()
	request_story(Story.Definitions.NPCS[id].after)
	return true

func withdraw_site(id: String) -> void:
	if not _site_in_reach(id): return
	var site = settlements.sites[id]
	var moved := 0
	for item in site.inventory.contents.keys(): moved += site.inventory.move_to(player, item, site.inventory.count(item))
	message.emit("Retrieved %d unused items. Goods in a dispatched shipment stay committed." % moved)
	changed.emit()

func move_player() -> void:
	exploration.reveal(player_position)
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
