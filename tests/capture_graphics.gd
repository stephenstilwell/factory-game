extends SceneTree
const Fixtures = preload("res://tests/fixtures.gd")
var prefix := "graphics"
func _initialize() -> void: call_deferred("run")
func shot(scene: Node, label: String) -> void:
	scene.hud.refresh()
	for i in range(10): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/verification/"+prefix+"_"+label+".png")
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--prefix="): prefix = arg.trim_prefix("--prefix=")
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280,800)
	root.content_scale_size = root.size
	scene.set_process(false)
	scene.paused = true
	scene.view.paused = true
	scene.hud.story_panel.dismiss_silently()
	var world := Fixtures.defense_town(false)
	scene._bind_world(world)
	scene.view.ambient_enabled = true
	world.player_position = Vector2(32.5,15.5)
	world.previous_position = world.player_position
	scene.camera.position = Vector2(31,16)*48
	await shot(scene,"town")
	var forest := Fixtures.industrial()
	scene._bind_world(forest)
	var center: Vector2i = forest.frontier.sites.orchard.origin+Vector2i(2,2)
	forest.player_position = Vector2(center)+Vector2(-4,2)
	forest.previous_position = forest.player_position
	scene.camera.position = Vector2(center)*48
	await shot(scene,"orchard")
	var marsh: RefCounted = forest.frontier.marsh
	center = forest.frontier.sites.marsh.origin+Vector2i(-2,2)
	forest.player_position = Vector2(marsh.shore(forest.frontier))+Vector2.ONE*0.5
	forest.previous_position = forest.player_position
	forest.player.contents = {"plank":24,"stone":16}
	for i in range(4): marsh.build_span(forest)
	scene.camera.position = Vector2(center)*48
	await shot(scene,"water")
	print("Graphics captures: ",prefix)
	quit()
