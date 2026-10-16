extends RefCounted
## Repair is permanent. Supplies fund timed shipments; income never accrues on a
## bare timer without consumed goods. Derived civic effects cannot stack duplicates.

const Definitions = preload("res://scripts/data/settlement_catalog.gd")
const Ages = preload("res://scripts/data/settlement_ages.gd")
const Site = preload("res://scripts/model/settlement_site.gd")
const Catalog = preload("res://scripts/data/catalog.gd")

var enabled := false
var sites: Dictionary = {}
var occupancy: Dictionary = {}
var ports: Dictionary = {}
var credits := 0
var total_earned := 0
var relief_waves: Array = []
var supply_orders := 0
var age := 0
var stone_shipments := 0 # Reconcile only market premiums actually earned after advancement.
var pending_sites: Array = [] # Only used while migrating an older save.
const SUPPLY_COST := 20
const SUPPLY_BUNDLE := {"coal": 20, "ammo": 10, "repair_kit": 2}

func age_reason(world: RefCounted, require_reach: bool = true) -> String:
	if world.early.enabled: return "Use the shelter and crossing projects in Town [Y]."
	if age > 0: return "Stone & Water is already established."
	if not enabled or not sites.town_hall.repaired: return "Restore the market, workshop and Town Hall first."
	if not services_online(): return "Repair the breached Hall before rebuilding."
	if world.defense.phase in ["warning", "active"]: return "Finish the beacon defense before rebuilding."
	if not world.frontier.claimed("orchard"): return "Recover the Lost Orchard cutting [L]."
	if not world.frontier.claimed("quarry"): return "Recover Greybank Quarry's mason pattern [L]."
	if require_reach and not world.in_reach(sites.town_hall.port()): return "Walk to the Town Hall delivery hatch."
	if not world.player.has_all(Ages.STONE_GOODS): return "Bring 80 stone, 20 iron plates and 10 gears in your pack."
	return ""

func advance_age(world: RefCounted) -> bool:
	if world.early.enabled: return world.early.advance(world)
	var reason := age_reason(world)
	if not reason.is_empty():
		world.message.emit(reason)
		return false
	if not world.player.exchange(Ages.STONE_GOODS, {}): return false
	age = 1
	world.metrics.consume(world.ticks, Ages.STONE_GOODS)
	world.award_skill("fabrication", 500)
	world.message.emit("Oldbridge enters Stone & Water! Civic buildings gain dressed-stone foundations. Each future market shipment earns +2 credits. +500 Fabrication XP.")
	world.feedback_requested.emit("success", sites.town_hall.port())
	world.changed.emit()
	return true

func age_summary(world: RefCounted) -> String:
	if world.early.enabled: return world.early.summary(world)
	var text: String = "TOWN AGE: " + Ages.AGES[age].name + "\n" + Ages.AGES[age].description
	if age == 0:
		text += "\nNEXT: Stone & Water • dressed-stone civic buildings, +2 credits per future market shipment, 500 Fabrication XP."
		text += "\n%s Hall restored   %s Orchard recovered   %s Mason pattern recovered" % ["[x]" if sites.town_hall.repaired else "[ ]", "[x]" if world.frontier.claimed("orchard") else "[ ]", "[x]" if world.frontier.claimed("quarry") else "[ ]"]
		text += "\nProject supplies (from pack):"
		for item in Ages.STONE_GOODS: text += "\n%s %d / %d" % [Catalog.item_name(item), world.player.count(item), Ages.STONE_GOODS[item]]
		text += "\n" + ("Ready — visit the Hall to begin." if age_reason(world, false).is_empty() else age_reason(world, false))
	else:
		text += "\nACTIVE: +2 credits per market shipment while services operate. No automatic waves."
	return text

func supply_order_reason(world: RefCounted) -> String:
	if not enabled or not sites.trading_post.repaired or sites.trading_post.health <= 0 or not services_online(): return "Restore town services first."
	if not sites.workshop.repaired: return "Restore the workshop to order ammunition."
	if not world.in_reach(sites.trading_post.port()): return "Walk to the trading post hatch."
	if credits < SUPPLY_COST: return "Needs 20 credits."
	if not world.player.can_exchange({}, SUPPLY_BUNDLE): return "Make room for 32 items in your pack."
	return ""

