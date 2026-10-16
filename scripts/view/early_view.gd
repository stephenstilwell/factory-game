extends RefCounted
const Art = preload("res://scripts/view/art.gd")
const TILE := 48

static func machine(canvas: CanvasItem, entity: RefCounted, p: Vector2, time: float) -> void:
	var wood := Color("b58d59")
	Art.shadow(canvas, p + Vector2(0, 12), Vector2(23, 12))
	match entity.kind:
		"lumber_camp", "communal_hearth":
			Art.box(canvas, Rect2(p + Vector2(-20, -10), Vector2(40, 30)), wood.darkened(0.12), 3)
			for row in range(3): canvas.draw_line(p + Vector2(-18, row * 8 - 5), p + Vector2(18, row * 8 - 5), wood.darkened(0.3), 2)
			canvas.draw_colored_polygon(PackedVector2Array([p + Vector2(-25, -8), p + Vector2(0, -34), p + Vector2(25, -8)]), Color("728062") if entity.kind == "lumber_camp" else Color("b69b6c"))
			Art.box(canvas, Rect2(p + Vector2(-6, 1), Vector2(12, 19)), Art.INK, 2)
			if entity.kind == "communal_hearth":
				canvas.draw_circle(p + Vector2(13, 7), 4, Art.AMBER)
			else:
				for row in range(3):
					canvas.draw_line(p + Vector2(-19, 17 + row * 4), p + Vector2(15, 17 + row * 4), wood.lightened(0.15), 4)
		"cart_post":
			for x in [-14, 14]:
				canvas.draw_circle(p + Vector2(x, 15), 7, Art.INK)
				canvas.draw_circle(p + Vector2(x, 15), 4, wood.darkened(0.2))
			Art.box(canvas, Rect2(p + Vector2(-22, -4), Vector2(44, 19)), wood, 3, Art.INK)
			for x in [-13, 0, 13]: canvas.draw_line(p + Vector2(x, -3), p + Vector2(x, 12), wood.darkened(0.25), 2)
			canvas.draw_line(p + Vector2(-20, -3), p + Vector2(-20, -26), wood.darkened(0.1), 4)
			canvas.draw_line(p + Vector2(-20, -26), p + Vector2(12, -26), Art.CREAM, 3)
		"watermill":
			Art.box(canvas, Rect2(p + Vector2(-21, -17), Vector2(30, 35)), wood, 3)
			canvas.draw_colored_polygon(PackedVector2Array([p + Vector2(-26, -16), p + Vector2(-7, -34), p + Vector2(15, -16)]), Art.STEEL)
			var axle := p + Vector2(16, 0)
			canvas.draw_arc(axle, 18, 0, TAU, 24, wood.darkened(0.2), 4)
			for i in range(8):
				var axis := Vector2.from_angle(i * TAU / 8 + time * 0.6)
				canvas.draw_line(axle, axle + axis * 18, wood, 3)
				canvas.draw_line(axle + axis * 18 - axis.orthogonal() * 4, axle + axis * 18 + axis.orthogonal() * 4, Art.CREAM, 3)
			canvas.draw_circle(axle, 4, Art.STONE)
		"charcoal_kiln":
			Art.ellipse(canvas, p + Vector2(0, 9), Vector2(24, 14), Color("494e3f"))
			Art.ellipse(canvas, p + Vector2(0, -1), Vector2(21, 17), Color("6a6a50"))
			canvas.draw_line(p + Vector2(-14, 7), p + Vector2(14, 7), Art.INK, 6)
			canvas.draw_line(p + Vector2(-9, 7), p + Vector2(9, 7), Art.AMBER.darkened(0.3), 2)
			if entity.status == "Working": Art.smoke(canvas, p + Vector2(0, -16), time, entity.id)

