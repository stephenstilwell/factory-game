extends RefCounted
## Sparse, saved work plots. Scenery reads never advance simulation.
const CUTS := 6
const GROW_TICKS := 1200
const LIMIT := 100000
var plots: Dictionary = {}
var awaiting_planting := false

func growing(world: RefCounted, cell: Vector2i) -> bool:
	return plots.has(cell) and (int(plots[cell].ready) < 0 or int(plots[cell].ready) > world.ticks)

func growth(world: RefCounted, cell: Vector2i) -> float:
	if not plots.has(cell) or int(plots[cell].ready) < 0: return 0.0
	return clampf(1.0 - (int(plots[cell].ready) - world.ticks) / float(GROW_TICKS), 0.0, 1.0)

func step(world: RefCounted) -> void:
	# Only needed when the shelter first enables planting. No per-tree growth ticks.
	if world.early.phase < 1 or not awaiting_planting: return
	awaiting_planting = false
	for cell in plots:
		if int(plots[cell].ready) < 0: plots[cell].ready = world.ticks + GROW_TICKS

func harvest(world: RefCounted, cell: Vector2i) -> bool:
	if not world.frontier.tree_at(world, cell): return false
	if not plots.has(cell):
		if plots.size() >= LIMIT: return false
		plots[cell] = {"cuts": 0, "ready": 0}
	var plot: Dictionary = plots[cell]
	if int(plot.ready) > 0: plot.cuts = 0; plot.ready = 0
	plot.cuts = int(plot.cuts) + 1
	if int(plot.cuts) >= CUTS:
		plot.cuts = 0
		plot.ready = world.ticks + GROW_TICKS if world.early.phase >= 1 else -1
		if int(plot.ready) < 0: awaiting_planting = true
	return true

func harvest_from(world: RefCounted, cells: Array[Vector2i]) -> bool:
	# Finish a worked tree before switching to one that has just matured.
	# Fixed spatial priority alone repeatedly interrupts work and lowers yield.
	var chosen := Vector2i.ZERO
	var best := -1
	for cell in cells:
		if not world.frontier.tree_at(world, cell): continue
		var cuts: int = int(plots[cell].cuts) if plots.has(cell) and int(plots[cell].ready) == 0 else 0
		if cuts > best:
			chosen = cell
			best = cuts
	return harvest(world, chosen) if best >= 0 else false

func harvest_nearby(world: RefCounted, center: Vector2i) -> bool:
	var cells: Array[Vector2i] = []
	for y in range(-4, 5):
		for x in range(-4, 5): cells.append(center + Vector2i(x, y))
	return harvest_from(world, cells)

func coverage(world: RefCounted, center: Vector2i) -> Dictionary:
	var mature := 0
	var recovering := 0
	var waiting := 0
	var harvests := 0
	var soonest := GROW_TICKS
	for y in range(-4, 5):
		for x in range(-4, 5):
			var cell := center + Vector2i(x, y)
			if growing(world, cell):
				if int(plots[cell].ready) < 0: waiting += 1
				else:
					recovering += 1
					soonest = mini(soonest, int(plots[cell].ready) - world.ticks)
			elif world.frontier.tree_at(world, cell):
				mature += 1
				harvests += CUTS - (int(plots[cell].cuts) if plots.has(cell) and int(plots[cell].ready) == 0 else 0)
	return {"mature": mature, "growing": recovering, "waiting": waiting, "harvests": harvests, "next": ceili(soonest / 10.0)}

func describe(world: RefCounted, center: Vector2i) -> String:
	var grove := coverage(world, center)
	var text := "GROVE: %d mature / %d growing / %d awaiting replanting\n%d harvests (about %ds work) in the 9 × 9 area." % [grove.mature, grove.growing, grove.waiting, grove.harvests, grove.harvests * 4]
	text += "\nAutomatic replanting unlocked. Six trees can sustain one camp; overlapping camps share this supply." if world.early.phase >= 1 else "\nSupply the first shelter [Y] to unlock automatic replanting, including this camp's harvested stumps."
	if grove.growing > 0: text += "\nNext tree matures in %ds." % grove.next
	return text

func replant(world: RefCounted, camp: RefCounted) -> int:
	if world.early.phase < 1 or camp.health <= 0 or not world.in_reach(camp.cell): return 0
	var planted := 0
	for y in range(-4, 5):
		for x in range(-4, 5):
			var cell: Vector2i = camp.cell + Vector2i(x, y)
			if not world.frontier.cleared.has(cell) or not world.frontier.tree_at(world, cell, true): continue
			if plots.size() >= LIMIT: break
			world.frontier.cleared.erase(cell)
			plots[cell] = {"cuts": 0, "ready": world.ticks + GROW_TICKS}
			planted += 1
	world.message.emit("Replanted %d cleared grove plots. Trees mature in two minutes; occupied ground stays clear." % planted)
	world.changed.emit()
	return planted

func serialize() -> Array:
	var records: Array = []
	for cell in plots: records.append([cell.x, cell.y, plots[cell].cuts, plots[cell].ready])
	return records

func restore(world: RefCounted, records) -> bool:
	if not records is Array or records.size() > LIMIT or (not records.is_empty() and not world.early.enabled): return false
	for entry in records:
		if not entry is Array or entry.size() != 4: return false
		if not world.frontier.integer(entry[0]) or not world.frontier.integer(entry[1]) or not world.frontier.integer(entry[2], 0, CUTS - 1) or not world.frontier.integer(entry[3], -1, 2000000000): return false
		var cell := Vector2i(int(entry[0]), int(entry[1]))
		if plots.has(cell) or world.frontier.cleared.has(cell) or not world.frontier.tree_at(world, cell, true): return false
		if int(entry[3]) > world.ticks + GROW_TICKS or (int(entry[3]) != 0 and int(entry[2]) != 0): return false
		plots[cell] = {"cuts": int(entry[2]), "ready": int(entry[3])}
		if int(entry[3]) < 0: awaiting_planting = true
	return true
