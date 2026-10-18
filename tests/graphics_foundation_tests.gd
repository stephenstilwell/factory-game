extends RefCounted
const Fixtures = preload("res://tests/fixtures.gd")
const Saves = preload("res://scripts/persistence/save_service.gd")
const Lighting = preload("res://scripts/view/world_lighting.gd")
const Water = preload("res://scripts/view/water_surface.gd")
static func run(test: SceneTree) -> void:
	var world := Fixtures.industrial()
	for y in range(10):
		for x in range(10):
			var furnace = world.spawn("furnace",Vector2i(150+x,150+y),0)
			furnace.status = "Working"
	var area := Rect2i(149,149,13,13)
	var before := Saves.encode(world)
	var sources := Lighting.collect(world,area,Vector2(155,155)*48)
	test.check(sources.size() == Lighting.LIMIT and sources == Lighting.collect(world,area,Vector2(155,155)*48),"Dense factories select a deterministic capped set of visible lights")
	test.check(Lighting.collect(world,Rect2i(-200,-200,5,5),Vector2(-200,-200)*48).is_empty(),"Offscreen factories create no illumination sources")
	var furnace = world.at(Vector2i(155,155))
	furnace.health = 0
	test.check(not Lighting.collect(world,area,Vector2(155,155)*48).any(func(source): return source.key == "entity:%d" % furnace.id),"Disabled machines cannot remain warm light sources")
	furnace.health = furnace.max_health()
	var marsh: RefCounted = world.frontier.marsh
	var bounds: Rect2i = marsh.bounds(world.frontier.sites.marsh.origin)
	var samples := Water.samples(world,bounds)
	test.check(not samples.is_empty() and samples.size() <= Water.LIMIT and samples == Water.samples(world,bounds),"Water highlights use deterministic bounded visible samples")
	test.check(samples.all(func(cell): return marsh.blocked(world.frontier,cell)),"Surface highlights match physical water")
	marsh.sections = 4
	test.check(Water.samples(world,bounds).all(func(cell): return not marsh.boardwalk(world.frontier,cell)),"Water surface detail yields to completed causeway tiles")
	marsh.sections = 0
	test.check(Water.samples(world,Rect2i(-200,-200,8,8)).is_empty(),"Water detail does not scan or draw distant regions")
	test.check(Saves.encode(world) == before,"Light and water presentation queries do not alter simulation or saves")
static func ui(test: SceneTree) -> void:
	var scene = load("res://main.tscn").instantiate()
	test.root.add_child(scene)
	await test.process_frame
	scene.set_process(false)
	scene.hud.story_panel.dismiss_silently()
	var world := Fixtures.industrial()
	world.spawn("furnace",Vector2i(19,18),0).status = "Working"
	scene._bind_world(world)
	scene.camera.position = Vector2(19,18)*48
	scene.view.visible_cells = Rect2i(10,10,25,20)
	var lighting = scene.view.lighting
	scene.view.ambient_enabled = true
	lighting.sync()
	var before := Saves.encode(world)
	test.check(lighting.pool.size() == Lighting.LIMIT and lighting.sources.size() == 1,"World owns one fixed pool of reusable local lights")
	var nodes: int = lighting.get_child_count()
	for i in range(20): lighting.sync()
	test.check(lighting.get_child_count() == nodes,"Lighting updates reuse nodes without accumulating scene objects")
	test.check(lighting.daylight == Lighting.DAYLIGHT and lighting.lighting_material == scene.view.material,"Ambient-enabled world applies the fixed daylight profile")
	test.check(scene.hud is CanvasLayer and not lighting.is_ancestor_of(scene.hud),"World grading cannot tint the HUD canvas")
	scene.view.paused = true
	scene.view.animation_time = 7
	lighting.sync()
	var energy: float = lighting.pool[0].energy
	scene.view.animation_time = 9
	lighting.sync()
	test.check(is_equal_approx(energy,lighting.pool[0].energy),"Paused light intensity remains static")
	scene.view.paused = false
	scene.view.reduced_motion = true
	lighting.sync()
	energy = lighting.pool[0].energy
	scene.view.animation_time = 15
	lighting.sync()
	test.check(is_equal_approx(energy,lighting.pool[0].energy),"Reduced motion disables decorative light flicker")
	scene.view.ambient_enabled = false
	lighting.sync()
	test.check(lighting.daylight == Color.WHITE and scene.view.material == null and lighting.pool.all(func(light): return not light.visible),"Ambient-off restores neutral daylight and disables the whole local light pool")
	scene.view.ambient_enabled = true
	lighting.sync()
	test.check(lighting.sources.size() == 1 and lighting.pool[0].visible,"Ambient lighting can be re-enabled without recreating lights")
	var a = preload("res://scripts/view/terrain_chunk.gd").new()
	var b = preload("res://scripts/view/terrain_chunk.gd").new()
	for chunk in [a,b]:
		chunk.terrain = world.terrain
		chunk.frontier = world.frontier
		scene.view.add_child(chunk)
	b.chunk = Vector2i(1,0)
	test.check(a._ground_color(Vector2i(16,8)) == b._ground_color(Vector2i(16,8)),"Ground shading samples the same world coordinates across chunk borders")
	await test.process_frame
	test.check(preload("res://scripts/view/art.gd").grain != null and preload("res://scripts/view/art.gd").grain.get_width() == 128,"Ground material detail shares one bounded reusable texture")
	test.check(Saves.encode(world) == before,"Daylight, shadows, material rendering and water polish leave saves unchanged")
	scene.queue_free()
	await test.process_frame
