extends SceneTree
## Native regression: craft prerequisites, real hotbar click, placement and harvesting.
const World = preload("res://scripts/simulation/world.gd")
const Simulation = preload("res://scripts/simulation/simulation.gd")
var failures := 0

func _initialize() -> void: call_deferred("run")

func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error(label)

func click(at: Vector2, button: int = MOUSE_BUTTON_LEFT, hold: float = 0.0) -> void:
	# Viewport coordinates differ from OS pixels when window stretching is active.
	root.warp_mouse(at)
	await process_frame
	var event := InputEventMouseButton.new()
	event.position = at
	event.button_index = button
	event.pressed = true
	root.push_input(event, true)
	if hold > 0: await create_timer(hold).timeout
	else: await process_frame
	event = event.duplicate()
	event.pressed = false
	root.push_input(event, true)
	await process_frame

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Placement smoke requires a native window to exercise rendering and GUI input.")
		quit(1)
		return
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1100, 720)
	root.content_scale_size = Vector2i(1100, 720)
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	# Scene display preferences are applied in _ready; configure the test afterward.
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1100, 720)
	root.content_scale_size = Vector2i(1100, 720)
	root.position = Vector2i(100, 100)
	scene.hud.story_panel.dismiss_silently()
	# Isolated shortcuts in memory; never replace the playtester's preferences.
	scene.hud.hotbar.timber_layout = preload("res://scripts/ui/hotbar_layout.gd").new("", ["lumber_camp", "cart_post"])
	for seed_value in [0, 1, 74103, 12345, -2000000000, 2000000000]:
		var world := World.new(seed_value)
		world.start()
		world.player.contents = {"timber": 8, "stone": 2}
		world.production.timber = 8
		check(world.craft("lumber_camp"), "Camp queues its missing axe")
		for i in range(60): Simulation.step(world)
		check(world.player.count("lumber_camp") == 1 and world.craft_queue.is_empty(), "Prerequisite crafting completes")
		scene._bind_world(world)
		scene.hud.story_panel.dismiss_silently()
		scene.paused = false
		scene.camera.position = world.player_position * 48
		await create_timer(0.25).timeout
		var slot: Button = scene.hud.hotbar.slots[0]
		await click(slot.get_global_rect().get_center())
		check(scene.selected_kind == "lumber_camp", "Real hotbar click selects the camp")
		var cell := Vector2i(23, 15)
		var screen: Vector2 = scene.get_viewport().get_canvas_transform() * ((Vector2(cell) + Vector2.ONE * 0.5) * 48)
		await click(screen)
		check(world.at(cell) != null and world.player.count("lumber_camp") == 0, "Real world click places the camp once")
		check(world.early.objective(world).title.contains("First logistics"), "Placement advances the visible opening objective")
		for i in range(80): Simulation.step(world)
		await create_timer(0.2).timeout
		# Keep the build tool selected: this is the reported crash interaction.
		await click(screen)
		check(scene.hud.workspace.visible and scene.hud.workspace.entity_id == world.at(cell).id, "Real click opens the placed camp inspector")
		scene.hud.close_workspace()
		await process_frame
		var timber: int = world.at(cell).output.count('timber')
		await click(screen, MOUSE_BUTTON_RIGHT, 0.8)
		check(world.at(cell) == null and world.player.count('lumber_camp') == 1 and world.player.count('timber') == timber, 'Right hold reclaims the selected camp and its timber')
		print("Native camp placement checked seed ", seed_value)
	print("Native placement smoke: ", failures, " failures; renderer ", RenderingServer.get_current_rendering_method())
	quit(failures)
