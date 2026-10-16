extends SceneTree
const Fixtures = preload("res://tests/fixtures.gd")
const Simulation = preload("res://scripts/simulation/simulation.gd")
func _initialize() -> void:
	call_deferred("_capture")
func shot(name: String) -> void:
	for i in range(6): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/verification/" + name + ".png")
func _capture() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 800)
	DirAccess.make_dir_recursive_absolute("res://.godot/verification")
	var world := Fixtures.defense_town(false)
	world.researched = ["logistics", "metallurgy"]
	world.research_target = "routing"
	world.research_progress = 7
	world.spawn("assembler", Vector2i(36, 14), 0).recipe = "belt"
	world.at(Vector2i(36, 14)).inventory.add("iron_plate", 10)
	for i in range(40): Simulation.step(world)
	world.settlements.sites.town_hall.shipments = 6
	scene._bind_world(world)
	scene.set_process(false)
	scene.paused = true
	scene.view.paused = true
	scene.camera.position = Vector2(41, 14) * 48
	scene._open_factory()
	await shot("expansion_research")
	scene.hud.factory_panel.tab = "production"
	scene.hud.factory_panel.refresh()
	await shot("expansion_production")
	scene.hud.factory_panel.tab = "plans"
	scene.hud.factory_panel.refresh()
	await shot("expansion_plans")
	scene.hud.factory_panel.close_panel()
	scene._inspect_site("town_hall")
	await shot("expansion_housing")
	scene.hud.close_workspace()
	scene.view.pointer_in_world = true
	scene.view.hover = Vector2i(38, 16)
	scene.view.ghost_kind = "underground_belt"
	scene.view.underground_exit = true
	world.plans.capture(world, Rect2i(36, 14, 1, 1))
	world.plans.place(world, Vector2i(38, 15))
	await shot("expansion_world")
	root.size = Vector2i(1100, 720)
	scene._open_factory()
	scene.hud.factory_panel.tab = "production"
	scene.hud.factory_panel.refresh()
	await shot("expansion_small")
	quit()
