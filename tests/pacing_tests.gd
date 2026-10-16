extends RefCounted
const World = preload("res://scripts/simulation/world.gd")
const Supply = preload("res://scripts/simulation/supply_service.gd")
const Saves = preload("res://scripts/persistence/save_service.gd")
const Fixtures = preload("res://tests/fixtures.gd")

static func run(test: SceneTree) -> void:
	for generator in [1, 2]:
		var old := World.new()
		old.terrain.generator_version = generator
		old.terrain.stock_scale = 1
		var cell := Vector2i(14, 16)
		old.terrain.mine(cell)
		old.terrain.depleted[cell + Vector2i.RIGHT] = 0
		var remaining: int = old.terrain.tile(cell).amount
		var data := Saves.encode(old)
		data.erase("resource_scale")
		var migrated := Saves.decode(JSON.parse_string(JSON.stringify(data)))
		test.check(migrated.error.is_empty(), "Legacy resource migration validates generator %d" % generator)
		if not migrated.error.is_empty(): continue
		test.check(migrated.world.terrain.tile(cell).amount == remaining * 4 and migrated.world.terrain.tile(cell + Vector2i.RIGHT).is_empty(), "Migration multiplies remaining stock and never revives exhausted tiles")
		var again := Saves.decode(Saves.encode(migrated.world))
		test.check(again.error.is_empty() and again.world.terrain.tile(cell) == migrated.world.terrain.tile(cell), "Richness migration runs once across repeated saves")
	var world := World.new()
	var hearth = world.spawn("fuel_depot", Vector2i.ZERO, 0)
	var first = world.spawn("furnace", Vector2i(8, 0), 0)
	var second = world.spawn("furnace", Vector2i(0, 8), 0)
	var far = world.spawn("furnace", Vector2i(8, 8), 0)
	var broken = world.spawn("furnace", Vector2i(1, 1), 0)
	broken.health = 0
	hearth.inventory.add("coal")
	Supply.step(world)
	test.check(first.inventory.count("coal") == 1 and hearth.inventory.total() == 0, "Hearth transfers a physical coal to an in-range burner")
	hearth.inventory.add("coal")
	Supply.step(world)
	test.check(second.inventory.count("coal") == 1 and first.inventory.count("coal") == 1, "Scarce hearth coal rotates fairly rather than starving later machines")
	hearth.inventory.add("coal", 20)
	for i in range(10): Supply.step(world)
	test.check(first.inventory.count("coal") == 3 and second.inventory.count("coal") == 3 and hearth.inventory.count("coal") == 16, "Hearth fills small reserves without hoarding or creating coal")
	test.check(far.inventory.total() == 0 and broken.inventory.total() == 0, "Hearth respects circular range and disabled machinery")
	test.check(world.metrics.snapshot(1).used.is_empty(), "Fuel delivery is not counted as fuel consumption")
	test.check(world.accepts(hearth, "coal") and not world.accepts(hearth, "iron_plate"), "Shared fuel storage accepts only coal")
	var saved := Saves.decode(Saves.encode(world))
	test.check(saved.error.is_empty(), "Hearth and fairness cursor persist")
	if saved.error.is_empty():
		hearth.inventory.remove("coal", 200)
		first.inventory.remove("coal", 3)
		second.inventory.remove("coal", 3)
		var resumed = saved.world
		resumed.entities[hearth.id].inventory.remove("coal", 200)
		resumed.entities[first.id].inventory.remove("coal", 3)
		resumed.entities[second.id].inventory.remove("coal", 3)
		hearth.inventory.add("coal")
		resumed.entities[hearth.id].inventory.add("coal")
		Supply.step(world)
		Supply.step(resumed)
		test.check(Saves.encode(world) == Saves.encode(resumed), "Scarce coal distribution resumes deterministically after save/load")
	var invalid := Saves.encode(world)
	invalid.entities[0].inventory = {"iron_plate": 1}
	test.check(not Saves.decode(invalid).error.is_empty(), "Malformed shared fuel storage is rejected")
	var automated := World.new()
	var chest = automated.spawn("chest", Vector2i(-2, 0), 0)
	chest.inventory.add("coal", 10)
	automated.spawn("inserter", Vector2i(-1, 0), 0)
	var fed = automated.spawn("fuel_depot", Vector2i.ZERO, 0)
	automated.spawn("furnace", Vector2i(1, 0), 0).inventory.add("iron_ore", 5)
	test.advance(automated, 200)
	test.check(automated.at(Vector2i(1, 0)).output.count("iron_plate") == 5 and fed.inventory.count("coal") > 0, "Chest to inserter to hearth to furnace runs without manual refueling")
	var town := Fixtures.defense_town(false)
	var before: int = town.settlements.credits
	test.check(town.defense.reward_preview(town).contains("+30 relief credits"), "First arrival previews concrete credits before signaling")
	town.defense.phase = "active"
	town.defense.pending = 0
	town.defense.step(town)
	test.check(town.defense.cleared == 1 and town.settlements.credits == before + 30 and town.settlements.relief_waves == [1], "Successful arrival grants its one-time relief reward")
	town.defense.step(town)
	test.check(town.settlements.credits == before + 30 and town.settlements.award_defense(1) == 0, "Idle ticks and duplicate victory callbacks cannot pay twice")
	test.check(Saves.decode(Saves.encode(town)).error.is_empty(), "Relief credits reconcile with trade income across saves")
	var forged := Saves.encode(town)
	forged.settlements.relief_waves.append(2)
	forged.settlements.credits += 35
	forged.settlements.total_earned += 35
	test.check(not Saves.decode(forged).error.is_empty(), "Save rejects rewards for defenses that were never completed")
	town.player_position = Vector2(town.settlements.sites.trading_post.port()) + Vector2(-1.5, 0.5)
	var coal_before: int = town.player.count("coal")
	test.check(town.settlements.order_supplies(town) and town.settlements.credits == before + 10 and town.player.count("coal") == coal_before + 20, "Relief credits buy an actual fuel/ammunition/repair bundle")
	var purchase_save := Saves.decode(Saves.encode(town))
	test.check(purchase_save.error.is_empty(), "Supply purchases reconcile spent currency after loading: " + purchase_save.error)
	town.defense.phase = "active"
	town.defense.step(town)
	test.check(town.supply_radius() == 9 and town.settlements.credits == before + 45, "Second returning crew extends supply hearth coverage and grants its own reward")
	var wallet: int = town.settlements.credits
	town.player.capacity = town.player.total()
	test.check(not town.settlements.order_supplies(town) and town.settlements.credits == wallet, "Full pack rejects an affordable purchase without charging credits")
	town.player.capacity = int(town.character.stat("inventory_capacity"))
	town.settlements.sites.town_hall.health = 0
	test.check(town.supply_radius() == 8, "Breached hall suspends crew coverage while preserving base hearth service")

