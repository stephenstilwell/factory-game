extends SceneTree
const World = preload("res://scripts/simulation/world.gd")
const Saves = preload("res://scripts/persistence/save_service.gd")
var checks := 0
var failures := 0
func check(ok: bool, title: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(title)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1100, 720)
	var world := World.new()
	world.start()
	world.exploration.reveal(world.player_position)
	check(world.exploration.known(world.player_position), "Player is charted")
	check(not world.exploration.known(Vector2(500, 500)), "Distant land stays hidden")
	var count: int = world.exploration.cells.size()
	world.exploration.reveal(world.player_position)
	check(world.exploration.cells.size() == count, "Stationary reveal is idempotent")
	world.exploration.reveal(Vector2(-33, -33))
	check(world.exploration.known(Vector2(-33, -33)), "Negative coordinates reveal correctly")
	var encoded := Saves.encode(world)
	var loaded := Saves.decode(encoded)
	check(loaded.error.is_empty(), "Exploration save loads")
	if loaded.error.is_empty(): check(loaded.world.exploration.serialize() == world.exploration.serialize(), "Chart survives round trip")
	encoded.erase("exploration")
	check(Saves.decode(encoded).error.is_empty(), "Old saves remain compatible")
	for bad in [null, {}, [[1]], [["x", 0]], [[0.5, 0]], [[999999999, 0]]]:
		check(not world.exploration.restore(bad), "Reject malformed chart")
	var panel := preload("res://scripts/ui/resource_survey.gd").new()
	root.add_child(panel)
	panel.open(world)
	await process_frame
	await process_frame
	check(panel.visible and panel.tabs.current_tab == 0, "M panel opens to chart")
	check(panel.tabs.get_tab_count() == 2, "Resource survey remains available")
	if "--capture" in OS.get_cmdline_user_args():
		await create_timer(1.0).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/map-preview.png")
	print("Map verification: %d checks, %d failures" % [checks, failures])
	panel.queue_free()
	quit(1 if failures else 0)
