extends SceneTree
## Native regression: Crafting -> close -> placed camp inspector at real display sizes.
const World = preload("res://scripts/simulation/world.gd")
const Simulation = preload("res://scripts/simulation/simulation.gd")
var failures := 0

func _initialize() -> void: call_deferred("run")

func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error(label)

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Workspace layout regression requires native text/layout rendering.")
		quit(1)
		return
	for fullscreen in [false, true]:
		var scene = load("res://main.tscn").instantiate()
		root.add_child(scene)
		root.mode = Window.MODE_FULLSCREEN if fullscreen else Window.MODE_WINDOWED
		root.content_scale_size = Vector2i(1280, 800)
		if not fullscreen: root.size = Vector2i(1100, 720)
		scene.hud.story_panel.dismiss_silently()
		scene.set_process(false)
		var world := World.new(1063638934)
		world.start()
		world.player_position = Vector2(22.5, 11.5)
		world.previous_position = world.player_position
		world.player.contents = {"timber": 8, "stone": 2}
		world.production.timber = 8
		scene._bind_world(world)
		scene.hud.toggle_crafting()
		await process_frame
		check(world.craft("lumber_camp"), "Camp queues intermediate axe through the open crafting workspace")
		for tick in range(60):
			Simulation.step(world)
			scene.hud.refresh()
			await process_frame
		check(world.player.count("lumber_camp") == 1, "Camp crafting completes with live queue controls")
		scene.hud.close_workspace()
		var cell := Vector2i(18, 9)
		check(world.build("lumber_camp", cell, 0), "Camp builds at the reported tile")
		scene._select("lumber_camp")
		var resizes := [0]
		scene.hud.workspace.machine.resized.connect(func(): resizes[0] += 1)
		scene._request_inspection(cell)
		for frame in range(6): await process_frame
		check(scene.hud.workspace.visible and scene.hud.workspace.mode == "machine", "Camp inspector opens after using Crafting")
		var settled: int = resizes[0]
		for frame in range(6): await process_frame
		check(resizes[0] == settled, "Machine layout settles instead of repeatedly resizing")
		# Reopening and changing modes must also keep the inspector responsive.
		for cycle in range(3):
			scene.hud.toggle_crafting()
			await process_frame
			scene.hud.close_workspace()
			scene._request_inspection(cell)
			for frame in range(4): await process_frame
		scene.hud.close_workspace()
		scene._update_reclaim(cell, true, 0.6)
		check(world.at(cell) == null and world.player.count("lumber_camp") == 1, "Camp can be reclaimed after repeated workspace transitions")
		scene._bind_world(preload("res://tests/fixtures.gd").industrial())
		scene._open_factory("research")
		var research = scene.hud.factory_panel.research_panel
		var project_resizes := [0]
		research.resized.connect(func(): project_resizes[0] += 1)
		for id in ["construction","routing","metallurgy","logistics"]:
			research.select(id)
			for frame in range(6): await process_frame
			var rect: Rect2 = scene.hud.factory_panel.get_child(0).get_child(0).get_global_rect()
			check(root.get_visible_rect().encloses(rect),"Technology window fits the viewport for " + id)
			var project_settled: int = project_resizes[0]
			for frame in range(4): await process_frame
			check(project_resizes[0] == project_settled,"Technology layout settles for " + id)
		scene.hud.factory_panel.close_panel()
		scene.hud.toggle_town()
		for frame in range(6): await process_frame
		check(not scene.hud.workspace.pack_column.visible,"Town overview gives project cards the full workspace width")
		scene._inspect_site("workshop")
		for frame in range(6): await process_frame
		check(scene.hud.workspace.pack_column.visible,"Building details restore the pack for delivery")
		print("Native workspace layout passed: ", "fullscreen" if fullscreen else "minimum window", " / ", root.size)
		scene.queue_free()
		await process_frame
	print("Native workspace layout: %d failures" % failures)
	quit(1 if failures else 0)
