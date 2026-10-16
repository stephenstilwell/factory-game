extends PanelContainer
## One workspace for the pack, recipes, machine buffers, and civic deliveries.

const Catalog = preload("res://scripts/data/catalog.gd")
const Style = preload("res://scripts/ui/ui_style.gd")
const Grid = preload("res://scripts/ui/inventory_grid.gd")
const CraftPanel = preload("res://scripts/ui/crafting_panel.gd")
const MachinePanel = preload("res://scripts/ui/machine_panel.gd")
const TownPanel = preload("res://scripts/ui/settlement_panel.gd")
const CharacterPanel = preload("res://scripts/ui/character_panel.gd")

signal close_requested
signal upgrade_requested(id: String, rank: int)
signal context_changed
signal weapon_requested
signal build_requested(id: String)
signal transfer_requested(item: String, amount: int, source: Dictionary, target: Dictionary, token: int)
signal craft_requested(id: String, count: int)
signal cancel_requested(job_id: int)
signal cancel_all_requested
signal recipe_requested(id: String)
signal supply_requested
signal collect_requested
signal site_selected(id: String)
signal site_supply_requested(id: String)
signal site_restore_requested(id: String)
signal site_talk_requested(id: String)
signal site_withdraw_requested(id: String)
signal age_requested
signal supplies_order_requested
signal beacon_requested
signal beacon_cancel_requested
signal structure_repair_requested
signal building_pickup_requested
signal underground_mode_requested(enabled: bool)

var world: RefCounted
var mode := "inventory"
var entity_id := -1
var site_id := ""
var selected_item := ""
var quantity := 5 # 0 means all available, still bounded by the destination.
var search: LineEdit
var category: OptionButton
var pack_grid: VBoxContainer
var pack_column: VBoxContainer
var pack_capacity: Label
var pack_progress: ProgressBar
var pack_hint: Label
var detail_title: Label
var detail_text: Label
var equip_button: Button
var recipe_button: Button
var quantity_buttons: Dictionary = {}
var tabs: Dictionary = {}
var crafting: VBoxContainer
var machine: VBoxContainer
var town: VBoxContainer
var details: VBoxContainer
var machine_scroll: ScrollContainer
var town_scroll: ScrollContainer
var character_scroll: ScrollContainer
var character_panel: VBoxContainer
var simulation_paused := false
var run_status: Label
var workspace_title: Label
var transfer_help: Label

