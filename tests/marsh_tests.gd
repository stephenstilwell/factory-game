extends RefCounted
const Fixtures = preload("res://tests/fixtures.gd")
const Saves = preload("res://scripts/persistence/save_service.gd")
const Simulation = preload("res://scripts/simulation/simulation.gd")
static func bank(world: RefCounted) -> void:
	world.player_position = Vector2(world.frontier.marsh.shore(world.frontier))+Vector2.ONE*0.5
	world.previous_position = world.player_position
static func ready(world: RefCounted) -> void:
	bank(world)
	world.player.contents = {"plank":44,"stone":46,"wire":8}
	for i in range(4): world.frontier.marsh.build_span(world)
	world.player_position = Vector2(world.frontier.port("marsh"))+Vector2.ONE*0.5
	world.previous_position = world.player_position
	world.frontier.claim(world,"marsh")
	world.frontier.marsh.restore_lodge(world)
static func run(test: SceneTree) -> void:
	for seed_value in [0,1,74103,-2000000000,2000000000,1063638934]:
		var a := Fixtures.industrial(seed_value)
		var b := Fixtures.industrial(seed_value)
		test.check(a.frontier.sites.has("marsh") and a.frontier.sites.marsh == b.frontier.sites.marsh,"Reedwater placement is repeatable for seed %d" % seed_value)
		var marsh: RefCounted = a.frontier.marsh
		var area: Rect2i = marsh.bounds(a.frontier.sites.marsh.origin)
		var safe := true
		for x in range(area.position.x,area.end.x):
			for y in range(area.position.y,area.end.y):
				var cell := Vector2i(x,y)
				if marsh.water_at(a.frontier,cell):
					safe = safe and a.terrain.tile(cell).is_empty() and a.settlements.at(cell) == null and not a.frontier.tree_at(a,cell)
		test.check(safe and not a.solid(marsh.shore(a.frontier)),"Marsh preserves ore, civic land and a dry western approach")
	var world := Fixtures.industrial()
	var marsh: RefCounted = world.frontier.marsh
	bank(world)
	var first: Vector2i = marsh.span(world.frontier,0)
	test.check(world.solid(first) and not world._walkable(Vector2(first)+Vector2.ONE*0.5),"Unbridged water blocks actual player movement")
	test.check(not world.can_build("belt",first,false).is_empty(),"Ordinary factory construction refuses water")
	world.move_direction = Vector2.RIGHT
	for i in range(8): world.move_player()
	test.check(world.player_position.x < first.x,"Movement cannot cross the unbuilt water gap")
	bank(world)
	var before := Saves.encode(world)
	var built_without_goods: bool = marsh.build_span(world)
	var after := Saves.encode(world)
	test.check(not built_without_goods and after.frontier == before.frontier and after.player == before.player and after.skills == before.skills,"Insufficient materials cannot alter construction, materials or XP")
	world.player.contents = {"plank":44,"stone":46,"wire":8}
	world.early.phase = 1
	test.check(not marsh.build_span(world),"Marsh construction waits until the original crossing is rebuilt")
	world.early.phase = 2
	test.check(marsh.build_span(world) and marsh.sections == 1 and world.player.count("plank") == 38 and not world.solid(first),"A paid span opens exactly one physical water tile")
	var loaded := Saves.decode(JSON.parse_string(JSON.stringify(Saves.encode(world))))
	test.check(loaded.error.is_empty() and loaded.world.frontier.marsh.sections == 1,"Partial causeway saves and resumes")
	world.player_position = Vector2(first)+Vector2.ONE*0.5
	test.check(not marsh.remove_span(world) and marsh.sections == 1,"Player cannot reclaim the span beneath them")
	bank(world)
	test.check(marsh.remove_span(world) and world.player.count("plank") == 44 and world.player.count("stone") == 46 and world.solid(first),"Reclaiming the farthest span safely refunds its exact materials")
	for i in range(4): test.check(marsh.build_span(world),"Causeway section builds sequentially")
	var cost: Dictionary = world.player.contents.duplicate()
	test.check(not marsh.build_span(world) and world.player.contents == cost,"Complete causeways cannot consume a fifth construction cost")
	var span: Vector2i = marsh.span(world.frontier,2)
	world.player_position = Vector2(span)+Vector2(0.5,-0.5)
	test.check(world.can_build("chest",span,false).contains("narrow causeway") and world.can_build("belt",span,false).is_empty(),"Causeway supports conveyors while preserving a walkable lane")
	bank(world)
	world.move_direction = Vector2.RIGHT
	for i in range(20): world.move_player()
	test.check(world.player_position.x >= world.frontier.port("marsh").x,"Completed spans physically connect shore to lodge")
	test.check(not marsh.remove_span(world),"Causeway cannot be removed while the player is on the island side")
	test.check(not marsh.restore_lodge(world),"Keeper ledger is required before lodge restoration")
	test.check(world.frontier.claim(world,"marsh"),"Crossing unlocks the one-time keeper ledger reward")
	var repair_before := world.repair_power()
	test.check(marsh.restore_lodge(world) and world.player.total() == 0 and world.repair_power() == roundi(repair_before*1.25),"Lodge consumes disclosed materials and applies its real repair bonus")
	var xp: int = world.skills.xp.fabrication
	test.check(not marsh.restore_lodge(world) and world.skills.xp.fabrication == xp,"Lodge cannot duplicate restoration rewards")
	test.check(not marsh.remove_span(world),"Restored service keeps its permanent causeway")
	test.check(world.logistics_receiver(world.frontier.port("marsh")) == marsh and world.logistics_source(world.frontier.port("marsh")) == marsh,"Marsh hatch participates in existing logistics interfaces")
	world.player.contents = marsh.INPUTS.duplicate()
	test.check(marsh.supply(world) and world.player.total() == 0,"Manual supply transfers real batch materials")
	marsh.step(world)
	test.check(marsh.work_ticks == 599 and marsh.inventory.total() == 0 and marsh.output.total() == 0,"Workshop commits input at the start without granting early output")
	loaded = Saves.decode(JSON.parse_string(JSON.stringify(Saves.encode(world))))
	test.check(loaded.error.is_empty() and loaded.world.frontier.marsh.work_ticks == 599,"Committed maintenance batch resumes without repeated input")
	var resumed: RefCounted = loaded.world if loaded.error.is_empty() else world
	for i in range(599): resumed.frontier.marsh.step(resumed)
	test.check(resumed.frontier.marsh.output.count("repair_kit") == 3,"A complete 60-second batch produces exactly three kits")
	test.check(resumed.frontier.marsh.collect(resumed) and resumed.player.count("repair_kit") == 3,"Kit collection transfers actual output")
	var chest = resumed.spawn("chest",resumed.frontier.port("marsh")+Vector2i(-1,1),0)
	chest.health = 1
	test.check(resumed.repair_at(chest.cell) and chest.health == mini(chest.max_health(),1+resumed.repair_power()) and resumed.player.count("repair_kit") == 2,"Actual building repair consumes one kit and uses the restored lodge bonus")
	resumed.frontier.marsh.output.contents = {"repair_kit":12}
	resumed.frontier.marsh.inventory.contents = marsh.INPUTS.duplicate()
	resumed.frontier.marsh.step(resumed)
	test.check(resumed.frontier.marsh.work_ticks == 0 and resumed.frontier.marsh.inventory.contents == marsh.INPUTS,"Full output never starts an unreserved batch")
	# Fresh automated lodge: inserter south feeds, inserter north extracts.
	var auto := Fixtures.industrial()
	ready(auto)
	var port: Vector2i = auto.frontier.port("marsh")
	var input = auto.spawn("chest",port+Vector2i(0,2),0)
	input.inventory.contents = auto.frontier.marsh.INPUTS.duplicate()
	auto.spawn("inserter",port+Vector2i.DOWN,3)
	var output = auto.spawn("chest",port+Vector2i(0,-2),0)
	auto.spawn("inserter",port+Vector2i.UP,3)
	for i in range(100): Simulation._inserters(auto)
	test.check(auto.frontier.marsh.inventory.contents == auto.frontier.marsh.INPUTS and input.inventory.total() == 0,"Inserters supply the lodge with conserved physical ingredients")
	for i in range(600): auto.frontier.marsh.step(auto)
	for i in range(40): Simulation._inserters(auto)
	test.check(output.inventory.count("repair_kit") == 3 and auto.frontier.marsh.output.total() == 0,"Inserters extract finished maintenance kits")
	var auto_result := Saves.decode(Saves.encode(auto))
	test.check(auto_result.error.is_empty(),"Restored automated lodge survives save validation")
	var bad := Saves.encode(auto)
	bad.frontier.marsh.sections = 3
	test.check(not Saves.decode(bad).error.is_empty(),"Restored lodge rejects a missing causeway section")
	bad = Saves.encode(auto)
	bad.frontier.marsh.work_ticks = 600
	test.check(not Saves.decode(bad).error.is_empty(),"Save rejects impossible maintenance timer")
	bad = Saves.encode(auto)
	bad.frontier.marsh.inventory = {"stone":1}
	test.check(not Saves.decode(bad).error.is_empty(),"Save rejects unsupported maintenance stock")
	bad = Saves.encode(auto)
	bad.position = [first.x+0.5,first.y+1.5]
	test.check(not Saves.decode(bad).error.is_empty(),"Save rejects a player stranded in unbridged water")
	bad = Saves.encode(auto)
	bad.frontier.erase("marsh")
	test.check(not Saves.decode(bad).error.is_empty(),"Pre-marsh development saves are rejected without silent terrain conversion")
	var nav_world := Fixtures.industrial()
	bank(nav_world)
	var nav_marsh: RefCounted = nav_world.frontier.marsh
	nav_world.settlements.sites.town_hall.origin = nav_world.frontier.sites.marsh.origin+Vector2i(-2,0)
	var nav := preload("res://scripts/simulation/combat_navigation.gd").new()
	var enemy := {"kind":"scout","cell":nav_marsh.shore(nav_world.frontier)}
	nav.next_cell(nav_world,enemy)
	test.check(nav.grids.scout.is_point_solid(nav_marsh.span(nav_world.frontier,0)),"Enemy navigation marks water as impassable rather than a destructible wall")
	nav_world.player.contents = {"plank":24,"stone":16}
	for i in range(4): nav_marsh.build_span(nav_world)
	nav.next_cell(nav_world,enemy)
	test.check(not nav.grids.scout.is_point_solid(nav_marsh.span(nav_world.frontier,0)),"Causeway topology changes invalidate enemy navigation")
