extends RefCounted
const World = preload("res://scripts/simulation/world.gd")
const Saves = preload("res://scripts/persistence/save_service.gd")
const Fixtures = preload("res://tests/fixtures.gd")

static func run(test: SceneTree) -> void:
	var world := World.new(12345)
	world.start()
	var initial := Saves.encode(world)
	var loaded := Saves.decode(JSON.parse_string(JSON.stringify(initial)))
	test.check(initial.version == 3 and loaded.error.is_empty() and Saves.encode(loaded.world) == initial, "Fresh timber worlds roundtrip in the sole supported save format")
	for version in [1, 2, 99]:
		var obsolete := initial.duplicate(true)
		obsolete.version = version
		var result := Saves.decode(obsolete)
		test.check(not result.has("world") and result.error.contains("new world"), "Unsupported format %d reports a fresh-start requirement" % version)
	for section in ["early", "onboarding", "settlements", "frontier", "combat", "home"]:
		var incomplete := initial.duplicate(true)
		incomplete.erase(section)
		test.check(not Saves.decode(incomplete).has("world"), "Missing %s is rejected instead of installed or defaulted" % section)
	var disabled := initial.duplicate(true)
	disabled.early.enabled = false
	test.check(not Saves.decode(disabled).has("world"), "Disabled legacy opening cannot enter the supported save path")
	test.check(Saves.encode(world) == initial, "Rejected saves never mutate the live playtest world")
	var factory := Fixtures.demo()
	factory.player.add("timber", 8)
	factory.player.add("stone", 2)
	test.check(factory.craft("lumber_camp"), "Current industrial factories retain dependency-aware forestry crafts")
	for i in range(7): preload("res://scripts/simulation/simulation.gd").step(factory)
	var snapshot := Saves.encode(factory)
	loaded = Saves.decode(JSON.parse_string(JSON.stringify(snapshot)))
	test.check(loaded.error.is_empty(), "Current machine work and reserved crafts load together")
	if loaded.error.is_empty():
		for i in range(100):
			preload("res://scripts/simulation/simulation.gd").step(factory)
			preload("res://scripts/simulation/simulation.gd").step(loaded.world)
		test.check(Saves.encode(factory) == Saves.encode(loaded.world), "Current format continues factory work and craft dependencies deterministically")
