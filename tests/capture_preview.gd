extends SceneTree
const Fixtures = preload("res://tests/fixtures.gd")
const Simulation = preload("res://scripts/simulation/simulation.gd")
## Optional visual verification. Run with a rendering backend (not --headless).

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 800)
	DirAccess.make_dir_recursive_absolute("res://.godot/verification")
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/verification/overview.png")
	scene.hud.toggle_survey()
	for i in range(4): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/verification/resource_survey.png")
	scene.hud.survey.hide()
	scene.hud.toggle_crafting()
	for i in range(4): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/verification/first_craft.png")
	scene._inspect_site("trading_post")
	for i in range(4): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/verification/trading_post_ruin.png")
	scene._bind_world(Fixtures.demo())
	scene._inspect(Vector2i(19, 15))
	for i in range(4): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/verification/inspector.png")
	scene.hud.toggle_crafting()
	for i in range(4): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/verification/crafting.png")
	scene._toggle_pause()
	scene.world.player.contents.erase("gear")
	scene.hud.crafting.select_recipe("drill")
	scene.hud.refresh()
	for i in range(4): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/verification/missing_components.png")
	scene.world.craft_many("gear", 3)
	for i in range(4): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/verification/craft_queue.png")
	scene._bind_world(Fixtures.demo())
	scene.hud.toggle_character()
	scene.world.award_skill("mining", scene.world.Skills.Definitions.threshold(10) + 200)
	scene.world.award_skill("fabrication", scene.world.Skills.Definitions.threshold(25) + 400)
	scene.world.award_skill("exploration", scene.world.Skills.Definitions.threshold(10) + 10)
	scene.hud.refresh()
	scene.hud.workspace.character_panel.show_section("skills")
	for i in range(4): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/verification/engineer_skills.png")
	scene.hud.workspace.character_panel.show_section("equipment")
	for i in range(4): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/verification/engineer_upgrades.png")
	var town := Fixtures.trading_town()
	for i in range(200): Simulation.step(town)
	scene._bind_world(town)
	scene._inspect_site("trading_post")
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/verification/trading_post_open.png")
	for i in range(2000): Simulation.step(town)
	town.player_position = Vector2(34.5, 20.5)
	town.previous_position = town.player_position
	town.supply_site("workshop")
	town.restore_site("workshop")
	scene._bind_world(town)
	scene._inspect_site("workshop")
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/verification/workshop_restored.png")
	scene.hud.close_workspace()
	scene._open_menu()
	for i in range(4): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/verification/pause_menu.png")
	scene._close_menu()
	var defended := Fixtures.defense_town()
	scene._bind_world(defended)
	scene._inspect_site("town_hall")
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/verification/town_hall.png")
	scene.hud.town_panel.beacon_button.pressed.emit()
	scene.hud.close_workspace()
	scene.camera.position = Vector2(54, 13) * 48
	scene.set_process(false) # Keep the preview camera over the whole approach.
	for i in range(186): Simulation.step(defended)
	for i in range(4): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/verification/defense_wave.png")
	print("Visual previews captured in .godot/verification")
	quit()
