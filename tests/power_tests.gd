extends RefCounted
const Fixtures = preload("res://tests/fixtures.gd")
const World = preload("res://scripts/simulation/world.gd")
const Simulation = preload("res://scripts/simulation/simulation.gd")
const Saves = preload("res://scripts/persistence/save_service.gd")
static func setup() -> RefCounted:
	var world := Fixtures.industrial()
	Fixtures.begin_lessons(world)
	world.guide.enabled = false
	world.researched = ["logistics", "metallurgy"]
	world.player_position = Vector2(10.5, 9.5)
	world.previous_position = world.player_position
	return world
static func run(test: SceneTree) -> void:
	var world := setup()
	var generator = world.spawn("generator", Vector2i(9, 9), 0)
	generator.inventory.add("coal", 1)
	world.spawn("power_pole", Vector2i(10, 9), 0)
	var furnace = world.spawn("furnace", Vector2i(11, 9), 0)
	world.player.contents = {"steel": 2, "wire": 4}
	test.check(world.power.retrofit(world, furnace) and world.player.total() == 0 and not world.power.retrofit(world, furnace), "Drive installation spends exact materials once")
	furnace.inventory.add("iron_ore", 2)
	furnace.inventory.add("coal", 2)
	test.advance(world, 16)
	test.check(furnace.output.count("iron_plate") == 1 and generator.energy == 2336 and generator.inventory.total() == 0, "Electric furnace doubles work with conserved generator energy")
	test.check(furnace.inventory.count("coal") == 2 and furnace.burn_ticks == 0 and not world.accepts(furnace, "coal"), "Electric drives never consume or accept burner fuel")
	var saved := Saves.decode(JSON.parse_string(JSON.stringify(Saves.encode(world))))
	test.check(saved.error.is_empty() and saved.world.entities[generator.id].energy == generator.energy and saved.world.entities[furnace.id].electric_mode, "Generator reserves and installed drives survive save validation")
	if saved.error.is_empty():
		test.advance(world, 16)
		test.advance(saved.world, 16)
		test.check(Saves.encode(world) == Saves.encode(saved.world), "Loaded power networks continue deterministically")
	var energy: int = generator.energy
	test.advance(world, 8)
	test.check(generator.energy == energy, "Idle machines draw no energy or coal")
	furnace.output.contents = {"iron_plate": 10}
	furnace.inventory.add("iron_ore", 1)
	test.advance(world, 4)
	test.check(generator.energy == energy, "Full output stalls before spending generator energy")
	world.damage_structure(Vector2i(10, 9), 1000)
	furnace.output.contents.clear()
	test.advance(world, 2)
	test.check(furnace.status.begins_with("Disconnected") and generator.energy == energy, "Destroyed poles disconnect consumers without spending stored energy")
	world.player_position = Vector2(9.5, 8.5)
	world.previous_position = world.player_position
	world.player.add("repair_kit", 1)
	world.repair_at(Vector2i(10, 9))
	test.advance(world, 1)
	test.check(furnace.progress == 2 and generator.energy == energy - 4, "Repairing a pole rebuilds connectivity and resumes work")
	var invalid := Saves.encode(world)
	invalid.entities[0].energy = 2401
	test.check(not Saves.decode(invalid).error.is_empty(), "Out-of-range generator energy is rejected")
	invalid = Saves.encode(world)
	invalid.entities[1].electric_mode = true
	test.check(not Saves.decode(invalid).error.is_empty(), "Electric drives on poles are rejected")
	var split := setup()
	var source = split.spawn("generator", Vector2i(0, 0), 0)
	source.inventory.add("coal", 2)
	split.spawn("power_pole", Vector2i(1, 0), 0)
	split.spawn("power_pole", Vector2i(7, 0), 0)
	var remote = split.spawn("assembler", Vector2i(8, 0), 0)
	remote.electric_mode = true
	remote.inventory.add("iron_plate", 4)
	test.advance(split, 1)
	test.check(remote.progress == 2, "Six-tile pole links carry power to distant districts")
	split.damage_structure(Vector2i(7, 0), 1000)
	test.advance(split, 1)
	test.check(remote.progress == 2 and remote.status.begins_with("Disconnected"), "Removing a bridge splits the network")
	var brownout := setup()
	var supply = brownout.spawn("generator", Vector2i(10, 10), 0)
	supply.inventory.add("coal", 2)
	brownout.spawn("power_pole", Vector2i(11, 10), 0)
	var machines: Array = []
	for cell in [Vector2i(11, 9), Vector2i(12, 10), Vector2i(11, 11)]:
		var machine = brownout.spawn("assembler", cell, 0)
		machine.electric_mode = true
		machine.inventory.add("iron_plate", 20)
		machines.append(machine)
	test.advance(brownout, 3)
	test.check(machines.all(func(machine): return machine.progress == 4) and supply.energy == 2382, "Brownouts rotate fairly and never exceed generator throughput")
	var reserve: int = supply.energy
	var outputs: int = machines[0].output.total()
	brownout.player_position = Vector2(11.5, 9.5)
	brownout.previous_position = brownout.player_position
	test.check(brownout.reclaim(machines[0].cell) and brownout.player.count("steel") == 2 and brownout.player.count("wire") == 4 and brownout.player.count("assembler") == 1, "Pickup returns physical drive materials with the machine")
	test.check(supply.energy == reserve and outputs == 0, "Pickup cannot refund spent generator energy")
	var locked := setup()
	locked.researched.clear()
	var machine = locked.spawn("assembler", Vector2i(10, 9), 0)
	locked.player.contents = {"steel": 2, "wire": 4}
	test.check(not locked.power.retrofit(locked, machine) and locked.player.total() == 6, "Unresearched retrofits cannot spend materials")
	var chute := setup()
	var chute_generator = chute.spawn("generator", Vector2i(13, 17), 0)
	chute_generator.inventory.add("coal", 1)
	chute.spawn("power_pole", Vector2i(14, 17), 0)
	var drill = chute.spawn("drill", Vector2i(14, 16), 0)
	drill.electric_mode = true
	drill.output.add("iron_ore", drill.output.capacity)
	chute.spawn("belt", Vector2i(15, 16), 0)
	test.advance(chute, 1)
	test.check(drill.output.total() == 9 and drill.progress == 0 and chute_generator.inventory.count("coal") == 1, "A newly emptied drill chute cannot advance without allocated power")
	test.advance(chute, 1)
	test.check(drill.progress == 2 and chute_generator.energy == 2398, "Unblocked drill resumes with an exact paid work tick")
	var research := setup()
	research.select_research("routing")
	research.research_progress = 19
	var dynamo = research.spawn("generator", Vector2i(10, 10), 0)
	dynamo.inventory.add("coal", 1)
	research.spawn("power_pole", Vector2i(11, 10), 0)
	var benches: Array = []
	for position in [Vector2i(11, 9), Vector2i(12, 10)]:
		var bench = research.spawn("lab", position, 0)
		bench.electric_mode = true
		bench.progress = 28
		bench.inventory.add("science", 1)
		benches.append(bench)
	test.advance(research, 1)
	test.check("routing" in research.researched and dynamo.energy == 2398 and benches[1].inventory.count("science") == 1, "A bench made idle by research completion never consumes reserved energy")
