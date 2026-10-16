extends RefCounted
## Demonstration setups belong to tests, never the new-game path.

const World = preload("res://scripts/simulation/world.gd")
const Settlements = preload("res://scripts/simulation/settlements.gd")
const Simulation = preload("res://scripts/simulation/simulation.gd")

static func demo() -> RefCounted:
	var world := World.new()
	world.player.contents = {"belt": 60, "inserter": 12, "drill": 4, "furnace": 4, "chest": 6, "assembler": 2, "lab": 1,
		"coal": 40, "stone": 20, "iron_plate": 40, "copper_plate": 20, "gear": 15, "wire": 10}
	world.spawn("drill", Vector2i(15, 15), 0).inventory.add("coal", 10)
	for x in [16, 17]: world.spawn("belt", Vector2i(x, 15), 0)
	world.spawn("inserter", Vector2i(18, 15), 0)
	world.spawn("furnace", Vector2i(19, 15), 0).inventory.add("coal", 10)
	world.spawn("inserter", Vector2i(20, 15), 0)
	for x in [21, 22]: world.spawn("belt", Vector2i(x, 15), 0)
	world.spawn("inserter", Vector2i(23, 15), 0)
	world.spawn("chest", Vector2i(24, 15), 0)
	return world

static func trading_town() -> RefCounted:
	var world := demo()
	world.settlements = Settlements.new(true)
	world.player_position = Vector2(28.5, 15.5)
	world.previous_position = world.player_position
	world.supply_site("trading_post")
	world.restore_site("trading_post")
	var port: Vector2i = world.settlements.sites.trading_post.port()
	var supply = world.spawn("chest", port - Vector2i(2, 0), 0)
	supply.inventory.contents = {"iron_plate": 24, "gear": 6}
	world.spawn("inserter", port - Vector2i(1, 0), 0)
	return world

static func defense_town(armed: bool = true) -> RefCounted:
	var world := trading_town()
	for i in range(2400): Simulation.step(world)
	world.player_position = Vector2(34.5, 20.5)
	world.previous_position = world.player_position
	world.supply_site("workshop")
	world.restore_site("workshop")
	# Manufactured stock is a preview fixture, never part of a real new game.
	world.player.contents = {"iron_plate": 200, "stone": 100, "gear": 80, "wire": 80, "copper_plate": 100, "turret": 2, "wall": 10, "ammo": 100, "repair_kit": 12}
	world.researched = ["logistics"]
	world.player_position = Vector2(41.5, 14.5)
	world.previous_position = world.player_position
	world.supply_site("town_hall")
	world.restore_site("town_hall")
	if armed:
		world.spawn("turret", Vector2i(51, 11), 0).inventory.add("ammo", 10)
		world.spawn("turret", Vector2i(51, 15), 0).inventory.add("ammo", 10)
		world.spawn("wall", Vector2i(49, 13), 0)
	return world

static func combat_town() -> RefCounted:
	var world := defense_town()
	world.researched = ["logistics", "metallurgy", "routing"]
	world.player.add("service_rifle")
	for position in [Vector2i(48, 9), Vector2i(48, 17), Vector2i(50, 13)]:
		world.spawn("cannon_turret", position, 0).inventory.add("ammo", 10)
	for position in [Vector2i(52, 9), Vector2i(52, 17)]:
		world.spawn("pulse_turret", position, 0).inventory.add("ammo", 10)
	return world
