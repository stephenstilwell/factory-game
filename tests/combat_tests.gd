extends RefCounted
const World = preload("res://scripts/simulation/world.gd")
const Fixtures = preload("res://tests/fixtures.gd")
const Saves = preload("res://scripts/persistence/save_service.gd")

static func arena() -> RefCounted:
	var world := Fixtures.defense_town(false)
	world.researched = ["logistics", "metallurgy", "routing"]
	world.defense.cleared = 2
	world.defense.phase = "active"
	world.player_position = Vector2(50.5, 13.5)
	world.previous_position = world.player_position
	world.player.add("service_rifle")
	return world

static func copy(world: RefCounted) -> Dictionary:
	return Saves.decode(JSON.parse_string(JSON.stringify(Saves.encode(world))))

static func run(test: SceneTree) -> void:
	var empty := Fixtures.industrial()
	Fixtures.begin_lessons(empty)
	test.check(not empty.combat.toggle(empty) and empty.player.total() == 0, "Fresh engineers receive no free weapon or ammunition")
	var manufacture := Fixtures.defense_town(false)
	manufacture.player.contents = World.Catalog.RECIPES.service_rifle["in"].duplicate()
	test.check(manufacture.craft("service_rifle"), "Service rifles are crafted from real workshop materials")
	test.advance(manufacture, 35)
	test.check(manufacture.player.contents == {"service_rifle": 1}, "A completed rifle craft delivers one weapon without duplicating its ingredients")
	for kind in ["cannon_turret", "pulse_turret"]:
		var supply := Fixtures.defense_town(false)
		supply.researched = ["logistics", "metallurgy", "routing"]
		var gun = supply.spawn(kind, Vector2i(51, 12), 0)
		supply.spawn("inserter", Vector2i(52, 12), 2)
		var maker = supply.spawn("assembler", Vector2i(53, 12), 0)
		maker.recipe = "ammo"
		maker.inventory.add("iron_plate", 4)
		test.advance(supply, 150)
		test.check(gun.inventory.count("ammo") == 10 and maker.inventory.total() == 0 and maker.output.total() == 0, "Factory production and inserters stock real ammunition for " + kind)
	var world := arena()
	var scout: Dictionary = world.defense.spawn_enemy("scout", Vector2i(54, 13))
	var hauler: Dictionary = world.defense.spawn_enemy("hauler", Vector2i(55, 13))
	world.combat.aim = Vector2(54.5, 13.5)
	test.check(world.combat.toggle(world), "A manufactured rifle can be drawn")
	var ammo: int = world.player.count("ammo")
	test.check(world.combat.shoot(world) and world.player.count("ammo") == ammo - 1 and scout.health == 16 and hauler.health == 84, "Rifle consumes one physical round and hits only the frontmost aimed construct")
	test.check(not world.combat.shoot(world) and world.player.count("ammo") == ammo - 1, "Rifle cooldown prevents extra shots and ammo loss")
	world.combat.cooldown = 0
	world.combat.shoot(world)
	test.check(not world.defense.enemies.has(scout.id), "A second rifle hit destroys the wounded scout")
	world.combat.cooldown = 0
	world.combat.shoot(world)
	test.check(hauler.health == 74, "Hauler armor subtracts six damage from ordinary rifle rounds")
	world.combat.cooldown = 0
	world.combat.aim = Vector2(50.5, 4.5)
	world.combat.shoot(world)
	test.check(hauler.health == 74 and world.player.count("ammo") == ammo - 4, "Missed shots spend ammunition without damaging an unrelated target")
	world.combat.firing = true
	var saved := copy(world)
	test.check(saved.error.is_empty(), "Rifle equipment, health, cooldown, and typed enemies save together")
	if saved.error.is_empty(): test.check(not saved.world.combat.firing and saved.world.combat.armed, "Loading retains the equipped rifle but never resumes a held trigger")
	world.player_position = Vector2(50.5, 13.5)
	world.spawn("chest", Vector2i(51, 12), 0)
	var chest = world.at(Vector2i(51, 12))
	world.transfer_item("service_rifle", 1, {"kind": "player"}, {"kind": "input", "entity_id": chest.id})
	test.check(not world.combat.armed and copy(world).error.is_empty(), "Storing the carried rifle immediately holsters it and leaves a valid save")
	var piercing := arena()
	var heavy: Dictionary = piercing.defense.spawn_enemy("hauler", Vector2i(54, 13))
	var quick: Dictionary = piercing.defense.spawn_enemy("scout", Vector2i(52, 13))
	var cannon = piercing.spawn("cannon_turret", Vector2i(50, 13), 0)
	cannon.inventory.add("ammo", 4)
	piercing.defense._fire_turrets(piercing)
	test.check(heavy.health == 52 and quick.health == 32 and cannon.inventory.count("ammo") == 2, "Piercing cannon bypasses armor and prioritizes a hauler over a nearer scout")
	var pulse := arena()
	var a: Dictionary = pulse.defense.spawn_enemy("scout", Vector2i(53, 13))
	var b: Dictionary = pulse.defense.spawn_enemy("dismantler", Vector2i(53, 14))
	var emitter = pulse.spawn("pulse_turret", Vector2i(50, 13), 0)
	emitter.inventory.add("ammo", 2)
	pulse.defense._fire_turrets(pulse)
	test.check(a.health == 24 and b.health == 40 and a.slow == 25 and b.slow == 25 and emitter.inventory.total() == 0, "Pulse turret spends two rounds to damage and slow a cluster, bypassing armor")
	test.check(copy(pulse).error.is_empty(), "Slows and specialized turret cooldowns persist")
	var path := arena()
	var wall = path.spawn("wall", Vector2i(60, 13), 0)
	var probe: Dictionary = path.defense.spawn_enemy("scout", Vector2i(61, 13))
	var next: Vector2i = path.defense.navigation.next_cell(path, probe)
	test.check(next != wall.cell, "Scouts route around an isolated wall instead of marching down one fixed lane")
	probe.kind = "dismantler"
	test.check(path.defense.navigation.next_cell(path, probe) == wall.cell, "Dismantlers prefer breaking through a short blocker")
	path.player_position = Vector2(60.5, 15.5)
	test.check(path.reclaim(wall.cell), "A healthy lane blocker can be reclaimed")
	probe.kind = "scout"
	test.check(path.defense.navigation.next_cell(path, probe) == Vector2i(60, 13), "Removing a blocker invalidates routing and restores the direct route")
	var danger := arena()
	var attacker: Dictionary = danger.defense.spawn_enemy("dismantler", Vector2i(51, 13))
	danger.defense._advance_enemy(danger, attacker)
	test.check(attacker.attack_ticks == 4 and attacker.attack_player and danger.combat.health == 100, "Enemy melee telegraphs before damaging the nearby engineer")
	danger.player_position = Vector2(49.0, 13.5)
	for i in range(4): danger.defense._advance_enemy(danger, attacker)
	test.check(danger.combat.health == 100, "Moving out of a telegraphed melee strike avoids its damage")
	danger.player_position = Vector2(50.5, 13.5)
	attacker.cooldown = 0
	danger.defense._advance_enemy(danger, attacker)
	var windup := copy(danger)
	test.check(windup.error.is_empty(), "Attack windup, locked target, and enemy type survive JSON")
	if windup.error.is_empty():
		test.advance(danger, 5)
		test.advance(windup.world, 5)
		test.check(Saves.encode(danger) == Saves.encode(windup.world) and danger.combat.health == 84, "Saved melee resumes deterministically and deals the advertised damage")
	var stock: Dictionary = danger.player.contents.duplicate()
	danger.combat.invulnerable = 0
	danger.combat.health = 1
	danger.combat.damage(danger, 16)
	test.check(danger.combat.health == 100 and danger.combat.invulnerable == 50 and danger.player.contents == stock and danger.defense.phase == "active", "Defeat retreats safely with gear intact while the defense continues")
	test.check(not danger.solid(Vector2i(danger.player_position.floor())), "Retreat never places the engineer inside a structure")
	var previous: int = danger.combat.health
	danger.combat.damage(danger, 50)
	test.check(danger.combat.health == previous, "Retreat protection prevents immediate repeated damage")
	var solo := Fixtures.defense_town(false)
	solo.player.add("service_rifle")
	solo.combat.toggle(solo)
	solo.defense.begin(solo)
	solo.player_position = Vector2(57.5, 13.5)
	var solo_ammo: int = solo.player.count("ammo")
	for tick in range(400):
		solo.combat.firing = not solo.defense.enemies.is_empty()
		if not solo.defense.enemies.is_empty():
			var front: Dictionary = solo.defense.enemies.values()[0]
			solo.combat.aim = Vector2(front.cell) + Vector2.ONE * 0.5
		test.advance(solo, 1)
		if solo.defense.cleared == 1: break
	test.check(solo.defense.cleared == 1 and solo.player.count("ammo") == solo_ammo - 8, "An actively aimed service rifle can complete the first wave with exactly eight rounds")
	var healing := Fixtures.industrial()
	healing.combat.damage(healing, 20)
	for i in range(50): healing.combat.step(healing)
	test.check(healing.combat.health == 80, "Health does not regenerate during its five-second damage delay")
	healing.combat.step(healing)
	test.check(healing.combat.health == 81, "Health recovers gradually after the damage delay")
	var old := Fixtures.defense_town(false)
	old.defense.phase = "active"
	old.defense.spawn_enemy("scout", Vector2i(60, 13))
	var legacy: Dictionary = Saves.encode(old)
	legacy.erase("combat")
	legacy.defense.version = 1
	for enemy in legacy.defense.enemies:
		for key in ["kind", "slow", "attack_ticks", "attack_x", "attack_y", "attack_player"]: enemy.erase(key)
	var migrated := Saves.decode(JSON.parse_string(JSON.stringify(legacy)))
	test.check(not migrated.has("world"), "Incomplete or obsolete saves are rejected without migration")
	var invalid: Dictionary = Saves.encode(pulse)
	invalid.defense.enemies[0].kind = "unknown"
	test.check(not Saves.decode(invalid).error.is_empty(), "Unknown saved construct types are rejected")
	invalid = Saves.encode(pulse)
	invalid.defense.enemies[0].slow = 999
	test.check(not Saves.decode(invalid).error.is_empty(), "Impossible saved slow timers are rejected")
	invalid = Saves.encode(pulse)
	invalid.combat.health = 0
	test.check(not Saves.decode(invalid).error.is_empty(), "Saved unrecovered zero engineer health is rejected")
	test.check(World.Catalog.Combat.kind_at(1, 2) == "scout" and World.Catalog.Combat.kind_at(2, 2) == "dismantler" and World.Catalog.Combat.kind_at(3, 4) == "hauler", "Wave composition introduces scouts, dismantlers, then haulers gradually")
	test.check(pulse.defense.entries(pulse).size() == 3, "Later defenses use three eastern arrival gates")

