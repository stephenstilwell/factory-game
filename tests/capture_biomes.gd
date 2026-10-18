extends SceneTree
const Fixtures = preload("res://tests/fixtures.gd")
func _initialize() -> void: call_deferred("run")
func shot(label: String) -> void:
	for i in range(12): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/verification/biome_" + label + ".png")
func run() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1100,720)
	root.content_scale_size = root.size
	scene.set_process(false)
	scene.hud.story_panel.dismiss_silently()
	scene.paused = true
	scene.view.paused = true
	var world = Fixtures.industrial()
	scene._bind_world(world)
	for id in ["orchard","quarry"]:
		var center: Vector2 = Vector2(world.frontier.sites[id].origin)+Vector2(2,2)
		world.player_position = center+Vector2(-4,2)
		world.previous_position = world.player_position
		scene.camera.position = center*48
		world.orchard_project.beds = 0
		world.settlements.road_deliveries = 0
		scene.hud.refresh()
		await shot(id+"_before")
		world.orchard_project.beds = 3
		world.settlements.road_deliveries = 9
		scene.view.queue_redraw()
		await shot(id+"_restored")
	print("Biome captures complete")
	quit()
