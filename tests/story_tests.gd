extends RefCounted
const World = preload("res://scripts/simulation/world.gd")
const Saves = preload("res://scripts/persistence/save_service.gd")
const Fixtures = preload("res://tests/fixtures.gd")

static func run(test: SceneTree) -> void:
	var world := Fixtures.industrial()
	Fixtures.begin_lessons(world)
	test.check(world.story.seen.is_empty() and world.entities.is_empty() and world.player.total() == 0, "Story starts with a promise, never free machines or materials")
	test.check(world.story.goal(world).contains("Mira") and world.story.conversation(world, "trading_post") == "mira_before", "Opening story explains why the market matters")
	var requests: Array = []
	world.story_requested.connect(func(chapter): requests.append(chapter))
	world.player_position = Vector2.ZERO
	test.check(not world.talk_to_site("trading_post") and requests.is_empty(), "NPC conversations respect reach")
	var npc_cell: Vector2i = world.story.npc_cell(world, "trading_post")
	world.player_position = Vector2(npc_cell) + Vector2.ONE * 0.5
	test.check(world.talk_to_site("trading_post") and requests == ["mira_before"] and not world.story.seen.has("mira_before"), "Talking requests the correct chapter without claiming it was already read")
	world.story.mark_seen(world, "mira_before")
	world.story.mark_seen(world, "mira_before")
	test.check(world.story.seen == ["mira_before"] and world.player.total() == 0, "Replaying conversations is idempotent and grants no inventory")
	test.check(not world.story.mark_seen(world, "first_homecoming") and not world.story.mark_seen(world, "unknown"), "Future milestones and unknown story IDs cannot be added to a journal")
	var post = world.settlements.sites.trading_post
	world.player_position = Vector2(post.port()) + Vector2(-0.5, 0.5)
	world.player.contents = world.settlements.Definitions.SITES.trading_post.repair.duplicate()
	world.supply_site("trading_post")
	test.check(world.restore_site("trading_post") and requests.back() == "mira_after" and world.story.conversation(world, "trading_post") == "mira_after", "A real restoration triggers its after-conversation")
	world.story.mark_seen(world, "mira_after")
	var saved := Saves.encode(world)
	var loaded := Saves.decode(JSON.parse_string(JSON.stringify(saved)))
	test.check(loaded.error.is_empty() and loaded.world.story.seen == world.story.seen and loaded.world.story.goal(loaded.world).contains("Oren"), "Story memories and the next human goal survive a JSON save roundtrip")
	var old := saved.duplicate(true)
	old.erase("story")
	var migrated := Saves.decode(old)
	test.check(not migrated.has("world"), "Incomplete or obsolete saves are rejected without migration")
	for invalid in [{"seen": ["unknown"]}, {"seen": ["arrival", "arrival"]}, {"seen": ["first_homecoming"]}, {"seen": "invalid"}]:
		var broken := saved.duplicate(true)
		broken.story = invalid
		test.check(not Saves.decode(broken).error.is_empty(), "Malformed or impossible story memories are rejected")
	var before: Vector2i = world.story.npc_cell(world, "workshop")
	world.spawn("chest", before, 0)
	var after: Vector2i = world.story.npc_cell(world, "workshop")
	test.check(after != before and world.at(before).kind == "chest", "NPC presentation moves around existing machines without moving or deleting them")
	world.settlements.sites.workshop.origin += Vector2i(80, 0)
	world.settlements.rebuild_index()
	test.check(world.story.npc_cell(world, "workshop").x > 100, "NPC positions follow the saved landmark origins")
	var defended := Fixtures.defense_town()
	for site_id in world.story.Definitions.NPCS:
		var npc: Dictionary = world.story.Definitions.NPCS[site_id]
		test.check(world.story.Definitions.CHAPTERS.has(npc.before) and world.story.Definitions.CHAPTERS.has(npc.after) and defended.story.conversation(defended, site_id) == ("stone_homecoming" if site_id == "workshop" else npc.after), "Every keeper has a valid before/after conversation and restoration selects the latter")
	var milestones: Array = []
	defended.story_requested.connect(func(chapter): milestones.append(chapter))
	defended.defense.begin(defended)
	test.advance(defended, 1000)
	test.check(defended.defense.cleared == 1 and milestones.count("first_homecoming") == 1, "First real defense victory requests the homecoming scene exactly once")
	defended.damage_structure(defended.settlements.sites.town_hall.port(), 999)
	test.check(defended.story.conversation(defended, "town_hall") == "ada_recovery", "Ada offers recovery dialogue when the hub is breached")

	var scene = load("res://main.tscn").instantiate()
	test.root.add_child(scene)
	var panel = scene.hud.story_panel
	test.check(panel.visible and panel.chapter_id == "arrival" and not scene.hud.world_has_pointer(), "Arrival dialogue blocks world clicks while it explains the first goal")
	var next := InputEventKey.new()
	next.keycode = KEY_ENTER
	next.pressed = true
	var count: int = scene.world.player.total()
	for i in range(3): scene._input(next)
	test.check(not panel.visible and not scene.paused and scene.world.story.seen.has("arrival") and scene.world.player.total() == count, "Completing the arrival scene resumes play without changing inventory")
	var journal := InputEventKey.new()
	journal.keycode = KEY_J
	journal.pressed = true
	scene._unhandled_input(journal)
	test.check(panel.visible and panel.chapter_id.is_empty() and panel.entries.get_child_count() >= 1 and scene.paused, "J opens a journal containing the introduction and current goal")
	panel.entries.get_child(0).pressed.emit()
	test.check(panel.chapter_id == "arrival", "Journal entries replay authored conversations")
	panel.close_panel()
	test.check(not scene.paused and scene.world.story.seen.size() == 1, "Closing a replay preserves both pause state and unique story memory")
	scene._toggle_pause()
	scene._open_journal()
	panel.close_panel()
	test.check(scene.paused, "Closing the journal preserves an existing manual pause")
	scene._toggle_pause()
	scene._bind_world(Fixtures.defense_town())
	scene._inspect_site("town_hall")
	scene.hud.town_panel.talk_button.pressed.emit()
	test.check(panel.visible and panel.chapter_id == "ada_after" and not scene.hud.workspace.visible, "The Town Hall Talk action reaches Ada through the existing UI")
	panel.close_panel()
	scene.world.defense.begin(scene.world)
	var ticks: int = scene.world.ticks
	scene._open_story("ada_after")
	for i in range(4): await test.process_frame
	test.check(scene.world.ticks == ticks and scene.world.defense.warning == 150, "Reading a conversation freezes active defense warnings")
	panel.close_panel()
	scene._open_journal()
	var old_world = scene.world
	scene._bind_world(Fixtures.demo())
	test.check(not panel.visible and not old_world.story_requested.is_connected(scene._open_story), "Loading a world closes stale dialogue and disconnects old story listeners")
	for viewport_size in [Vector2i(1280, 800), Vector2i(1100, 720)]:
		test.root.content_scale_size = viewport_size
		test.root.size = viewport_size
		scene._open_journal()
		for i in range(3): await test.process_frame
		var center = panel.get_child(0)
		var frame = center.get_child(0)
		test.check(test.root.get_visible_rect().encloses(frame.get_global_rect()) and test.root.get_visible_rect().encloses(scene.hud.bottom.get_global_rect()), "Journal and expanded hotbar fit viewport %s" % viewport_size)
		panel.close_panel()
	scene.queue_free()
	await test.process_frame
	test.root.content_scale_size = Vector2i(1280, 800)
	test.root.size = Vector2i(1280, 800)