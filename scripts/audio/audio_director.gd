extends Node
## Presentation-only audio: bounded voices, cue cooldowns, separate buses, local preferences.
const SETTINGS_PATH := "user://audio_settings.cfg"
const CUES := {
	"damage": preload("res://assets/audio/mine.wav"),
	"ui": preload("res://assets/audio/ui.wav"),
	"open": preload("res://assets/audio/open.wav"),
	"close": preload("res://assets/audio/close.wav"),
	"mine": preload("res://assets/audio/mine.wav"),
	"build": preload("res://assets/audio/build.wav"),
	"pickup": preload("res://assets/audio/pickup.wav"),
	"transfer": preload("res://assets/audio/transfer.wav"),
	"craft": preload("res://assets/audio/craft.wav"),
	"success": preload("res://assets/audio/success.wav"),
	"repair": preload("res://assets/audio/repair.wav"),
	"machine": preload("res://assets/audio/machine.wav"),
	"warning": preload("res://assets/audio/warning.wav"),
	"shot": preload("res://assets/audio/shot.wav"),
}
const Score = preload("res://scripts/audio/adaptive_music.gd")
var output_enabled := DisplayServer.get_name() != "headless"
var settings_path := SETTINGS_PATH
var levels := {"Master": 0.75, "Music": 0.35, "SFX": 0.7}
var voices: Array[AudioStreamPlayer] = []
var music: Node
var adaptive_music := true
var music_caption: Label
var cooldowns: Dictionary = {}
var world: RefCounted
var suspended := false
var machine_timer := 0.0
var ui_visible := false
var panel: Node
var game_paused := false
var settings_timer: Timer

func _ready() -> void:
	for bus_name in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus_name) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
			AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
	var config := ConfigFile.new()
	if config.load(settings_path) == OK:
		for bus_name in levels:
			var value = config.get_value("volume", bus_name, levels[bus_name])
			if (value is float or value is int) and is_finite(float(value)): levels[bus_name] = clampf(float(value), 0.0, 1.0)
	var stored_adaptive = config.get_value("music", "adaptive", true)
	adaptive_music = stored_adaptive if stored_adaptive is bool else true
	for bus_name in levels: _apply(bus_name)
	for i in range(10):
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		voices.append(player)
	music = Score.new()
	music.output_enabled = output_enabled
	music.adaptive = adaptive_music
	add_child(music)
	music.track_changed.connect(func(_id): _refresh_music_caption())
	settings_timer = Timer.new()
	settings_timer.one_shot = true
	settings_timer.wait_time = 0.4
	add_child(settings_timer)
	settings_timer.timeout.connect(save_settings)

func bind_world(state: RefCounted) -> void:
	if world != null:
		world.feedback_requested.disconnect(_feedback)
		world.hand_resource_extracted.disconnect(_mined)
		world.structure_repaired.disconnect(_repaired)
		world.skill_progressed.disconnect(_skill)
	world = state
	world.feedback_requested.connect(_feedback)
	world.hand_resource_extracted.connect(_mined)
	world.structure_repaired.connect(_repaired)
	world.skill_progressed.connect(_skill)
	cooldowns.clear()
	machine_timer = 0.0
	for voice in voices: voice.stop()
	music.bind_world(world)

func watch_ui(root_node: Node) -> void:
	panel = root_node
	_connect_buttons(panel)
	get_tree().node_added.connect(_watch_node)

func _watch_node(node: Node) -> void:
	if panel != null and panel.is_ancestor_of(node): _connect_buttons(node)

func _connect_buttons(node: Node) -> void:
	if node is BaseButton and not node.has_meta("audio_connected"):
		node.set_meta("audio_connected", true)
		node.pressed.connect(func(): play_cue("ui"))
	for child in node.get_children(): _connect_buttons(child)

func set_interface_state(visible: bool, paused: bool) -> void:
	if visible != ui_visible:
		play_cue("open" if visible else "close")
		ui_visible = visible
	game_paused = paused

func _feedback(cue: String, cell: Vector2i) -> void:
	play_cue(cue, cell)
func _mined(cell: Vector2i, _item: String) -> void:
	play_cue("mine", cell)
func _repaired(cell: Vector2i) -> void:
	play_cue("repair", cell)
func _skill(_id: String, _amount: int, _level: int, leveled: bool) -> void:
	if leveled: play_cue("success")

