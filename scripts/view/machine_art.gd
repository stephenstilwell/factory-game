extends RefCounted
const Art = preload("res://scripts/view/art.gd")
const Catalog = preload("res://scripts/data/catalog.gd")
const DIRS := [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]

static func draw(canvas: CanvasItem, entity: RefCounted, center: Vector2, time: float, aim: Vector2, firing: bool, interpolation: float = 1.0) -> void:
	var kind: String = entity.kind
	var healthy: bool = entity.health > 0
	var working: bool = healthy and (entity.status == "Working" or entity.status.begins_with("Mining"))
	var direction: Vector2 = DIRS[entity.direction]
	if kind in Catalog.TRANSPORT:
		_belt(canvas, entity, center, time if healthy else 0.0)
		if kind == "splitter":
			Art.box(canvas, Rect2(center - Vector2(10, 10), Vector2(20, 20)), Art.COPPER, 3)
			for axis in [direction, direction.rotated(PI / 2)]:
				canvas.draw_line(center, center + axis * 22, Art.CREAM, 3, true)
		elif kind == "underground_belt":
			Art.box(canvas, Rect2(center - Vector2(18, 18), Vector2(36, 36)), Art.STEEL, 4, Art.INK)
			var mouth := center + direction * (13 if entity.underground_exit else -13)
			Art.box(canvas, Rect2(mouth - Vector2(8, 7), Vector2(16, 14)), Art.INK, 2)
			canvas.draw_line(center - direction * 6, center + direction * 8, Art.AMBER, 3, true)
			canvas.draw_string(ThemeDB.fallback_font, center + Vector2(-8, -21), "OUT" if entity.underground_exit else "IN", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Art.CREAM)
		return
	Art.shadow(canvas, center + Vector2(0, 9), Vector2(22, 13))
	if kind == "inserter":
		Art.box(canvas, Rect2(center - Vector2(12, 9), Vector2(24, 22)), Art.INK, 5)
		Art.ellipse(canvas, center, Vector2(10, 8), Art.COPPER)
		var extension := hand_extension(entity, interpolation)
		var hand := center + direction * extension
		var elbow := (center + hand) / 2 + direction.orthogonal() * 6
		canvas.draw_polyline(PackedVector2Array([center, elbow, hand]), Art.INK, 8, true)
		canvas.draw_polyline(PackedVector2Array([center - Vector2(1, 2), elbow - Vector2(1, 2), hand - Vector2(1, 2)]), Art.AMBER, 5, true)
		canvas.draw_circle(elbow, 3, Art.STEEL)
		canvas.draw_circle(center, 4, Art.CREAM)
		canvas.draw_line(hand - direction.orthogonal() * 5, hand + direction.orthogonal() * 5, Art.STEEL_LIGHT, 3, true)
		return
	if kind == "wall":
		if not healthy:
			for i in range(5):
				Art.box(canvas, Rect2(center + Vector2(-20 + i * 8, -3 + posmod(i * 7, 11)), Vector2(13, 8)), Art.STONE.darkened(0.15), 3)
			return
		for row in range(3):
			for column in range(2):
				var at := center + Vector2(-21 + column * 21, -21 + row * 12)
				Art.box(canvas, Rect2(at + Vector2(0, 3), Vector2(20, 13)), Color("6d6b59"), 2)
				Art.box(canvas, Rect2(at, Vector2(20, 10)), Art.STONE.lightened(row * 0.025), 2)
				canvas.draw_line(at + Vector2(3, 2), at + Vector2(16, 2), Art.CREAM.darkened(0.12), 1, true)
		return
	Art.box(canvas, Rect2(center + Vector2(-21, -10), Vector2(42, 33)), Art.INK, 6)
	Art.box(canvas, Rect2(center + Vector2(-20, -14), Vector2(40, 32)), Color("626e63"), 5)
	for x in [-16, 16]: Art.bolt(canvas, center + Vector2(x, 12))
	match kind:
		"furnace": _furnace(canvas, center, time, entity.id, working)
		"drill": _drill(canvas, center, time, direction, working)
		"turret", "cannon_turret", "pulse_turret":
			Art.ellipse(canvas, center + Vector2(0, 3), Vector2(18, 14), Art.INK)
			Art.ellipse(canvas, center - Vector2(0, 2), Vector2(17, 13), Art.STEEL)
			var barrel := aim.normalized()
			canvas.draw_line(center + barrel * 3, center + barrel * (23 if firing else 26), Art.INK, 9, true)
			canvas.draw_line(center - Vector2(0, 4), center - Vector2(0, 4) + barrel * (23 if firing else 26), Art.STEEL_LIGHT, 6, true)
			Art.box(canvas, Rect2(center + Vector2(-10, -13), Vector2(20, 18)), Art.STEEL, 6)
			Art.box(canvas, Rect2(center + Vector2(-6, -11), Vector2(12, 5)), Art.COPPER, 2)
			if kind == "cannon_turret":
				canvas.draw_line(center - Vector2(0, 4) + barrel * 12, center - Vector2(0, 4) + barrel * 31, Art.COPPER, 10, true)
			elif kind == "pulse_turret":
				canvas.draw_arc(center - Vector2(0, 6), 12, 0, TAU, 20, Color("86d6cb"), 4, true)
				canvas.draw_circle(center - Vector2(0, 6), 5, Art.CREAM)
			if firing:
				var muzzle := center - Vector2(0, 4) + barrel * 27
				Art.glow(canvas, muzzle, 13, Art.AMBER)
				canvas.draw_circle(muzzle, 4, Art.CREAM)
		"fuel_depot":
			Art.box(canvas, Rect2(center + Vector2(-20, -18), Vector2(40, 33)), Color("805b3b"), 4, Art.INK)
			Art.box(canvas, Rect2(center + Vector2(-15, -14), Vector2(30, 17)), Art.INK, 3)
			for i in range(5): canvas.draw_circle(center + Vector2(-10 + i * 5, -6 + i % 2 * 3), 5, Color("414a4b"))
			canvas.draw_line(center + Vector2(-19, 7), center + Vector2(19, 7), Art.COPPER, 4)
			canvas.draw_circle(center + Vector2(0, 7), 4, Art.AMBER if healthy else Art.INK)
			canvas.draw_line(center + Vector2(0, -18), center + Vector2(0, -31), Art.STEEL, 2)
			canvas.draw_colored_polygon(PackedVector2Array([center + Vector2(0, -31), center + Vector2(14, -28), center + Vector2(0, -23)]), Art.CREAM)
		"chest":
			Art.box(canvas, Rect2(center + Vector2(-18, -13), Vector2(36, 31)), Color("76583c"), 3)
			Art.box(canvas, Rect2(center + Vector2(-18, -21), Vector2(36, 19)), Color("a47d4c"), 4, Art.INK)
			for x in [-11, 11]: canvas.draw_line(center + Vector2(x, -19), center + Vector2(x, 15), Art.STEEL.darkened(0.25), 4, true)
			Art.box(canvas, Rect2(center + Vector2(-3, -4), Vector2(6, 9)), Art.AMBER, 1)
		"assembler":
			Art.box(canvas, Rect2(center + Vector2(-20, -22), Vector2(40, 32)), Art.STEEL, 5, Art.INK)
			Art.box(canvas, Rect2(center + Vector2(-15, -19), Vector2(29, 24)), Art.INK, 3)
			var angle := time * 1.8 if working else 0.0
			_gear(canvas, center + Vector2(-4, -7), 9, angle, Art.STEEL_LIGHT)
			_gear(canvas, center + Vector2(8, -1), 6, -angle, Art.COPPER)
			canvas.draw_line(center + Vector2(-17, 11), center + Vector2(17, 11), Art.COPPER, 3, true)
		"lab":
			var research_time := time if healthy and entity.status.begins_with("Researching") else 0.0
			Art.box(canvas, Rect2(center + Vector2(-21, -18), Vector2(42, 32)), Color("8f6b48"), 3, Art.INK)
			Art.box(canvas, Rect2(center + Vector2(-16, -15), Vector2(30, 24)), Color("dfd4ad"), 1)
			for i in range(3): canvas.draw_line(center + Vector2(-11, -10 + i * 6), center + Vector2(7, -10 + i * 6), Color("668e92"), 1, true)
			canvas.draw_rect(Rect2(center + Vector2(-7, -7), Vector2(10, 12)), Color("668e92"), false, 1)
			canvas.draw_line(center + Vector2(8, -7 + sin(research_time * 4) * 3), center + Vector2(15, -18 + sin(research_time * 4) * 3), Art.COPPER, 3, true)
			Art.box(canvas, Rect2(center + Vector2(-19, 6), Vector2(7, 8)), Art.INK, 2)

