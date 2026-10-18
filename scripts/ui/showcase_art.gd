extends Node2D
## UI-owned illustration data; never draw or modify a live settlement object.
const Site = preload("res://scripts/model/settlement_site.gd")
var domain := ""
var subject := ""
var preview: RefCounted

func present(kind: String, id: String, restored: bool) -> void:
	domain = kind
	subject = id
	if kind == "site":
		preview = Site.new(id)
		preview.repaired = restored
		preview.health = preview.max_health() if restored else 0
	queue_redraw()

func _draw() -> void:
	if domain == "site" and preview != null:
		preload("res://scripts/ui/civic_portrait.gd").paint(self,subject,preview.repaired)
		return
	var copper := Color("d5a16e")
	var dark := Color("4b5c61")
	var light := Color("b7cbc5")
	match subject:
		"boots":
			for x in [-24, 8]:
				draw_colored_polygon(PackedVector2Array([Vector2(x,-28),Vector2(x+18,-28),Vector2(x+18,10),Vector2(x+28,17),Vector2(x+28,28),Vector2(x-3,28),Vector2(x-3,9)]), copper)
				draw_line(Vector2(x-3,28), Vector2(x+28,28), dark, 6, true)
				for y in [-18,-8,2]: draw_line(Vector2(x+4,y),Vector2(x+14,y),light,2,true)
		"pack", "reach":
			draw_style_box(_box(dark), Rect2(-31,-32,62,67))
			draw_arc(Vector2(0,-27),16,PI,TAU,16,copper,5,true)
			draw_style_box(_box(copper), Rect2(-21,2,42,25))
			for x in [-18,18]: draw_line(Vector2(x,-25),Vector2(x,24),light,4,true)
		"armor":
			draw_colored_polygon(PackedVector2Array([Vector2(-18,-34),Vector2(-40,-16),Vector2(-27,0),Vector2(-19,-8),Vector2(-26,34),Vector2(26,34),Vector2(19,-8),Vector2(27,0),Vector2(40,-16),Vector2(18,-34),Vector2(0,-23)]),dark)
			draw_line(Vector2(0,-21),Vector2(0,31),copper,3,true)
			for y in [-8,4,16]: draw_circle(Vector2(6,y),2,light)
		"scanner":
			draw_circle(Vector2.ZERO,34,copper)
			draw_circle(Vector2.ZERO,28,dark)
			draw_arc(Vector2.ZERO,22,0,TAU,40,light,1,true)
			draw_colored_polygon(PackedVector2Array([Vector2(-7,9),Vector2(0,-23),Vector2(8,9),Vector2.ZERO]),light)
			draw_circle(Vector2.ZERO,4,copper)
		_:
			draw_line(Vector2(-25,29),Vector2(20,-22),copper,9,true)
			if subject == "repair":
				draw_arc(Vector2(22,-24),15,0,PI*1.55,20,light,9,true)
			else:
				draw_polyline(PackedVector2Array([Vector2(-25,-16),Vector2(-1,-30),Vector2(22,-25),Vector2(37,-8)]),light,8,true)

func _box(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(5)
	return box
