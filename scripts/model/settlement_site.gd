extends RefCounted

const Inventory = preload("res://scripts/model/inventory.gd")
const Definitions = preload("res://scripts/data/settlement_catalog.gd")

# This small receiver interface is also used by inserters.
var kind := "settlement_port"
var id: String
var origin: Vector2i
var inventory: RefCounted
var repaired := false
var shipment_ticks := 0
var shipments := 0
var health := 0

func max_health() -> int:
	return int(Definitions.SITES[id].get("health", 150))

func _init(site_id: String) -> void:
	id = site_id
	origin = Definitions.SITES[id].origin
	inventory = Inventory.new(200)

func footprint() -> Rect2i:
	return Rect2i(origin, Definitions.SITES[id].size)

func port() -> Vector2i:
	return origin + Definitions.SITES[id].port

func serialize() -> Dictionary:
	return {"id": id, "x": origin.x, "y": origin.y, "repaired": repaired,
		"inventory": inventory.contents.duplicate(), "shipment_ticks": shipment_ticks, "shipments": shipments, "health": health}
