extends Node2D
## A single reusable radial gradient, culled light sources, and bounded decorative motes.
var world_view: Node2D
var glow: GradientTexture2D

func _ready() -> void:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.25, 0.65, 1.0])
	gradient.colors = PackedColorArray([Color(1, 0.74, 0.37, 0.17), Color(1, 0.69, 0.3, 0.10), Color(1, 0.66, 0.28, 0.035), Color(1, 0.66, 0.28, 0)])
	glow = GradientTexture2D.new()
	glow.gradient = gradient
	glow.width = 128
	glow.height = 128
	glow.fill = GradientTexture2D.FILL_RADIAL
	glow.fill_from = Vector2(0.5, 0.5)
	glow.fill_to = Vector2(1, 0.5)
	var blend := CanvasItemMaterial.new()
	blend.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = blend

func _process(_delta: float) -> void:
	if world_view == null: return
	visible = world_view.ambient_enabled
	if visible: queue_redraw()

func _draw() -> void:
	if world_view == null or world_view.world == null or glow == null: return
	var world: RefCounted = world_view.world
	var area: Rect2i = world_view.visible_cells
	var time: float = 0.0 if world_view.reduced_motion else world_view.animation_time
	# Scan visible cells, not the whole factory, and limit overlapping lights.
	var lights := 0
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			if lights >= 48: break
			var entity = world.at(Vector2i(x, y))
			if entity == null or entity.health <= 0: continue
			if entity.kind == "furnace" and entity.status == "Working":
				_light((Vector2(entity.cell) + Vector2(0.5, 0.7)) * 48, 63 + sin(time * 2.1 + entity.id) * 2)
				lights += 1
	if world.settlements.enabled:
		for site in world.settlements.sites.values():
			if site.repaired and site.health > 0 and area.intersects(site.footprint()):
				var at := Vector2(site.origin) * 48
				_light(at + Vector2(75, 102), 110)
				_light(at + Vector2(28, 107), 52)
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
				draw_circle(at, 0.9 + i * 0.4, Color(0.95, 0.85, 0.57, 0.13))
				motes += 1

func _light(at: Vector2, radius: float) -> void:
	draw_texture_rect(glow, Rect2(at - Vector2.ONE * radius, Vector2.ONE * radius * 2), false)
