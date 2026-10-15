extends VBoxContainer
## Stable tiles update in place: an inventory refresh never destroys a drag source.

const Catalog = preload("res://scripts/data/catalog.gd")
const Tile = preload("res://scripts/ui/item_tile.gd")
const Style = preload("res://scripts/ui/ui_style.gd")

signal item_activated(item: String, gesture: String)
signal transfer_dropped(data: Dictionary, target: Dictionary)

var buttons: Dictionary = {}
var grid: GridContainer
var empty_label: Label
var descriptor: Dictionary = {}
var destination: Dictionary = {}
var world_token := 0
var transfer_amount := 5
var can_transfer: Callable

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	grid = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	add_child(grid)
	for id in Catalog.ITEMS:
		var tile := Tile.new()
		tile.item_id = id
		grid.add_child(tile)
		tile.activated.connect(func(item, gesture): item_activated.emit(item, gesture))
		tile.transfer_dropped.connect(func(data, target): transfer_dropped.emit(data, target))
		buttons[id] = tile
	empty_label = Style.label("No items yet.\nMine nearby resources, then open Crafting.", 15, Style.MUTED)
	add_child(empty_label)

func refresh(contents: Dictionary, expected: Array = [], query: String = "", category: String = "All", selected: String = "") -> void:
	var shown := 0
	for id in buttons:
		var tile: Button = buttons[id]
		var visible_item: bool = contents.has(id) or id in expected
		visible_item = visible_item and (query.is_empty() or Catalog.item_name(id).to_lower().contains(query.to_lower())) and (category == "All" or Catalog.category(id) == category)
		tile.visible = visible_item
		if not visible_item: continue
		shown += 1
		tile.source = descriptor
		tile.target = destination
		tile.world_token = world_token
		tile.transfer_amount = transfer_amount
		tile.can_transfer = can_transfer
		tile.update_count(int(contents.get(id, 0)), id == selected)
	empty_label.visible = shown == 0
	empty_label.text = "No matching items." if not query.is_empty() or category != "All" else "No items yet.\nDrop accepted goods here, or click an empty ingredient to load it."

func _can_drop_data(_at: Vector2, data) -> bool:
	return data is Dictionary and not destination.is_empty() and can_transfer.is_valid() and can_transfer.call(data, destination)

func _drop_data(_at: Vector2, data) -> void:
	transfer_dropped.emit(data, destination)
