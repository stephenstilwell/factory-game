extends ColorRect
const Style = preload("res://scripts/ui/ui_style.gd")
const Definitions = preload("res://scripts/data/frontier_catalog.gd")
signal close_requested
var world: RefCounted
var selected := ""
var site_buttons: Dictionary = {}
var title: Label
var description: Label
var reward: Label
var state_label: Label
var claim_button: Button
var track_button: Button
var puzzle: VBoxContainer
var cells: Dictionary = {}
var result_label: Label
var timer := 0.0
var leads_hint: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color = Color(0.02, 0.04, 0.045, 0.86)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(920, 600)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var header := HBoxContainer.new()
	box.add_child(header)
	var heading := Style.label("BEYOND OLDBRIDGE • DISCOVERIES", 22, Style.ACCENT)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	Style.button(header, "Close [Esc / L]", func(): close_requested.emit())
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 18)
	box.add_child(body)
	var list := VBoxContainer.new()
	list.custom_minimum_size.x = 230
	body.add_child(list)
	list.add_child(Style.label("PLACES & LEADS", 14, Style.GOLD))
	for id in Definitions.SITES:
		var button := Style.button(list, Definitions.SITES[id].name, func(): selected = id; refresh())
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		site_buttons[id] = button
	leads_hint = Style.label("", 13, Style.MUTED)
	list.add_child(leads_hint)
	var detail := VBoxContainer.new()
	detail.custom_minimum_size.x = 610
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_theme_constant_override("separation", 8)
	body.add_child(detail)
	title = Style.label("", 22, Style.ACCENT)
	detail.add_child(title)
	state_label = Style.label("", 14, Style.GOLD)
	detail.add_child(state_label)
	description = Style.label("", 15)
	detail.add_child(description)
	reward = Style.label("", 14, Style.GOLD)
	detail.add_child(reward)
	var actions := HBoxContainer.new()
	detail.add_child(actions)
	track_button = Style.button(actions, "Track lead", func():
		world.frontier.target = "" if world.frontier.target == selected else selected
		world.changed.emit()
		refresh())
	claim_button = Style.button(actions, "Recover discovery", func(): world.frontier.claim(world, selected); refresh())
	puzzle = VBoxContainer.new()
	puzzle.add_theme_constant_override("separation", 6)
	detail.add_child(puzzle)
	puzzle.add_child(Style.label("LOANED SORTING TABLE • no pack items used\nLeft-click places / rotates a conveyor. Right-click removes. Route A and B to their matching docks around the wall.", 13, Style.MUTED))
	var grid := GridContainer.new()
	grid.columns = 7
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	puzzle.add_child(grid)
	for y in range(5):
		for x in range(7):
			var cell := Vector2i(x, y)
			var button := Style.button(grid, "", func(): world.frontier.edit_belt(world, cell); refresh())
			button.custom_minimum_size = Vector2(63, 32)
			for state in ["normal", "hover", "pressed", "disabled", "focus"]:
				var tile_style := Style.panel(Color("293e40"), Color("688278"))
				tile_style.set_content_margin_all(4)
				button.add_theme_stylebox_override(state, tile_style)
			button.add_theme_font_size_override("font_size", 15)
			button.gui_input.connect(func(event):
				if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
					world.frontier.edit_belt(world, cell, true)
					refresh()
					button.accept_event())
			cells[cell] = button
	result_label = Style.label("", 13, Style.GOLD)
	puzzle.add_child(result_label)
	var table_actions := HBoxContainer.new()
	puzzle.add_child(table_actions)
	Style.button(table_actions, "Test cargo routes", _test_routes)
	Style.button(table_actions, "Clear table", func():
		world.frontier.reset_table(world)
		refresh())
	hide()

func open_panel(state: RefCounted, id: String = "") -> void:
	world = state
	if world.frontier.sites.has(id): selected = id
	if not world.frontier.sites.has(selected):
		selected = "" if world.frontier.sites.is_empty() else world.frontier.sites.keys()[0]
	refresh()
	show()

