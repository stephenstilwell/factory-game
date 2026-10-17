extends Button

const Catalog = preload("res://scripts/data/catalog.gd")
const Icon = preload("res://scripts/ui/item_icon.gd")
const Style = preload("res://scripts/ui/ui_style.gd")

signal activated(id: String, gesture: String)
signal transfer_dropped(data: Dictionary, target: Dictionary)

var item_id := "stone"
var compact := false
var amount := 0
var source: Dictionary = {}
var target: Dictionary = {}
var world_token := 0
var transfer_amount := 5
var can_transfer: Callable
var glyph: Control
var count_label: Label
var name_label: Label
var selected_style: Variant = null

func _ready() -> void:
	custom_minimum_size = Vector2(78, 74 if compact else 82)
	focus_mode = Control.FOCUS_ALL
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 6
	box.offset_top = 5
	box.offset_right = -6
	box.offset_bottom = -4
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(row)
	glyph = Icon.new()
	glyph.item_id = item_id
	row.add_child(glyph)
	count_label = Style.label("", 16)
	count_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	count_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(count_label)
	var short_names := {"science": "Dossier", "underground_belt": "Underpass", "generator": "Dynamo", "power_pole": "Power pole"}
	name_label = Style.label(short_names.get(item_id, Catalog.item_name(item_id)) if compact else Catalog.item_name(item_id), 12)
	name_label.max_lines_visible = 2
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(name_label)
	pressed.connect(func(): activated.emit(item_id, "all" if Input.is_key_pressed(KEY_SHIFT) or Input.is_key_pressed(KEY_CTRL) else "select"))
	update_count(0)

func update_count(value: int, selected: bool = false) -> void:
	amount = value
	count_label.text = "%.1fk" % (value / 1000.0) if value >= 1000 else str(value)
	glyph.modulate.a = 1.0 if value > 0 else 0.4
	if selected_style != selected:
		selected_style = selected
		add_theme_stylebox_override("normal", Style.panel(Color("2d4848") if selected else Color("24373d"), Style.GOLD if selected else Color("3a5057")))
	tooltip_text = "%s\n%d in this inventory\n%s\n\nClick to select / load / take. Right-click: 1. Shift-click: all.\nDrag transfers the selected quantity." % [Catalog.item_name(item_id), amount, Catalog.item_description(item_id)]

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			activated.emit(item_id, "one")
			accept_event()
		elif event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
			activated.emit(item_id, "equip")
			accept_event()

func _get_drag_data(_at: Vector2):
	if amount <= 0 or source.is_empty(): return null
	var preview := Label.new()
	preview.text = "%s  x%s" % [Catalog.item_name(item_id), str(amount if transfer_amount == 0 else mini(amount, transfer_amount))]
	preview.add_theme_font_size_override("font_size", 18)
	preview.add_theme_color_override("font_color", Style.ACCENT)
	set_drag_preview(preview)
	return {"type": "inventory_item", "item": item_id, "source": source.duplicate(), "amount": transfer_amount, "world": world_token}

func _can_drop_data(_at: Vector2, data) -> bool:
	return data is Dictionary and not target.is_empty() and can_transfer.is_valid() and can_transfer.call(data, target)

func _drop_data(_at: Vector2, data) -> void:
	transfer_dropped.emit(data, target)
