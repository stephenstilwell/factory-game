extends Control
## Charted terrain is reconstructed in a bounded, disposable cache; simulation stays untouched.
const Catalog = preload("res://scripts/data/catalog.gd")
const SettlementCatalog = preload("res://scripts/data/settlement_catalog.gd")
const FrontierCatalog = preload("res://scripts/data/frontier_catalog.gd")
const ORE := {"iron_ore": Color("9db9cc"), "copper_ore": Color("dc9663"), "coal": Color("303d47"), "stone": Color("d4c6a4")}
signal pins_changed
signal notice(text: String)
var pin_title := ""
var world: RefCounted
var center := Vector2.ZERO
var zoom := 5.0
var dragging := false
var label_bounds: Array[Rect2] = []
var terrain_cache := preload("res://scripts/ui/map_terrain_cache.gd").new()

func _process(_delta: float) -> void:
	if world != null and is_visible_in_tree() and terrain_cache.step(world): queue_redraw()

func _get_tooltip(at_position: Vector2) -> String:
	if world == null: return ""
	var tile := Vector2i((center + (at_position - size * 0.5) / zoom).floor())
	if not world.exploration.known(Vector2(tile)): return "Unexplored land"
	if zoom < 2: return "Zoom in for deposit details"
	var chunk: Dictionary = terrain_cache.request(world, world.terrain.chunk_at(tile))
	var deposit: Dictionary = chunk.get(tile, {})
	if deposit.is_empty(): return "Explored land (%d, %d)" % [tile.x, tile.y]
	var remaining: int = int(world.terrain.depleted.get(tile, deposit.amount))
	return "%s / %d remaining / (%d, %d)" % [Catalog.item_name(deposit.item), remaining, tile.x, tile.y]

func _ready() -> void:
	custom_minimum_size = Vector2(760, 330)
	mouse_default_cursor_shape = Control.CURSOR_DRAG
	clip_contents = true
	resized.connect(queue_redraw)

func open(state: RefCounted) -> void:
	world = state
	world.exploration.reveal(world.player_position)
	center = world.player_position
	queue_redraw()

func point(position: Vector2) -> Vector2:
	return size * 0.5 + (position - center) * zoom

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			add_pin_at(event.position)
		if event.button_index == MOUSE_BUTTON_LEFT: dragging = event.pressed
		if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			var before: Vector2 = center + (event.position - size * 0.5) / zoom
			zoom = clampf(zoom * (1.2 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.2), 1.0, 12.0)
			center = before - (event.position - size * 0.5) / zoom
			queue_redraw()
		accept_event()
	if event is InputEventMouseMotion and dragging:
		center -= event.relative / zoom
		queue_redraw()
		accept_event()

func add_pin_at(pixel: Vector2) -> void:
	var cell := Vector2i((center + (pixel - size * 0.5) / zoom).floor())
	if not world.exploration.known(Vector2(cell)):
		notice.emit("Explore this land before adding a pin.")
		return
	if world.navigation.add(cell, pin_title) == 0:
		notice.emit("Map pin limit reached (32). Remove an old pin first.")
		return
	world.changed.emit()
	pins_changed.emit()
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("101f27"))
	if world == null: return
	label_bounds.clear()
	var screen := Rect2(Vector2.ZERO, size)
	for cell in world.exploration.cells:
		var origin := Vector2(cell * 8)
		var rect := Rect2(point(origin), Vector2.ONE * 8 * zoom)
		if not screen.intersects(rect): continue
		var region: int = world.frontier.landscape_index(Vector2i(origin))
		var shade: Color = [Color("455c4a"), Color("69704b"), Color("69716e")][region]
		draw_rect(rect, shade)
		if world.early.enabled:
			for x in range(8):
				for y in range(8):
					var tile := Vector2i(origin) + Vector2i(x, y)
					if world.early.water_at(tile): draw_rect(Rect2(point(Vector2(tile)), Vector2.ONE * zoom), Color("467e91"))
	var first: Vector2i = world.terrain.chunk_at(Vector2i((center - size * 0.5 / zoom).floor()))
	var last: Vector2i = world.terrain.chunk_at(Vector2i((center + size * 0.5 / zoom).ceil()))
	var visible_chunks: Array = []
	for x in range(first.x, last.x + 1):
		for y in range(first.y, last.y + 1):
			var key := Vector2i(x, y)
			if zoom >= 2:
				var chunk: Dictionary = terrain_cache.request(world, key)
				if not chunk.is_empty(): visible_chunks.append(chunk)
	for chunk in visible_chunks:
		for tile in chunk:
			if not world.exploration.known(Vector2(tile)) or not screen.has_point(point(Vector2(tile))): continue
			var deposit: Dictionary = chunk[tile]
			if int(world.terrain.depleted.get(tile, deposit.amount)) <= 0: continue
			draw_rect(Rect2(point(Vector2(tile)), Vector2.ONE * maxf(1, zoom)), ORE[deposit.item])
	var road: PackedVector2Array = world.quarry_project.road(world)
	if road.size() == 2: draw_line(point(road[0]), point(road[1]), Color("c9b589"), maxf(2, zoom * 0.6))
	for entity in world.entities.values():
		if world.exploration.known(Vector2(entity.cell)):
			draw_rect(Rect2(point(Vector2(entity.cell)), Vector2.ONE * maxf(2, zoom)), Color("c2a977"))
	for site in world.settlements.sites.values():
		if world.exploration.known(Vector2(site.origin)):
			marker(Vector2(site.origin), str(SettlementCatalog.SITES[site.id].name), Color("e7c47e"))
	for id in world.frontier.sites:
		var site: Dictionary = world.frontier.sites[id]
		if site.discovered: marker(Vector2(site.origin), str(FrontierCatalog.SITES[id].name), Color("b9d6aa"))
	for id in world.navigation.pins:
		var pin: Dictionary = world.navigation.pins[id]
		marker(Vector2(pin.cell) + Vector2.ONE * 0.5, ("[TRACKED] " if id == world.navigation.active else "") + pin.title, Color("d2b6ec"))
	var player := point(world.player_position)
	draw_circle(player, 7, Color("11212a"))
	draw_circle(player, 4, Color("f5f1cf"))
	draw_line(player, player + world.move_direction * 14, Color.WHITE, 2)

func marker(position: Vector2, title: String, tint: Color) -> void:
	var pixel := point(position)
	if not Rect2(Vector2.ZERO, size).grow(80).has_point(pixel): return
	draw_circle(pixel, 5, Color("15242b"))
	draw_circle(pixel, 3, tint)
	var label_position := pixel + Vector2(8, -5)
	var width := ThemeDB.fallback_font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
	label_position.x = clampf(label_position.x, 4, maxf(4, size.x - width - 4))
	var bounds := Rect2(label_position - Vector2(0, 13), Vector2(width + 4, 18))
	for attempt in range(16):
		var overlaps := false
		for previous in label_bounds:
			if bounds.intersects(previous): overlaps = true
		if not overlaps: break
		label_position.y += 19
		bounds.position.y += 19
	label_bounds.append(bounds)
	draw_rect(bounds, Color(0.05, 0.09, 0.11, 0.85))
	draw_string(ThemeDB.fallback_font, label_position, title, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, tint)