static func ui(test: SceneTree) -> void:
	var world := Fixtures.industrial()
	bank(world)
	world.player.contents = {"plank":6,"stone":4}
	var panel := preload("res://scripts/ui/frontier_panel.gd").new()
	test.root.add_child(panel)
	panel.open_panel(world,"marsh")
	test.check(panel.marsh_box.visible and not panel.marsh_build.disabled and panel.marsh_text.text.contains("+25%") and panel.marsh_text.text.contains("WEST bank"),"Marsh UI discloses route, cost and meaningful reward")
	panel.marsh_build.pressed.emit()
	test.check(world.frontier.marsh.sections == 1 and not panel.marsh_remove.disabled,"Panel causeway action builds actual terrain and offers safe refund")
	panel.marsh_remove.pressed.emit()
	test.check(world.frontier.marsh.sections == 0 and world.player.count("plank") == 6,"Panel refund restores materials")
	panel.queue_free()
	await test.process_frame
	var scene = load("res://main.tscn").instantiate()
	test.root.add_child(scene)
	await test.process_frame
	scene.set_process(false)
	scene.hud.story_panel.dismiss_silently()
	var state := Fixtures.industrial()
	scene._bind_world(state)
	bank(state)
	scene.hud.survey.chart.open(state)
	var water: Vector2i = state.frontier.marsh.span(state.frontier,0)
	test.check(scene.hud.survey.chart._get_tooltip(scene.hud.survey.chart.point(Vector2(water)+Vector2.ONE*0.5)).contains("water"),"Map identifies charted marsh water")
	ready(state)
	test.check(scene.hud.history.entries.any(func(entry): return entry.destination == "discoveries" and entry.subject == "marsh"),"Successful lodge restoration records an actionable update")
	scene._history_navigate("discoveries","marsh")
	test.check(scene.hud.frontier_panel.visible and scene.hud.frontier_panel.selected == "marsh" and scene.hud.frontier_panel.marsh_text.text.contains("%d HP" % state.repair_power()),"Restoration update navigates to the service and shows effective repair power")
	test.check(scene.hud.survey.chart._get_tooltip(scene.hud.survey.chart.point(Vector2(water)+Vector2.ONE*0.5)).contains("causeway"),"Map reflects constructed causeway topology")
	scene.view.paused = false
	scene.view.nature_audio.step(0.1,scene.view)
	test.check(scene.view.nature_audio.current_region == 3 and scene.view.nature_audio.voices[3].data != scene.view.nature_audio.voices[2].data,"Marsh selects a separate water/frog ambient waveform")
	scene.queue_free()
	await test.process_frame
