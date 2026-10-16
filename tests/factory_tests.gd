extends SceneTree

const FrontierTests = preload("res://tests/frontier_tests.gd")
const ProgressionGuidanceTests = preload("res://tests/progression_guidance_tests.gd")
const PacingTests = preload("res://tests/pacing_tests.gd")
const CombatTests = preload("res://tests/combat_tests.gd")
const PresentationTests = preload("res://tests/presentation_tests.gd")
const ExpansionTests = preload("res://tests/expansion_tests.gd")
const World = preload("res://scripts/simulation/world.gd")
const Simulation = preload("res://scripts/simulation/simulation.gd")
const Inventory = preload("res://scripts/model/inventory.gd")
const Terrain = preload("res://scripts/model/terrain.gd")
const SaveService = preload("res://scripts/persistence/save_service.gd")
const Fixtures = preload("res://tests/fixtures.gd")
const SettlementTests = preload("res://tests/settlement_tests.gd")
const InventoryUXTests = preload("res://tests/inventory_ux_tests.gd")
const TerrainGenerationTests = preload("res://tests/terrain_generation_tests.gd")
const CharacterTests = preload("res://tests/character_tests.gd")
const SkillTests = preload("res://tests/skill_tests.gd")
const StoryTests = preload("res://tests/story_tests.gd")
const HotbarTests = preload("res://tests/hotbar_tests.gd")
const AudioTests = preload("res://tests/audio_tests.gd")
const DefenseTests = preload("res://tests/defense_tests.gd")

var failures := 0
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + description)

func advance(world: RefCounted, count: int) -> void:
	for i in range(count): Simulation.step(world)

