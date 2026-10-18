extends RefCounted
## Illustrated civic silhouettes, restored materials, and an active beacon.
const Art = preload("res://scripts/view/art.gd")
const TILE := 48

static func draw_sites(canvas: Node2D, region: RefCounted, visible: Rect2i, selected: String, defense_phase: String = "idle", time: float = 0.0) -> void:
	if not region.enabled: return
	for site in region.sites.values():
		if visible.intersects(site.footprint().grow(3)): draw_site(canvas, site, selected, defense_phase, time)

static func draw_site(canvas: Node2D, site: RefCounted, selected: String, phase: String, time: float, stone_age: bool = false) -> void:
	var p := Vector2(site.origin) * TILE
	var operational: bool = site.repaired and site.health > 0
	var id: String = site.id
	if id == "town_hall":
		Art.shadow(canvas,p+Vector2(78,113),Vector2(74,27))
		var Hero = preload("res://scripts/view/hero_art.gd")
		Hero.paint(canvas,"town_hall",Hero.hall_frame(site.repaired,operational,stone_age),p)
		if site.repaired: _beacon(canvas,p,operational,phase,time,stone_age)
	else:
		Art.shadow(canvas, p + Vector2(78, 113), Vector2(74, 27))
		Art.box(canvas, Rect2(p + Vector2(12, 50), Vector2(126, 91)), Color("414b3d"), 7)
		var wall := (Color("b6bbb0") if stone_age else Color("a38a61")) if site.repaired else Color("858574")
		Art.box(canvas, Rect2(p + Vector2(17, 48), Vector2(113, 84)), wall, 5, Color("62694f"))
		for row in range(4):
			canvas.draw_line(p + Vector2(20, 72 + row * 15), p + Vector2(127, 72 + row * 15), wall.darkened(0.15), 1, true)
			for column in range(4 if stone_age or not site.repaired else 0):
				var x := 25 + column * 28 + (12 if row % 2 else 0)
				if x < 125: canvas.draw_line(p + Vector2(x, 58 + row * 15), p + Vector2(x, 72 + row * 15), wall.darkened(0.12), 1, true)
		if site.repaired:
			if stone_age:
				Art.box(canvas, Rect2(p + Vector2(13, 122), Vector2(122, 16)), Color("87928c"), 2, Art.STEEL)
			else:
				for x in [22, 124]: canvas.draw_line(p + Vector2(x, 53), p + Vector2(x, 130), Color("68573e"), 5)
		var roof := Color("637f73") if id == "trading_post" else (Color("b87c56") if id == "town_hall" else Color("637f85"))
		if stone_age and site.repaired: roof = roof.lerp(Color("586e7b"), 0.55)
		if not site.repaired: roof = Color("747664")
		if site.repaired:
			canvas.draw_colored_polygon(PackedVector2Array([p + Vector2(7, 61), p + Vector2(72, 15), p + Vector2(137, 61), p + Vector2(137, 83), p + Vector2(72, 40), p + Vector2(7, 83)]), roof.darkened(0.18))
			canvas.draw_colored_polygon(PackedVector2Array([p + Vector2(7, 61), p + Vector2(72, 15), p + Vector2(72, 40), p + Vector2(7, 83)]), roof.lightened(0.12))
			for i in range(1, 6):
				var offset := i * 10.0
				canvas.draw_line(p + Vector2(72 + offset, 16 + offset * 0.7), p + Vector2(72 + offset, 40 + offset * 0.66), roof.darkened(0.18), 1, true)
				canvas.draw_line(p + Vector2(72 - offset, 16 + offset * 0.7), p + Vector2(72 - offset, 40 + offset * 0.66), roof.darkened(0.1), 1, true)
			canvas.draw_polyline(PackedVector2Array([p + Vector2(7, 62), p + Vector2(72, 16), p + Vector2(137, 62)]), Art.CREAM.darkened(0.1), 3, true)
			canvas.draw_line(p + Vector2(9, 85), p + Vector2(72, 42), roof.darkened(0.3), 3, true)
			canvas.draw_line(p + Vector2(72, 42), p + Vector2(136, 85), roof.darkened(0.3), 3, true)
		else:
			canvas.draw_colored_polygon(PackedVector2Array([p + Vector2(8, 64), p + Vector2(49, 35), p + Vector2(62, 47), p + Vector2(55, 68), p + Vector2(8, 84)]), roof)
			for i in range(3): canvas.draw_line(p + Vector2(70 + i * 19, 22 + i * 14), p + Vector2(70 + i * 19, 63 + i * 8), Color("8c7e5e"), 5, true)
			canvas.draw_line(p + Vector2(69, 21), p + Vector2(137, 68), Color("a39c7c"), 5, true)
			for i in range(7):
				Art.box(canvas, Rect2(p + Vector2(18 + i * 16, 119 + posmod(i * 7, 16)), Vector2(12, 7)), Color("999781"), 2)
			for i in range(5): Art.ellipse(canvas, p + Vector2(24 + i * 10, 62 + sin(i) * 6), Vector2(9, 5), Color("566d48"))
		Art.box(canvas, Rect2(p + Vector2(59, 86), Vector2(28, 46)), Color("5a634c"), 7)
		Art.box(canvas, Rect2(p + Vector2(63, 91), Vector2(20, 39)), Color("34473e"), 4)
		canvas.draw_circle(p + Vector2(79, 113), 1.7, Art.AMBER)
		for x in [32, 100]:
			Art.box(canvas, Rect2(p + Vector2(x - 10, 87), Vector2(22, 26)), Color("5c6753"), 3)
			Art.box(canvas, Rect2(p + Vector2(x - 7, 90), Vector2(16, 20)), Color("e5b66b") if operational else Color("394d44"), 2)
			canvas.draw_line(p + Vector2(x + 1, 90), p + Vector2(x + 1, 109), Color("8d7855"), 2)
			if operational: Art.glow(canvas, p + Vector2(x, 102), 17, Art.AMBER, 0.7)
			if not site.repaired:
				canvas.draw_line(p + Vector2(x - 9, 93), p + Vector2(x + 10, 107), Color("ab9670"), 5, true)
		if site.repaired:
			_details(canvas, p, id, operational, time)
		else:
			canvas.draw_line(p + Vector2(62, 103), p + Vector2(85, 119), Color("aa9670"), 5, true)
	var port := (Vector2(site.port()) + Vector2.ONE * 0.5) * TILE
	Art.box(canvas, Rect2(port - Vector2(17, 14), Vector2(34, 28)), Color("4b685d"), 5, Color("a5c2a4"))
	canvas.draw_polyline(PackedVector2Array([port + Vector2(-7, -5), port + Vector2(2, 0), port + Vector2(-7, 5)]), Color("b9d9bc"), 2, true)
	var caption := "OLDBRIDGE MARKET" if id == "trading_post" else ("TOWN HALL" if id == "town_hall" else "ENGINEERS' WORKSHOP")
	canvas.draw_string(ThemeDB.fallback_font, p + Vector2(9, -10), caption + (" / RUIN" if not site.repaired else (" / DISABLED" if not operational else "")), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Art.CREAM)
	if selected == id: canvas.draw_rect(site_rect(site).grow(3), Color("a9ddbd"), false, 2)
	if site.repaired and site.health < site.max_health():
		Art.box(canvas, Rect2(p + Vector2(10, 146), Vector2(124, 5)), Art.INK, 2)
		Art.box(canvas, Rect2(p + Vector2(10, 146), Vector2(124.0 * site.health / site.max_health(), 5)), Color("d49a73"), 2)
	elif not site.repaired:
		var supplied := 0
		var required := 0
		for item in site.Definitions.SITES[id].repair:
			supplied += site.inventory.count(item)
			required += int(site.Definitions.SITES[id].repair[item])
		if supplied > 0: Art.box(canvas, Rect2(p + Vector2(10, 146), Vector2(124.0 * supplied / required, 4)), Art.AMBER, 2)

