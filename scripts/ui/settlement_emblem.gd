extends Control
## A small civic bridge mark, drawn as vectors at the current UI scale.
func _ready() -> void:
	custom_minimum_size = Vector2(34, 34)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var scale_value := minf(size.x, size.y) / 34.0
	draw_set_transform((size - Vector2.ONE * 34.0 * scale_value) / 2.0, 0.0, Vector2.ONE * scale_value)
	draw_rect(Rect2(0, 0, 34, 34), Color("292d30"))
	draw_line(Vector2(7, 24), Vector2(27, 24), Color("e5ae78"), 2, true)
	draw_line(Vector2(9, 24), Vector2(9, 16), Color("e5ae78"), 2, true)
	draw_line(Vector2(25, 24), Vector2(25, 16), Color("e5ae78"), 2, true)
	draw_arc(Vector2(17, 22), 8, PI, TAU, 24, Color("e5ae78"), 2, true)
	draw_line(Vector2(17, 12), Vector2(17, 5), Color("b3cdbd"), 1.5, true)
	draw_colored_polygon(PackedVector2Array([Vector2(17, 9), Vector2(21, 4), Vector2(22, 8)]), Color("b3cdbd"))
	draw_set_transform(Vector2.ZERO)
