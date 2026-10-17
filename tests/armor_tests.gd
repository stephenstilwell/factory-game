extends RefCounted
const Fixtures = preload("res://tests/fixtures.gd")
const Saves = preload("res://scripts/persistence/save_service.gd")
static func run(test: SceneTree) -> void:
	var world := Fixtures.defense_town(false)
	world.researched = ["logistics", "metallurgy"]
	world.player.contents = {"iron_plate": 20, "wire": 10}
	test.check(world.upgrade_character("armor", 1) and world.player.total() == 0 and world.character.stat("damage_reduction") == 15, "Protective coat consumes real workshop materials")
	world.combat.damage(world, 16)
	test.check(world.combat.health == 86, "First coat tier reduces incoming engineer damage")
	world.combat.invulnerable = 0
	world.player.contents = {"steel": 20, "gear": 10}
	test.check(world.upgrade_character("armor", 2) and world.player.total() == 0, "Second coat tier spends steel and gears")
	world.combat.damage(world, 16)
	test.check(world.combat.health == 75, "Second coat tier provides 30 percent personal damage reduction")
	world.combat.invulnerable = 0
	world.combat.damage(world, 1)
	test.check(world.combat.health == 74, "Protective equipment never makes damaging hits free")
	world.combat.invulnerable = 0
	world.combat.regen_delay = 0
	world.combat.damage(world, 0)
	test.check(world.combat.health == 74 and world.combat.invulnerable == 0 and world.combat.regen_delay == 0, "Non-damaging hits never trigger protection or delay regeneration")
	var loaded := Saves.decode(JSON.parse_string(JSON.stringify(Saves.encode(world))))
	test.check(loaded.error.is_empty() and loaded.world.character.level("armor") == 2 and loaded.world.character.stat("damage_reduction") == 30, "Saved armor derives its protection from purchased ranks")
	var locked := Fixtures.demo()
	locked.player.contents = {"iron_plate": 20, "wire": 10}
	test.check(not locked.upgrade_character("armor", 1) and locked.player.total() == 30, "Protection remains gated behind workshop restoration and research")
