extends Control
const Art = preload("res://scripts/view/npc_art.gd")
var npc_id := "trading_post"
func _ready() -> void:
	custom_minimum_size = Vector2(106, 112)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
	draw_circle(size * Vector2(0.5, 0.45), 48, Color("2f4845"))
	Art.person(self, size * Vector2(0.5, 0.63), npc_id, 0.0, 2.6)