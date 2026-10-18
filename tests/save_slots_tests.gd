extends RefCounted
const Fixtures = preload("res://tests/fixtures.gd")
const World = preload("res://scripts/simulation/world.gd")
const Saves = preload("res://scripts/persistence/save_service.gd")
const Slots = preload("res://scripts/persistence/save_slots.gd")
static func run(test: SceneTree) -> void:
	var folder := "user://slot_test_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_absolute(folder)
	var base := folder + "/factory.json"
	var path := Slots.slot_path(base, 2)
	test.check(Slots.base_path(path + ".auto.json.bak") == base and Slots.index_for(path) == 2, "Fixed save slots map recovery paths to their factory")
	test.check(not Slots.autosave_enabled(path), "Autosave defaults off")
	test.check(Slots.rename(base, 2, "  Orchard town  ") == OK and Slots.label(base, 2) == "Orchard town", "Factory slot names persist separately from save paths")
	test.check(Slots.set_autosave(path, true) == OK and Slots.autosave_enabled(path) and not Slots.autosave_enabled(base), "Autosave preferences belong to individual factory slots")
	var world := Fixtures.industrial()
	world.start()
	Saves.save_world(world, base)
	world.ticks = 100
	Saves.save_world(world, path)
	world.ticks = 200
	Saves.save_world(world, path)
	var manual := FileAccess.get_file_as_bytes(path)
	var backup := FileAccess.get_file_as_bytes(path + ".bak")
	world.ticks = 300
	Saves.save_world(world, path + ".auto.json")
	test.check(FileAccess.get_file_as_bytes(path) == manual and FileAccess.get_file_as_bytes(path + ".bak") == backup and Saves.load_world(base).world.ticks == 0, "Autosaving leaves manual saves, backups and other slots unchanged")
	var dialog := preload("res://scripts/ui/save_recovery_dialog.gd").new()
	test.root.add_child(dialog)
	dialog.open(path)
	test.check(dialog.slot_picker.item_count == 4 and dialog.slot_picker.selected == 2 and dialog.records[2].valid, "Load picker shows named slots and separate autosave recovery")
	dialog.select(2)
	test.check(dialog.selected_path == path + ".auto.json", "Autosave recovery selection is explicit")
	dialog.hide()
	dialog.open(base, true)
	dialog.slot_picker.select(3)
	dialog.slot_picker.item_selected.emit(3)
	test.check(dialog.selected_slot_path == Slots.slot_path(base, 3) and not dialog.get_ok_button().disabled, "An empty slot can receive an explicit Save as")
	var requests: Array = []
	dialog.save_selected.connect(func(target, title): requests.append([target, title]))
	dialog.slot_name.text = "Quarry experiment"
	dialog.confirmed.emit()
	test.check(requests == [[Slots.slot_path(base, 3), "Quarry experiment"]] and not FileAccess.file_exists(Slots.slot_path(base, 3)), "Save confirmation emits one fixed destination without writing from the dialog")
	dialog.queue_free()
	await test.process_frame
	for entry in DirAccess.get_files_at(folder): DirAccess.remove_absolute(folder + "/" + entry)
	DirAccess.remove_absolute(folder)
