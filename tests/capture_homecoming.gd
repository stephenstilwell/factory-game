extends SceneTree
const Simulation = preload("res://scripts/simulation/simulation.gd")
func _initialize() -> void: call_deferred("run")
func shot(name: String) -> void:
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/verification/homecoming_"+name+".png")
func run() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1100,720)
	root.content_scale_size = root.size
	scene.set_process(false)
	scene.hud.story_panel.dismiss_silently()
	scene.paused = true
	var world = preload("res://tests/homecoming_tests.gd").setup()
	scene._bind_world(world)
	scene.camera.position = Vector2(world.settlements.sites.town_hall.origin)*48
	scene.hud.toggle_town()
	await shot("pantry")
	# Visual fixture only: regression tests exercise the complete real supply/power chain.
	var chapter = world.settlements.homecoming
	chapter.stage = 2
	chapter.work_ticks = 300
	chapter.last_work_tick = 300
	world.ticks = 300
	world.settlements.road_deliveries = 9
	world.settlements.sites.town_hall.shipments = 3
	world.settlements.sites.town_hall.inventory.contents = chapter.goods().duplicate()
	scene.hud.refresh()
	await shot("ready")
	scene.hud.town_panel.chapter_finish.pressed.emit()
	scene.hud.close_workspace()
	scene.hud.refresh()
	await shot("fair")
	scene._inspect_site("town_hall")
	await shot("depot")
	scene.hud.town_panel.talk_button.pressed.emit()
	await shot("story")
	print("Homecoming visual capture complete")
	quit()
