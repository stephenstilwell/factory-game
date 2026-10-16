extends SceneTree
func _initialize() -> void: call_deferred("run")
func shot(name: String) -> void:
	await create_timer(0.2).timeout
	for i in range(5): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/verification/timber_" + name + ".png")
func run() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	scene.paused = true
	scene.view.paused = true
	scene.hud.story_panel.dismiss_silently()
	root.mode = Window.MODE_WINDOWED
	root.content_scale_size = Vector2i(1100, 720)
	root.size = Vector2i(1100, 720)
	var world = load("res://scripts/simulation/world.gd").new(74103)
	world.start()
	scene._bind_world(world)
	scene.camera.position = world.player_position * 48
	scene.hud.story_panel.present(world, "arrival")
	await shot("introduction")
	scene.hud.story_panel.dismiss_silently()
	await shot("opening")
	scene.hud.toggle_crafting()
	await shot("crafting")
	scene.hud.close_workspace()
	scene.hud.workspace.open_mode("town")
	scene.hud.refresh()
	await shot("first_project")
	scene.hud.close_workspace()
	# Explicit screenshot fixture; no supplies are added to new-game code.
	world.spawn("lumber_camp", Vector2i(20, 30), 0)
	world.spawn("cart_post", Vector2i(22, 30), 0)
	world.spawn("communal_hearth", Vector2i(20, 33), 0)
	world.early.delivered = 8
	world.early.phase = 1
	world.settlements.age = 1
	world.spawn("watermill", Vector2i(24, 31), 0)
	world.spawn("charcoal_kiln", Vector2i(24, 34), 0)
	world.player_position = Vector2(22.5, 32.5)
	world.previous_position = world.player_position
	scene.camera.position = world.player_position * 48
	scene.hud.refresh()
	await shot("stone_village")
	scene._inspect(Vector2i(24, 31))
	await shot("sawmill")
	scene.hud.close_workspace()
	world.early.phase = 2
	world.settlements.age = 2
	world.player_position = Vector2(24.5, 26.5)
	world.previous_position = world.player_position
	scene.camera.position = world.player_position * 48
	scene.hud.refresh()
	await shot("crossing")
	quit()
