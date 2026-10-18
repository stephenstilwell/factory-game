extends Node2D
## Bake immutable terrain commands once; redraw only when a deposit chunk changes.
const TerrainArt = preload("res://scripts/view/terrain_chunk.gd")
const PIXELS := 768
var terrain: RefCounted
var frontier: RefCounted
var chunk := Vector2i.ZERO
var surface: SubViewport
var renderer: Node2D
var sprite: Sprite2D
func _ready() -> void:
	use_parent_material = true
	surface = SubViewport.new()
	surface.size = Vector2i(PIXELS,PIXELS)
	surface.disable_3d = true
	surface.transparent_bg = true
	surface.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(surface)
	renderer = TerrainArt.new()
	renderer.terrain = terrain
	renderer.frontier = frontier
	renderer.chunk = chunk
	surface.add_child(renderer)
	sprite = Sprite2D.new()
	sprite.centered = false
	sprite.texture = surface.get_texture()
	sprite.use_parent_material = true
	add_child(sprite)
func refresh() -> void:
	renderer.queue_redraw()
	surface.render_target_update_mode = SubViewport.UPDATE_ONCE
