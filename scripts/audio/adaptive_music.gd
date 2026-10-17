extends Node
## Two reusable voices; context hysteresis plus independent per-context shuffle bags.
const Catalog = preload("res://scripts/data/music_catalog.gd")
const FADE_SECONDS := 3.0
const HOLD_SECONDS := 20.0
const SETTLE_SECONDS := 5.0
signal track_changed(id: String)
var players: Array[AudioStreamPlayer] = []
var output_enabled := DisplayServer.get_name() != "headless"
var adaptive := true
var current := "wilds"
var track := ""
var candidate := ""
var candidate_time := 0.0
var dwell := HOLD_SECONDS
var poll := 0.0
var incoming := 0
var outgoing := 1
var fade := FADE_SECONDS
var duck := 1.0
var track_time := 0.0
var gains := [1.0, 1.0]
var bags: Dictionary = {}
var last_tracks: Dictionary = {}
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize() # Never change the simulation's random sequence.
	for i in range(2):
		var player := AudioStreamPlayer.new()
		player.bus = "Music"
		add_child(player)
		players.append(player)
	_load(0, current)
	apply_mix()

static func context(world: RefCounted) -> String:
	if world == null: return "wilds"
	if world.defense.phase in ["warning", "active"]: return "beacon"
	if world.early.enabled:
		for id in world.by_kind.communal_hearth:
			var home = world.entities[id]
			if home.health > 0 and world.player_position.distance_squared_to(Vector2(home.cell) + Vector2.ONE * 0.5) <= 100: return "hearth"
	if world.settlements.enabled:
		for site in world.settlements.sites.values():
			if site.repaired and site.health > 0 and world.player_position.distance_squared_to(Vector2(site.origin) + Vector2(1.5, 1.5)) <= 100: return "hearth"
	var biome: int = world.frontier.landscape_index(Vector2i(world.player_position.floor()))
	if biome == 1: return "farmlands"
	if biome == 2: return "highlands"
	return "wilds"


func bind_world(world: RefCounted) -> void:
	candidate = ""
	candidate_time = 0
	poll = 0
	dwell = HOLD_SECONDS
	request(context(world) if adaptive else "hearth")

func set_adaptive(value: bool, world: RefCounted) -> void:
	adaptive = value
	candidate = ""
	candidate_time = 0
	dwell = HOLD_SECONDS
	request(context(world) if adaptive else "hearth")

func next_track(id: String) -> String:
	if not bags.has(id) or bags[id].is_empty():
		var bag: Array = Catalog.PLAYLISTS[id].duplicate()
		for i in range(bag.size() - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var swap = bag[i]
			bag[i] = bag[j]
			bag[j] = swap
		if bag.size() > 1 and bag[0] == last_tracks.get(id, ""):
			var swap = bag[0]
			bag[0] = bag[1]
			bag[1] = swap
		bags[id] = bag
	var result: String = bags[id].pop_front()
	last_tracks[id] = result
	return result

func _load(index: int, id: String) -> void:
	track = next_track(id)
	var entry: Dictionary = Catalog.TRACKS[track]
	var stream: AudioStream = entry.stream.duplicate()
	# Recordings play to their endings, then rotate; never force a full-song hard loop.
	if stream is AudioStreamWAV: stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	elif stream is AudioStreamOggVorbis or stream is AudioStreamMP3: stream.loop = false
	players[index].stream = stream
	gains[index] = db_to_linear(float(entry.gain_db))
	track_time = 0
	if output_enabled: players[index].play()

func request(id: String, rotate: bool = false) -> bool:
	if not Catalog.PLAYLISTS.has(id) or (id == current and not rotate) or fade < FADE_SECONDS: return false
	outgoing = incoming
	incoming = 1 - incoming
	_load(incoming, id)
	current = id
	fade = 0
	if not rotate:
		dwell = 0
		candidate = ""
		candidate_time = 0
	apply_mix()
	track_changed.emit(id)
	return true

func step(delta: float, world: RefCounted, paused: bool, suspended: bool) -> void:
	for player in players: player.stream_paused = suspended
	if suspended: return
	track_time += delta
	if fade < FADE_SECONDS:
		fade = minf(FADE_SECONDS, fade + delta)
		if fade >= FADE_SECONDS:
			players[outgoing].stop()
			players[outgoing].stream = null
	var target_duck := 0.5 if paused else 1.0
	duck = move_toward(duck, target_duck, delta * 1.5)
	apply_mix()
	# Follow actual audio position when a device is active, a test clock otherwise.
	var elapsed: float = players[incoming].get_playback_position() if output_enabled else track_time
	var duration: float = players[incoming].stream.get_length()
	if fade >= FADE_SECONDS and elapsed >= duration - FADE_SECONDS:
		request(current, true)
	elif output_enabled and fade >= FADE_SECONDS and not players[incoming].playing:
		request(current, true) # Recover if a frame skipped the end transition.
	if paused: return
	dwell += delta
	poll += delta
	if poll < 1.0: return
	var interval := poll
	poll = 0
	var wanted := context(world) if adaptive else "hearth"
	if wanted == current:
		candidate = ""
		candidate_time = 0
		return
	if wanted != candidate:
		candidate = wanted
		candidate_time = 0
	else: candidate_time += interval
	if not adaptive or wanted == "beacon" or (candidate_time >= SETTLE_SECONDS and dwell >= HOLD_SECONDS): request(wanted)

func apply_mix() -> void:
	var progress := clampf(fade / FADE_SECONDS, 0, 1)
	players[incoming].volume_linear = sin(progress * PI / 2) * duck * 0.5 * gains[incoming]
	players[outgoing].volume_linear = cos(progress * PI / 2) * duck * 0.5 * gains[outgoing]

func _exit_tree() -> void:
	for player in players:
		player.stream_paused = false
		player.stop()
		player.stream = null
