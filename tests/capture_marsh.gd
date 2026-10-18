extends SceneTree
const Fixtures = preload("res://tests/fixtures.gd")
var failures := 0
func _initialize() -> void: call_deferred("run")
func shot(label: String) -> void:
	for i in range(10): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/verification/marsh_"+label+".png")
func check(ok: bool,label: String) -> void:
	if not ok:
		failures += 1
		push_error(label)
func run() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1100,720)
	root.content_scale_size = root.size
	scene.set_process(false)
	scene.paused = true
	scene.view.paused = true
	scene.hud.story_panel.dismiss_silently()
	var world := Fixtures.industrial()
	var marsh: RefCounted = world.frontier.marsh
	world.player_position = Vector2(marsh.shore(world.frontier))+Vector2.ONE*0.5
	world.previous_position = world.player_position
	world.player.contents = {"plank":44,"stone":46,"wire":8}
	scene._bind_world(world)
	scene.camera.position = Vector2(world.frontier.sites.marsh.origin+Vector2i(-2,2))*48
	scene.hud.refresh()
	await shot("approach")
	scene.hud.frontier_panel.open_panel(world,"marsh")
	await shot("causeway_menu")
	var panel = scene.hud.frontier_panel
	check(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(panel.get_child(0).get_child(0).get_global_rect()),"Discoveries stays inside minimum window")
	for i in range(4): marsh.build_span(world)
	panel.hide()
	world.player_position = Vector2(world.frontier.port("marsh"))+Vector2.ONE*0.5
	world.previous_position = world.player_position
	world.frontier.claim(world,"marsh")
	scene.hud.frontier_panel.open_panel(world,"marsh")
	await shot("lodge_menu")
	marsh.restore_lodge(world)
	panel.hide()
	scene.hud.refresh()
	scene.view.queue_redraw()
	await shot("restored")
	panel.open_panel(world,"marsh")
	await shot("service_menu")
	check(panel.marsh_text.get_global_rect().end.x <= panel.get_child(0).get_child(0).get_global_rect().end.x,"Marsh text remains bounded")
	check(panel.marsh_collect.get_global_rect().end.y < panel.get_child(0).get_child(0).get_global_rect().end.y,"Workshop actions are visible without scrolling at minimum window")
	root.size = Vector2i(3840,2160)
	root.content_scale_size = root.size
	await shot("4k_menu")
	check(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(panel.get_child(0).get_child(0).get_global_rect()),"Discoveries stays inside 4K window")
	print("Native marsh presentation: %d failures" % failures)
	quit(1 if failures else 0)
