extends RefCounted
const Fixtures = preload("res://tests/fixtures.gd")
const Saves = preload("res://scripts/persistence/save_service.gd")

static func run(test: SceneTree) -> void:
	var world = Fixtures.defense_town(false)
	test.check(world.early.phase == 2 and world.settlements.age == 2, "Industrial towns use the shelter and crossing progression")
	for site in world.settlements.sites.values():
		site.inventory.contents.clear()
		site.shipment_ticks = 0
	world.settlements.sites.trading_post.inventory.contents = {"iron_plate": 4, "gear": 1}
	var earned: int = world.settlements.total_earned
	for i in range(300): world.settlements.step(world)
	test.check(world.settlements.total_earned == earned + 12, "Completed opening retains the two-credit stone market premium")
	var data := Saves.encode(world)
	var loaded := Saves.decode(JSON.parse_string(JSON.stringify(data)))
	test.check(loaded.error.is_empty() and Saves.encode(loaded.world) == data, "Current age and premium ledger roundtrip exactly")
	var invalid := data.duplicate(true)
	invalid.settlements.age = 1
	test.check(not Saves.decode(invalid).error.is_empty(), "Civic age must agree with the opening chapter")
	invalid = data.duplicate(true)
	invalid.settlements.stone_shipments += 1
	test.check(not Saves.decode(invalid).error.is_empty(), "Forged premium ledgers are rejected")
	invalid = data.duplicate(true)
	invalid.frontier.sites.quarry.claimed = false
	test.check(not Saves.decode(invalid).error.is_empty(), "Completed crossing requires the mason pattern")
	invalid = data.duplicate(true)
	invalid.settlements.sites.pop_back()
	test.check(not Saves.decode(invalid).error.is_empty(), "Missing civic sites are rejected rather than placed on load")
	var fresh = Fixtures.industrial()
	fresh.start()
	test.check(fresh.settlements.age == 0 and fresh.early.phase == 0 and fresh.entities.is_empty() and fresh.player.total() == 0, "Only new-game path resets to an empty timber age")
	var center: Vector2i = world.frontier.sites.orchard.origin + Vector2i(2, 2)
	test.check(world.frontier.landscape_index(center) == 1 and world.frontier.landscape_index(world.frontier.sites.quarry.origin) == 2, "Restoration regions retain their landscape themes")

static func ui(test: SceneTree) -> void:
	var scene = load("res://main.tscn").instantiate()
	test.root.add_child(scene)
	await test.process_frame
	scene.set_process(false)
	scene.paused = true
	var world = Fixtures.defense_town(false)
	scene._bind_world(world)
	scene._inspect_site("town_hall")
	test.check(not scene.hud.town_panel.age_button.visible and scene.hud.town_panel.age_text.text.contains("Iron & Industry"), "Restored Hall shows the completed opening and no obsolete age project")
	scene.queue_free()
	await test.process_frame
