extends Control
## Vector icons remain sharp at fullscreen scales and require no imported textures.

const Catalog = preload("res://scripts/data/catalog.gd")
const Entity = preload("res://scripts/model/entity.gd")
const MachineArt = preload("res://scripts/view/machine_art.gd")
var item_id := "stone"
var preview: RefCounted

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(30, 30)

func _draw() -> void:
	var center := size / 2
	var radius := minf(size.x, size.y) * 0.36
	var color := Catalog.color(item_id)
	if Catalog.BUILDINGS.has(item_id):
		if preview == null or preview.kind != item_id: preview = Entity.new(0, item_id)
		var scale_factor := 0.47 if item_id == "furnace" else 0.65
		draw_set_transform(Vector2(center.x, size.y * (0.65 if item_id == "furnace" else 0.5)), 0, Vector2.ONE * minf(size.x, size.y) / 30.0 * scale_factor)
		MachineArt.draw(self, preview, Vector2.ZERO, 0.0, Vector2.RIGHT, false)
		draw_set_transform(Vector2.ZERO)
		return
	if item_id in ["timber", "plank"]:
		for row in range(3):
			draw_line(center + Vector2(-radius, -7 + row * 7), center + Vector2(radius, -10 + row * 7), color, 5)
		return
	if item_id == "stone_axe":
		draw_line(center + Vector2(-7, 11), center + Vector2(5, -10), Color("ac8759"), 4)
		draw_colored_polygon(PackedVector2Array([center + Vector2(1, -10), center + Vector2(12, -11), center + Vector2(10, 0), center + Vector2(0, -2)]), color)
		return
	if item_id.ends_with("ore") or item_id in ["stone", "coal"]:
		draw_colored_polygon(PackedVector2Array([center + Vector2(-radius, radius * 0.5), center + Vector2(-radius * 0.6, -radius * 0.7), center + Vector2(radius * 0.45, -radius), center + Vector2(radius, radius * 0.35), center + Vector2(0, radius)]), color)
		draw_line(center + Vector2(-radius * 0.4, -radius * 0.45), center + Vector2(radius * 0.35, -radius * 0.55), color.lightened(0.4), 2)
	elif item_id.ends_with("plate") or item_id == "steel":
		for i in range(2): draw_rect(Rect2(center + Vector2(-radius, -radius * 0.4 + i * 7), Vector2(radius * 2, radius * 0.7)), color.darkened(i * 0.15))
	elif item_id in ["gear", "assembler", "drill"]:
		for i in range(8):
			var arm := Vector2.from_angle(i * TAU / 8)
			draw_line(center + arm * radius * 0.6, center + arm * radius, color, 5)
		draw_circle(center, radius * 0.7, color)
		draw_circle(center, radius * 0.3, Color("1c2c30"))
	elif item_id == "service_rifle":
		draw_line(center + Vector2(-12, 4), center + Vector2(14, -4), color, 6, true)
		draw_line(center + Vector2(-4, 2), center + Vector2(-2, 9), color.darkened(0.3), 4, true)
	elif item_id == "ammo":
		for x in [-7, 0, 7]:
			draw_rect(Rect2(center + Vector2(x - 2, -7), Vector2(4, 15)), color)
			draw_circle(center + Vector2(x, -7), 2, color.lightened(0.25))
	elif item_id == "repair_kit":
		draw_rect(Rect2(center + Vector2(-11, -8), Vector2(22, 18)), color.darkened(0.3))
		draw_line(center + Vector2(-6, 0), center + Vector2(6, 0), color, 4)
		draw_line(center + Vector2(0, -6), center + Vector2(0, 6), color, 4)
	elif item_id == "wall":
		for y in [-7, 1]:
			for x in [-10, 1]: draw_rect(Rect2(center + Vector2(x, y), Vector2(9, 6)), color)
	elif item_id == "turret":
		draw_circle(center, 10, color.darkened(0.4))
		draw_rect(Rect2(center - Vector2(5, 6), Vector2(10, 12)), color)
		draw_line(center, center + Vector2(13, 0), color.lightened(0.3), 5)
	elif item_id == "wire":
		for i in range(3): draw_arc(center + Vector2(i * 4 - 4, 0), radius * 0.7, 0, TAU, 20, color, 2)
	elif item_id in ["science", "lab"]:
		draw_rect(Rect2(center + Vector2(-11, -9), Vector2(22, 19)), Color("b28b5d"))
		draw_rect(Rect2(center + Vector2(-8, -11), Vector2(16, 18)), Color("dfd4ad"))
		for y in [-6, -1, 4]: draw_line(center + Vector2(-5, y), center + Vector2(5, y), Color("668e92"), 2)
	elif item_id in ["belt", "fast_belt"]:
		draw_rect(Rect2(center - Vector2.ONE * radius, Vector2.ONE * radius * 2), color.darkened(0.65))
		for y in [-6, 3]:
			draw_line(center + Vector2(-7, y + 4), center + Vector2(0, y - 2), color, 3)
			draw_line(center + Vector2(0, y - 2), center + Vector2(7, y + 4), color, 3)
	elif item_id == "inserter":
		draw_circle(center + Vector2(-5, 5), 6, color)
		draw_line(center + Vector2(-5, 5), center + Vector2(2, -8), color, 4)
		draw_line(center + Vector2(2, -8), center + Vector2(10, -3), color, 4)
	else:
		draw_rect(Rect2(center - Vector2.ONE * radius, Vector2.ONE * radius * 2), color)
		if item_id == "chest":
			draw_line(center + Vector2(-radius, -2), center + Vector2(radius, -2), color.darkened(0.5), 3)
			draw_rect(Rect2(center + Vector2(-2, -2), Vector2(4, 6)), Color("e9d89c"))
		else:
			draw_rect(Rect2(center + Vector2(-7, -4), Vector2(14, 12)), color.darkened(0.7))
			draw_circle(center + Vector2(0, 3), 4, Color("f2bb78"))
