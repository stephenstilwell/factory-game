extends RefCounted
const World = preload("res://scripts/simulation/world.gd")
const Fixtures = preload("res://tests/fixtures.gd")
const Saves = preload("res://scripts/persistence/save_service.gd")
const Catalog = preload("res://scripts/data/catalog.gd")
const Combat = preload("res://scripts/data/combat_catalog.gd")
const DefenseView = preload("res://scripts/view/defense_view.gd")

static func setup_town() -> RefCounted:
	var world := Fixtures.defense_town(false)
	world.researched = ["logistics", "metallurgy", "routing"]
	world.defense.cleared = 2
	world.defense.phase = "active"
	world.player_position = Vector2(50.5, 13.5)
	world.previous_position = world.player_position
	return world

static func run(test: SceneTree) -> void:
	# 1. Tradeoffs and Weapon definitions
	test.check(Combat.WEAPONS.has("service_rifle") and Combat.WEAPONS.has("marksman_rifle"), "Combat catalog defines both standard service rifle and precision marksman rifle")
	var service: Dictionary = Combat.WEAPONS.service_rifle
	var marksman: Dictionary = Combat.WEAPONS.marksman_rifle
	test.check(marksman.range > service.range and marksman.damage > service.damage, "Precision rifle offers superior range and punch")
	test.check(marksman.cooldown > service.cooldown and marksman.ammo > service.ammo and marksman.piercing and not service.piercing, "Precision rifle trades slower fire rate and double ammo cost for armor-piercing capabilities")

	# 2. Crafting and technology gating
	var town := setup_town()
	town.player.contents = Catalog.RECIPES.marksman_rifle["in"].duplicate()
	test.check(town.craft("marksman_rifle"), "Precision rifle can be crafted with steel, gears, and wire")
	test.advance(town, int(Catalog.RECIPES.marksman_rifle.ticks))
	test.check(town.player.count("marksman_rifle") == 1, "Completed marksman craft places one precision rifle in the pack")

	var unresearched := Fixtures.defense_town(false)
	unresearched.researched = ["logistics"] # lacks metallurgy
	unresearched.player.contents = Catalog.RECIPES.marksman_rifle["in"].duplicate()
	test.check(not unresearched.craft("marksman_rifle"), "Precision rifle crafting is gated behind Foundry craft research")

	town.player.contents = Catalog.RECIPES.reinforced_wall["in"].duplicate()
	test.check(town.craft("reinforced_wall"), "Reinforced barricade is craftable with stone and steel")
	test.advance(town, int(Catalog.RECIPES.reinforced_wall.ticks))
	test.check(town.player.count("reinforced_wall") == 1, "Completed reinforced wall craft places one barrier in the pack")
	test.check(Catalog.BUILDINGS.reinforced_wall.health == 320 and Catalog.BUILDINGS.wall.health == 120, "Reinforced barricade provides 320 health compared to 120 for stone wall")

	# 3. Equipping, weapon switching, and holstering
	var player_test := setup_town()
	player_test.player.add("service_rifle", 1)
	player_test.player.add("marksman_rifle", 1)
	player_test.player.add("ammo", 100)
	test.check(not player_test.combat.armed, "Player starts holstered")

	# Draw first weapon
	test.check(player_test.combat.toggle(player_test), "Toggle draws weapon")
	test.check(player_test.combat.armed and player_test.combat.active_weapon == "service_rifle", "Service rifle is armed first by default")

	# Cycle weapon while armed
	test.check(player_test.combat.toggle(player_test), "Toggle while armed with multiple rifles switches to the next carried weapon")
	test.check(player_test.combat.armed and player_test.combat.active_weapon == "marksman_rifle", "Marksman rifle is now armed")

	# Toggle again holsters
	test.check(player_test.combat.toggle(player_test), "Toggle after cycling holsters the weapon")
	test.check(not player_test.combat.armed, "Weapon is now holstered")

	# Specific weapon arming
	test.check(player_test.combat.toggle(player_test, "marksman_rifle"), "Direct toggle with marksman_rifle arms it directly")
	test.check(player_test.combat.armed and player_test.combat.active_weapon == "marksman_rifle", "Active weapon is marksman_rifle")

	# Target reach matches equipped weapon range
	player_test.combat.aim = Vector2(61.0, 13.5) # distance 10.5 from player at (50.5, 13.5)
	var distant_scout: Dictionary = player_test.defense.spawn_enemy("scout", Vector2i(61, 13))
	test.check(player_test.combat.target(player_test) == distant_scout.id, "Precision rifle targets construct at 10.5 tiles (within range 11.0)")

	player_test.combat.toggle(player_test, "service_rifle")
	test.check(player_test.combat.target(player_test) == -1, "Service rifle cannot target construct at 10.5 tiles (exceeds range 8.0)")
	player_test.defense.enemies.erase(distant_scout.id)

	# 4. Readable feedback: Hits, Armor Resistance, Piercing, and Misses
	var combat_world := setup_town()
	combat_world.player.add("service_rifle", 1)
	combat_world.player.add("marksman_rifle", 1)
	combat_world.player.add("ammo", 50)
	var hauler: Dictionary = combat_world.defense.spawn_enemy("hauler", Vector2i(54, 13))
	var starting_hauler_health: int = hauler.health

	# Test Service Rifle against Hauler (non-piercing vs armor 6)
	combat_world.combat.toggle(combat_world, "service_rifle")
	combat_world.combat.aim = Vector2(54.5, 13.5)
	var ammo_before: int = combat_world.player.count("ammo")
	test.check(combat_world.combat.shoot(combat_world), "Service rifle shoots successfully")
	test.check(combat_world.player.count("ammo") == ammo_before - 1, "Service rifle spends exactly 1 ammo")
	test.check(hauler.last_damage == 10 and hauler.last_absorbed == 6 and hauler.hit_kind == "resisted", "Service rifle shot is resisted: 16 damage - 6 armor = 10 damage dealt, 6 absorbed")
	test.check(hauler.health == starting_hauler_health - 10, "Hauler health correctly reflects resisted damage")

	# Test Marksman Rifle against Hauler (piercing vs armor 6)
	combat_world.combat.cooldown = 0
	combat_world.combat.toggle(combat_world, "marksman_rifle")
	ammo_before = combat_world.player.count("ammo")
	test.check(combat_world.combat.shoot(combat_world), "Marksman rifle shoots successfully")
	test.check(combat_world.player.count("ammo") == ammo_before - 2, "Marksman rifle spends exactly 2 ammo")
	test.check(hauler.last_damage == 36 and hauler.last_absorbed == 0 and hauler.hit_kind == "pierce", "Marksman rifle shot pierces hauler armor completely: deals full 36 damage")
	test.check(hauler.health == starting_hauler_health - 10 - 36, "Hauler health reflects 36 piercing damage")

	# Insufficient ammo rejection
	combat_world.combat.cooldown = 0
	combat_world.player.contents["ammo"] = 1
	test.check(not combat_world.combat.shoot(combat_world) and combat_world.player.count("ammo") == 1, "Marksman rifle rejects shot when player has only 1 ammo round")

	# Miss feedback and ammunition conservation
	combat_world.player.add("ammo", 10)
	combat_world.combat.cooldown = 0
	combat_world.combat.aim = Vector2(50.5, 2.0) # Aiming North away from enemies
	var misses_before: int = combat_world.defense.misses.size()
	var costs_ammo_before: int = combat_world.defense.costs.ammo
	test.check(combat_world.combat.shoot(combat_world), "Missed shot still fires and spends ammo")
	test.check(combat_world.defense.misses.size() == misses_before + 1, "Miss is recorded in defense misses list for readable feedback")
	test.check(combat_world.defense.costs.ammo == costs_ammo_before + 2, "Defense costs accurately track ammo spent on missed shots")

	# 5. Dropping / Transferring Weapon Handling
	combat_world.spawn("chest", Vector2i(51, 12), 0)
	var chest = combat_world.at(Vector2i(51, 12))
	combat_world.transfer_item("marksman_rifle", 1, {"kind": "player"}, {"kind": "input", "entity_id": chest.id})
	test.check(combat_world.combat.armed and combat_world.combat.active_weapon == "service_rifle", "Transferring marksman rifle automatically switches to remaining service rifle in pack")
	combat_world.transfer_item("service_rifle", 1, {"kind": "player"}, {"kind": "input", "entity_id": chest.id})
	test.check(not combat_world.combat.armed, "Transferring last carried rifle immediately holsters the weapon")

	# 6. Reinforced barricade durability and pathfinding
	var barrier_world := setup_town()
	var steel_wall = barrier_world.spawn("reinforced_wall", Vector2i(60, 13), 0)
	test.check(steel_wall.health == 320, "Placed reinforced barricade has 320 health")

	var dismantler: Dictionary = barrier_world.defense.spawn_enemy("dismantler", Vector2i(61, 13))
	test.check(barrier_world.defense.navigation.next_cell(barrier_world, dismantler) == steel_wall.cell, "Dismantler targets reinforced barricade along its route")
	barrier_world.damage_structure(steel_wall.cell, 100)
	test.check(steel_wall.health == 220, "Barricade absorbs 100 damage and survives")
	barrier_world.damage_structure(steel_wall.cell, 250)
	test.check(steel_wall.health == 0, "Barricade is disabled at 0 health")
	barrier_world.player.add("repair_kit", 2)
	barrier_world.player_position = Vector2(59.5, 13.5)
	test.check(barrier_world.repair_at(steel_wall.cell) and steel_wall.health > 0, "Reinforced barricade can be repaired with repair kits")

	# 7. Persistence and save validation
	var save_world := setup_town()
	save_world.player.add("service_rifle", 1)
	save_world.player.add("marksman_rifle", 1)
	save_world.player.add("ammo", 80)
	save_world.defense.spawn_enemy("scout", Vector2i(54, 13))
	save_world.combat.toggle(save_world, "marksman_rifle")
	save_world.combat.cooldown = 4
	save_world.combat.invulnerable = 3
	var encoded := Saves.encode(save_world)
	var decoded := Saves.decode(JSON.parse_string(JSON.stringify(encoded)))
	test.check(decoded.error.is_empty(), "Save with marksman rifle, custom cooldown, and defenses roundtrips: " + decoded.error)
	if decoded.error.is_empty():
		test.check(decoded.world.combat.armed and decoded.world.combat.cooldown == 4, "Loaded world preserves armed status and cooldown")
		test.check(decoded.world.player.count("marksman_rifle") == 1 and decoded.world.player.count("service_rifle") == 1, "Carried weapons survive save/load intact")

