extends RefCounted
const World = preload("res://scripts/simulation/world.gd")
const Simulation = preload("res://scripts/simulation/simulation.gd")
const Saves = preload("res://scripts/persistence/save_service.gd")
const Fixtures = preload("res://tests/fixtures.gd")

static func ui(test: SceneTree) -> void:
	var scene = load("res://main.tscn").instantiate()
	test.root.add_child(scene)
	await test.process_frame
	scene.set_process(false)
	scene.hud.story_panel.dismiss_silently()
	scene.paused = true
	var world := World.new(1063638934)
	world.start()
	world.player.contents = {}
	scene._bind_world(world)
	scene.hud.toggle_crafting()
	var panel = scene.hud.crafting
	panel.select_recipe("lumber_camp")
	panel.craft_one.pressed.emit()
	test.check(world.craft_queue.is_empty() and panel.preview.charge == 0, "Rejected crafting cannot play a material-acceptance animation")
	world.player.contents = {"timber": 8, "stone": 2}
	scene.presentation.reduced_motion = false
	scene.presentation.apply_preferences()
	scene.hud.refresh()
	test.check(panel.preview.subject == "lumber_camp" and panel.description.visible, "Selected product has an illustrated preview and a visible purpose")
	test.check(panel.ingredient_states.stone_axe.text == "AUTO-CRAFT" and panel.stock_cost.text.contains("Timber x8") and panel.route_label.text.contains("Stone axe"), "Craft cards distinguish automatic intermediates and the full raw cost")
	var deliveries: Array = []
	world.hand_craft_completed.connect(func(id, goods): deliveries.append({"id":id,"goods":goods}))
	panel.craft_one.pressed.emit()
	test.check(world.craft_queue.size() == 2 and panel.preview.charge > 0, "One accepted click queues its chain and starts bounded ingredient feedback")
	world.player.capacity = 0
	for tick in range(100): Simulation.step(world)
	test.check(world.craft_queue.size() == 1 and world.craft_queue[0].remaining == 0 and deliveries.is_empty(), "Consumed intermediates and a finished craft blocked by pack capacity do not claim delivery")
	world.player.capacity = 10000
	Simulation.step(world)
	test.check(deliveries == [{"id":"lumber_camp","goods":{"lumber_camp":1}}] and world.player.count("lumber_camp") == 1, "Only actual final inventory output emits its completion event")
	test.check(scene.hud.workspace.reward_card.visible and not scene.hud.completion.visible and scene.hud.workspace.reward_card.detail.text.contains("+1 to pack"), "Crafting rewards use an inline card instead of covering craft controls")
	Simulation.step(world)
	test.check(deliveries.size() == 1, "A completed craft cannot replay its delivery on later ticks")
	var industrial := Fixtures.industrial()
	industrial.player.contents = {"iron_plate":10,"gear":3,"copper_plate":5}
	scene._bind_world(industrial)
	world.hand_craft_completed.emit("lumber_camp",{"lumber_camp":99})
	test.check(not scene.hud.workspace.reward_card.visible and not scene.hud.completion.visible, "Rebinding clears feedback and disconnects completed-item events from the old world")
	scene.hud.toggle_character()
	scene.hud.workspace.character_panel.show_section("equipment")
	var upgrades: Array = []
	industrial.equipment_upgraded.connect(func(id, rank): upgrades.append([id,rank]))
	var boots: Button = scene.hud.workspace.character_panel.cards.boots.button
	boots.pressed.emit()
	boots.pressed.emit()
	test.check(upgrades == [["boots",1]] and industrial.player.count("iron_plate") == 0, "Installed-equipment events require a successful purchase and reject repeated stale requests")
	test.check(scene.hud.workspace.reward_card.key == "equipment:boots" and scene.hud.workspace.reward_card.detail.text.contains("4.6"), "Equipment celebration communicates the actual installed stat")
	scene.presentation.reduced_motion = true
	scene.presentation.apply_preferences()
	var before: Dictionary = Saves.encode(industrial)
	panel.preview.absorb(["timber","stone"])
	test.check(panel.preview.charge == 0 and panel.preview.flash == 0 and scene.hud.workspace.reward_card.modulate.a == 1.0, "Reduced motion disables material flight and keeps rewards immediately readable")
	test.check(Saves.encode(industrial) == before, "Illustration and animation preferences do not alter gameplay or save data")
	scene.hud.workspace.reward_card._process(6)
	test.check(not scene.hud.workspace.reward_card.visible, "Reward presentation expires rather than accumulating cards")
	scene.hud.close_workspace()
	industrial.player.contents = {"iron_plate":2}
	industrial.craft("gear")
	for tick in range(30): Simulation.step(industrial)
	test.check(scene.hud.completion.visible and scene.hud.completion.key == "item:gear", "Crafts completed outside a menu remain visible in the gameplay HUD")
	var town := Fixtures.trading_town()
	town.player_position = Vector2(town.settlements.sites.workshop.port()) + Vector2.ONE * 0.5
	town.previous_position = town.player_position
	town.player.contents = {"iron_plate":20,"gear":5,"copper_plate":10}
	town.settlements.credits = 60
	scene._bind_world(town)
	scene._inspect_site("workshop")
	var restorations: Array = []
	town.settlement_restored.connect(func(id): restorations.append(id))
	test.check(not town.restore_site("workshop") and restorations.is_empty(), "Unfunded repair materials cannot trigger a restored-building celebration")
	town.supply_site("workshop")
	test.check(town.restore_site("workshop") and restorations == ["workshop"], "Restoration emits its reward only after authoritative repair succeeds")
	await test.process_frame
	test.check(scene.pending_restoration == "workshop" and scene.hud.story_panel.visible, "Restoration rewards wait for the new conversation instead of expiring behind it")
	scene.hud.story_panel.close_panel()
	await test.process_frame
	test.check(scene.hud.completion.key == "site:workshop" and scene.hud.completion.detail.text.contains("20%"), "Restoration feedback identifies the real regional benefit after dialogue")
	scene.queue_free()
	await test.process_frame
