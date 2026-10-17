extends RefCounted
## Decode into a new world and validate before replacing live state.
## v1 is imported on request; the original save is never overwritten.

const World = preload("res://scripts/simulation/world.gd")
const Entity = preload("res://scripts/model/entity.gd")
const Catalog = preload("res://scripts/data/catalog.gd")
const SettlementSave = preload("res://scripts/persistence/settlement_save.gd")
const DefenseSave = preload("res://scripts/persistence/defense_save.gd")
const PATH := "user://factory_save_v2.json"
const LEGACY_PATH := "user://factory_save.json"
const MAX_ENTITIES := 50000

static func encode(world: RefCounted) -> Dictionary:
	var records: Array = []
	var ids: Array = world.entities.keys()
	ids.sort()
	for id in ids: records.append(world.entities[id].serialize())
	var depletion: Array = []
	for cell in world.terrain.depleted:
		depletion.append([cell.x, cell.y, world.terrain.depleted[cell]])
	return {"version": 2, "seed": world.terrain.seed_value, "terrain_generator": world.terrain.generator_version, "resource_scale": world.terrain.stock_scale, "ticks": world.ticks, "next_id": world.next_id,
		"player": world.player.contents.duplicate(), "character": world.character.serialize(), "skills": world.skills.serialize(), "position": [world.player_position.x, world.player_position.y],
		"orchard_project": world.orchard_project.serialize(), "quarry_project": world.quarry_project.serialize(), "navigation": world.navigation.serialize(), "exploration": world.exploration.serialize(), "entities": records, "depletion": depletion, "production": world.production.duplicate(), "defense": world.defense.serialize(), "combat": world.combat.serialize(), "story": world.story.serialize(), "guidance": world.guidance.serialize(), "frontier": world.frontier.serialize(), "early": world.early.serialize(),
		"researched": world.researched.duplicate(), "research_progress": world.research_progress, "research_target": world.current_research(), "research_banks": world.research_banks.duplicate(), "automation_awards": world.automation_awards.duplicate(), "plans": world.plans.serialize(),
		"craft_queue": world.craft_queue.duplicate(true), "next_craft_id": world.next_craft_id, "craft_credit": world.craft_credit, "onboarding": world.guide.serialize(), "settlements": world.settlements.serialize()}

static func save_world(world: RefCounted, path: String = PATH) -> String:
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null: return "Could not write save: " + error_string(FileAccess.get_open_error())
	file.store_string(JSON.stringify(encode(world)))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK: return "Save write failed: " + error_string(write_error)
	# Keep the previous successful save as a backup before replacing the slot.
	if FileAccess.file_exists(path):
		var previous := load_world(path)
		# Never rotate a damaged primary over a usable backup.
		var destination := path + ".bak"
		if not previous.get("error", "").is_empty():
			destination = path + ".damaged.%d.%d" % [int(Time.get_unix_time_from_system()), Time.get_ticks_usec()]
		var backup_error := DirAccess.copy_absolute(path, destination)
		if backup_error != OK: return "Could not preserve the previous save. Current files were left unchanged."
	var result := DirAccess.rename_absolute(temporary, path)
	return "" if result == OK else "Could not commit save: " + error_string(result)

static func load_world(path: String = PATH) -> Dictionary:
	var source := path
	if path == PATH and not FileAccess.file_exists(path) and FileAccess.file_exists(LEGACY_PATH): source = LEGACY_PATH
	if not FileAccess.file_exists(source): return {"error": "No saved factory yet."}
	var file := FileAccess.open(source, FileAccess.READ)
	if file == null: return {"error": "Could not read save: " + error_string(FileAccess.get_open_error())}
	if file.get_length() > 16000000: return {"error": "Save exceeds size limit."}
	var document := JSON.new()
	if document.parse(file.get_as_text()) != OK: return {"error": "Save is not valid JSON."}
	return decode(document.data)

static func _integer(value, minimum: int = 0, maximum: int = 2000000000) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value)) and value >= minimum and value <= maximum

static func _inventory(data, capacity: int) -> bool:
	if not data is Dictionary: return false
	var total := 0
	for item in data:
		if not Catalog.ITEMS.has(item) or not _integer(data[item], 1, capacity): return false
		total += int(data[item])
	return total <= capacity

