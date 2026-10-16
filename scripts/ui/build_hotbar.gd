extends VBoxContainer
const Catalog = preload("res://scripts/data/catalog.gd")
const Style = preload("res://scripts/ui/ui_style.gd")
const Layout = preload("res://scripts/ui/hotbar_layout.gd")
const Slot = preload("res://scripts/ui/hotbar_slot.gd")
const Tile = preload("res://scripts/ui/item_tile.gd")
signal build_selected(id: String)
signal journal_requested
signal notice(text: String)
var layout := Layout.new()
var world: RefCounted
var selection := ""
var slots: Array = []
var caption: Label
var page_button: Button
var picker: ColorRect
var search: LineEdit
var choices: Dictionary = {}
var target_buttons: Array = []
var empty_label: Label
var picker_title: Label
var editing_slot := 0
var hovered_slot := -1

func _ready() -> void:
	add_theme_constant_override("separation", 4)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	add_child(row)
	var previous := Style.button(row, "‹", func(): change_page(-1))
	previous.tooltip_text = "Previous hotbar page [Shift+Tab]"
	page_button = Style.button(row, "1 / 2", func(): change_page(1))
	page_button.custom_minimum_size.x = 56
	page_button.tooltip_text = "Next hotbar page [Tab]"
	for i in Layout.SLOTS:
		var slot := Slot.new()
		slot.owner_bar = self
		slot.index = i
		row.add_child(slot)
		slots.append(slot)
	var library := Style.button(row, "Buildings", func(): open_picker(0))
	library.custom_minimum_size = Vector2(104, 62)
	library.tooltip_text = "Choose a slot and assign a building. Right-click any slot to edit it."
	var journal := Style.button(row, "Journal [J]", func(): journal_requested.emit())
	journal.custom_minimum_size = Vector2(96, 62)
	caption = Style.label("", 13, Style.MUTED)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.max_lines_visible = 1
	add_child(caption)
	describe(hovered_slot)

func attach_picker(parent: Node) -> void:
	picker = ColorRect.new()
	picker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	picker.color = Color(0.02, 0.04, 0.045, 0.82)
	picker.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(picker)
	picker.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT: close_picker())
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	picker.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(620, 430)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var header := HBoxContainer.new()
	box.add_child(header)
	picker_title = Style.label("", 22, Style.ACCENT)
	picker_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(picker_title)
	Style.button(header, "Close [Esc]", close_picker)
	box.add_child(Style.label("Shortcuts use your pack inventory. Assigning a slot never spends or moves items.", 14, Style.MUTED))
	var target_row := HBoxContainer.new()
	box.add_child(target_row)
	for i in Layout.SLOTS:
		var target := Style.button(target_row, str((i + 1) % 10), func(): open_picker(i))
		target.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		target_buttons.append(target)
	search = LineEdit.new()
	search.placeholder_text = "Search buildings..."
	search.clear_button_enabled = true
	box.add_child(search)
	search.text_changed.connect(func(_text): refresh_choices())
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 190
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 6
	scroll.add_child(grid)
	for id in Catalog.BUILDINGS:
		var tile := Tile.new()
		tile.item_id = id
		grid.add_child(tile)
		tile.activated.connect(func(item, gesture):
			if gesture != "one" and assign(editing_slot, item): close_picker())
		choices[id] = tile
	empty_label = Style.label("", 14, Style.MUTED)
	box.add_child(empty_label)
	Style.button(box, "Clear this slot", func(): assign(editing_slot, ""); close_picker())
	picker.hide()

func refresh(state: RefCounted, selected: String) -> void:
	world = state
	selection = selected
	page_button.text = "%d / %d" % [layout.active_page + 1, Layout.PAGES]
	for i in Layout.SLOTS:
		var id: String = layout.item(layout.active_page, i)
		var is_available := available(id)
		slots[i].refresh(id, world.player.count(id), is_available, not id.is_empty() and id == selection)
		var title := Catalog.item_name(id) if is_available else ("Empty slot" if id.is_empty() else "Undiscovered building")
		slots[i].tooltip_text = "%s [%d]\n%s\n\nClick / number: select • Right-click: assign\nMiddle-click: clear • Drag slots: swap\nDrag a building from your pack to assign." % [title, (i + 1) % 10, ("%d in pack" % world.player.count(id)) if is_available else "Assign a building as you discover it."]
	describe(hovered_slot)
	if picker != null and picker.visible: refresh_choices()

