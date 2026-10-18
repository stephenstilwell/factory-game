extends SceneTree
const Fixtures = preload("res://tests/fixtures.gd")
const Simulation = preload("res://scripts/simulation/simulation.gd")
const World = preload("res://scripts/simulation/world.gd")
var prefix := "ui_review"
func _initialize() -> void: call_deferred("run")
func shot(label: String) -> void:
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/verification/" + prefix + "_" + label + ".png")
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--prefix="): prefix = arg.trim_prefix("--prefix=")
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1100, 720) if "--small" in OS.get_cmdline_user_args() else Vector2i(1280, 800)
	root.content_scale_size = root.size
	scene.set_process(false)
	scene.hud.story_panel.dismiss_silently()
	scene.paused = true
	scene.view.paused = true
	var world := World.new(1063638934)
	world.start()
	world.player_position = Vector2(22.5, 11.5)
	world.previous_position = world.player_position
	world.player.contents = {"timber": 42, "stone": 18, "lumber_camp": 1, "cart_post": 1, "berries": 8}
	world.production.timber = 42
	scene._bind_world(world)
	scene.camera.position = world.player_position * 48
	scene.hud.hotbar.timber_layout = preload("res://scripts/ui/hotbar_layout.gd").new("", ["lumber_camp", "cart_post", "communal_hearth", "watermill", "charcoal_kiln"])
	scene.hud.refresh()
	await shot("field")
	scene.hud.toggle_crafting()
	scene.hud.crafting.select_recipe("lumber_camp")
	await shot("craft")
	scene.hud.crafting.craft_one.pressed.emit()
	for tick in range(10): Simulation.step(world)
	scene.hud.refresh()
	await shot("craft_queue")
	for tick in range(60): Simulation.step(world)
	scene.hud.refresh()
	await shot("craft_complete")
	scene.hud.close_workspace()
	world.build("lumber_camp", Vector2i(18, 9), 0)
	scene._inspect(Vector2i(18, 9))
	await shot("camp")
	scene.hud.close_workspace()
	scene._bind_world(Fixtures.demo())
	scene.world.player_position = Vector2(19.5,17.5)
	scene.world.previous_position = scene.world.player_position
	Simulation.step(scene.world)
	scene._inspect(Vector2i(19,15))
	await shot("machine")
	scene.hud.close_workspace()
	scene.hud.toggle_inventory()
	await shot("inventory")
	scene._open_factory("research")
	await shot("technology")
	scene.hud.factory_panel.research_panel.select("construction")
	await shot("technology_locked")
	scene.hud.factory_panel.close_panel()
	scene._bind_world(Fixtures.trading_town())
	scene.hud.toggle_town()
	await shot("town_overview")
	scene._inspect_site("workshop")
	await shot("restoration")
	scene.hud.close_workspace()
	scene.hud.toggle_character()
	scene.hud.workspace.character_panel.show_section("equipment")
	await shot("equipment")
	scene.hud.close_workspace()
	scene.world.player.add("timber")
	scene.world.craft("plank")
	for tick in range(20): Simulation.step(scene.world)
	var bench = scene.world.spawn("lab",Vector2i(20,20),0)
	bench.inventory.contents = {"science":1}
	bench.progress = 29
	scene.world.research_progress = 9
	Simulation.step(scene.world)
	await shot("milestone")
	scene.hud.completion.clear()
	scene.hud.workspace.reward_card.clear()
	scene._open_history()
	await shot("updates")
	print("UI review captured: ", prefix)
	quit()
