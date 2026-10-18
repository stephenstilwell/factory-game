extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	if not ok:
		failures += 1
		push_error(label)
func settle() -> void:
	for i in range(6): await process_frame
	await RenderingServer.frame_post_draw
func run() -> void:
	var world = preload("res://tests/fixtures.gd").industrial()
	var node = preload("res://scripts/view/terrain_surface.gd").new()
	node.terrain = world.terrain
	node.frontier = world.frontier
	node.chunk = Vector2i(0,1)
	root.add_child(node)
	await settle()
	check(node.surface.get_texture().get_width() == 768,"Terrain surface bakes the complete chunk at its native resolution")
	var before: Image = node.surface.get_texture().get_image()
	var cell := Vector2i(14,16)
	check(not world.terrain.tile(cell).is_empty(),"Native terrain refresh uses a real ore deposit")
	world.terrain.depleted[cell] = 0
	node.renderer.queue_redraw()
	await settle()
	check(node.surface.get_texture().get_image().get_data() == before.get_data(),"Terrain texture stays cached until explicitly invalidated")
	node.refresh()
	await settle()
	var after: Image = node.surface.get_texture().get_image()
	var changes := 0
	for x in range(14*48,15*48):
		for y in range(48):
			if before.get_pixel(x,y) != after.get_pixel(x,y): changes += 1
	check(changes > 50,"Depleted ore changes the actual baked terrain pixels")
	world.terrain.depleted.erase(cell)
	node.renderer.queue_redraw()
	await settle()
	check(node.surface.get_texture().get_image().get_data() == after.get_data(),"Refreshed terrain returns to cached rendering")
	check(node.sprite.use_parent_material and node.use_parent_material,"Baked terrain participates in the shared world light field")
	print("Native terrain baking: %d failures; ore pixels changed: %d" % [failures,changes])
	quit(1 if failures else 0)