func _run() -> void:
	FrontierTests.run(self)
	ProgressionGuidanceTests.run(self)
	PacingTests.run(self)
	ExpansionTests.run(self)
	_inventory()
	_terrain()
	TerrainGenerationTests.run(self)
	CharacterTests.run(self)
	SkillTests.run(self)
	DefenseTests.run(self)
	CombatTests.run(self)
	_construction()
	_transport()
	_production()
	_progression()
	_onboarding()
	_persistence()
	SettlementTests.run(self)
	InventoryUXTests.models(self)
	await AudioTests.run(self)
	await HotbarTests.run(self)
	await StoryTests.run(self)
	await ExpansionTests.ui(self)
	await PresentationTests.run(self)
	await CombatTests.ui(self)
	await FrontierTests.ui(self)
	await ProgressionGuidanceTests.ui(self)
	await PacingTests.ui(self)
	await _scene_smoke()
	await InventoryUXTests.ui(self)
	print("Factory verification: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func _inventory() -> void:
	var source := Inventory.new(5)
	var destination := Inventory.new(2)
	check(source.add("iron_ore", 8) == 5, "Inventory caps additions")
	check(not source.exchange({"iron_ore": 6}, {"iron_plate": 1}) and source.count("iron_ore") == 5, "Failed exchange is atomic")
	check(not source.exchange({}, {"coal": 1}), "Full inventory rejects exchange")
	check(source.move_to(destination, "iron_ore", 4) == 2 and source.count("iron_ore") == 3, "Partial transfer preserves items")
	check(source.remove("iron_ore", -5) == 0, "Negative removal cannot create items")
	check(source.exchange({"iron_ore": 3}, {"iron_plate": 2}) and source.total() == 2, "Recipe exchange commits as one transaction")

func _terrain() -> void:
	var a := Terrain.new(74103)
	var b := Terrain.new(74103)
	for cell in [Vector2i(14, 16), Vector2i(28, 23), Vector2i(9, 23), Vector2i(26, 9), Vector2i(-33, -19)]:
		check(a.tile(cell) == b.tile(cell), "Terrain generation is reproducible at " + str(cell))
	check(a.chunk_at(Vector2i(-1, -17)) == Vector2i(-1, -2), "Negative chunk coordinates use floor division")
	var cell := Vector2i(14, 16)
	var amount: int = a.tile(cell).amount
	var correct_items := true
	for i in range(amount): correct_items = (a.mine(cell) == "iron_ore") and correct_items
	check(correct_items, "Every extraction returns the correct resource")
	check(a.mine(cell) == "" and a.tile(cell).is_empty(), "Deposit eventually exhausts")
	a.chunks.clear()
	check(a.tile(cell).is_empty(), "Depletion survives chunk cache eviction")

func _construction() -> void:
	var world := World.new()
	world.player_position = Vector2(4.5, 4.5)
	world.player.add("drill", 1)
	world.player.add("chest", 2)
	check(not world.build("drill", Vector2i(5, 4), 0) and world.player.count("drill") == 1, "Invalid construction does not spend items")
	check(not world.build("chest", Vector2i(20, 20), 0), "Construction has an interaction radius")
	check(not world.build("chest", Vector2i(4, 4), 0), "Construction cannot trap engineer inside a machine")
	check(world.build("chest", Vector2i(5, 4), 0), "Construction consumes building item")
	var chest = world.at(Vector2i(5, 4))
	chest.inventory.add("iron_plate", 12)
	world.player.capacity = world.player.total()
	check(not world.reclaim(chest.cell) and world.at(chest.cell) != null, "Full pack prevents destructive reclaim")
	world.player.capacity = 10000
	check(world.reclaim(chest.cell) and world.player.count("iron_plate") == 12 and world.player.count("chest") == 2, "Reclaim returns building and all inventory")
	world.spawn("furnace", Vector2i(5, 4), 0)
	world.move_direction = Vector2.RIGHT
	advance(world, 20)
	check(world.player_position.x < 4.8, "Engineer collides with machine body")
	world.player_position = Vector2(14.5, 17.5)
	world.move_direction = Vector2.ZERO
	world.mining_cell = Vector2i(14, 16)
	world.mining = true
	advance(world, 8)
	check(world.player.count("iron_ore") == 1, "Engineer hand mining produces physical ore")

func _transport() -> void:
	var world := World.new()
	var a = world.spawn("belt", Vector2i(0, 0), 0)
	var b = world.spawn("belt", Vector2i(1, 0), 0)
	var c = world.spawn("belt", Vector2i(2, 0), 0)
	a.inventory.add("iron_ore")
	world.ticks = 1
	Simulation.step(world)
	check(b.inventory.count("iron_ore") == 1 and c.inventory.total() == 0, "Belt item moves at most one cell per tick")
	a.inventory.add("coal")
	world.ticks = 3
	Simulation.step(world)
	check(a.inventory.count("coal") == 1 and c.inventory.count("iron_ore") == 1, "Snapshot congestion cannot overwrite or chain items")
	var side = world.spawn("belt", Vector2i(1, -1), 1)
	side.inventory.add("stone")
	world.ticks = 5
	Simulation.step(world)
	check(b.inventory.total() == 1 and a.inventory.total() + side.inventory.total() == 1, "Competing belts reserve one destination without loss")
	var direct := World.new()
	var belt = direct.spawn("belt", Vector2i(0, 0), 0)
	var furnace = direct.spawn("furnace", Vector2i(1, 0), 0)
	belt.inventory.add("iron_ore")
	advance(direct, 10)
	check(belt.inventory.total() == 1 and furnace.inventory.total() == 0, "Machines need inserters rather than direct belt ingestion")
	var logistics := World.new()
	var source = logistics.spawn("chest", Vector2i(0, 0), 0)
	var arm = logistics.spawn("inserter", Vector2i(1, 0), 0)
	var target = logistics.spawn("chest", Vector2i(2, 0), 0)
	source.inventory.add("iron_plate", 2)
	Simulation.step(logistics)
	check(arm.carried == "iron_plate" and source.inventory.count("iron_plate") == 1, "Inserter hand reserves an actual item")
	target.inventory.add("stone", 200)
	advance(logistics, 10)
	check(arm.carried == "iron_plate" and target.inventory.count("iron_plate") == 0, "Blocked drop retains carried item")
	logistics.player_position = Vector2(1.5, 2.5)
	logistics.reclaim(arm.cell)
	check(logistics.player.count("iron_plate") == 1, "Reclaiming a loaded inserter returns its hand")
	var faster := World.new()
	var fast = faster.spawn("fast_belt", Vector2i(0, 0), 0)
	var next = faster.spawn("fast_belt", Vector2i(1, 0), 0)
	fast.inventory.add("coal")
	Simulation.step(faster)
	check(next.inventory.count("coal") == 1, "Fast belt advances on ticks when ordinary belts wait")

func _production() -> void:
	var world := World.new()
	var drill = world.spawn("drill", Vector2i(14, 16), 0)
	drill.inventory.add("coal")
	var before: int = world.terrain.tile(drill.cell).amount
	advance(world, 150)
	var first_batch: int = drill.output.remove("iron_ore", 10)
	advance(world, 150)
	check(first_batch + drill.output.count("iron_ore") == 16 and drill.status.begins_with("No fuel"), "One coal gives finite drill work, then stops")
	check(world.terrain.tile(drill.cell).amount == before - 16, "Drilling depletes matching deposit amount")
	var furnace = world.spawn("furnace", Vector2i(20, 20), 0)
	furnace.inventory.add("iron_ore", 2)
	advance(world, 40)
	check(furnace.output.total() == 0 and furnace.inventory.count("iron_ore") == 2, "Furnace needs fuel and preserves waiting inputs")
	furnace.inventory.add("coal")
	advance(world, 64)
	check(furnace.output.count("iron_plate") == 2 and furnace.inventory.count("iron_ore") == 0, "Smelting obeys recipe quantities and timing")
	furnace.output.add("iron_plate", 8)
	furnace.inventory.add("iron_ore")
	var fuel: int = furnace.burn_ticks
	advance(world, 40)
	check(furnace.status == "Output full" and furnace.inventory.count("iron_ore") == 1 and furnace.burn_ticks == fuel, "Backpressure preserves ingredients and stored energy")
	var demo := Fixtures.demo()
	advance(demo, 700)
	var chest = demo.at(Vector2i(24, 15))
	check(chest.inventory.count("iron_plate") >= 15, "Starter drill/belt/inserter/furnace/chest line works end to end")
	var assembler = world.spawn("assembler", Vector2i(22, 20), 0)
	assembler.recipe = "wire"
	assembler.inventory.add("copper_plate", 2)
	advance(world, 10)
	check(assembler.output.count("wire") == 4, "Assembler supports multi-output recipes")
	check(not world.accepts(assembler, "iron_ore"), "Inserter acceptance rejects wrong recipe inputs")
	world.player_position = Vector2(22.5, 22.5)
	assembler.inventory.add("copper_plate", 3)
	world.cycle_recipe(assembler.cell)
	check(assembler.recipe == "science" and world.player.count("copper_plate") == 3, "Recipe change returns unused inputs")
	world.player.add("iron_ore", 5)
	world.deposit(assembler.cell, "iron_ore")
	check(world.player.count("iron_ore") == 5 and assembler.inventory.count("iron_ore") == 0, "Manual insertion obeys machine input filters")

func _progression() -> void:
	var world := World.new()
	world.player.add("iron_plate", 10)
	check(world.craft("gear") and world.player.count("iron_plate") == 8 and world.player.count("gear") == 0, "Handcraft reserves ingredients before producing output")
	world.cancel_craft()
	check(world.player.count("iron_plate") == 10 and world.craft_queue.is_empty(), "Craft cancellation refunds reserved ingredients")
	world.craft("gear")
	advance(world, 10)
	check(world.player.count("gear") == 1, "Queued craft completes at its recipe duration")
	var crowded := World.new()
	crowded.player.capacity = 2
	crowded.player.add("iron_plate")
	crowded.craft("belt")
	crowded.player.add("stone", 2)
	advance(crowded, 10)
	check(crowded.craft_queue.size() == 1 and crowded.player.count("belt") == 0, "Completed craft waits when its output does not fit")
	crowded.player.remove("stone", 2)
	advance(crowded, 1)
	check(crowded.craft_queue.is_empty() and crowded.player.count("belt") == 2, "Waiting craft completes losslessly when pack has room")
	check(not world.craft("fast_belt"), "Research gates crafting recipes")
	var assembler = world.spawn("assembler", Vector2i(0, 0), 0)
	assembler.recipe = "science"
	assembler.inventory.contents = {"iron_plate": 10, "gear": 10, "copper_plate": 10}
	world.spawn("inserter", Vector2i(1, 0), 0)
	var lab = world.spawn("lab", Vector2i(2, 0), 0)
	advance(world, 500)
	check("logistics" in world.researched and world.production.get("science", 0) == 10, "Automated assembler/inserter/lab chain unlocks Logistics I")
	world.player.add("belt")
	world.player.add("gear", 2)
	check(world.craft("fast_belt"), "Research unlock enables fast conveyor recipe")
	check(world.current_research().is_empty(), "Completed project waits for an explicit next choice")
	world.select_research("metallurgy")
	lab.inventory.add("science", 20)
	advance(world, 600)
	check("metallurgy" in world.researched, "Second technology consumes 20 science packs")
	var furnace = world.spawn("furnace", Vector2i(4, 0), 0)
	furnace.recipe = "steel"
	furnace.inventory.contents = {"coal": 1, "iron_plate": 5}
	advance(world, 80)
	check(furnace.output.count("steel") == 1 and lab.status == "Choose a workshop project [T]", "Metallurgy enables steel while further research awaits science")

func _mine_for_lesson(world: RefCounted, item: String, amount: int) -> void:
	var cells := {"stone": Vector2i(26, 9), "iron_ore": Vector2i(14, 16), "coal": Vector2i(9, 23), "copper_ore": Vector2i(28, 23)}
	var center: Vector2i = cells[item]
	# Travel is shortcut here; movement/collision are verified independently.
	# The actual mining, depletion, crafting, fueling, and construction commands run.
	for unit in range(amount):
		var cell := center
		var found := false
		for radius in range(6):
			if found: break
			for x in range(-radius, radius + 1):
				if found: break
				for y in range(-radius, radius + 1):
					var candidate := center + Vector2i(x, y)
					var deposit: Dictionary = world.terrain.tile(candidate)
					if not deposit.is_empty() and deposit.item == item and world.at(candidate) == null and world.settlements.at(candidate) == null:
						cell = candidate
						found = true
						break
		world.player_position = Vector2(cell) + Vector2(1.5, 1.5)
		world.mining_cell = cell
		world.mining_progress = 0
		world.mining = true
		advance(world, 8)
	world.mining = false

func _smelt_for_lesson(world: RefCounted, furnace: RefCounted, item: String, amount: int) -> void:
	var ore := "copper_ore" if item == "copper_plate" else "iron_ore"
	_mine_for_lesson(world, ore, amount)
	_mine_for_lesson(world, "coal", maxi(2, ceili(amount * 32.0 / World.Catalog.FUEL_TICKS)))
	world.player_position = Vector2(furnace.cell) + Vector2(0.5, 2.5)
	for i in range(3):
		if furnace.recipe == item: break
		world.cycle_recipe(furnace.cell)
	var remaining := amount
	while remaining > 0:
		var batch := mini(5, remaining)
		world.deposit(furnace.cell, ore, batch)
		world.deposit(furnace.cell, "coal", 5)
		advance(world, batch * 32)
		world.take_all(furnace.cell)
		remaining -= batch

func _craft_for_lesson(world: RefCounted, id: String, count: int = 1) -> void:
	for i in range(count): check(world.craft(id), "Can craft earned " + id + " from gathered materials")
	advance(world, count * int(world.Catalog.RECIPES[id].get("ticks", 5)))

func _onboarding() -> void:
	var world := World.new()
	world.start()
	check(world.entities.is_empty() and world.occupancy.is_empty() and world.player.total() == 0, "New game has no prebuilt factory or starting inventory")
	check(world.guide.current().id == "stone" and not world.content_available("drill"), "First lesson teaches basic gathering before machines")
	check(not world.craft("gear") and world.craft_queue.is_empty(), "Undiscovered recipes cannot bypass the learning path")
	_mine_for_lesson(world, "stone", 3)
	var saved := SaveService.decode(JSON.parse_string(JSON.stringify(SaveService.encode(world))))
	check(saved.has("world") and saved.world.guide.counters.get("mined:stone") == 3 and saved.world.guide.current().id == "stone", "Partial learning progress survives JSON save/load")
	if not saved.has("world"): return
	world = saved.world
	_mine_for_lesson(world, "stone", 2)
	check(world.guide.current().id == "craft_furnace", "Five stone advances the guide")
	world.craft("furnace")
	world.cancel_craft()
	check(world.guide.current().id == "craft_furnace", "Cancelled crafting does not complete a lesson")
	_craft_for_lesson(world, "furnace")
	check(world.guide.current().id == "place_furnace" and world.player.count("stone") == 0, "First furnace is earned entirely from hand-mined stone")
	world.player_position = Vector2(19.5, 17.5)
	check(world.build("furnace", Vector2i(19, 15), 0), "First furnace can be placed without any gifted supplies")
	var furnace = world.at(Vector2i(19, 15))
	_smelt_for_lesson(world, furnace, "iron_plate", 5)
	check(world.guide.current().id == "gears" and world.player.count("iron_plate") == 5, "Raw ore and coal bootstrap to collected iron plates")
	check(world.content_available("drill") and not world.content_available("lab"), "Learning reveals the next machinery tier without exposing science early")
	_smelt_for_lesson(world, furnace, "iron_plate", 6)
	_craft_for_lesson(world, "gear", 3)
	_mine_for_lesson(world, "stone", 5)
	_craft_for_lesson(world, "drill")
	_mine_for_lesson(world, "coal", 10)
	world.player_position = Vector2(17.5, 17.5)
	check(world.build("drill", Vector2i(15, 15), 0), "First drill can be built from smelted/crafted resources")
	world.supply(Vector2i(15, 15))
	advance(world, 15)
	check(world.guide.current().id == "storage" and world.content_available("belt"), "A fueled drill introduces belt logistics")
	_smelt_for_lesson(world, furnace, "iron_plate", 9)
	_craft_for_lesson(world, "gear", 2)
	_craft_for_lesson(world, "inserter", 2)
	_craft_for_lesson(world, "belt")
	_craft_for_lesson(world, "chest")
	_mine_for_lesson(world, "coal", 10)
	world.player_position = Vector2(18.5, 17.5)
	for cell in [Vector2i(16, 15), Vector2i(17, 15)]: check(world.build("belt", cell, 0), "Earned belt placement")
	for cell in [Vector2i(18, 15), Vector2i(20, 15)]: check(world.build("inserter", cell, 0), "Earned inserter placement")
	check(world.build("chest", Vector2i(21, 15), 0), "Earned storage placement")
	world.supply(Vector2i(15, 15))
	world.supply(furnace.cell)
	advance(world, 240)
	check("storage" in world.guide.completed and world.at(Vector2i(21, 15)).inventory.count("iron_plate") >= 5, "Empty-start materials can build a working automated storage line")
	world.take_all(Vector2i(21, 15))
	world.reclaim(Vector2i(18, 15))
	world.reclaim(Vector2i(20, 15))
	_smelt_for_lesson(world, furnace, "copper_plate", 5)
	check(world.guide.current().id == "assembly", "Guide teaches copper before assemblers")
	_smelt_for_lesson(world, furnace, "copper_plate", 15)
	_smelt_for_lesson(world, furnace, "iron_plate", 80)
	_craft_for_lesson(world, "gear", 5)
	_craft_for_lesson(world, "assembler")
	world.player_position = Vector2(22.5, 18.5)
	check(world.build("assembler", Vector2i(22, 16), 0), "Assembler is earned from existing production")
	world.deposit(Vector2i(22, 16), "iron_plate", 5)
	advance(world, 10)
	check(world.content_available("science") and world.guide.current().id == "science", "An assembled gear introduces science")
	_craft_for_lesson(world, "gear", 15)
	_craft_for_lesson(world, "wire", 3)
	_craft_for_lesson(world, "science", 10)
	_craft_for_lesson(world, "lab")
	check(world.build("lab", Vector2i(24, 18), 0), "Lab is built from earned resources")
	world.supply(Vector2i(24, 18))
	world.supply(Vector2i(24, 18))
	advance(world, 300)
	check(world.guide.current().is_empty() and world.guide.completed.size() == world.guide.STAGES.size() and "logistics" in world.researched, "Entire guided opening reaches science research without free items")
	var finished := SaveService.decode(SaveService.encode(world))
	check(finished.has("world") and finished.world.guide.completed == world.guide.completed, "Completed lessons persist after materials are spent")
	var malformed := SaveService.encode(world)
	malformed.onboarding.completed.reverse()
	check(not SaveService.decode(malformed).has("world"), "Malformed milestone order is rejected")
	var old_v2 := SaveService.encode(Fixtures.demo())
	old_v2.erase("onboarding")
	var imported := SaveService.decode(old_v2)
	check(imported.has("world") and not imported.world.guide.enabled and imported.world.entities.size() == 10, "Older v2 saves keep existing factories without forced lesson gates")
	_first_settlement_from_nothing(world, furnace)

func _first_settlement_from_nothing(world: RefCounted, furnace: RefCounted) -> void:
	_smelt_for_lesson(world, furnace, "iron_plate", 30)
	_craft_for_lesson(world, "gear", 5)
	_mine_for_lesson(world, "stone", 10)
	world.player_position = Vector2(28.5, 15.5)
	world.supply_site("trading_post")
	check(world.restore_site("trading_post"), "Resource-only opening can fund and restore its first settlement landmark")
	_smelt_for_lesson(world, furnace, "iron_plate", 36)
	_craft_for_lesson(world, "gear", 6)
	world.player_position = Vector2(28.5, 15.5)
	for shipment in range(6): world.supply_site("trading_post")
	advance(world, 1800)
	check(world.settlements.credits == 60, "Player-earned production can fulfill enough contracts to pay a restoration crew")
	_smelt_for_lesson(world, furnace, "iron_plate", 30)
	_craft_for_lesson(world, "gear", 5)
	_smelt_for_lesson(world, furnace, "copper_plate", 10)
	world.player_position = Vector2(34.5, 20.5)
	world.supply_site("workshop")
	check(world.restore_site("workshop") and world.burner_fuel_duration() == 288, "Entire empty-start economy reaches its first global civic bonus without free materials or currency")
	var civic_save := SaveService.decode(JSON.parse_string(JSON.stringify(SaveService.encode(world))))
	check(civic_save.has("world") and civic_save.world.settlements.sites.workshop.repaired and civic_save.world.settlements.credits == 0, "Earned campaign restoration and spent currency persist with learning progress")

func _persistence() -> void:
	var world := Fixtures.demo()
	world.craft("gear")
	advance(world, 18)
	var hand_save := SaveService.decode(SaveService.encode(world))
	check(hand_save.has("world") and hand_save.world.at(Vector2i(18, 15)).carried == "iron_ore", "Save restores an in-flight inserter hand")
	advance(world, 59)
	world.craft("belt")
	var data := SaveService.encode(world)
	var result := SaveService.decode(JSON.parse_string(JSON.stringify(data)))
	check(result.get("error", "").is_empty() and result.has("world"), "Versioned save decodes from actual JSON")
	if not result.has("world"): return
	var restored = result.world
	check(SaveService.encode(restored) == data, "Save round trip preserves all authoritative state")
	advance(world, 350)
	advance(restored, 350)
	check(SaveService.encode(restored) == SaveService.encode(world), "Restored world continues deterministically")
	var unordered := SaveService.encode(world)
	unordered.entities.reverse()
	var reordered := SaveService.decode(unordered)
	check(reordered.has("world"), "Unordered entity records can be decoded")
	if reordered.has("world"):
		advance(world, 100)
		advance(reordered.world, 100)
		check(SaveService.encode(world) == SaveService.encode(reordered.world), "Save record order does not change simulation arbitration")
	var malformed := data.duplicate(true)
	malformed.entities[0].kind = "missing_machine"
	check(not SaveService.decode(malformed).has("world"), "Unknown machine is rejected")
	malformed = data.duplicate(true)
	malformed.player.coal = -1
	check(not SaveService.decode(malformed).has("world"), "Negative inventory quantities are rejected")
	malformed = data.duplicate(true)
	malformed.entities.append(malformed.entities[0].duplicate(true))
	check(not SaveService.decode(malformed).has("world"), "Duplicate occupancy is rejected")
	check(not SaveService.decode({"version": 999}).has("world"), "Future save versions are rejected")
	malformed = data.duplicate(true)
	malformed.research_progress = "broken"
	check(not SaveService.decode(malformed).has("world"), "Invalid timer type is rejected without mutating live state")
	malformed = data.duplicate(true)
	malformed.craft_queue = [{"recipe": "iron_plate", "remaining": 1}]
	check(not SaveService.decode(malformed).has("world"), "Machine-only recipes cannot appear in the handcraft queue")
	var legacy := {"version": 1, "credits": 100, "delivered": 12, "buildings": [{"x": 15, "y": 15, "machine": {"kind": 1, "dir": 0, "ore": 0}}], "items": [{"x": 15, "y": 15, "item": "ore"}]}
	var imported := SaveService.decode(legacy)
	check(imported.get("legacy", false) and imported.world.at(Vector2i(15, 15)).output.count("iron_ore") == 1, "Legacy save migrates stable item and building identities")
	var path := "user://factory_verification_only.json"
	check(SaveService.save_world(world, path).is_empty(), "Save writes a new slot")
	check(SaveService.save_world(world, path).is_empty() and FileAccess.file_exists(path + ".bak"), "Second save commits and retains backup")
	var loaded := SaveService.load_world(path)
	check(loaded.has("world") and SaveService.encode(loaded.world) == SaveService.encode(world), "Disk save restores equivalent world")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))