static func ui(test: SceneTree) -> void:
	var scene = load("res://main.tscn").instantiate()
	test.root.add_child(scene)
	var world := setup_town()
	world.player.add("service_rifle", 1)
	world.player.add("marksman_rifle", 1)
	world.player.add("ammo", 50)
	scene._bind_world(world)
	scene.paused = true
	await test.process_frame

	# Check HUD weapon button display and switching
	test.check(scene.hud.weapon_button.visible and not scene.hud.weapon_button.disabled, "Weapon button is active when rifles are carried")
	test.check(scene.hud.weapon_button.text.contains("Draw"), "Button offers to draw rifle")

	# Press V to draw
	var key := InputEventKey.new()
	key.keycode = KEY_V
	key.pressed = true
	scene._unhandled_input(key)
	test.check(scene.world.combat.armed and scene.world.combat.active_weapon == "service_rifle", "Pressing V draws service rifle")
	test.check(scene.hud.weapon_button.text.contains("Switch [V]"), "Button indicates switching is available when multiple rifles are carried")

	# Press V again to switch
	scene._unhandled_input(key)
	test.check(scene.world.combat.armed and scene.world.combat.active_weapon == "marksman_rifle", "Pressing V again switches to precision rifle")

	# Pack double-click equipping
	scene.hud.toggle_inventory()
	await test.process_frame
	scene.hud.workspace._pack_click("service_rifle", "equip")
	test.check(scene.world.combat.armed and scene.world.combat.active_weapon == "service_rifle" and not scene.hud.workspace.visible, "Double-clicking service rifle in pack switches back to it and closes workspace")

	scene.queue_free()
	await test.process_frame
