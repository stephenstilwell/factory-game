extends SceneTree
## Rendered art review, with a model snapshot guard against visual side effects.
const Fixtures = preload("res://tests/fixtures.gd")
const Simulation = preload("res://scripts/simulation/simulation.gd")
const Saves = preload("res://scripts/persistence/save_service.gd")

func _initialize() -> void:
	call_deferred("_capture")

func shot(name: String) -> void:
	await create_timer(0.2).timeout
	for i in range(5): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/verification/" + name + ".png")

func _capture() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 800)
	DirAccess.make_dir_recursive_absolute("res://.godot/verification")
	scene.set_process(false)
	if not scene.paused: scene._toggle_pause()
	scene.view.paused = true
	var factory := Fixtures.demo()
	for i in range(80): Simulation.step(factory)
	scene._bind_world(factory)
	scene.camera.position = Vector2(20, 16) * 48
	scene.camera.zoom = Vector2.ONE * 1.3
	scene.view.animation_time = 3.0
	var before := Saves.encode(factory)
	await shot("art_factory")
	scene.view.animation_time = 3.4
	await shot("art_factory_motion")
	if Saves.encode(factory) != before:
		push_error("Rendering modified authoritative factory state")
		quit(1)
		return
	scene.hud.toggle_inventory()
	await shot("art_inventory")
	scene.hud.close_workspace()
	scene.view.ghost_kind = "furnace"
	scene.view.pointer_in_world = true
	scene.view.hover = Vector2i(20, 18)
	await shot("art_build_grid")
	scene.view.ghost_kind = ""
	scene.view.pointer_in_world = false
	var restored := Fixtures.defense_town()
	scene._bind_world(restored)
	scene.camera.position = Vector2(37, 16) * 48
	scene.camera.zoom = Vector2.ONE
	scene.view.animation_time = 4.0
	await shot("art_oldbridge_restored")
	# Compare the same landmarks/camera to their original ruins.
	for site in restored.settlements.sites.values():
		site.repaired = false
		site.health = 0
	scene.hud.refresh()
	await shot("art_oldbridge_ruins")
	print("Art review captured; render-only snapshots preserve simulation state.")
	quit()
