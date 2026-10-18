extends RefCounted
const Fixtures = preload("res://tests/fixtures.gd")
const Simulation = preload("res://scripts/simulation/simulation.gd")
const Report = preload("res://scripts/ui/machine_report.gd")
static func ui(test: SceneTree) -> void:
	var scene = load("res://main.tscn").instantiate()
	test.root.add_child(scene)
	await test.process_frame
	scene.set_process(false)
	scene.hud.story_panel.dismiss_silently()
	var world := Fixtures.industrial()
	world.player_position = Vector2(22.5,22.5)
	world.previous_position = world.player_position
	world.player.contents = {"iron_ore":8,"coal":5}
	var furnace = world.spawn("furnace",Vector2i(23,22),0)
	scene._bind_world(world)
	Simulation.step(world)
	scene._inspect(furnace.cell)
	var panel = scene.hud.workspace.machine
	test.check(panel.status_label.text == "Waiting for ingredients" and panel.blocker_hint.text.contains("Iron ore"),"Machine blocker names the real missing ingredients")
	test.check(panel.flow.visible and panel.flow_input.text.contains("Iron ore") and panel.flow_output.text.contains("Iron plate"),"Production diagram explains the selected recipe")
	var before: Dictionary = furnace.serialize()
	Report.inspect(world,furnace)
	test.check(furnace.serialize() == before,"Inspecting production cannot consume items or advance work")
	panel.resolve_button.pressed.emit()
	test.check(furnace.inventory.count("iron_ore") > 0 and world.player.count("iron_ore") < 8,"Suggested loading action transfers actual pack supplies")
	furnace.inventory.contents = {"iron_ore":2}
	world.player.add("coal",5)
	Simulation.step(world)
	scene.hud.refresh()
	test.check(panel.status_label.text == "Waiting for fuel" and panel.blocker_hint.text.contains("fuel depot"),"Fuel starvation explains the automation alternative")
	panel.resolve_button.pressed.emit()
	Simulation.step(world)
	scene.hud.refresh()
	test.check(panel.status_label.text == "Working" and not panel.resolve_button.visible and furnace.burn_ticks > 0,"Loading fuel resumes real simulation work and removes the obsolete action")
	furnace.output.contents = {"iron_plate":furnace.output.capacity}
	Simulation.step(world)
	scene.hud.refresh()
	test.check(panel.status_label.text == "Output blocked" and panel.resolve_action == "collect","Full output offers collection rather than more fuel")
	panel.resolve_button.pressed.emit()
	test.check(furnace.output.total() == 0 and world.player.count("iron_plate") > 0,"Output remedy collects real output through the existing command")
	furnace.health = 0
	scene.hud.refresh()
	test.check(panel.status_label.text == "Building disabled" and panel.resolve_button.disabled,"Damage takes priority and a missing repair kit disables the remedy")
	world.player.add("repair_kit")
	scene.hud.refresh()
	panel.resolve_button.pressed.emit()
	test.check(furnace.health > 0 and world.player.count("repair_kit") == 0,"Repair remedy consumes a kit and restores actual health")
	furnace.electric_mode = true
	world.power.revision = -1
	Simulation.step(world)
	scene.hud.refresh()
	test.check(panel.status_label.text == "Waiting for district power" and not panel.resolve_button.visible and panel.flow_process.text.contains("1.6s"),"Disconnected electric machines explain poles and show upgraded batch time")
	world.player_position = Vector2(70,70)
	furnace.electric_mode = false
	furnace.inventory.contents = {}
	Simulation.step(world)
	scene.hud.refresh()
	test.check(panel.resolve_button.disabled and panel.resolve_button.tooltip_text.contains("closer"),"Production remedy respects build reach")
	world.player_position = Vector2(22.5,22.5)
	var lab = world.spawn("lab",Vector2i(22,23),0)
	world.research_target = ""
	Simulation.step(world)
	scene._inspect(lab.cell)
	test.check(panel.resolve_action == "technology" and panel.input_grid.buttons.has("science"),"Idle drafting bench offers technology navigation and an empty dossier loading slot")
	panel.resolve_button.pressed.emit()
	test.check(scene.hud.factory_panel.visible and not scene.hud.workspace.visible,"Drafting bench remedy opens Technology and closes machine inspection")
	scene.queue_free()
	await test.process_frame