func _scene_smoke() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	check(scene.hud.story_panel.visible and scene.paused, "New arrivals get a skippable story scene before the mining lesson")
	scene.hud.story_panel.close_panel()
	check(not scene.world.story.seen.has("arrival") and not scene.paused, "Dismissing an unfinished introduction preserves its unread marker and resumes the tutorial")
	check(scene.world.entities.is_empty() and scene.world.player.total() == 0, "Playable scene starts without buildings or supplies")
	check(scene.hud.objective.visible and scene.hud.objective.text.contains("Gather stone"), "New player sees the first mining lesson")
	check(not scene.hud.hotbar.available("drill") and scene.hud.hotbar.available("furnace"), "Hotbar introduces tools gradually without moving shortcut slots")
	scene.hud.toggle_crafting()
	await process_frame
	check(scene.hud.craft_buttons.furnace.visible and not scene.hud.craft_buttons.science.visible, "New player sees only introductory crafting recipes")
	scene._bind_world(Fixtures.demo())
	scene._select("furnace")
	scene._inspect(Vector2i(19, 15))
	scene.hud.refresh()
	check(scene.hud.inspector.visible and not scene.hud.inspector_text.text.is_empty(), "Machine inspection UI binds to model")
	scene.hud.toggle_crafting()
	await process_frame
	check(scene.hud.crafting.visible and scene.hud.craft_buttons.size() >= 10, "Crafting UI exposes registered recipes")
	var viewport: Rect2 = root.get_visible_rect()
	if not viewport.encloses(scene.hud.top.get_global_rect()) or not viewport.encloses(scene.hud.bottom.get_global_rect()):
		print("HUD bounds: viewport=", viewport, " top=", scene.hud.top.get_global_rect(), " bottom=", scene.hud.bottom.get_global_rect())
	check(viewport.encloses(scene.hud.top.get_global_rect()) and viewport.encloses(scene.hud.bottom.get_global_rect()), "Main HUD panels fit the viewport")
	for item in scene.Catalog.ITEMS:
		if not scene.Catalog.BUILDINGS.has(item): scene.world.player.add(item, 500)
	scene.hud.refresh()
	await process_frame
	await process_frame
	check(viewport.encloses(scene.hud.bottom.get_global_rect()), "Expanded material inventory remains within the HUD")
	scene._toggle_pause()
	var tick: int = scene.world.ticks
	scene._process(0.5)
	check(scene.world.ticks == tick, "Pause freezes authoritative simulation")
	var town := World.new()
	town.start()
	town.player_position = Vector2(28.5, 15.5)
	town.player.contents = {"stone": 10, "iron_plate": 24, "gear": 6}
	scene._bind_world(town)
	scene._inspect(town.settlements.sites.trading_post.port())
	check(scene.hud.site_id == "trading_post" and scene.hud.town_panel.visible and scene.hud.town_panel.restore_button.disabled, "Clicking a landmark opens repair inspection and disables incomplete restoration")
	scene.hud.town_panel.supply_button.pressed.emit()
	check(not scene.hud.town_panel.restore_button.disabled, "Repair supply UI delivers materials through authoritative commands")
	scene.hud.town_panel.restore_button.pressed.emit()
	check(town.settlements.sites.trading_post.repaired and scene.hud.town_panel.information.text.contains("Mira"), "Restoration UI reopens the trading post and introduces its keeper")
	await process_frame
	await process_frame
	check(root.get_visible_rect().encloses(scene.hud.top.get_global_rect()) and root.get_visible_rect().encloses(scene.hud.bottom.get_global_rect()), "Restoration notifications and trade status stay inside the viewport")
	scene.hud.town_panel.supply_button.pressed.emit()
	Simulation.step(town)
	var remaining: int = town.settlements.sites.trading_post.shipment_ticks
	scene._process(0.5)
	check(remaining > 0 and town.settlements.sites.trading_post.shipment_ticks == remaining, "Paused gameplay freezes trade delivery timers as well as factory simulation")
	scene.hud.toggle_town()
	check(scene.hud.town_panel.overview.visible and not scene.hud.town_panel.detail.visible, "Town overview exposes both restoration projects")
	scene.queue_free()
	await process_frame
