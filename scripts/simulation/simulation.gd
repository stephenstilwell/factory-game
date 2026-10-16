extends RefCounted
## Fixed phase order is part of the save/replay contract.
## Belts resolve from a snapshot; inserters reserve an item in their hand.

const Catalog = preload("res://scripts/data/catalog.gd")
const Supply = preload("res://scripts/simulation/supply_service.gd")
const Transport = preload("res://scripts/simulation/transport.gd")
const World = preload("res://scripts/simulation/world.gd")

static func step(world: RefCounted) -> void:
	world.ticks += 1
	Transport.step(world)
	world.metrics.prune(world.ticks)
	Supply.step(world)
	world.early.step(world)
	_machines(world)
	_inserters(world)
	world.combat.step(world)
	world.defense.step(world)
	world.settlements.step(world)
	_player(world)
	world.guidance.observe(world)
	if world.ticks % 5 == 0: world.frontier.observe(world)
	if world.ticks % 5 == 0: world.changed.emit()

static func _machines(world: RefCounted) -> void:
	for kind in ["drill", "furnace", "assembler", "lab", "watermill", "charcoal_kiln"]:
		for id in world.by_kind[kind]:
			var entity = world.entities[id]
			if entity.health <= 0:
				entity.status = "Disabled — repair with H"
				continue
			if kind == "watermill" and not world.early.near_water(entity.cell):
				entity.status = "Needs the old watercourse"
				continue
			if kind == "lab":
				_lab(world, entity)
				continue
			if kind == "drill":
				# Burner drills have a built-in chute; other machines need inserters.
				var target = world.at(entity.cell + World.DIRS[entity.direction])
				if target != null and target.kind in Catalog.TRANSPORT and entity.output.total() > 0:
					entity.output.move_to(target.inventory, entity.output.contents.keys()[0])
				var deposit: Dictionary = world.terrain.tile(entity.cell)
				if deposit.is_empty():
					entity.status = "Deposit depleted"
					continue
				if entity.output.total() >= entity.output.capacity:
					entity.status = "Output full"
					continue
				if not _fuel(world, entity): continue
				entity.status = "Mining " + Catalog.item_name(deposit.item)
				entity.progress += 1
				if entity.progress >= 15:
					entity.progress = 0
					var item: String = world.terrain.mine(entity.cell)
					entity.output.add(item)
					_record(world, item, 1)
					world.record("extracted:" + item)
					world.award_automation("mine:" + item, "mining", 100)
					world.skills.commission(world, "mine:" + item, "mining")
				continue
			var recipe: Dictionary = Catalog.RECIPES[entity.recipe]
			if not entity.inventory.has_all(recipe["in"]):
				entity.status = "Missing ingredients"
				continue
			if not entity.output.can_exchange({}, recipe["out"]):
				entity.status = "Output full"
				continue
			if kind == "furnace" and not _fuel(world, entity): continue
			entity.status = "Working"
			entity.progress += 1
			if entity.progress >= int(recipe.ticks):
				entity.inventory.exchange(recipe["in"], {})
				world.metrics.consume(world.ticks, recipe["in"])
				world.award_automation("line:" + entity.recipe, "fabrication", 120)
				world.skills.commission(world, "line:" + entity.recipe, "fabrication")
				entity.output.exchange({}, recipe["out"])
				entity.progress = 0
				if kind == "watermill": world.early.sawn += int(recipe["out"].get("plank", 0))
				if kind == "charcoal_kiln": world.early.charcoal += int(recipe["out"].get("coal", 0))
				for item in recipe["out"]:
					_record(world, item, int(recipe["out"][item]))
					world.record(("smelted:" if kind == "furnace" else "assembled:") + item, int(recipe["out"][item]))

static func _fuel(world: RefCounted, entity: RefCounted) -> bool:
	if entity.burn_ticks <= 0:
		if entity.inventory.remove("coal") == 0:
			entity.status = "No fuel - insert coal"
			return false
		world.metrics.record(world.ticks, "used", "coal", 1)
		entity.burn_ticks = world.burner_fuel_duration()
	entity.burn_ticks -= 1
	return true

static func _inserters(world: RefCounted) -> void:
	for id in world.by_kind.inserter:
		var entity = world.entities[id]
		if entity.health <= 0: continue
		if entity.cooldown > 0:
			entity.cooldown -= 1
			continue
		var direction: Vector2i = World.DIRS[entity.direction]
		var target = world.logistics_receiver(entity.cell + direction)
		if target == null:
			entity.status = "No drop target"
			continue
		if not entity.carried.is_empty():
			if world.accepts(target, entity.carried) and target.inventory.add(entity.carried) == 1:
				if target.kind == "chest": world.record("stored:" + entity.carried)
				entity.carried = ""
				entity.cooldown = 2
				entity.status = "Returning"
			else: entity.status = "Drop target blocked"
			continue
		var source = world.at(entity.cell - direction)
		if source == null:
			entity.status = "No pickup source"
			continue
		var storage = world.transfer_source(source)
		entity.status = "Waiting for items"
		for item in storage.contents.keys():
			if not world.accepts(target, item) or target.inventory.total() >= target.inventory.capacity: continue
			storage.remove(item)
			entity.carried = item
			entity.cooldown = 2
			entity.status = "Carrying " + Catalog.item_name(item)
			break

