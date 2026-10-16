extends RefCounted
## Cached weighted grids, invalidated when structure topology changes.
const Definitions = preload("res://scripts/data/combat_catalog.gd")
var revision := -1
var origin := Vector2i(999999, 999999)
var grids: Dictionary = {}

func region(world: RefCounted) -> Rect2i:
	return Rect2i(world.settlements.sites.town_hall.origin + Vector2i(-5, -6), Vector2i(29, 15))

func next_cell(world: RefCounted, enemy: Dictionary) -> Vector2i:
	var hall = world.settlements.sites.town_hall
	if revision != world.navigation_revision or origin != hall.origin:
		revision = world.navigation_revision
		origin = hall.origin
		grids.clear()
	if not grids.has(enemy.kind):
		var grid := AStarGrid2D.new()
		grid.region = region(world)
		grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
		grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
		grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
		grid.update()
		for y in range(grid.region.position.y, grid.region.end.y):
			for x in range(grid.region.position.x, grid.region.end.x):
				var cell := Vector2i(x, y)
				if world.solid(cell): grid.set_point_weight_scale(cell, float(Definitions.ENEMIES[enemy.kind].weight))
		grids[enemy.kind] = grid
	var route: Array[Vector2i] = grids[enemy.kind].get_id_path(enemy.cell, hall.origin + Vector2i(1, 1))
	return route[1] if route.size() > 1 else enemy.cell
