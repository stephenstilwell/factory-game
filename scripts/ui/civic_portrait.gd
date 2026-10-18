extends RefCounted
## Dedicated civic portraits, independent of world geometry and simulation.
static func paint(c: CanvasItem, id: String, restored: bool) -> void:
	var ink := Color("29383d")
	var stone := Color("7b8d8c") if restored else Color("596766")
	var wall := Color("b7c2b0") if restored else Color("6d7972")
	var roof := Color("497b75") if restored else Color("4a5756")
	var trim := Color("dda86e") if restored else Color("8e7e65")
	var glass := Color("ffe1a0") if restored else Color("334346")
	c.draw_circle(Vector2(0,-5),68,Color(0.7,0.85,0.7,0.035))
	c.draw_colored_polygon(PackedVector2Array([Vector2(-69,48),Vector2(-12,60),Vector2(69,43),Vector2(18,31)]),Color(0.02,0.03,0.04,0.4))
	c.draw_colored_polygon(PackedVector2Array([Vector2(-68,42),Vector2(0,53),Vector2(67,40),Vector2(8,29)]),ink)
	c.draw_rect(Rect2(-48,-11,96,54),stone)
	c.draw_rect(Rect2(-43,-16,86,49),wall)
	c.draw_colored_polygon(PackedVector2Array([Vector2(43,-16),Vector2(54,-6),Vector2(54,39),Vector2(43,43)]),wall.darkened(0.28))
	for y in [23,33]:
		c.draw_line(Vector2(-47,y),Vector2(46,y),stone.darkened(0.2),1,true)
	c.draw_colored_polygon(PackedVector2Array([Vector2(-57,-15),Vector2(-4,-52),Vector2(55,-16)]),roof)
	c.draw_line(Vector2(-57,-15),Vector2(-4,-52),trim,3,true)
	c.draw_line(Vector2(-4,-52),Vector2(55,-16),trim,3,true)
	for y in [-29,-21]:
		c.draw_line(Vector2(-29-(y+29),y),Vector2(27+(y+29),y),roof.lightened(0.15),1,true)
	c.draw_rect(Rect2(-10,8,20,35),ink)
	c.draw_rect(Rect2(-6,12,12,29),trim.darkened(0.3))
	c.draw_circle(Vector2(3,27),1.3,glass)
	for x in [-32,23]:
		if restored: c.draw_circle(Vector2(x+5,2),13,Color(1,0.8,0.4,0.055))
		c.draw_rect(Rect2(x,-7,11,18),ink)
		c.draw_rect(Rect2(x+2,-5,7,13),glass)
		c.draw_line(Vector2(x,2),Vector2(x+11,2),trim,1,true)
		c.draw_line(Vector2(x-2,13),Vector2(x+13,13),trim,3,true)
	if id == "trading_post":
		c.draw_rect(Rect2(-43,13,32,7),trim)
		for x in range(-43,-12,8):
			c.draw_colored_polygon(PackedVector2Array([Vector2(x,13),Vector2(x+8,13),Vector2(x+11,23),Vector2(x+3,23)]),roof if x % 16 == 5 else wall)
		for x in [-40,-15]: c.draw_line(Vector2(x,23),Vector2(x,42),trim,2,true)
		c.draw_rect(Rect2(-41,32,24,9),trim.darkened(0.2))
		for x in [-36,-27,-20]: c.draw_circle(Vector2(x,31),3,Color("b78155") if restored else stone)
		c.draw_line(Vector2(29,-32),Vector2(44,-32),trim,2,true)
		c.draw_rect(Rect2(36,-30,15,12),trim)
		c.draw_arc(Vector2(43,-24),4,0,TAU,12,ink,1,true)
	elif id == "workshop":
		c.draw_rect(Rect2(25,-54,13,24),stone.darkened(0.2))
		c.draw_rect(Rect2(22,-57,19,6),trim)
		c.draw_rect(Rect2(-31,18,19,17),ink)
		c.draw_circle(Vector2(-21,26),6,trim)
		c.draw_circle(Vector2(-21,26),2,ink)
		for angle in range(8):
			var direction := Vector2.from_angle(angle*TAU/8.0)
			c.draw_line(Vector2(-21,26)+direction*5,Vector2(-21,26)+direction*9,trim,3,true)
		c.draw_line(Vector2(18,28),Vector2(40,28),trim,3,true)
		for x in [21,37]: c.draw_line(Vector2(x,29),Vector2(x,42),ink,2,true)
	else:
		c.draw_rect(Rect2(-15,-60,30,43),stone)
		c.draw_colored_polygon(PackedVector2Array([Vector2(-23,-60),Vector2(0,-78),Vector2(23,-60)]),roof)
		c.draw_rect(Rect2(-8,-51,16,20),ink)
		if restored: c.draw_circle(Vector2(0,-41),18,Color(1,0.8,0.4,0.07))
		c.draw_circle(Vector2(0,-41),5,glass)
		c.draw_line(Vector2(0,-51),Vector2(0,-32),trim,2,true)
		for y in [39,44,49]: c.draw_rect(Rect2(-18,y,36,3),stone.lightened(0.15))
	if restored:
		for x in [-57,55]:
			c.draw_line(Vector2(x,38),Vector2(x,27),Color("789979"),2,true)
			c.draw_circle(Vector2(x-3,29),4,Color("789979"))
			c.draw_circle(Vector2(x+3,25),5,Color("91b18b"))
		c.draw_line(Vector2(12,44),Vector2(35,49),trim.darkened(0.1),2,true)
	else:
		for x in [-28,21]:
			c.draw_line(Vector2(x,-3),Vector2(x+10,9),trim.darkened(0.2),4,true)
		c.draw_polyline(PackedVector2Array([Vector2(28,14),Vector2(21,21),Vector2(26,27),Vector2(18,35)]),ink,2,true)
		for x in [-52,42,58]: c.draw_rect(Rect2(x,42,9,5),stone)
