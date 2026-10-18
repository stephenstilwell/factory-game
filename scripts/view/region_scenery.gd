extends RefCounted
## Small deterministic ground ornaments. They are scenery, not resources or obstacles.
const Frontier = preload("res://scripts/model/frontier.gd")
const Art = preload("res://scripts/view/art.gd")
const LIMIT := 32
static func candidates(world: RefCounted, area: Rect2i) -> Array:
	var result: Array = []
	var start := Vector2i(floori(area.position.x/4.0),floori(area.position.y/4.0))
	var finish := Vector2i(ceili(area.end.x/4.0),ceili(area.end.y/4.0))
	for x in range(start.x,finish.x):
		for y in range(start.y,finish.y):
			if result.size() >= LIMIT: return result
			var value: int = Frontier.hash_cell(Vector2i(x,y),world.terrain.seed_value,113)
			var cell := Vector2i(x*4+value%4,y*4+(value/7)%4)
			if not area.has_point(cell): continue
			var region: int = world.frontier.landscape_index(cell)
			if region == 0 or region == 3 or world.frontier.landscape_weight(cell,"orchard" if region == 1 else "quarry") < 0.4: continue
			if world.at(cell) != null or world.settlements.at(cell) != null or world.frontier.cleared.has(cell) or world.frontier.forestry.plots.has(cell): continue
			if world.early.enabled and world.early.water_at(cell): continue
			world.terrain.tile(cell)
			if world.terrain.chunks[world.terrain.chunk_at(cell)].has(cell): continue
			if world.frontier.tree_at(world,cell): continue
			var occupied := false
			for id in world.frontier.sites:
				if world.frontier.footprint(id).grow(2).has_point(cell): occupied = true; break
			if occupied: continue
			result.append({"cell":cell,"region":region,"variant":value%3})
	return result

static func draw(canvas: Node2D, world: RefCounted, area: Rect2i) -> void:
	for record in candidates(world,area):
		var at := (Vector2(record.cell)+Vector2.ONE*0.5)*48
		if record.region == 1:
			var tended: bool = world.orchard_project.beds > 0
			match record.variant:
				0:
					for index in range(5):
						var p := at+Vector2(-14+index*7,index%2*9-4)
						canvas.draw_line(p,p+Vector2(0,-7),Color("77935d"),1.5,true)
						canvas.draw_circle(p+Vector2(0,-8),2.4,Color("e3b6b4") if tended else Color("cbbba0"))
				1:
					for x in [-13,13]: canvas.draw_line(at+Vector2(x,8),at+Vector2(x,-8),Color("a58b61") if tended else Color("716b54"),3,true)
					canvas.draw_line(at+Vector2(-14,-4),at+Vector2(14,0 if not tended else -4),Color("8f7958"),2,true)
				2:
					Art.ellipse(canvas,at+Vector2(0,4),Vector2(18,7),Color("72614c"))
					for row in range(3): canvas.draw_line(at+Vector2(-13,-2+row*4),at+Vector2(13,-2+row*4),Color("8b7856"),1,true)
					if tended:
						for x in [-9,0,9]: canvas.draw_circle(at+Vector2(x,-3),2.5,Color("a8ba75"))
		else:
			for index in range(3):
				var p := at+Vector2(index*10-11,index%2*8)
				canvas.draw_colored_polygon(PackedVector2Array([p+Vector2(-9,0),p+Vector2(-4,-5),p+Vector2(8,-3),p+Vector2(10,3),p+Vector2(-7,5)]),Color("7e908b") if world.settlements.road_deliveries >= 3 else Color("647471"))
				canvas.draw_line(p+Vector2(-5,-2),p+Vector2(7,-3),Color("a2afa2"),1,true)
			if record.variant == 1:
				canvas.draw_line(at+Vector2(-5,-10),at+Vector2(10,8),Color("aa926c"),3,true)
				canvas.draw_line(at+Vector2(-10,-9),at+Vector2(0,-13),Color("b3beb5"),3,true)
