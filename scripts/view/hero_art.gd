extends RefCounted
## Fixed, authored 2x SVG atlases. Pivots are logical world pixels, independent of collision.
const ATLASES := {
	"furnace":{"texture":preload("res://assets/art/hero/furnace.svg"),"size":Vector2(64,112),"pivot":Vector2(32,84),"frames":6},
	"tree":{"texture":preload("res://assets/art/hero/tree.svg"),"size":Vector2(96,112),"pivot":Vector2(48,96),"frames":4},
	"player":{"texture":preload("res://assets/art/hero/player.svg"),"size":Vector2(32,44),"pivot":Vector2(16,29),"frames":4},
	"town_hall":{"texture":preload("res://assets/art/hero/town_hall.svg"),"size":Vector2(160,176),"pivot":Vector2(8,24),"frames":5}
}
static var surfaces: Dictionary = {}
static func surface(id: String) -> Texture2D:
	if id not in ["furnace","town_hall"]: return ATLASES[id].texture
	if not surfaces.has(id):
		var canvas := CanvasTexture.new()
		canvas.diffuse_texture = ATLASES[id].texture
		canvas.normal_texture = load("res://assets/art/hero/"+id+"_normal.svg")
		canvas.specular_texture = load("res://assets/art/hero/"+id+"_specular.svg")
		surfaces[id] = canvas
	return surfaces[id]
static func source(id: String, frame: int) -> Rect2:
	var entry: Dictionary = ATLASES[id]
	var texture: Texture2D = entry.texture
	var width := texture.get_width()/float(entry.frames)
	return Rect2(Vector2(clampi(frame,0,int(entry.frames)-1)*width,0),Vector2(width,texture.get_height()))
static func paint(canvas: CanvasItem, id: String, frame: int, at: Vector2, scale: float = 1.0, tint: Color = Color.WHITE) -> void:
	var entry: Dictionary = ATLASES[id]
	canvas.draw_texture_rect_region(surface(id),Rect2(at-entry.pivot*scale,entry.size*scale),source(id,frame),tint)
static func furnace_frame(healthy: bool, working: bool, time: float, seed_value: int) -> int:
	if not healthy: return 5
	return 1+posmod(floori(time*5)+seed_value,4) if working else 0
static func player_frame(direction: Vector2) -> int:
	if absf(direction.x) > absf(direction.y): return 2 if direction.x > 0 else 3
	return 1 if direction.y < 0 else 0
static func hall_frame(repaired: bool, operational: bool, stone_age: bool) -> int:
	if not repaired: return 0
	return (2 if stone_age else 1)+(0 if operational else 2)
