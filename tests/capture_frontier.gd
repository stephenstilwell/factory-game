extends SceneTree
const World = preload("res://scripts/simulation/world.gd")
func _initialize() -> void: call_deferred("_capture")
func shot(name: String) -> void:
	await create_timer(0.2).timeout
	for i in range(6): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/verification/" + name + ".png")
func _capture() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	root.mode = Window.MODE_WINDOWED
	root.content_scale_size = Vector2i(1280, 800)
	root.size = Vector2i(1280, 800)
	DirAccess.make_dir_recursive_absolute("res://.godot/verification")
	var world := World.new(74103)
	world.start(false)
	scene._bind_world(world)
	scene.set_process(false)
	scene.paused = true
	scene.view.paused = true
	scene.camera.position = world.player_position * 48
	await shot("frontier_opening")
	for id in ["camp", "orchard", "depot"]:
		world.player_position = Vector2(world.frontier.port(id)) + Vector2.ONE * 0.5
		world.previous_position = world.player_position
		world.frontier.observe(world)
		scene.camera.position = world.player_position * 48
		await shot("frontier_" + id)
		scene._open_frontier(id)
		await shot("frontier_panel_" + id)
		scene.hud.frontier_panel.hide()
	world.player_position = Vector2(world.frontier.port("orchard")) + Vector2.ONE * 0.5
	world.frontier.claim(world, "orchard")
	world.settlements.sites.trading_post.repaired = true
	world.settlements.sites.trading_post.health = world.settlements.sites.trading_post.max_health()
	world.player_position = Vector2(28.5, 17.5)
	world.previous_position = world.player_position
	scene.camera.position = Vector2(30.5, 16.5) * 48
	await shot("frontier_garden")
	world.player_position = Vector2(world.frontier.port("depot")) + Vector2.ONE * 0.5
	world.previous_position = world.player_position
	scene.camera.position = world.player_position * 48
	for viewport in [Vector2i(1280, 800), Vector2i(1100, 720)]:
		root.content_scale_size = viewport
		root.size = viewport
		scene._open_frontier("depot")
		await shot("frontier_puzzle_" + str(viewport.x))
		scene.hud.frontier_panel.hide()
	load("res://tests/frontier_tests.gd").solve(world)
	scene._open_frontier("depot")
	await shot("frontier_puzzle_solved")
	world.frontier.claim(world, "depot")
	scene.hud.frontier_panel.hide()
	await shot("frontier_depot_restored")
	quit()
