extends RefCounted
const Fixtures = preload("res://tests/fixtures.gd")
const Saves = preload("res://scripts/persistence/save_service.gd")
const Regions = preload("res://scripts/data/biome_catalog.gd")
const Scenery = preload("res://scripts/view/region_scenery.gd")
const Nature = preload("res://scripts/audio/nature_audio.gd")
static func run(test: SceneTree) -> void:
	var world := Fixtures.industrial()
	var before := Saves.encode(world)
	for id in ["orchard","quarry"]:
		var definition: Dictionary = Regions.REGIONS[id]
		var center: Vector2i = world.frontier.sites[id].origin+Vector2i(2,2)
		test.check(world.frontier.landscape_index(center) == definition.index and world.frontier.landscape_weight(center,id) == 1,"Region center retains its established identity: " + id)
		var edge := center+Vector2i(int(definition.radius),0)
		var transition := center+Vector2i(int(definition.radius)-3,0)
		test.check(world.frontier.landscape_weight(edge,id) == 0 and world.frontier.landscape_weight(transition,id) > 0 and world.frontier.landscape_weight(transition,id) < 1,"Region ground blends continuously near its existing border: " + id)
		var area := Rect2i(center-Vector2i(12,12),Vector2i(24,24))
		var props := Scenery.candidates(world,area)
		test.check(not props.is_empty() and props.size() <= Scenery.LIMIT and props == Scenery.candidates(world,area),"Region ornaments are seeded, deterministic and bounded: " + id)
		var safe := true
		for prop in props:
			var cell: Vector2i = prop.cell
			safe = safe and area.has_point(cell) and world.at(cell) == null and world.settlements.at(cell) == null and not world.terrain.chunks[world.terrain.chunk_at(cell)].has(cell) and not world.frontier.tree_at(world,cell)
		test.check(safe,"Ornaments avoid buildings, living trees and original ore masks: " + id)
		if not props.is_empty():
			var cell: Vector2i = props[0].cell
			var solid: bool = world.solid(cell)
			Scenery.candidates(world,area)
			test.check(world.solid(cell) == solid,"Decorative scenery does not add terrain collision: " + id)
			world.frontier.forestry.plots[cell] = {}
			test.check(not Scenery.candidates(world,area).any(func(prop): return prop.cell == cell),"Scenery yields to managed forestry plots: " + id)
			world.frontier.forestry.plots.erase(cell)
	test.check(Saves.encode(world) == before,"Region classification and decoration leave authoritative saves unchanged")
	var birds := Nature.build_voice(0)
	var orchard := Nature.build_voice(1)
	var wind := Nature.build_voice(2)
	test.check(birds.data != orchard.data and orchard.data != wind.data and wind.data.size() > birds.data.size(),"Regional ambience uses distinct cached bird, orchard trill and wind/stone waveforms")
	test.check(wind.mix_rate == 22050 and birds.format == AudioStreamWAV.FORMAT_16_BITS,"Regional audio uses bounded standard mono samples")
static func ui(test: SceneTree) -> void:
	var scene = load("res://main.tscn").instantiate()
	test.root.add_child(scene)
	await test.process_frame
	scene.set_process(false)
	scene.hud.story_panel.dismiss_silently()
	var world := Fixtures.industrial()
	scene._bind_world(world)
	world.player_position = Vector2(world.frontier.sites.orchard.origin)+Vector2(1,1)
	scene.hud.refresh()
	test.check(scene.hud.status.text.contains("Farmlands"),"HUD identifies the region the player is exploring")
	var audio = scene.view.nature_audio
	scene.view.paused = false
	scene.view.ambient_enabled = true
	audio.step(0.1,scene.view)
	test.check(audio.current_region == 1 and audio.voices.size() == 4,"Orchard ambience switches palette without creating more voices")
	world.player_position = Vector2(world.frontier.sites.quarry.origin)+Vector2(1,1)
	audio.step(0.1,scene.view)
	test.check(audio.current_region == 2 and audio.stream == audio.voices[2],"Greybank selects the wind/stone palette")
	scene.view.ambient_enabled = false
	audio.step(0.1,scene.view)
	test.check(not audio.playing,"Ambient preference stops regional sound playback")
	scene.queue_free()
	await test.process_frame
