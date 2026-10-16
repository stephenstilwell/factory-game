extends RefCounted
const World = preload("res://scripts/simulation/world.gd")
const Saves = preload("res://scripts/persistence/save_service.gd")
const Fixtures = preload("res://tests/fixtures.gd")

static func visit(world: RefCounted, id: String) -> void:
	world.player_position = Vector2(world.frontier.port(id)) + Vector2.ONE * 0.5
	world.previous_position = world.player_position
	world.frontier.observe(world)

static func solve(world: RefCounted) -> void:
	for row in [1, 3]:
		var detour := 0 if row == 1 else 4
		for entry in [[Vector2i(1, row), 0], [Vector2i(2, row), 3 if row == 1 else 1], [Vector2i(2, detour), 0], [Vector2i(3, detour), 0], [Vector2i(4, detour), 1 if row == 1 else 3], [Vector2i(4, row), 0], [Vector2i(5, row), 0]]:
			world.frontier.edit_belt(world, entry[0])
			for turn in range(entry[1]): world.frontier.edit_belt(world, entry[0])

static func run(test: SceneTree) -> void:
	for seed_value in [0, 1, 74103, -2000000000, 2000000000]:
		var a := World.new(seed_value)
		a.start()
		var b := World.new(seed_value)
		b.start()
		test.check(a.frontier.serialize() == b.frontier.serialize() and a.frontier.sites.size() == 3, "All three landmarks generate reproducibly for seed %d" % seed_value)
		test.check(a.player.total() == 0 and a.entities.is_empty(), "Frontier keeps the empty tutorial start")
		for id in a.frontier.sites:
			var rect: Rect2i = a.frontier.footprint(id)
			var clear := true
			for x in range(rect.position.x, rect.end.x):
				for y in range(rect.position.y, rect.end.y):
					if not a.terrain.tile(Vector2i(x, y)).is_empty() or a.settlements.at(Vector2i(x, y)) != null: clear = false
			test.check(clear and a.solid(rect.position) and not a.solid(a.frontier.port(id)), "Landmark preserves ore and civic footprints with an accessible entrance")
	var world := World.new()
	world.start()
	test.check(not world.frontier.claim(world, "camp"), "Frontier rewards require physical reach")
	visit(world, "camp")
	var discovered: int = world.skills.xp.exploration
	world.frontier.observe(world)
	test.check(discovered == 75 and world.skills.xp.exploration == discovered, "Landmark discovery XP is granted once through actual proximity")
	world.player.capacity = 1
	test.check(not world.frontier.claim(world, "camp") and not world.frontier.claimed("camp") and world.player.total() == 0, "Full pack leaves the entire salvage bundle unclaimed")
	world.player.capacity = 10000
	var radius: int = world.survey_radius()
	test.check(world.frontier.claim(world, "camp") and world.player.contents == {"coal": 10, "gear": 4, "wire": 6}, "Camp yields its exact physical salvage")
	test.check(world.survey_radius() == radius + 1 and world.skills.xp.exploration == 275, "Survey notes grant advertised XP and actual survey capability")
	var before := Saves.encode(world)
	test.check(not world.frontier.claim(world, "camp") and world.player.total() == 20 and world.skills.xp.exploration == 275, "Repeated claims cannot duplicate salvage or XP")
	var loaded := Saves.decode(JSON.parse_string(JSON.stringify(Saves.encode(world))))
	test.check(loaded.error.is_empty() and loaded.world.frontier.serialize() == world.frontier.serialize(), "Discoveries and reward ownership survive JSON saves")
	if loaded.error.is_empty():
		test.check(not loaded.world.frontier.claim(loaded.world, "camp") and loaded.world.player.total() == 20, "Reloading cannot repeat one-time rewards")
	visit(world, "orchard")
	test.check(world.frontier.claim(world, "orchard") and world.frontier.claimed("orchard"), "Recovered orchard cutting persists without inventory clutter")
	visit(world, "depot")
	var bag: Dictionary = world.player.contents.duplicate()
	test.check(not world.frontier.claim(world, "depot"), "Depot reward requires two valid cargo routes")
	test.check(not world.frontier.edit_belt(world, Vector2i(3, 1)) and not world.frontier.edit_belt(world, Vector2i(0, 1)), "Puzzle cannot overwrite walls, sources, or docks")
	solve(world)
	test.check(world.frontier.board.size() == 14 and world.frontier.evaluate().success and world.player.contents == bag, "Both routes solve using exactly the loaned toolkit without factory items")
	var spare := Vector2i(1, 0)
	test.check(not world.frontier.edit_belt(world, spare) and world.frontier.board.size() == 14, "Puzzle respects the finite conveyor budget")
	loaded = Saves.decode(JSON.parse_string(JSON.stringify(Saves.encode(world))))
	test.check(loaded.error.is_empty() and loaded.world.frontier.evaluate().success, "Unclaimed solved routing table persists")
	test.check(world.frontier.claim(world, "depot") and not world.frontier.edit_belt(world, Vector2i(1, 1)), "Restored depot retains its completed layout")
	test.check(world.frontier.hearth_bonus(world) == 0, "Depot runners require an operational trading post")
	world.settlements.sites.trading_post.repaired = true
	world.settlements.sites.trading_post.health = world.settlements.sites.trading_post.max_health()
	test.check(world.frontier.hearth_bonus(world) == 1 and world.supply_radius() == 9, "Depot restoration extends real Supply Hearth coverage")
	world.settlements.sites.trading_post.health = 0
	test.check(world.frontier.hearth_bonus(world) == 0, "Disabled trading post suspends runner service")
	world.settlements.sites.trading_post.health = world.settlements.sites.trading_post.max_health()
	loaded = Saves.decode(Saves.encode(world))
	test.check(loaded.error.is_empty(), "All recovered sites save with their persistent effects")
	var bad := Saves.encode(world)
	bad.frontier.board[0][2] = 4
	test.check(not Saves.decode(bad).error.is_empty(), "Save rejects impossible conveyor directions")
	bad = Saves.encode(world)
	bad.frontier.sites.depot.discovered = false
	test.check(not Saves.decode(bad).error.is_empty(), "Claimed sites must have been discovered")
	bad = Saves.encode(world)
	bad.frontier.board = []
	test.check(not Saves.decode(bad).error.is_empty(), "Claimed depot requires a completed routing table")
	var tree_world := World.new()
	tree_world.start()
	tree_world.guide.enabled = false
	var tree := Vector2i(2000000, 2000000)
	for x in range(-8, 12):
		for y in range(-15, 0):
			if tree_world.frontier.tree_at(tree_world, Vector2i(x, y)): tree = Vector2i(x, y); break
		if tree.x != 2000000: break
	test.check(tree.x != 2000000 and not tree_world.solid(tree), "Seeded groves exist and remain passable")
	tree_world.player_position = Vector2(tree) + Vector2(1.5, 1.5)
	tree_world.previous_position = tree_world.player_position
	tree_world.mining = true
	tree_world.mining_cell = tree
	test.advance(tree_world, 6)
	test.check(not tree_world.frontier.tree_at(tree_world, tree) and tree_world.player.total() == 0 and tree_world.skills.xp.mining == 0, "Brush clearing is quick and cannot farm materials or Mining XP")
	loaded = Saves.decode(JSON.parse_string(JSON.stringify(Saves.encode(tree_world))))
	test.check(loaded.error.is_empty() and not loaded.world.frontier.tree_at(loaded.world, tree), "Cleared scenery never regrows on reload")
	var old := Fixtures.demo()
	old.settlements = World.Settlements.new(true)
	var entities: Array = Saves.encode(old).entities
	var data := Saves.encode(old)
	data.erase("frontier")
	loaded = Saves.decode(data)
	test.check(loaded.error.is_empty() and loaded.world.frontier.sites.size() == 3 and Saves.encode(loaded.world).entities == entities, "Old saves gain landmarks on vacant land without moving factories")
	var guarded := World.new()
	guarded.start()
	visit(guarded, "camp")
	guarded.defense.phase = "warning"
	test.check(not guarded.frontier.claim(guarded, "camp"), "Active or warning defenses prevent exploration interactions")
	world.start()
	test.check(world.frontier.board.is_empty() and world.frontier.cleared.is_empty() and not world.frontier.claimed("camp"), "New games reset discoveries, puzzle state, and scenery removals")

