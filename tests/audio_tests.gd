extends RefCounted
const Director = preload("res://scripts/audio/audio_director.gd")
const World = preload("res://scripts/simulation/world.gd")

static func run(test: SceneTree) -> void:
	var audio := Director.new()
	audio.settings_path = "user://factory_audio_test_%d.cfg" % Time.get_ticks_usec()
	test.root.add_child(audio)
	test.check((audio.music.playing or not audio.output_enabled) and audio.music.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD and is_equal_approx(audio.music.stream.get_length(), 24.0), "Original ambient music starts with a valid 24-second loop")
	test.check(audio.voices.size() == 10 and AudioServer.get_bus_index("Music") >= 0 and AudioServer.get_bus_index("SFX") >= 0, "Music and effects have separate buses and a bounded voice pool")
	for cue in Director.CUES:
		test.check(Director.CUES[cue].get_length() > 0, "Audio palette contains playable " + cue)
	var world := World.new()
	world.player_position = Vector2(5.5, 5.5)
	world.player.add("furnace")
	var cues: Array = []
	world.feedback_requested.connect(func(cue, _cell): cues.append(cue))
	audio.bind_world(world)
	test.check(world.build("furnace", Vector2i(6, 6), 0) and cues == ["build"], "Successful construction emits one semantic audio event")
	test.check(not world.build("furnace", Vector2i(7, 6), 0) and cues == ["build"], "Rejected construction does not emit a success sound")
	audio.bind_world(World.new())
	test.check(not world.feedback_requested.is_connected(audio._feedback) and audio.world.feedback_requested.is_connected(audio._feedback), "Loading a world disconnects old audio listeners")
	audio.set_level("SFX", 0.0)
	test.check(AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")) and not audio.play_cue("mine"), "Muted effects produce no new voices")
	audio.set_level("SFX", 0.7)
	test.check(audio.play_cue("ui") and not audio.play_cue("ui"), "Repeated cues are rate limited")
	test.check(not audio.play_cue("mine", Vector2i(10000, 10000)), "Distant gameplay cues are inaudible")
	audio.save_settings()
	var config := ConfigFile.new()
	test.check(config.load(audio.settings_path) == OK and is_equal_approx(float(config.get_value("volume", "SFX")), 0.7), "Volume preferences persist outside gameplay saves")
	audio._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	test.check(audio.suspended and not audio.play_cue("shot"), "Losing application focus stops effects and suspends new sounds")
	audio._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	test.check(not audio.suspended, "Application focus restores audio")
	var path: String = audio.settings_path
	audio.settings_timer.stop()
	audio.queue_free()
	await test.process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))