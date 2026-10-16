extends RefCounted
const World = preload("res://scripts/simulation/world.gd")
const Simulation = preload("res://scripts/simulation/simulation.gd")
const Transport = preload("res://scripts/simulation/transport.gd")
const Saves = preload("res://scripts/persistence/save_service.gd")
const Catalog = preload("res://scripts/data/catalog.gd")
const Fixtures = preload("res://tests/fixtures.gd")

static func roundtrip(world: RefCounted) -> Dictionary:
	return Saves.decode(JSON.parse_string(JSON.stringify(Saves.encode(world))))

static func run(test: SceneTree) -> void:
	_routes(test)
	_manufacturing(test)
	_research(test)
	_housing(test)
	_plans(test)

static func _routes(test: SceneTree) -> void:
	var world := World.new()
	world.researched = ["logistics", "routing"]
	var splitter = world.spawn("splitter", Vector2i.ZERO, 0)
	var forward = world.spawn("belt", Vector2i.RIGHT, 0)
	var side = world.spawn("belt", Vector2i.DOWN, 1)
	var received := [0, 0]
	for i in range(20):
		splitter.inventory.add("iron_ore")
		world.ticks += 2
		Transport.step(world)
		received[0] += forward.inventory.remove("iron_ore")
		received[1] += side.inventory.remove("iron_ore")
	test.check(received == [10, 10], "Splitters alternate equal available outputs without duplicating items")
	forward.inventory.add("stone")
	splitter.routing_cursor = 0
	splitter.inventory.add("copper_ore")
	Transport.step(world)
	test.check(side.inventory.count("copper_ore") == 1 and forward.inventory.count("stone") == 1, "Blocked splitter branch bypasses to the other output")
	var snapshot := roundtrip(world)
	test.check(snapshot.error.is_empty(), "Splitter cursors and branch research survive JSON saves")
	var merge := World.new()
	var a = merge.spawn("belt", Vector2i(-1, 0), 0)
	var b = merge.spawn("belt", Vector2i(0, -1), 1)
	var target = merge.spawn("belt", Vector2i.ZERO, 0)
	var merged := {"iron_ore": 0, "copper_ore": 0}
	for i in range(20):
		a.inventory.add("iron_ore")
		b.inventory.add("copper_ore")
		Transport.step(merge)
		for item in merged: merged[item] += target.inventory.remove(item)
	test.check(merged.iron_ore == 10 and merged.copper_ore == 10, "Receiver round-robin prevents merge starvation")
	var tunnel := World.new()
	tunnel.researched = ["logistics", "routing"]
	var entry = tunnel.spawn("underground_belt", Vector2i.ZERO, 0)
	var exit = tunnel.spawn("underground_belt", Vector2i(6, 0), 0)
	exit.underground_exit = true
	var crossing = tunnel.spawn("belt", Vector2i(3, 0), 1)
	var after = tunnel.spawn("belt", Vector2i(7, 0), 0)
	entry.inventory.add("iron_ore")
	crossing.inventory.add("copper_ore")
	Transport.step(tunnel)
	test.check(exit.inventory.count("iron_ore") == 1 and after.inventory.total() == 0 and crossing.inventory.count("copper_ore") == 1, "Tunnel crosses surface lines with one snapshot hop and conserves both streams")
	Transport.step(tunnel)
	test.check(after.inventory.count("iron_ore") == 1, "Underground exit feeds a surface conveyor")
	exit.direction = 1
	test.check(Transport.partner(tunnel, entry) == null, "Tunnels require matching direction")
	exit.direction = 0
	exit.health = 0
	test.check(Transport.partner(tunnel, entry) == null, "Disabled underground exits stop transport")
	exit.health = exit.max_health()
	var blocker = tunnel.spawn("underground_belt", Vector2i(2, 0), 0)
	test.check(Transport.partner(tunnel, entry) == null, "Nearest matching entrance prevents ambiguous tunnel connections")
	tunnel.player_position = Vector2(2.5, 2.5)
	tunnel.reclaim(blocker.cell)
	test.check(Transport.partner(tunnel, entry) == exit, "Removing an intervening entrance reconnects its tunnel")
	test.check(roundtrip(tunnel).error.is_empty(), "Tunnel mode and contents validate through saves")
	var far := World.new()
	var far_entry = far.spawn("underground_belt", Vector2i.ZERO, 0)
	far.spawn("underground_belt", Vector2i(7, 0), 0).underground_exit = true
	test.check(Transport.partner(far, far_entry) == null, "Underground range is bounded to six tiles")

