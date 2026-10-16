extends SceneTree
## Native playback/context smoke and pause-menu screenshot; not a performance benchmark.
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	scene.audio.set_process(false)
	scene.hud.story_panel.dismiss_silently()
	scene.paused = true
	scene.view.paused = true
	root.mode = Window.MODE_WINDOWED
	root.content_scale_size = Vector2i(1100, 720)
	root.size = Vector2i(1100, 720)
	var world = scene.world
	var score = scene.audio.music
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), -18)
	for id in ["wilds", "hearth", "farmlands", "highlands", "beacon"]:
		world.defense.phase = "idle"
		match id:
			"wilds": world.player_position = Vector2(24.5, 12.5)
			"hearth":
				world.spawn("communal_hearth", Vector2i(23, 14), 0)
				world.player_position = Vector2(24.5, 12.5)
			"farmlands": world.player_position = Vector2(world.frontier.sites.orchard.origin)
			"highlands": world.player_position = Vector2(world.frontier.sites.quarry.origin)
			"beacon": world.defense.phase = "warning"
		scene.camera.position = world.player_position * 48
		scene.audio.bind_world(world)
		for i in range(120):
			score.step(1.0 / 30, world, false, false)
			await process_frame
		var player: AudioStreamPlayer = score.players[score.incoming]
		if score.current != id or (score.output_enabled and (not player.playing or player.get_playback_position() <= 0)):
			push_error("Native music playback failed: " + id)
			quit(1)
			return
		print("Native music playing: ", id, " at ", player.get_playback_position())
	scene.hud.pause_menu.show()
	for i in range(5): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/verification/adaptive_music_options.png")
	score.step(0.1, world, false, true)
	if score.output_enabled and not score.players[score.incoming].stream_paused:
		push_error("Music did not suspend")
		quit(1)
		return
	quit()
