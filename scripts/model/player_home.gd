extends RefCounted
## Optional instanced-room state. Furniture owns no factory resources or production.
const Definitions = preload("res://scripts/data/home_catalog.gd")
const Catalog = preload("res://scripts/data/catalog.gd")
const LIMIT := 256
const HISTORY_LIMIT := 32
var stock: Dictionary = {}
var pieces: Array = []
var floor_style := 0
var wall_style := 0
var active_entry := 0
var undo_stack: Array = []
var redo_stack: Array = []
func unlocked(world: RefCounted) -> bool:
	return world.early.phase >= 1
func kit_reason(world: RefCounted) -> String:
	if not unlocked(world): return "Welcome the first neighbors at the shelter (Town [Y]) to unlock your cottage."
	if not world.by_kind.cottage.is_empty(): return "Inspect your cottage entrance to enter. Pick it up to move it; your interior stays saved."
	if world.player.count("cottage") > 0: return "Your cottage kit is in your pack. Assign it to the hotbar and place it."
	if not world.player.can_exchange(Definitions.KIT_COST, {"cottage": 1}): return "Bring 12 timber, 12 planks and 8 stone; make room for the cottage kit."
	return ""
func make_kit(world: RefCounted) -> bool:
	var reason := kit_reason(world)
	if not reason.is_empty(): world.message.emit(reason); return false
	if not world.player.exchange(Definitions.KIT_COST, {"cottage": 1}): return false
	world.metrics.consume(world.ticks, Definitions.KIT_COST)
	world.message.emit("Cottage kit ready! Assign it to your hotbar, place it, then inspect its entrance. Furnish your own home; decoration is optional.")
	world.changed.emit()
	return true
func entry_reason(world: RefCounted, id: int) -> String:
	var entity = world.entities.get(id)
	if entity == null or entity.kind != "cottage": return "Place your cottage kit first."
	if entity.health <= 0: return "Repair your cottage entrance first."
	if not world.in_reach(entity.cell): return "Walk closer to the cottage door."
	return ""
func enter(world: RefCounted, id: int) -> bool:
	if not entry_reason(world, id).is_empty(): return false
	active_entry = id
	return true
func inside(world: RefCounted) -> bool:
	return active_entry > 0 and entry_reason(world, active_entry).is_empty()
func leave() -> void:
	active_entry = 0
func total() -> int:
	var count := pieces.size()
	for value in stock.values(): count += int(value)
	return count
func make_reason(world: RefCounted, kind: String) -> String:
	if not Definitions.PIECES.has(kind): return "Unknown furnishing."
	if not inside(world): return "Enter your cottage to make furnishings."
	if not unlocked(world): return "Restore the first shelter to furnish a home."
	if total() >= LIMIT: return "Your home collection is full (256 furnishings)."
	var definition: Dictionary = Definitions.PIECES[kind]
	if definition.get("market", false) and (not world.settlements.sites.trading_post.repaired or world.settlements.sites.trading_post.health <= 0 or not world.settlements.services_online()): return "Reopen healthy market services to barter for rugs."
	if not world.player.has_all(definition.cost): return "Missing materials: " + Catalog.describe(definition.cost)
	return ""
func make(world: RefCounted, kind: String) -> bool:
	var reason := make_reason(world, kind)
	if not reason.is_empty(): world.message.emit(reason); return false
	if not world.player.exchange(Definitions.PIECES[kind].cost, {}): return false
	stock[kind] = int(stock.get(kind, 0)) + 1
	# History only rearranges owned furniture. It must never reverse an outside payment.
	undo_stack.clear()
	redo_stack.clear()
	world.metrics.consume(world.ticks, Definitions.PIECES[kind].cost)
	world.changed.emit()
	return true
func placement_reason(kind: String, cell: Vector2i, direction: int, require_stock: bool = true) -> String:
	if not Definitions.PIECES.has(kind): return "Choose a furnishing."
	if require_stock and int(stock.get(kind, 0)) == 0: return "Make or pick up this furnishing first."
	var footprint := Definitions.footprint(kind, direction)
	var rect := Rect2i(cell, footprint)
	if not Rect2i(Vector2i.ZERO, Definitions.SIZE).encloses(rect): return "Keep furniture inside the room."
	if rect.intersects(Rect2i(4, 7, 2, 1)): return "Keep the doorway clear."
	var layer: int = int(Definitions.PIECES[kind].get("layer", 1))
	for record in pieces:
		if layer != int(Definitions.PIECES[record.kind].get("layer", 1)): continue
		if rect.intersects(Rect2i(Vector2i(record.x, record.y), Definitions.footprint(record.kind, int(record.direction)))): return "That space is occupied."
	return ""
