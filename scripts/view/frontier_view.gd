extends RefCounted
const Art = preload("res://scripts/view/art.gd")
const Frontier = preload("res://scripts/model/frontier.gd")
const TILE := 48

static func tree(canvas: CanvasItem, world: RefCounted, cell: Vector2i, time: float, faded: bool) -> void:
	var p := (Vector2(cell) + Vector2.ONE * 0.5) * TILE
	var seed_value: int = Frontier.hash_cell(cell, world.terrain.seed_value)
	var height: float = 42 + seed_value % 22
	var palette: Array = [Color("7d9560"), Color("477661"), Color("8a9b5e")]
	var leaf: Color = palette[Frontier.biome(cell, world.terrain.seed_value)]
	var region: int = world.frontier.landscape_index(cell)
	if region == 1: leaf = Color("9aab69")
	elif region == 2: leaf = Color("668782")
	var sway := sin(time * 1.1 + seed_value % 17) * 1.4
	Art.shadow(canvas, p + Vector2(0, 4), Vector2(26, 10))
	canvas.draw_line(p + Vector2(0, 8), p + Vector2(sway, -height + 10), Color("5d5940"), 7, true)
	canvas.draw_line(p + Vector2(1, 6), p + Vector2(sway + 1, -height + 10), Color("9b8657"), 2, true)
	leaf.a = 0.42 if faded else 1.0
	for i in range(4):
		var at := p + Vector2([-12, 13, 0, -2][i] + sway, -height + [10, 7, -8, 3][i])
		Art.ellipse(canvas, at + Vector2(2, 5), Vector2(21 - i, 16), leaf.darkened(0.16))
		Art.ellipse(canvas, at, Vector2(20 - i, 15), leaf.lightened(i * 0.025))
	if seed_value % 5 == 0:
		for i in range(3):
			var tint := Color("d9b976")
			tint.a = leaf.a
			canvas.draw_circle(p + Vector2(-11 + i * 9 + sway, -height + 3 + i % 2 * 6), 2, tint)

