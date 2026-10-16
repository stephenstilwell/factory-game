extends SceneTree
const Fixtures = preload("res://tests/fixtures.gd")
func _initialize() -> void: call_deferred("_capture")
func shot(name: String) -> void:
	await create_timer(0.2).timeout
	for i in range(6): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/verification/" + name + ".png")
func _capture() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	root.mode = Window.MODE_WINDOWED
	DirAccess.make_dir_recursive_absolute("res://.godot/verification")
	var world := Fixtures.combat_town()
	world.player.contents = {"iron_plate": 100, "gear": 60, "copper_plate": 60, "wire": 80, "steel": 70, "construction_kit": 8}
	world.skills.xp = {"mining": 52859, "fabrication": 4425, "exploration": 679}
	world.skills.commissions = {"mine:iron_ore": 190, "line:gear": 34, "line:wire": 7}
	world.settlements.sites.town_hall.shipments = 3
	world.guidance.pin(world, "equipment", "boots", 1)
	world.message.emit("Working supply line: Iron gear • 50 automated batches • +400 Fabrication XP [P]")
	scene._bind_world(world)
	scene.set_process(false)
	scene.paused = true
	scene.view.paused = true
	for viewport_size in [Vector2i(1280, 800), Vector2i(1100, 720)]:
		root.content_scale_size = viewport_size
		root.size = viewport_size
		scene.hud.toggle_character()
		scene.hud.workspace.character_panel.show_section("skills")
		await shot("progression_skills_" + str(viewport_size.x))
		scene.hud.workspace.character_panel.show_section("equipment")
		await shot("progression_equipment_" + str(viewport_size.x))
		scene.hud.close_workspace()
		scene._open_journal()
		await shot("progression_journal_" + str(viewport_size.x))
		scene.hud.story_panel.close_panel()
		await shot("progression_goal_" + str(viewport_size.x))
	quit()
