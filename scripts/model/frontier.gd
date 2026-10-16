extends RefCounted
## Interactive frontier state. Scenery is derived; discoveries and removals persist.
const Definitions = preload("res://scripts/data/frontier_catalog.gd")
const VERSION := 1
var enabled := false
var sites: Dictionary = {}
var cleared: Dictionary = {}
var board: Dictionary = {}
var target := ""

static func hash_cell(cell: Vector2i, seed_value: int, salt: int = 0) -> int:
	var value := posmod(cell.x * 73856093 + cell.y * 19349663 + seed_value + salt * 83492791, 2147483647)
	value = posmod((value ^ (value >> 13)) * 1274126177, 2147483647)
	return value ^ (value >> 16)

static func biome(cell: Vector2i, seed_value: int) -> int:
	return hash_cell(Vector2i(floori(cell.x / 32.0), floori(cell.y / 32.0)), seed_value, 71) % 3

static func tree_candidate(cell: Vector2i, seed_value: int) -> bool:
	if cell.distance_squared_to(Vector2i(24, 12)) < 25: return false
	var grove := Vector2i(floori(cell.x / 8.0), floori(cell.y / 8.0))
	var density: int = [5, 18, 11][biome(cell, seed_value)]
	return hash_cell(grove, seed_value, 21) % 4 != 0 and hash_cell(cell, seed_value, 11) % 100 < density

func footprint(id: String) -> Rect2i:
	return Rect2i(sites[id].origin, Definitions.SITES[id].size)

func port(id: String) -> Vector2i:
	return sites[id].origin + Vector2i(-1, 2)

func at(cell: Vector2i) -> String:
	if not enabled: return ""
	for id in sites:
		if footprint(id).has_point(cell) or port(id) == cell: return id
	return ""

func blocks(cell: Vector2i) -> bool:
	var id := at(cell)
	return not id.is_empty() and port(id) != cell

func tree_at(world: RefCounted, cell: Vector2i) -> bool:
	if not enabled or cleared.has(cell) or not tree_candidate(cell, world.terrain.seed_value): return false
	world.terrain.tile(cell) # Ensure the original deposit mask is cached, including exhausted ore.
	if world.at(cell) != null or world.settlements.at(cell) != null or world.terrain.chunks[world.terrain.chunk_at(cell)].has(cell): return false
	for id in sites:
		if footprint(id).grow(2).has_point(cell): return false
	if world.settlements.enabled:
		for site in world.settlements.sites.values():
			if site.footprint().grow(2).has_point(cell): return false
	return true

func clear_tree(world: RefCounted, cell: Vector2i, announce: bool = true) -> bool:
	if not tree_at(world, cell) or cleared.size() >= 100000: return false
	cleared[cell] = true
	if announce:
		world.message.emit("Grove tree cleared. Ground ready for building.")
		world.feedback_requested.emit("pickup", cell)
		world.changed.emit()
	return true

func install(world: RefCounted) -> void:
	enabled = true
	sites.clear()
	for entity in world.entities.values():
		if tree_candidate(entity.cell, world.terrain.seed_value): cleared[entity.cell] = true
	for id in Definitions.SITES:
		var definition: Dictionary = Definitions.SITES[id]
		var shift: Vector2i = world.settlements.sites.trading_post.origin - world.settlements.Definitions.SITES.trading_post.origin if world.settlements.enabled else Vector2i.ZERO
		var jitter := Vector2i(hash_cell(definition.anchor, world.terrain.seed_value, 41) % 9 - 4, hash_cell(definition.anchor, world.terrain.seed_value, 43) % 9 - 4)
		for attempt in range(256):
			var ring := (attempt + 7) / 8
			var axis: Vector2i = [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP, Vector2i(1, 1), Vector2i(-1, 1), Vector2i(-1, -1), Vector2i(1, -1)][posmod(attempt - 1, 8)]
			var origin: Vector2i = definition.anchor + shift + jitter + (axis * ring * 8 if attempt > 0 else Vector2i.ZERO)
			var rect := Rect2i(origin, definition.size).grow(2)
			var vacant := true
			if world.settlements.enabled:
				var approach := Rect2i(world.settlements.sites.town_hall.origin + Vector2i(-5, -7), Vector2i(32, 17))
				if approach.intersects(rect): continue
			for y in range(rect.position.y, rect.end.y):
				for x in range(rect.position.x, rect.end.x):
					var cell := Vector2i(x, y)
					if world.at(cell) != null or world.settlements.at(cell) != null or not world.terrain.tile(cell).is_empty() or at(cell) != "" or cell.distance_squared_to(Vector2i(world.player_position.floor())) < 16:
						vacant = false
						break
				if not vacant: break
			if vacant:
				sites[id] = {"origin": origin, "discovered": false, "claimed": false}
				break

func _discover(world: RefCounted, id: String) -> void:
	if sites[id].discovered: return
	sites[id].discovered = true
	world.award_skill("exploration", 75)
	world.message.emit("Discovered %s! +75 Exploration XP. Click the landmark or open Discoveries [L / J]." % Definitions.SITES[id].name)
	world.feedback_requested.emit("success", port(id))
	world.changed.emit()

func observe(world: RefCounted) -> void:
	if not enabled: return
	for id in sites:
		if sites[id].discovered or world.player_position.distance_to(Vector2(port(id)) + Vector2.ONE * 0.5) > 9: continue
		_discover(world, id)

func interaction_reason(world: RefCounted, id: String) -> String:
	if not enabled or not sites.has(id): return "This landmark is unavailable."
	if not world.in_reach(port(id)): return "Walk within reach of the marked entrance."
	if world.defense.phase in ["warning", "active"]: return "Finish the beacon defense before investigating."
	return ""

