extends Node2D
## Terrain CanvasItems are cached by chunk; dynamic drawing visits visible cells only.

const Catalog = preload("res://scripts/data/catalog.gd")
const World = preload("res://scripts/simulation/world.gd")
const ChunkView = preload("res://scripts/view/terrain_chunk.gd")
const SettlementView = preload("res://scripts/view/settlement_view.gd")
const DefenseView = preload("res://scripts/view/defense_view.gd")
const LandscapeView = preload("res://scripts/view/landscape_view.gd")
const MachineArt = preload("res://scripts/view/machine_art.gd")
const NpcArt = preload("res://scripts/view/npc_art.gd")
const EngineerArt = preload("res://scripts/view/engineer_art.gd")
const Art = preload("res://scripts/view/art.gd")
const Atmosphere = preload("res://scripts/view/atmosphere.gd")
const Effects = preload("res://scripts/view/visual_effects.gd")
const PlanLayer = preload("res://scripts/view/plan_layer.gd")
const PlacementPreview = preload("res://scripts/view/placement_preview.gd")
const Transport = preload("res://scripts/simulation/transport.gd")
const TILE := 48
const TEAL := Color("80d8ba")

var world: RefCounted
var camera: Camera2D
var chunks: Dictionary = {}
var visible_cells := Rect2i()
var selected := Vector2i(999999, 999999)
var selected_site := ""
var hover := Vector2i.ZERO
var ghost_kind := ""
var facing := 0
var underground_exit := false
var pointer_in_world := false
var animation_time := 0.0
var paused := false
var interpolation := 1.0
var resource_target: Dictionary = {}
var effects := Effects.new()
var engineer_facing := Vector2.DOWN
var placement: Node2D
var plan_layer: Node2D
var copy_rect := Rect2i()
var reduced_motion := false
var ambient_enabled := true

func _ready() -> void:
	placement = PlacementPreview.new()
	add_child(placement)
	placement.hide()
	var atmosphere := Atmosphere.new()
	atmosphere.world_view = self
	atmosphere.z_index = 1
	add_child(atmosphere)
	plan_layer = PlanLayer.new()
	plan_layer.z_index = 2
	add_child(plan_layer)

func bind(state: RefCounted, view_camera: Camera2D) -> void:
	if world != null:
		if world.hand_resource_extracted.is_connected(_on_mined): world.hand_resource_extracted.disconnect(_on_mined)
		if world.structure_repaired.is_connected(_on_repaired): world.structure_repaired.disconnect(_on_repaired)
		if world.feedback_requested.is_connected(_on_feedback): world.feedback_requested.disconnect(_on_feedback)
	world = state
	plan_layer.world = world
	for node in plan_layer.nodes.values(): node.queue_free()
	plan_layer.nodes.clear()
	plan_layer.pasting = false
	world.hand_resource_extracted.connect(_on_mined)
	world.structure_repaired.connect(_on_repaired)
	world.feedback_requested.connect(_on_feedback)
	effects.clear()
	engineer_facing = Vector2.DOWN
	camera = view_camera
	for node in chunks.values(): node.queue_free()
	chunks.clear()