static func _lab(world: RefCounted, entity: RefCounted) -> void:
	var id: String = world.current_research()
	if id.is_empty():
		entity.status = "Choose a workshop project [T]" if world.researched.size() < Catalog.TECHNOLOGIES.size() else "All projects complete"
		return
	world.research_target = id
	if entity.inventory.count("science") == 0:
		entity.status = "Needs engineering dossiers"
		return
	entity.status = "Researching " + Catalog.technology(id).name
	entity.progress += 1
	if entity.progress < 30: return
	entity.progress = 0
	entity.inventory.remove("science")
	world.metrics.record(world.ticks, "used", "science", 1)
	world.research_progress += 1
	var technology: Dictionary = Catalog.technology(id)
	if world.research_progress >= int(technology.cost):
		world.researched.append(id)
		world.record("researched:" + id)
		world.research_progress = 0
		world.research_target = ""
		world.feedback_requested.emit("success", Vector2i(world.player_position.floor()))
		world.message.emit("Research complete: %s. Unlocked %s." % [technology.name, technology.unlock])

static func _player(world: RefCounted) -> void:
	world.move_player()
	world.skills.observe(world)
	if not world.craft_queue.is_empty():
		var entry: Dictionary = world.craft_queue[0]
		if int(entry.remaining) > 0:
			var work: int = int(entry.get("work", 0)) + world.skills.work_units("fabrication") + world.craft_credit
			world.craft_credit = maxi(0, work - int(entry.remaining) * 100)
			entry.remaining = maxi(0, int(entry.remaining) - work / 100)
			entry.work = work % 100 if int(entry.remaining) > 0 else 0
		var recipe: Dictionary = Catalog.RECIPES[entry.recipe]
		if entry.remaining == 0 and world.player.exchange({}, recipe["out"]):
			for item in recipe["out"]:
				_record(world, item, int(recipe["out"][item]))
				world.record("crafted:" + item, int(recipe["out"][item]))
			world.metrics.consume(world.ticks, recipe["in"])
			world.craft_queue.pop_front()
			if world.craft_queue.is_empty(): world.craft_credit = 0
			world.feedback_requested.emit("craft", Vector2i(world.player_position.floor()))
			world.award_skill("fabrication", int(world.Skills.Definitions.CRAFT_XP.get(entry.recipe, 0)))
	if not world.mining or not world.in_reach(world.mining_cell) or world.at(world.mining_cell) != null or world.settlements.at(world.mining_cell) != null:
		world.mining_progress = 0
		return
	var forage: Dictionary = world.early.resource_at(world, world.mining_cell)
	if not forage.is_empty():
		if world.player.total() >= world.player.capacity:
			world.mining_progress = 0
			return
		world.mining_progress += world.skills.work_units("mining")
		if world.mining_progress >= (300 if world.player.count("stone_axe") > 0 else 600):
			world.early.gather(world, world.mining_cell)
			world.mining_progress = 0
		return
	var deposit: Dictionary = world.terrain.tile(world.mining_cell)
	if world.early.active() and not deposit.is_empty() and deposit.item != "stone":
		world.mining_progress = 0
		return
	if deposit.is_empty():
		if world.frontier.tree_at(world, world.mining_cell):
			if world.early.enabled and not world.player.can_exchange({}, {"timber": 4}):
				world.mining_progress = 0
				return
			world.mining_progress += world.skills.work_units("mining") if world.early.enabled else 100
			if world.mining_progress >= 600:
				if world.frontier.clear_tree(world, world.mining_cell) and world.early.enabled:
					world.player.add("timber", 4)
					world.early.produced(world, "timber", 4)
					world.award_skill("mining", 6)
				world.mining_progress = 0
		else: world.mining_progress = 0
		return
	if world.player.total() >= world.player.capacity:
		world.mining_progress = 0
		return
	world.mining_progress += world.skills.work_units("mining")
	if world.mining_progress >= world.mining_duration() * 100:
		world.mining_progress -= world.mining_duration() * 100
		var item: String = world.terrain.mine(world.mining_cell)
		world.player.add(item)
		_record(world, item, 1)
		world.record("mined:" + item)
		world.hand_resource_extracted.emit(world.mining_cell, item)
		world.award_skill("mining", int(world.Skills.Definitions.MINING_XP.get(item, 0)))

static func _record(world: RefCounted, item: String, amount: int) -> void:
	world.production[item] = int(world.production.get(item, 0)) + amount
	world.metrics.record(world.ticks, "made", item, amount)
	world.record("produced:" + item, amount)