func place(world: RefCounted, kind: String, cell: Vector2i, direction: int) -> bool:
	if not inside(world) or not placement_reason(kind, cell, direction).is_empty(): return false
	_remember()
	stock[kind] -= 1
	if stock[kind] == 0: stock.erase(kind)
	pieces.append({"kind": kind, "x": cell.x, "y": cell.y, "direction": posmod(direction, 4)})
	world.changed.emit()
	return true
func at(cell: Vector2i) -> int:
	var chosen := -1
	for index in range(pieces.size()):
		var record: Dictionary = pieces[index]
		if not Rect2i(Vector2i(record.x, record.y), Definitions.footprint(record.kind, int(record.direction))).has_point(cell): continue
		if chosen < 0 or int(Definitions.PIECES[record.kind].get("layer", 1)) >= int(Definitions.PIECES[pieces[chosen].kind].get("layer", 1)): chosen = index
	return chosen
func pickup(world: RefCounted, cell: Vector2i) -> String:
	if not inside(world): return ""
	var index := at(cell)
	if index < 0: return ""
	_remember()
	var kind: String = pieces[index].kind
	pieces.remove_at(index)
	stock[kind] = int(stock.get(kind, 0)) + 1
	world.changed.emit()
	return kind
func style_available(world: RefCounted, index: int) -> bool:
	if index < 0 or index >= Definitions.STYLES.size(): return false
	var site: String = Definitions.STYLES[index].requires
	return site.is_empty() or world.frontier.claimed(site)
func finish(world: RefCounted, floor_index: int, wall_index: int) -> bool:
	if not inside(world): return false
	if not style_available(world, floor_index) or not style_available(world, wall_index): return false
	if floor_style == floor_index and wall_style == wall_index: return false
	_remember()
	floor_style = floor_index
	wall_style = wall_index
	world.changed.emit()
	return true
func _remember() -> void:
	undo_stack.append(serialize().duplicate(true))
	if undo_stack.size() > HISTORY_LIMIT: undo_stack.pop_front()
	redo_stack.clear()
func undo(world: RefCounted, redo: bool = false) -> bool:
	if not inside(world): return false
	var source: Array = redo_stack if redo else undo_stack
	var target: Array = undo_stack if redo else redo_stack
	if source.is_empty(): return false
	target.append(serialize().duplicate(true))
	_apply(source.pop_back())
	world.changed.emit()
	return true
func serialize() -> Dictionary:
	return {"stock": stock.duplicate(), "pieces": pieces.duplicate(true), "floor": floor_style, "wall": wall_style}
func _apply(data: Dictionary) -> void:
	stock = data.stock.duplicate()
	pieces = data.pieces.duplicate(true)
	floor_style = int(data.floor)
	wall_style = int(data.wall)
func restore(world: RefCounted, data: Variant) -> bool:
	if not data is Dictionary or not data.get("stock") is Dictionary or not data.get("pieces") is Array: return false
	for index in [data.get("floor", 0), data.get("wall", 0)]:
		if not world.frontier.integer(index, 0, Definitions.STYLES.size() - 1) or not style_available(world, int(index)): return false
	var owned: Dictionary = {}
	for kind in data.stock:
		if not Definitions.PIECES.has(kind) or not world.frontier.integer(data.stock[kind], 1, LIMIT): return false
		owned[kind] = int(data.stock[kind])
	if data.get("pieces").size() > Definitions.SIZE.x * Definitions.SIZE.y * 2: return false
	stock = owned
	pieces.clear()
	for record in data.pieces:
		if not record is Dictionary or not Definitions.PIECES.has(record.get("kind")): return false
		for key in ["x", "y", "direction"]:
			if not world.frontier.integer(record.get(key), 0, 10 if key != "direction" else 3): return false
		if not placement_reason(record.kind, Vector2i(record.x, record.y), int(record.direction), false).is_empty(): return false
		pieces.append({"kind": record.kind, "x": int(record.x), "y": int(record.y), "direction": int(record.direction)})
	floor_style = int(data.get("floor", 0))
	wall_style = int(data.get("wall", 0))
	if total() > LIMIT or ((total() > 0 or floor_style > 0 or wall_style > 0) and not unlocked(world)): return false
	if (stock.has("rug") or pieces.any(func(piece): return piece.kind == "rug")) and not world.settlements.sites.trading_post.repaired: return false
	undo_stack.clear()
	redo_stack.clear()
	active_entry = 0
	return true
