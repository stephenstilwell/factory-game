extends SceneTree
const Hero = preload("res://scripts/view/hero_art.gd")
const Fixtures = preload("res://tests/fixtures.gd")
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	if not ok:
		failures += 1
		push_error(label)
func settle() -> void:
	for i in range(12): await process_frame
	await RenderingServer.frame_post_draw
func image_region(scene: Node,cell: Vector2i) -> Image:
	var at: Vector2 = scene.view.get_global_transform_with_canvas()*((Vector2(cell)+Vector2.ONE*0.5)*48)
	return root.get_texture().get_image().get_region(Rect2i(Vector2i(at)-Vector2i(32,84),Vector2i(64,112)))
func save_shot(label: String) -> void:
	root.get_texture().get_image().save_png("res://.godot/verification/g2_"+label+".png")
func run() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280,800)
	root.content_scale_size = root.size
	scene.set_process(false)
	scene.paused = true
	scene.view.paused = true
	scene.hud.story_panel.dismiss_silently()
	var world := Fixtures.industrial()
	var cell := Vector2i(20,18)
	var furnace = world.spawn("furnace",cell,0)
	world.player_position = Vector2(17.5,18.5)
	world.previous_position = world.player_position
	scene._bind_world(world)
	scene.camera.position = (Vector2(cell)+Vector2.ONE*0.5)*48
	await settle()
	var idle := image_region(scene,cell)
	furnace.status = "Working"
	await settle()
	var working := image_region(scene,cell)
	await settle()
	var paused := image_region(scene,cell)
	check(idle.get_data() != working.get_data(),"Actual world furnace changes from idle to working artwork")
	check(working.get_data() == paused.get_data(),"Paused furnace flame and smoke pixels remain stable")
	furnace.health = 0
	await settle()
	check(image_region(scene,cell).get_data() != working.get_data(),"Disabled furnace uses distinct cold/damaged artwork")
	var town := Fixtures.defense_town(false)
	scene._bind_world(town)
	scene.camera.position = Vector2(34,16)*48
	await settle()
	save_shot("street")
	var original_zoom: Vector2 = scene.camera.zoom
	scene.camera.zoom = original_zoom*0.65
	await settle()
	save_shot("street_zoomed_out")
	scene.camera.zoom = original_zoom
	var hall = town.settlements.sites.town_hall
	scene.camera.position = Vector2(hall.origin+Vector2i(1,1))*48
	await settle()
	save_shot("hall_restored")
	hall.health = 0
	await settle()
	save_shot("hall_disabled")
	hall.repaired = false
	await settle()
	save_shot("hall_ruin")
	var woodland := Fixtures.industrial()
	scene._bind_world(woodland)
	var center: Vector2i = woodland.frontier.sites.orchard.origin+Vector2i(2,2)
	woodland.player_position = Vector2(center)+Vector2(-4,2)
	woodland.previous_position = woodland.player_position
	scene.camera.position = Vector2(center)*48
	await settle()
	save_shot("trees_player")
	print("Native hero pilot: %d failures" % failures)
	quit(1 if failures else 0)
