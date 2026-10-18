extends RefCounted
const World = preload("res://scripts/simulation/world.gd")

static func ui(test: SceneTree) -> void:
	var scene = load("res://main.tscn").instantiate()
	test.root.add_child(scene)
	await test.process_frame
	scene.set_process(false)
	scene.hud.story_panel.dismiss_silently()
	scene.paused = true
	var world := World.new(1812085856)
	world.start()
	var cell := Vector2i(32, 7)
	world.player_position = Vector2(30.5, 9.5)
	world.previous_position = world.player_position
	world.player.contents = {"lumber_camp": 1}
	scene._bind_world(world)
	test.check(world.build("lumber_camp", cell, 0), "Reported camp tile builds normally with the reported seed")
	scene._select("lumber_camp")
	scene._request_inspection(cell)
	test.check(not scene.hud.workspace.visible, "World inspection waits until input dispatch finishes")
	await test.process_frame
	test.check(scene.hud.workspace.visible and scene.hud.workspace.entity_id == world.at(cell).id, "Placed camp opens its inspector while its build tool remains selected")
	scene.hud.close_workspace()
	scene.hud.refresh()
	var previous: String = scene.hud.inventory_label.text
	world.player.add("timber")
	for i in range(3): world.changed.emit()
	test.check(scene.hud.inventory_label.text == previous and scene.hud.refresh_queued, "World signals coalesce without changing controls inside their callback")
	await test.process_frame
	test.check(scene.hud.inventory_label.text.contains("PACK 1") and not scene.hud.refresh_queued, "Queued HUD update shows the latest inventory on the following frame")
	world.at(cell).output.add("timber", 4)
	scene._update_reclaim(cell, true, 0.2)
	test.check(world.at(cell) != null, "A short right hold does not reclaim prematurely")
	scene._update_reclaim(cell, true, 0.35)
	test.check(world.at(cell) == null and world.player.count("lumber_camp") == 1 and world.player.count("timber") == 5, "Right hold reclaims the camp and real stored timber while the build tool remains selected")
	scene._request_inspection(cell)
	var replacement := World.new()
	replacement.start()
	scene._bind_world(replacement)
	await test.process_frame
	test.check(not scene.hud.workspace.visible and scene.world == replacement, "Queued inspection from an old world cannot open in a replacement session")
	scene.queue_free()
	await test.process_frame
