extends Node
## Two voices, infrequent context queries, boundary hysteresis and smooth crossfades.
const Catalog = preload("res://scripts/data/music_catalog.gd")
const FADE_SECONDS := 3.0
const HOLD_SECONDS := 20.0
const SETTLE_SECONDS := 5.0
signal track_changed(id: String)
var players: Array[AudioStreamPlayer] = []
var output_enabled := DisplayServer.get_name() != "headless"
var adaptive := true
var current := "wilds"
var candidate := ""
var candidate_time := 0.0
var dwell := HOLD_SECONDS
var poll := 0.0
var incoming := 0
var outgoing := 1
var fade := FADE_SECONDS
var duck := 1.0

func _ready() -> void:
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

func _load(index: int, id: String) -> void:
	var stream: AudioStreamWAV = Catalog.TRACKS[id].stream.duplicate()
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = roundi(stream.get_length() * stream.mix_rate)
	players[index].stream = stream
	if output_enabled: players[index].play()

func request(id: String) -> bool:
	if not Catalog.TRACKS.has(id) or id == current or fade < FADE_SECONDS: return false
	outgoing = incoming
	incoming = 1 - incoming
	_load(incoming, id)
	current = id
	fade = 0
	dwell = 0
	candidate = ""
	candidate_time = 0
	apply_mix()
	track_changed.emit(id)
	return true

func step(delta: float, world: RefCounted, paused: bool, suspended: bool) -> void:
	for player in players: player.stream_paused = suspended
	if suspended: return
	if fade < FADE_SECONDS:
		fade = minf(FADE_SECONDS, fade + delta)
		if fade >= FADE_SECONDS:
			players[outgoing].stop()
			players[outgoing].stream = null
	var target_duck := 0.5 if paused else 1.0
	duck = move_toward(duck, target_duck, delta * 1.5)
	apply_mix()
	if paused: return # Keep the musical bed; freeze context decisions with gameplay.
	dwell += delta
	poll += delta
	if poll < 1.0: return
	var elapsed := poll
	poll = 0
	var wanted := context(world) if adaptive else "hearth"
	if wanted == current:
		candidate = ""
		candidate_time = 0
		return
	if wanted != candidate:
		candidate = wanted
		candidate_time = 0
	else: candidate_time += elapsed
	if not adaptive or wanted == "beacon" or (candidate_time >= SETTLE_SECONDS and dwell >= HOLD_SECONDS): request(wanted)

func apply_mix() -> void:
	var progress := clampf(fade / FADE_SECONDS, 0, 1)
	# Equal-power fades avoid a volume dip; gain remains capped at -6 dB per voice.
	players[incoming].volume_linear = sin(progress * PI / 2) * duck * 0.5
	players[outgoing].volume_linear = cos(progress * PI / 2) * duck * 0.5

func _exit_tree() -> void:
	for player in players:
		player.stream_paused = false
		player.stop()
		player.stream = null
