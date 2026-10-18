extends RefCounted
const Fixtures = preload("res://tests/fixtures.gd")
const Simulation = preload("res://scripts/simulation/simulation.gd")
const Catalog = preload("res://scripts/data/catalog.gd")
static func ui(test: SceneTree) -> void:
	var scene = load("res://main.tscn").instantiate()
	test.root.add_child(scene)
	await test.process_frame
	scene.set_process(false)
	scene.hud.story_panel.dismiss_silently()
	var world := Fixtures.industrial()
	world.player.contents = {"timber":2}
	scene._bind_world(world)
	var history = scene.hud.history
	test.check(not world.craft("lumber_camp") and history.entries.is_empty(),"Rejected craft cannot create a reward-history entry")
	world.craft("plank")
	for tick in range(20): Simulation.step(world)
	test.check(history.entries.size() == 1 and history.entries[0].amount == 2 and history.unread == 1,"Actual completed output creates one unread history entry")
	world.player.add("timber")
	world.craft("plank")
	for tick in range(20): Simulation.step(world)
	test.check(history.entries.size() == 1 and history.entries[0].amount == 4 and history.unread == 1,"Repeated completed crafts coalesce actual quantities without inflating unread count")
	scene.hud.completion.clear()
	scene.hud.workspace.reward_card.clear()
	test.check(history.entries.size() == 1 and scene.hud.history_button.text.contains("1 new"),"History survives expiring reward cards and advertises unread updates")
	scene._open_history()
	test.check(history.unread == 0 and history.visible and not scene.hud.world_has_pointer(),"Opening history acknowledges updates and blocks world-pointer actions")
	var uid: int = history.entries[0].uid
	history.buttons[uid].pressed.emit()
	test.check(not history.visible and scene.hud.workspace.visible and scene.hud.crafting.selected_id == "plank","Recipe shortcut opens the correct craft without crafting it")
	scene.hud.close_workspace()
	var lab = world.spawn("lab",Vector2i(20,20),0)
	lab.inventory.contents = {"science":1}
	lab.progress = 29
	world.research_progress = Catalog.technology("logistics").cost - 1
	Simulation.step(world)
	test.check(history.entries[0].destination == "technology" and history.entries[0].subject == "logistics" and world.researched.has("logistics"),"Actual research completion records its unlock and destination")
	Simulation.step(world)
	test.check(history.entries.size() == 2,"Completed technology cannot repeatedly announce itself on later simulation ticks")
	scene._open_history()
	history.buttons[history.entries[0].uid].pressed.emit()
	test.check(scene.hud.factory_panel.visible and scene.hud.factory_panel.research_panel.selected_id == "logistics","Unlock shortcut selects the completed technology")
	scene.hud.factory_panel.close_panel()
	history.record("equipment:boots","Equipment installed","Boots","equipment","boots")
	scene._open_history()
	history.buttons[history.entries[0].uid].pressed.emit()
	test.check(scene.hud.workspace.character_panel.section == "equipment" and scene.hud.workspace.visible,"Equipment history shortcut opens equipment upgrades")
	scene.hud.close_workspace()
	var post = world.settlements.sites.trading_post
	post.inventory.contents = world.settlements.Definitions.SITES.trading_post.repair.duplicate()
	world.player_position = Vector2(post.port()) + Vector2(0.5,0.5)
	test.check(world.restore_site("trading_post"),"Restoration-history fixture completes a real repair")
	for frame in range(3): await test.process_frame
	var before: int = history.entries.size()
	scene.hud.story_panel.dismiss_silently()
	scene._story_finished("")
	for frame in range(3): await test.process_frame
	test.check(history.entries.size() == before and history.entries[0].destination == "town","Deferred restoration celebration cannot duplicate the history record")
	scene._open_history()
	history.buttons[history.entries[0].uid].pressed.emit()
	test.check(scene.hud.workspace.site_id == "trading_post" and scene.hud.workspace.mode == "town","Restoration shortcut opens the correct civic building")
	scene._open_history()
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	scene._input(escape)
	test.check(not history.visible and not scene.hud.pause_menu.visible,"Escape closes history before opening pause")
	history.clear()
	for index in range(60): history.record("unique:%d" % index,"Update","Details","crafting","plank")
	test.check(history.entries.size() == 50 and history.unread == 50,"Bounded history drops old entries and keeps unread count accurate")
	scene._open_history()
	history.record("new","Update","Details","crafting","plank")
	test.check(history.unread == 0 and history.entries.size() == 50,"Events received while reading history are acknowledged without overflow")
	history.clear_button.pressed.emit()
	test.check(history.entries.is_empty() and history.unread == 0,"Clear history acknowledges and removes retained entries")
	history.record("old","Update","Details","crafting","plank")
	var old_world = world
	scene._bind_world(Fixtures.industrial())
	old_world.technology_completed.emit("routing")
	test.check(history.entries.is_empty() and not history.visible,"Switching worlds clears history and disconnects old unlock events")
	scene.queue_free()
	await test.process_frame
