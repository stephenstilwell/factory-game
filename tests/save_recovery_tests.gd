extends RefCounted
const Fixtures = preload("res://tests/fixtures.gd")
const Saves = preload("res://scripts/persistence/save_service.gd")
const World = preload("res://scripts/simulation/world.gd")

static func run(test: SceneTree) -> void:
	var folder := "user://recovery_test_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_absolute(folder)
	var path := folder + "/factory.json"
	var world := Fixtures.industrial()
	world.start()
	world.ticks = 12000
	test.check(not Saves.describe(path).exists, "Recovery metadata handles absent saves")
	test.check(Saves.save_world(world, path).is_empty(), "Recovery fixture writes first save")
	world.ticks = 24000
	world.player.add("timber", 4)
	test.check(Saves.save_world(world, path).is_empty(), "Recovery fixture retains previous save")
	var primary_bytes := FileAccess.get_file_as_bytes(path)
	var backup_bytes := FileAccess.get_file_as_bytes(path + ".bak")
	var metadata := Saves.describe(path)
	test.check(metadata.valid and "World time 0h 40m" in metadata.summary and "Timber & Hearth" in metadata.summary, "Save metadata describes chapter and simulated time")
	var recovered := Saves.load_world(path + ".bak")
	test.check(recovered.error.is_empty() and recovered.world.ticks == 12000 and recovered.world.player.count("timber") == 0, "Backup loads the earlier world rather than the current world")
	test.check(primary_bytes == FileAccess.get_file_as_bytes(path) and backup_bytes == FileAccess.get_file_as_bytes(path + ".bak"), "Inspecting and recovering never rewrites either save")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("{damaged save")
	file.close()
	test.check(not Saves.describe(path).valid and Saves.describe(path + ".bak").valid, "Damaged primary and valid backup are reported separately")
	test.check(Saves.save_world(recovered.world, path).is_empty(), "A recovered world can become the new primary")
	test.check(backup_bytes == FileAccess.get_file_as_bytes(path + ".bak"), "Saving over a corrupt primary preserves the good backup")
	var archives := 0
	for entry in DirAccess.get_files_at(folder):
		if ".damaged." in entry:
			archives += 1
			test.check(FileAccess.get_file_as_string(folder + "/" + entry) == "{damaged save", "Damaged primary is preserved for manual recovery")
	test.check(archives == 1 and Saves.load_world(path).world.ticks == 12000, "Recovered primary is valid and damaged source is retained")
	await _ui(test, path)
	# All test files live under this unique, test-owned directory.
	for entry in DirAccess.get_files_at(folder): DirAccess.remove_absolute(folder + "/" + entry)
	DirAccess.remove_absolute(folder)

static func _ui(test: SceneTree, path: String) -> void:
	var dialog := preload("res://scripts/ui/save_recovery_dialog.gd").new()
	test.root.add_child(dialog)
	dialog.open(path)
	test.check(not dialog.get_ok_button().disabled and dialog.selected_path == path, "Recovery UI selects a valid primary by default")
	dialog.select(1)
	test.check(dialog.selected_path == path + ".bak" and dialog.choices[1].button_pressed, "Backup selection is explicit")
	var requested: Array = []
	dialog.load_selected.connect(func(source): requested.append(source))
	dialog.canceled.emit()
	test.check(requested.is_empty(), "Cancelling recovery does not load or write a world")
	dialog.confirmed.emit()
	test.check(requested == [path + ".bak"], "Confirmed recovery emits exactly the selected source")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("broken")
	file.close()
	dialog.open(path)
	test.check(dialog.choices[0].disabled and not dialog.choices[1].disabled and dialog.selected_path == path + ".bak", "Recovery UI guides the player to a healthy backup when primary is damaged")
	file = FileAccess.open(path + ".bak", FileAccess.WRITE)
	file.store_string("also broken")
	file.close()
	dialog.open(path)
	test.check(dialog.get_ok_button().disabled and dialog.selected_path.is_empty(), "No valid saves means loading is disabled")
	dialog.queue_free()
	await test.process_frame