static func _manufacturing(test: SceneTree) -> void:
	for recipe_id in Catalog.BUILDINGS.keys() + ["construction_kit"]:
		var world := Fixtures.defense_town(false)
		world.researched = ["logistics", "metallurgy", "routing", "construction"]
		world.player_position = Vector2(2.5, 2.5)
		var machine = world.spawn("assembler", Vector2i.ZERO, 0)
		test.check(world.set_recipe(machine.cell, recipe_id), "Assembler accepts building recipe " + recipe_id)
		machine.inventory.contents = Catalog.RECIPES[recipe_id]["in"].duplicate()
		test.advance(world, int(Catalog.RECIPES[recipe_id].ticks))
		test.check(machine.output.contents == Catalog.RECIPES[recipe_id]["out"], "Automated building batch consumes real ingredients: " + recipe_id)
		var xp: int = world.skills.xp.fabrication
		machine.output.contents.clear()
		machine.inventory.contents = Catalog.RECIPES[recipe_id]["in"].duplicate()
		test.advance(world, int(Catalog.RECIPES[recipe_id].ticks))
		test.check(world.skills.xp.fabrication == xp and world.automation_awards.has("line:" + recipe_id), "Commission XP occurs once per recipe: " + recipe_id)
		test.check(roundtrip(world).error.is_empty(), "Manufacturing milestones and configured recipes save: " + recipe_id)
	var supply := Fixtures.defense_town(false)
	supply.researched = ["logistics"]
	supply.player_position = Vector2(2.5, 2.5)
	var turret_line = supply.spawn("assembler", Vector2i.ZERO, 0)
	supply.set_recipe(turret_line.cell, "turret")
	turret_line.inventory.add("iron_plate", 10)
	test.check(supply.accepts(turret_line, "iron_plate"), "Large building recipes can receive more than ten ingredients")
	var metrics: RefCounted = supply.metrics
	metrics.record(10, "made", "belt", 2)
	metrics.consume(10, {"iron_plate": 1})
	var stats: Dictionary = metrics.snapshot(20)
	test.check(stats.made.belt == 2 and stats.used.iron_plate == 1 and stats.seconds == 2.0, "Production history reports actual made and used amounts over observed time")
	for i in range(1000): metrics.record(i * 10, "made", "stone", 1)
	test.check(metrics.buckets.size() <= 60 and metrics.snapshot(10000).made.get("belt", 0) == 0, "Rolling production history remains bounded and expires old activity")
	var canceled := World.new()
	canceled.player.add("iron_plate")
	canceled.craft("belt")
	canceled.cancel_all_crafts()
	test.check(canceled.metrics.snapshot(1).used.is_empty(), "Canceled craft reservations do not inflate consumption")

static func _research(test: SceneTree) -> void:
	var world := World.new()
	world.researched = ["logistics"]
	world.research_target = "metallurgy"
	world.research_progress = 3
	test.check(not world.select_research("construction"), "Construction research requires metallurgy")
	test.check(world.select_research("routing") and world.research_progress == 0 and world.research_banks.metallurgy == 3, "Research choice banks invested science without spending more packs")
	var lab = world.spawn("lab", Vector2i.ZERO, 0)
	lab.inventory.add("science", 20)
	test.advance(world, 150)
	test.check(world.research_progress == 5 and lab.inventory.count("science") == 15, "Selected routing research spends one science per completed lab cycle")
	test.check(world.select_research("metallurgy") and world.research_progress == 3 and world.research_banks.routing == 5, "Switching back restores previous science investment")
	var loaded := roundtrip(world)
	test.check(loaded.error.is_empty(), "Branching research and inactive investments persist")
	if loaded.error.is_empty():
		test.advance(world, 120)
		test.advance(loaded.world, 120)
		test.check(Saves.encode(world) == Saves.encode(loaded.world), "Partial research resumes deterministically after save")
	world.select_research("routing")
	lab.inventory.contents = {"science": 15}
	test.advance(world, 450)
	test.check("routing" in world.researched and world.unlocked(Catalog.BUILDINGS.splitter), "Routing can complete before metallurgy and unlocks real layout tools")
	test.check(roundtrip(world).error.is_empty(), "Nonlinear technology completion order validates")
	var old: Dictionary = Saves.encode(World.new())
	for key in ["research_target", "research_banks", "automation_awards", "plans"]: old.erase(key)
	old.researched = ["logistics", "metallurgy"]
	var migrated := Saves.decode(old)
	test.check(migrated.error.is_empty() and migrated.world.current_research() == "routing", "Older completed two-technology saves discover new branches safely")
	var invalid: Dictionary = Saves.encode(world)
	invalid.researched = ["construction"]
	test.check(not Saves.decode(invalid).error.is_empty(), "Save validation rejects research without its prerequisites")