func _ready() -> void:
	add_theme_stylebox_override("panel", Style.panel(Color("19292e"), Color("6b8e89")))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	var header := HBoxContainer.new()
	box.add_child(header)
	var title := Style.label("PACK & WORKBENCH", 20, Style.ACCENT)
	workspace_title = title
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	run_status = Style.label("Factory running", 12, Style.MUTED)
	run_status.autowrap_mode = TextServer.AUTOWRAP_OFF
	header.add_child(run_status)
	var transfer_label := Style.label("TRANSFER", 12, Style.MUTED)
	transfer_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	header.add_child(transfer_label)
	for amount in [1, 5, 0]:
		quantity_buttons[amount] = Style.button(header, "All" if amount == 0 else str(amount), func(): set_quantity(amount))
	Style.button(header, "Close [Esc]", func(): close_requested.emit())
	var tab_row := HBoxContainer.new()
	box.add_child(tab_row)
	for entry in [["inventory", "Inventory [E]"], ["crafting", "Crafting [C]"], ["character", "Engineer [P]"], ["machine", "Machine"], ["town", "Town [Y]"]]:
		var id: String = entry[0]
		tabs[id] = Style.button(tab_row, entry[1], func(): open_mode(id))
	var help := Style.label("Click to inspect / take. Right-click: 1. Shift-click: all. Drag to transfer the selected quantity.", 13, Style.MUTED)
	transfer_help = help
	box.add_child(help)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 18)
	box.add_child(body)
	var left := VBoxContainer.new()
	pack_column = left
	left.custom_minimum_size.x = 350
	left.add_theme_constant_override("separation", 6)
	body.add_child(left)
	pack_capacity = Style.label("YOUR PACK", 16, Style.ACCENT)
	left.add_child(pack_capacity)
	var filters := HBoxContainer.new()
	left.add_child(filters)
	search = LineEdit.new()
	search.placeholder_text = "Search pack..."
	search.clear_button_enabled = true
	search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	filters.add_child(search)
	category = OptionButton.new()
	for text in ["All", "Resources", "Components", "Buildings"]: category.add_item(text)
	filters.add_child(category)
	search.text_changed.connect(func(_text): refresh(world))
	category.item_selected.connect(func(_index): refresh(world))
	var pack_scroll := ScrollContainer.new()
	pack_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	pack_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(pack_scroll)
	pack_grid = Grid.new()
	pack_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pack_scroll.add_child(pack_grid)
	pack_grid.item_activated.connect(_pack_click)
	pack_grid.transfer_dropped.connect(_drop)
	pack_progress = ProgressBar.new()
	pack_progress.custom_minimum_size.y = 8
	pack_progress.show_percentage = false
	left.add_child(pack_progress)
	pack_hint = Style.label("", 13, Style.MUTED)
	left.add_child(pack_hint)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(right)
	details = VBoxContainer.new()
	right.add_child(details)
	detail_title = Style.label("Your inventory", 24, Style.ACCENT)
	details.add_child(detail_title)
	detail_text = Style.label("", 16)
	details.add_child(detail_text)
	equip_button = Style.button(details, "Equip for building", func():
		if selected_item == "service_rifle": weapon_requested.emit()
		else: build_requested.emit(selected_item))
	recipe_button = Style.button(details, "Show crafting recipe", _show_selected_recipe)
	crafting = CraftPanel.new()
	right.add_child(crafting)
	crafting.craft_requested.connect(func(id, count): craft_requested.emit(id, count))
	crafting.cancel_requested.connect(func(id): cancel_requested.emit(id))
	crafting.cancel_all_requested.connect(func(): cancel_all_requested.emit())
	machine_scroll = _scroll(right)
	machine = MachinePanel.new()
	machine.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	machine_scroll.add_child(machine)
	machine.transfer_requested.connect(func(item, amount, from, to, token): transfer_requested.emit(item, amount, from, to, token))
	machine.recipe_requested.connect(func(id): recipe_requested.emit(id))
	machine.supply_requested.connect(func(): supply_requested.emit())
	machine.collect_requested.connect(func(): collect_requested.emit())
	machine.repair_requested.connect(func(): structure_repair_requested.emit())
	machine.reclaim_requested.connect(func(): building_pickup_requested.emit())
	machine.underground_mode_requested.connect(func(enabled): underground_mode_requested.emit(enabled))
	town_scroll = _scroll(right)
	town = TownPanel.new()
	town.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	town_scroll.add_child(town)
	town.site_selected.connect(func(id): site_selected.emit(id))
	town.supply_requested.connect(func(id): site_supply_requested.emit(id))
	town.restore_requested.connect(func(id): site_restore_requested.emit(id))
	town.talk_requested.connect(func(id): site_talk_requested.emit(id))
	town.withdraw_requested.connect(func(id): site_withdraw_requested.emit(id))
	town.age_requested.connect(func(): age_requested.emit())
	town.supplies_order_requested.connect(func(): supplies_order_requested.emit())
	town.beacon_requested.connect(func(): beacon_requested.emit())
	town.beacon_cancel_requested.connect(func(): beacon_cancel_requested.emit())
	town.repair_requested.connect(func(): structure_repair_requested.emit())
	town.transfer_requested.connect(func(item, amount, from, to, token): transfer_requested.emit(item, amount, from, to, token))
	character_scroll = _scroll(right)
	character_panel = CharacterPanel.new()
	character_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	character_scroll.add_child(character_panel)
	character_panel.upgrade_requested.connect(func(id, rank): upgrade_requested.emit(id, rank))

func _scroll(parent: Node) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroll)
	return scroll

func open_mode(next_mode: String) -> void:
	mode = next_mode
	show()
	refresh(world)
	context_changed.emit()

func set_quantity(amount: int) -> void:
	if amount not in [0, 1, 5]: return
	quantity = amount
	refresh(world)

func destination() -> Dictionary:
	if mode == "machine" and world.entities.has(entity_id): return {"kind": "input", "entity_id": entity_id}
	if mode == "town" and site_id != "" and world.settlements.enabled: return {"kind": "site", "site_id": site_id}
	return {}

func _pack_click(item: String, gesture: String) -> void:
	selected_item = item
	var target := destination()
	if gesture == "equip" and item == "service_rifle": weapon_requested.emit()
	elif gesture == "equip" and Catalog.BUILDINGS.has(item): build_requested.emit(item)
	elif gesture in ["one", "all"] and not target.is_empty():
		transfer_requested.emit(item, 1 if gesture == "one" else 0, {"kind": "player"}, target, world.get_instance_id())
	refresh(world)

func _can_drop(data: Dictionary, target: Dictionary) -> bool:
	return data.get("type") == "inventory_item" and data.get("item") is String and data.get("source") is Dictionary and data.get("world") is int and data.get("amount") is int and data.amount >= 0 and world.transfer_limit(data.item, data.source, target, int(data.world)) > 0

