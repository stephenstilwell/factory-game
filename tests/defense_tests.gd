extends RefCounted
const World = preload("res://scripts/simulation/world.gd")
const Fixtures = preload("res://tests/fixtures.gd")
const Saves = preload("res://scripts/persistence/save_service.gd")

static func run(test: SceneTree) -> void:
	var empty := World.new()
	empty.start()
	test.check(not empty.defense.begin(empty) and empty.defense.phase == "idle", "A fresh empty world cannot start an attack")
	test.advance(empty, 500)
	test.check(empty.defense.enemies.is_empty() and empty.defense.cleared == 0, "Waves never begin automatically")
	test.check(not empty.craft("turret") and not empty.craft("wall"), "Defense recipes respect restoration and research gates")
	var world := Fixtures.defense_town()
	var hall = world.settlements.sites.town_hall
	test.check(hall.repaired and hall.health == 300 and world.settlements.sites.workshop.repaired, "A real restoration chain produces a fully healthy Town Hall")
	test.check(world.craft("ammo"), "Restoration plus Logistics unlocks ammunition crafting")
	test.advance(world, 15)
	test.check(world.player.count("ammo") == 105, "Ammunition recipe consumes factory materials and produces rounds")
	var kits: int = world.player.count("repair_kit")
	test.check(not world.repair_at(hall.port()) and world.player.count("repair_kit") == kits, "Repairing a healthy hub consumes no kit")
	test.check(world.defense.begin(world) and world.defense.warning == 150, "Lighting the beacon starts a fifteen-second warning")
	test.check(not world.defense.begin(world), "Repeated signal requests cannot overlap waves")
	var snapshot := Saves.decode(JSON.parse_string(JSON.stringify(Saves.encode(world))))
	test.check(snapshot.error.is_empty() and snapshot.world.defense.warning == 150, "Preparation countdown survives JSON save/load")
	test.check(world.defense.cancel(world) and world.defense.phase == "idle", "Warning can be canceled without a wave or reward")
	test.advance(world, 200)
	test.check(world.defense.enemies.is_empty() and world.defense.cleared == 0, "Canceled warning never spawns enemies later")
	world.defense.begin(world)
	test.advance(world, 149)
	test.check(world.defense.phase == "warning" and world.defense.enemies.is_empty(), "No scavenger arrives before the full warning")
	test.advance(world, 31)
	test.check(world.defense.phase == "active" and not world.defense.enemies.is_empty() and not world.defense.cancel(world), "Active waves spawn real enemies and cannot be dismissed")
	var mid := Saves.decode(JSON.parse_string(JSON.stringify(Saves.encode(world))))
	test.check(mid.error.is_empty(), "Active enemies, positions, ammunition, and cooldowns validate through JSON")
	if mid.error.is_empty():
		test.advance(world, 300)
		test.advance(mid.world, 300)
		test.check(Saves.encode(world) == Saves.encode(mid.world), "Saved active combat continues deterministically")
	test.check(world.defense.cleared == 1 and world.defense.phase == "idle" and hall.health == 300, "Loaded turrets can defeat the first wave and protect the hall")
	var rounds := 0
	for id in world.by_kind.turret: rounds += world.entities[id].inventory.count("ammo")
	test.check(rounds == 12, "Four 24-health scavengers require exactly eight 12-damage rounds")
	test.check(is_equal_approx(world.defense.morale_multiplier(world), 1.05), "First victory grants the promised road-crew movement benefit")
	test.advance(world, 1000)
	test.check(world.defense.cleared == 1 and world.defense.phase == "idle", "Victory waits for another deliberate signal")
	var losing := Fixtures.defense_town(false)
	losing.upgrade_character("boots", 1)
	losing.award_skill("mining", 500)
	var preserved_xp: int = losing.skills.xp.mining
	losing.defense.begin(losing)
	test.advance(losing, 1000)
	var broken = losing.settlements.sites.town_hall
	test.check(losing.defense.phase == "recovery" and broken.health == 0 and losing.defense.enemies.is_empty() and losing.defense.cleared == 0, "Undefended waves breach the hub, withdraw, and enter a recoverable setback")
	test.check(losing.character.level("boots") == 1 and losing.skills.xp.mining == preserved_xp and losing.researched == ["logistics"] and losing.entities.size() > 0, "Defeat preserves personal equipment, skill XP, research, and the factory")
	test.check(losing.settlements.effect("burner_ticks") == 0 and not losing.settlements.services_online(), "A breached Town Hall suspends regional services and workshop bonuses")
	var credits: int = losing.settlements.credits
	losing.player_position = Vector2(28.5, 15.5)
	losing.supply_site("trading_post")
	test.advance(losing, 600)
	test.check(losing.settlements.credits == credits, "Town income remains suspended while the hub is down")
	var lost_snapshot := Saves.decode(JSON.parse_string(JSON.stringify(Saves.encode(losing))))
	test.check(lost_snapshot.error.is_empty() and lost_snapshot.world.defense.phase == "recovery", "Breached hub and recovery state persist in saves")
	losing.player_position = Vector2(41.5, 14.5)
	var before := losing.player.contents.duplicate() as Dictionary
	for i in range(6): losing.repair_at(broken.port())
	test.check(broken.health == 300 and losing.player.count("repair_kit") == int(before.repair_kit) - 6 and losing.defense.phase == "idle", "Six real repair kits recover the hall without resetting research, skills, or factory stock")
	test.check(losing.settlements.services_online() and losing.settlements.effect("burner_ticks") == 16, "Repairing the hall restores town services")
	test.check(losing.defense.begin(losing) and losing.defense.cleared == 0, "A failed defense can be retried at the same difficulty")
	var barrier := Fixtures.defense_town(false)
	var wall = barrier.spawn("wall", Vector2i(60, 13), 0)
	barrier.defense.phase = "active"
	barrier.defense.spawn_enemy("dismantler", Vector2i(61, 13))
	test.advance(barrier, 8)
	test.check(wall.health < wall.max_health() and barrier.defense.enemies.values()[0].cell.x > 60, "Dismantlers damage blockers and cannot walk through a healthy wall")
	barrier.player_position = Vector2(60.5, 15.5)
	var saved_health: int = wall.health
	barrier.repair_at(wall.cell)
	test.check(wall.health > saved_health, "The engineer can repair defenses during an active wave")
	barrier.damage_structure(wall.cell, 999)
	test.check(wall.health == 0 and not barrier.solid(wall.cell) and not barrier.reclaim(wall.cell), "Disabled walls become passable ruins and cannot be reclaimed for free healing")
	var turret = barrier.spawn("turret", Vector2i(60, 16), 0)
	turret.inventory.add("ammo", 9)
	barrier.damage_structure(turret.cell, 999)
	test.check(turret.inventory.count("ammo") == 9 and not barrier.accepts(turret, "ammo"), "Disabled turrets preserve stock and refuse new deliveries until repaired")
	var factory := Fixtures.defense_town(false)
	var gun = factory.spawn("turret", Vector2i(48, 16), 0)
	factory.spawn("inserter", Vector2i(49, 16), 2)
	var assembler = factory.spawn("assembler", Vector2i(50, 16), 0)
	assembler.recipe = "ammo"
	assembler.inventory.add("iron_plate", 4)
	test.advance(factory, 150)
	test.check(gun.inventory.count("ammo") == 10 and assembler.inventory.count("iron_plate") == 0 and assembler.output.total() == 0, "Assemblers and inserters can manufacture and automatically stock real turret ammunition")
	var empty_gun := Fixtures.defense_town(false)
	var unfed = empty_gun.spawn("turret", Vector2i(60, 12), 0)
	empty_gun.defense.begin(empty_gun)
	test.advance(empty_gun, 170)
	test.check(unfed.status == "No ammunition" and empty_gun.defense.enemies.size() > 0, "Unloaded turrets do not fire free shots")
	factory.damage_structure(factory.settlements.sites.workshop.port(), 999)
	test.check(factory.settlements.effect("burner_ticks") == 0, "Damage to the outlying workshop suspends its bonus")
	factory.player_position = Vector2(34.5, 20.5)
	factory.repair_at(factory.settlements.sites.workshop.port())
	test.check(factory.settlements.effect("burner_ticks") == 16, "Repairing the workshop restores its existing civic bonus")
	var old := Saves.encode(Fixtures.trading_town())
	old.erase("defense")
	old.settlements.version = 1
	old.settlements.sites = old.settlements.sites.filter(func(site): return site.id != "town_hall")
	for record in old.settlements.sites: record.erase("health")
	for record in old.entities: record.erase("health"); record.erase("attack_cooldown")
	old.entities.append(World.Entity.new(int(old.next_id), "chest", Vector2i(42, 12), 0).serialize())
	old.next_id += 1
	var migrated := Saves.decode(JSON.parse_string(JSON.stringify(old)))
	test.check(migrated.error.is_empty() and migrated.world.at(Vector2i(42, 12)) != null and migrated.world.settlements.sites.town_hall.origin != Vector2i(42, 12) and migrated.world.defense.phase == "idle", "Old factories gain a vacant relocated Town Hall without losing existing buildings or receiving attacks")
	var malformed := Saves.encode(world)
	malformed.defense.phase = "active"
	test.check(not Saves.decode(malformed).error.is_empty(), "Impossible empty active waves are rejected")
	malformed = Saves.encode(world)
	malformed.entities[0].health = -1
	test.check(not Saves.decode(malformed).error.is_empty(), "Invalid saved structure health is rejected")
	var campaign := Fixtures.combat_town()
	for wave in range(10):
		if not campaign.defense.begin(campaign): break
		for tick in range(1000):
			# Fixture resupply isolates wave balance from factory throughput.
			for kind in campaign.Catalog.Combat.TURRETS:
				for id in campaign.by_kind[kind]:
					var stock = campaign.entities[id].inventory
					stock.add("ammo", maxi(0, 10 - stock.count("ammo")))
			test.advance(campaign, 1)
			if campaign.defense.phase in ["idle", "recovery"]: break
		if campaign.defense.phase == "recovery": break
	test.check(campaign.defense.cleared == 10 and not campaign.defense.begin(campaign), "A resupplied mixed-defense factory can win ten waves and never starts an eleventh")
	var completed := Saves.decode(JSON.parse_string(JSON.stringify(Saves.encode(campaign))))
	test.check(completed.error.is_empty() and completed.world.defense.cleared == 10, "Completed defense campaign and permanent reward survive saving")
