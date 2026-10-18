extends RefCounted
## A finite regional logistics project; only committed physical shipments earn rewards.
const Inventory = preload("res://scripts/model/inventory.gd")
const GOODS := {"stone": 20, "plank": 4}
const TOTAL := 9
const TICKS := 600
const REWARD := 12
var kind := "regional_port"
var inventory := Inventory.new(72)
var shipment_ticks := 0

func available(world: RefCounted) -> bool:
	return world.frontier.claimed("quarry") and not world.early.active() and world.settlements.enabled and world.settlements.sites.trading_post.repaired and world.settlements.sites.trading_post.health > 0 and world.settlements.services_online()

func receiving_limit(world: RefCounted, item: String) -> int:
	if not available(world): return 0
	var batches := mini(3, TOTAL - world.settlements.road_deliveries - (1 if shipment_ticks > 0 else 0))
	return maxi(0, int(GOODS.get(item, 0)) * batches - inventory.count(item))

func deliver(world: RefCounted) -> bool:
	if not available(world) or not world.in_reach(world.frontier.port("quarry")):
		world.message.emit("Recover Greybank, rebuild the crossing and reopen the market; then visit the quarry entrance.")
		return false
	var moved := 0
	for item in GOODS:
		moved += world.player.move_to(inventory, item, mini(GOODS[item], receiving_limit(world, item)))
	if moved == 0: world.message.emit("Bring stone and planks, or wait for buffered loads to depart.")
	world.changed.emit()
	return moved > 0

func withdraw(world: RefCounted) -> bool:
	if not world.frontier.sites.has("quarry") or not world.in_reach(world.frontier.port("quarry")): return false
	if not world.player.exchange({}, inventory.contents):
		world.message.emit("Make pack space before withdrawing road supplies.")
		return false
	inventory.contents.clear()
	world.changed.emit()
	return true

func step(world: RefCounted) -> void:
	if not available(world) or world.settlements.road_deliveries >= TOTAL: return
	if shipment_ticks == 0:
		if not inventory.exchange(GOODS, {}): return
		world.metrics.consume(world.ticks, GOODS)
		shipment_ticks = TICKS
	shipment_ticks -= 1
	if shipment_ticks > 0: return
	world.settlements.road_deliveries += 1
	world.settlements.credits += REWARD
	world.settlements.total_earned += REWARD
	var count: int = world.settlements.road_deliveries
	world.message.emit("Greybank road load %d/9 delivered: +12 credits. %s" % [count, "A road section is restored! +15% movement on restored stone paths." if count % 3 == 0 else "Every three loads restores a road section."])
	if count % 3 == 0:
		world.award_automation("greybank:road:%d" % count, "fabrication", 300)
		world.feedback_requested.emit("success", world.frontier.port("quarry"))
	world.changed.emit()

func road(world: RefCounted) -> PackedVector2Array:
	if not world.frontier.sites.has("quarry"): return PackedVector2Array()
	var stages: int = world.settlements.road_deliveries / 3
	if stages == 0: return PackedVector2Array()
	var start := Vector2(world.settlements.sites.workshop.port()) + Vector2(-1, 0.5)
	var finish := Vector2(world.frontier.port("quarry")) + Vector2.ONE * 0.5
	return PackedVector2Array([start, start.lerp(finish, stages / 3.0)])

func movement_multiplier(world: RefCounted) -> float:
	var points := road(world)
	if points.is_empty(): return 1.0
	var closest := Geometry2D.get_closest_point_to_segment(world.player_position, points[0], points[1])
	return 1.15 if closest.distance_squared_to(world.player_position) <= 0.5625 else 1.0

func serialize() -> Dictionary:
	return {"inventory": inventory.contents.duplicate(), "shipment_ticks": shipment_ticks}

func restore(world: RefCounted, data: Variant) -> bool:
	if not data is Dictionary or not data.get("inventory") is Dictionary or not world.frontier.integer(data.get("shipment_ticks", 0), 0, TICKS - 1): return false
	shipment_ticks = int(data.get("shipment_ticks", 0))
	var remaining := mini(3, TOTAL - world.settlements.road_deliveries - (1 if shipment_ticks > 0 else 0))
	for item in data.inventory:
		if not GOODS.has(item) or not world.frontier.integer(data.inventory[item], 1, int(GOODS[item]) * remaining): return false
		inventory.contents[item] = int(data.inventory[item])
	if world.settlements.road_deliveries > 0 or shipment_ticks > 0 or inventory.total() > 0:
		if not world.frontier.claimed("quarry") or world.early.active() or not world.settlements.sites.trading_post.repaired: return false
	if world.settlements.road_deliveries == TOTAL and shipment_ticks != 0: return false
	for threshold in [3, 6, 9]:
		if world.automation_awards.has("greybank:road:%d" % threshold) != (world.settlements.road_deliveries >= threshold): return false
	return true
