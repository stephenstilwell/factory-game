extends RefCounted
const Fixtures = preload("res://tests/fixtures.gd")
const World = preload("res://scripts/simulation/world.gd")
const Simulation = preload("res://scripts/simulation/simulation.gd")
const Saves = preload("res://scripts/persistence/save_service.gd")

static func stock(world: RefCounted) -> void:
	world.player.contents = {"iron_plate": 500, "gear": 200, "copper_plate": 100, "wire": 100, "steel": 100}

static func run(test: SceneTree) -> void:
	var world := Fixtures.industrial()
	stock(world)
	test.check(world.character.stat("movement_speed") == 4.0 and world.mining_duration() == 8 and world.interaction_reach() == 6.0 and world.player.capacity == 10000, "Unupgraded characters preserve existing movement, mining, reach, and capacity")
	var before: Dictionary = world.player.contents.duplicate()
	test.check(not world.upgrade_character("made_up", 1) and not world.upgrade_character("boots", 2) and world.player.contents == before, "Invalid upgrades and skipped ranks never consume materials")
	world.move_direction = Vector2.RIGHT
	var position: Vector2 = world.player_position
	world.move_player()
	test.check(is_equal_approx(world.player_position.x - position.x, 0.4), "Base movement remains four tiles per second")
	test.check(world.upgrade_character("boots", 1) and world.player.count("iron_plate") == 490 and world.player.count("gear") == 197 and world.player.count("copper_plate") == 95, "Installing boots consumes the complete material cost exactly once")
	position = world.player_position
	world.move_player()
	test.check(is_equal_approx(world.player_position.x - position.x, 0.46), "Boot upgrades affect actual fixed-tick movement")
	before = world.player.contents.duplicate()
	test.check(not world.upgrade_character("boots", 1) and not world.upgrade_character("boots", 2) and world.player.contents == before, "Stale clicks and locked research tiers leave inventory intact")
	world.researched = ["logistics"]
	test.check(world.upgrade_character("boots", 2) and world.character.stat("movement_speed") == 5.2, "Logistics research unlocks the second personal upgrade tier")
	test.check(not world.upgrade_character("boots", 3), "Third tier requires Metallurgy")
	world.researched.append("metallurgy")
	test.check(not world.upgrade_character("boots", 3), "Third tier also requires the restored workshop")
	world.settlements = World.Settlements.new(true)
	world.settlements.sites.workshop.repaired = true
	test.check(world.upgrade_character("boots", 3) and world.character.stat("movement_speed") == 5.8 and not world.upgrade_character("boots", 4), "Workshop unlocks final boots with a bounded maximum rank")
	var collision := Fixtures.industrial()
	stock(collision)
	collision.upgrade_character("boots", 1)
	collision.spawn("chest", Vector2i(19, 18), 0)
	collision.move_direction = Vector2.RIGHT
	for i in range(20): collision.move_player()
	test.check(collision.player_position.x < 19.0, "Faster movement still respects machine collision")
	var miner := Fixtures.industrial()
	stock(miner)
	miner.player_position = Vector2(14.5, 16.5)
	miner.mining_cell = Vector2i(14, 16)
	miner.mining = true
	var ore: int = miner.terrain.tile(miner.mining_cell).amount
	test.advance(miner, 8)
	test.check(miner.player.count("iron_ore") == 1, "Baseline hand mining takes eight ticks per item")
	miner.upgrade_character("pickaxe", 1)
	test.advance(miner, 5)
	test.check(miner.player.count("iron_ore") == 1, "Upgraded mining still waits for its full duration")
	test.advance(miner, 1)
	test.check(miner.player.count("iron_ore") == 2 and miner.terrain.tile(miner.mining_cell).amount == ore - 2, "Mining upgrade produces faster output while consuming exactly one finite resource per item")
	miner.player.capacity = miner.player.total()
	test.advance(miner, 10)
	test.check(miner.terrain.tile(miner.mining_cell).amount == ore - 2, "Full pack prevents upgraded mining from destroying ore")
	var reach := Fixtures.industrial()
	stock(reach)
	reach.player_position = Vector2(0.5, 0.5)
	test.check(not reach.in_reach(Vector2i(7, 0)), "Base reach rejects a seven-tile interaction")
	reach.upgrade_character("reach", 1)
	test.check(reach.in_reach(Vector2i(7, 0)) and reach.build("chest", Vector2i(7, 0), 0) == false, "Upgraded reach extends command validation without granting free buildings")
	reach.player.add("chest")
	test.check(reach.build("chest", Vector2i(7, 0), 0), "Utility harness enables construction at the upgraded distance")
	var pack := Fixtures.industrial()
	stock(pack)
	test.check(pack.upgrade_character("pack", 1) and pack.player.capacity == 12500, "Pack upgrades increase actual inventory capacity")
	pack.player.contents = {"iron_plate": 12000}
	var result := Saves.decode(JSON.parse_string(JSON.stringify(Saves.encode(pack))))
	test.check(result.error.is_empty() and result.world.character.level("pack") == 1 and result.world.player.capacity == 12500 and result.world.player.total() == 12000, "Upgrade ranks and inventories above the old capacity round-trip through JSON")
	var bad := Saves.encode(pack)
	bad.character.levels.pack = 0.5
	test.check(not Saves.decode(bad).error.is_empty(), "Fractional ranks are rejected")
	bad.player = {}
	bad.character.levels = {"boots": 3}
	test.check(Saves.decode(bad).error == "Engineer upgrades lack required progression.", "Saved upgrades must satisfy their progression prerequisites")
	bad.character.levels = {"boots": 9}
	test.check(not Saves.decode(bad).error.is_empty(), "Out-of-range saved ranks are rejected")
	var complete := Fixtures.industrial()
	stock(complete)
	complete.researched = ["logistics"]
	for id in complete.character.Definitions.UPGRADES:
		complete.upgrade_character(id, 1)
		complete.upgrade_character(id, 2)
	result = Saves.decode(JSON.parse_string(JSON.stringify(Saves.encode(complete))))
	test.check(result.error.is_empty() and result.world.character.levels == complete.character.levels and result.world.player.capacity == 15000, "All four second-tier tracks preserve derived stats and capacity across JSON saves")
	if result.error.is_empty():
		complete.mining_cell = Vector2i(14, 16)
		complete.mining = true
		result.world.mining_cell = complete.mining_cell
		result.world.mining = true
		test.advance(complete, 100)
		test.advance(result.world, 100)
		test.check(Saves.encode(complete) == Saves.encode(result.world) and complete.player.count("iron_ore") == 20, "Upgraded characters continue deterministically after save and load")
	var legacy := Saves.encode(Fixtures.industrial())
	legacy.erase("character")
	result = Saves.decode(legacy)
	test.check(not result.error.is_empty(), "Incomplete or obsolete saves are rejected without migration")
	var guided := Fixtures.industrial()
	Fixtures.begin_lessons(guided)
	stock(guided)
	test.check(not guided.upgrade_character("pickaxe", 1), "Personal upgrades cannot bypass the first automation lessons")
	Fixtures.begin_lessons(pack)
	test.check(pack.player.capacity == 10000 and pack.character.levels.is_empty() and pack.player.total() == 0, "Starting a new world resets all personal progression and capacity")
