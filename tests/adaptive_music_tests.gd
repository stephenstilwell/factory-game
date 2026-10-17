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
	test.check(Score.Catalog.PLAYLISTS.size() == 5 and Score.Catalog.TRACKS.size() == 10, "Five contexts have ten licensed recordings")
	var resources: Array = []
	for id in Score.Catalog.TRACKS:
		var stream: AudioStream = Score.Catalog.TRACKS[id].stream
		test.check(stream.get_length() > 20.0 and stream not in resources and not Score.Catalog.TRACKS[id].artist.is_empty(), "Each recording has unique audio and a credited composer: " + id)
		resources.append(stream)
		var playback := stream.instantiate_playback()
		playback.start(stream.get_length() * 0.5)
		var samples := playback.mix_audio(1.0, 4096)
		var energy := 0.0
		for frame in samples: energy += frame.length_squared()
		playback.stop()
		test.check(energy > 0.0001, "Compressed recording decodes audible samples: " + id)
	var levels: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/audio/licensed/levels.json"))
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/audio/licensed/manifest.json"))
	for entry in manifest.tracks:
		var hash := HashingContext.new()
		hash.start(HashingContext.HASH_SHA256)
		hash.update(FileAccess.get_file_as_bytes("res://" + entry.path))
		test.check(hash.finish().hex_encode() == entry.sha256 and entry.license == "CC0-1.0", "Downloaded asset matches licensed source manifest: " + entry.id)
		var adjustment: float = Score.Catalog.TRACKS[entry.id].gain_db
		test.check(absf(float(levels[entry.id].rms_db) + adjustment + 23.0) < 0.2 and float(levels[entry.id].peak_db) + adjustment < -2.8, "Recording gain matches measured average level with peak headroom: " + entry.id)
	for context_id in Score.Catalog.PLAYLISTS:
		var heard: Array = []
		for i in range(6): heard.append(score.next_track(context_id))
		var repeats := false
		for i in range(1, heard.size()):
			if heard[i] == heard[i - 1]: repeats = true
		test.check(not repeats and heard[0] != heard[1], "Context playlist avoids repeats across shuffle bag boundaries: " + context_id)
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
	var a: float = score.players[0].volume_linear / score.gains[0]
	var b: float = score.players[1].volume_linear / score.gains[1]
	test.check(is_equal_approx(a, b) and is_equal_approx(a * a + b * b, 0.25), "Crossfades use bounded equal-power gain")
	score.step(1.5, world, false, false)
	test.check(score.players[score.outgoing].stream == null and not score.players[score.incoming].stream.loop, "A completed fade releases the old stream and plays the new recording without a forced loop")
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
	advance(score, world, 3)
	var previous_track: String = score.track
	score.track_time = score.players[score.incoming].stream.get_length() - Score.FADE_SECONDS
	score.step(0.1, world, true, false)
	test.check(score.track != previous_track and score.current == "beacon" and score.fade == 0, "A completed song rotates within its context even while paused")
	var frozen_track: String = score.track
	var frozen_time: float = score.track_time
	score.step(100, world, false, true)
	test.check(score.track == frozen_track and score.track_time == frozen_time, "Focus loss freezes playlist advancement")
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
