extends SceneTree
## Run with a native display backend to exercise actual window mode transitions.

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	for i in range(8): await process_frame
	if root.mode != Window.MODE_FULLSCREEN:
		push_error("Expected borderless fullscreen on startup")
		quit(1)
		return
	var key := InputEventKey.new()
	key.keycode = KEY_F11
	key.pressed = true
	scene._input(key)
	for i in range(4): await process_frame
	if root.mode != Window.MODE_WINDOWED:
		push_error("F11 did not return to windowed mode")
		quit(1)
		return
	scene.hud.fullscreen_button.pressed.emit()
	for i in range(8): await process_frame
	if root.mode != Window.MODE_FULLSCREEN:
		push_error("Display button did not restore borderless fullscreen")
		quit(1)
		return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://.godot/verification")
	root.get_texture().get_image().save_png("res://.godot/verification/fullscreen.png")
	print("PASS: fullscreen startup, F11 windowed toggle, display button fullscreen toggle. Window size: ", root.size)
	quit()
