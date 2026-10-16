extends RefCounted
const Art = preload("res://scripts/view/art.gd")
const Definitions = preload("res://scripts/data/combat_catalog.gd")
const TILE := 48

static func draw_route(canvas: Node2D, world: RefCounted, visible: Rect2i, selected_site: String) -> void:
	if not world.settlements.enabled: return
	var hall = world.settlements.sites.town_hall
	if not hall.repaired and selected_site != "town_hall": return
	for entry in world.defense.entries(world):
		for x in range(hall.origin.x + 3, entry.x + 1):
			var cell := Vector2i(x, entry.y)
			if not visible.has_point(cell): continue
			var center := (Vector2(cell) + Vector2.ONE * 0.5) * TILE
			canvas.draw_rect(Rect2(center - Vector2(24, 7), Vector2(48, 14)), Color(0.60, 0.48, 0.32, 0.15))
			if x % 3 == 0: canvas.draw_polyline(PackedVector2Array([center + Vector2(6, -4), center + Vector2(-2, 0), center + Vector2(6, 4)]), Color("c8ad7c"), 2, true)
		var at := (Vector2(entry) + Vector2.ONE * 0.5) * TILE
		canvas.draw_arc(at, 24, 0, TAU, 32, Color("d9966e"), 2, true)
		canvas.draw_string(ThemeDB.fallback_font, at + Vector2(-42, 42), "ARRIVAL GATE", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Art.AMBER)

static func draw_enemy(canvas: Node2D, enemy: Dictionary, maximum: int, time: float, tick: int = 0, reduced: bool = false) -> void:
	var center := (Vector2(enemy.cell) + Vector2.ONE * 0.5) * TILE
	var kind: String = enemy.get("kind", "scout")
	var definition: Dictionary = Definitions.ENEMIES[kind]
	var color := Color(definition.color)
	if not reduced and int(enemy.get("hit_until", 0)) > tick: color = Art.CREAM
	Art.shadow(canvas, center + Vector2(0, 6), Vector2(18, 10))
	var stride := sin(time * (14 if kind == "scout" else 7) + enemy.id) * 3
	for side in [-1, 1]:
		for y in [-8, 8]:
			var elbow := center + Vector2(15 * side, y + stride * side)
			canvas.draw_polyline(PackedVector2Array([center + Vector2(4 * side, y / 2.0), elbow, elbow + Vector2(-5, 5)]), Art.INK, 5, true)
			canvas.draw_line(center + Vector2(4 * side, y / 2.0), elbow, color.darkened(0.25), 3, true)
	if kind == "hauler":
		Art.box(canvas, Rect2(center + Vector2(-21, -15), Vector2(42, 30)), Art.INK, 4)
		Art.box(canvas, Rect2(center + Vector2(-19, -18), Vector2(38, 29)), color, 4)
		for x in [-12, 0, 12]: canvas.draw_line(center + Vector2(x, -15), center + Vector2(x, 6), Art.STEEL, 3, true)
	elif kind == "dismantler":
		Art.box(canvas, Rect2(center + Vector2(-16, -17), Vector2(32, 29)), color, 3, Art.INK)
		for y in [-11, 10]:
			canvas.draw_line(center + Vector2(-9, y), center + Vector2(-25, y), Art.INK, 6, true)
			canvas.draw_line(center + Vector2(-25, y), center + Vector2(-29, y * 0.5), Art.COPPER, 5, true)
	else:
		Art.box(canvas, Rect2(center + Vector2(-12, -15), Vector2(24, 23)), color, 8, Art.INK)
		canvas.draw_line(center + Vector2(3, -11), center + Vector2(11, -24), Art.STEEL_LIGHT, 2, true)
		canvas.draw_circle(center + Vector2(11, -24), 3, Art.AMBER)
	# The same fractured relay rune links all three to the old enchanted network.
	canvas.draw_polyline(PackedVector2Array([center + Vector2(-5, -10), center + Vector2(2, -4), center + Vector2(-4, 3)]), Art.CREAM, 2, true)
	canvas.draw_circle(center + Vector2(-12, -3), 3, Art.AMBER)
	Art.box(canvas, Rect2(center + Vector2(-18, -32), Vector2(36, 5)), Art.INK, 2)
	Art.box(canvas, Rect2(center + Vector2(-18, -32), Vector2(36.0 * enemy.health / maximum, 5)), Color(definition.color), 2)
	if enemy.get("slow", 0) > 0: canvas.draw_arc(center, 24, 0, TAU, 24, Color("83d3cc"), 2, true)
	if enemy.get("attack_ticks", 0) > 0:
		var target := (Vector2(enemy.attack_cell) + Vector2.ONE * 0.5) * TILE
		canvas.draw_rect(Rect2(target - Vector2.ONE * 22, Vector2.ONE * 44), Color(0.9, 0.4, 0.25, 0.28))
		canvas.draw_rect(Rect2(target - Vector2.ONE * 22, Vector2.ONE * 44), Color("ed9e6b"), false, 2)
		canvas.draw_line(center, target, Color("ed9e6b"), 2, true)
	if not reduced and int(enemy.get("hit_until", 0)) > tick:
		canvas.draw_string(ThemeDB.fallback_font, center + Vector2(-10, -40), "-%d" % enemy.get("last_damage", 0), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Art.CREAM)