static func _cell(data: Dictionary) -> bool:
	return _integer(data.get("x"), -1000000, 1000000) and _integer(data.get("y"), -1000000, 1000000)

static func _counts(data: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key in data: result[key] = int(data[key])
	return result

static func _restore_guide(world: RefCounted, data) -> bool:
	if not data is Dictionary or not data.get("enabled") is bool or not data.get("counters") is Dictionary or not data.get("completed") is Array: return false
	if data.counters.size() > 512 or data.completed.size() > world.guide.STAGES.size(): return false
	for key in data.counters:
		if not key is String or not _integer(data.counters[key], 1): return false
		var parts: PackedStringArray = key.split(":")
		if parts.size() != 2: return false
		if parts[0] == "researched":
			if Catalog.technology(parts[1]).is_empty(): return false
		elif parts[0] not in ["mined", "crafted", "placed", "fed", "collected", "extracted", "smelted", "assembled", "stored", "produced"] or not Catalog.ITEMS.has(parts[1]): return false
	if not data.get("timber_opening", false) is bool: return false
	world.guide.timber_opening = data.get("timber_opening", false)
	world.guide.enabled = data.enabled
	world.guide.counters = _counts(data.counters)
	for i in range(data.completed.size()):
		var stage: Dictionary = world.guide.stage_at(i)
		if data.completed[i] != stage.id or not world.guide.satisfied(stage): return false
	world.guide.completed = data.completed.duplicate()
	if world.guide.enabled and not world.guide.current().is_empty() and world.guide.satisfied(world.guide.current()): return false
	return true

static func decode(data) -> Dictionary:
	if not data is Dictionary: return {"error": "Invalid save document."}
	if data.get("version") == 1: return _legacy(data)
	if data.get("version") != 2: return {"error": "Unsupported save version."}
	if not _integer(data.get("seed"), -2000000000) or not _integer(data.get("ticks")) or not _integer(data.get("next_id"), 1): return {"error": "Invalid world metadata."}
	var character := World.Character.new()
	if data.has("character") and not character.restore(data.character): return {"error": "Invalid engineer upgrades."}
	if not _inventory(data.get("player"), int(character.stat("inventory_capacity"))): return {"error": "Invalid player inventory."}
	var position = data.get("position")
	if not position is Array or position.size() != 2: return {"error": "Invalid player position."}
	for coordinate in position:
		if not (coordinate is float or coordinate is int) or not is_finite(float(coordinate)) or absf(float(coordinate)) > 1000000: return {"error": "Invalid player position."}
	if not data.get("entities") is Array or data.entities.size() > MAX_ENTITIES: return {"error": "Invalid entity list."}
	var world = World.new(int(data.seed))
	world.character = character
	world.player.capacity = int(character.stat("inventory_capacity"))
	if not _integer(data.get("terrain_generator", 1), 1, World.Terrain.GENERATOR_VERSION): return {"error": "Unsupported terrain generator."}
	world.terrain.generator_version = int(data.get("terrain_generator", 1))
	var saved_scale = data.get("resource_scale", 1)
	if not _integer(saved_scale, 1, 4) or int(saved_scale) not in [1, 4]: return {"error": "Invalid resource richness."}
	if data.has("skills") and not world.skills.restore(data.skills, world.terrain): return {"error": "Invalid skill progress."}
	world.player.contents = _counts(data.player)
	world.player_position = Vector2(float(position[0]), float(position[1]))
	world.previous_position = world.player_position
	if not world.exploration.restore(data.get("exploration", [])): return {"error": "Invalid exploration chart."}
	if not world.navigation.restore(data.get("navigation", {})): return {"error": "Invalid map pins."}
	world.ticks = int(data.ticks)
	world.metrics.start_tick = world.ticks
	world.next_id = int(data.next_id)
	if data.has("early") and not world.early.restore(world, data.early): return {"error": "Invalid early settlement progression."}
	# Older v2 saves had no guide. Preserve their unrestricted progression and layout.
	if data.has("onboarding") and not _restore_guide(world, data.onboarding): return {"error": "Invalid learning progress."}
	if data.has("settlements") and not SettlementSave.restore(world, data.settlements): return {"error": "Invalid settlement economy."}
	var research = data.get("researched")
	if not research is Array or research.size() > Catalog.TECHNOLOGIES.size(): return {"error": "Invalid research."}
	for id in research:
		if not id is String or not world.research_available(id): return {"error": "Invalid technology prerequisites."}
		world.researched.append(id)
	var legacy_target := ""
	for definition in Catalog.TECHNOLOGIES:
		if world.research_available(definition.id):
			legacy_target = definition.id
			break
	var target = data.get("research_target", legacy_target)
	if not target is String or (not target.is_empty() and not world.research_available(target)): return {"error": "Invalid research target."}

	world.research_target = target
	var banks = data.get("research_banks", {})
	if not banks is Dictionary or banks.size() > Catalog.TECHNOLOGIES.size(): return {"error": "Invalid research investments."}
	for id in banks:
		if id == target or not world.research_available(id) or not _integer(banks[id], 1, int(Catalog.technology(id).cost) - 1): return {"error": "Invalid research investment."}
	world.research_banks = _counts(banks)
	var awards = data.get("automation_awards", {})
	if not awards is Dictionary or awards.size() > 128: return {"error": "Invalid automation milestones."}
	var allowed_awards: Array = []
	for id in Catalog.RECIPES: allowed_awards.append("line:" + id)
	for id in World.Terrain.RESOURCE_IDS: allowed_awards.append("mine:" + id)
	for site_id in world.settlements.sites:
		for threshold in world.skills.Definitions.DELIVERY_MILESTONES: allowed_awards.append("delivery:%s:%d" % [site_id, threshold])
	for threshold in [3, 6, 9]: allowed_awards.append("delivery:town_hall:%d" % threshold)
	for threshold in [3, 6, 9]: allowed_awards.append("greybank:road:%d" % threshold)
	for key in awards:
		if key not in allowed_awards or not awards[key] is bool or awards[key] != true: return {"error": "Invalid automation milestone."}
	world.automation_awards = awards.duplicate()

	var research_limit: int = int(Catalog.technology(world.research_target).cost) - 1 if not world.research_target.is_empty() else 0
	if not _integer(data.get("research_progress"), 0, research_limit): return {"error": "Invalid research progress."}
	world.research_progress = int(data.research_progress)
	for record in data.entities:
		if not record is Dictionary or not _cell(record) or not _integer(record.get("id"), 1, world.next_id - 1): return {"error": "Invalid entity coordinates or ID."}
		if not Catalog.BUILDINGS.has(record.get("kind")) or not _integer(record.get("direction"), 0, 3): return {"error": "Unknown building or direction."}
		var entity = Entity.new(int(record.id), record.kind, Vector2i(int(record.x), int(record.y)), int(record.direction))
		if world.entities.has(entity.id) or world.at(entity.cell) != null: return {"error": "Duplicate entity ID or tile."}
		if not _inventory(record.get("inventory"), entity.inventory.capacity) or not _inventory(record.get("output"), entity.output.capacity): return {"error": "Invalid machine inventory."}
		var recipes: Array = Catalog.BUILDINGS[entity.kind].get("recipes", [])
		if (recipes.is_empty() and record.get("recipe") != "") or (not recipes.is_empty() and record.get("recipe") not in recipes): return {"error": "Invalid machine recipe."}
		entity.recipe = record.recipe
		if not record.get("electric_mode", false) is bool or not _integer(record.get("energy", 0), 0, world.power.FUEL_ENERGY): return {"error": "Invalid electrical state."}
		entity.electric_mode = record.get("electric_mode", false)
		entity.energy = int(record.get("energy", 0))
		if entity.electric_mode and (not world.power.LOAD.has(entity.kind) or "metallurgy" not in world.researched): return {"error": "Invalid electric drive."}
		if entity.kind == "power_pole" and ("metallurgy" not in world.researched or not record.inventory.is_empty() or not record.output.is_empty()): return {"error": "Invalid district pole."}
		if entity.kind != "generator" and entity.energy != 0: return {"error": "Energy stored outside a generator."}
		if entity.kind == "generator" and ("metallurgy" not in world.researched or record.inventory.keys().any(func(item): return item != "coal") or not record.output.is_empty()): return {"error": "Invalid dynamo state."}
		if not _integer(record.get("health", entity.max_health()), 0, entity.max_health()) or not _integer(record.get("attack_cooldown", 0), 0, int(Catalog.Combat.TURRETS.get(entity.kind, {"cooldown": 0}).cooldown)): return {"error": "Invalid structure health or combat timer."}
		entity.health = int(record.get("health", entity.max_health()))
		entity.attack_cooldown = int(record.get("attack_cooldown", 0))
		if not _integer(record.get("routing_cursor", 0), 0, 1) or not _integer(record.get("merge_cursor", 0)) or not record.get("underground_exit", false) is bool: return {"error": "Invalid transport state."}
		if not _integer(record.get("supply_cursor", 0), 0, world.next_id - 1) or (entity.kind != "fuel_depot" and record.get("supply_cursor", 0) != 0): return {"error": "Invalid hearth state."}
		entity.supply_cursor = int(record.get("supply_cursor", 0))
		entity.routing_cursor = int(record.get("routing_cursor", 0))
		entity.merge_cursor = int(record.get("merge_cursor", 0))
		entity.underground_exit = record.get("underground_exit", false)
		if entity.kind != "splitter" and entity.routing_cursor != 0: return {"error": "Invalid splitter state."}
		if entity.kind not in Catalog.TRANSPORT and entity.merge_cursor != 0: return {"error": "Invalid merge state."}
		if entity.kind != "underground_belt" and entity.underground_exit: return {"error": "Invalid tunnel state."}
		if not Catalog.Combat.TURRETS.has(entity.kind) and entity.attack_cooldown != 0: return {"error": "Invalid turret timer."}
		if not entity.recipe.is_empty() and not world.unlocked(Catalog.RECIPES[entity.recipe]): return {"error": "Recipe is not researched."}
		var duration: int = int(Catalog.RECIPES[entity.recipe].ticks) if not entity.recipe.is_empty() else (30 if entity.kind == "lab" else int(Catalog.BUILDINGS[entity.kind].get("work_ticks", 15)))
		var fuel_limit: int = (288 if world.settlements.sites.workshop.repaired else Catalog.FUEL_TICKS) + world.settlements.district_level() * 12
		if not _integer(record.get("progress"), 0, duration - 1) or not _integer(record.get("burn_ticks"), 0, fuel_limit) or not _integer(record.get("cooldown"), 0, 2): return {"error": "Invalid machine timers."}
		if not record.get("carried") is String or (record.carried != "" and (entity.kind != "inserter" or not Catalog.ITEMS.has(record.carried))): return {"error": "Invalid inserter hand."}
		if entity.kind == "fuel_depot" and (record.inventory.keys().any(func(item): return item != "coal") or not record.output.is_empty()): return {"error": "Invalid hearth contents."}
		entity.inventory.contents = _counts(record.inventory)
		entity.output.contents = _counts(record.output)
		entity.progress = int(record.progress)
		entity.burn_ticks = int(record.burn_ticks)
		entity.cooldown = int(record.cooldown)
		entity.carried = record.carried
		world.register(entity)
	for kind in world.by_kind: world.by_kind[kind].sort()
	if data.has("settlements"):
		if not SettlementSave.place_pending(world): return {"error": "No vacant land for the Town Hall."}
		if not SettlementSave.valid_layout(world): return {"error": "Settlement footprints overlap occupied land."}
	elif not world.settlements.install_legacy(world): return {"error": "No vacant land for new settlement projects."}
	if not data.get("depletion") is Array or data.depletion.size() > 100000: return {"error": "Invalid resource depletion."}
	for entry in data.depletion:
		if not entry is Array or entry.size() != 3: return {"error": "Invalid resource tile."}
		if not _integer(entry[0], -1000000, 1000000) or not _integer(entry[1], -1000000, 1000000) or not _integer(entry[2], 0, 1000000): return {"error": "Invalid resource amounts."}
		var cell := Vector2i(int(entry[0]), int(entry[1]))
		var deposit: Dictionary = world.terrain.tile(cell)
		if world.terrain.depleted.has(cell) or deposit.is_empty() or int(entry[2]) * (4 / int(saved_scale)) > int(deposit.amount): return {"error": "Invalid resource override."}
		world.terrain.depleted[cell] = int(entry[2]) * (4 / int(saved_scale))
	if not data.get("production") is Dictionary: return {"error": "Invalid production counters."}
	for item in data.production:
		if not Catalog.ITEMS.has(item) or not _integer(data.production[item]): return {"error": "Invalid production statistic."}
	world.production = _counts(data.production)
	if not data.get("craft_queue") is Array or data.craft_queue.size() > 20: return {"error": "Invalid craft queue."}
	var job_ids: Dictionary = {}
	var maximum_job_id := 0
	for entry in data.craft_queue:
		if not entry is Dictionary or not Catalog.RECIPES.has(entry.get("recipe")): return {"error": "Invalid queued recipe."}
		var recipe: Dictionary = Catalog.RECIPES[entry.recipe]
		if not recipe.get("hand", false) or not world.unlocked(recipe) or not _integer(entry.get("remaining"), 0, int(recipe.get("ticks", 5))): return {"error": "Invalid queued crafting state."}
		var job_id = entry.get("id", maximum_job_id + 1)
		if not _integer(job_id, 1) or job_ids.has(int(job_id)): return {"error": "Invalid crafting job identity."}
		job_ids[int(job_id)] = true
		maximum_job_id = maxi(maximum_job_id, int(job_id))
		var work = entry.get("work", 0)
		if not _integer(work, 0, 99) or (int(entry.remaining) == 0 and work != 0): return {"error": "Invalid queued crafting work."}
		world.craft_queue.append({"id": int(job_id), "recipe": entry.recipe, "remaining": int(entry.remaining), "work": int(work)})
	if not _integer(data.get("next_craft_id", maximum_job_id + 1), maximum_job_id + 1): return {"error": "Invalid next crafting job ID."}
	world.next_craft_id = int(data.get("next_craft_id", maximum_job_id + 1))
	if not _integer(data.get("craft_credit", 0), 0, 124) or (world.craft_queue.is_empty() and data.get("craft_credit", 0) != 0): return {"error": "Invalid carried crafting work."}
	world.craft_credit = int(data.get("craft_credit", 0))
	if data.has("combat") and not world.combat.restore(data.combat, world): return {"error": "Invalid engineer combat state."}
	if data.has("defense") and not DefenseSave.restore(world, data.defense): return {"error": "Invalid beacon defense state."}
	if data.has("frontier"):
		if not world.frontier.restore(world, data.frontier): return {"error": "Invalid frontier discoveries."}
		world.frontier.add_missing_sites(world)
	elif world.settlements.enabled: world.frontier.install(world)
	if not world.early.enabled and world.settlements.age == 1 and (not world.frontier.claimed("orchard") or not world.frontier.claimed("quarry")): return {"error": "Invalid town age discoveries."}
	if world.early.enabled:
		if world.settlements.age != world.early.phase or not world.guide.timber_opening: return {"error": "Town age and opening disagree."}
		if world.early.phase == 2 and not world.frontier.claimed("quarry"): return {"error": "The crossing lacks its mason pattern."}
		if world.early.sawn > int(world.production.get("plank", 0)) or world.early.charcoal > int(world.production.get("coal", 0)) or world.early.delivered > int(world.production.get("timber", 0)): return {"error": "Opening counters exceed actual production."}
		if world.early.active():
			if not world.researched.is_empty(): return {"error": "Research predates the crossing."}
			for site in world.settlements.sites.values():
				if site.repaired: return {"error": "Industrial restoration predates the crossing."}
		for entity in world.entities.values():
			if not world.early.available(entity.kind): return {"error": "Building predates its civic age."}
			if entity.kind == "watermill" and not world.early.near_water(entity.cell): return {"error": "Watermill is not beside its watercourse."}
	elif world.guide.timber_opening: return {"error": "Missing timber opening."}
	for entity in world.entities.values():
		if entity.kind in world.early.Definitions.BUILDINGS and not world.early.enabled: return {"error": "Primitive building lacks its world extension."}
	for job in world.craft_queue:
		if not world.early.available(job.recipe): return {"error": "Queued recipe predates its civic age."}
	if not character.valid_progress(world): return {"error": "Engineer upgrades lack required progression."}
	for wave in world.settlements.relief_waves:
		if wave > world.defense.cleared: return {"error": "Relief reward lacks a completed defense."}
	if data.has("story") and not world.story.restore(data.story, world): return {"error": "Invalid story journal."}
	if data.has("guidance") and not world.guidance.restore(data.guidance, world.ticks): return {"error": "Invalid player goals or notices."}
	if data.has("plans") and not world.plans.restore(data.plans, world): return {"error": "Invalid construction plans."}
	if not world.orchard_project.restore(world, data.get("orchard_project", {})): return {"error": "Invalid orchard gardens."}
	if not world.quarry_project.restore(world, data.get("quarry_project", {})): return {"error": "Invalid Greybank road project."}
	return {"world": world, "error": "", "frontier_added": not data.has("frontier") and world.frontier.enabled}

static func _legacy(data: Dictionary) -> Dictionary:
	if not data.get("buildings") is Array or not data.get("items") is Array or data.buildings.size() > MAX_ENTITIES: return {"error": "Invalid legacy save."}
	if not _integer(data.get("credits")) or not _integer(data.get("delivered")): return {"error": "Invalid legacy counters."}
	var world = World.new()
	world.player.add("iron_plate", mini(1000, int(data.credits) / 4))
	world.production["iron_plate"] = int(data.delivered)
	var kinds := ["belt", "drill", "furnace", "chest"]
	for record in data.buildings:
		if not record is Dictionary or not _cell(record) or not record.get("machine") is Dictionary: return {"error": "Invalid legacy building."}
		var machine: Dictionary = record.machine
		if not _integer(machine.get("kind"), 0, 3) or not _integer(machine.get("dir"), 0, 3): return {"error": "Invalid legacy machine."}
		var cell := Vector2i(int(record.x), int(record.y))
		if world.at(cell) != null: return {"error": "Duplicate legacy tile."}
		var entity = world.spawn(kinds[int(machine.kind)], cell, int(machine.dir))
		if entity.kind in ["drill", "furnace"]: entity.inventory.add("coal", 10)
		if entity.kind == "furnace" and _integer(machine.get("ore", 0), 0, 5): entity.inventory.add("iron_ore", int(machine.get("ore", 0)))
	for record in data.items:
		if not record is Dictionary or not _cell(record) or record.get("item") not in ["ore", "plate"]: return {"error": "Invalid legacy item."}
		var entity = world.at(Vector2i(int(record.x), int(record.y)))
		if entity == null: continue
		var storage = world.transfer_source(entity)
		storage.add("iron_ore" if record.item == "ore" else "iron_plate")
	if not world.settlements.install_legacy(world): return {"error": "No vacant land for settlement projects."}
	world.frontier.install(world)
	return {"world": world, "error": "", "legacy": true}

static func describe(path: String, allow_legacy: bool = false) -> Dictionary:
	var source := path
	if allow_legacy and path == PATH and not FileAccess.file_exists(path) and FileAccess.file_exists(LEGACY_PATH): source = LEGACY_PATH
	var info := {"path": source, "exists": FileAccess.file_exists(source), "valid": false, "summary": "No saved game yet."}
	if not info.exists: return info
	var result := load_world(source)
	if not result.get("error", "").is_empty():
		info.summary = "Cannot load: " + result.error
		return info
	var world: RefCounted = result.world
	var seconds := int(world.ticks * World.TICK_SECONDS)
	var date := Time.get_datetime_string_from_unix_time(FileAccess.get_modified_time(source)).replace("T", " ")
	var chapter: String = world.early.Definitions.NAMES[world.early.phase] if world.early.enabled else "Industrial factory"
	info.valid = true
	info.summary = "%s UTC\n%s / World time %dh %02dm\n%d buildings / Seed %d" % [date, chapter, seconds / 3600, (seconds / 60) % 60, world.entities.size(), world.terrain.seed_value]
	return info
