extends SceneTree
const Hero = preload("res://scripts/view/hero_art.gd")
const Visibility = preload("res://scripts/view/light_visibility.gd")
var failures := 0
class Sample extends Node2D:
	func _draw() -> void:
		draw_rect(Rect2(0,0,600,400),Color(0.4,0.4,0.4))
		Hero.paint(self,"furnace",0,Vector2(250,230),2)
		Hero.paint(self,"town_hall",2,Vector2(380,90))
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func shot() -> Image:
	for i in range(4): await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()
func run() -> void:
	root.size = Vector2i(600,400)
	root.content_scale_size = root.size
	var canvas := Sample.new()
	root.add_child(canvas)
	var material := ShaderMaterial.new()
	material.shader = preload("res://assets/shaders/world_lighting.gdshader")
	canvas.material = material
	var fields := PackedVector4Array()
	var energy := PackedFloat32Array()
	for i in range(12):
		fields.append(Vector4(180,180,250,0))
		energy.append(0.8 if i == 0 else 0.0)
	var sources := [{"position":Vector2(180,180),"radius":250.0}]
	var clear := Visibility.bake(sources,[])
	var shapes: Array[Rect2] = [Rect2(205,0,25,400)]
	check(Visibility.visible(Vector2(180,180),Vector2(150,180),shapes),"Wall leaves light's near side visible")
	check(not Visibility.visible(Vector2(180,180),Vector2(300,180),shapes),"Wall blocks far side")
	check(Visibility.visible(Vector2(210,180),Vector2(300,180),shapes),"Source inside civic footprint is not self-blocked")
	var atlas := ImageTexture.create_from_image(clear)
	material.set_shader_parameter("light_fields",fields)
	material.set_shader_parameter("light_energy",energy)
	material.set_shader_parameter("visibility_atlas",atlas)
	material.set_shader_parameter("daylight",Vector3(0.91,0.95,0.99))
	material.set_shader_parameter("detailed_lighting",false)
	var simple := await shot()
	material.set_shader_parameter("detailed_lighting",true)
	var detailed := await shot()
	check(simple.get_data() != detailed.get_data(),"Authored material maps affect rendered pixels")
	# Plain, unmapped ground must keep its material appearance.
	check(simple.get_pixel(160,160).is_equal_approx(detailed.get_pixel(160,160)),"Flat default textures do not acquire specular highlights")
	atlas.update(Visibility.bake(sources,shapes))
	var blocked := await shot()
	check(blocked.get_pixel(300,180).r < detailed.get_pixel(300,180).r,"Baked occlusion darkens far-side ground on the GPU")
	check(blocked.get_pixel(150,180).is_equal_approx(detailed.get_pixel(150,180)),"Occlusion leaves the near side unchanged")
	DirAccess.make_dir_recursive_absolute("res://.godot/verification")
	detailed.save_png("res://.godot/verification/g3_materials.png")
	blocked.save_png("res://.godot/verification/g3_occlusion.png")
	material.set_shader_parameter("detailed_lighting",false)
	check((await shot()).get_data() == simple.get_data(),"Fallback bypasses maps and occlusion deterministically")
	check(Hero.surface("furnace") == Hero.surface("furnace"),"All furnaces reuse one CanvasTexture")
	canvas.queue_free()
	await process_frame
	root.size = Vector2i(1100,720)
	root.content_scale_size = root.size
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	scene.view.set_process(false)
	scene.hud.story_panel.dismiss_silently()
	var world = preload("res://tests/fixtures.gd").industrial()
	world.spawn("furnace",Vector2i(150,150),0).status = "Working"
	var wall = world.spawn("wall",Vector2i(151,150),0)
	scene._bind_world(world)
	scene.view.visible_cells = Rect2i(145,145,15,15)
	scene.view.ambient_enabled = true
	scene.view.detailed_lighting = true
	var before = preload("res://scripts/persistence/save_service.gd").encode(world)
	scene.view.lighting.sync()
	var texture = scene.view.lighting.visibility_texture
	var key = scene.view.lighting.visibility_key
	scene.view.lighting.sync()
	check(texture == scene.view.lighting.visibility_texture,"Unchanged scene reuses its visibility texture")
	check(preload("res://scripts/persistence/save_service.gd").encode(world) == before,"Lighting leaves simulation and save data untouched")
	wall.health = 0
	scene.view.lighting.sync()
	check(key != scene.view.lighting.visibility_key,"Destroyed walls invalidate occlusion in the actual world")
	check(texture == scene.view.lighting.visibility_texture,"Topology updates reuse the same GPU texture")
	scene.hud.pause_menu.show()
	await shot()
	var scroll: ScrollContainer = scene.hud.pause_content.get_parent()
	check(root.get_visible_rect().encloses(scroll.get_global_rect()),"Presentation viewport fits the minimum window")
	scroll.scroll_vertical = 10000
	await shot()
	check(scroll.get_global_rect().intersects(scene.hud.pause_content.get_child(-1).get_global_rect()),"Last pause action remains reachable with the new controls")
	scene.queue_free()
	await process_frame
	print("G3 native lighting: ",failures," failures")
	quit(1 if failures else 0)