func _process(delta: float) -> void:
	if world == null: return
	placement.visible = pointer_in_world and not ghost_kind.is_empty() and world.at(hover) == null
	if placement.visible:
		placement.show_building(ghost_kind, hover, facing, world.can_build(ghost_kind, hover).is_empty())
		placement.preview.underground_exit = underground_exit and ghost_kind == "underground_belt"
	if not paused:
		animation_time += delta
		effects.step(delta)
		if world.previous_position != world.player_position and world.move_direction.length_squared() > 0.01: engineer_facing = world.move_direction.normalized()
	var half_size := get_viewport_rect().size / camera.zoom / 2
	var minimum := Vector2i(((camera.position - half_size) / TILE).floor()) - Vector2i.ONE
	var maximum := Vector2i(((camera.position + half_size) / TILE).ceil()) + Vector2i.ONE
	visible_cells = Rect2i(minimum, maximum - minimum)
	plan_layer.visible_cells = visible_cells
	var min_chunk: Vector2i = world.terrain.chunk_at(minimum)
	var max_chunk: Vector2i = world.terrain.chunk_at(maximum)
	var visible_chunks := Rect2i(min_chunk, max_chunk - min_chunk + Vector2i.ONE)
	for coordinate in chunks.keys():
		var node: Node2D = chunks[coordinate]
		node.visible = visible_chunks.has_point(coordinate)
		if not node.visible and world.terrain.dirty_chunks.has(coordinate):
			node.queue_free()
			chunks.erase(coordinate)
			continue
		if not node.visible and chunks.size() > 64:
			node.queue_free()
			chunks.erase(coordinate)
	for x in range(min_chunk.x, max_chunk.x + 1):
		for y in range(min_chunk.y, max_chunk.y + 1):
			var coordinate := Vector2i(x, y)
			if not chunks.has(coordinate):
				var node := ChunkView.new()
				node.terrain = world.terrain
				node.chunk = coordinate
				node.position = Vector2(coordinate) * 16 * TILE
				node.z_index = -1
				add_child(node)
				chunks[coordinate] = node
			if world.terrain.dirty_chunks.has(coordinate): chunks[coordinate].queue_redraw()
	world.terrain.dirty_chunks.clear()
	# Generated chunks are reproducible; depletion lives separately and survives eviction.
	if world.terrain.chunks.size() > 128:
		for coordinate in world.terrain.chunks.keys():
			if not visible_chunks.grow(2).has_point(coordinate): world.terrain.chunks.erase(coordinate)
	queue_redraw()

