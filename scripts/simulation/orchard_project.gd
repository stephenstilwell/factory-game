extends RefCounted
## Restorable agricultural outpost with paid beds, funded growing and physical output.
const Inventory = preload("res://scripts/model/inventory.gd")
const INPUTS := {"coal": 1, "plank": 1}
const BED_COST := {"stone": 10, "plank": 8}
const BED_CREDITS := 15
const GROW_TICKS := 450
const SALE_TICKS := 300
const SALE_GOODS := 4
const SALE_REWARD := 6
var kind := "orchard_port"
var inventory := Inventory.new(20)
var output := Inventory.new(24)
var beds := 0
var growth_ticks := 0
var growing_beds := 0
var sale_ticks := 0

func available(world: RefCounted) -> bool:
	return world.frontier.claimed("orchard") and not world.early.active() and world.settlements.enabled and world.settlements.sites.trading_post.repaired and world.settlements.sites.trading_post.health > 0 and world.settlements.services_online()

func restore_bed_reason(world: RefCounted) -> String:
	if not available(world): return "Recover the orchard, rebuild the crossing and reopen healthy town services."
	if beds >= 3: return "All three growing beds are restored."
	if not world.in_reach(world.frontier.port("orchard")): return "Walk to the orchard entrance."
	if world.settlements.credits < BED_CREDITS: return "Needs 15 trade credits."
	if not world.player.has_all(BED_COST): return "Bring 10 stone and 8 planks for the next bed."
	return ""

func restore_bed(world: RefCounted) -> bool:
	var reason := restore_bed_reason(world)
	if not reason.is_empty():
		world.message.emit(reason)
		return false
	if not world.player.exchange(BED_COST, {}): return false
	world.settlements.credits -= BED_CREDITS
	beds += 1
	world.settlements.garden_beds = beds
	world.metrics.consume(world.ticks, BED_COST)
	world.award_skill("mining", 250)
	world.message.emit("Iona restored growing bed %d/3! +250 Gathering XP. Each bed converts 1 charcoal/coal + 1 plank into 4 fresh produce every 45 seconds." % beds)
	world.feedback_requested.emit("success", world.frontier.port("orchard"))
	world.changed.emit()
	return true

func receiving_limit(world: RefCounted, item: String) -> int:
	return maxi(0, 10 - inventory.count(item)) if available(world) and beds > 0 and INPUTS.has(item) else 0

func supply(world: RefCounted) -> bool:
	if not world.frontier.sites.has("orchard") or not world.in_reach(world.frontier.port("orchard")): return false
	var moved := 0
	for item in INPUTS: moved += world.player.move_to(inventory, item, mini(beds, receiving_limit(world, item)))
	if moved == 0: world.message.emit("Bring planks and charcoal/coal for orchard beds.")
	world.changed.emit()
	return moved > 0

func collect(world: RefCounted) -> bool:
	if not world.frontier.sites.has("orchard") or not world.in_reach(world.frontier.port("orchard")): return false
	var moved := output.move_to(world.player, "foraged_food", output.count("foraged_food"))
	if moved == 0: world.message.emit("Harvest not ready, or your pack is full.")
	world.changed.emit()
	return moved > 0

func withdraw(world: RefCounted) -> bool:
	if not world.frontier.sites.has("orchard") or not world.in_reach(world.frontier.port("orchard")): return false
	if not world.player.exchange({}, inventory.contents): return false
	inventory.contents.clear()
	world.changed.emit()
	return true

func market_limit(world: RefCounted) -> int:
	return maxi(0, 16 - world.settlements.sites.trading_post.inventory.count("foraged_food")) if available(world) and beds > 0 else 0

func deliver_market(world: RefCounted) -> bool:
	if not world.in_reach(world.settlements.sites.trading_post.port()): return false
	var moved: int = world.player.move_to(world.settlements.sites.trading_post.inventory, "foraged_food", mini(SALE_GOODS, market_limit(world)))
	world.changed.emit()
	return moved > 0

func step(world: RefCounted) -> void:
	if not available(world) or beds == 0: return
	if growth_ticks == 0:
		var count := mini(beds, mini(inventory.count("coal"), mini(inventory.count("plank"), (output.capacity - output.total()) / 4)))
		if count > 0:
			var goods := {"coal": count, "plank": count}
			if inventory.exchange(goods, {}):
				world.metrics.consume(world.ticks, goods)
				growing_beds = count
				growth_ticks = GROW_TICKS
	if growth_ticks > 0:
		growth_ticks -= 1
		if growth_ticks == 0:
			var yield_count := growing_beds * 4
			output.add("foraged_food", yield_count)
			world.production["foraged_food"] = int(world.production.get("foraged_food", 0)) + yield_count
			world.metrics.record(world.ticks, "made", "foraged_food", yield_count)
			growing_beds = 0
	var market: RefCounted = world.settlements.sites.trading_post.inventory
	if sale_ticks == 0 and market.exchange({"foraged_food": SALE_GOODS}, {}): sale_ticks = SALE_TICKS
	if sale_ticks > 0:
		sale_ticks -= 1
		if sale_ticks == 0:
			world.settlements.produce_sales += 1
			world.settlements.credits += SALE_REWARD
			world.settlements.total_earned += SALE_REWARD
			world.message.emit("Iona's produce reached neighboring homes: +6 trade credits.")
			world.changed.emit()

func serialize() -> Dictionary:
	return {"beds": beds, "inventory": inventory.contents.duplicate(), "output": output.contents.duplicate(), "growth_ticks": growth_ticks, "growing_beds": growing_beds, "sale_ticks": sale_ticks}

func restore(world: RefCounted, data: Variant) -> bool:
	if not data is Dictionary: return false
	for pair in [["beds", 3], ["growth_ticks", GROW_TICKS - 1], ["growing_beds", 3], ["sale_ticks", SALE_TICKS - 1]]:
		if not world.frontier.integer(data.get(pair[0], 0), 0, pair[1]): return false
	beds = int(data.get("beds", 0))
	growth_ticks = int(data.get("growth_ticks", 0))
	growing_beds = int(data.get("growing_beds", 0))
	sale_ticks = int(data.get("sale_ticks", 0))
	if beds != world.settlements.garden_beds: return false
	if (growth_ticks > 0) != (growing_beds > 0) or growing_beds > beds: return false
	if not _inventory(data.get("inventory"), inventory, ["coal", "plank"], 10): return false
	if not _inventory(data.get("output"), output, ["foraged_food"], 24): return false
	if output.total() + growing_beds * 4 > output.capacity: return false
	if beds > 0:
		if not world.frontier.claimed("orchard") or world.early.active() or not world.settlements.sites.trading_post.repaired: return false
	elif inventory.total() > 0 or output.total() > 0 or growth_ticks > 0 or sale_ticks > 0 or world.settlements.produce_sales > 0: return false
	return true

func _inventory(data: Variant, storage: RefCounted, allowed: Array, limit: int) -> bool:
	if not data is Dictionary: return false
	for item in data:
		if item not in allowed or not (data[item] is int or data[item] is float) or not is_finite(float(data[item])) or data[item] != floorf(float(data[item])) or data[item] < 1 or data[item] > limit: return false
		storage.contents[item] = int(data[item])
	return storage.total() <= storage.capacity