func _drop(data: Dictionary, target: Dictionary) -> void:
	transfer_requested.emit(data.item, int(data.amount), data.source, target, int(data.world))

func _show_selected_recipe() -> void:
	crafting.selected_id = selected_item
	crafting.search.text = ""
	crafting.category.select(0)
	crafting.craftable_only.button_pressed = false
	open_mode("crafting")

func refresh(state: RefCounted) -> void:
	world = state
	if world == null or search == null: return
	workspace_title.text = "ENGINEER • SKILLS & EQUIPMENT" if mode == "character" else "PACK & WORKBENCH"
	transfer_help.visible = mode != "character"
	run_status.text = "Paused [Pause]" if simulation_paused else "Factory running"
	run_status.add_theme_color_override("font_color", Style.GOLD if simulation_paused else Style.MUTED)
	if mode == "machine" and not world.entities.has(entity_id):
		entity_id = -1
		mode = "inventory"
	for id in tabs:
		Style.select(tabs[id], mode == id)
	tabs.machine.visible = world.entities.has(entity_id)
	tabs.town.visible = world.settlements.enabled
	for amount in quantity_buttons: Style.select(quantity_buttons[amount], amount == quantity)
	pack_grid.descriptor = {"kind": "player"}
	pack_grid.destination = {"kind": "player"}
	pack_grid.world_token = world.get_instance_id()
	pack_grid.transfer_amount = quantity
	pack_grid.can_transfer = _can_drop
	pack_grid.refresh(world.player.contents, [], search.text, category.get_item_text(category.selected), selected_item)
	if world.player.total() == 0 and search.text.is_empty(): pack_grid.empty_label.text = "Your pack is empty.\nHover a nearby deposit and hold right mouse to mine, then open Crafting."
	pack_capacity.text = "YOUR PACK  •  %d / %d items" % [world.player.total(), world.player.capacity]
	pack_progress.value = 100.0 * world.player.total() / world.player.capacity if world.player.capacity > 0 else 0
	pack_hint.text = "Shift-click pack items to send them to the open destination." if not destination().is_empty() else "Select an item for details. Double-click buildings to equip."
	details.visible = mode == "inventory"
	crafting.visible = mode == "crafting"
	pack_column.visible = mode not in ["crafting", "character"]
	offset_top = 24 if mode in ["crafting", "character"] else 80
	machine_scroll.visible = mode == "machine"
	town_scroll.visible = mode == "town"
	character_scroll.visible = mode == "character"
	# Compatibility with callers inspecting content visibility directly.
	machine.visible = mode == "machine"
	town.visible = mode == "town"
	if mode == "crafting": crafting.refresh(world)
	if mode == "machine": machine.refresh(world, world.entities[entity_id], quantity)
	if mode == "town": town.refresh(world, site_id, quantity)
	if mode == "character": character_panel.refresh(world)
	if selected_item.is_empty():
		detail_title.text = "Everything you carry, in one place"
		detail_text.text = "Select a tile to inspect an item. Search or filter your pack above.\n\nOpen Crafting to compare your ingredients, craft batches, and manage queued work.\n\nInspect a machine in the world to open its inventories alongside your pack. Use drag-and-drop or Shift-click for quick transfers.\n\nCapacity counts individual items; each tile groups one item type."
	else:
		detail_title.text = Catalog.item_name(selected_item)
		detail_text.text = "%s\n\nIn pack: %d\nCategory: %s\n\n%s" % [Catalog.item_description(selected_item), world.player.count(selected_item), Catalog.category(selected_item), _uses(selected_item)]
	equip_button.visible = Catalog.BUILDINGS.has(selected_item) or selected_item == "service_rifle"
	equip_button.text = "Draw / holster rifle [V]" if selected_item == "service_rifle" else "Equip for building"
	equip_button.disabled = world.player.count(selected_item) == 0 or not world.content_available(selected_item) or not world.unlocked(Catalog.BUILDINGS.get(selected_item, {}))
	recipe_button.visible = Catalog.RECIPES.has(selected_item) and world.Crafting.available(world, selected_item)

func _uses(item: String) -> String:
	var names := PackedStringArray()
	for id in Catalog.RECIPES:
		if Catalog.RECIPES[id]["in"].has(item) and world.content_available(id) and world.unlocked(Catalog.RECIPES[id]): names.append(Catalog.item_name(id))
	return "Used in: " + ", ".join(names) if not names.is_empty() else "Useful in production or settlement deliveries."
