extends ColorRect
## Bounded current-session history. It records successful events, never arbitrary status spam.
const Style = preload("res://scripts/ui/ui_style.gd")
signal navigate(destination: String, id: String)
signal count_changed(unread: int)
const LIMIT := 50
var entries: Array[Dictionary] = []
var unread := 0
var next_id := 1
var rows: VBoxContainer
var empty: Label
var count: Label
var clear_button: Button
var buttons: Dictionary = {}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color = Color(0.02,0.03,0.04,0.88)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,32)
	add_child(margin)
	var panel := PanelContainer.new()
	margin.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",10)
	panel.add_child(box)
	var header := HBoxContainer.new()
	box.add_child(header)
	var title := Style.label("RECENT UPDATES",23,Style.TEXT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	Style.button(header,"Close [Esc]",hide)
	count = Style.label("",13,Style.MUTED)
	box.add_child(count)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_RESERVE
	box.add_child(scroll)
	rows = VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(rows)
	empty = Style.label("Your story starts here. Completed crafts, equipment upgrades, technology unlocks and restored buildings will appear here.",16,Style.MUTED)
	box.add_child(empty)
	clear_button = Style.button(box,"Clear history",clear)
	box.add_child(Style.label("Last 50 updates from this play session. Loading or starting a world begins a fresh history.",12,Style.MUTED))
	hide()
	_refresh()

func record(key: String, title: String, detail: String, destination: String, subject: String, amount: int = 0) -> void:
	var entry: Dictionary
	if amount > 0 and not entries.is_empty() and entries[0].key == key:
		entry = entries.pop_front()
		entry.amount += amount
		if not entry.unread and not visible: unread += 1
		entry.unread = not visible
	else:
		entry = {"uid":next_id,"key":key,"title":title,"detail":detail,"destination":destination,"subject":subject,"amount":amount,"unread":not visible}
		next_id += 1
		if not visible: unread += 1
	entries.push_front(entry)
	while entries.size() > LIMIT:
		if entries.pop_back().unread: unread -= 1
	_refresh()
	count_changed.emit(unread)

func open_history() -> void:
	for entry in entries: entry.unread = false
	unread = 0
	show()
	_refresh()
	count_changed.emit(unread)

func clear() -> void:
	entries.clear()
	unread = 0
	next_id = 1
	_refresh()
	count_changed.emit(unread)

func _refresh() -> void:
	if rows == null: return
	for child in rows.get_children():
		rows.remove_child(child)
		child.queue_free()
	buttons.clear()
	count.text = "%d recent updates • %d unread" % [entries.size(),unread]
	empty.visible = entries.is_empty()
	clear_button.disabled = entries.is_empty()
	for entry in entries:
		var card := PanelContainer.new()
		rows.add_child(card)
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation",12)
		card.add_child(line)
		var text := VBoxContainer.new()
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(text)
		text.add_child(Style.label(("NEW • " if entry.unread else "") + entry.title,16,Style.GOLD))
		text.add_child(Style.label(entry.detail + (" • +%d to pack" % entry.amount if entry.amount > 0 else ""),14,Style.TEXT))
		var button := Style.button(line,{"crafting":"View recipe","technology":"View technology","equipment":"View equipment","town":"View building","discoveries":"View discovery"}.get(entry.destination,"Open"),func(): hide(); navigate.emit(entry.destination,entry.subject))
		buttons[entry.uid] = button
