extends RefCounted
const Simulation = preload("res://scripts/simulation/simulation.gd")
const Saves = preload("res://scripts/persistence/save_service.gd")
static func setup() -> RefCounted:
	var world = preload("res://tests/orchard_project_tests.gd").world()
	world.orchard_project.restore_bed(world)
	world.researched = ["logistics","metallurgy","construction"]
	world.player_position = Vector2(world.settlements.sites.town_hall.port())+Vector2(-0.5,0.5)
	world.previous_position = world.player_position
	return world
static func run(test: SceneTree) -> void:
	var world := setup()
	var chapter = world.settlements.homecoming
	var hall = world.settlements.sites.town_hall
	test.check(chapter.unlocked(world) and chapter.reason(world).contains("supplies"),"Homecoming starts as a funded pantry project after Town Hall restoration")
	var before: Dictionary = hall.inventory.contents.duplicate()
	test.check(not chapter.commission(world) and hall.inventory.contents == before,"Unfunded phase cannot consume items or advance the chapter")
	world.player.contents = chapter.goods().duplicate()
	test.check(chapter.deliver(world) and world.player.total() == 0 and hall.inventory.count("foraged_food") == 12,"Manual chapter delivery transfers actual produce through the Hall inventory")
	test.check(world.settlements.receiving_limit("town_hall","foraged_food",world) == 0,"Chapter hatch refuses excess phase supplies")
	world.player_position = Vector2(80,80)
	test.check(not chapter.commission(world) and chapter.stage == 0 and hall.inventory.count("foraged_food") == 12,"Remote commissioning cannot spend stocked supplies")
	world.player_position = Vector2(hall.port())+Vector2(-0.5,0.5)
	test.check(chapter.commission(world) and chapter.stage == 1 and hall.inventory.total() == 0,"Commissioning pantry consumes its full bill exactly once")
	test.check(not chapter.commission(world) and chapter.work_ticks == 0,"Second phase requires genuine power work")
	world.player.contents = chapter.goods().duplicate()
	chapter.deliver(world)
	var generator = world.spawn("generator",Vector2i(39,10),0)
	world.spawn("power_pole",Vector2i(39,11),0)
	var a = world.spawn("furnace",Vector2i(39,12),0)
	var b = world.spawn("furnace",Vector2i(40,11),0)
	a.electric_mode = true
	b.electric_mode = true
	a.inventory.contents = {"iron_ore":20}
	b.inventory.contents = {"iron_ore":20}
	for i in range(10): Simulation.step(world)
	test.check(chapter.work_ticks == 0,"Unfueled electric machines cannot prove a working district")
	generator.inventory.add("coal",2)
	for i in range(10): Simulation.step(world)
	test.check(chapter.work_ticks == 10,"Two working drives count elapsed useful work once per tick, not twice")
	a.inventory.contents.clear()
	b.inventory.contents.clear()
	for i in range(10): Simulation.step(world)
	test.check(chapter.work_ticks == 10,"Idle generators and empty production lines keep but do not grow proof")
	var loaded := Saves.decode(JSON.parse_string(JSON.stringify(Saves.encode(world))))
	test.check(loaded.error.is_empty(),"In-progress homecoming and banked work survive save validation: " + loaded.error)
	if loaded.error.is_empty():
		test.check(loaded.world.settlements.homecoming.work_ticks == 10 and loaded.world.settlements.homecoming.stage == 1,"Saved phase and exact work proof restore")
	a.inventory.contents = {"iron_ore":30}
	b.inventory.contents = {"iron_ore":30}
	for i in range(290):
		Simulation.step(world)
		if a.output.total() >= 5: world.collect_output(a.cell)
		if b.output.total() >= 5: world.collect_output(b.cell)
	test.check(chapter.work_ticks == 300 and chapter.reason(world).is_empty(),"A fueled local line with cleared outputs finishes the commissioning proof")
	test.check(chapter.commission(world) and chapter.stage == 2 and hall.inventory.total() == 0,"Power phase consumes its wire and gears only when commissioning succeeds")
	world.player.contents = chapter.goods().duplicate()
	chapter.deliver(world)
	test.check(chapter.reason(world).contains("Greybank"),"Fair explains its regional road dependency even when all supplies are stocked")
	world.frontier.sites.quarry.discovered = true
	world.frontier.sites.quarry.claimed = true
	for batch in range(9):
		world.quarry_project.inventory.contents = world.quarry_project.GOODS.duplicate()
		for i in range(600):
			world.ticks += 1
			world.quarry_project.step(world)
	test.check(chapter.reason(world).contains("neighborhood"),"Completed road reveals the real housing-delivery requirement")
	hall.inventory.add("construction_kit",6)
	hall.inventory.add("steel",12)
	hall.inventory.add("copper_plate",12)
	for i in range(1800):
		world.ticks += 1
		world.settlements.step(world)
	test.check(world.settlements.district_level() == 1 and hall.inventory.count("foraged_food") == 24 and chapter.reason(world).is_empty(),"Housing shipments progress without consuming fair supplies")
	test.check(chapter.commission(world) and chapter.stage == 3 and world.defense.cleared == 0,"Homecoming completes without requiring combat")
	test.check(not chapter.commission(world) and world.story.available(world,"homecoming_fair"),"Completed chapter cannot repeat rewards and unlocks Ada's conclusion")
	world.player.contents = {"coal":10}
	test.check(chapter.deliver(world) and hall.inventory.count("coal") == 10,"Public depot unlock accepts real coal through the same hatch")
	a.electric_mode = false
	a.inventory.contents.clear()
	b.electric_mode = false
	b.inventory.contents.clear()
	world.power.revision = -1
	world.ticks = ceili(world.ticks/10.0)*10
	chapter.step(world)
	test.check(hall.inventory.count("coal") == 9 and a.inventory.count("coal")+b.inventory.count("coal") == 1,"Public depot moves one real coal to a nearby burner without creating fuel")
	hall.health = 0
	world.ticks += 10
	chapter.step(world)
	test.check(hall.inventory.count("coal") == 9,"Town Hall damage suspends public depot service without erasing the chapter")
	hall.health = hall.max_health()
	loaded = Saves.decode(JSON.parse_string(JSON.stringify(Saves.encode(world))))
	test.check(loaded.error.is_empty(),"Completed chapter, road, housing and coal buffer survive save validation: " + loaded.error)
	if loaded.error.is_empty():
		Simulation.step(world)
		Simulation.step(loaded.world)
		test.check(Saves.encode(world) == Saves.encode(loaded.world),"Loaded chapter and public services continue deterministically")
	var invalid := Saves.encode(world)
	invalid.settlements.homecoming.work_ticks = 299
	test.check(not Saves.decode(invalid).error.is_empty(),"Save rejects completed phases without their full power proof")
	invalid = Saves.encode(world)
	invalid.settlements.homecoming.last_work_tick = world.ticks+1
	test.check(not Saves.decode(invalid).error.is_empty(),"Save rejects work proof from the future")
	invalid = Saves.encode(world)
	invalid.settlements.homecoming.stage = 99
	test.check(not Saves.decode(invalid).error.is_empty(),"Save rejects unknown chapter phases")

static func ui(test: SceneTree) -> void:
	var scene = load("res://main.tscn").instantiate()
	test.root.add_child(scene)
	await test.process_frame
	scene.set_process(false)
	scene.hud.story_panel.dismiss_silently()
	var world := setup()
	scene._bind_world(world)
	scene.hud.toggle_town()
	var panel = scene.hud.town_panel
	test.check(panel.chapter_box.visible and panel.chapter_title.text.contains("pantry") and panel.chapter_finish.disabled,"Town overview makes the active chapter and unmet requirements visible")
	world.player.contents = world.settlements.homecoming.goods().duplicate()
	panel.chapter_deliver.pressed.emit()
	test.check(not panel.chapter_finish.disabled,"Delivering phase supplies enables the authoritative commission action")
	panel.chapter_finish.pressed.emit()
	test.check(world.settlements.homecoming.stage == 1 and scene.hud.history.entries[0].subject == "town_hall","Chapter milestone advances the model and records a navigable reward")
	panel.chapter_lead.pressed.emit()
	test.check(scene.hud.factory_panel.visible and not scene.hud.workspace.visible,"Power phase links directly to Technology")
	scene.queue_free()
	await test.process_frame
