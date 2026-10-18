extends VBoxContainer

const Catalog = preload("res://scripts/data/catalog.gd")
const Style = preload("res://scripts/ui/ui_style.gd")
const Icon = preload("res://scripts/ui/item_icon.gd")
const Report = preload("res://scripts/ui/machine_report.gd")
const Grid = preload("res://scripts/ui/inventory_grid.gd")

signal transfer_requested(item: String, quantity: int, source: Dictionary, target: Dictionary, token: int)
signal technology_requested
signal home_requested
signal recipe_requested(id: String)
signal supply_requested
signal collect_requested
signal repair_requested
signal reclaim_requested
signal underground_mode_requested(enabled: bool)

var world: RefCounted
var entity = null
var quantity := 5
var title: Label
var machine_icon: Control
var status_label: Label
var progress: ProgressBar
var recipe_picker: OptionButton
var recipe_ids: Array = []
var supply_button: Button
var collect_button: Button
var repair_button: Button
var reclaim_hint: Label
var reclaim_button: Button
var underground_button: Button
var electric_button: Button
var home_button: Button
var input_box: VBoxContainer
var output_box: VBoxContainer
var fuel_box: VBoxContainer
var input_grid: VBoxContainer
var output_grid: VBoxContainer
var fuel_grid: VBoxContainer
var output_title: Label
var fuel_label: Label
var summary: Label
var blocker_hint: Label
var resolve_button: Button
var resolve_action := ""
var flow: HBoxContainer
var flow_input: Label
var flow_process: Label
var flow_output: Label

