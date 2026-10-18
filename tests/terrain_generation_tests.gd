extends RefCounted
const Fixtures = preload("res://tests/fixtures.gd")
const Terrain = preload("res://scripts/model/terrain.gd")
const World = preload("res://scripts/simulation/world.gd")
const Saves = preload("res://scripts/persistence/save_service.gd")

static func run(test: SceneTree) -> void:
	for seed_value in [0, 1, 74103, -2000000000, 2000000000]:
		var a := Fixtures.industrial(seed_value)
		Fixtures.begin_lessons(a)
		var b := Fixtures.industrial(seed_value)
		Fixtures.begin_lessons(b)
		test.check(a.player.total() == 0, "New generation preserves an empty guided start")
		for patch in Terrain.START_PATCHES:
			test.check(a.terrain.tile(patch[0]).get("item") == patch[2], "Every seed guarantees each tutorial resource at its anchor")
		var resources: Dictionary = {}
		var order_independent := true
		for patch in a.terrain._frontier_patches(Vector2i(-2, 3)):
			resources[patch[2]] = true
			# Generate neighboring chunks in different orders before comparing patch stock.
			var center: Vector2i = patch[0]
			b.terrain.tile(center + Vector2i(16, 0))
			for x in range(center.x - 16, center.x + 17):
				for y in range(center.y - 16, center.y + 17):
					var cell := Vector2i(x, y)
					if a.terrain.tile(cell) != b.terrain.tile(cell): order_independent = false
			test.check(int(a.terrain.tile(center).get("amount", 0)) >= 450, "Frontier patch centers contain substantial finite ore")
		test.check(resources.size() == 4, "Every frontier region supplies all four resource types")
		test.check(order_independent, "Positive and negative chunk generation is independent of visit order")
	var a := Fixtures.industrial(123)
	Fixtures.begin_lessons(a)
	var b := Fixtures.industrial(456)
	Fixtures.begin_lessons(b)
	test.check(a.terrain._frontier_patches(Vector2i(3, 2)) != b.terrain._frontier_patches(Vector2i(3, 2)), "Different seeds change frontier locations and resource assignments")
	var rich_patch: Array = a.terrain._frontier_patches(Vector2i(10, 10))[0]
	var rich_cell: Vector2i = rich_patch[0]
	test.check(a.terrain.tile(rich_cell).amount >= 2250 and rich_patch[1] >= 10, "Distant patches are richer and larger than nearby frontier deposits")
	var mined := 0
	while not a.terrain.tile(rich_cell).is_empty():
		a.terrain.mine(rich_cell)
		mined += 1
	a.terrain.chunks.clear()
	test.check(mined >= 2250 and a.terrain.tile(rich_cell).is_empty(), "Even rich deposits exhaust and stay empty after cache eviction")
	var partial: Vector2i = rich_cell + Vector2i.RIGHT
	a.terrain.mine(partial)
	var restored: Dictionary = Saves.decode(JSON.parse_string(JSON.stringify(Saves.encode(a))))
	test.check(restored.error.is_empty() and restored.world.terrain.tile(rich_cell).is_empty() and restored.world.terrain.tile(partial) == a.terrain.tile(partial), "New generator, exhausted ore, and high remaining counts survive JSON saves")
	var obsolete := Saves.encode(a)
	obsolete.version = 2
	test.check(not Saves.decode(obsolete).error.is_empty(), "Old world formats are rejected instead of switching terrain generators")
	var found: Dictionary = a.terrain.find_resource("iron_ore", Vector2i(24, 12))
	test.check(not found.is_empty() and found.remaining > 0 and a.terrain.tile(found.cell).item == "iron_ore", "Survey reports actual remaining material at a reachable world coordinate")
	# Exhaust the entire starting iron patch; the next survey must find a frontier patch.
	for x in range(10, 19):
		for y in range(12, 21):
			var cell := Vector2i(x, y)
			var data: Dictionary = a.terrain.tile(cell)
			if data.get("item") == "iron_ore": a.terrain.depleted[cell] = 0
	var replacement: Dictionary = a.terrain.find_resource("iron_ore", Vector2i(24, 12))
	test.check(not replacement.is_empty() and replacement.distance > 20 and a.terrain.tile(replacement.cell).item == "iron_ore", "Exhausting the starter patch still leaves a discoverable finite frontier source")
	test.check(a.terrain.find_resource("made_up_ore", Vector2i.ZERO).is_empty(), "Survey rejects unknown resources")
