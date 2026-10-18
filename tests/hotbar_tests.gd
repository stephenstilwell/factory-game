extends RefCounted
const Layout = preload("res://scripts/ui/hotbar_layout.gd")
const Fixtures = preload("res://tests/fixtures.gd")

static func run(test: SceneTree) -> void:
	var path := "user://hotbar_test_%d.cfg" % Time.get_ticks_usec()
	var layout := Layout.new(path)
	test.check(layout.pages.size() == 2 and layout.pages[0].size() == 10 and layout.item(0, 2) == "furnace", "Hotbar defaults retain familiar number positions with ten stable slots")
	test.check(not layout.assign(0, 10, "drill") and not layout.assign(0, 0, "iron_plate"), "Hotbar layout rejects invalid slots and non-building IDs")
	test.check(layout.assign(1, 9, "turret") and layout.save() == OK, "A second hotbar page can persist a defense building")
	layout.active_page = 1
	layout.save()
	var loaded := Layout.new(path)
	test.check(loaded.active_page == 1 and loaded.item(1, 9) == "turret", "Shortcut assignments and selected page survive relaunch")
	var revision: int = layout.revision
	test.check(layout.swap(0, 2, 1, 9, revision) and layout.item(0, 2) == "turret" and layout.item(1, 9) == "furnace", "Dragging between pages swaps shortcuts without losing either")
	test.check(not layout.swap(0, 0, 0, 1, revision), "Stale drag data cannot overwrite a changed layout")
	var corrupt := ConfigFile.new()
	corrupt.set_value("hotbar", "page_0", ["missing", "iron_plate", "", "drill", "", "", "", "", "", ""])
	corrupt.set_value("hotbar", "page_1", "invalid")
	corrupt.set_value("hotbar", "active_page", 999)
	corrupt.save(path)
	var repaired := Layout.new(path)
	test.check(repaired.item(0, 0).is_empty() and repaired.item(0, 1).is_empty() and repaired.item(0, 3) == "drill" and repaired.active_page == 1, "Malformed hotbar preferences are safely sanitized")

	var scene = load("res://main.tscn").instantiate()
	test.root.add_child(scene)
	var bar = scene.hud.hotbar
	bar.layout = Layout.new(path + ".ui")
	scene._bind_world(Fixtures.demo())
	test.check(bar.layout.settings_path == path + ".ui", "World binding preserves the injected hotbar preference file")
	scene.paused = true
	scene.world.player_position = Vector2(19.5, 17.5)
	var stock: Dictionary = scene.world.player.contents.duplicate()
	bar.assign(0, "furnace")
	test.check(bar.slots[0].tooltip_text.contains("Smelts iron and copper ore") and bar.slots[0].tooltip_text.contains("in pack"), "Hotbar hover explains building purpose alongside stock and controls")
	var key := InputEventKey.new()
	key.keycode = KEY_1
	key.pressed = true
	scene._unhandled_input(key)
	test.check(scene.selected_kind == "furnace" and scene.world.player.contents == stock, "Number keys follow customized shortcuts without consuming items")
	bar.open_picker(9)
	test.check(bar.picker.visible and not scene.hud.world_has_pointer(), "The assignment picker blocks world interactions")
	test.check(bar.choices.furnace.visible and bar.choices.drill.visible, "Opening the picker with an empty search shows discovered buildings")
	bar.search.text = "furnace"
	bar.refresh_choices()
	test.check(bar.choices.furnace.visible and not bar.choices.drill.visible, "The building picker searches discovered buildings")
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	scene._input(escape)
	test.check(not bar.picker.visible and not scene.hud.pause_menu.visible, "Escape dismisses assignment before opening pause")
	var drag := {"type": "inventory_item", "item": "drill", "source": {"kind": "player"}, "world": scene.world.get_instance_id()}
	test.check(bar.can_drop(drag), "Pack building drags can create shortcuts")
	bar.drop_on(9, drag)
	test.check(bar.layout.item(0, 9) == "drill" and scene.world.player.contents == stock, "Dragging a building to the hotbar copies a reference and conserves all inventory")
	drag.world = -1
	test.check(not bar.can_drop(drag), "Inventory drags from an old world cannot change shortcuts")
	var stale := {"type": "hotbar_shortcut", "owner": bar.get_instance_id(), "page": 0, "slot": 0, "revision": bar.layout.revision}
	bar.drop_on(1, stale)
	test.check(bar.layout.item(0, 1) == "furnace" and not bar.can_drop(stale), "Hotbar slot drags swap assignments and invalidate old drag payloads")
	bar.assign(8, "")
	bar.activate(8)
	test.check(bar.picker.visible, "Clicking an empty slot opens assignment instead of doing nothing")
	bar.close_picker()
	var tab := InputEventKey.new()
	tab.keycode = KEY_TAB
	tab.pressed = true
	scene._unhandled_input(tab)
	test.check(bar.layout.active_page == 1, "Tab switches the active hotbar page")
	scene._select("furnace")
	key.alt_pressed = true
	scene._unhandled_input(key)
	test.check(bar.layout.item(1, 0) == "furnace", "Alt-number pins the current building to that page")
	scene.hud.toggle_inventory()
	key.alt_pressed = false
	scene._unhandled_input(key)
	test.check(scene.hud.workspace.visible and scene.selected_kind == "furnace", "Number keys in inventory do not select world tools")
	scene.hud.close_workspace()
	scene._bind_world(Fixtures.industrial())
	Fixtures.begin_lessons(scene.world)
	bar.refresh(scene.world, "")
	test.check(not bar.assign(0, "turret") and not bar.available("turret"), "Custom shortcuts cannot bypass restoration or research")
	for viewport_size in [Vector2i(1280, 800), Vector2i(1100, 720)]:
		test.root.content_scale_size = viewport_size
		test.root.size = viewport_size
		for i in range(3): await test.process_frame
		test.check(test.root.get_visible_rect().encloses(scene.hud.bottom.get_global_rect()), "Ten-slot hotbar fits viewport %s" % viewport_size)
	var ui_path: String = bar.layout.settings_path
	scene.queue_free()
	await test.process_frame
	test.root.content_scale_size = Vector2i(1280, 800)
	test.root.size = Vector2i(1280, 800)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(ui_path))