static func ui(test: SceneTree) -> void:
	var scene = load("res://main.tscn").instantiate()
	test.root.add_child(scene)
	scene._bind_world(arena())
	scene.paused = true
	var key := InputEventKey.new()
	key.keycode = KEY_V
	key.pressed = true
	scene._unhandled_input(key)
	test.check(scene.world.combat.armed and scene.selected_kind.is_empty(), "V draws the rifle and clears the build cursor")
	var facing: int = scene.facing
	key.keycode = KEY_R
	scene._unhandled_input(key)
	test.check(scene.facing == facing, "R in weapon mode never rotates factory equipment")
	key.keycode = KEY_SPACE
	scene._unhandled_input(key)
	test.check(scene.firing_held, "Space starts the armed firing gesture rather than pausing")
	scene._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	test.check(not scene.firing_held and not scene.world.combat.firing, "Focus loss clears firing immediately")
	scene._select("belt")
	test.check(not scene.world.combat.armed, "Choosing a building holsters the rifle")
	scene.hud.toggle_inventory()
	scene.hud.workspace._pack_click("service_rifle", "equip")
	test.check(scene.world.combat.armed and not scene.hud.workspace.visible, "Double-clicking a rifle in the pack equips it through the shared command")
	scene._start_copy()
	test.check(not scene.world.combat.armed and scene.copy_mode, "Blueprint editing cannot leave the rifle active")
	scene.queue_free()
	await test.process_frame
