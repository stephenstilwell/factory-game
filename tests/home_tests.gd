extends RefCounted
const World = preload("res://scripts/simulation/world.gd")
const Fixtures = preload("res://tests/fixtures.gd")
const Saves = preload("res://scripts/persistence/save_service.gd")
static func setup() -> RefCounted:
	var world := Fixtures.defense_town(false)
	Fixtures.install_frontier(world)
	world.player.contents = {"timber": 80, "plank": 160, "stone": 100, "iron_plate": 20, "wire": 20, "foraged_food": 20}
	world.player_position = Vector2(19.5, 30.5)
	world.previous_position = world.player_position
	world.home.make_kit(world)
	world.build("cottage", Vector2i(20, 30), 0)
	return world
static func run(test: SceneTree) -> void:
	var fresh := Fixtures.industrial()
	fresh.start()
	test.check(not fresh.home.make_kit(fresh) and fresh.player.total() == 0, "Empty-start cottage remains optional and gated behind shelter restoration")
	fresh.early.phase = 1
	test.check(fresh.content_available("cottage"), "Cottage construction unlocks in Stone and Water before metal industry")
	var world := setup()
	var home: RefCounted = world.home
	var entrance = world.at(Vector2i(20, 30))
	test.check(entrance != null and world.player.count("timber") == 68 and world.player.count("plank") == 148 and world.player.count("stone") == 92, "Cottage construction consumes exact physical kit materials")
	test.check(not world.can_build("cottage", Vector2i(21, 30), false).is_empty(), "A world cannot place duplicate cottage entrances")
	test.check(not home.make(world, "chair") and home.enter(world, entrance.id), "Furnishing commands require a real reachable cottage instance")
	var planks: int = world.player.count("plank")
	test.check(home.make(world, "chair") and world.player.count("plank") == planks - 3 and home.stock.chair == 1, "Furniture manufacture spends actual pack resources")
	test.check(not home.undo(world) and world.player.count("plank") == planks - 3, "Undo never crosses a manufacturing transaction")
	test.check(home.place(world, "chair", Vector2i(1, 1), 1) and not home.stock.has("chair"), "Placing a rotated furnishing consumes an owned piece")
	test.check(home.undo(world) and home.pieces.is_empty() and home.stock.chair == 1 and home.undo(world, true), "Room undo and redo conserve furnishing ownership")
	home.make(world, "bed")
	test.check(not home.place(world, "bed", Vector2i(1, 1), 0) and not home.place(world, "bed", Vector2i(9, 7), 0) and not home.place(world, "bed", Vector2i(4, 6), 0), "Overlap, room bounds and blocked doorway reject placement without spending furniture")
	test.check(home.place(world, "bed", Vector2i(2, 2), 0), "Multi-tile furniture occupies its full footprint")
	home.make(world, "rug")
	test.check(home.place(world, "rug", Vector2i(2, 2), 0) and home.pickup(world, Vector2i(2, 2)) == "bed" and home.pieces.size() == 2, "Rugs sit underneath furniture and pickup selects the upper layer")
	test.check(home.undo(world) and home.at(Vector2i(3, 3)) >= 0, "Pickup can be undone without touching factory stock")
	test.check(not home.finish(world, 1, 0), "Regional room finishes require actual discoveries")
	world.frontier.sites.orchard.discovered = true
	world.frontier.sites.orchard.claimed = true
	test.check(home.finish(world, 1, 1), "Recovered Orchard unlocks free green room finishes")
	var before: Dictionary = Saves.encode(world)
	var loaded := Saves.decode(JSON.parse_string(JSON.stringify(before)))
	test.check(loaded.error.is_empty() and loaded.world.home.serialize() == home.serialize() and loaded.world.home.active_entry == 0 and loaded.world.home.undo_stack.is_empty(), "Interior saves preserve exact furniture, stock and finishes; loading stays outside with fresh history")
	home.leave()
	test.check(not home.place(world, "bed", Vector2i(6, 2), 0), "Leaving revokes room editing commands")
	test.check(world.reclaim(entrance.cell) and world.home.serialize() == before.home, "Moving a cottage entrance preserves the complete interior")
	world.build("cottage", Vector2i(19, 29), 0)
	test.check(home.enter(world, world.at(Vector2i(19, 29)).id) and home.pieces.size() == 3, "Relocated cottage opens the same room")
	var malformed := Saves.encode(world)
	malformed.home.pieces.append(malformed.home.pieces[0].duplicate())
	test.check(not Saves.decode(malformed).error.is_empty(), "Overlapping saved furnishings are rejected")
	malformed = Saves.encode(world)
	malformed.home.stock.chair = 0.5
	test.check(not Saves.decode(malformed).error.is_empty(), "Fractional furnishing counts are rejected")
	malformed = Saves.encode(world)
	malformed.erase("home")
	test.check(not Saves.decode(malformed).error.is_empty(), "Incomplete or obsolete saves are rejected without migration")
static func ui(test: SceneTree) -> void:
	var scene = load("res://main.tscn").instantiate()
	test.root.add_child(scene)
	await test.process_frame
	scene.set_process(false)
	scene.audio.set_process(false)
	scene.hud.story_panel.dismiss_silently()
	var world := setup()
	scene.save_path = "user://home_ui_test_%d.json" % Time.get_ticks_usec()
	scene._bind_world(world)
	scene.paused = false
	scene.hud.inspect(world.at(Vector2i(20, 30)))
	scene.hud.inspector.home_button.pressed.emit()
	test.check(scene.hud.home_panel.visible and scene.paused and not scene.hud.world_has_pointer(), "Cottage entrance opens a separate room and pauses world interaction")
	var ticks: int = world.ticks
	scene._process(1.0)
	test.check(world.ticks == ticks, "Time, factories and defenses do not advance while decorating")
	var panel = scene.hud.home_panel
	panel.selected = "table"
	panel.refresh()
	panel.make_button.pressed.emit()
	panel.room.room_clicked.emit(Vector2i(1, 1), false)
	test.check(world.home.pieces.size() == 1 and world.home.pieces[0].kind == "table", "Actual room buttons manufacture and place owned furniture")
	panel.save_requested.emit()
	test.check(FileAccess.file_exists(scene.save_path) and panel.hint.text == "Cottage and factory saved.", "Saving inside the cottage persists room edits and confirms visibly")
	DirAccess.remove_absolute(scene.save_path)
	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_R
	scene._input(key)
	test.check(panel.direction == 1 and scene.facing == 0, "Room rotation does not rotate outdoor building controls")
	key.ctrl_pressed = true
	key.keycode = KEY_Z
	scene._input(key)
	test.check(world.home.pieces.is_empty(), "Ctrl+Z in the cottage routes to furniture history")
	key.ctrl_pressed = false
	key.keycode = KEY_ESCAPE
	scene._input(key)
	test.check(not panel.visible and not scene.paused and world.home.active_entry == 0, "Leaving restores the player's previous running state")
	scene.paused = true
	scene.hud.inspect(world.at(Vector2i(20, 30)))
	scene.hud.inspector.home_button.pressed.emit()
	scene._leave_home()
	test.check(scene.paused, "A previously paused game remains paused after leaving home")
	scene.queue_free()
	await test.process_frame