static func _belt(canvas: CanvasItem, entity: RefCounted, center: Vector2, time: float) -> void:
	var dir: Vector2 = DIRS[entity.direction]
	var side := dir.orthogonal()
	Art.box(canvas, Rect2(center - Vector2.ONE * 22, Vector2.ONE * 44), Art.INK, 4)
	Art.box(canvas, Rect2(center - Vector2.ONE * 18, Vector2.ONE * 36), Color("394743"), 3)
	for offset in [-19, 19]:
		canvas.draw_line(center + side * offset - dir * 20, center + side * offset + dir * 20, Color("8f947b"), 3, true)
	for i in range(4):
		var shift := fmod(time * (28 if entity.kind == "fast_belt" else 14), 12)
		var at := center + dir * (-22 + i * 12 + shift)
		canvas.draw_line(at - side * 12, at + side * 12, Color("576257"), 1, true)
	var accent := Color("cb8b60") if entity.kind == "fast_belt" else Color("c3ad6d")
	canvas.draw_polyline(PackedVector2Array([center - dir * 5 - side * 6, center + dir * 1, center - dir * 5 + side * 6]), accent, 2, true)

static func hand_extension(entity: RefCounted, interpolation: float) -> float:
	var travel := clampf((2.0 - entity.cooldown + interpolation) / 2.0, 0, 1)
	return lerpf(-16, 16, travel) if entity.carried != "" else lerpf(16, -16, travel)