func _draw() -> void:
	if world == null: return
	if copy_rect.has_area(): draw_rect(Rect2(Vector2(copy_rect.position) * TILE, Vector2(copy_rect.size) * TILE), Color(0.4, 0.8, 1.0, 0.6), false, 3)
	LandscapeView.draw(self, world.settlements, visible_cells)
	_draw_tunnel_link()
	if pointer_in_world and not ghost_kind.is_empty(): _build_grid()
	DefenseView.draw_route(self, world, visible_cells, selected_site)
	var engineer: Vector2 = world.previous_position.lerp(world.player_position, interpolation) * TILE
	var drawables: Array = []
	if world.settlements.enabled:
		for site in world.settlements.sites.values():
			if visible_cells.intersects(site.footprint().grow(3)): drawables.append({"kind": "site", "data": site, "depth": (site.origin.y + 3) * TILE - 6})
	for y in range(visible_cells.position.y, visible_cells.end.y):
		for x in range(visible_cells.position.x, visible_cells.end.x):
			var entity = world.at(Vector2i(x, y))
			if entity != null: drawables.append({"kind": "machine", "data": entity, "depth": y * TILE + (18 if entity.kind in Catalog.TRANSPORT else 43)})
	if world.settlements.enabled:
		for id in world.story.Definitions.NPCS:
			var cell: Vector2i = world.story.npc_cell(world, id)
			if visible_cells.has_point(cell): drawables.append({"kind": "npc", "data": id, "depth": cell.y * TILE + 38})
	for enemy in world.defense.enemies.values():
		if visible_cells.has_point(enemy.cell): drawables.append({"kind": "enemy", "data": enemy, "depth": enemy.cell.y * TILE + 38})
	drawables.append({"kind": "engineer", "depth": engineer.y + 14})
	for drawable in drawables:
		if drawable.kind == "machine" and Catalog.BUILDINGS[drawable.data.kind].solid: _cast_shadow(drawable.data)
	drawables.sort_custom(func(a, b): return float(a.depth) < float(b.depth))
	for drawable in drawables:
		match drawable.kind:
			"site":
				SettlementView.draw_site(self, drawable.data, selected_site, world.defense.phase, animation_time)
				NpcArt.draw_homecoming(self, drawable.data, world.defense.cleared, world.defense.phase, animation_time)
				if drawable.data.id == "town_hall": NpcArt.draw_neighborhoods(self, drawable.data, world.settlements.district_level(), animation_time)
			"npc": NpcArt.draw_npc(self, world, drawable.data, animation_time, pointer_in_world and hover == world.story.npc_cell(world, drawable.data))
			"machine": _machine(drawable.data)
			"enemy": DefenseView.draw_enemy(self, drawable.data, world.defense.enemy_health(drawable.data.kind), animation_time, world.ticks, reduced_motion)
			"engineer":
				var mining: bool = world.mining and world.mining_progress > 0
				var facing := (Vector2(world.mining_cell) * TILE + Vector2.ONE * 24 - engineer).normalized() if mining else engineer_facing
				if world.combat.armed: facing = (world.combat.aim - world.player_position).normalized()
				EngineerArt.draw(self, engineer, facing, animation_time, not paused and world.previous_position != world.player_position, mining, Vector2(world.mining_cell) * TILE + Vector2.ONE * 24)
	DefenseView.draw_shots(self, world, reduced_motion or not ambient_enabled)
	DefenseView.draw_player(self, world, pointer_in_world, reduced_motion, engineer)
	if world.at(selected) != null and world.at(selected).kind == "fuel_depot":
		draw_arc((Vector2(selected) + Vector2.ONE * 0.5) * TILE, world.supply_radius() * TILE, 0, TAU, 96, Color(0.95, 0.65, 0.35, 0.4), 2)
	if Catalog.Combat.TURRETS.has(world.at(selected).kind if world.at(selected) != null else ""):
		var turret = world.at(selected)
		draw_arc((Vector2(selected) + Vector2.ONE * 0.5) * TILE, float(Catalog.Combat.TURRETS[turret.kind].range) * TILE, 0, TAU, 96, Color(0.5, 0.85, 0.75, 0.35), 2)
	effects.draw(self)
	if not resource_target.is_empty():
		var target := Vector2(resource_target.cell) * TILE + Vector2.ONE * 24
		var toward := target - engineer
		var position := engineer + toward.normalized() * minf(85, toward.length())
		draw_arc(target, 31, 0, TAU, 32, TEAL, 3)
		if toward.length() > 80:
			var direction := toward.normalized()
			draw_colored_polygon(PackedVector2Array([position + direction * 12, position - direction * 9 + direction.orthogonal() * 8, position - direction * 9 - direction.orthogonal() * 8]), TEAL)
		draw_string(ThemeDB.fallback_font, engineer + Vector2(-85, -44), "%s: %d tiles" % [Catalog.item_name(resource_target.item), ceili(toward.length() / TILE)], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, TEAL)
	var objective: Dictionary = world.guide.target(world)
	if objective.is_empty(): objective = world.settlements.objective_target()
	if selected_site != "" and world.settlements.enabled and world.settlements.sites.has(selected_site):
		objective = {"cell": world.settlements.sites[selected_site].port()}
	if not objective.is_empty():
		var target := Vector2(objective.cell) * TILE + Vector2.ONE * 24
		draw_arc(target, 28 + sin(animation_time * 2) * 2, 0, TAU, 32, Color("dfc68d"), 2)
		var toward := target - engineer
		if toward.length() > 80:
			var pointer := engineer + toward.normalized() * 55
			var forward := toward.normalized()
			var side := forward.orthogonal()
			draw_colored_polygon(PackedVector2Array([pointer + forward * 9, pointer - forward * 7 + side * 6, pointer - forward * 7 - side * 6]), Color("dfc68d"))
	if world.mining and world.mining_progress > 0:
		var target := Vector2(world.mining_cell) * TILE + Vector2.ONE * 24
		draw_arc(target, 20, -PI / 2, -PI / 2 + TAU * world.mining_progress / float(world.mining_duration() * 100), 24, TEAL, 3)
	if world.at(selected) != null:
		draw_rect(Rect2(Vector2(selected) * TILE - Vector2.ONE * 2, Vector2.ONE * 52), TEAL, false, 2)
	if pointer_in_world:
		var rect := Rect2(Vector2(hover) * TILE, Vector2.ONE * TILE)
		var valid: bool = world.in_reach(hover)
		if not ghost_kind.is_empty():
			valid = world.can_build(ghost_kind, hover).is_empty()
			if world.at(hover) == null:
				draw_rect(rect.grow(-4), Color(0.65, 0.83, 0.68, 0.08))
			draw_arc(engineer, world.interaction_reach() * TILE, 0, TAU, 96, Color(0.5, 0.8, 0.65, 0.12), 1)
		draw_rect(rect, TEAL if valid else Color("de806a"), false, 2)

