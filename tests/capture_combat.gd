extends SceneTree
const Fixtures = preload("res://tests/fixtures.gd")
const Simulation = preload("res://scripts/simulation/simulation.gd")
func _initialize() -> void:
	call_deferred("_capture")
func shot(name: String) -> void:
	await create_timer(0.2).timeout
	for i in range(3): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/verification/" + name + ".png")
func _capture() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 800)
	var world := Fixtures.combat_town()
	world.defense.cleared = 2
	world.defense.phase = "active"
	world.player_position = Vector2(52.5, 15.5)
	world.previous_position = world.player_position
	world.combat.armed = true
	world.combat.aim = Vector2(57.5, 15.5)
	world.combat.health = 72
	world.defense.spawn_enemy("scout", Vector2i(58, 9))
	world.defense.spawn_enemy("scout", Vector2i(57, 14))
	world.defense.spawn_enemy("dismantler", Vector2i(56, 13))
	world.defense.spawn_enemy("hauler", Vector2i(58, 17))
	var attacker: Dictionary = world.defense.spawn_enemy("dismantler", Vector2i(54, 15))
	attacker.attack_ticks = 3
	attacker.attack_player = true
	attacker.attack_cell = Vector2i(53, 15)
	world.defense.add_shot(world, Vector2(50.5, 13.5), Vector2(56.5, 13.5), "cannon_turret")
	scene._bind_world(world)
	scene.set_process(false)
	scene.paused = true
	scene.view.paused = true
	scene.view.pointer_in_world = true
	scene.camera.position = Vector2(53.5, 13) * 48
	scene.camera.zoom = Vector2.ONE * 0.85
	scene.view.animation_time = 3
	scene.view.selected = Vector2i(50, 13)
	await shot("combat_field")
	scene._inspect_site("town_hall")
	await shot("combat_town_briefing")
	scene.hud.close_workspace()
	scene._inspect(Vector2i(50, 13))
	await shot("combat_cannon")
	root.size = Vector2i(1100, 720)
	await shot("combat_small")
	quit()
