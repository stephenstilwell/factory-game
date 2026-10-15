extends RefCounted
const Art = preload("res://scripts/view/art.gd")
const TILE := 48

static func draw_route(canvas: Node2D, world: RefCounted, visible: Rect2i, selected_site: String) -> void:
	if not world.settlements.enabled: return
	var hall = world.settlements.sites.town_hall
	if not hall.repaired and selected_site != "town_hall": return
	var start: Vector2i = world.defense.spawn_cell(world)
	var end: Vector2i = hall.origin + Vector2i(3, 1)
	for x in range(end.x, start.x + 1):
		var cell := Vector2i(x, start.y)
		if not visible.has_point(cell): continue
		var center := (Vector2(cell) + Vector2.ONE * 0.5) * TILE
		canvas.draw_rect(Rect2(center - Vector2(24, 13), Vector2(48, 26)), Color(0.60, 0.48, 0.32, 0.28))
		for y in [-9, 9]: canvas.draw_line(center + Vector2(-24, y), center + Vector2(24, y), Color(0.80, 0.68, 0.45, 0.18), 2)
		if x % 3 == 0:
			canvas.draw_polyline(PackedVector2Array([center + Vector2(6, -4), center + Vector2(-2, 0), center + Vector2(6, 4)]), Color("c8ad7c"), 2, true)
	var entry := (Vector2(start) + Vector2.ONE * 0.5) * TILE
	canvas.draw_arc(entry, 24, 0, TAU, 32, Color("d9966e"), 2, true)
	canvas.draw_string(ThemeDB.fallback_font, entry + Vector2(-50, -35), "EAST APPROACH", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("f0cb91"))

static func draw_enemy(canvas: Node2D, enemy: Dictionary, maximum: int, time: float) -> void:
	var center := (Vector2(enemy.cell) + Vector2.ONE * 0.5) * TILE
	Art.shadow(canvas, center + Vector2(0, 6), Vector2(17, 9))
	var stride := sin(time * 12 + enemy.id) * 3
	for side in [-1, 1]:
		for y in [-8, 8]:
			var elbow := center + Vector2(12 * side, y + stride * side)
			canvas.draw_polyline(PackedVector2Array([center + Vector2(4 * side, y / 2.0), elbow, elbow + Vector2(-5, 5)]), Art.INK, 5, true)
			canvas.draw_line(center + Vector2(4 * side, y / 2.0), elbow, Color("b68e6a"), 3, true)
	Art.box(canvas, Rect2(center + Vector2(-14, -11), Vector2(27, 21)), Color("6b4a3e"), 8, Art.INK)
	Art.box(canvas, Rect2(center + Vector2(-11, -14), Vector2(23, 18)), Color("ab7150"), 7, Art.INK)
	canvas.draw_line(center + Vector2(-4, -12), center + Vector2(-4, 1), Color("d0a074"), 2)
	for y in [-4, 3]: canvas.draw_line(center + Vector2(-16, y), center + Vector2(-10, y), Color("d7ae7e"), 3, true)
	Art.glow(canvas, center + Vector2(-10, -3), 6, Color("d9835c"), 0.6)
	canvas.draw_circle(center + Vector2(-10, -3), 3, Color("f0c28a"))
	Art.box(canvas, Rect2(center + Vector2(-15, -25), Vector2(30, 4)), Art.INK, 2)
	Art.box(canvas, Rect2(center + Vector2(-15, -25), Vector2(30.0 * enemy.health / maximum, 4)), Color("ce8b6a"), 2)

static func draw_shots(canvas: Node2D, world: RefCounted) -> void:
	for shot in world.defense.shots:
		var start := (Vector2(shot.from) + Vector2.ONE * 0.5) * TILE
		var end := (Vector2(shot.to) + Vector2.ONE * 0.5) * TILE
		var direction := (end - start).normalized()
		canvas.draw_line(start + direction * 22 - Vector2(0, 4), end, Color(0.98, 0.80, 0.49, 0.65), 1.5, true)
		Art.glow(canvas, end, 10, Art.AMBER)
		for i in range(4):
			var axis := Vector2.from_angle(i * TAU / 4 + 0.4)
			canvas.draw_line(end + axis * 3, end + axis * 8, Art.CREAM, 1.5, true)