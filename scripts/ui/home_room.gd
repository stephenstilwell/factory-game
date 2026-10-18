extends Control
## Standalone room view. Occupancy and ownership are enforced by PlayerHome.
const Art = preload("res://scripts/view/art.gd")
const Definitions = preload("res://scripts/data/home_catalog.gd")
signal room_clicked(cell: Vector2i, pickup: bool)
signal hover_changed(cell: Vector2i)
var world: RefCounted
var selected := ""
var direction := 0
var hover := Vector2i(-1, -1)
func _ready() -> void:
	custom_minimum_size = Vector2(540, 390)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	mouse_exited.connect(func(): hover = Vector2i(-1, -1); queue_redraw())
func scale_value() -> float: return minf((size.x - 28) / 10.0, (size.y - 74) / 8.0)
func origin() -> Vector2: return (size - Vector2(10, 8) * scale_value()) / 2 + Vector2(0, 18)
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		hover = Vector2i(((event.position - origin()) / scale_value()).floor())
		hover_changed.emit(hover)
		queue_redraw()
	if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		var cell := Vector2i(((event.position - origin()) / scale_value()).floor())
		room_clicked.emit(cell, event.button_index == MOUSE_BUTTON_RIGHT)
		accept_event()
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("111f25"))
	if world == null: return
	var scale := scale_value()
	var start := origin()
	var home: RefCounted = world.home
	var floor_color := Color(Definitions.STYLES[home.floor_style].floor)
	var wall_color := Color(Definitions.STYLES[home.wall_style].wall)
	draw_rect(Rect2(start - Vector2(8, 45), Vector2(scale * 10 + 16, scale * 8 + 53)), Art.INK)
	draw_rect(Rect2(start - Vector2(3, 39), Vector2(scale * 10 + 6, 39)), wall_color)
	for x in range(10):
		for y in range(8):
			var position := start + Vector2(x, y) * scale
			var color := floor_color.lightened(0.025 if (x + y) % 2 == 0 else -0.025)
			draw_rect(Rect2(position, Vector2.ONE * scale), color)
			draw_rect(Rect2(position, Vector2.ONE * scale), floor_color.darkened(0.14), false, 1)
			if home.floor_style != 2: draw_line(position + Vector2(0, scale * 0.5), position + Vector2(scale, scale * 0.5), floor_color.darkened(0.08), 1)
	for x in [2.0, 7.0]:
		Art.box(self, Rect2(start + Vector2(x * scale, -34), Vector2(scale, 26)), Art.COPPER, 2)
		draw_rect(Rect2(start + Vector2(x * scale + 4, -30), Vector2(scale - 8, 18)), Color("8dafad"))
		draw_line(start + Vector2((x + 0.5) * scale, -30), start + Vector2((x + 0.5) * scale, -12), Art.CREAM, 2)
	draw_rect(Rect2(start + Vector2(4, 7) * scale, Vector2(2, 1) * scale), floor_color.darkened(0.2))
	draw_string(ThemeDB.fallback_font, start + Vector2(4.2, 7.6) * scale, "DOOR", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Art.CREAM)
	var records: Array = home.pieces.duplicate()
	records.sort_custom(func(a, b):
		var layer_a: int = int(Definitions.PIECES[a.kind].get("layer", 1))
		var layer_b: int = int(Definitions.PIECES[b.kind].get("layer", 1))
		return layer_a < layer_b if layer_a != layer_b else (a.y < b.y if a.y != b.y else a.x < b.x))
	for record in records: _piece(record.kind, Vector2i(record.x, record.y), int(record.direction), start, scale)
	if not selected.is_empty() and Rect2i(Vector2i.ZERO, Definitions.SIZE).has_point(hover):
		var footprint := Definitions.footprint(selected, direction)
		var rect := Rect2(start + Vector2(hover) * scale, Vector2(footprint) * scale)
		var valid: bool = home.placement_reason(selected, hover, direction).is_empty()
		draw_rect(rect, Color(0.55, 0.9, 0.75, 0.3) if valid else Color(0.95, 0.4, 0.35, 0.35))
		draw_rect(rect.grow(-2), Color("bce3c7") if valid else Color("ee8e7b"), false, 2)
func _piece(kind: String, cell: Vector2i, facing: int, start: Vector2, scale: float) -> void:
	var footprint := Definitions.footprint(kind, facing)
	var world_center := start + Vector2(cell) * scale + Vector2(footprint) * scale * 0.5
	draw_set_transform(world_center, facing * PI / 2)
	var base_size: Vector2 = Vector2(Definitions.PIECES[kind].size) * scale
	var rect := Rect2(-base_size * 0.5 + Vector2.ONE * 5, base_size - Vector2.ONE * 10)
	var center := Vector2.ZERO
	var color := Color(Definitions.PIECES[kind].color)
	if kind == "rug":
		draw_rect(rect, color)
		draw_rect(rect.grow(-5), Color("dcc796"), false, 2)
		for x in range(3): draw_line(center + Vector2(-12 + x * 12, -15), center + Vector2(-12 + x * 12, 15), color.lightened(0.25), 3)
		draw_set_transform(Vector2.ZERO)
		return
	Art.shadow(self, center + Vector2(2, rect.size.y * 0.3), rect.size * Vector2(0.53, 0.28))
	Art.box(self, rect, color, 4)
	match kind:
		"bed":
			draw_rect(Rect2(rect.position + Vector2.ONE * 4, Vector2(rect.size.x - 8, rect.size.y * 0.3)), Color("e4d8bd"))
			for x in range(3): draw_line(center + Vector2(-rect.size.x * 0.3 + x * rect.size.x * 0.3, 0), center + Vector2(-rect.size.x * 0.3 + x * rect.size.x * 0.3, rect.size.y * 0.4), color.lightened(0.15), 2)
		"chair", "bench", "screen":
			var axis := Vector2.RIGHT
			draw_line(center - axis.orthogonal() * rect.size.length() * 0.25, center + axis.orthogonal() * rect.size.length() * 0.25, color.darkened(0.4), 5)
		"shelf":
			for i in range(6): draw_rect(Rect2(rect.position + Vector2(5 + i * (rect.size.x - 10) / 6, 5), Vector2((rect.size.x - 16) / 6, rect.size.y - 10)), [Color("71968e"), Color("b87860"), Color("d8bd80")][i % 3])
		"planter":
			for i in range(5): draw_circle(center + Vector2.from_angle(i * TAU / 5) * scale * 0.15, scale * 0.16, Color("6f9d67").lightened(i * 0.035))
		"lamp":
			draw_circle(center, scale * 0.52, Color(1, 0.82, 0.4, 0.09))
			draw_circle(center, scale * 0.28, Color("f6d68c"))
			draw_circle(center, scale * 0.12, Color("fff3ca"))
		"hearth":
			draw_rect(rect.grow(-6), Art.INK)
			draw_colored_polygon(PackedVector2Array([center + Vector2(-10, 8), center + Vector2(0, -12), center + Vector2(10, 8)]), Color("e7a45d"))
		"crate":
			draw_line(rect.position + Vector2.ONE * 4, rect.end - Vector2.ONE * 4, color.darkened(0.4), 3)
			draw_line(rect.position + Vector2(4, rect.size.y - 4), rect.position + Vector2(rect.size.x - 4, 4), color.darkened(0.4), 3)
		"plinth":
			draw_circle(center, scale * 0.2, Color("81b6b0"))
		"table":
			draw_line(rect.position + Vector2(5, 6), rect.position + Vector2(rect.size.x - 5, 6), color.lightened(0.25), 2)
	draw_set_transform(Vector2.ZERO)
