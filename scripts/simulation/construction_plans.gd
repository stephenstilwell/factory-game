extends RefCounted
## A clipboard stores configurations only. Ghosts never own resources or produce items.
const Catalog = preload("res://scripts/data/catalog.gd")
const MAX_GHOSTS := 512
const MAX_MODULE := 256
var clipboard: Array = []
var ghosts: Dictionary = {}

const MAX_HISTORY := 32
var undo_stack: Array = []
var redo_stack: Array = []

func _remember(before: Dictionary) -> void:
	var changes: Dictionary = {}
	for cell in before:
		if before[cell] != ghosts.get(cell): changes[cell] = {"before": before[cell], "after": ghosts.get(cell)}
	if changes.is_empty(): return
	undo_stack.append(changes.duplicate(true))
	if undo_stack.size() > MAX_HISTORY: undo_stack.pop_front()
	redo_stack.clear()

func remove(world: RefCounted, cell: Vector2i) -> void:
	if not ghosts.has(cell): return
	var before := {cell: ghosts[cell].duplicate(true)}
	ghosts.erase(cell)
	_remember(before)
	world.changed.emit()

func clear(world: RefCounted) -> void:
	var before := ghosts.duplicate(true)
	ghosts.clear()
	_remember(before)
	world.changed.emit()

func forget(cell: Vector2i) -> void:
	ghosts.erase(cell)
	for stack in [undo_stack, redo_stack]:
		for edit in stack: edit.erase(cell)
		for index in range(stack.size() - 1, -1, -1):
			if stack[index].is_empty(): stack.remove_at(index)

func undo(world: RefCounted) -> bool:
	return _history(world, undo_stack, redo_stack, "before", "after")

func redo(world: RefCounted) -> bool:
	return _history(world, redo_stack, undo_stack, "after", "before")

func _history(world: RefCounted, source: Array, destination: Array, target: String, expected: String) -> bool:
	if source.is_empty(): return false
	var edit: Dictionary = source.pop_back()
	var applied: Dictionary = {}
	for cell in edit:
		if world.at(cell) != null or world.settlements.at(cell) != null: continue
		if ghosts.get(cell) != edit[cell][expected]: continue
		var record = edit[cell][target]
		if record == null: ghosts.erase(cell)
		else: ghosts[cell] = record.duplicate(true)
		applied[cell] = edit[cell]
	if applied.is_empty(): return false
	destination.append(applied)
	world.changed.emit()
	return true


func capture(world: RefCounted, rect: Rect2i) -> String:
	if rect.size.x > 64 or rect.size.y > 64: return "Select an area no larger than 64 by 64 tiles."
	var copied: Array = []
	for entity in world.entities.values():
		if not rect.has_point(entity.cell): continue
		copied.append({"x": entity.cell.x - rect.position.x, "y": entity.cell.y - rect.position.y, "kind": entity.kind, "direction": entity.direction, "recipe": entity.recipe, "underground_exit": entity.underground_exit})
	if copied.is_empty(): return "There are no factory buildings in that selection."
	if copied.size() > MAX_MODULE: return "A module can contain up to 256 buildings."
	copied.sort_custom(func(a, b): return a.y < b.y or (a.y == b.y and a.x < b.x))
	clipboard = copied
	return ""

func rotate() -> void:
	for record in clipboard:
		var old_x: int = record.x
		record.x = -int(record.y)
		record.y = old_x
		record.direction = posmod(int(record.direction) + 1, 4)

func place(world: RefCounted, origin: Vector2i) -> String:
	return _place(world, clipboard, origin)

func place_single(world: RefCounted, kind: String, cell: Vector2i, direction: int, exit_mode: bool = false) -> String:
	if not Catalog.BUILDINGS.has(kind): return "Unknown planned building."
	var recipes: Array = Catalog.BUILDINGS[kind].get("recipes", [])
	var recipe: String = "" if recipes.is_empty() else recipes[0]
	var record := {"x": 0, "y": 0, "kind": kind, "direction": posmod(direction, 4), "recipe": recipe, "underground_exit": exit_mode and kind == "underground_belt"}
	return _place(world, [record], cell)

func _place(world: RefCounted, records: Array, origin: Vector2i) -> String:
	if records.is_empty(): return "Copy a factory area with Ctrl+C first."
	var pending: Dictionary = {}
	for record in records:
		var cell := origin + Vector2i(record.x, record.y)
		if abs(cell.x) > 1000000 or abs(cell.y) > 1000000: return "That plan is outside the buildable world."
		if not world.content_available(record.kind) or not world.unlocked(Catalog.BUILDINGS[record.kind]): return "This plan contains a building that is not unlocked."
		if world.settlements.at(cell) != null: return "The plan overlaps a civic landmark."
		var existing = world.at(cell)
		if existing != null:
			if existing.kind == record.kind and existing.direction == record.direction and existing.recipe == record.recipe and existing.underground_exit == record.underground_exit: continue
			return "The plan overlaps an existing building."
		if record.kind == "drill" and world.terrain.tile(cell).is_empty(): return "A planned drill needs a resource deposit."
		if not record.recipe.is_empty() and not world.unlocked(Catalog.RECIPES[record.recipe]): return "This plan contains an unresearched recipe."
		var ghost: Dictionary = record.duplicate()
		ghost.x = cell.x
		ghost.y = cell.y
		pending[cell] = ghost
	var count := ghosts.size()
	for cell in pending:
		if not ghosts.has(cell): count += 1
	if count > MAX_GHOSTS: return "Build or clear existing plans before adding more than 512 ghosts."
	var before: Dictionary = {}
	for cell in pending: before[cell] = ghosts.get(cell)
	for cell in pending: ghosts[cell] = pending[cell]
	_remember(before)
	world.changed.emit()
	return ""