func _process(delta: float) -> void:
	if not visible: return
	timer += delta
	if timer >= 0.5:
		timer = 0
		refresh()

func _test_routes() -> void:
	if world == null or selected != "depot": return
	var reason: String = world.frontier.interaction_reason(world, "depot")
	if not reason.is_empty():
		result_label.text = reason
		return
	result_label.text = world.frontier.evaluate().message
	if world.frontier.evaluate().success: world.feedback_requested.emit("success", world.frontier.port("depot"))

func refresh() -> void:
	if world == null: return
	leads_hint.text = "Walk to the marked entrance to investigate; tracking does not teleport.\n\n" + ("Greybank supports rebuilding the crossing. Other discoveries are optional. Beacon defenses remain your choice." if world.early.enabled else "The factory keeps running. Exploration is optional; beacon defenses remain your choice.")
	for id in site_buttons:
		var exists: bool = world.frontier.sites.has(id)
		var found: bool = exists and world.frontier.sites[id].discovered
		site_buttons[id].disabled = not exists
		site_buttons[id].text = Definitions.SITES[id].name + ("\nRECOVERED" if world.frontier.claimed(id) else ("\nDISCOVERED" if found else "\nRUMOR"))
		Style.select(site_buttons[id], id == selected)
	if selected.is_empty():
		title.text = "No leads in this world yet."
		puzzle.hide()
		claim_button.hide()
		track_button.hide()
		return
	var definition: Dictionary = Definitions.SITES[selected]
	var record: Dictionary = world.frontier.sites[selected]
	var reason: String = world.frontier.interaction_reason(world, selected)
	title.text = definition.name
	if definition.has("biome"): state_label.tooltip_text = definition.biome
	else: state_label.tooltip_text = ""
	var distance: int = ceili(world.player_position.distance_to(Vector2(world.frontier.port(selected)) + Vector2.ONE * 0.5))
	state_label.text = ("RECOVERED" if record.claimed else ("DISCOVERED" if record.discovered else "RUMOR")) + " • %d tiles away" % distance
	if definition.has("biome"): state_label.text += "\n" + definition.biome
	description.text = definition.story if record.discovered else definition.hint
	description.visible = selected != "depot" or not record.discovered
	reward.text = "REWARD\n" + definition.reward
	track_button.show()
	track_button.text = "Stop tracking" if world.frontier.target == selected else "Track entrance"
	claim_button.show()
	claim_button.disabled = record.claimed or not reason.is_empty() or (selected == "depot" and not world.frontier.evaluate().success)
	claim_button.text = "Recovered" if record.claimed else ("Restore depot" if selected == "depot" else "Recover discovery")
	claim_button.tooltip_text = reason if not reason.is_empty() else "Rewards are granted once. Salvage requires enough pack space for the whole bundle."
	puzzle.visible = selected == "depot" and record.discovered
	if not reason.is_empty(): state_label.text += "\n" + reason
	if not puzzle.visible: return
	for cell in cells:
		var button: Button = cells[cell]
		button.disabled = not world.frontier.editable(cell) or not reason.is_empty() or record.claimed
		button.text = ["→", "↓", "←", "↑"][world.frontier.board[cell]] if world.frontier.board.has(cell) else "·"
		button.tooltip_text = "Place / rotate conveyor • Right-click to remove"
		if cell in Definitions.BLOCKED: button.text = "WALL"
		if cell.x == 0: button.text = "A →" if cell.y == 1 else ("B →" if cell.y == 3 else "")
		if cell.x == 6: button.text = "A" if cell.y == 1 else ("B" if cell.y == 3 else "")
		button.add_theme_color_override("font_color", Style.GOLD if cell.y <= 1 else Style.ACCENT)
	result_label.text = "%d / %d loaned conveyors\n%s" % [world.frontier.board.size(), Definitions.MAX_BELTS, world.frontier.evaluate().message]
