extends RefCounted

const Inventory = preload("res://scripts/model/inventory.gd")
const Catalog = preload("res://scripts/data/catalog.gd")

var id := 0
var kind := ""
var cell := Vector2i.ZERO
var direction := 0
var inventory: RefCounted
var output: RefCounted
var recipe := ""
var progress := 0
var burn_ticks := 0
var cooldown := 0
var carried := ""
var status := "Idle"
var health := 100
var attack_cooldown := 0
var supply_cursor := 0
var routing_cursor := 0
var merge_cursor := 0
var underground_exit := false

func max_health() -> int:
	return int(Catalog.BUILDINGS[kind].get("health", 100))

func _init(entity_id: int = 0, type: String = "belt", position: Vector2i = Vector2i.ZERO, facing: int = 0) -> void:
	id = entity_id
	kind = type
	cell = position
	direction = posmod(facing, 4)
	health = max_health()
	inventory = Inventory.new(int(Catalog.BUILDINGS[kind].capacity))
	output = Inventory.new(10)
	var recipes: Array = Catalog.BUILDINGS[kind].get("recipes", [])
	if not recipes.is_empty(): recipe = recipes[0]

func serialize() -> Dictionary:
	return {"id": id, "kind": kind, "x": cell.x, "y": cell.y, "direction": direction,
		"inventory": inventory.contents.duplicate(), "output": output.contents.duplicate(),
		"recipe": recipe, "progress": progress, "burn_ticks": burn_ticks,
		"cooldown": cooldown, "carried": carried, "health": health, "attack_cooldown": attack_cooldown, "supply_cursor": supply_cursor, "routing_cursor": routing_cursor, "merge_cursor": merge_cursor, "underground_exit": underground_exit}
