extends VBoxContainer

const Catalog = preload("res://scripts/data/catalog.gd")
const Style = preload("res://scripts/ui/ui_style.gd")
const Grid = preload("res://scripts/ui/inventory_grid.gd")

signal transfer_requested(item: String, quantity: int, source: Dictionary, target: Dictionary, token: int)
signal recipe_requested(id: String)
signal supply_requested
signal collect_requested
signal repair_requested

var world: RefCounted
var entity = null
var quantity := 5
var title: Label
var status_label: Label
var progress: ProgressBar
var recipe_picker: OptionButton
var recipe_ids: Array = []
var supply_button: Button
var collect_button: Button
var repair_button: Button
var input_box: VBoxContainer
var output_box: VBoxContainer
var fuel_box: VBoxContainer
var input_grid: VBoxContainer
var output_grid: VBoxContainer
var fuel_grid: VBoxContainer
var output_title: Label
var fuel_label: Label
var summary: Label

func _ready() -> void:
	add_theme_constant_override("separation", 8)
	title = Style.label("Machine", 23, Style.ACCENT)
	add_child(title)
	status_label = Style.label("", 16, Style.GOLD)
	add_child(status_label)
	var actions := HBoxContainer.new()
	add_child(actions)
	supply_button = Style.button(actions, "Load ingredients", func(): supply_requested.emit())
	collect_button = Style.button(actions, "Collect output [X]", func(): collect_requested.emit())
	repair_button = Style.button(actions, "Repair [H]", func(): repair_requested.emit())
	recipe_picker = OptionButton.new()
	recipe_picker.item_selected.connect(func(index): recipe_requested.emit(recipe_ids[index]))
	add_child(recipe_picker)
	progress = ProgressBar.new()
	progress.custom_minimum_size.y = 18
	progress.show_percentage = true
	add_child(progress)
	var stores := HBoxContainer.new()
	stores.add_theme_constant_override("separation", 18)
	add_child(stores)
	input_box = VBoxContainer.new()
	input_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stores.add_child(input_box)
	input_box.add_child(Style.label("INPUT  •  drop / click to load", 13, Style.MUTED))
	input_grid = _new_grid(input_box)
	fuel_box = VBoxContainer.new()
	input_box.add_child(fuel_box)
	fuel_label = Style.label("FUEL", 13, Style.MUTED)
	fuel_box.add_child(fuel_label)
	fuel_grid = _new_grid(fuel_box)
	fuel_grid.grid.columns = 1
	output_box = VBoxContainer.new()
	output_box.custom_minimum_size.x = 260
	output_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stores.add_child(output_box)
	output_title = Style.label("OUTPUT  •  click to take", 13, Style.MUTED)
	output_box.add_child(output_title)
	output_grid = _new_grid(output_box)
	summary = Style.label("", 14, Style.MUTED)
	add_child(summary)

func _new_grid(parent: Node) -> VBoxContainer:
	var grid := Grid.new()
	parent.add_child(grid)
	grid.grid.columns = 3
	grid.item_activated.connect(func(item, gesture): _click_item(grid, item, gesture))
	grid.transfer_dropped.connect(func(data, target): _drop(data, target))
	return grid

func _can_drop(data: Dictionary, target: Dictionary) -> bool:
	return data.get("type") == "inventory_item" and data.get("source") is Dictionary and data.get("item") is String and data.get("world") is int and data.get("amount") is int and data.amount >= 0 and world.transfer_limit(data.item, data.source, target, int(data.world)) > 0

func _can_drop_fuel(data: Dictionary, target: Dictionary) -> bool:
	return data.get("item") == "coal" and _can_drop(data, target)

func _drop(data: Dictionary, target: Dictionary) -> void:
	transfer_requested.emit(data.item, int(data.amount), data.source, target, int(data.world))

func _click_item(grid: VBoxContainer, item: String, gesture: String) -> void:
	var amount := 1 if gesture == "one" else (0 if gesture == "all" else quantity)
	if grid == output_grid or (grid == input_grid and entity.kind in ["chest", "belt", "fast_belt"]):
		transfer_requested.emit(item, amount, grid.descriptor, {"kind": "player"}, world.get_instance_id())
	elif grid.buttons[item].amount > 0:
		transfer_requested.emit(item, amount, grid.descriptor, {"kind": "player"}, world.get_instance_id())
	else:
		transfer_requested.emit(item, amount, {"kind": "player"}, {"kind": "input", "entity_id": entity.id}, world.get_instance_id())

