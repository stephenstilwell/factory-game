extends RefCounted
const Director = preload("res://scripts/audio/audio_director.gd")
const Score = preload("res://scripts/audio/adaptive_music.gd")
const World = preload("res://scripts/simulation/world.gd")
const Saves = preload("res://scripts/persistence/save_service.gd")

static func advance(score: Node, world: RefCounted, seconds: int, paused: bool = false) -> void:
	for i in range(seconds): score.step(1.0, world, paused, false)

static func run(test: SceneTree) -> void:
	var audio := Director.new()
	audio.settings_path = "user://adaptive_music_test_%d.cfg" % Time.get_ticks_usec()
	test.root.add_child(audio)
	audio.set_process(false)
	var score: Node = audio.music
	test.check(Score.Catalog.TRACKS.size() == 5, "Five original musical moods are available")
	var resources: Array = []
	for id in Score.Catalog.TRACKS:
		var stream: AudioStreamWAV = Score.Catalog.TRACKS[id].stream
		test.check(is_equal_approx(stream.get_length(), 48.0) and stream.mix_rate == 22050 and stream not in resources, "Each mood has its own rendered 48-second score: " + id)
		resources.append(stream)
		var raw := FileAccess.get_file_as_bytes(stream.resource_path)
		var energy := 0.0
		var peak := 0
		for frame in range(44, raw.size() - 1, 128):
			var value := absi(raw.decode_s16(frame))
			peak = maxi(peak, value)
			energy += value * value
		test.check(peak > 1000 and peak < 23000 and energy > 0 and absi(raw.decode_s16(44) - raw.decode_s16(raw.size() - 2)) < 3000, "Rendered score is audible, unclipped and continuous at the loop seam: " + id)
	var world := World.new()
	world.start()
	test.check(Score.context(world) == "wilds", "Empty timber worlds begin with the exploration theme")
	var home = world.spawn("communal_hearth", Vector2i(23, 14), 0)
	test.check(Score.context(world) == "hearth", "A healthy nearby communal shelter gets the home theme")
	home.health = 0
	test.check(Score.context(world) == "wilds", "A disabled shelter does not claim the home music")
	world.player_position = Vector2(world.frontier.sites.orchard.origin)
	test.check(Score.context(world) == "farmlands", "The orchard biome gets its pastoral score")
	world.player_position = Vector2(world.frontier.sites.quarry.origin)
	test.check(Score.context(world) == "highlands", "Greybank gets the highland score")
	world.defense.phase = "warning"
	test.check(Score.context(world) == "beacon", "Beacon preparation takes priority over biome music")
	world.defense.phase = "active"
	test.check(Score.context(world) == "beacon", "An active defense keeps the same score without restarting")
	world.defense.phase = "idle"
	world.player_position = Vector2(world.frontier.sites.orchard.origin)
	audio.bind_world(world)
	test.check(score.current == "farmlands" and score.fade == 0, "World binding crossfades directly into its current context")
	score.step(1.5, world, false, false)
	var a: float = score.players[0].volume_linear
	var b: float = score.players[1].volume_linear
	test.check(is_equal_approx(a, b) and is_equal_approx(a * a + b * b, 0.25), "Crossfades use bounded equal-power gain")
	score.step(1.5, world, false, false)
	test.check(score.players[score.outgoing].stream == null and score.players[score.incoming].stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "A completed fade releases the old stream and loops the new one")
	for i in range(3):
		world.player_position = Vector2(world.frontier.sites.quarry.origin)
		advance(score, world, 3)
		world.player_position = Vector2(world.frontier.sites.orchard.origin)
		advance(score, world, 3)
	test.check(score.current == "farmlands", "Brief biome boundary crossings cannot churn music")
	world.player_position = Vector2(world.frontier.sites.quarry.origin)
	advance(score, world, 7)
	test.check(score.current == "highlands", "A settled biome change eventually selects its score")
	advance(score, world, 3)
	world.defense.phase = "warning"
	advance(score, world, 1)
	test.check(score.current == "beacon", "Defense music bypasses the peaceful minimum dwell")
	var fading: float = score.fade
	score.step(10.0, world, false, true)
	test.check(score.fade == fading, "Focus suspension freezes both playback transition clocks")
	world.defense.phase = "idle"
	advance(score, world, 10, true)
	test.check(score.current == "beacon" and is_equal_approx(score.duck, 0.5), "Pausing ducks music and freezes context selection")
	advance(score, world, 25)
	test.check(score.current == "highlands" and is_equal_approx(score.duck, 1.0), "Normal music and volume return after pause and defense")
	advance(score, world, 3)
	score.set_adaptive(false, world)
	advance(score, world, 6)
	test.check(score.current == "hearth", "Fixed music mode selects a calm theme")
	world.defense.phase = "active"
	advance(score, world, 25)
	test.check(score.current == "hearth", "Fixed mode ignores biome and combat changes")
	score.set_adaptive(true, world)
	advance(score, world, 4)
	test.check(score.current == "beacon", "Re-enabling adaptation recognizes an ongoing defense")
	world.defense.phase = "idle"
	var data: Dictionary = Saves.encode(world)
	advance(score, world, 60)
	test.check(Saves.encode(world) == data and score.get_child_count() == 2, "Music neither mutates saves nor creates unbounded players")
	audio.adaptive_music = false
	audio.save_settings()
	var config := ConfigFile.new()
	test.check(config.load(audio.settings_path) == OK and config.get_value("music", "adaptive", true) == false, "Adaptive music preference saves independently of gameplay")
	var path: String = audio.settings_path
	audio.settings_timer.stop()
	audio.queue_free()
	await test.process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
