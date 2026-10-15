extends RefCounted
const Art = preload("res://scripts/view/art.gd")

static func draw(canvas: Node2D, at: Vector2, direction: Vector2, time: float, walking: bool, mining: bool, target: Vector2) -> void:
	Art.shadow(canvas, at + Vector2(0, 11), Vector2(15, 7))
	var stride := sin(time * 12) * 3.0 if walking else 0.0
	var bob := absf(sin(time * 12)) * 0.8 if walking else 0.0
	for side in [-1, 1]:
		Art.box(canvas, Rect2(at + Vector2(side * 5 - 4, 5 + stride * side), Vector2(8, 10)), Color("30474b"), 3)
		Art.box(canvas, Rect2(at + Vector2(side * 5 - 4, 12 + stride * side), Vector2(9, 5)), Color("293733"), 2)
	var p := at + Vector2(0, -bob)
	Art.box(canvas, Rect2(p + Vector2(-13, -7), Vector2(26, 20)), Art.INK, 7)
	Art.box(canvas, Rect2(p + Vector2(-12, -10), Vector2(24, 20)), Color("c39662"), 7)
	Art.box(canvas, Rect2(p - direction * 5 + Vector2(-10, -7), Vector2(20, 15)), Color("637a67"), 4, Art.INK)
	canvas.draw_line(p + Vector2(-7, -6), p + Vector2(-7, 7), Color("b4a47d"), 2, true)
	canvas.draw_line(p + Vector2(7, -6), p + Vector2(7, 7), Color("b4a47d"), 2, true)
	canvas.draw_line(p + Vector2(-11, 7), p + Vector2(10, 7), Color("6b513c"), 3, true)
	var scarf := p + Vector2(-9, -10)
	canvas.draw_colored_polygon(PackedVector2Array([scarf, scarf + Vector2(-7, 5 + sin(time * 3)), scarf + Vector2(1, 7)]), Color("b76e53"))
	var head := p + Vector2(0, -12)
	Art.ellipse(canvas, head + Vector2(0, 2), Vector2(10, 9), Color("a97752"))
	Art.ellipse(canvas, head + Vector2(0, -2), Vector2(12, 9), Color("d9ae64"))
	canvas.draw_arc(head + Vector2(0, -2), 8, 3.5, 5.2, 12, Color("f2d293"), 2, true)
	var face := head + direction * 7
	canvas.draw_line(face - direction.orthogonal() * 7, face + direction.orthogonal() * 7, Color("394f4a"), 4, true)
	canvas.draw_circle(face - direction.orthogonal() * 3, 2, Color("9ebeb0"))
	canvas.draw_circle(face + direction.orthogonal() * 3, 2, Color("9ebeb0"))
	var lantern := p + Vector2(12, 4)
	Art.box(canvas, Rect2(lantern - Vector2(2, 3), Vector2(5, 7)), Art.AMBER, 2)
	Art.glow(canvas, lantern, 6, Art.AMBER, 0.5)
	if mining:
		var aim := (target - at).normalized()
		var swing := aim.rotated(sin(time * 11) * 0.45)
		var hand := p + swing * 14
		canvas.draw_line(p + aim * 7, hand, Color("c39662"), 5, true)
		canvas.draw_line(hand - swing * 4, hand + swing * 13, Color("785a3f"), 3, true)
		canvas.draw_line(hand + swing * 12 - swing.orthogonal() * 7, hand + swing * 12 + swing.orthogonal() * 8, Art.STEEL_LIGHT, 3, true)
