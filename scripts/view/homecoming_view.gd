extends RefCounted
## Decorative public fair; no collision, income or simulated residents.
static func draw(canvas: Node2D, site: RefCounted, stage: int) -> void:
	if not site.repaired or stage == 0: return
	var p := Vector2(site.origin)*48
	if stage >= 2:
		for x in [-10,154]:
			var at := p+Vector2(x,131)
			canvas.draw_line(at,at+Vector2(0,-35),Color("475459"),3,true)
			canvas.draw_circle(at+Vector2(0,-35),11,Color(1,0.82,0.45,0.1))
			canvas.draw_rect(Rect2(at+Vector2(-4,-40),Vector2(8,11)),Color("efd397"))
	if stage < 3: return
	var start := p+Vector2(-12,47)
	canvas.draw_line(start,start+Vector2(170,0),Color("a7b6a3"),1.5,true)
	for index in range(10):
		var at := start+Vector2(index*17,0)
		canvas.draw_colored_polygon(PackedVector2Array([at,at+Vector2(12,0),at+Vector2(6,13)]),Color("cc9d6d") if index%2==0 else Color("6b9c8b"))
	for x in [22,105]:
		var at := p+Vector2(x,152)
		canvas.draw_rect(Rect2(at,Vector2(27,8)),Color("866952"))
		for offset in [4,22]: canvas.draw_line(at+Vector2(offset,8),at+Vector2(offset,14),Color("536858"),2,true)
		for offset in [5,13,21]: canvas.draw_circle(at+Vector2(offset,-2),3,Color("cc9259"))

	if site.id == "town_hall":
		for index in range(3): preload("res://scripts/view/npc_art.gd").person(canvas,p+Vector2(28+index*38,176),"visitor",0.0,0.6)