func build_nearby(world: RefCounted) -> int:
	var built := 0
	for cell in ghosts.keys():
		var record: Dictionary = ghosts[cell]
		if not world.can_build(record.kind, cell).is_empty(): continue
		if not world.build(record.kind, cell, int(record.direction), bool(record.underground_exit)): continue
		var entity = world.at(cell)
		if not record.recipe.is_empty(): entity.recipe = record.recipe
		built += 1
	return built

func serialize() -> Array:
	var records: Array = []
	for cell in ghosts: records.append(ghosts[cell].duplicate())
	records.sort_custom(func(a, b): return a.y < b.y or (a.y == b.y and a.x < b.x))
	return records

func restore(data: Variant, world: RefCounted) -> bool:
	if not data is Array or data.size() > MAX_GHOSTS: return false
	var restored: Dictionary = {}
	for record in data:
		if not record is Dictionary or not Catalog.BUILDINGS.has(record.get("kind")): return false
		for key in ["x", "y", "direction"]:
			var number = record.get(key)
			if not (number is int or number is float) or not is_finite(float(number)) or number != floor(float(number)): return false
		if abs(record.x) > 1000000 or abs(record.y) > 1000000 or record.direction < 0 or record.direction > 3: return false
		if not record.get("underground_exit") is bool or not record.get("recipe") is String: return false
		var recipes: Array = Catalog.BUILDINGS[record.kind].get("recipes", [])
		if record.recipe != "" and (record.recipe not in recipes or not world.unlocked(Catalog.RECIPES[record.recipe])): return false
		if not recipes.is_empty() and record.recipe.is_empty(): return false
		if record.underground_exit and record.kind != "underground_belt": return false
		if not world.unlocked(Catalog.BUILDINGS[record.kind]) or not world.content_available(record.kind): return false
		var cell := Vector2i(int(record.x), int(record.y))
		if restored.has(cell) or world.at(cell) != null or world.settlements.at(cell) != null: return false
		if record.kind == "drill" and world.terrain.tile(cell).is_empty(): return false
		restored[cell] = {"x": cell.x, "y": cell.y, "kind": record.kind, "direction": int(record.direction), "recipe": record.recipe, "underground_exit": record.underground_exit}
	ghosts = restored
	undo_stack.clear()
	redo_stack.clear()
	return true

func supply_report(world: RefCounted, nearby_only: bool = true) -> Dictionary:
	var rows: Dictionary = {}
	var ready := 0
	var distant := 0
	var blocked := 0
	var allocated: Dictionary = {}
	for cell in ghosts:
		var record: Dictionary = ghosts[cell]
		var nearby: bool = world.in_reach(cell)
		if not nearby: distant += 1
		if nearby_only and not nearby: continue
		var kind: String = record.kind
		if not rows.has(kind): rows[kind] = {"needed": 0, "pack": world.player.count(kind), "queued": 0, "missing": 0, "recipe": "", "craft_batches": 0}
		rows[kind].needed += 1
		if nearby:
			var reason: String = world.can_build(kind, cell, false)
			if reason.is_empty() and int(allocated.get(kind, 0)) < world.player.count(kind):
				ready += 1
				allocated[kind] = int(allocated.get(kind, 0)) + 1
			elif not reason.is_empty(): blocked += 1
	for job in world.craft_queue:
		for item in Catalog.RECIPES[job.recipe]["out"]:
			if rows.has(item): rows[item].queued += int(Catalog.RECIPES[job.recipe]["out"][item])
	for kind in rows:
		var row: Dictionary = rows[kind]
		row.missing = maxi(0, int(row.needed) - int(row.pack) - int(row.queued))
		for id in Catalog.RECIPES:
			var recipe: Dictionary = Catalog.RECIPES[id]
			if not recipe["out"].has(kind) or not world.Crafting.available(world, id): continue
			row.recipe = id
			row.craft_batches = mini(ceili(float(row.missing) / int(recipe["out"][kind])), world.craft_maximum(id))
			break
	return {"rows": rows, "ready": ready, "distant": distant, "blocked": blocked}

func craft_missing(world: RefCounted, kind: String, nearby_only: bool = true) -> bool:
	var report := supply_report(world, nearby_only)
	if not report.rows.has(kind): return false
	var row: Dictionary = report.rows[kind]
	if row.craft_batches <= 0: return false
	return world.craft_many(row.recipe, int(row.craft_batches))
