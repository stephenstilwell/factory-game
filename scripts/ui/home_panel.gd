extends ColorRect
const Style = preload("res://scripts/ui/ui_style.gd")
const Catalog = preload("res://scripts/data/catalog.gd")
const Definitions = preload("res://scripts/data/home_catalog.gd")
signal close_requested
signal save_requested
var world: RefCounted
var entry_id := 0
var selected := "chair"
var direction := 0
var room: Control
var title_label: Label
var details: Label
var hint: Label
var make_button: Button
var undo_button: Button
var redo_button: Button
var floor_picker: OptionButton
var wall_picker: OptionButton
var choices: Dictionary = {}
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color = Color("101b22")
	mouse_filter = Control.MOUSE_FILTER_STOP
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(1000, 620)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	var header := HBoxContainer.new()
	box.add_child(header)
	title_label = Style.label("YOUR OLDBRIDGE COTTAGE", 23, Style.ACCENT)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_label)
	Style.button(header, "Save game", func(): save_requested.emit())
	Style.button(header, "Leave [Esc]", func(): close_requested.emit())
	box.add_child(Style.label("A home of your own / Outside time, factories and defenses are paused. Decoration grants no stat bonuses.", 14, Style.GOLD))
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 16)
	box.add_child(body)
	var side := VBoxContainer.new()
	side.custom_minimum_size.x = 310
	body.add_child(side)
	side.add_child(Style.label("FURNISHINGS / select, then make or place", 14, Style.ACCENT))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(310, 160)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	side.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for kind in Definitions.PIECES:
		var button := Style.button(list, Definitions.PIECES[kind].name, func(): selected = kind; refresh())
		button.tooltip_text = Definitions.PIECES[kind].description
		choices[kind] = button
	details = Style.label("", 14)
	details.custom_minimum_size = Vector2(310, 88)
	side.add_child(details)
	make_button = Style.button(side, "Make furnishing", func(): world.home.make(world, selected); refresh())
	var actions := HBoxContainer.new()
	side.add_child(actions)
	Style.button(actions, "Rotate [R]", func(): rotate())
	Style.button(actions, "Clear cursor [Q]", func(): selected = ""; refresh())
	var history := HBoxContainer.new()
	side.add_child(history)
	undo_button = Style.button(history, "Undo [Ctrl+Z]", func(): world.home.undo(world); refresh())
	redo_button = Style.button(history, "Redo [Ctrl+Y]", func(): world.home.undo(world, true); refresh())
	room = preload("res://scripts/ui/home_room.gd").new()
	body.add_child(room)
	room.room_clicked.connect(func(cell, pickup):
		if pickup:
			var index: int = world.home.at(cell)
			var old_direction: int = int(world.home.pieces[index].direction) if index >= 0 else direction
			var kind: String = world.home.pickup(world, cell)
			if not kind.is_empty():
				selected = kind
				direction = old_direction
		elif not selected.is_empty():
			var reason: String = world.home.placement_reason(selected, cell, direction)
			if not world.home.place(world, selected, cell, direction): hint.text = reason
			else: hint.text = "Placed " + Definitions.PIECES[selected].name + ". Right-click to move it."
		refresh())
	room.hover_changed.connect(func(cell):
		if not selected.is_empty(): hint.text = world.home.placement_reason(selected, cell, direction))
	var finishes := HBoxContainer.new()
	box.add_child(finishes)
	var floor_label := Style.label("Floor", 14)
	floor_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	finishes.add_child(floor_label)
	floor_picker = OptionButton.new()
	finishes.add_child(floor_picker)
	var wall_label := Style.label("Walls", 14)
	wall_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	finishes.add_child(wall_label)
	wall_picker = OptionButton.new()
	finishes.add_child(wall_picker)
	for picker in [floor_picker, wall_picker]:
		picker.custom_minimum_size.x = 230
		picker.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		for definition in Definitions.STYLES: picker.add_item(definition.name)
		picker.item_selected.connect(func(_index): world.home.finish(world, floor_picker.selected, wall_picker.selected); refresh())
	hint = Style.label("", 14, Style.GOLD)
	hint.custom_minimum_size.y = 20
	box.add_child(hint)
	box.add_child(Style.label("Left-click places owned furniture / Right-click picks up and selects / R rotates / Q clears cursor\nMoving pieces and changing unlocked finishes are free. Making a furnishing starts a fresh undo history.", 14, Style.MUTED))
	hide()
func open(state: RefCounted, id: int) -> void:
	world = state
	entry_id = id
	hint.text = "Choose a furnishing. Make one from your pack, then click a free room tile."
	show()
	refresh()
func refresh() -> void:
	if world == null: return
	for kind in choices:
		choices[kind].text = "%s / %d stored" % [Definitions.PIECES[kind].name, int(world.home.stock.get(kind, 0))]
		Style.select(choices[kind], kind == selected)
	if selected.is_empty():
		details.text = "Right-click any furnishing to pick it up and select it. Furniture is kept in your home collection."
		make_button.disabled = true
	else:
		var definition: Dictionary = Definitions.PIECES[selected]
		details.text = "%s\nCost: %s\nOwned, ready to place: %d" % [definition.description, Catalog.describe(definition.cost), int(world.home.stock.get(selected, 0))]
		make_button.text = "Barter 4 produce for rug" if selected == "rug" else "Make " + definition.name
		var reason: String = world.home.make_reason(world, selected)
		make_button.disabled = not reason.is_empty()
		make_button.tooltip_text = reason
	undo_button.disabled = world.home.undo_stack.is_empty()
	redo_button.disabled = world.home.redo_stack.is_empty()
	for picker in [floor_picker, wall_picker]:
		for index in Definitions.STYLES.size():
			picker.set_item_disabled(index, not world.home.style_available(world, index))
			picker.set_item_text(index, Definitions.STYLES[index].name + (" / discover region" if not world.home.style_available(world, index) else ""))
	floor_picker.select(world.home.floor_style)
	wall_picker.select(world.home.wall_style)
	room.world = world
	room.selected = selected
	room.direction = direction
	room.queue_redraw()
func rotate() -> void:
	direction = posmod(direction + 1, 4)
	refresh()
func handle_key(event: InputEventKey) -> void:
	if not event.pressed or event.echo: return
	if event.keycode == KEY_ESCAPE: close_requested.emit()
	elif event.keycode == KEY_R: rotate()
	elif event.keycode == KEY_Q: selected = ""; refresh()
	elif event.ctrl_pressed and event.keycode in [KEY_Z, KEY_Y]:
		world.home.undo(world, event.keycode == KEY_Y or event.shift_pressed)
		refresh()