static func _housing(test: SceneTree) -> void:
	var world := Fixtures.defense_town(false)
	var hall = world.settlements.sites.town_hall
	var goods: Dictionary = world.settlements.Definitions.CONTRACTS.housing.goods
	var before: int = world.settlements.effect("burner_ticks")
	test.advance(world, 600)
	test.check(hall.shipments == 0, "Housing growth never advances without supplies")
	for i in range(3):
		hall.inventory.contents = goods.duplicate()
		test.advance(world, 1)
		test.check(hall.inventory.total() == 0 and hall.shipment_ticks == 599, "Housing consumes a real shipment before its delivery timer")
		test.advance(world, 599)
	test.check(world.settlements.district_level() == 1 and world.settlements.effect("burner_ticks") == before + 4, "Three supplied deliveries restore a visible neighborhood and five percent base coal benefit")
	test.check(roundtrip(world).error.is_empty(), "Neighborhood growth and delivery milestones validate through saves")
	var resumed := roundtrip(world)
	if resumed.error.is_empty():
		var xp: int = resumed.world.skills.xp.fabrication
		resumed.world.award_automation("delivery:town_hall:1", "fabrication", 150)
		test.check(resumed.world.skills.xp.fabrication == xp, "Saved delivery commission cannot be earned again")
	var automated := Fixtures.defense_town(false)
	var target = automated.settlements.sites.town_hall
	var supply = automated.spawn("chest", target.port() - Vector2i(2, 0), 0)
	supply.inventory.contents = goods.duplicate()
	automated.spawn("inserter", target.port() - Vector2i(1, 0), 0)
	test.advance(automated, 120)
	test.check(supply.inventory.total() == 0 and target.shipment_ticks > 0 and target.inventory.total() == 0, "Inserter-fed housing hatch dispatches physical factory supplies")
	test.check(roundtrip(automated).error.is_empty(), "Automated in-transit housing delivery saves correctly")
	var count: int = hall.shipments
	test.advance(world, 1200)
	test.check(hall.shipments == count, "Housing shortages pause growth without removing restored neighborhoods")
	for i in range(6):
		hall.inventory.contents = goods.duplicate()
		test.advance(world, 600)
	test.check(world.settlements.district_level() == 3 and hall.shipments == 9, "Nine deliveries complete all three neighborhoods")
	hall.inventory.contents = goods.duplicate()
	test.advance(world, 601)
	test.check(hall.inventory.contents == goods and world.settlements.receiving_limit("town_hall", "steel") == 0, "Completed housing stops dispatch and refuses further supplies without wasting buffered goods")
	test.check(roundtrip(world).error.is_empty(), "Fully grown town with buffered supplies remains loadable")
	hall.health = 0
	test.check(world.settlements.effect("burner_ticks") == 0, "Breached hub suspends neighborhood and workshop services")

