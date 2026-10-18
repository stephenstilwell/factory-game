extends RefCounted
const Fixtures = preload("res://tests/fixtures.gd")
const World = preload("res://scripts/simulation/world.gd")
const Reports = preload("res://scripts/ui/project_reports.gd")
const Sites = preload("res://scripts/data/settlement_catalog.gd")
static func ui(test: SceneTree) -> void:
	var scene = load("res://main.tscn").instantiate()
	test.root.add_child(scene)
	await test.process_frame
	scene.set_process(false)
	scene.hud.story_panel.dismiss_silently()
	var world := World.new(1063638934)
	world.start()
	scene._bind_world(world)
	scene._open_factory("research")
	var panel = scene.hud.factory_panel.research_panel
	panel.select("construction")
	test.check(panel.start_button.disabled and panel.requirements.text.contains("crossing"),"Early technology explains the age gate and cannot start a locked project")
	test.check(Reports.recommended_technology(world).is_empty(),"Opening does not recommend unavailable technology")
	var original_target: String = world.research_target
	panel.tree.buttons.metallurgy.pressed.emit()
	test.check(world.research_target == original_target and panel.selected_id == "metallurgy","Inspecting a future technology does not change research")
	panel.prerequisite_button.pressed.emit()
	test.check(panel.selected_id == "logistics","Locked project links to its unmet prerequisite")
	world = Fixtures.industrial()
	world.researched = ["logistics"]
	world.research_target = ""
	world.research_progress = 0
	world.research_banks = {"metallurgy":7}
	scene._bind_world(world)
	scene.hud.factory_panel.open_panel(world,"research")
	test.check(panel.selected_id == "metallurgy" and not panel.start_button.disabled and panel.progress.value == 35,"Next project recommendation displays banked dossiers")
	panel.select("routing")
	test.check(world.current_research().is_empty(),"Browsing an available branch requires an explicit start")
	panel.start_button.pressed.emit()
	scene.hud.factory_panel.refresh()
	test.check(world.current_research() == "routing" and panel.start_button.disabled,"Start project uses the authoritative research command")
	world.research_progress = 3
	panel.select("metallurgy")
	panel.start_button.pressed.emit()
	scene.hud.factory_panel.refresh()
	test.check(world.current_research() == "metallurgy" and world.research_progress == 7 and world.research_banks.routing == 3,"Switching branches restores banked progress and preserves the previous branch")
	panel.bench_button.pressed.emit()
	test.check(not scene.hud.factory_panel.visible and scene.hud.crafting.visible and scene.hud.crafting.selected_id == "lab","Technology recipe link opens the correct crafting recipe")
	scene.hud.close_workspace()
	world = Fixtures.industrial()
	scene._bind_world(world)
	var hall = world.settlements.sites.town_hall
	hall.inventory.contents = Sites.SITES.town_hall.repair.duplicate()
	var report := Reports.settlement(world,"town_hall")
	test.check(report.delivered == report.required and report.state == "incomplete" and report.prerequisite == "workshop","Full Town Hall materials still show the workshop prerequisite")
	hall.inventory.contents = {"stone":45,"iron_plate":10}
	report = Reports.settlement(world,"town_hall")
	test.check(report.delivered == 50 and report.missing.iron_plate == 30 and not report.missing.has("stone"),"Repair progress caps surplus supplies and reports exact remaining quantities")
	world.settlements.sites.trading_post.repaired = true
	world.settlements.sites.workshop.inventory.contents = Sites.SITES.workshop.repair.duplicate()
	report = Reports.settlement(world,"workshop")
	test.check(report.state == "incomplete" and report.credit_cost == 60 and not report.reason.is_empty(),"Fully supplied workshop still communicates its credit requirement")
	world.settlements.credits = 60
	test.check(Reports.settlement(world,"workshop").state == "ready","Repair card becomes ready only after all model requirements are met")
	scene.hud.toggle_town()
	var town = scene.hud.town_panel
	test.check(town.project_cards.workshop.badge.text == "READY TO RESTORE" and town.project_buttons.town_hall.text == "Inspect requirements","Town overview distinguishes ready and blocked projects")
	test.check(scene.hud.objective.visible and not scene.hud.objective.text.is_empty(),"Industrial play retains a settlement objective after introductory lessons")
	world.settlements.sites.workshop.repaired = true
	hall.repaired = true
	hall.health = 0
	scene.hud.refresh()
	test.check(Reports.settlement(world,"workshop").state == "offline" and town.project_cards.workshop.badge.text == "SERVICES OFFLINE","Breached Town Hall cannot present disabled regional services as active")
	scene.queue_free()
	await test.process_frame