static func _furnace(canvas: CanvasItem, p: Vector2, time: float, id: int, working: bool) -> void:
	Art.box(canvas, Rect2(p + Vector2(-17, -22), Vector2(34, 36)), Color("84624b"), 10, Art.INK)
	for row in range(3):
		canvas.draw_line(p + Vector2(-15, -13 + row * 10), p + Vector2(15, -13 + row * 10), Color("634c3b"), 1, true)
		canvas.draw_line(p + Vector2(-5 if row % 2 == 0 else 6, -21 + row * 10), p + Vector2(-5 if row % 2 == 0 else 6, -13 + row * 10), Color("634c3b"), 1)
	Art.box(canvas, Rect2(p + Vector2(-13, -3), Vector2(26, 18)), Art.INK, 8)
	if working:
		Art.glow(canvas, p + Vector2(0, 8), 18, Art.AMBER, 0.8 + sin(time * 6) * 0.1)
		Art.ellipse(canvas, p + Vector2(0, 8), Vector2(9, 6), Color("d77c44"))
		canvas.draw_colored_polygon(PackedVector2Array([p + Vector2(-6, 10), p + Vector2(-3, -1 - sin(time * 9) * 2), p + Vector2(1, 5), p + Vector2(5, -2), p + Vector2(7, 10)]), Art.AMBER)
	for x in [-7, 0, 7]: canvas.draw_line(p + Vector2(x, 1), p + Vector2(x, 13), Color("594c3c"), 2, true)
	Art.ellipse(canvas, p + Vector2(0, -23), Vector2(17, 7), Color("c1a887"))
	Art.box(canvas, Rect2(p + Vector2(7, -38), Vector2(10, 18)), Art.STEEL.darkened(0.2), 2)
	Art.box(canvas, Rect2(p + Vector2(5, -40), Vector2(14, 5)), Art.STEEL_LIGHT, 2)
	if working: Art.smoke(canvas, p + Vector2(12, -40), time, id)

static func _drill(canvas: CanvasItem, p: Vector2, time: float, dir: Vector2, working: bool) -> void:
	var shake := sin(time * 24) * 0.5 if working else 0.0
	var at := p + Vector2(shake, 0)
	Art.box(canvas, Rect2(at + Vector2(-17, -16), Vector2(34, 27)), Color("b99b5c"), 4, Art.INK)
	Art.box(canvas, Rect2(at + Vector2(-14, -20), Vector2(19, 17)), Art.COPPER, 3)
	for i in range(3): canvas.draw_line(at + Vector2(-11, -16 + i * 4), at + Vector2(1, -16 + i * 4), Color("765d40"), 2)
	Art.box(canvas, Rect2(at + Vector2(8, -25), Vector2(7, 23)), Art.STEEL, 2)
	canvas.draw_line(at + Vector2(10, -25), at + Vector2(10, 14), Art.STEEL_LIGHT, 3, true)
	for i in range(4):
		var y := fposmod((time * 15 if working else 0) + i * 5, 20)
		canvas.draw_line(at + Vector2(6, -6 + y), at + Vector2(16, -11 + y), Art.INK, 2, true)
	Art.ellipse(canvas, at + Vector2(11, 14), Vector2(8, 4), Color("615440"))
	_gear(canvas, at + Vector2(-4, 0), 8, time * 3 if working else 0.0, Art.CREAM.darkened(0.15))
	canvas.draw_line(at + dir * 13 + Vector2(0, 5), at + dir * 25 + Vector2(0, 5), Art.STEEL, 8, true)
	if working:
		for i in range(3):
			var age := fposmod(time * 1.5 + i / 3.0, 1.0)
			canvas.draw_circle(at + Vector2(11 + sin(i * 3.0) * age * 12, 13 - age * 9), 1 + age * 2, Color(0.76, 0.67, 0.46, (1 - age) * 0.4))

static func _gear(canvas: CanvasItem, at: Vector2, radius: float, angle: float, color: Color) -> void:
	for i in range(8):
		var axis := Vector2.from_angle(angle + i * TAU / 8)
		canvas.draw_line(at + axis * radius * 0.6, at + axis * radius, color, 3, true)
	canvas.draw_circle(at, radius * 0.7, color)
	canvas.draw_circle(at, radius * 0.28, Art.INK)