func play_cue(cue: String, cell: Variant = null) -> bool:
	if not CUES.has(cue) or suspended or levels.Master <= 0 or levels.SFX <= 0: return false
	var now := Time.get_ticks_msec()
	if now < int(cooldowns.get(cue, 0)): return false
	var gain := 1.0
	if cell != null and world != null:
		gain = clampf(1.0 - world.player_position.distance_to(Vector2(cell) + Vector2(0.5, 0.5)) / 18.0, 0.0, 1.0)
		if gain <= 0.0: return false
	for voice in voices:
		if voice.playing: continue
		cooldowns[cue] = now + (400 if cue in ["success", "warning"] else 90)
		voice.stream = CUES[cue]
		voice.volume_db = linear_to_db(gain) - (12.0 if cue == "machine" else 3.0)
		if output_enabled: voice.play()
		return true
	return false

func _process(delta: float) -> void:
	music.step(minf(delta, 0.25), world, game_paused, suspended)
	if world == null or suspended or ui_visible or game_paused: return
	machine_timer -= delta
	if machine_timer > 0: return
	machine_timer = 1.8
	# At most one nearby machine accent, regardless of factory size.
	var center := Vector2i(world.player_position.floor())
	for x in range(center.x - 8, center.x + 9):
		for y in range(center.y - 8, center.y + 9):
			var entity = world.at(Vector2i(x, y))
			if entity != null and entity.kind in ["drill", "furnace", "assembler"] and (entity.status == "Working" or entity.status.begins_with("Mining ")):
				play_cue("machine", entity.cell)
				return

func _apply(bus_name: String) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	var value: float = levels[bus_name]
	AudioServer.set_bus_mute(index, value <= 0.0)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(value, 0.0001)))

func set_level(bus_name: String, value: float) -> void:
	if not levels.has(bus_name) or not is_finite(value): return
	levels[bus_name] = clampf(value, 0.0, 1.0)
	_apply(bus_name)
	settings_timer.start()

func save_settings() -> void:
	var config := ConfigFile.new()
	for bus_name in levels: config.set_value("volume", bus_name, levels[bus_name])
	config.set_value("music", "adaptive", adaptive_music)
	if config.save(settings_path) != OK: push_warning("Audio preferences could not be saved.")

func create_controls(parent: Node) -> void:
	var heading := Label.new()
	heading.text = "SOUND"
	parent.add_child(heading)
	for bus_name in ["Master", "Music", "SFX"]:
		var row := HBoxContainer.new()
		parent.add_child(row)
		var label := Label.new()
		label.text = "Sound effects" if bus_name == "SFX" else bus_name
		label.custom_minimum_size.x = 125
		row.add_child(label)
		var slider := HSlider.new()
		slider.min_value = 0
		slider.max_value = 100
		slider.step = 1
		slider.value = float(levels[bus_name]) * 100.0
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.custom_minimum_size.x = 200
		row.add_child(slider)
		var percentage := Label.new()
		percentage.custom_minimum_size.x = 48
		percentage.text = "%d%%" % slider.value
		row.add_child(percentage)
		slider.value_changed.connect(func(value):
			percentage.text = "%d%%" % value
			set_level(bus_name, value / 100.0))
		slider.drag_ended.connect(func(_changed): play_cue("ui"))
	var adaptive_toggle := CheckButton.new()
	adaptive_toggle.text = "Music follows places and beacon activity"
	adaptive_toggle.button_pressed = adaptive_music
	adaptive_toggle.tooltip_text = "Smooth transitions between home, wilderness, farmland, highlands and defense. Disable for a fixed calm theme. Music volume still controls both modes."
	parent.add_child(adaptive_toggle)
	adaptive_toggle.toggled.connect(func(value):
		adaptive_music = value
		music.set_adaptive(value, world)
		settings_timer.start())
	music_caption = Label.new()
	music_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(music_caption)
	_refresh_music_caption()
	var next := Button.new()
	next.text = "Next music track"
	parent.add_child(next)
	next.pressed.connect(func(): music.request(music.current, true))
	var credits := Button.new()
	credits.text = "Music credits"
	parent.add_child(credits)
	credits.pressed.connect(_show_music_credits)

func _show_music_credits() -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "Music credits / CC0 1.0"
	var text := RichTextLabel.new()
	text.custom_minimum_size = Vector2(650, 340)
	text.text = Score.Catalog.credits_text()
	dialog.add_child(text)
	add_child(dialog)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered()

func _refresh_music_caption() -> void:
	if music_caption != null: music_caption.text = "Now playing: " + Score.Catalog.TRACKS[music.track].title + " — " + Score.Catalog.TRACKS[music.track].artist

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		suspended = true
		for voice in voices: voice.stop()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN: suspended = false

func _exit_tree() -> void:
	for voice in voices:
		voice.stop()
		voice.stream = null
	if settings_timer != null and not settings_timer.is_stopped(): save_settings()