func _machine(entity: RefCounted) -> void:
	var center := Vector2(entity.cell) * TILE + Vector2.ONE * 24
	var aim := Vector2(World.DIRS[entity.direction])
	var firing := false
	if Catalog.Combat.TURRETS.has(entity.kind):
		var closest := INF
		for enemy in world.defense.enemies.values():
			var distance := Vector2(enemy.cell - entity.cell).length_squared()
			if distance < closest:
				closest = distance
				aim = Vector2(enemy.cell - entity.cell).normalized()
		for shot in world.defense.shots:
			if Vector2(shot.from) == Vector2(entity.cell):
				aim = (Vector2(shot.to) - Vector2(entity.cell)).normalized()
				firing = true
	MachineArt.draw(self, entity, center, animation_time, aim, firing, interpolation)
	if entity.kind in Catalog.TRANSPORT and entity.inventory.total() > 0:
		var item_position := center
		var next = world.at(entity.cell + World.DIRS[entity.direction])
		if entity.health > 0 and next != null and next.health > 0 and next.kind in Catalog.TRANSPORT and next.inventory.total() == 0:
			var travel := interpolation if entity.kind == "fast_belt" else (posmod(world.ticks, 2) + interpolation) / 2.0
			item_position += Vector2(World.DIRS[entity.direction]) * (travel - 0.5) * TILE
		_item(item_position, entity.inventory.contents.keys()[0])
	if entity.kind == "inserter" and entity.carried != "":
		_item(center + Vector2(World.DIRS[entity.direction]) * MachineArt.hand_extension(entity, interpolation), entity.carried, 0.7)
	if entity.kind not in (Catalog.TRANSPORT + ["inserter", "chest", "wall"]):
		var working: bool = entity.status in ["Working", "Firing"] or entity.status.begins_with("Researching") or entity.status.begins_with("Mining")
		var indicator := Color("9dccab") if working else Color("ddae6f")
		draw_circle(center + Vector2(17, 13), 3.5, Art.INK)
		draw_circle(center + Vector2(17, 12), 2.2, indicator if entity.health > 0 else Color("bd7563"))
		if entity.progress > 0:
			var duration: int = int(Catalog.RECIPES[entity.recipe].ticks) if entity.recipe != "" else (30 if entity.kind == "lab" else 15)
			Art.box(self, Rect2(center + Vector2(-17, 20), Vector2(34, 3)), Art.INK, 1)
			Art.box(self, Rect2(center + Vector2(-17, 20), Vector2(34.0 * entity.progress / duration, 3)), Color("a5cdb1"), 1)
	if entity.output.total() > 0: _item(center + Vector2(12, 14), entity.output.contents.keys()[0], 0.65)
	if entity.health < entity.max_health() or entity.kind in (["wall"] + Catalog.Combat.TURRETS.keys()):
		Art.box(self, Rect2(center + Vector2(-19, -32), Vector2(38, 4)), Art.INK, 2)
		if entity.health > 0: Art.box(self, Rect2(center + Vector2(-19, -32), Vector2(38.0 * entity.health / entity.max_health(), 4)), Color("91bc97"), 2)
		else:
			draw_line(center - Vector2.ONE * 13, center + Vector2.ONE * 13, Color("dc9477"), 3, true)
			draw_line(center + Vector2(-13, 13), center + Vector2(13, -13), Color("dc9477"), 3, true)

func _build_grid() -> void:
	var engineer_cell := Vector2i(world.player_position.floor())
	var radius := ceili(world.interaction_reach()) + 1
	for x in range(engineer_cell.x - radius, engineer_cell.x + radius + 1):
		for y in range(engineer_cell.y - radius, engineer_cell.y + radius + 1):
			var cell := Vector2i(x, y)
			if not visible_cells.has_point(cell): continue
			var alpha := 0.12 if world.in_reach(cell) else 0.035
			draw_rect(Rect2(Vector2(cell) * TILE, Vector2.ONE * TILE), Color(0.83, 0.89, 0.73, alpha), false, 1)

