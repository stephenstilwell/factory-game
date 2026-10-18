extends RefCounted
const Saves = preload("res://scripts/persistence/save_service.gd")
const Simulation = preload("res://scripts/simulation/simulation.gd")

static func world() -> RefCounted:
	var result = preload("res://tests/town_services_tests.gd").town()
	result.frontier.sites.quarry.discovered = true
	result.frontier.sites.quarry.claimed = true
	result.player_position = Vector2(result.frontier.port("quarry")) + Vector2.ONE * 0.5
	result.previous_position = result.player_position
	return result

static func run(test: SceneTree) -> void:
	var game := world()
	var project: RefCounted = game.quarry_project
	var credits: int = game.settlements.credits
	for i in range(700): project.step(game)
	test.check(game.settlements.credits == credits and game.settlements.road_deliveries == 0, "An unfunded quarry project never earns timer-only income")
	game.player.add("stone", 20)
	game.player.add("plank", 4)
	test.check(project.deliver(game) and project.inventory.count("stone") == 20 and game.player.count("stone") == 0, "Manual road delivery transfers real goods")
	project.step(game)
	test.check(project.inventory.total() == 0 and project.shipment_ticks == 599, "Starting a road shipment commits its goods exactly once")
	test.check(project.withdraw(game) and game.player.count("stone") == 0, "Committed road supplies cannot be withdrawn or duplicated")
	var saved := Saves.decode(JSON.parse_string(JSON.stringify(Saves.encode(game))))
	test.check(saved.error.is_empty() and saved.world.quarry_project.shipment_ticks == 599, "In-flight road cargo saves and resumes")
	if saved.error.is_empty():
		for i in range(599): saved.world.quarry_project.step(saved.world)
		test.check(saved.world.settlements.road_deliveries == 1 and saved.world.settlements.credits == credits + 12, "Resumed road load pays one reward at completion")
	for i in range(599): project.step(game)
	for load_index in range(8):
		project.inventory.add("stone", 20)
		project.inventory.add("plank", 4)
		for i in range(600): project.step(game)
	test.check(game.settlements.road_deliveries == 9 and game.settlements.credits == credits + 108, "Nine physical loads finish the road with the advertised total reward")
	test.check(game.automation_awards.has("greybank:road:9") and game.quarry_project.road(game).size() == 2, "Finished road grants its saved milestone and visible route")
	var points: PackedVector2Array = project.road(game)
	game.player_position = points[0].lerp(points[1], 0.5)
	test.check(is_equal_approx(project.movement_multiplier(game), 1.15), "Restored road grants local travel speed")
	game.player_position += (points[1] - points[0]).normalized().orthogonal()
	test.check(is_equal_approx(project.movement_multiplier(game), 1.0), "Road rewards do not become a global speed buff")
	game.player_position = Vector2(game.frontier.port("quarry")) + Vector2.ONE * 0.5
	saved = Saves.decode(JSON.parse_string(JSON.stringify(Saves.encode(game))))
	test.check(saved.error.is_empty(), "Finished road and credit/XP ledgers survive JSON saving")
	var earned: int = game.settlements.total_earned
	for i in range(700): project.step(game)
	test.check(project.receiving_limit(game, "stone") == 0 and game.settlements.total_earned == earned, "Completed road refuses further supplies and rewards")
	var malformed := Saves.encode(game)
	malformed.quarry_project.shipment_ticks = 1
	test.check(not Saves.decode(malformed).error.is_empty(), "Completed roads cannot have pending duplicate reward cargo")
	var old := world()
	var old_data := Saves.encode(old)
	old_data.erase("quarry_project")
	old_data.settlements.erase("road_deliveries")
	test.check(not Saves.decode(old_data).error.is_empty(), "Incomplete or obsolete saves are rejected without migration")
	var automated := world()
	var port: Vector2i = automated.frontier.port("quarry")
	var chest = automated.spawn("chest", port + Vector2i(-2, 0), 0)
	chest.inventory.add("stone", 20)
	chest.inventory.add("plank", 4)
	automated.spawn("inserter", port + Vector2i.LEFT, 0)
	for i in range(200): Simulation._inserters(automated)
	test.check(automated.quarry_project.inventory.count("stone") == 20 and automated.quarry_project.inventory.count("plank") == 4 and chest.inventory.total() == 0, "Existing inserters automate the quarry hatch without creating goods")
	var capped := world()
	capped.settlements.road_deliveries = 8
	capped.quarry_project.shipment_ticks = 10
	test.check(capped.quarry_project.receiving_limit(capped, "stone") == 0, "The final in-flight load blocks excess buffer stock")

static func ui(test: SceneTree) -> void:
	var game := world()
	game.player.add("stone", 20)
	var panel := preload("res://scripts/ui/frontier_panel.gd").new()
	test.root.add_child(panel)
	panel.open_panel(game, "quarry")
	test.check(panel.road_box.visible and not panel.road_deliver.disabled and "60-second" in panel.road_text.text, "Recovered quarry clearly shows road task, cost, timer and reward")
	panel.road_deliver.pressed.emit()
	test.check(game.quarry_project.inventory.count("stone") == 20, "Discoveries panel delivers real road supplies")
	panel.road_withdraw.pressed.emit()
	test.check(game.player.count("stone") == 20, "Discoveries panel returns uncommitted road buffer")
	panel.open_panel(game, "orchard")
	test.check(not panel.road_box.visible, "Road controls only belong to Greybank")
	panel.queue_free()
	await test.process_frame
