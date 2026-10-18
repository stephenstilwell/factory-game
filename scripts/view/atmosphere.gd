extends Node2D
## Bounded decorative motes; actual illumination is owned by WorldLighting.
var world_view: Node2D
func _ready() -> void:
	var blend := CanvasItemMaterial.new()
	blend.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	blend.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = blend

func _process(_delta: float) -> void:
	if world_view == null: return
	visible = world_view.ambient_enabled
	if visible: queue_redraw()

func _draw() -> void:
	if world_view == null or world_view.world == null: return
	var world: RefCounted = world_view.world
	var area: Rect2i = world_view.visible_cells
	var time: float = 0.0 if world_view.reduced_motion else world_view.animation_time
	if world_view.reduced_motion: return
	# World-anchored decoration stays continuous when the camera crosses a tile.
	var bounds := Rect2(Vector2(area.position) * 48, Vector2(area.size) * 48)
	var first := Vector2i(floori(area.position.x / 8.0), floori(area.position.y / 8.0))
	var last := Vector2i(ceili(area.end.x / 8.0), ceili(area.end.y / 8.0))
	var motes := 0
	for x in range(first.x - 1, last.x + 1):
		for y in range(first.y - 1, last.y + 1):
			for i in range(2):
				if motes >= 64: return
				var seed_value: int = posmod(x * 7381 + y * 19391 + i * 439 + world.terrain.seed_value, 104729)
				var phase := seed_value / 104729.0 * TAU
				var at := Vector2(x * 384 + posmod(seed_value, 384), y * 384 + posmod(seed_value * 31, 384))
				at += Vector2(sin(time * 0.17 + phase) * 24, cos(time * 0.23 + phase) * 18)
				if not bounds.has_point(at): continue
				var region: int = world.frontier.landscape_index(Vector2i((at/48).floor()))
				if region == 1:
					draw_line(at,at+Vector2(3,1),Color(0.94,0.71,0.76,0.35),2,true)
				elif region == 3:
					draw_line(at,at+Vector2(22,0),Color(0.64,0.79,0.76,0.09),4,true)
				elif region == 2:
					draw_line(at,at+Vector2(11,0),Color(0.76,0.84,0.8,0.09),1,true)
				else: draw_circle(at, 0.9 + i * 0.4, Color(0.95, 0.85, 0.57, 0.13))
				motes += 1
