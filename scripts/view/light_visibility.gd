extends RefCounted
## Small CPU visibility atlas. Only solid defense walls and repaired civic footprints block.
const SIZE := 16
const LIMIT := 12
static func blockers(world: RefCounted, area: Rect2i) -> Array[Rect2]:
	var result: Array[Rect2] = []
	for y in range(area.position.y-4,area.end.y+4):
		for x in range(area.position.x-4,area.end.x+4):
			var entity = world.at(Vector2i(x,y))
			if entity != null and entity.kind in ["wall", "reinforced_wall"] and entity.health > 0:
				result.append(Rect2(Vector2(x,y)*48+Vector2(7,7),Vector2(34,34)))
	if world.settlements.enabled:
		for site in world.settlements.sites.values():
			if site.repaired and site.health > 0 and area.grow(4).intersects(site.footprint()):
				result.append(Rect2(Vector2(site.footprint().position)*48,Vector2(site.footprint().size)*48).grow(-8))
	return result
static func visible(from: Vector2, to: Vector2, shapes: Array[Rect2]) -> bool:
	for shape in shapes:
		# A window illuminates its own building; never trap a source inside itself.
		if shape.has_point(from): continue
		if shape.has_point(to) or Geometry2D.segment_intersects_segment(from,to,shape.position,Vector2(shape.end.x,shape.position.y)) != null or Geometry2D.segment_intersects_segment(from,to,Vector2(shape.end.x,shape.position.y),shape.end) != null or Geometry2D.segment_intersects_segment(from,to,shape.end,Vector2(shape.position.x,shape.end.y)) != null or Geometry2D.segment_intersects_segment(from,to,Vector2(shape.position.x,shape.end.y),shape.position) != null:
			return false
	return true
static func bake(sources: Array, shapes: Array[Rect2]) -> Image:
	var image := Image.create(SIZE*LIMIT,SIZE,false,Image.FORMAT_L8)
	image.fill(Color.WHITE)
	for i in range(sources.size()):
		var source: Dictionary = sources[i]
		var nearby: Array[Rect2] = []
		var bounds := Rect2(source.position-Vector2.ONE*source.radius,Vector2.ONE*source.radius*2)
		for shape in shapes:
			if bounds.intersects(shape) and not shape.has_point(source.position): nearby.append(shape)
		for y in range(SIZE):
			for x in range(SIZE):
				var point: Vector2 = source.position+(Vector2(x+0.5,y+0.5)/SIZE*2-Vector2.ONE)*source.radius
				if not visible(source.position,point,nearby): image.set_pixel(i*SIZE+x,y,Color.BLACK)
	return image