static func ui(test: SceneTree) -> void:
	var scene = load("res://main.tscn").instantiate()
	test.root.add_child(scene)
	await test.process_frame
	scene.set_process(false)
	scene._bind_world(Fixtures.combat_town())
	for viewport_size in [Vector2i(1280, 800), Vector2i(1100, 720)]:
		test.root.content_scale_size = viewport_size
		test.root.size = viewport_size
		scene.hud.toggle_crafting()
		for i in range(4): await test.process_frame
		var panel = scene.hud.workspace.crafting
		test.check(not scene.hud.workspace.pack_column.visible and panel.size.x > 900, "Crafting gets the full workspace at %s" % viewport_size)
		var tiles_fit := true
		for button in panel.recipe_buttons.values():
			if button.visible and not button.get_parent().get_parent().get_parent().get_global_rect().encloses(button.get_global_rect()): tiles_fit = false
		test.check(tiles_fit, "All unlocked hand recipes fit without palette scrolling at %s" % viewport_size)
		scene.hud.close_workspace()
		var tech := InputEventKey.new()
		tech.pressed = true
		tech.keycode = KEY_T
		scene._unhandled_input(tech)
		test.check(scene.hud.factory_panel.visible and scene.hud.factory_panel.tab == "research", "T opens Technology")
		var operations := InputEventKey.new()
		operations.pressed = true
		operations.keycode = KEY_F
		scene._unhandled_input(operations)
		test.check(scene.hud.factory_panel.visible and scene.hud.factory_panel.tab == "production", "F switches Technology to production operations")
		var town := InputEventKey.new()
		town.pressed = true
		town.keycode = KEY_Y
		scene._unhandled_input(town)
		test.check(scene.hud.workspace.mode == "town" and scene.hud.workspace.visible and not scene.hud.factory_panel.visible, "Y switches operations to settlement projects")
		scene.hud.close_workspace()
	scene.queue_free()
	await test.process_frame
	test.root.content_scale_size = Vector2i(1280, 800)
	test.root.size = Vector2i(1280, 800)
