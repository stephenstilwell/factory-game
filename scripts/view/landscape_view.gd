extends RefCounted
const Art = preload("res://scripts/view/art.gd")
const TILE := 48
static var roads: Dictionary = {}

static func draw(canvas: Node2D, region: RefCounted, visible: Rect2i) -> void:
	if not region.enabled: return
	var market := (Vector2(region.sites.trading_post.port()) + Vector2.ONE * 0.5) * TILE
	var hall := (Vector2(region.sites.town_hall.port()) + Vector2.ONE * 0.5) * TILE
	var workshop := (Vector2(region.sites.workshop.port()) + Vector2.ONE * 0.5) * TILE
	var road_y := maxf(market.y, hall.y) + TILE * 2.1
	var paths: Array = []
	if market.distance_to(hall) < TILE * 48:
		paths.append({"points": PackedVector2Array([market, market + Vector2(-55, 32), Vector2(market.x + 10, road_y), Vector2(hall.x - 60, road_y), hall + Vector2(-55, 32), hall]), "restored": region.sites.trading_post.repaired})
	if market.distance_to(workshop) < TILE * 48:
		paths.append({"points": PackedVector2Array([Vector2(workshop.x - 90, road_y), workshop + Vector2(-60, -15), workshop]), "restored": region.sites.workshop.repaired})
	# Draw each material across all roads before the next layer to merge junctions.
	for layer in range(3):
		for path in paths: _path(canvas, path.points, path.restored, layer)
	for site in region.sites.values():
		if not visible.intersects(site.footprint().grow(2)): continue
		var origin := Vector2(site.origin) * TILE
		var size := Vector2(site.footprint().size) * TILE
		Art.box(canvas, Rect2(origin - Vector2(7, 5), size + Vector2(14, 12)), Color("5c5b44"), 16)
		for x in range(6):
			for y in range(6):
				var color := Color("8b8a6b") if site.repaired else Color("676e53")
				color = color.darkened(posmod(x * 3 + y * 7, 5) * 0.014)
				Art.box(canvas, Rect2(origin + Vector2(x * 24, y * 24), Vector2(22, 22)), color, 4)

static func _path(canvas: Node2D, controls: PackedVector2Array, restored: bool, layer: int) -> void:
	var key := hash(controls)
	if not roads.has(key):
		if roads.size() >= 32: roads.clear()
		var curve := Curve2D.new()
		for i in range(controls.size()):
			var previous := controls[maxi(0, i - 1)]
			var next := controls[mini(controls.size() - 1, i + 1)]
			var tangent := (next - previous) * 0.12
			curve.add_point(controls[i], -tangent, tangent)
		roads[key] = curve.get_baked_points()
	var points: PackedVector2Array = roads[key]
	var width: float = [34.0, 27.0, 15.0][layer]
	var colors := [Color("626149"), Color("9a8762") if restored else Color("778064"), Color("aa9670") if restored else Color("7d8367")]
	canvas.draw_polyline(points, colors[layer], width, true)
	canvas.draw_circle(points[0], width / 2.0, colors[layer])
	canvas.draw_circle(points[points.size() - 1], width / 2.0, colors[layer])
