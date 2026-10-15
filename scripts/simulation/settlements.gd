extends RefCounted
## Repair is permanent. Supplies fund timed shipments; income never accrues on a
## bare timer without consumed goods. Derived civic effects cannot stack duplicates.

const Definitions = preload("res://scripts/data/settlement_catalog.gd")
const Site = preload("res://scripts/model/settlement_site.gd")
const Catalog = preload("res://scripts/data/catalog.gd")

var enabled := false
var sites: Dictionary = {}
var occupancy: Dictionary = {}
var ports: Dictionary = {}
var credits := 0
var total_earned := 0
var pending_sites: Array = [] # Only used while migrating an older save.

func services_online() -> bool:
	return not sites.town_hall.repaired or sites.town_hall.health > 0

func _init(active: bool = false) -> void:
	enabled = active
	for id in Definitions.SITES: sites[id] = Site.new(id)
	rebuild_index()

func rebuild_index() -> void:
	occupancy.clear()
	ports.clear()
	if not enabled: return
	for id in sites:
		var site = sites[id]
		var rect: Rect2i = site.footprint()
		for x in range(rect.position.x, rect.end.x):
			for y in range(rect.position.y, rect.end.y): occupancy[Vector2i(x, y)] = id
		ports[site.port()] = id

func at(cell: Vector2i):
	return sites.get(occupancy.get(cell, ""))

func receiver(cell: Vector2i):
	return sites.get(ports.get(cell, ""))

func receiving_limit(site_id: String, item: String) -> int:
	if not enabled or not sites.has(site_id): return 0
	var site = sites[site_id]
	var definition: Dictionary = Definitions.SITES[site_id]
	var wanted: Dictionary = definition.repair
	if site.repaired and site.health == 0: return 0
	var multiplier := 1
	if site.repaired:
		if not definition.has("contract"): return 0
		var contract: Dictionary = Definitions.CONTRACTS[definition.contract]
		wanted = contract.goods
		multiplier = int(contract.buffer_batches)
	return maxi(0, int(wanted.get(item, 0)) * multiplier - site.inventory.count(item))

func repair_reason(site_id: String) -> String:
	if not enabled or not sites.has(site_id): return "Unknown settlement project."
	var site = sites[site_id]
	var definition: Dictionary = Definitions.SITES[site_id]
	if site.repaired: return "Already restored."
	if definition.has("requires") and not sites[definition.requires].repaired: return "Restore %s first." % Definitions.SITES[definition.requires].name
	if credits < int(definition.credits): return "Need %d trade credits; earn them through supply contracts." % definition.credits
	if not site.inventory.has_all(definition.repair): return "Deliver the remaining repair materials first."
	return ""

func restore(site_id: String) -> String:
	var reason := repair_reason(site_id)
	if not reason.is_empty(): return reason
	var site = sites[site_id]
	var definition: Dictionary = Definitions.SITES[site_id]
	if not site.inventory.exchange(definition.repair, {}): return "Repair materials are missing."
	credits -= int(definition.credits)
	site.repaired = true
	site.health = site.max_health()
	return ""

func effect(name: String) -> int:
	if not enabled or not services_online(): return 0
	var value := 0
	for id in sites:
		if sites[id].repaired and sites[id].health > 0: value = maxi(value, int(Definitions.SITES[id].get("effect", {}).get(name, 0)))
	return value

func step(world: RefCounted) -> void:
	if not enabled or not services_online(): return
	for id in sites:
		var site = sites[id]
		var definition: Dictionary = Definitions.SITES[id]
		if not site.repaired or site.health <= 0 or not definition.has("contract"): continue
		var contract: Dictionary = Definitions.CONTRACTS[definition.contract]
		if site.shipment_ticks == 0:
			if not site.inventory.exchange(contract.goods, {}): continue
			site.shipment_ticks = int(contract.ticks)
		site.shipment_ticks -= 1
		if site.shipment_ticks == 0:
			site.shipments += 1
			credits += int(contract.reward)
			total_earned += int(contract.reward)
			var next_step := "Keep our neighbors supplied." if sites.workshop.repaired else "Fund the engineers' workshop next."
			world.message.emit("Mira: Shipment delivered! +%d trade credits. %s" % [contract.reward, next_step])
			world.changed.emit()

func status(site_id: String) -> String:
	var site = sites[site_id]
	if not site.repaired: return "Ready for restoration" if repair_reason(site_id).is_empty() else "Ruined - awaiting repairs"
	if site.health == 0: return "Disabled — repair with kits [H]"
	if not services_online(): return "Services suspended — repair the Town Hall"
	var definition: Dictionary = Definitions.SITES[site_id]
	if site_id == "town_hall": return "Restored — beacon ready for voluntary defenses"
	if not definition.has("contract"): return "Restored - regional bonus active"
	if site.shipment_ticks > 0: return "Shipment en route - %.1f seconds" % (site.shipment_ticks / 10.0)
	return "Open - waiting for contract supplies"

func objective_text() -> String:
	if not sites.trading_post.repaired: return "Reopen Oldbridge trading post: 20 iron plates, 5 gears, 10 stone. [T] Town"
	if not sites.workshop.repaired: return "Earn 60 trade credits and restore the engineers' workshop. [T] Town"
	if not sites.town_hall.repaired: return "Rebuild Oldbridge Town Hall and prepare its beacon defenses. [T] Town"
	if not services_online(): return "Repair the breached Town Hall with kits [H] to restore town services."
	return "Town Hall restored! Prepare walls, loaded turrets, and repair kits; light the beacon when ready. [T] Town"

func objective_target() -> Dictionary:
	if not enabled: return {}
	var site = sites.trading_post if not sites.trading_post.repaired else (sites.workshop if not sites.workshop.repaired else sites.town_hall)
	return {} if site.repaired else {"cell": site.port(), "label": Definitions.SITES[site.id].name}

func install_legacy(world: RefCounted) -> bool:
	# Add new ruins to old factories without overwriting existing machines or the engineer.
	enabled = true
	occupancy.clear()
	ports.clear()
	for id in sites:
		var site = sites[id]
		var placed := false
		for attempt in range(128):
			site.origin = Definitions.SITES[id].origin + Vector2i(attempt * 8, 0)
			var rect: Rect2i = site.footprint()
			var free := not Rect2(rect).grow(0.22).has_point(world.player_position)
			for x in range(rect.position.x, rect.end.x):
				for y in range(rect.position.y, rect.end.y):
					if world.at(Vector2i(x, y)) != null or occupancy.has(Vector2i(x, y)): free = false
			if not free: continue
			for x in range(rect.position.x, rect.end.x):
				for y in range(rect.position.y, rect.end.y): occupancy[Vector2i(x, y)] = id
			ports[site.port()] = id
			placed = true
			break
		if not placed: return false
	return true

func serialize() -> Dictionary:
	var records: Array = []
	for id in Definitions.SITES: records.append(sites[id].serialize())
	return {"version": 2, "enabled": enabled, "credits": credits, "total_earned": total_earned, "sites": records}