static func site_rect(site: RefCounted) -> Rect2:
	return Rect2(Vector2(site.origin) * TILE, Vector2(site.footprint().size) * TILE)

static func _details(canvas: Node2D, p: Vector2, id: String, operational: bool, time: float) -> void:
	for x in [23, 112]:
		Art.box(canvas, Rect2(p + Vector2(x - 8, 119), Vector2(18, 10)), Color("7d6546"), 2)
		for i in range(3):
			Art.ellipse(canvas, p + Vector2(x - 3 + i * 5, 118), Vector2(5, 5), Color("68875b"))
			if operational: canvas.draw_circle(p + Vector2(x - 2 + i * 5, 115), 1.7, Art.AMBER if id == "town_hall" else Color("cbb5a0"))
	if id == "trading_post":
		for i in range(6):
			var color := Color("e0c997") if i % 2 == 0 else Color("708973")
			Art.box(canvas, Rect2(p + Vector2(16 + i * 19, 78), Vector2(19, 15)), color, 2)
		Art.box(canvas, Rect2(p + Vector2(17, 117), Vector2(111, 7)), Color("9c794d"), 2)
		for i in range(3):
			Art.box(canvas, Rect2(p + Vector2(24 + i * 19, 111), Vector2(14, 9)), Color("b38c52"), 2)
	elif id == "workshop":
		Art.box(canvas, Rect2(p + Vector2(109, 28), Vector2(12, 24)), Art.STEEL.darkened(0.1), 2)
		Art.box(canvas, Rect2(p + Vector2(106, 25), Vector2(18, 5)), Art.STEEL_LIGHT, 2)
		if operational: Art.smoke(canvas, p + Vector2(115, 25), time, 3)
		canvas.draw_circle(p + Vector2(73, 76), 11, Art.STEEL)
		for i in range(6):
			var axis := Vector2.from_angle(i * TAU / 6)
			canvas.draw_line(p + Vector2(73, 76) + axis * 5, p + Vector2(73, 76) + axis * 12, Art.CREAM, 3, true)

static func _beacon(canvas: Node2D, p: Vector2, operational: bool, phase: String, time: float, stone_age: bool = false) -> void:
	Art.box(canvas, Rect2(p + Vector2(57, 18), Vector2(30, 29)), Art.STEEL, 4, Art.INK)
	Art.box(canvas, Rect2(p + Vector2(62, 23), Vector2(20, 18)), Art.AMBER if operational else Art.INK, 3)
	Art.box(canvas, Rect2(p + Vector2(53, 13), Vector2(38, 7)), Art.COPPER, 3)
	canvas.draw_line(p + Vector2(72, 13), p + Vector2(72, -17), Art.STEEL_LIGHT, 5, true)
	var at := p + Vector2(72, -21)
	var lit := operational and phase in ["warning", "active"]
	Art.box(canvas, Rect2(at - Vector2(8, 11), Vector2(16, 22)), Color("63776c"), 4, Art.INK)
	Art.box(canvas, Rect2(at - Vector2(5, 7), Vector2(10, 14)), Art.AMBER if lit else Color("7a998b"), 2)
	if lit:
		var pulse := fposmod(time * 0.6, 1.0)
		Art.glow(canvas, at, 29, Art.AMBER, 0.8 + sin(time * 4) * 0.2)
		canvas.draw_arc(at, 14 + pulse * 23, -2.8, -0.3, 28, Color(0.95, 0.78, 0.45, 0.5 * (1 - pulse)), 2, true)