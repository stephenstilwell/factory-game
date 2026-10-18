extends RefCounted
const Fixtures = preload("res://tests/fixtures.gd")
const World = preload("res://scripts/simulation/world.gd")
const Saves = preload("res://scripts/persistence/save_service.gd")

static func run(test: SceneTree) -> void:
	var world := Fixtures.industrial()
	world.start()
	var cell := Vector2i.ZERO
	for y in range(60, 100):
		for x in range(60, 100):
			if world.frontier.tree_at(world, Vector2i(x, y)):
				cell = Vector2i(x, y)
				break
		if cell != Vector2i.ZERO: break
	var forestry = world.frontier.forestry
	var gate_camp = world.spawn("lumber_camp", cell + Vector2i(2, 0), 0)
	world.player_position = Vector2(gate_camp.cell) + Vector2(0.5, 1.5)
	test.check(forestry.replant(world, gate_camp) == 0, "Manual replanting requires the shelter milestone")
	gate_camp.health = 0
	for i in range(5): test.check(forestry.harvest(world, cell), "A mature tree supports repeated harvests")
	test.check(world.frontier.tree_at(world, cell) and not world.frontier.cleared.has(cell), "Five camp harvests preserve the tree and do not permanently clear land")
	test.check(forestry.harvest(world, cell) and forestry.growing(world, cell) and not forestry.harvest(world, cell), "Sixth harvest leaves an unavailable stump")
	world.ticks += 2400
	forestry.step(world)
	test.check(forestry.growing(world, cell) and forestry.plots[cell].ready == -1, "Timber age stumps wait for the shelter rather than regrowing for free")
	var encoded := Saves.encode(world)
	var loaded := Saves.decode(JSON.parse_string(JSON.stringify(encoded)))
	test.check(loaded.error.is_empty() and Saves.encode(loaded.world) == encoded, "Partial harvests and waiting stumps roundtrip in an early save")
	world.early.phase = 1
	world.settlements.age = 1
	world.early.delivered = 8
	world.production.timber = 8
	forestry.step(world)
	test.check(forestry.plots[cell].ready == world.ticks + 1200, "Shelter unlock replants existing camp stumps")
	var before: Dictionary = Saves.encode(world)
	var coverage: Dictionary = forestry.coverage(world, cell)
	forestry.describe(world, cell)
	forestry.growth(world, cell)
	test.check(coverage.growing > 0 and Saves.encode(world) == before, "Coverage and growth UI are read-only")
	world.ticks += 600
	test.check(is_equal_approx(forestry.growth(world, cell), 0.5) and not world.frontier.tree_at(world, cell), "Saplings visibly grow halfway through two minute recovery")
	encoded = Saves.encode(world)
	loaded = Saves.decode(JSON.parse_string(JSON.stringify(encoded)))
	test.check(loaded.error.is_empty() and Saves.encode(loaded.world) == encoded, "Active regrowth survives save/load exactly")
	world.ticks += 600
	test.check(world.frontier.tree_at(world, cell) and forestry.harvest(world, cell) and forestry.plots[cell].cuts == 1, "Mature regrowth starts a fresh six-harvest cycle")
	test.check(world.frontier.clear_tree(world, cell, false), "Player clearing can permanently remove a managed tree")
	world.ticks += 5000
	test.check(not world.frontier.tree_at(world, cell) and not forestry.plots.has(cell), "Hand-cleared ground never regrows automatically")
	var camp_cell := cell + Vector2i(1, 0)
	var camp = world.spawn("lumber_camp", camp_cell, 0)
	world.player_position = Vector2(camp_cell) + Vector2(0.5, 1.5)
	test.check(forestry.replant(world, camp) >= 1 and forestry.growing(world, cell), "Explicit replanting can recover old cleared groves")
	world.frontier.clear_tree(world, cell, false)
	var occupied = world.spawn("cart_post", cell, 0)
	test.check(forestry.replant(world, camp) == 0 and not forestry.plots.has(cell), "Replanting excludes buildings and preserves settled ground")
	world.entities.erase(occupied.id)
	world.occupancy.erase(cell)
	world.by_kind.cart_post.erase(occupied.id)
	forestry.replant(world, camp)
	test.check(world.frontier.clear_tree(world, cell, false) and not forestry.plots.has(cell), "Construction can clear a growing sapling permanently")
	encoded = Saves.encode(world)
	var corrupt: Dictionary = encoded.duplicate(true)
	corrupt.frontier.forestry = [[cell.x, cell.y, 0, world.ticks + 1200]]
	test.check(not Saves.decode(corrupt).error.is_empty(), "Save validation rejects plots on permanently cleared ground")
	corrupt = encoded.duplicate(true)
	corrupt.frontier.forestry = [[999999, 999999, 8, 0]]
	test.check(not Saves.decode(corrupt).error.is_empty(), "Save validation rejects malformed harvest counters")
	encoded.frontier.erase("forestry")
	loaded = Saves.decode(JSON.parse_string(JSON.stringify(encoded)))
	test.check(not loaded.error.is_empty(), "Missing forestry state is rejected without reconstruction")

	# Two camps share the same authoritative plot; no duplicate tree budgets.
	world.frontier.cleared.erase(cell)
	for i in range(6): forestry.harvest(world, cell)
	test.check(not forestry.harvest(world, cell), "Overlapping camps cannot harvest a depleted shared tree")
	camp.output.contents.clear()
	world.frontier.forestry.plots.clear()
	world.frontier.forestry.awaiting_planting = false
	# An actual camp preserves throughput while harvesting gradually.
	world.ticks = 10000
	for i in range(40): world.early.step(world); world.ticks += 1
	test.check(camp.output.count("timber") == 4, "Live camp produces four timber per four seconds")
	camp.output.contents.clear()
	for i in range(40): world.early.step(world); world.ticks += 1
	test.check(camp.output.count("timber") == 4, "Repeated production keeps the original timber rate")
	camp.output.contents = {"timber": 40}
	var locked := forestry.serialize()
	for i in range(80): world.early.step(world); world.ticks += 1
	test.check(forestry.serialize() == locked, "Full output pauses harvesting without consuming trees")
	var snapshots := Saves.encode(world)
	loaded = Saves.decode(JSON.parse_string(JSON.stringify(snapshots)))
	test.check(loaded.error.is_empty() and Saves.encode(loaded.world) == snapshots, "Operating forestry camps save and load with work intact")
	# Six shared tree plots support several full harvest/regrowth cycles.
	var sustainable := Fixtures.industrial()
	sustainable.start()
	sustainable.early.phase = 1
	sustainable.settlements.age = 1
	var trees: Array[Vector2i] = []
	for y in range(60, 100):
		for x in range(60, 100):
			var tree_cell := Vector2i(x, y)
			if sustainable.frontier.tree_at(sustainable, tree_cell): trees.append(tree_cell)
			if trees.size() == 6: break
		if trees.size() == 6: break
	var successes := 0
	for i in range(180):
		sustainable.ticks += 40
		if sustainable.frontier.forestry.harvest_from(sustainable, trees): successes += 1
	test.check(successes == 180, "Six trees maintain uninterrupted four-second harvests for twelve minutes")
	var young := trees[0]
	for i in range(6):
		if sustainable.frontier.forestry.growing(sustainable, young): break
		sustainable.frontier.forestry.harvest(sustainable, young)
	var timber_before: int = sustainable.player.count("timber")
	var xp_before: int = sustainable.skills.xp.mining
	sustainable.player_position = Vector2(young) + Vector2(0.5, 1.5)
	sustainable.mining_cell = young
	sustainable.mining = true
	for i in range(100): preload("res://scripts/simulation/simulation.gd").step(sustainable)
	test.check(sustainable.frontier.cleared.has(young) and sustainable.player.count("timber") == timber_before and sustainable.skills.xp.mining == xp_before, "Clearing saplings removes them without timber or XP farming")