static func _plans(test: SceneTree) -> void:
	var world := World.new()
	world.researched = ["logistics", "routing"]
	world.player_position = Vector2(2.5, 2.5)
	world.player_position = Vector2(2.5, 2.5)
	var machine = world.spawn("assembler", Vector2i.ZERO, 0)
	machine.recipe = "belt"
	machine.inventory.add("iron_plate", 7)
	var end = world.spawn("underground_belt", Vector2i(1, 0), 0)
	end.underground_exit = true
	test.check(world.plans.capture(world, Rect2i(0, 0, 2, 1)).is_empty(), "Copy captures a configured factory module")
	test.check(not world.plans.clipboard[0].has("inventory"), "Plans contain no items, health, or production state")
	test.check(world.plans.place(world, Vector2i(3, 0)).is_empty() and world.plans.ghosts.size() == 2, "Plans stamp ghosts without consuming or creating buildings")
	test.check(world.plans.build_nearby(world) == 0, "Ghost construction requires physical building items")
	world.player.add("assembler")
	world.player.add("underground_belt")
	test.check(world.plans.build_nearby(world) == 2 and world.plans.ghosts.is_empty(), "Reachable ghosts build using the player's actual stock")
	test.check(world.at(Vector2i(3, 0)).recipe == "belt" and world.at(Vector2i(3, 0)).inventory.total() == 0 and world.at(Vector2i(4, 0)).underground_exit, "Built modules restore configuration without copying machine contents")
	var clipboard: Array = world.plans.clipboard.duplicate(true)
	for i in range(4): world.plans.rotate()
	test.check(world.plans.clipboard == clipboard, "Four module rotations preserve all configuration")
	world.plans.rotate()
	test.check(world.plans.clipboard[1].direction == 1 and world.plans.clipboard[1].y == 1, "Module rotation turns positions and machine directions together")
	world.plans.place(world, Vector2i(20, 0))
	world.player.add("assembler")
	test.check(world.plans.build_nearby(world) == 0 and world.player.count("assembler") == 1, "Remote ghosts wait for player reach and preserve inventory")
	var saved := roundtrip(world)
	test.check(saved.error.is_empty() and saved.world.plans.ghosts.size() == 2, "Persistent construction ghosts validate after load")
	var legacy: Dictionary = Saves.encode(World.new())
	var old_machine = World.new()
	old_machine.spawn("belt", Vector2i.ZERO, 0)
	legacy = Saves.encode(old_machine)
	for record in legacy.entities:
		for key in ["merge_cursor", "routing_cursor", "underground_exit"]: record.erase(key)
	test.check(Saves.decode(legacy).error.is_empty(), "Older transport entities load with safe new-field defaults")
	var before: Array = world.plans.serialize()
	test.check(not world.plans.place(world, Vector2i.ZERO).is_empty() and world.plans.serialize() == before, "Conflicting module stamps fail atomically")
	var previous_clipboard: Array = world.plans.clipboard.duplicate(true)
	test.check(world.plans.place_single(world, "belt", Vector2i(30, 0), 0).is_empty() and world.plans.clipboard == previous_clipboard, "Single ghosts need no building item and preserve the module clipboard")
	var invalid: Dictionary = Saves.encode(world)
	invalid.plans[0].kind = "unknown"
	test.check(not Saves.decode(invalid).error.is_empty(), "Malformed construction plans are rejected")

static func ui(test: SceneTree) -> void:
	var scene = load("res://main.tscn").instantiate()
	test.root.add_child(scene)
	scene._bind_world(World.new())
	scene.paused = true
	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_F
	scene._unhandled_input(key)
	test.check(scene.hud.factory_panel.visible and not scene.hud.world_has_pointer(), "F opens the factory workbench and blocks world actions")
	scene.hud.factory_panel.tab = "production"
	scene.hud.factory_panel.refresh()
	scene._unhandled_input(key)
	test.check(not scene.hud.factory_panel.visible, "F closes the workbench")
	scene.world.researched = ["logistics", "routing"]
	scene._select("underground_belt")
	key.keycode = KEY_G
	scene._unhandled_input(key)
	test.check(scene.underground_exit, "G selects underground exit mode")
	key.keycode = KEY_C
	key.ctrl_pressed = true
	scene._unhandled_input(key)
	test.check(scene.copy_mode and not scene.hud.workspace.visible, "Ctrl+C begins area copy without opening crafting")
	key.ctrl_pressed = false
	key.keycode = KEY_ESCAPE
	scene._input(key)
	test.check(not scene.copy_mode and not scene.hud.pause_menu.visible, "Escape cancels planning before opening pause")
	scene._start_copy()
	scene._open_journal()
	test.check(not scene.copy_mode and scene.hud.story_panel.visible, "Story menus cancel construction gestures")
	scene.queue_free()
	await test.process_frame