static func ui(test: SceneTree) -> void:
	var scene = load("res://main.tscn").instantiate()
	test.root.add_child(scene)
	await test.process_frame
	scene.set_process(false)
	var world := World.new()
	world.start()
	visit(world, "depot")
	scene._bind_world(world)
	scene.view.paused = true
	scene.paused = true
	for viewport in [Vector2i(1280, 800), Vector2i(1100, 720)]:
		test.root.content_scale_size = viewport
		test.root.size = viewport
		scene._open_frontier("depot")
		var panel = scene.hud.frontier_panel
		for i in range(5): await test.process_frame
		var frame: Control = panel.get_child(0).get_child(0)
		test.check(test.root.get_visible_rect().encloses(frame.get_global_rect()), "Discovery and puzzle panel fits %s" % viewport)
		test.check(not scene.hud.world_has_pointer(), "Discovery panel blocks world interactions")
		panel.cells[Vector2i(1, 1)].pressed.emit()
		test.check(world.frontier.board.has(Vector2i(1, 1)), "Puzzle buttons update only the loaned sorting table")
		panel.track_button.pressed.emit()
		test.check(world.frontier.target == "depot", "Tracking points to the actual generated entrance")
		panel.track_button.pressed.emit()
		scene.hud.frontier_panel.hide()
		world.frontier.board.clear()
	var encoded := Saves.encode(world)
	for i in range(5): await test.process_frame
	test.check(Saves.encode(world) == encoded, "Drawing groves, landmarks, and wildlife cannot alter rewards or simulation state")
	scene._inspect(world.frontier.port("depot"))
	test.check(scene.hud.frontier_panel.visible and scene.hud.frontier_panel.selected == "depot", "Click inspection opens a landmark rather than the factory inventory")
	scene.queue_free()
	await test.process_frame
	test.root.content_scale_size = Vector2i(1280, 800)
	test.root.size = Vector2i(1280, 800)
