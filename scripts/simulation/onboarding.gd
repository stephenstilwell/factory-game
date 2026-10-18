extends RefCounted
## Permanent learning milestones. Counters record actions, never current possessions.
## No free items or buildings are awarded. Research remains a separate science system.

const Catalog = preload("res://scripts/data/catalog.gd")
const STAGES := [
	{"id": "stone", "title": "Gather stone", "goals": {"mined:stone": 5}, "target": "stone", "hint": "Walk with WASD. Hover the pale stone at (26, 9) and hold right mouse to mine 5 stone."},
	{"id": "craft_furnace", "title": "Craft your first furnace", "goals": {"crafted:furnace": 1}, "hint": "Press C, select Stone furnace, then choose Craft 1. It costs 5 stone; wait for the queue to finish."},
	{"id": "place_furnace", "title": "Place the furnace", "goals": {"placed:furnace": 1}, "hint": "Select the furnace on your hotbar and left-click empty ground near you. Esc clears the build tool. Click a machine to inspect it."},
	{"id": "ingredients", "title": "Gather iron and prepare charcoal", "goals": {"mined:iron_ore": 5, "produced:coal": 2}, "target": "iron_ore", "hint": "Now you can mine iron. Gather 5 ore near (14, 16). Your charcoal clamp produces furnace fuel from timber; collect it with X. No coal mining is required."},
	{"id": "feed_furnace", "title": "Fuel and load your furnace", "goals": {"fed:iron_ore": 5, "fed:coal": 2}, "machine": "furnace", "hint": "Walk back to your furnace. Click it, then use Load ingredients to insert ore and coal. Watch its status change to Working."},
	{"id": "smelt", "title": "Smelt iron plates", "goals": {"smelted:iron_plate": 5}, "machine": "furnace", "hint": "The furnace burns coal to turn ore into plates. Inspect its progress and output; one coal now supports seven plates of active work."},
	{"id": "collect_plates", "title": "Collect your first plates", "goals": {"collected:iron_plate": 5}, "machine": "furnace", "hint": "Select the furnace and press X to collect its output. Gears and the burner drill become available next."},
	{"id": "gears", "title": "Make three gears", "goals": {"crafted:gear": 3}, "hint": "C opens crafting. Each gear costs 2 iron plates. Mine and smelt more ore as needed; you need 11 plates total for a drill."},
	{"id": "craft_drill", "title": "Craft a burner drill", "goals": {"crafted:drill": 1}, "hint": "Gather 5 more stone. Craft a burner drill with 5 iron plates, 3 gears, and 5 stone. No supplies are granted."},
	{"id": "drill_online", "title": "Let a drill do the mining", "goals": {"extracted:iron_ore": 1}, "target": "iron_ore", "hint": "Select the drill on your hotbar and place it on iron ore. Ctrl-click it to supply coal. It stores mined ore in its output; X collects it."},
	{"id": "storage", "title": "Build your first automated line", "goals": {"stored:iron_plate": 5}, "machine": "furnace", "hint": "Craft belts, inserters, and a chest. Route drill -> belts -> inserter -> furnace -> inserter -> chest. R rotates; inserters pick behind and drop ahead. Build a Supply Hearth nearby and load its shared coal reserve to refuel burners automatically."},
	{"id": "copper", "title": "Smelt copper", "goals": {"smelted:copper_plate": 5}, "target": "copper_ore", "hint": "Mine copper near (28, 23). Click a furnace and choose copper in its recipe selector. Supply copper ore and coal; X collects finished plates."},
	{"id": "assembly", "title": "Automate a gear", "goals": {"assembled:gear": 1}, "hint": "Craft an assembler (9 plates + 5 gears), place it, and Ctrl-click to supply iron plates. Its default recipe makes gears. Choose other recipes in its Machine tab."},
	{"id": "science", "title": "Make engineering dossiers", "goals": {"produced:science": 10}, "hint": "Craft 10 engineering dossiers by hand or in an assembler. Each costs 1 iron plate, 1 gear, and 1 copper plate. Build a drafting bench using plates, gears, and copper wire."},
	{"id": "research", "title": "Complete your first research", "goals": {"researched:logistics": 1}, "hint": "Place a drafting bench. Supply 10 engineering dossiers (Ctrl-click loads up to 5 at a time), or use an inserter. Supply routes unlocks fast conveyors."},
]

const REVEALS := {
	"gear": "collect_plates", "drill": "collect_plates",
	"belt": "drill_online", "inserter": "drill_online", "chest": "drill_online",
	"assembler": "storage", "wire": "storage", "science": "assembly", "lab": "assembly",
	"fast_belt": "research",
}

var enabled := false
var counters: Dictionary = {}
var completed: Array = []

func stage_at(index: int) -> Dictionary:
	return STAGES[index]

func current() -> Dictionary:
	return stage_at(completed.size()) if enabled and completed.size() < STAGES.size() else {}

func available(id: String) -> bool:
	return not enabled or not REVEALS.has(id) or REVEALS[id] in completed

func record(key: String, amount: int = 1) -> Array:
	if not enabled or amount <= 0: return []
	counters[key] = int(counters.get(key, 0)) + amount
	var newly_completed: Array = []
	while not current().is_empty() and satisfied(current()):
		var stage := current()
		completed.append(stage.id)
		newly_completed.append(stage.title)
	return newly_completed

func satisfied(stage: Dictionary) -> bool:
	for key in stage.goals:
		if int(counters.get(key, 0)) < int(stage.goals[key]): return false
	return true

func objective_text() -> String:
	var stage := current()
	if stage.is_empty(): return "FOUNDATIONS COMPLETE - expand your factory and research steel smelting."
	var parts := PackedStringArray()
	for key in stage.goals:
		var id: String = key.split(":")[1]
		parts.append("%s %d/%d" % [Catalog.item_name(id) if Catalog.ITEMS.has(id) else "Supply routes", mini(int(counters.get(key, 0)), int(stage.goals[key])), int(stage.goals[key])])
	return "LEARN %d/%d  %s  |  %s" % [completed.size() + 1, STAGES.size(), stage.title, ", ".join(parts)]

func target(world: RefCounted) -> Dictionary:
	var stage := current()
	if stage.has("machine"):
		var ids: Array = world.by_kind[stage.machine]
		if not ids.is_empty():
			var entity = world.entities[ids[0]]
			return {"cell": entity.cell, "label": Catalog.item_name(entity.kind)}
	if not stage.has("target"): return {}
	var item: String = stage.target
	if stage.id == "ingredients" and int(counters.get("mined:iron_ore", 0)) >= 5: item = "coal"
	# Fall back to a nearby remaining tile when the patch center is occupied/depleted.
	for patch in world.terrain.START_PATCHES:
		if patch[2] != item: continue
		var center: Vector2i = patch[0]
		for radius in range(int(patch[1]) + 1):
			for x in range(-radius, radius + 1):
				for y in range(-radius, radius + 1):
					var cell := center + Vector2i(x, y)
					if world.at(cell) == null and not world.terrain.tile(cell).is_empty(): return {"cell": cell, "label": Catalog.item_name(item)}
	return {}

func serialize() -> Dictionary:
	return {"enabled": enabled, "counters": counters.duplicate(), "completed": completed.duplicate()}
