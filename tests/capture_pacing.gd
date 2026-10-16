extends SceneTree
const Fixtures = preload("res://tests/fixtures.gd")
func _initialize() -> void:
	call_deferred("_capture")
func shot(name: String) -> void:
	await create_timer(0.2).timeout
	for i in range(6): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/verification/" + name + ".png")
func _capture() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 800)
	DirAccess.make_dir_recursive_absolute("res://.godot/verification")
	var world := Fixtures.combat_town()
	world.research_target = "construction"
	world.research_progress = 8
	var hearth = world.spawn("fuel_depot", Vector2i(43, 17), 0)
	hearth.inventory.add("coal", 100)
	world.player.add("fuel_depot")
	scene._bind_world(world)
	scene.set_process(false)
	scene.paused = true
	scene.view.paused = true
	scene.camera.position = Vector2(43, 14) * 48
	for viewport_size in [Vector2i(1280, 800), Vector2i(1100, 720)]:
		root.content_scale_size = viewport_size
		root.size = viewport_size
		scene.hud.toggle_crafting()
		await shot("pacing_crafting_" + str(viewport_size.x))
		scene.hud.close_workspace()
		scene._open_factory("research")
		await shot("pacing_technology_" + str(viewport_size.x))
		scene.hud.factory_panel.close_panel()
		scene._inspect_site("town_hall")
		await shot("pacing_rewards_" + str(viewport_size.x))
		scene.hud.close_workspace()
	scene._inspect(hearth.cell)
	await shot("pacing_hearth")
	quit()
