extends RefCounted
## Optional v2-world extension, with its own schema and currency reconciliation.

const Settlements = preload("res://scripts/simulation/settlements.gd")
const Definitions = preload("res://scripts/data/settlement_catalog.gd")
const Catalog = preload("res://scripts/data/catalog.gd")

static func _int(value, lower: int = 0, upper: int = 2000000000) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value == floor(float(value)) and value >= lower and value <= upper

static func restore(world: RefCounted, data) -> bool:
	if not data is Dictionary or not _int(data.get("version"), 1, 2) or not data.get("enabled") is bool: return false
	if not _int(data.get("credits")) or not _int(data.get("total_earned")): return false
	if not data.get("sites") is Array or data.sites.size() > Definitions.SITES.size() or data.sites.size() < (2 if data.version == 1 else Definitions.SITES.size()): return false
	var region := Settlements.new(bool(data.enabled))
	region.credits = int(data.credits)
	region.total_earned = int(data.total_earned)
	if not _int(data.get("age", 0), 0, 2) or not _int(data.get("stone_shipments", 0)): return false
	region.age = int(data.get("age", 0))
	region.stone_shipments = int(data.get("stone_shipments", 0))
	var seen: Dictionary = {}
	var earned := 0
	var relief = data.get("relief_waves", [])
	if not relief is Array or relief.size() > 10: return false
	for wave in relief:
		if not region.enabled or not _int(wave, 1, 10) or int(wave) in region.relief_waves: return false
		region.relief_waves.append(int(wave))
		earned += region.defense_reward(int(wave))
	if not _int(data.get("supply_orders", 0), 0, 100000000): return false
	region.supply_orders = int(data.get("supply_orders", 0))
	if region.supply_orders > 0 and not region.enabled: return false
	var spent := region.supply_orders * region.SUPPLY_COST
	for record in data.sites:
		if not record is Dictionary or not Definitions.SITES.has(record.get("id")) or seen.has(record.id): return false
		seen[record.id] = true
		if not _int(record.get("x"), -999990, 999990) or not _int(record.get("y"), -999990, 999990) or not record.get("repaired") is bool: return false
		if not _int(record.get("shipment_ticks")) or not _int(record.get("shipments")): return false
		var definition: Dictionary = Definitions.SITES[record.id]
		var site = region.sites[record.id]
		site.origin = Vector2i(int(record.x), int(record.y))
		site.repaired = record.repaired
		var health = record.get("health", site.max_health() if site.repaired else 0)
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
			if not Catalog.ITEMS.has(item) or not allowed.has(item) or not _int(record.inventory[item], 1, int(allowed[item]) * multiplier): return false
			site.inventory.contents[item] = int(record.inventory[item])
		if site.inventory.total() > site.inventory.capacity: return false
		if not region.enabled and (site.repaired or site.inventory.total() > 0 or site.shipment_ticks > 0 or site.shipments > 0): return false
	if region.supply_orders > 0 and (not region.sites.trading_post.repaired or not region.sites.workshop.repaired): return false
	if region.stone_shipments > region.sites.trading_post.shipments: return false
	if region.age == 0 and region.stone_shipments != 0: return false
	if region.age > 0 and not region.enabled: return false
	if not world.early.enabled and (region.age > 1 or (region.age == 1 and not region.sites.town_hall.repaired)): return false
	earned += region.stone_shipments * region.Ages.STONE_MARKET_BONUS
	if earned != region.total_earned or earned - spent != region.credits: return false
	if not seen.has("trading_post") or not seen.has("workshop"): return false
	if not seen.has("town_hall"): region.pending_sites.append("town_hall")
	for id in region.sites:
		var definition: Dictionary = Definitions.SITES[id]
		if region.sites[id].repaired and definition.has("requires") and not region.sites[definition.requires].repaired: return false
	region.rebuild_index()
	world.settlements = region
	return true

static func place_pending(world: RefCounted) -> bool:
	var region = world.settlements
	if not region.enabled:
		region.pending_sites.clear()
		return true
	for id in region.pending_sites:
		var site = region.sites[id]
		var placed := false
		for attempt in range(128):
			site.origin = Definitions.SITES[id].origin + Vector2i(attempt * 8, 0)
			var rect: Rect2i = site.footprint()
			var free := not Rect2(rect).grow(0.22).has_point(world.player_position)
			for other in region.sites:
				if other != id and rect.intersects(region.sites[other].footprint()): free = false
			for x in range(rect.position.x, rect.end.x):
				for y in range(rect.position.y, rect.end.y):
					if world.at(Vector2i(x, y)) != null: free = false
			if free:
				placed = true
				break
		if not placed: return false
	region.pending_sites.clear()
	region.rebuild_index()
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
