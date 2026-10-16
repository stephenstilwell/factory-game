extends Button
const Icon = preload("res://scripts/ui/item_icon.gd")
const Style = preload("res://scripts/ui/ui_style.gd")
var owner_bar: VBoxContainer
var index := 0
var glyph: Control
var count_label: Label
var key_label: Label
var placeholder: Label

func _ready() -> void:
	custom_minimum_size = Vector2(62, 62)
	focus_mode = Control.FOCUS_NONE
	glyph = Icon.new()
	glyph.position = Vector2(13, 12)
	glyph.size = Vector2(38, 38)
	add_child(glyph)
	key_label = Style.label(str((index + 1) % 10), 12, Style.MUTED)
	key_label.position = Vector2(6, 2)
	add_child(key_label)
	count_label = Style.label("", 12, Style.TEXT)
	count_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	count_label.offset_left = -48
	count_label.offset_top = -20
	count_label.offset_right = -5
	count_label.offset_bottom = -3
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(count_label)
	placeholder = Style.label("+", 23, Style.MUTED)
	placeholder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(placeholder)
	for node in [glyph, key_label, count_label, placeholder]: node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pressed.connect(func(): owner_bar.activate(index))
	mouse_entered.connect(func(): owner_bar.describe(index))
	mouse_exited.connect(func(): owner_bar.describe(-1))

func refresh(id: String, amount: int, available: bool, selected: bool) -> void:
	glyph.visible = not id.is_empty() and available
	if glyph.visible:
		glyph.item_id = id
		glyph.modulate.a = 1.0 if amount > 0 else 0.35
		glyph.queue_redraw()
	count_label.visible = not id.is_empty() and available
	count_label.text = ("%.1fk" % (amount / 1000.0)) if amount >= 1000 else str(amount)
	count_label.add_theme_color_override("font_color", Style.TEXT if amount > 0 else Style.ERROR)
	placeholder.visible = id.is_empty() or not available
	placeholder.text = "+" if id.is_empty() else "·"
	var border := Style.GOLD if selected else Color("3a5050")
	var background := Color("38504a") if selected else Color("172729")
	add_theme_stylebox_override("normal", Style.panel(background, border))
	add_theme_stylebox_override("hover", Style.panel(background.lightened(0.15), Style.ACCENT))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			owner_bar.open_picker(index)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			owner_bar.assign(index, "")
			accept_event()

func _get_drag_data(_at: Vector2):
	var id: String = owner_bar.layout.item(owner_bar.layout.active_page, index)
	if id.is_empty() or not owner_bar.available(id): return null
	var preview := Label.new()
	preview.text = owner_bar.Catalog.item_name(id)
	set_drag_preview(preview)
	return {"type": "hotbar_shortcut", "owner": owner_bar.get_instance_id(), "page": owner_bar.layout.active_page, "slot": index, "revision": owner_bar.layout.revision}

func _can_drop_data(_at: Vector2, data) -> bool:
	return owner_bar.can_drop(data)

func _drop_data(_at: Vector2, data) -> void:
	owner_bar.drop_on(index, data)