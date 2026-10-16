extends RefCounted
const World = preload("res://scripts/simulation/world.gd")
const Saves = preload("res://scripts/persistence/save_service.gd")
const Definitions = preload("res://scripts/data/skill_catalog.gd")
const Fixtures = preload("res://tests/fixtures.gd")

static func run(test: SceneTree) -> void:
	for level in [1, 10, 25, 50, 75, 99]:
		var world := World.new()
		world.skills.xp.fabrication = Definitions.threshold(level)
		var units: int = world.skills.work_units("fabrication")
		world.player.add("copper_plate", 20)
		world.craft_many("wire", 20)
		while not world.craft_queue.is_empty(): test.advance(world, 1)
		test.check(world.ticks == ceili(10000.0 / units) and world.player.count("wire") == 40 and world.craft_credit == 0, "Wire batches realize advertised bonus at level %d without idle credit or extra output" % level)
	var partial := World.new()
	partial.skills.xp.fabrication = Definitions.threshold(50)
	partial.player.add("copper_plate", 3)
	partial.craft_many("wire", 3)
	test.advance(partial, 5)
	test.check(partial.craft_credit > 0, "Completed short job carries earned surplus into the next queued job")
	var loaded := Saves.decode(JSON.parse_string(JSON.stringify(Saves.encode(partial))))
	test.check(loaded.error.is_empty() and loaded.world.craft_credit == partial.craft_credit, "Cross-job crafting credit survives JSON saves")
	if loaded.error.is_empty():
		test.advance(partial, 20)
		test.advance(loaded.world, 20)
		test.check(Saves.encode(partial) == Saves.encode(loaded.world), "Cross-job work continues deterministically after loading")
	var cancel := World.new()
	cancel.skills.xp.fabrication = Definitions.threshold(50)
	cancel.player.add("copper_plate", 3)
	cancel.craft_many("wire", 3)
	test.advance(cancel, 5)
	cancel.cancel_all_crafts()
	test.check(cancel.craft_credit == 0 and cancel.player.count("copper_plate") == 2 and cancel.player.count("wire") == 2, "Cancellation clears surplus work and refunds only remaining jobs")
	var bad := Saves.encode(cancel)
	bad.craft_credit = 100
	test.check(not Saves.decode(bad).error.is_empty(), "Save rejects idle banked work")
	bad = Saves.encode(partial)
	bad.craft_credit = 125
	test.check(not Saves.decode(bad).error.is_empty(), "Save rejects unearned full-tick credit")
	var line := World.new()
	var assembler = line.spawn("assembler", Vector2i.ZERO, 0)
	assembler.inventory.add("iron_plate", 30)
	test.advance(line, 100)
	test.check(line.skills.commissions.get("line:gear") == 10 and line.skills.xp.fabrication == 270, "Ten real automated batches award first commissioning and graduated productive XP")
	test.advance(line, 1000)
	test.check(line.skills.commissions["line:gear"] == 10 and line.skills.xp.fabrication == 270, "Blocked output and idle time cannot farm productive commissions")
	loaded = Saves.decode(JSON.parse_string(JSON.stringify(Saves.encode(line))))
	test.check(loaded.error.is_empty(), "Productive commission counters persist")
	if loaded.error.is_empty():
		loaded.world.entities[assembler.id].output.remove("gear", 10)
		test.advance(loaded.world, 10)
		test.check(loaded.world.skills.commissions["line:gear"] == 11 and loaded.world.skills.xp.fabrication == 270, "Loading cannot repeat a completed commission threshold")
	bad = Saves.encode(line)
	bad.skills.commissions = {"line:unknown": 10}
	test.check(not Saves.decode(bad).error.is_empty(), "Save rejects commissions for unknown recipes")
	for id in Definitions.SKILLS:
		var previous := 0
		for milestone in Definitions.milestones(id):
			var bonus: int = line.skills.bonus_percent(id, milestone)
			test.check(bonus > previous, "Every %s reward milestone grants an actual improvement at %d" % [id, milestone])
			previous = bonus
	var town := Fixtures.defense_town(false)
	town.player.contents = {"iron_plate": 1000, "gear": 1000, "copper_plate": 1000, "steel": 1000, "wire": 1000, "construction_kit": 100, "repair_kit": 5}
	town.researched = ["logistics", "metallurgy", "construction"]
	test.check(town.upgrade_character("repair", 1) and town.character.stat("repair_power") == 65, "Rebuilt Hall unlocks a real repair-efficiency upgrade")
	test.check(not town.upgrade_character("repair", 2), "Later repair rig requires a restored neighborhood")
	town.settlements.sites.town_hall.shipments = 6
	test.check(town.upgrade_character("repair", 2) and town.upgrade_character("scanner", 1) and town.upgrade_character("scanner", 2), "Neighborhood restoration unlocks repair and survey improvements")
	test.check(town.survey_radius() == town.skills.survey_radius() + 2, "Survey instruments extend the actual survey command")
	town.player_position = Vector2(41.5, 14.5)
	var hall = town.settlements.sites.town_hall
	hall.health = 100
	test.check(town.repair_at(hall.port()) and hall.health == 180 and town.player.count("repair_kit") == 4, "Repair rig restores advertised health for exactly one physical kit")
	hall.health = hall.max_health()
	test.check(not town.upgrade_character("repair", 3), "Final repair rig requires three rescued arrivals")
	town.defense.cleared = 5
	town.settlements.sites.town_hall.shipments = 9
	test.check(town.upgrade_character("repair", 3), "Rescued arrivals unlock final repair rig")
	for rank in range(1, 5): town.upgrade_character("boots", rank)
	test.check(town.character.level("boots") == 4 and town.character.stat("movement_speed") == 6.2, "Late settlement and defense goal unlocks fourth equipment tier")
	loaded = Saves.decode(JSON.parse_string(JSON.stringify(Saves.encode(town))))
	test.check(loaded.error.is_empty() and loaded.world.character.level("repair") == 3, "Late equipment validates after restoration of defense progression")
	var goal_world := World.new()
	goal_world.guidance.pin(goal_world, "equipment", "boots", 1)
	test.check(not goal_world.guidance.goal(goal_world).complete and goal_world.guidance.goal(goal_world).text.contains("Iron plate"), "Pinned equipment goal communicates materials and reward")
	goal_world.player.contents = {"iron_plate": 10, "gear": 3, "copper_plate": 5}
	test.check(goal_world.guidance.equipment_status(goal_world).ready == 1, "Only affordable unlocked next tiers count as READY")
	goal_world.guidance.view_equipment(goal_world)
	test.check(goal_world.guidance.equipment_status(goal_world).new == 0 and goal_world.guidance.equipment_status(goal_world).ready == 1, "Viewing clears NEW while preserving actionable READY")
	goal_world.upgrade_character("boots", 1)
	test.check(goal_world.guidance.goal(goal_world).complete, "Pinned goal shows completion after purchase")
	loaded = Saves.decode(JSON.parse_string(JSON.stringify(Saves.encode(goal_world))))
	test.check(loaded.error.is_empty() and loaded.world.guidance.serialize() == goal_world.guidance.serialize(), "Goals, acknowledgements, and recent activity persist")
	var old := Saves.encode(World.new())
	for key in ["craft_credit", "guidance"]: old.erase(key)
	old.skills.erase("commissions")
	loaded = Saves.decode(old)
	test.check(loaded.error.is_empty() and loaded.world.guidance.pinned.is_empty() and loaded.world.skills.commissions.is_empty(), "Older saves gain guidance and productive milestones without retroactive XP")
	bad = Saves.encode(goal_world)
	bad.guidance.pinned = {"kind": "equipment", "id": "boots", "target": 99}
	test.check(not Saves.decode(bad).error.is_empty(), "Save rejects impossible personal goals")
	bad = Saves.encode(goal_world)
	bad.guidance.history = [{"text": "Future event", "tick": goal_world.ticks + 1}]
	test.check(not Saves.decode(bad).error.is_empty(), "Activity history cannot contain future timestamps")
	var guide := World.new()
	guide.start()
	test.check(not guide.guidance.introduced and guide.guidance.pinned.is_empty(), "New game does not advertise equipment before the working-drill lesson")
	guide.guide.completed.append("drill_online")
	guide.guidance.observe(guide)
	var notices: int = guide.guidance.history.size()
	guide.guidance.observe(guide)
	test.check(guide.guidance.introduced and guide.guidance.pinned.id == "boots" and guide.guidance.history.size() == notices, "Working-drill introduction suggests a useful goal exactly once")
	var unread: Array = guide.story.unread(guide)
	test.check(unread.has("arrival") and unread.has("mira_before"), "Unread journal includes the introduction and currently relevant conversations")
	for i in range(60): goal_world.message.emit("Event %d" % i)
	test.check(goal_world.guidance.history.size() == 40 and goal_world.guidance.history.back().text == "Event 59", "Recent activity remains bounded")