func _ready() -> void:
	add_theme_constant_override("separation", 8)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 12)
	add_child(heading)
	machine_icon = Icon.new()
	heading.add_child(machine_icon)
	machine_icon.custom_minimum_size = Vector2(42, 42)
	title = Style.label("Machine", 24, Style.TEXT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	var condition := PanelContainer.new()
	add_child(condition)
	var condition_box := VBoxContainer.new()
	condition.add_child(condition_box)
	status_label = Style.label("",18,Style.GOLD)
	condition_box.add_child(status_label)
	blocker_hint = Style.label("",13,Style.TEXT)
	blocker_hint.max_lines_visible = 3
	condition_box.add_child(blocker_hint)
	resolve_button = Style.button(condition_box,"",_resolve_blocker)
	Style.action(resolve_button)
	flow = HBoxContainer.new()
	flow.add_theme_constant_override("separation",10)
	add_child(flow)
	flow_input = _flow_stage("INPUT")
	flow.add_child(Style.label("→",20,Style.GOLD))
	flow_process = _flow_stage("PROCESS")
	flow.add_child(Style.label("→",20,Style.GOLD))
	flow_output = _flow_stage("OUTPUT")
	var actions := HBoxContainer.new()
	add_child(actions)
	supply_button = Style.button(actions, "Load ingredients", func(): supply_requested.emit())
	Style.action(supply_button)
	collect_button = Style.button(actions, "Collect output [X]", func(): collect_requested.emit())
	repair_button = Style.button(actions, "Repair [H]", func(): repair_requested.emit())
	reclaim_button = Style.button(self, "Pick up building", func(): reclaim_requested.emit())
	reclaim_hint = Style.label("",13,Style.GOLD)
	add_child(reclaim_hint)
	underground_button = Style.button(self, "", func(): underground_mode_requested.emit(not entity.underground_exit))
	home_button = Style.button(self, "Enter cottage / decorate", func(): home_requested.emit())
	electric_button = Style.button(self, "Install electric drive: 2 steel + 4 wire / double speed", func(): world.power.retrofit(world, entity); refresh(world, entity, quantity))
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
	# Supplies take priority over optional retrofits and pickup.
	move_child(recipe_picker,flow.get_index())
	move_child(progress,flow.get_index()+1)
	move_child(stores,progress.get_index()+1)
	move_child(actions,stores.get_index()+1)
	for arrow in flow.get_children():
		if arrow is Label: arrow.autowrap_mode = TextServer.AUTOWRAP_OFF

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
	if grid == output_grid or (grid == input_grid and entity.kind in (["chest", "cart_post", "fuel_depot"] + Catalog.TRANSPORT)):
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
	if machine_icon.item_id != entity.kind:
		machine_icon.item_id = entity.kind
		machine_icon.queue_redraw()
	var reachable: bool = world.in_reach(entity.cell)
	home_button.visible = entity.kind == "cottage"
	home_button.disabled = not world.home.entry_reason(world, entity.id).is_empty()
	home_button.tooltip_text = world.home.entry_reason(world, entity.id)
	electric_button.visible = world.power.LOAD.has(entity.kind) and not entity.electric_mode
	electric_button.disabled = not world.power.retrofit_reason(world, entity).is_empty()
	electric_button.tooltip_text = world.power.retrofit_reason(world, entity)
	underground_button.visible = entity.kind == "underground_belt"
	underground_button.disabled = not reachable
	underground_button.text = ("Exit → set as entrance" if entity.underground_exit else "Entrance → set as exit") + " [G]"
	repair_button.text = "Repair [H] (+%d)" % int(world.character.stat("repair_power"))
	repair_button.visible = entity.health < entity.max_health()
	repair_button.disabled = not reachable or world.player.count("repair_kit") == 0
	var reclaim_blocker: String = world.reclaim_reason(entity.cell)
	reclaim_button.disabled = not reclaim_blocker.is_empty()
	reclaim_hint.visible = not reclaim_blocker.is_empty()
	reclaim_hint.text = reclaim_blocker
	reclaim_button.text = "Pick up building" if reclaim_blocker.is_empty() else "Pick up building (unavailable)"

	reclaim_button.tooltip_text = reclaim_blocker if not reclaim_blocker.is_empty() else "Returns the building, fuel, inputs, and output to your pack. Also: close this panel and hold right mouse over the building for 0.5 seconds. Unfinished work and spent fuel energy are lost."

	supply_button.tooltip_text = ""
	supply_button.text = "Stack matching" if entity.kind in ["chest", "cart_post"] else "Load ingredients"
	supply_button.disabled = not reachable or entity.kind in ["inserter", "power_pole", "wall", "cottage"]
	collect_button.text = "Take all [X]" if entity.kind in (["chest", "cart_post", "fuel_depot"] + Catalog.TRANSPORT) else ("Recover hand [X]" if entity.kind == "inserter" else "Collect output [X]")
	collect_button.disabled = not reachable
	if Catalog.Combat.TURRETS.has(entity.kind): collect_button.text = "Unload ammo [X]"
	if entity.kind in ["wall", "power_pole", "cottage"]: collect_button.visible = false
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
	elif Catalog.BUILDINGS[entity.kind].has("work_ticks"):
		progress.show()
		progress.value = 100.0 * entity.progress / int(Catalog.BUILDINGS[entity.kind].work_ticks)
	if entity.kind in ["drill","lab"]:
		progress.show()
		progress.value = 100.0 * entity.progress / (15 if entity.kind == "drill" else 30)
	var input: Dictionary = entity.inventory.contents.duplicate()
	var expected: Array = []
	if Catalog.Combat.TURRETS.has(entity.kind): expected = ["ammo"]
	if entity.kind in ["fuel_depot", "generator"]: expected = ["coal"]
	if entity.kind == "lab": expected = ["science"]
	var output_expected: Array = []
	if entity.recipe != "":
		expected = Catalog.RECIPES[entity.recipe]["in"].keys()
		output_expected = Catalog.RECIPES[entity.recipe]["out"].keys()
	fuel_box.visible = Catalog.BUILDINGS[entity.kind].get("fuel", false) and (not entity.electric_mode or entity.inventory.count("coal") > 0 or entity.burn_ticks > 0)
	if fuel_box.visible:
		input.erase("coal")
		if entity.kind == "generator": expected = []
	input_box.visible = entity.kind not in ["inserter", "power_pole", "wall", "cottage"]
	output_box.visible = entity.kind not in (["chest", "fuel_depot", "generator", "power_pole", "wall", "cottage"] + Catalog.Combat.TURRETS.keys() + Catalog.TRANSPORT)
	input_grid.grid.columns = 6 if entity.kind in ["chest", "cart_post"] else 3
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
	if entity.kind in ["chest", "cart_post"]: summary.text = "Drop pack items into storage, or Shift-click them in your pack to transfer all. Ctrl-click stacks only item types already stored here; it never dumps unrelated supplies."
	if Catalog.Combat.TURRETS.has(entity.kind): summary.text = "Load ammunition into INPUT manually or by inserter. Guns stop scouts, cannons counter armor, and pulses slow groups. Walls shape routes; scouts can go around isolated barriers. Select a turret to see its range."
	if entity.kind == "fuel_depot":
		summary.text = "Covers %d tiles. Delivers one real coal per nearby burner each tick, keeping a small 3-coal reserve. Load once here or automate an inserter supply. No coal is created. Returning crews and restored depot runners expand coverage." % world.supply_radius()

		supply_button.text = "Load all coal"
	if entity.kind == "generator":
		fuel_label.text = "FUEL / %d coal / %d stored energy" % [entity.inventory.count("coal"), entity.energy]
		supply_button.text = "Load all coal"
	if entity.kind == "cottage": summary.text = Catalog.item_description("cottage")
	if entity.kind in ["generator", "power_pole"]: summary.text = Catalog.item_description(entity.kind)
	if entity.electric_mode: summary.text += "\nElectric drive installed. Stored burner fuel remains withdrawable; power loss pauses work. Pickup also returns 2 steel + 4 wire."
	if entity.kind in world.early.Definitions.BUILDINGS:
		summary.text = Catalog.item_description(entity.kind)
	if entity.kind == "communal_hearth":
		supply_button.text = "Deliver town project [Y]"
		supply_button.disabled = not world.early.project_reason(world).is_empty()
		input_box.hide()
		output_box.hide()
	if entity.kind == "lumber_camp":
		input_box.hide()
		supply_button.text = "Replant cleared grove"
		supply_button.disabled = not reachable or entity.health <= 0 or world.early.phase < 1
		supply_button.tooltip_text = "Explicitly reforest vacant, previously cleared tree plots in this 9 × 9 grove. Restore forest where you want it again. Buildings are excluded. New camp harvests replant automatically."
		summary.text = world.frontier.forestry.describe(world, entity.cell) + "\n" + summary.text
	if entity.kind == "charcoal_kiln": output_title.text = "CHARCOAL FUEL • shared coal stock"
	if entity.kind == "wall": summary.text = "Blocks the marked approach until its health reaches zero. Disabled walls stay in place as passable ruins; repair them with kits [H]. Damaged structures must be repaired before reclamation."

	var report := Report.inspect(world,entity)
	status_label.text = report.title
	status_label.add_theme_color_override("font_color",Style.ACCENT if report.tone == "working" else Style.GOLD)
	blocker_hint.text = report.hint
	blocker_hint.tooltip_text = report.hint
	resolve_action = report.action
	resolve_button.visible = not resolve_action.is_empty()
	resolve_button.text = report.action_text
	resolve_button.disabled = (not reachable and resolve_action != "technology") or (resolve_action == "repair" and world.player.count("repair_kit") == 0)
	resolve_button.tooltip_text = "Walk closer to interact." if not reachable else ("Requires a repair kit in your pack." if resolve_action == "repair" and world.player.count("repair_kit") == 0 else report.hint)
	flow.visible = report.flow
	flow_input.text = report.input
	flow_process.text = report.process
	flow_output.text = report.output
	for label in [flow_input,flow_process,flow_output]: label.tooltip_text = label.text
	summary.text += "\nHealth %d/%d" % [entity.health,entity.max_health()]
	if entity.electric_mode: summary.text += " • Electric drive: double speed • " + world.power.reason(world,entity)
	elif not entity.recipe.is_empty(): summary.text += " • Rated %.1f batches/min" % (600.0 / float(Catalog.RECIPES[entity.recipe].ticks))

func _flow_stage(heading: String) -> Label:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flow.add_child(card)
	var box := VBoxContainer.new()
	card.add_child(box)
	box.add_child(Style.label(heading,11,Style.MUTED))
	var label := Style.label("",13,Style.TEXT)
	box.add_child(label)
	return label

func _resolve_blocker() -> void:
	match resolve_action:
		"supply": supply_requested.emit()
		"collect": collect_requested.emit()
		"repair": repair_requested.emit()
		"technology": technology_requested.emit()
