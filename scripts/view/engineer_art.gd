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
	var Hero = preload("res://scripts/view/hero_art.gd")
	Hero.paint(canvas,"player",Hero.player_frame(direction),p)
	if mining:
		var aim := (target - at).normalized()
		var swing := aim.rotated(sin(time * 11) * 0.45)
		var hand := p + swing * 14
		canvas.draw_line(p + aim * 7, hand, Color("c39662"), 5, true)
		canvas.draw_line(hand - swing * 4, hand + swing * 13, Color("785a3f"), 3, true)
		canvas.draw_line(hand + swing * 12 - swing.orthogonal() * 7, hand + swing * 12 + swing.orthogonal() * 8, Art.STEEL_LIGHT, 3, true)
