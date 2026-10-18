extends RefCounted
const Hero = preload("res://scripts/view/hero_art.gd")
const Fixtures = preload("res://tests/fixtures.gd")
const Saves = preload("res://scripts/persistence/save_service.gd")
static func run(test: SceneTree) -> void:
	var texture_ids: Dictionary = {}
	for id in Hero.ATLASES:
		var entry: Dictionary = Hero.ATLASES[id]
		var texture: Texture2D = entry.texture
		texture_ids[texture.get_instance_id()] = true
		test.check(texture.get_width() == int(entry.size.x*entry.frames*2) and texture.get_height() == int(entry.size.y*2),"Hero atlas imports at its documented 2x resolution: "+id)
		var safe := true
		for frame in range(entry.frames):
			var source := Hero.source(id,frame)
			safe = safe and source.size == entry.size*2 and Rect2(Vector2.ZERO,texture.get_size()).encloses(source)
		test.check(safe,"All hero frames stay inside their texture and cannot sample another row: "+id)
	test.check(texture_ids.size() == 4,"Hero pilot shares four texture resources rather than per-entity render targets")
	var active: Dictionary = {}
	for tick in range(12): active[Hero.furnace_frame(true,true,tick/5.0,0)] = true
	test.check(active.size() == 4 and not active.has(Hero.furnace_frame(false,true,0,0)) and not active.has(Hero.furnace_frame(true,false,0,0)),"Working kiln animation remains separate from cold and damaged artwork")
	test.check(Hero.hall_frame(true,true,true) != Hero.hall_frame(true,true,false) and Hero.hall_frame(false,false,true) != Hero.hall_frame(true,false,true),"Civic artwork preserves construction age, ruin and disabled distinctions")
static func ui(test: SceneTree) -> void:
	var scene = load("res://main.tscn").instantiate()
	test.root.add_child(scene)
	await test.process_frame
	scene.set_process(false)
	scene.hud.story_panel.dismiss_silently()
	var world := Fixtures.industrial()
	var furnace = world.spawn("furnace",Vector2i(20,18),0)
	scene._bind_world(world)
	scene.camera.position = Vector2(20,18)*48
	scene.view.paused = true
	scene.view.reduced_motion = true
	var before := Saves.encode(world)
	for i in range(8): await test.process_frame
	var children: int = scene.view.get_child_count()
	for i in range(16):
		scene.view.queue_redraw()
		await test.process_frame
	test.check(scene.view.get_child_count() == children,"Hero body redraws do not allocate per-machine sprite nodes or viewports")
	test.check(world.at(Vector2i(20,18)) == furnace and world.solid(Vector2i(20,18)),"New furnace art retains its original gameplay footprint")
	test.check(Saves.encode(world) == before,"Atlas drawing, sprite variants and player visuals leave gameplay and saves unchanged")
	scene.hud.toggle_crafting()
	scene.hud.crafting.select_recipe("furnace")
	for i in range(3): await test.process_frame
	test.check(scene.hud.crafting.visible,"Shared furnace art remains available in the crafting workspace")
	scene.queue_free()
	await test.process_frame