func refresh(state: RefCounted, machine, amount: int) -> void:
	world = state
	entity = machine
	quantity = amount
	if entity == null or title == null: return
	title.text = Catalog.item_name(entity.kind)
	var reachable: bool = world.in_reach(entity.cell)
	status_label.text = entity.status + ("  •  Out of reach" if not reachable else "")
	status_label.text += " • Health %d/%d" % [entity.health, entity.max_health()]
	repair_button.visible = entity.health < entity.max_health()
	repair_button.disabled = not reachable or world.player.count("repair_kit") == 0
	if entity.kind == "drill":
		var deposit: Dictionary = world.terrain.tile(entity.cell)
		status_label.text += "\n%d units remaining under this drill" % int(deposit.get("amount", 0)) if not deposit.is_empty() else "\nPress M to survey another deposit, then hold right mouse to reclaim and relocate this drill."
	supply_button.text = "Stack matching" if entity.kind == "chest" else "Load ingredients"
	supply_button.disabled = not reachable or entity.kind == "inserter"
	collect_button.text = "Take all [X]" if entity.kind in ["chest", "belt", "fast_belt"] else ("Recover hand [X]" if entity.kind == "inserter" else "Collect output [X]")
	collect_button.disabled = not reachable
	if entity.kind == "turret": collect_button.text = "Unload ammo [X]"
	if entity.kind == "wall": collect_button.visible = false
	else: collect_button.visible = true
	var ids: Array = Catalog.BUILDINGS[entity.kind].get("recipes", []).filter(func(id): return world.unlocked(Catalog.RECIPES[id]) and world.content_available(id))
	if ids != recipe_ids:
		recipe_ids = ids
		recipe_picker.clear()
		for id in ids: recipe_picker.add_item("Recipe: " + Catalog.item_name(id))
	recipe_picker.visible = not ids.is_empty()
	recipe_picker.disabled = not reachable
	if not ids.is_empty(): recipe_picker.select(ids.find(entity.recipe))
	progress.visible = entity.recipe != ""
	if entity.recipe != "": progress.value = 100.0 * entity.progress / int(Catalog.RECIPES[entity.recipe].ticks)
	var input: Dictionary = entity.inventory.contents.duplicate()
	var expected: Array = []
	if entity.kind == "turret": expected = ["ammo"]
	var output_expected: Array = []
	if entity.recipe != "":
		expected = Catalog.RECIPES[entity.recipe]["in"].keys()
		output_expected = Catalog.RECIPES[entity.recipe]["out"].keys()
	fuel_box.visible = Catalog.BUILDINGS[entity.kind].get("fuel", false)
	if fuel_box.visible: input.erase("coal")
	input_box.visible = entity.kind not in ["inserter", "wall"]
	output_box.visible = entity.kind not in ["chest", "belt", "fast_belt", "turret", "wall"]
	input_grid.grid.columns = 6 if entity.kind == "chest" else 3
	var descriptor := {"kind": "input", "entity_id": entity.id}
	for grid in [input_grid, fuel_grid, output_grid]:
		grid.world_token = world.get_instance_id()
		grid.transfer_amount = quantity
		grid.can_transfer = _can_drop
	input_grid.descriptor = descriptor
	input_grid.destination = descriptor
	input_grid.refresh(input, expected)
	fuel_grid.descriptor = descriptor
	fuel_grid.destination = descriptor
	fuel_grid.can_transfer = _can_drop_fuel
	fuel_grid.refresh({"coal": entity.inventory.count("coal")}, ["coal"])
	fuel_label.text = "FUEL  •  %d coal  •  %.1fs stored work" % [entity.inventory.count("coal"), entity.burn_ticks / 10.0]
	output_grid.destination = {}
	output_grid.descriptor = {"kind": "output", "entity_id": entity.id}
	output_title.text = "OUTPUT  •  click to take"
	var output: Dictionary = entity.output.contents
	if entity.kind == "inserter":
		output_grid.descriptor = {"kind": "hand", "entity_id": entity.id}
		output_title.text = "IN HAND  •  click to recover"
		output = {entity.carried: 1} if entity.carried != "" else {}
	output_grid.refresh(output, output_expected)
	summary.text = "Click a filled tile to take items; click an empty ingredient to load it. Drag pack items into INPUT or FUEL. Output collection leaves fuel and ingredients in place."
	if entity.kind == "chest": summary.text = "Drop pack items into storage, or Shift-click them in your pack to transfer all. Ctrl-click stacks only item types already stored here; it never dumps unrelated supplies."
	if entity.kind == "turret": summary.text = "Load ammunition into INPUT manually or by inserter. Range: 6 tiles; 12 damage per round; one shot every 0.5 seconds. A wall across the marked lane buys more firing time."
	if entity.kind == "wall": summary.text = "Blocks the marked approach until its health reaches zero. Disabled walls stay in place as passable ruins; repair them with kits [H]. Damaged structures must be repaired before reclamation."
