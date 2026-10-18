extends Control
## Positions come from prerequisite depth, not hard-coded technology IDs.
const Catalog = preload("res://scripts/data/catalog.gd")
const Style = preload("res://scripts/ui/ui_style.gd")
signal selected(id: String)
var buttons: Dictionary = {}
var labels: Dictionary = {}
var bars: Dictionary = {}
var levels: Dictionary = {}
var states: Dictionary = {}
var selected_id := ""
const CARD := Vector2(170,128)
const GAP := Vector2(20,30)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	for definition in Catalog.TECHNOLOGIES:
		var button := Button.new()
		button.custom_minimum_size = CARD
		button.size = CARD
		button.pressed.connect(func(): selected.emit(definition.id))
		add_child(button)
		var box := VBoxContainer.new()
		button.add_child(box)
		box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		box.offset_left = 12; box.offset_right = -12
		box.offset_top = 10; box.offset_bottom = -10
		var title := Style.label(definition.name,16,Style.TEXT)
		box.add_child(title)
		var state := Style.label("",11,Style.GOLD)
		box.add_child(state)
		var progress := ProgressBar.new()
		progress.custom_minimum_size.y = 5
		progress.show_percentage = false
		box.add_child(progress)
		var cost := Style.label("",12,Style.MUTED)
		box.add_child(cost)
		_ignore_pointer(box)
		buttons[definition.id] = button
		labels[definition.id] = {"state":state,"cost":cost}
		bars[definition.id] = progress
	_arrange()

func _ignore_pointer(node: Node) -> void:
	if node is Control: node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children(): _ignore_pointer(child)

func _arrange() -> void:
	for definition in Catalog.TECHNOLOGIES: levels[definition.id] = 0
	# Bounded relaxation supports definitions listed in any order.
	for iteration in Catalog.TECHNOLOGIES.size():
		for definition in Catalog.TECHNOLOGIES:
			for required in definition.requires: levels[definition.id] = maxi(int(levels[definition.id]), int(levels.get(required,0))+1)
	var counts: Dictionary = {}
	var max_depth := 0
	var max_rows := 1
	for id in levels:
		var depth: int = levels[id]
		counts[depth] = int(counts.get(depth,0))+1
		max_depth = maxi(max_depth,depth)
		max_rows = maxi(max_rows,int(counts[depth]))
	var used: Dictionary = {}
	var height := 16 + max_rows * (CARD.y + GAP.y)
	for definition in Catalog.TECHNOLOGIES:
		var depth: int = levels[definition.id]
		var row: int = int(used.get(depth,0))
		used[depth] = row+1
		var offset := (height - int(counts[depth]) * (CARD.y+GAP.y))/2.0
		buttons[definition.id].position = Vector2(8+depth*(CARD.x+GAP.x),offset+row*(CARD.y+GAP.y))
	custom_minimum_size = Vector2(16+(max_depth+1)*CARD.x+max_depth*GAP.x,height)
	queue_redraw()

func refresh(reports: Dictionary, selection: String) -> void:
	states = reports
	selected_id = selection
	for definition in Catalog.TECHNOLOGIES:
		var report: Dictionary = reports[definition.id]
		var status: Label = labels[definition.id].state
		status.text = {"complete":"COMPLETE","active":"IN PROGRESS","available":"AVAILABLE","locked":"LOCKED"}[report.state]
		status.add_theme_color_override("font_color",Style.ACCENT if report.state == "complete" else (Style.GOLD if report.state in ["active","available"] else Style.MUTED))
		labels[definition.id].cost.text = "%d / %d dossiers" % [report.progress,report.cost]
		bars[definition.id].value = 100.0 * report.progress / report.cost
		Style.select(buttons[definition.id],definition.id == selection)
		buttons[definition.id].tooltip_text = definition.name + "\n" + (report.reason if not report.reason.is_empty() else definition.unlock)
	queue_redraw()

func _draw() -> void:
	for definition in Catalog.TECHNOLOGIES:
		var target: Button = buttons.get(definition.id)
		if target == null: continue
		for required in definition.requires:
			if not buttons.has(required): continue
			var source: Button = buttons[required]
			var start := source.position + Vector2(CARD.x,CARD.y/2)
			var end := target.position + Vector2(0,CARD.y/2)
			var middle := (start.x+end.x)/2
			var color := Style.ACCENT if states.get(required,{}).get("state","") == "complete" else Style.BORDER.lightened(0.15)
			if definition.id == selected_id: color = Style.GOLD
			draw_polyline(PackedVector2Array([start,Vector2(middle,start.y),Vector2(middle,end.y),end]),color,2,true)
			draw_colored_polygon(PackedVector2Array([end,end+Vector2(-6,-4),end+Vector2(-6,4)]),color)
