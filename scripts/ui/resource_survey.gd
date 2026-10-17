extends ColorRect
## Explicit prospecting reports existing stock; it never creates or replenishes ore.
const Style = preload("res://scripts/ui/ui_style.gd")
const Catalog = preload("res://scripts/data/catalog.gd")
signal target_selected(data: Dictionary)
signal close_requested
var pin_list: OptionButton
var pin_name: LineEdit
var pin_hint: Label
var pin_actions: Array[Button] = []
var chart: Control
var tabs: TabContainer
var world: RefCounted
var seed_label: Label
var description: Label
var rows: Dictionary = {}
var results: Dictionary = {}

func _ready() -> void:
	color = Color(0.025, 0.045, 0.055, 0.90)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 650
	center.add_child(panel)
	tabs = TabContainer.new()
	panel.add_child(tabs)
	var chart_box := VBoxContainer.new()
	chart_box.name = "Settlement chart"
	tabs.add_child(chart_box)
	chart_box.add_child(Style.label("OLDBRIDGE / SETTLEMENT CHART", 24, Style.ACCENT))
	chart_box.add_child(Style.label("Drag to pan | Wheel to zoom | Right-click explored land to pin", 14, Style.MUTED))
	chart = preload("res://scripts/ui/settlement_map.gd").new()
	chart_box.add_child(chart)
	chart.pins_changed.connect(func(): refresh_pins(true))
	chart.notice.connect(func(text): pin_hint.text = text)
	var pin_row := HBoxContainer.new()
	chart_box.add_child(pin_row)
	pin_list = OptionButton.new()
	pin_list.custom_minimum_size.x = 230
	pin_list.fit_to_longest_item = false
	pin_list.clip_text = true
	pin_list.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	pin_row.add_child(pin_list)
	pin_list.item_selected.connect(func(_index):
		var pin: Dictionary = world.navigation.pins.get(pin_list.get_selected_id(), {})
		pin_name.text = pin.get("title", "")
		chart.pin_title = pin_name.text
		pin_actions[0].disabled = pin_name.text.strip_edges().is_empty())
	pin_name = LineEdit.new()
	pin_name.placeholder_text = "Pin name"
	pin_name.max_length = 40
	pin_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pin_row.add_child(pin_name)
	pin_name.text_changed.connect(func(text):
		chart.pin_title = text
		if not pin_actions.is_empty(): pin_actions[0].disabled = world == null or world.navigation.pins.is_empty() or text.strip_edges().is_empty())
	pin_actions.append(Style.button(pin_row, "Rename", func():
		world.navigation.rename(pin_list.get_selected_id(), pin_name.text)
		_pins_updated()))
	pin_actions.append(Style.button(pin_row, "Track / stop", func():
		var id := pin_list.get_selected_id()
		world.navigation.track(0 if world.navigation.active == id else id)
		_pins_updated()))
	pin_actions.append(Style.button(pin_row, "Remove", func():
		world.navigation.remove(pin_list.get_selected_id())
		_pins_updated()))
	pin_hint = Style.label("Pins save with your world. A purple compass guides you to the tracked pin.", 14, Style.MUTED)
	chart_box.add_child(pin_hint)
	chart_box.add_child(Style.label("Ivory: you | Gold: settlement / machines | Green: discoveries", 14))
	chart_box.add_child(Style.label("Ore: iron blue / copper orange / coal dark / stone sand. Zoom in and hover for stock.", 14, Style.MUTED))
	var chart_actions := HBoxContainer.new()
	chart_box.add_child(chart_actions)
	Style.button(chart_actions, "Center on player", func(): chart.open(world))
	Style.button(chart_actions, "Close [M / Esc]", func(): close_requested.emit())
	var box := VBoxContainer.new()
	box.name = "Resource survey"
	box.add_theme_constant_override("separation", 14)
	tabs.add_child(box)
	box.add_child(Style.label("RESOURCE SURVEY", 24, Style.ACCENT))
	seed_label = Style.label("", 14, Style.MUTED)
	box.add_child(seed_label)
	description = Style.label("", 16)
	box.add_child(description)
	for item in ["iron_ore", "copper_ore", "coal", "stone"]:
		var row := VBoxContainer.new()
		box.add_child(row)
		var label := Style.label("", 16)
		row.add_child(label)
		var button := Style.button(row, "Track " + Catalog.item_name(item), func():
			if results.has(item): target_selected.emit(results[item]))
		rows[item] = {"label": label, "button": button}
	var actions := HBoxContainer.new()
	box.add_child(actions)
	Style.button(actions, "Refresh survey", refresh)
	Style.button(actions, "Copy world seed", func(): DisplayServer.clipboard_set(str(world.terrain.seed_value)))
	Style.button(actions, "Clear marker", func(): target_selected.emit({}))
	Style.button(actions, "Close [M / Esc]", func(): close_requested.emit())
	hide()

func open(state: RefCounted) -> void:
	world = state
	chart.open(world)
	refresh_pins(true)
	tabs.current_tab = 0
	refresh()
	show()

func _pins_updated() -> void:
	world.changed.emit()
	chart.queue_redraw()
	refresh_pins()

func refresh_pins(prefer_active: bool = false) -> void:
	var selected := pin_list.get_selected_id() if pin_list.item_count > 0 else 0
	if prefer_active and world.navigation.active != 0: selected = world.navigation.active
	pin_list.clear()
	for id in world.navigation.pins:
		var pin: Dictionary = world.navigation.pins[id]
		pin_list.add_item(("* " if id == world.navigation.active else "") + pin.title, id)
		if id == selected: pin_list.select(pin_list.item_count - 1)
	var empty: bool = world.navigation.pins.is_empty()
	if empty: pin_list.add_item("No saved pins", 0)
	for button in pin_actions: button.disabled = empty
	pin_actions[0].disabled = empty or pin_name.text.strip_edges().is_empty()
	pin_hint.text = "%d / 32 pins. Purple compass = tracked pin; Track / stop toggles pin guidance." % world.navigation.pins.size()

func refresh() -> void:
	if world == null: return
	description.text = "Deposits are finite. Survey nearby patches, then follow a marker to relocate your drills. " + ("Frontier deposits grow larger and richer with distance." if world.terrain.generator_version == 2 else "This saved world retains its original terrain. New worlds use the improved resource distribution.")
	seed_label.text = "World seed: %d | Generator: %d | Local survey" % [world.terrain.seed_value, world.terrain.generator_version]
	results.clear()
	for item in rows:
		var found: Dictionary = world.terrain.find_resource(item, Vector2i(world.player_position.floor()), world.survey_radius())
		rows[item].button.disabled = found.is_empty()
		if found.is_empty():
			rows[item].label.text = "%s: no remaining patch found nearby. Explore farther and survey again." % Catalog.item_name(item)
		else:
			results[item] = found
			rows[item].label.text = "%s: %d units in patch | %.0f tiles away | (%d, %d)" % [Catalog.item_name(item), found.remaining, found.distance, found.cell.x, found.cell.y]
