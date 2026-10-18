extends Node2D
## One-pass light field with a fixed uniform budget; no per-light world redraw.
const Visibility = preload("res://scripts/view/light_visibility.gd")
const LIMIT := 12
const DAYLIGHT := Color(0.91,0.95,0.99)
var view: Node2D
var daylight := Color.WHITE
var pool: Array[Dictionary] = []
var sources: Array = []
var refresh_left := 0.0
var world_token := 0
var topology := -1
var last_area := Rect2i()
var previous_enabled := false
var lighting_material: ShaderMaterial
var visibility_texture: ImageTexture
var visibility_key := 0
var visibility_ready := false
var visibility_refresh := 0.0
func _ready() -> void:
	lighting_material = ShaderMaterial.new()
	lighting_material.shader = preload("res://assets/shaders/world_lighting.gdshader")
	view.material = lighting_material
	for i in range(LIMIT): pool.append({"visible":false,"energy":0.0})

static func collect(world: RefCounted, area: Rect2i, camera: Vector2) -> Array:
	var result: Array = []
	if world.settlements.enabled:
		for site in world.settlements.sites.values():
			if site.repaired and site.health > 0 and area.intersects(site.footprint().grow(3)):
				result.append({"position":Vector2(site.origin)*48+Vector2(73,103),"radius":150.0,"energy":0.42,"key":"site:"+site.id})
	if world.frontier.marsh.restored and world.frontier.sites.has("marsh") and area.intersects(world.frontier.footprint("marsh").grow(3)):
		result.append({"position":Vector2(world.frontier.sites.marsh.origin)*48+Vector2(118,106),"radius":170.0,"energy":0.42,"key":"marsh"})
	for y in range(area.position.y,area.end.y):
		for x in range(area.position.x,area.end.x):
			var entity = world.at(Vector2i(x,y))
			if entity == null or entity.health <= 0: continue
			var radius := 0.0
			var energy := 0.0
			if entity.kind == "cottage":
				radius = 82; energy = 0.28
			elif entity.kind == "communal_hearth":
				radius = 116; energy = 0.5
			elif entity.kind in ["furnace","charcoal_kiln"] and entity.status == "Working":
				radius = 105; energy = 0.5
			elif entity.kind == "generator" and entity.status.begins_with("Generating"):
				radius = 80; energy = 0.26
			if radius > 0:
				result.append({"position":(Vector2(entity.cell)+Vector2(0.5,0.65))*48,"radius":radius,"energy":energy,"key":"entity:%d" % entity.id})
	# Nearest sources win; tie-breakers keep the pool stable as machines change state.
	result.sort_custom(func(a,b):
		var da: float = a.position.distance_squared_to(camera)
		var db: float = b.position.distance_squared_to(camera)
		return a.key < b.key if is_equal_approx(da,db) else da < db)
	if result.size() > LIMIT: result.resize(LIMIT)
	return result

func sync(delta: float = 0.2) -> void:
	if view == null or view.world == null: return
	daylight = DAYLIGHT if view.ambient_enabled else Color.WHITE
	var desired: Material = lighting_material if view.ambient_enabled else null
	if view.material != desired: view.material = desired
	refresh_left -= delta
	var token: int = view.world.get_instance_id()
	if refresh_left <= 0 or token != world_token or last_area != view.visible_cells or topology != view.world.navigation_revision or previous_enabled != view.ambient_enabled:
		sources = collect(view.world,view.visible_cells,view.camera.position) if view.ambient_enabled else []
		refresh_left = 0.15
		world_token = token
		topology = view.world.navigation_revision
		last_area = view.visible_cells
		previous_enabled = view.ambient_enabled
	visibility_refresh -= delta
	if view.ambient_enabled and view.detailed_lighting and (visibility_refresh <= 0 or not visibility_ready):
		visibility_refresh = 0.15
		var shapes := Visibility.blockers(view.world,view.visible_cells)
		var key := hash([sources,shapes])
		if not visibility_ready or key != visibility_key:
			var image := Visibility.bake(sources,shapes)
			if visibility_texture == null: visibility_texture = ImageTexture.create_from_image(image)
			else: visibility_texture.update(image)
			visibility_key = key
			visibility_ready = true
			lighting_material.set_shader_parameter("visibility_atlas",visibility_texture)
	lighting_material.set_shader_parameter("detailed_lighting",view.detailed_lighting)
	var fields := PackedVector4Array()
	var energies := PackedFloat32Array()
	for i in range(pool.size()):
		var light: Dictionary = pool[i]
		light.visible = i < sources.size()
		if not light.visible:
			fields.append(Vector4(0,0,1,0))
			energies.append(0.0)
			continue
		var source: Dictionary = sources[i]
		var pulse := 1.0 if view.reduced_motion or view.paused else 1.0+sin(view.animation_time*1.7+i)*0.025
		light.energy = source.energy*pulse
		fields.append(Vector4(source.position.x,source.position.y,source.radius,0))
		energies.append(light.energy)
	lighting_material.set_shader_parameter("daylight",Vector3(daylight.r,daylight.g,daylight.b))
	lighting_material.set_shader_parameter("light_fields",fields)
	lighting_material.set_shader_parameter("light_energy",energies)