static func ui(test: SceneTree) -> void:
	var scene = load("res://main.tscn").instantiate()
	test.root.add_child(scene)
	await test.process_frame
	scene.set_process(false)
	var world := Fixtures.combat_town()
	world.player.contents = {"iron_plate": 100, "gear": 100, "copper_plate": 100}
	scene._bind_world(world)
	for viewport in [Vector2i(1280, 800), Vector2i(1100, 720)]:
		test.root.content_scale_size = viewport
		test.root.size = viewport
		scene.hud.toggle_character()
		var panel = scene.hud.workspace.character_panel
		panel.show_section("skills")
		for i in range(4): await test.process_frame
		test.check(not scene.hud.workspace.pack_column.visible and panel.size.x > 900, "Engineer receives full workspace at %s" % viewport)
		var pins_fit := true
		for row in panel.skill_rows.values():
			if not scene.hud.workspace.character_scroll.get_global_rect().encloses(row.pin.get_global_rect()): pins_fit = false
		test.check(pins_fit, "All three skill rewards and tracking actions are visible at %s" % viewport)
		panel.show_section("equipment")
		panel.cards.boots.pin.pressed.emit()
		test.check(world.guidance.pinned.id == "boots", "Equipment Track pins its exact next tier")
		scene.hud.close_workspace()
		scene.hud.refresh()
		test.check(scene.hud.goal_panel.visible and scene.hud.goal_button.text.contains("PERSONAL GOAL"), "Pinned goal remains visible during world play")
		world.guidance.pinned = {}
		scene.hud.refresh()
		test.check(not scene.hud.goal_panel.visible, "Unpinning dismisses the personal tracker")
		test.check(test.root.get_visible_rect().encloses(scene.hud.top.get_global_rect()) and test.root.get_visible_rect().encloses(scene.hud.bottom.get_global_rect()), "Guidance indicators fit viewport %s" % viewport)
	scene._open_journal()
	var story = scene.hud.story_panel
	story.present(world, "mira_after")
	story.close_panel()
	test.check(not world.story.seen.has("mira_after"), "Closing an unread conversation early retains its unread marker")
	story.present(world, "mira_after")
	while story.visible: story.advance()
	test.check(world.story.seen.has("mira_after"), "Finishing the conversation clears its unread marker")
	scene.queue_free()
	await test.process_frame
	test.root.content_scale_size = Vector2i(1280, 800)
	test.root.size = Vector2i(1280, 800)
