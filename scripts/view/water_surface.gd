extends RefCounted
## Sparse surface highlights follow real water and never animate under causeways.
const LIMIT := 24
static func samples(world: RefCounted, area: Rect2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if not world.frontier.sites.has("marsh"): return result
	var bounds: Rect2i = world.frontier.marsh.bounds(world.frontier.sites.marsh.origin).intersection(area)
	for y in range(bounds.position.y,bounds.end.y):
		for x in range(bounds.position.x,bounds.end.x):
			var cell := Vector2i(x,y)
			if posmod(x*7+y*11,4) != 0 or not world.frontier.marsh.blocked(world.frontier,cell): continue
			result.append(cell)
			if result.size() == LIMIT: return result
	return result
static func draw(canvas: CanvasItem, world: RefCounted, area: Rect2i, time: float) -> void:
	for cell in samples(world,area):
		var phase := fposmod(time*0.18+posmod(cell.x*13+cell.y*7,101)/101.0,1.0)
		var at := (Vector2(cell)+Vector2(0.5,0.6))*48+Vector2(sin(phase*TAU)*3,0)
		var tint := Color(0.72,0.86,0.80,0.10+sin(phase*PI)*0.08)
		canvas.draw_arc(at,10+phase*8,0.15,2.1,10,tint,1.2,true)
		canvas.draw_line(at+Vector2(-12,-7),at+Vector2(6,-7),Color(0.75,0.88,0.83,0.10),1,true)