func claim(world: RefCounted, id: String) -> bool:
	var reason := interaction_reason(world, id)
	if reason.is_empty() and sites[id].claimed: reason = "This discovery's reward has already been recovered."
	if reason.is_empty() and id == "depot" and not evaluate().success: reason = "Complete both cargo routes before restoring the depot."
	if not reason.is_empty():
		world.message.emit(reason)
		return false
	var definition: Dictionary = Definitions.SITES[id]
	if not world.player.exchange({}, definition.goods):
		world.message.emit("Make pack space for the complete salvage bundle. Nothing has been claimed.")
		return false
	_discover(world, id)
	sites[id].claimed = true
	world.award_skill("exploration", definition.xp)
	world.message.emit("%s recovered! %s" % [definition.name, definition.reward])
	world.feedback_requested.emit("success", port(id))
	world.changed.emit()
	return true

func claimed(id: String) -> bool:
	return enabled and sites.has(id) and sites[id].claimed

func hearth_bonus(world: RefCounted) -> int:
	return 1 if claimed("depot") and world.settlements.enabled and world.settlements.services_online() and world.settlements.sites.trading_post.repaired and world.settlements.sites.trading_post.health > 0 else 0

func edit_belt(world: RefCounted, cell: Vector2i, remove: bool = false) -> bool:
	if not interaction_reason(world, "depot").is_empty() or claimed("depot") or not editable(cell): return false
	_discover(world, "depot")
	if remove:
		board.erase(cell)
	elif board.has(cell): board[cell] = posmod(int(board[cell]) + 1, 4)
	elif board.size() < Definitions.MAX_BELTS: board[cell] = 0
	else: return false
	world.changed.emit()
	return true

func reset_table(world: RefCounted) -> bool:
	if not interaction_reason(world, "depot").is_empty() or claimed("depot"): return false
	board.clear()
	world.changed.emit()
	return true

static func editable(cell: Vector2i) -> bool:
	return cell.x > 0 and cell.x < 6 and cell.y >= 0 and cell.y < 5 and cell not in Definitions.BLOCKED

func evaluate() -> Dictionary:
	var routes: Array = []
	for row in [1, 3]:
		var cell := Vector2i(1, row)
		var route: Array = [Vector2i(0, row)]
		var seen: Dictionary = {}
		var success := false
		for step in range(36):
			route.append(cell)
			if cell == Vector2i(6, row):
				success = true
				break
			if not board.has(cell) or seen.has(cell): break
			seen[cell] = true
			cell += Definitions.DIRS[int(board[cell])]
		if not success: return {"success": false, "routes": routes + [route], "message": "%s route incomplete. Follow the arrows to its matching dock." % ("A" if row == 1 else "B")}
		routes.append(route)
	return {"success": true, "routes": routes, "message": "Both cargo routes reach the correct docks. Restore the depot to welcome local runners."}

func serialize() -> Dictionary:
	var records := {}
	for id in sites: records[id] = {"x": sites[id].origin.x, "y": sites[id].origin.y, "discovered": sites[id].discovered, "claimed": sites[id].claimed}
	var trees: Array = []
	for cell in cleared: trees.append([cell.x, cell.y])
	var belts: Array = []
	for cell in board: belts.append([cell.x, cell.y, board[cell]])
	return {"version": VERSION, "enabled": enabled, "sites": records, "cleared": trees, "board": belts, "target": target}

static func integer(value, lower: int = -1000000, upper: int = 1000000) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value == floor(float(value)) and value >= lower and value <= upper

func restore(world: RefCounted, data) -> bool:
	if not data is Dictionary or data.get("version") != VERSION or not data.get("enabled") is bool or not data.get("sites") is Dictionary: return false
	if data.sites.size() > Definitions.SITES.size() or not data.get("cleared") is Array or data.cleared.size() > 100000 or not data.get("board") is Array or data.board.size() > Definitions.MAX_BELTS: return false
	enabled = data.enabled
	for id in data.sites:
		var record = data.sites[id]
		if not Definitions.SITES.has(id) or not record is Dictionary or not integer(record.get("x")) or not integer(record.get("y")) or not record.get("discovered") is bool or not record.get("claimed") is bool or (record.claimed and not record.discovered): return false
		sites[id] = {"origin": Vector2i(int(record.x), int(record.y)), "discovered": record.discovered, "claimed": record.claimed}
	for id in sites:
		var rect := footprint(id)
		if rect.has_point(Vector2i(world.player_position.floor())) or world.at(port(id)) != null or world.settlements.at(port(id)) != null: return false
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				var cell := Vector2i(x, y)
				if world.at(cell) != null or world.settlements.at(cell) != null or not world.terrain.tile(cell).is_empty(): return false
		for other in sites:
			if other != id and footprint(other).grow(1).intersects(rect): return false
	for entry in data.cleared:
		if not entry is Array or entry.size() != 2 or not integer(entry[0]) or not integer(entry[1]): return false
		var cell := Vector2i(int(entry[0]), int(entry[1]))
		if cleared.has(cell) or not tree_candidate(cell, world.terrain.seed_value): return false
		cleared[cell] = true
	for entry in data.board:
		if not entry is Array or entry.size() != 3 or not integer(entry[0]) or not integer(entry[1]) or not integer(entry[2], 0, 3): return false
		var cell := Vector2i(int(entry[0]), int(entry[1]))
		if not editable(cell) or board.has(cell): return false
		board[cell] = int(entry[2])
	if not data.get("target") is String or (data.target != "" and not sites.has(data.target)): return false
	target = data.target
	if not enabled and (not sites.is_empty() or not cleared.is_empty() or not board.is_empty() or target != ""): return false
	if not board.is_empty() and (not sites.has("depot") or not sites.depot.discovered): return false
	if claimed("depot") and not evaluate().success: return false
	return true
