extends SceneTree
func _initialize() -> void: call_deferred("run")
func shot(name: String) -> void:
 await create_timer(0.3).timeout
 for i in range(5): await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://.godot/verification/age_" + name + ".png")
func run() -> void:
 var scene = load("res://main.tscn").instantiate()
 root.add_child(scene)
 scene.set_process(false)
 scene.paused = true
 scene.view.paused = true
 root.mode = Window.MODE_WINDOWED
 root.content_scale_size = Vector2i(1100, 720)
 root.size = Vector2i(1100, 720)
 var world = load("res://tests/settlement_age_tests.gd").ready_town()
 scene._bind_world(world)
 scene.camera.position = world.player_position * 48
 await shot("timber")
 scene._inspect_site("town_hall")
 await shot("project_ready")
 scene.hud.town_panel.age_button.pressed.emit()
 scene.hud.refresh()
 await shot("project_completed")
 scene.hud.close_workspace()
 await shot("stone")
 for id in ["quarry", "orchard"]:
  world.player_position = Vector2(world.frontier.port(id)) + Vector2.ONE * 0.5
  world.previous_position = world.player_position
  scene.camera.position = world.player_position * 48
  await shot(id)
  scene._open_frontier(id)
  await shot(id + "_panel")
  scene.hud.frontier_panel.hide()
 quit()