func order_supplies(world: RefCounted) -> bool:
	var reason := supply_order_reason(world)
	if not reason.is_empty():
		world.message.emit(reason)
		return false
	if not world.player.exchange({}, SUPPLY_BUNDLE): return false
	credits -= SUPPLY_COST
	supply_orders += 1
	world.message.emit("Trade supplies delivered: 20 coal, 10 ammunition, 2 repair kits. Spent 20 credits.")
	world.feedback_requested.emit("transfer", sites.trading_post.port())
	world.changed.emit()
	return true

static func defense_reward(wave: int) -> int:
	return 25 + 5 * wave

func award_defense(wave: int) -> int:
	if not enabled or wave < 1 or wave > 10 or wave in relief_waves: return 0
	var reward := defense_reward(wave)
	relief_waves.append(wave)
	credits += reward
	total_earned += reward
	return reward

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
	if site_id == "town_hall" and district_level() >= 3: return 0
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

func district_level() -> int:
	return mini(3, int(sites.town_hall.shipments) / 3) if enabled and sites.town_hall.repaired else 0

func effect(name: String) -> int:
	if not enabled or not services_online(): return 0
	var value := 0
	for id in sites:
		if sites[id].repaired and sites[id].health > 0: value = maxi(value, int(Definitions.SITES[id].get("effect", {}).get(name, 0)))
	if name == "burner_ticks": value += district_level() * 12
	return value

func step(world: RefCounted) -> void:
	if not enabled or not services_online(): return
	for id in sites:
		var site = sites[id]
		var definition: Dictionary = Definitions.SITES[id]
		if not site.repaired or site.health <= 0 or not definition.has("contract"): continue
		var contract: Dictionary = Definitions.CONTRACTS[definition.contract]
		if id == "town_hall" and district_level() >= 3: continue
		if site.shipment_ticks == 0:
			if not site.inventory.exchange(contract.goods, {}): continue
			world.metrics.consume(world.ticks, contract.goods)
			site.shipment_ticks = int(contract.ticks)
		site.shipment_ticks -= 1
		if site.shipment_ticks == 0:
			var previous_district := district_level()
			site.shipments += 1
			var milestones: Array = world.skills.Definitions.DELIVERY_MILESTONES
			for i in range(milestones.size()):
				if site.shipments == milestones[i]: world.award_automation("delivery:%s:%d" % [id, milestones[i]], "fabrication", world.skills.Definitions.DELIVERY_XP[i])
			if id == "town_hall" and site.shipments in [3, 6, 9]: world.award_automation("delivery:town_hall:%d" % site.shipments, "fabrication", 500 * (site.shipments / 3))
			if district_level() > previous_district:
				world.message.emit("A neighborhood is restored! District %d/3. New coal gains another 5%% working time." % district_level())
				world.feedback_requested.emit("success", site.port())
			var premium := Ages.STONE_MARKET_BONUS if age >= 1 and id == "trading_post" else 0
			if premium > 0: stone_shipments += 1
			credits += int(contract.reward) + premium
			total_earned += int(contract.reward) + premium
			var next_step := "Keep our neighbors supplied." if sites.workshop.repaired else "Fund the engineers' workshop next."
			if id != "town_hall": world.message.emit("Supply delivery complete! +%d trade credits. %s" % [int(contract.reward) + premium, next_step])
			elif district_level() == previous_district: world.message.emit("Housing supplies delivered: %d/3 toward the next neighborhood." % (site.shipments % 3))
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
	if not sites.trading_post.repaired: return "Reopen Oldbridge trading post: 20 iron plates, 5 gears, 10 stone. [Y] Town"
	if not sites.workshop.repaired: return "Earn 60 trade credits and restore the engineers' workshop. [Y] Town"
	if not sites.town_hall.repaired: return "Rebuild Oldbridge Town Hall and prepare its beacon defenses. [Y] Town"
	if not services_online(): return "Repair the breached Town Hall with kits [H] to restore town services."
	if age == 0: return "Timber → Stone: recover the orchard and Greybank mason pattern [L], then rebuild at the Hall [Y]."
	if district_level() < 3: return "Restore neighborhoods %d/3: research Homes for Oldbridge [T], then automate housing deliveries [Y]." % district_level()
	return "Oldbridge neighborhoods restored! Prepare defenses and light the beacon when ready. [Y] Town"

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
	return {"version": 2, "enabled": enabled, "credits": credits, "total_earned": total_earned, "relief_waves": relief_waves.duplicate(), "supply_orders": supply_orders, "age": age, "stone_shipments": stone_shipments, "sites": records}