static func draw_shots(canvas: Node2D, world: RefCounted, reduced: bool = false) -> void:
	for shot in world.defense.shots:
		var start := (Vector2(shot.from) + Vector2.ONE * 0.5) * TILE
		var end := (Vector2(shot.to) + Vector2.ONE * 0.5) * TILE
		var color := Color("89ded2") if shot.kind == "pulse_turret" else Art.AMBER
		canvas.draw_line(start, end, color, 3.0 if shot.kind == "cannon_turret" else 1.5, true)
		if not reduced: Art.glow(canvas, start, 13, color)
		if shot.kind == "pulse_turret": canvas.draw_arc(end, 1.8 * TILE, 0, TAU, 48, Color(0.55, 0.9, 0.85, 0.6), 2, true)
		if not reduced: Art.glow(canvas, end, 10, color)
	if reduced: return
	for impact in world.defense.impacts:
		var at := (Vector2(impact.cell) + Vector2.ONE * 0.5) * TILE
		for i in range(5):
			var direction := Vector2.from_angle(i * TAU / 5)
			canvas.draw_line(at + direction * 10, at + direction * 21, Color(impact.color), 4, true)

static func draw_player(canvas: Node2D, world: RefCounted, pointer: bool, _reduced: bool, at: Vector2) -> void:
	if world.combat.health < 100:
		Art.box(canvas, Rect2(at + Vector2(-20, -39), Vector2(40, 5)), Art.INK, 2)
		Art.box(canvas, Rect2(at + Vector2(-20, -39), Vector2(world.combat.health * 0.4, 5)), Color("95c2a3"), 2)
	if world.combat.invulnerable > 0: canvas.draw_arc(at, 25, 0, TAU, 32, Color("a9d9d3"), 2, true)
	if not world.combat.armed: return
	var direction: Vector2 = (world.combat.aim - world.player_position).normalized()
	canvas.draw_line(at + direction * 9, at + direction * 31, Art.INK, 8, true)
	canvas.draw_line(at + direction * 8 - Vector2(0, 3), at + direction * 30 - Vector2(0, 3), Art.STEEL_LIGHT, 5, true)
	canvas.draw_line(at + direction * 12, at + direction * 12 + direction.orthogonal() * 7, Art.COPPER, 4, true)
	if not pointer: return
	var aim: Vector2 = world.combat.aim * TILE
	var targeted: int = world.combat.target(world)
	var color := Color("a2d3b1") if targeted != -1 else Art.AMBER
	canvas.draw_arc(at, Definitions.RIFLE_RANGE * TILE, 0, TAU, 96, Color(0.6, 0.8, 0.7, 0.17), 1)
	canvas.draw_arc(aim, 12, 0, TAU, 24, color, 2, true)
	for axis in [Vector2.RIGHT, Vector2.DOWN]:
		canvas.draw_line(aim - axis * 18, aim - axis * 8, color, 2, true)
		canvas.draw_line(aim + axis * 8, aim + axis * 18, color, 2, true)
	if targeted != -1:
		var enemy: Dictionary = world.defense.enemies[targeted]
		var point := (Vector2(enemy.cell) + Vector2.ONE * 0.5) * TILE
		canvas.draw_arc(point, 27, 0, TAU, 32, color, 2, true)
