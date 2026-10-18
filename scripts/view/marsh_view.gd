extends RefCounted
const Art = preload("res://scripts/view/art.gd")
const TILE := 48
static func draw(canvas: Node2D, world: RefCounted, visible: Rect2i, time: float) -> void:
	if not world.frontier.sites.has("marsh"): return
	var marsh: RefCounted = world.frontier.marsh
	var origin: Vector2i = world.frontier.sites.marsh.origin
	var area: Rect2i = marsh.bounds(origin).intersection(visible)
	for x in range(area.position.x,area.end.x):
		for y in range(area.position.y,area.end.y):
			var cell := Vector2i(x,y)
			var offset := cell-origin
			var p := Vector2(cell)*TILE
			if marsh.boardwalk(world.frontier,cell):
				Art.box(canvas,Rect2(p+Vector2(0,4),Vector2(48,40)),Color("66533e"),1)
				for board in range(5):
					canvas.draw_line(p+Vector2(2,7+board*8),p+Vector2(46,7+board*8),Color("b79d70"),6)
				for side in [5,43]:
					canvas.draw_circle(p+Vector2(side,8),2,Art.STEEL)
					canvas.draw_circle(p+Vector2(side,39),2,Art.STEEL)
			elif offset.y == 2 and offset.x >= -6 and offset.x < -2:
				for corner in [Vector2(8,10),Vector2(38,38)]:
					canvas.draw_circle(p+corner,4,Color("9c9169"))
				if offset.x == -6+marsh.sections:
					canvas.draw_rect(Rect2(p+Vector2(4,7),Vector2(40,34)),Color("dfbf7d"),false,1.5)
			elif marsh.water_at(world.frontier,cell) and (x*7+y*13)%4 == 0:
				var sway := sin(time*0.7+x)*2
				for reed in range(3):
					var at := p+Vector2(13+reed*9,35)
					canvas.draw_line(at,at+Vector2(sway-3,-18-reed*3),Color("8caa82"),2,true)
					canvas.draw_line(at+Vector2(sway-3,-18-reed*3),at+Vector2(sway-3,-24-reed*3),Color("b7ac75"),3,true)
			elif not marsh.water_at(world.frontier,cell) and world.at(cell) == null and world.frontier.at(cell) == "" and (x*11+y*7)%13 == 0:
				Art.ellipse(canvas,p+Vector2(24,30),Vector2(15,4),Color("759583"))
	var bank: Vector2i = marsh.shore(world.frontier)
	if visible.has_point(bank):
		var p := (Vector2(bank)+Vector2(0.5,0.1))*TILE
		canvas.draw_line(p,p+Vector2(0,-28),Art.COPPER,3)
		Art.box(canvas,Rect2(p+Vector2(-20,-37),Vector2(40,18)),Color("b1a47a"),2)
		canvas.draw_string(ThemeDB.fallback_font,p+Vector2(-14,-24),"L →",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Art.INK)
static func lodge(canvas: Node2D, world: RefCounted, p: Vector2, time: float) -> void:
	var restored: bool = world.frontier.marsh.restored
	for x in [25,205]:
		canvas.draw_line(p+Vector2(x,75),p+Vector2(x,170),Color("695640"),8)
	Art.box(canvas,Rect2(p+Vector2(22,55),Vector2(191,100)),Color("8d9b86") if restored else Color("687c70"),4)
	for row in range(5):
		canvas.draw_line(p+Vector2(28,65+row*18),p+Vector2(208,65+row*18),Color("536c60"),2)
	canvas.draw_colored_polygon(PackedVector2Array([p+Vector2(8,60),p+Vector2(85,12),p+Vector2(166,12),p+Vector2(230,60)]),Color("42656a") if restored else Color("465b5c"))
	for x in [48,159]:
		Art.box(canvas,Rect2(p+Vector2(x,79),Vector2(30,31)),Color("e2ce91") if restored else Art.INK,2)
	Art.box(canvas,Rect2(p+Vector2(101,94),Vector2(37,61)),Color("574a3c"),2)
	canvas.draw_line(p+Vector2(13,162),p+Vector2(225,162),Color("b5a57a"),6)
	if restored:
		var keeper := p+Vector2(167+sin(time*0.4)*3,148)
		Art.ellipse(canvas,keeper,Vector2(7,10),Color("9aafae"))
		canvas.draw_circle(keeper+Vector2(0,-12),5,Color("d5b994"))
		Art.box(canvas,Rect2(p+Vector2(23,132),Vector2(35,23)),Color("bda875"),2)
		canvas.draw_line(p+Vector2(35,135),p+Vector2(45,147),Art.STEEL,4)