static func landmark(canvas: CanvasItem, world: RefCounted, id: String, time: float) -> void:
	var rect: Rect2i = world.frontier.footprint(id)
	var p := Vector2(rect.position) * TILE
	var size := Vector2(rect.size) * TILE
	var recovered: bool = world.frontier.claimed(id)
	Art.shadow(canvas, p + size / 2 + Vector2(0, 30), size * Vector2(0.46, 0.18))
	Art.box(canvas, Rect2(p - Vector2(7, 3), size + Vector2(14, 6)), Color("686b4d"), 16)
	match id:
		"quarry":
			for row in range(3):
				var step := p + Vector2(17 + row * 15, 35 + row * 36)
				Art.box(canvas, Rect2(step, Vector2(203 - row * 30, 33)), Color("818c88").darkened(row * 0.09), 4, Art.STEEL)
				canvas.draw_line(step + Vector2(4, 3), step + Vector2(196 - row * 30, 3), Color("bac0ad"), 2)
				for column in range(3): canvas.draw_line(step + Vector2(30 + column * 48, 8), step + Vector2(28 + column * 48, 28), Color("63746f"), 2)
			for x in [25, 184]:
				canvas.draw_line(p + Vector2(x, 65), p + Vector2(x, 145), Art.COPPER.darkened(0.25), 5)
			canvas.draw_line(p + Vector2(19, 61), p + Vector2(202, 61), Art.COPPER, 6)
			Art.box(canvas, Rect2(p + Vector2(96, 121), Vector2(48, 29)), Art.CREAM if not recovered else Color("a8b7a4"), 3)
			for i in range(3): canvas.draw_line(p + Vector2(102, 128 + i * 6), p + Vector2(135, 128 + i * 6), Art.STEEL, 1)
		"camp":
			canvas.draw_colored_polygon(PackedVector2Array([p + Vector2(20, 90), p + Vector2(70, 15), p + Vector2(125, 90)]), Color("b9b18b"))
			canvas.draw_colored_polygon(PackedVector2Array([p + Vector2(70, 15), p + Vector2(85, 90), p + Vector2(125, 90)]), Color("7e8061"))
			canvas.draw_colored_polygon(PackedVector2Array([p + Vector2(45, 90), p + Vector2(70, 48), p + Vector2(80, 90)]), Art.INK)
			Art.box(canvas, Rect2(p + Vector2(135, 65), Vector2(35, 26)), Art.COPPER.darkened(0.3), 3)
			Art.box(canvas, Rect2(p + Vector2(131, 56), Vector2(43, 15)), Art.CREAM, 2)
			for i in range(3): canvas.draw_line(p + Vector2(140, 59 + i * 3), p + Vector2(165, 59 + i * 3), Art.STEEL, 1)
			canvas.draw_circle(p + Vector2(140, 113), 12, Art.STONE.darkened(0.4))
			canvas.draw_line(p + Vector2(130, 115), p + Vector2(150, 110), Art.COPPER.darkened(0.4), 4)
		"orchard":
			for x in [42, 118, 195]:
				canvas.draw_line(p + Vector2(x, 145), p + Vector2(x, 40), Color("796442"), 7)
				Art.ellipse(canvas, p + Vector2(x, 51), Vector2(35, 29), Color("76915e"))
				for i in range(5): canvas.draw_circle(p + Vector2(x - 22 + i * 10, 45 + (i % 2) * 15), 3, Color("d7ba76"))
			for x in range(12, 230, 20):
				canvas.draw_line(p + Vector2(x, 175), p + Vector2(x, 145), Art.STONE.darkened(0.2), 3)
			canvas.draw_line(p + Vector2(10, 154), p + Vector2(232, 154), Art.COPPER.darkened(0.2), 3)
			Art.box(canvas, Rect2(p + Vector2(82, 119), Vector2(57, 23)), Color("b59461"), 4)
			canvas.draw_circle(p + Vector2(172, 132), 8, Art.STEEL)
			canvas.draw_line(p + Vector2(177, 129), p + Vector2(191, 121), Art.STEEL, 5)
		"depot":
			Art.box(canvas, Rect2(p + Vector2(16, 39), Vector2(208, 123)), Color("8d8465"), 5)
			for row in range(4):
				canvas.draw_line(p + Vector2(20, 57 + row * 25), p + Vector2(220, 57 + row * 25), Color("686c56"), 2)
			canvas.draw_colored_polygon(PackedVector2Array([p + Vector2(6, 47), p + Vector2(91, 4), p + Vector2(190, 12), p + Vector2(234, 45)]), Art.STEEL if recovered else Color("58675c"))
			for x in [38, 147]:
				Art.box(canvas, Rect2(p + Vector2(x, 79), Vector2(53, 74)), Art.INK, 3)
				Art.box(canvas, Rect2(p + Vector2(x + 5, 82), Vector2(43, 23)), Color("a8c3a0") if recovered else Color("847c58"), 2)
			canvas.draw_line(p + Vector2(32, 159), p + Vector2(205, 159), Art.COPPER, 5)
			for x in range(38, 205, 17): canvas.draw_circle(p + Vector2(x, 165), 5, Art.STEEL)
			if recovered:
				var runner := p + Vector2(117 + sin(time * 0.6) * 12, 163)
				Art.ellipse(canvas, runner, Vector2(7, 10), Color("90b2a0"))
				canvas.draw_circle(runner + Vector2(0, -12), 5, Color("d1b38a"))
				Art.box(canvas, Rect2(runner + Vector2(1, -1), Vector2(12, 10)), Art.COPPER, 2)
	var hatch := (Vector2(world.frontier.port(id)) + Vector2.ONE * 0.5) * TILE
	Art.box(canvas, Rect2(hatch - Vector2(17, 14), Vector2(34, 28)), Color("93b48c"), 4, Art.INK)
	canvas.draw_string(ThemeDB.fallback_font, hatch + Vector2(-7, 6), "✓" if recovered else "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Art.CREAM)
	canvas.draw_string(ThemeDB.fallback_font, p + Vector2(0, -12), world.frontier.Definitions.SITES[id].name, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Art.CREAM)

static func garden(canvas: CanvasItem, world: RefCounted, time: float, visible: Rect2i) -> void:
	if not world.frontier.claimed("orchard") or not world.settlements.enabled or not world.settlements.sites.trading_post.repaired: return
	var origin: Vector2i = world.settlements.sites.trading_post.origin
	if not visible.intersects(Rect2i(origin - Vector2i(4, 4), Vector2i(13, 13))): return
	var p := Vector2.ZERO
	var found := false
	for offset in [Vector2i(-3, 4), Vector2i(4, 1), Vector2i(-4, -2), Vector2i(0, -4)]:
		var vacant := true
		for x in range(4):
			for y in range(2):
				var cell: Vector2i = origin + offset + Vector2i(x, y)
				if world.at(cell) != null or world.settlements.at(cell) != null or world.frontier.at(cell) != "" or not world.terrain.tile(cell).is_empty() or world.frontier.tree_at(world, cell): vacant = false
		if vacant:
			p = Vector2(origin + offset) * TILE
			found = true
			break
	if not found:
		for x in [32, 100]:
			var at := Vector2(origin) * TILE + Vector2(x, 116)
			Art.box(canvas, Rect2(at - Vector2(9, 0), Vector2(18, 9)), Art.COPPER, 2)
			for i in range(3): canvas.draw_circle(at + Vector2(-5 + i * 5, -4), 3, Color("b5c790"))
		return
	for row in range(2):
		Art.box(canvas, Rect2(p + Vector2(0, row * 25), Vector2(130, 20)), Color("655d42"), 4)
		for i in range(7):
			var at := p + Vector2(10 + i * 18, 10 + row * 25)
			canvas.draw_line(at, at + Vector2(0, -9), Color("7e9e65"), 2)
			canvas.draw_circle(at + Vector2(0, -10), 3, Color("deba7a") if row == 0 else Color("b9c9a1"))
	var at := p + Vector2(145 + sin(time * 0.5) * 4, 18)
	Art.shadow(canvas, at + Vector2(0, 8), Vector2(9, 4))
	Art.ellipse(canvas, at, Vector2(7, 10), Color("97ac79"))
	canvas.draw_circle(at + Vector2(0, -12), 5, Color("d2b98a"))
	Art.ellipse(canvas, at + Vector2(0, -16), Vector2(10, 3), Color("c3af72"))
	canvas.draw_line(at + Vector2(3, 0), at + Vector2(15, 6 + sin(time) * 3), Art.COPPER, 3)
	canvas.draw_string(ThemeDB.fallback_font, p + Vector2(0, 63), "Iona's community garden", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Art.CREAM)

static func wildlife(canvas: CanvasItem, world: RefCounted, visible: Rect2i, time: float) -> void:
	var first := Vector2i(floori(visible.position.x / 8.0), floori(visible.position.y / 8.0))
	var last := Vector2i(floori(visible.end.x / 8.0), floori(visible.end.y / 8.0))
	var count := 0
	for x in range(first.x, last.x + 1):
		for y in range(first.y, last.y + 1):
			if count >= 12: return
			var key := Frontier.hash_cell(Vector2i(x, y), world.terrain.seed_value, 91)
			if key % 3 == 0: continue
			count += 1
			var p := Vector2(x * 8 + key % 6, y * 8 + (key / 7) % 6) * TILE
			p += Vector2(sin(time * 0.35 + key % 17) * 70, cos(time * 0.27 + key % 11) * 25)
			if key % 2 == 0:
				var flap := sin(time * 9 + key % 5) * 5
				canvas.draw_polyline(PackedVector2Array([p + Vector2(-7, flap), p, p + Vector2(7, flap)]), Art.INK.lightened(0.1), 2, true)
			else:
				Art.ellipse(canvas, p + Vector2(-3, 0), Vector2(2 + absf(sin(time * 12)) * 2, 3), Color("d9bf7f"))
				Art.ellipse(canvas, p + Vector2(3, 0), Vector2(2 + absf(sin(time * 12)) * 2, 3), Color("b8cba0"))
