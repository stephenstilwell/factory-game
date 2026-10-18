extends RefCounted
## Current settlement schema and currency reconciliation.

const Settlements = preload("res://scripts/simulation/settlements.gd")
const Definitions = preload("res://scripts/data/settlement_catalog.gd")
const Catalog = preload("res://scripts/data/catalog.gd")

static func _int(value, lower: int = 0, upper: int = 2000000000) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value == floor(float(value)) and value >= lower and value <= upper

static func restore(world: RefCounted, data) -> bool:
	if not data is Dictionary or data.get("version") != 2 or not data.get("enabled") is bool: return false
	if not _int(data.get("credits")) or not _int(data.get("total_earned")): return false
	if not data.get("sites") is Array or data.sites.size() != Definitions.SITES.size(): return false
	var region := Settlements.new(bool(data.enabled))
	if not region.homecoming.restore(data.get("homecoming"),world.ticks): return false
	region.credits = int(data.credits)
	region.total_earned = int(data.total_earned)
	if not _int(data.age, 0, 2) or not _int(data.stone_shipments): return false
	region.age = int(data.age)
	region.stone_shipments = int(data.stone_shipments)
	var seen: Dictionary = {}
	var earned := 0
	var relief = data.relief_waves
	if not relief is Array or relief.size() > 10: return false
	for wave in relief:
		if not region.enabled or not _int(wave, 1, 10) or int(wave) in region.relief_waves: return false
		region.relief_waves.append(int(wave))
		earned += region.defense_reward(int(wave))
	if not _int(data.supply_orders, 0, 100000000): return false
	region.supply_orders = int(data.supply_orders)
	if region.supply_orders > 0 and not region.enabled: return false
	if not _int(data.maintenance_kits, 0, 100000000): return false
	region.maintenance_kits = int(data.maintenance_kits)
	if not _int(data.road_deliveries, 0, 9): return false
	region.road_deliveries = int(data.road_deliveries)
	if region.road_deliveries > 0 and not region.enabled: return false
	earned += region.road_deliveries * world.quarry_project.REWARD
	if not _int(data.garden_beds, 0, 3) or not _int(data.produce_sales, 0, 100000000): return false
	region.garden_beds = int(data.garden_beds)
	region.produce_sales = int(data.produce_sales)
	if region.garden_beds > 0 and not region.enabled: return false
	earned += region.produce_sales * world.orchard_project.SALE_REWARD
	var spent: int = region.garden_beds * world.orchard_project.BED_CREDITS + region.supply_orders * region.SUPPLY_COST + region.maintenance_kits * world.TownServices.CREDIT_PER_KIT
	for record in data.sites:
		if not record is Dictionary or not Definitions.SITES.has(record.get("id")) or seen.has(record.id): return false
		seen[record.id] = true
		if not _int(record.get("x"), -999990, 999990) or not _int(record.get("y"), -999990, 999990) or not record.get("repaired") is bool: return false
		if not _int(record.get("shipment_ticks")) or not _int(record.get("shipments")): return false
		var definition: Dictionary = Definitions.SITES[record.id]
		var site = region.sites[record.id]
		site.origin = Vector2i(int(record.x), int(record.y))
		site.repaired = record.repaired
		var health = record.get("health")
		if not _int(health, 0, site.max_health()) or (not site.repaired and health != 0): return false
		site.health = int(health)
		site.shipment_ticks = int(record.shipment_ticks)
		site.shipments = int(record.shipments)
		var allowed: Dictionary = definition.repair
		var multiplier := 1
		if site.repaired:
			spent += int(definition.credits)
			if definition.has("contract"):
				var contract: Dictionary = Definitions.CONTRACTS[definition.contract]
				allowed = contract.goods
				multiplier = int(contract.buffer_batches)
				if site.shipment_ticks >= int(contract.ticks): return false
				if site.id == "town_hall" and (site.shipments > 9 or (site.shipments == 9 and site.shipment_ticks > 0)): return false
				earned += site.shipments * int(contract.reward)
			else:
				allowed = {}
				if site.shipment_ticks != 0 or site.shipments != 0: return false
		elif site.shipment_ticks != 0 or site.shipments != 0: return false
		if not record.get("inventory") is Dictionary: return false
		for item in record.inventory:
			var limit: int = 16 if record.id == "trading_post" and site.repaired and region.garden_beds > 0 and item == "foraged_food" else int(allowed.get(item, 0)) * multiplier
			if record.id == "workshop" and site.repaired and item == "ammo" and 1 in region.relief_waves: limit = 100
			if record.id == "town_hall" and site.repaired:
				limit = maxi(limit,int(region.homecoming.goods().get(item,0)))
				if item == "coal" and region.homecoming.stage == 3: limit = 100
			if not Catalog.ITEMS.has(item) or not _int(record.inventory[item], 1, limit): return false
			site.inventory.contents[item] = int(record.inventory[item])
		if site.inventory.total() > site.inventory.capacity: return false
		if not region.enabled and (site.repaired or site.inventory.total() > 0 or site.shipment_ticks > 0 or site.shipments > 0): return false
	if (region.supply_orders > 0 or region.maintenance_kits > 0) and (not region.enabled or not region.sites.trading_post.repaired or not region.sites.workshop.repaired): return false
	if region.stone_shipments > region.sites.trading_post.shipments: return false
	if region.age == 0 and region.stone_shipments != 0: return false
	if region.age > 0 and not region.enabled: return false
	earned += region.stone_shipments * region.Ages.STONE_MARKET_BONUS
	if earned != region.total_earned or earned - spent != region.credits: return false
	if not seen.has("trading_post") or not seen.has("workshop"): return false
	for id in region.sites:
		var definition: Dictionary = Definitions.SITES[id]
		if region.sites[id].repaired and definition.has("requires") and not region.sites[definition.requires].repaired: return false
	region.rebuild_index()
	world.settlements = region
	return true

static func valid_layout(world: RefCounted) -> bool:
	if not world.settlements.enabled: return true
	var occupied: Dictionary = {}
	for site in world.settlements.sites.values():
		var rect: Rect2i = site.footprint()
		if Rect2(rect).grow(0.22).has_point(world.player_position): return false
		for x in range(rect.position.x, rect.end.x):
			for y in range(rect.position.y, rect.end.y):
				var cell := Vector2i(x, y)
				if occupied.has(cell) or world.at(cell) != null: return false
				occupied[cell] = true
	return true
