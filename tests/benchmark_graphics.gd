extends SceneTree
const Fixtures = preload("res://tests/fixtures.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	scene.paused = true
	scene.view.paused = true
	scene.hud.story_panel.dismiss_silently()
	var world := Fixtures.industrial()
	for y in range(12):
		for x in range(20):
			var furnace = world.spawn("furnace",Vector2i(140+x,140+y),0)
			furnace.status = "Working"
	world.player_position = Vector2(150,146)
	world.previous_position = world.player_position
	scene._bind_world(world)
	scene.camera.position = world.player_position*48
	for dimensions in [Vector2i(1100,720),Vector2i(3840,2160)]:
		root.mode = Window.MODE_WINDOWED
		root.size = dimensions
		root.content_scale_size = dimensions
		for mode in range(3):
			var enabled := mode > 0
			scene.view.ambient_enabled = enabled
			scene.view.detailed_lighting = mode == 2
			for warmup in range(12): await process_frame
			var began := Time.get_ticks_usec()
			for sample in range(24): await process_frame
			var frame_ms := (Time.get_ticks_usec()-began)/24000.0
			print("Graphics benchmark ",dimensions," ambient=",enabled," detailed=",scene.view.detailed_lighting," ms/frame=",snappedf(frame_ms,0.01)," lights=",scene.view.lighting.sources.size()," nodes=",scene.view.lighting.get_child_count()," draw_calls=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	print("Native graphics benchmark complete")
	quit()
