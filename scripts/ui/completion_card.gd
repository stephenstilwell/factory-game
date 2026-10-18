extends PanelContainer
## One bounded, input-transparent completion card. Driven by successful model events.
const Style = preload("res://scripts/ui/ui_style.gd")
const Showcase = preload("res://scripts/ui/showcase.gd")
var accent: Control
var art: Control
var heading: Label
var detail: Label
var remaining := 0.0
var reduced_motion := false
var total := 0
var key := ""

func _ready() -> void:
	var frame := Style.panel(Style.BACKGROUND, Style.GOLD.darkened(0.25))
	frame.border_width_left = 3
	add_theme_stylebox_override("panel", frame)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",12)
	add_child(row)
	art = Showcase.new()
	row.add_child(art)
	art.custom_minimum_size = Vector2(52,52)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	heading = Style.label("",15,Style.GOLD)
	text.add_child(heading)
	detail = Style.label("",13,Style.TEXT)
	detail.max_lines_visible = 2
	text.add_child(detail)
	accent = preload("res://scripts/ui/milestone_accent.gd").new()
	add_child(accent)
	_ignore_pointer(self)
	hide()
	set_process(false)

func _ignore_pointer(node: Node) -> void:
	if node is Control: node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children(): _ignore_pointer(child)

func set_reduced_motion(enabled: bool) -> void:
	reduced_motion = enabled
	if enabled: modulate.a = 1.0
	if accent != null: accent.set_reduced_motion(enabled)

func reveal(kind: String, id: String, title: String, text: String, amount: int = 0, milestone: bool = false) -> void:
	var next_key := kind + ":" + id
	total = total + amount if remaining > 0 and next_key == key else amount
	key = next_key
	heading.text = title
	detail.text = text + ("  •  +%d to pack" % total if total > 0 else "")
	detail.tooltip_text = detail.text
	art.present(kind, id)
	remaining = 5.0 if milestone or kind in ["site","equipment"] else 3.5
	accent.finish()
	if milestone or kind in ["site","equipment"]: accent.celebrate()
	modulate.a = 1.0
	show()
	set_process(true)

func clear() -> void:
	if accent != null: accent.finish()
	remaining = 0
	key = ""
	total = 0
	hide()
	set_process(false)

func _process(delta: float) -> void:
	remaining = maxf(0.0, remaining - delta)
	modulate.a = 1.0 if reduced_motion else minf(1.0, remaining / 0.3)
	if remaining == 0: clear()
