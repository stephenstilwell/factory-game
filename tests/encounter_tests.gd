extends RefCounted
const Fixtures = preload("res://tests/fixtures.gd")
const Catalog = preload("res://scripts/data/combat_catalog.gd")
const Simulation = preload("res://scripts/simulation/simulation.gd")
const Saves = preload("res://scripts/persistence/save_service.gd")
static func later(wave: int) -> RefCounted:
	var world := Fixtures.defense_town(false)
	world.researched = ["logistics","metallurgy","routing"]
	for previous in range(1,wave): world.settlements.award_defense(previous)
	world.defense.cleared = wave-1
	return world
static func run(test: SceneTree) -> void:
	var names: Dictionary = {}
	var valid := Catalog.ENCOUNTERS.size() == 10
	for wave in range(1,11):
		var data := Catalog.encounter(wave)
		names[data.name] = true
		valid = valid and data.units.size() == 4+(wave-1)*2 and data.units.size() <= 22
		for kind in data.units: valid = valid and Catalog.ENEMIES.has(kind)
		for gate in data.gates: valid = valid and gate >= 0 and gate <= (0 if wave == 1 else 2)
		for index in data.breaks: valid = valid and index > 0 and index < data.units.size() and Catalog.spawn_delay(wave,index) <= 100
	test.check(valid and names.size() == 10,"All ten authored encounters have unique names, bounded valid units, disclosed gates and internal reinforcement groups")
	test.check(Catalog.kind_at(1,2) == "scout" and Catalog.kind_at(2,2) == "dismantler" and Catalog.kind_at(3,4) == "hauler","Early encounters preserve gradual enemy-role introductions")
	test.check(Catalog.encounter(4).gap < Catalog.encounter(5).gap and Catalog.encounter(10).breaks.size() == 2,"Rush, convoy and final three-group encounters use meaningfully different timing")
	var world := later(6)
	world.defense.begin(world)
	for i in range(149): Simulation.step(world)
	test.check(world.defense.phase == "warning" and world.defense.enemies.is_empty(),"Authored encounters retain the full cancelable warning")
	Simulation.step(world)
	world.defense.enemies.clear() # Isolate scheduling; combat viability is tested separately.
	while world.defense.pending > 7:
		Simulation.step(world)
		world.defense.enemies.clear()
	test.check(world.defense.phase == "active" and world.defense.spawn_timer == 100 and world.defense.summary().contains("REINFORCEMENTS"),"Clearing an opening group does not win while disclosed reinforcements remain")
	var saved := Saves.decode(JSON.parse_string(JSON.stringify(Saves.encode(world))))
	test.check(saved.error.is_empty(),"A reinforcement pause with no live enemies survives validation: " + saved.error)
	var invalid := Saves.encode(world)
	invalid.defense.spawn_timer = 101
	test.check(not Saves.decode(invalid).error.is_empty(),"Save rejects delays beyond the disclosed schedule")
	for i in range(99): Simulation.step(world)
	test.check(world.defense.pending == 7 and world.defense.enemies.is_empty(),"Reinforcements wait the advertised ten simulated seconds")
	Simulation.step(world)
	test.check(world.defense.pending == 6 and not world.defense.enemies.is_empty(),"Reinforcements arrive at the scheduled countdown boundary")
	if saved.error.is_empty():
		for i in range(100): Simulation.step(saved.world)
		test.check(Saves.encode(world) == Saves.encode(saved.world),"Reload during a reinforcement pause preserves exact scheduling and cost counters")
	var blocked := later(1)
	var entry: Vector2i = blocked.defense.spawn_cell(blocked)
	blocked.spawn("wall",entry,0)
	blocked.spawn("wall",entry+Vector2i.RIGHT,0)
	blocked.defense.begin(blocked)
	for i in range(160): Simulation.step(blocked)
	test.check(blocked.defense.pending == 4 and blocked.defense.enemies.is_empty() and blocked.defense.summary().contains("OBSTRUCTED"),"Blocked entry cells wait visibly rather than spawning inside buildings")
	blocked.damage_structure(entry,1000)
	Simulation.step(blocked)
	test.check(blocked.defense.pending == 3,"Clearing a marked entry resumes the same pending encounter")
	var costs := Fixtures.defense_town()
	var starting := 0
	for id in costs.by_kind.turret: starting += costs.entities[id].inventory.count("ammo")
	costs.defense.begin(costs)
	for i in range(900): Simulation.step(costs)
	var remaining := 0
	for id in costs.by_kind.turret: remaining += costs.entities[id].inventory.count("ammo")
	test.check(costs.defense.last_result.victory and costs.defense.last_result.ammo == starting-remaining and costs.defense.last_result.ammo == 8,"First-defense report matches actual rounds removed from gun buffers")
	test.check(costs.defense.cost_summary().contains("8 rounds") and costs.defense.last_result.kits == 0,"After-action summary states actual supply cost rather than a readiness estimate")
	var loaded := Saves.decode(JSON.parse_string(JSON.stringify(Saves.encode(costs))))
	test.check(loaded.error.is_empty() and loaded.world.defense.last_result == costs.defense.last_result,"Last defense outcome persists with validated costs")
	var accounting := later(1)
	accounting.defense.begin(accounting)
	for i in range(150): Simulation.step(accounting)
	var wall = accounting.spawn("wall",Vector2i(43,18),0)
	accounting.damage_structure(wall.cell,17)
	accounting.player_position = Vector2(41.5,17.5)
	accounting.player.add("repair_kit",1)
	accounting.repair_at(wall.cell)
	test.check(accounting.defense.costs.damage == 17 and accounting.defense.costs.kits == 1,"In-battle repairs and actual structure health loss are counted exactly")
	accounting.damage_structure(accounting.settlements.sites.town_hall.port(),1000)
	Simulation.step(accounting)
	test.check(accounting.defense.phase == "recovery" and not accounting.defense.last_result.victory and accounting.defense.last_result.damage == 317,"Breach reports cap damage at actual health lost and retain failed-attempt costs")
	var report: Dictionary = accounting.defense.last_result.duplicate()
	accounting.player_position = Vector2(41.5,13.5)
	accounting.player.add("repair_kit",6)
	for i in range(6): accounting.repair_at(accounting.settlements.sites.town_hall.port())
	test.check(accounting.defense.last_result == report,"Recovery repairs do not rewrite the finished battle's in-battle cost report")
	accounting.defense.begin(accounting)
	test.check(accounting.defense.costs == {"ammo":0,"kits":0,"damage":0} and accounting.defense.last_result == report,"Retry starts fresh counters while retaining the previous outcome for comparison")

static func ui(test: SceneTree) -> void:
	var scene = load("res://main.tscn").instantiate()
	test.root.add_child(scene)
	await test.process_frame
	scene.set_process(false)
	scene.hud.story_panel.dismiss_silently()
	var world = preload("res://tests/combat_readiness_tests.gd").winner()
	scene._bind_world(world)
	scene._inspect_site("town_hall")
	test.check(scene.hud.town_panel.after_action.visible and scene.hud.town_panel.after_action.text.contains("8 rounds"),"Finished defense costs are visible in the Hall briefing")
	scene._bind_world(later(6))
	scene._inspect_site("town_hall")
	test.check(scene.hud.town_panel.readiness.text.contains("10-second") and scene.hud.town_panel.defense_status.text.contains("Hold the crossing"),"Briefing names the authored encounter and discloses its reinforcement pause")
	scene.queue_free()
	await test.process_frame