func _on_mined(cell: Vector2i, item: String) -> void:
	if reduced_motion or not ambient_enabled: return
	effects.burst((Vector2(cell) + Vector2.ONE * 0.5) * TILE, Catalog.color(item).lightened(0.2), world.ticks + cell.x * 31 + cell.y * 17, 6)

func _on_repaired(cell: Vector2i) -> void:
	if reduced_motion or not ambient_enabled: return
	effects.burst((Vector2(cell) + Vector2.ONE * 0.5) * TILE, Art.AMBER, world.ticks + cell.x * 31 + cell.y * 17, 10)

func _arrow(center: Vector2, direction: int, color: Color, size: float = 9) -> void:
	var dir := Vector2(World.DIRS[direction])
	var side := dir.orthogonal()
	draw_line(center - dir * size / 2 + side * size, center + dir * size / 2, color, 2)
	draw_line(center + dir * size / 2, center - dir * size / 2 - side * size, color, 2)

func _item(center: Vector2, id: String, scale_factor: float = 1.0) -> void:
	var color := Catalog.color(id)
	if id.ends_with("plate") or id == "steel":
		draw_rect(Rect2(center - Vector2(8, 5) * scale_factor, Vector2(16, 10) * scale_factor), color)
		draw_line(center - Vector2(5, 3) * scale_factor, center + Vector2(5, -3) * scale_factor, color.lightened(0.3), 2)
	else:
		draw_circle(center + Vector2(1, 2), 7 * scale_factor, Color("202824"))
		draw_circle(center, 6 * scale_factor, color)

func _draw_tunnel_link() -> void:
	if not pointer_in_world: return
	var entry = world.at(hover)
	if entry == null or entry.kind != "underground_belt": return
	if entry.underground_exit:
		var found = null
		for distance in range(1, Transport.UNDERGROUND_SPAN + 1):
			var candidate = world.at(entry.cell - World.DIRS[entry.direction] * distance)
			if candidate != null and candidate.kind == "underground_belt" and candidate.direction == entry.direction:
				if not candidate.underground_exit and Transport.partner(world, candidate) == entry: found = candidate
				break
		entry = found
	if entry == null: return
	var exit = Transport.partner(world, entry)
	if exit == null: return
	var start := (Vector2(entry.cell) + Vector2.ONE * 0.5) * TILE
	var end := (Vector2(exit.cell) + Vector2.ONE * 0.5) * TILE
	draw_dashed_line(start, end, TEAL, 3, 8)
	draw_rect(Rect2(Vector2(exit.cell) * TILE, Vector2.ONE * TILE), TEAL, false, 2)

func _on_feedback(cue: String, cell: Vector2i) -> void:
	if reduced_motion or not ambient_enabled: return
	if cue in ["build", "pickup", "success", "damage"]:
		var color := Color("e67c63") if cue == "damage" else (Art.AMBER if cue == "success" else TEAL)
		effects.pulse((Vector2(cell) + Vector2.ONE * 0.5) * TILE, color)
		if cue == "build": effects.burst((Vector2(cell) + Vector2.ONE * 0.5) * TILE, Art.CREAM, cell.x * 31 + cell.y * 17, 5)

func _cast_shadow(entity: RefCounted) -> void:
	if entity.health <= 0: return
	var center := (Vector2(entity.cell) + Vector2.ONE * 0.5) * TILE
	var projection := Vector2(14, 11) if entity.kind != "wall" else Vector2(6, 5)
	var a := center + Vector2(-16, -10)
	var b := center + Vector2(16, -10)
	var c := center + Vector2(16, 15)
	var d := center + Vector2(-16, 15)
	draw_colored_polygon(PackedVector2Array([a, b, b + projection, c + projection, d + projection, d]), Color(0.06, 0.10, 0.09, 0.14))