func available(id: String) -> bool:
	return world != null and Catalog.BUILDINGS.has(id) and world.content_available(id) and world.unlocked(Catalog.BUILDINGS[id])

func activate(index: int) -> void:
	var id: String = layout.item(layout.active_page, index)
	if id.is_empty(): open_picker(index)
	elif available(id): build_selected.emit(id)
	else: notice.emit("This building is not available yet. Follow your learning objectives and research.")

func assign(index: int, id: String) -> bool:
	if not id.is_empty() and not available(id): return false
	if not layout.assign(layout.active_page, index, id): return false
	_save()
	refresh(world, selection)
	return true

func change_page(direction: int) -> void:
	layout.active_page = posmod(layout.active_page + direction, Layout.PAGES)
	_save()
	if world != null: refresh(world, selection)

func _save() -> void:
	if layout.save() != OK: notice.emit("Could not save hotbar preferences.")

func describe(index: int) -> void:
	hovered_slot = index
	if caption == null: return
	var id := layout.item(layout.active_page, index) if index >= 0 else selection
	if not id.is_empty() and available(id):
		caption.text = "%s  •  %d in pack  •  %s" % [Catalog.item_name(id), world.player.count(id), "Left-click to place • R rotate • Q clear" if world.player.count(id) > 0 else "Craft more with C"]
	else:
		caption.text = "1–0 select  •  Right-click slot to assign  •  Drag to rearrange  •  Tab switches page"

func open_picker(index: int) -> void:
	if picker == null or world == null: return
	editing_slot = clampi(index, 0, Layout.SLOTS - 1)
	picker_title.text = "Assign slot %d  /  page %d" % [(editing_slot + 1) % 10, layout.active_page + 1]
	for i in target_buttons.size(): target_buttons[i].modulate = Style.GOLD if i == editing_slot else Color.WHITE
	search.text = ""
	refresh_choices()
	picker.show()
	search.grab_focus()

func close_picker() -> void:
	picker.hide()
	search.release_focus()

func refresh_choices() -> void:
	if world == null: return
	var found := 0
	for id in choices:
		var tile = choices[id]
		tile.visible = world.content_available(id) and (search.text.is_empty() or Catalog.item_name(id).to_lower().contains(search.text.to_lower()))
		tile.disabled = not available(id)
		tile.update_count(world.player.count(id))
		tile.tooltip_text = Catalog.item_name(id) + ("\nClick to assign this shortcut." if available(id) else "\nResearch the required technology first.")
		if tile.visible: found += 1
	empty_label.text = "No matching buildings discovered yet." if found == 0 else "More buildings appear as you learn. Pick a number above to edit another slot."

func can_drop(data: Variant) -> bool:
	if not data is Dictionary or world == null: return false
	if data.get("type") == "hotbar_shortcut":
		return data.get("owner") == get_instance_id() and data.get("revision") == layout.revision and data.get("page") is int and data.get("slot") is int and data.page >= 0 and data.page < Layout.PAGES and data.slot >= 0 and data.slot < Layout.SLOTS
	return data.get("type") == "inventory_item" and data.get("world") == world.get_instance_id() and data.get("item") is String and data.get("source") is Dictionary and data.source.get("kind") == "player" and available(data.item) and world.player.count(data.item) > 0

func drop_on(index: int, data: Variant) -> void:
	if not can_drop(data): return
	if data.type == "hotbar_shortcut":
		if layout.swap(data.page, data.slot, layout.active_page, index, data.revision):
			_save()
			refresh(world, selection)
	else: assign(index, data.item)