extends SceneTree
const Tests = preload("res://tests/combat_readiness_tests.gd")
func _initialize() -> void: call_deferred("run")
func shot(name: String) -> void:
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/verification/combat_c1_"+name+".png")
func run() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1100,720)
	root.content_scale_size = root.size
	scene.set_process(false)
	scene.hud.story_panel.dismiss_silently()
	scene.paused = true
	var world = preload("res://tests/fixtures.gd").defense_town()
	scene._bind_world(world)
	scene.camera.position = Vector2(world.settlements.sites.town_hall.origin)*48
	scene._inspect_site("town_hall")
	await shot("briefing")
	world = Tests.winner()
	scene._bind_world(world)
	scene._inspect_site("town_hall")
	await shot("after_action")
	world.player_position = Vector2(world.settlements.sites.workshop.port())+Vector2(-0.5,0.5)
	world.previous_position = world.player_position
	world.player.contents = {"ammo":30}
	for id in world.by_kind.turret: world.entities[id].inventory.contents.clear()
	scene.camera.position = Vector2(world.settlements.sites.workshop.origin)*48
	scene._inspect_site("workshop")
	await shot("nell_empty")
	scene.hud.town_panel.nell_stock.pressed.emit()
	await shot("nell_stocked")
	scene.hud.town_panel.nell_rearm.pressed.emit()
	await shot("nell_dispatched")
	scene.hud.close_workspace()
	await shot("specialist")
	world = preload("res://tests/encounter_tests.gd").later(6)
	scene._bind_world(world)
	scene._inspect_site("town_hall")
	await shot("encounter_plan")
	world.defense.begin(world)
	for i in range(150): preload("res://scripts/simulation/simulation.gd").step(world)
	world.defense.enemies.clear()
	while world.defense.pending > 7:
		preload("res://scripts/simulation/simulation.gd").step(world)
		world.defense.enemies.clear()
	scene.hud.refresh()
	await shot("reinforcements")
	print("Combat C1/C2 visual capture complete")
	quit()
