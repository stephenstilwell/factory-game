extends RefCounted
const Art = preload("res://scripts/view/art.gd")
const Definitions = preload("res://scripts/data/story_catalog.gd")

static func person(canvas: CanvasItem, at: Vector2, id: String, time: float = 0.0, scale_factor: float = 1.0) -> void:
	var coat := Color(Definitions.NPCS.get(id, {"color": "a79071"}).color)
	canvas.draw_set_transform(at, 0, Vector2.ONE * scale_factor)
	Art.shadow(canvas, Vector2(0, 13), Vector2(14, 6))
	var bob := sin(time * 1.4) * 0.6
	for x in [-7, 2]:
		Art.box(canvas, Rect2(Vector2(x, 5), Vector2(6, 11)), Color("3b4541"), 2)
	Art.box(canvas, Rect2(Vector2(-11, -7 + bob), Vector2(22, 19)), coat.darkened(0.25), 5)
	Art.box(canvas, Rect2(Vector2(-9, -9 + bob), Vector2(18, 18)), coat, 4)
	canvas.draw_line(Vector2(-8, 7), Vector2(8, 7), Color("5b4a39"), 3, true)
	canvas.draw_circle(Vector2(0, -15 + bob), 8, Color("cba27b") if id != "town_hall" else Color("a67a5e"))
	if id == "trading_post":
		Art.box(canvas, Rect2(Vector2(-10, -24 + bob), Vector2(20, 6)), Color("72533d"), 3)
		canvas.draw_line(Vector2(-13, -18 + bob), Vector2(13, -18 + bob), Color("bc9b68"), 3, true)
		canvas.draw_line(Vector2(-5, -6), Vector2(6, 7), Color("dbb87a"), 3, true)
		Art.box(canvas, Rect2(Vector2(7, 2), Vector2(8, 10)), Color("745238"), 2)
	elif id == "workshop":
		canvas.draw_arc(Vector2(0, -17), 9, PI, TAU, 14, Color("9e9f91"), 4, true)
		canvas.draw_line(Vector2(-7, -15), Vector2(7, -15), Art.INK, 3, true)
		canvas.draw_line(Vector2(12, -1), Vector2(12, 13), Art.STEEL_LIGHT, 3, true)
		canvas.draw_arc(Vector2(12, -3), 4, 0, PI, 8, Art.STEEL_LIGHT, 2)
	else:
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(-9, -8), Vector2(-16, 12), Vector2(-5, 8)]), coat.darkened(0.2))
		canvas.draw_line(Vector2(-8, -22), Vector2(8, -22), Color("4b4540"), 5, true)
		Art.box(canvas, Rect2(Vector2(9, 1), Vector2(5, 8)), Art.AMBER, 2)
	canvas.draw_circle(Vector2(-3, -14 + bob), 1.0, Art.INK)
	canvas.draw_circle(Vector2(3, -14 + bob), 1.0, Art.INK)
	canvas.draw_set_transform(Vector2.ZERO)

static func draw_npc(canvas: Node2D, world: RefCounted, id: String, time: float, hovered: bool) -> void:
	var cell: Vector2i = world.story.npc_cell(world, id)
	var at := (Vector2(cell) + Vector2.ONE * 0.5) * 48
	person(canvas, at, id, time)
	var name: String = Definitions.NPCS[id].name
	var chapter: String = world.story.conversation(world, id)
	var unread: bool = not world.story.seen.has(chapter)
	canvas.draw_string(ThemeDB.fallback_font, at + Vector2(-22, -36), name + (" •" if unread else ""), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Art.AMBER if unread else Art.CREAM)
	if hovered:
		canvas.draw_arc(at + Vector2(0, 12), 19, 0, TAU, 24, Art.AMBER, 2)
		canvas.draw_string(ThemeDB.fallback_font, at + Vector2(-36, 38), "Click to talk", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Art.CREAM)

static func draw_homecoming(canvas: Node2D, site: RefCounted, cleared: int, phase: String, time: float) -> void:
	if not site.repaired or site.health == 0: return
	var p := Vector2(site.origin) * 48
	if site.id == "trading_post":
		for i in range(2):
			person(canvas, p + Vector2(37 + i * 65, 132), "visitor", time + i, 0.6)
	elif site.id == "workshop":
		Art.box(canvas, Rect2(p + Vector2(24, 124), Vector2(85, 9)), Color("8b6847"), 2)
		canvas.draw_line(p + Vector2(37, 119), p + Vector2(54, 119), Art.STEEL_LIGHT, 3, true)
		person(canvas, p + Vector2(110, 130), "workshop", time, 0.65)
	elif site.id == "town_hall":
		for i in range(3):
			Art.box(canvas, Rect2(p + Vector2(24 + i * 33, 123), Vector2(27, 13)), Color("856950"), 2)
			Art.box(canvas, Rect2(p + Vector2(26 + i * 33, 121), Vector2(22, 8)), Color("bcb794"), 2)
		if cleared > 0 and phase == "idle":
			for i in range(3): person(canvas, p + Vector2(23 + i * 43, 139), "visitor", time + i, 0.55)
static func draw_neighborhoods(canvas: Node2D, site: RefCounted, level: int, time: float) -> void:
	if not site.repaired or site.health <= 0: return
	# Small restored cottages occupy the Hall's reserved front terrace.
	var p := Vector2(site.origin) * 48
	for i in range(level):
		var at := p + Vector2(28 + i * 42, 123)
		Art.box(canvas, Rect2(at + Vector2(-14, -11), Vector2(28, 21)), Color("ccb894"), 2)
		canvas.draw_colored_polygon(PackedVector2Array([at + Vector2(-18, -10), at + Vector2(0, -24), at + Vector2(18, -10)]), Color("718f87"))
		Art.box(canvas, Rect2(at + Vector2(-3, -2), Vector2(7, 12)), Color("655440"), 1)
		Art.box(canvas, Rect2(at + Vector2(-11, -7), Vector2(5, 6)), Art.AMBER, 1)
		person(canvas, at + Vector2(14, 12), "visitor", time + i, 0.4)
