extends RefCounted
## Material-funded civic commissioning; proof counts actual electric work, not idle generators.
const Catalog = preload("res://scripts/data/catalog.gd")
const STAGES := [
 {"name":"A pantry for returning families","goods":{"foraged_food":12,"plank":16},"purpose":"Orchard harvests become reliable food for the families coming home."},
 {"name":"Light the working district","goods":{"wire":24,"gear":12},"purpose":"Give Oren a working local power system, not another silent monument."},
 {"name":"A town worth returning to","goods":{"foraged_food":24,"plank":24,"stone":24},"purpose":"Finish the road, prepare a neighborhood, and invite the region to the homecoming fair."}
]
const WORK_TICKS := 300
const RADIUS := 12
var stage := 0
var work_ticks := 0
var last_work_tick := -1

func unlocked(world: RefCounted) -> bool:
	return world.settlements.enabled and not world.early.active() and world.settlements.sites.town_hall.repaired

func goods() -> Dictionary:
	return STAGES[stage].goods if stage < STAGES.size() else {}

func reason(world: RefCounted) -> String:
	if not unlocked(world): return "Restore Town Hall to begin the homecoming chapter."
	if stage == 3: return "Oldbridge's homecoming fair is open."
	if not world.settlements.services_online() or world.settlements.sites.workshop.health <= 0 or world.settlements.sites.trading_post.health <= 0: return "Repair civic services before commissioning the next phase."
	if stage == 0 and world.orchard_project.beds < 1: return "Build a growing bed at the Lost Orchard [L]."
	if stage == 1:
		if "metallurgy" not in world.researched: return "Research Foundry craft [T] to build local power."
		if work_ticks < WORK_TICKS: return "Run an electric machine within 12 tiles of Town Hall: %.1f / 30 seconds of real work. Pauses keep progress." % (work_ticks/10.0)
	if stage == 2:
		if world.settlements.road_deliveries < 9: return "Finish Greybank's road: %d / 9 loads [L]." % world.settlements.road_deliveries
		if world.settlements.district_level() < 1: return "Restore the first neighborhood: %d / 3 housing deliveries at Town Hall." % world.settlements.sites.town_hall.shipments
	if not world.settlements.sites.town_hall.inventory.has_all(goods()): return "Deliver the remaining phase supplies to Town Hall."
	return ""

func observe_work(world: RefCounted, entity: RefCounted) -> void:
	if stage != 1 or not unlocked(world) or not world.settlements.services_online() or last_work_tick == world.ticks: return
	if not entity.electric_mode or entity.health <= 0 or not world.power.LOAD.has(entity.kind): return
	if entity.cell.distance_squared_to(world.settlements.sites.town_hall.origin) > RADIUS*RADIUS: return
	work_ticks = mini(WORK_TICKS,work_ticks+1)
	last_work_tick = world.ticks

func deliver(world: RefCounted) -> bool:
	if not unlocked(world) or not world.in_reach(world.settlements.sites.town_hall.port()): return false
	if stage == 3: return world.transfer_item("coal",0,{"kind":"player"},{"kind":"site","site_id":"town_hall"}) > 0
	var moved := 0
	var hall = world.settlements.sites.town_hall
	for item in goods():
		moved += world.player.move_to(hall.inventory,item,world.settlements.receiving_limit("town_hall",item,world))
	world.changed.emit()
	if moved == 0: world.message.emit("Bring " + Catalog.describe(goods()) + " for this homecoming phase.")
	return moved > 0

func commission(world: RefCounted) -> bool:
	var blocker := reason(world)
	if not blocker.is_empty():
		world.message.emit(blocker)
		return false
	var hall = world.settlements.sites.town_hall
	if not world.in_reach(hall.port()):
		world.message.emit("Walk to Town Hall's delivery hatch to commission this phase.")
		return false
	if not hall.inventory.exchange(goods(),{}): return false
	world.metrics.consume(world.ticks,goods())
	stage += 1
	world.chapter_progressed.emit(stage)
	world.feedback_requested.emit("success",hall.port())
	world.message.emit("Homecoming phase %d/3 complete. %s" % [stage,"The fair is open; Town Hall's public fuel depot now serves nearby burners." if stage == 3 else STAGES[stage].purpose])
	world.changed.emit()
	return true

func objective(world: RefCounted) -> String:
	if stage == 3: return "Oldbridge's homecoming fair is open! Supply coal to Town Hall's public depot [Y]."
	return "HOMECOMING %d/3 • %s [Y] Town" % [stage+1,STAGES[stage].name]

func describe(world: RefCounted) -> String:
	var hall = world.settlements.sites.town_hall
	if stage == 3: return "Families have a pantry, a working district and a road home. Talk to Ada at Town Hall for the homecoming conclusion. Town Hall now distributes your real coal to drills and furnaces within 12 tiles, up to one coal per second. Buffer: %d/100 coal. No fuel is created. The fair is a permanent civic milestone; beacon defenses remain optional." % hall.inventory.count("coal")
	var parts := PackedStringArray()
	for item in goods(): parts.append("%s %d/%d" % [Catalog.item_name(item),mini(hall.inventory.count(item),int(goods()[item])),goods()[item]])
	return STAGES[stage].purpose + "\n" + " • ".join(parts) + "\n" + reason(world) + "\nPayoff: a visible homecoming fair, Ada's conclusion and Town Hall's public fuel depot. Deliver through its existing hatch manually or by inserter. Housing supplies remain separate."

func step(world: RefCounted) -> void:
	if stage != 3 or world.ticks % 10 != 0 or not world.settlements.services_online(): return
	var hall = world.settlements.sites.town_hall
	if hall.health <= 0 or hall.inventory.count("coal") == 0: return
	var candidates: Array = []
	for kind in ["drill","furnace"]:
		for id in world.by_kind[kind]:
			var entity = world.entities[id]
			if entity.health > 0 and not entity.electric_mode and entity.inventory.count("coal") < 3 and entity.cell.distance_squared_to(hall.origin) <= RADIUS*RADIUS: candidates.append(entity)
	if candidates.is_empty(): return
	candidates.sort_custom(func(a,b): return a.id < b.id)
	var target = candidates[(world.ticks/10) % candidates.size()]
	hall.inventory.move_to(target.inventory,"coal",1)

func serialize() -> Dictionary:
	return {"stage":stage,"work_ticks":work_ticks,"last_work_tick":last_work_tick}

func restore(data, ticks: int) -> bool:
	if not data is Dictionary or data.size() != 3: return false
	for key in ["stage","work_ticks","last_work_tick"]:
		var value = data.get(key)
		if not (value is int or value is float) or not is_finite(float(value)) or value != floor(value): return false
	if data.stage < 0 or data.stage > 3 or data.work_ticks < 0 or data.work_ticks > WORK_TICKS or data.last_work_tick < -1 or data.last_work_tick > ticks: return false
	if data.stage == 0 and (data.work_ticks != 0 or data.last_work_tick != -1): return false
	if data.stage >= 2 and data.work_ticks != WORK_TICKS: return false
	if (data.work_ticks == 0) != (data.last_work_tick == -1): return false
	if data.work_ticks > ticks: return false
	stage = int(data.stage)
	work_ticks = int(data.work_ticks)
	last_work_tick = int(data.last_work_tick)
	return true

func valid_world(world: RefCounted) -> bool:
	if stage == 0 and work_ticks == 0: return true
	if not unlocked(world) or world.orchard_project.beds < 1: return false
	if work_ticks > 0 and "metallurgy" not in world.researched: return false
	if stage == 3 and (world.settlements.road_deliveries < 9 or world.settlements.district_level() < 1): return false
	return true