static func landscape(canvas: CanvasItem, world: RefCounted, area: Rect2i) -> void:
	if not world.early.enabled: return
	# The old millrace is shallow/passable; it is a power location, not a fluid simulation.
	for y in range(maxi(21, area.position.y), mini(52, area.end.y)):
		for x in range(22, 28):
			var cell := Vector2i(x, y)
			if area.has_point(cell) and world.early.water_at(cell) and world.at(cell) == null and world.settlements.at(cell) == null and world.terrain.tile(cell).is_empty():
				var p := Vector2(cell) * TILE
				canvas.draw_rect(Rect2(p, Vector2.ONE * TILE), Color("517f80"))
				canvas.draw_line(p + Vector2(9, 18), p + Vector2(34, 22), Color("91b6a6"), 2)
	if area.intersects(Rect2i(23, 25, 6, 3)):
		var crossing := Vector2(23, 26) * TILE
		if world.early.phase >= 2:
			Art.box(canvas, Rect2(crossing + Vector2(-8, 0), Vector2(250, 36)), Art.STONE, 3)
			for i in range(20):
				canvas.draw_line(crossing + Vector2(i * 12, 4), crossing + Vector2(i * 12, 32), Color("b79768"), 9)
			for row in [0, 36]: canvas.draw_line(crossing + Vector2(-4, row), crossing + Vector2(242, row), Color("63766d"), 5)
		else:
			for side in [0, 4]:
				for i in range(3): canvas.draw_line(crossing + Vector2(side * 48 + i * 10, 6), crossing + Vector2(side * 48 + i * 10, 29), Color("867855"), 7)
	var first: Vector2i = world.terrain.chunk_at(area.position)
	var last: Vector2i = world.terrain.chunk_at(area.end)
	for x in range(first.x, last.x + 1):
		for y in range(first.y, last.y + 1):
			for cell in world.early.forage_cells(Vector2i(x, y), world.terrain.seed_value):
				if not area.has_point(cell): continue
				var resource: Dictionary = world.early.resource_at(world, cell)
				if resource.is_empty(): continue
				var p := (Vector2(cell) + Vector2.ONE * 0.5) * TILE
				if resource.item == "timber":
					for row in range(3):
						var a := p + Vector2(-15 + row * 2, -7 + row * 7)
						canvas.draw_line(a, a + Vector2(28, -4), Color("77603f"), 7)
						canvas.draw_circle(a + Vector2(28, -4), 3, Color("d3b582"))
				else:
					for i in range(3):
						var at := p + Vector2(-10 + i * 10, -4 + i % 2 * 6)
						Art.ellipse(canvas, at, Vector2(10, 8), Color("697f4d"))
						for j in range(3): canvas.draw_circle(at + Vector2(-4 + j * 4, -3 + j % 2 * 4), 2, Color("c1887d"))

static func settlers(canvas: CanvasItem, world: RefCounted, area: Rect2i) -> void:
	if not world.early.enabled or world.early.phase == 0: return
	for id in world.by_kind.communal_hearth:
		var home = world.entities[id]
		if home.health <= 0 or not area.has_point(home.cell): continue
		var p := (Vector2(home.cell) + Vector2.ONE * 0.5) * TILE
		Art.box(canvas, Rect2(p + Vector2(-21, 16), Vector2(42, 6)), Art.STONE, 2)
		for i in range(2):
			var at := p + Vector2(14 + i * 8, 13 + i * 3)
			Art.ellipse(canvas, at, Vector2(3, 5), Color("a8b67c") if i == 0 else Art.COPPER)
			canvas.draw_circle(at + Vector2(0, -7), 3, Color("d4b98e"))

static func workers(canvas: CanvasItem, world: RefCounted, area: Rect2i, time: float) -> void:
	if not world.early.enabled: return
	var count := 0
	for id in world.by_kind.cart_post:
		var post = world.entities[id]
		if post.health <= 0 or not area.grow(10).has_point(post.cell): continue
		var source = world.early.route_source(world, post)
		if source == null: continue
		if count >= 12: return
		count += 1
		var t: float = post.progress / 40.0
		var p := (Vector2(source.cell).lerp(Vector2(post.cell), t) + Vector2.ONE * 0.5) * TILE
		Art.shadow(canvas, p + Vector2(0, 6), Vector2(7, 3))
		Art.ellipse(canvas, p + Vector2(0, sin(time * 10) * 0.7), Vector2(5, 8), Color("b4ad7b"))
		canvas.draw_circle(p + Vector2(0, -10), 4, Color("d0af80"))
		Art.box(canvas, Rect2(p + Vector2(3, -2), Vector2(9, 8)), Art.COPPER, 2)
