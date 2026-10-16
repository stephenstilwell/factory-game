extends ColorRect
## Explicit prospecting reports existing stock; it never creates or replenishes ore.
const Style = preload("res://scripts/ui/ui_style.gd")
const Catalog = preload("res://scripts/data/catalog.gd")
signal target_selected(data: Dictionary)
signal close_requested
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
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
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
	refresh()
	show()

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
