extends VBoxContainer

const Catalog = preload("res://scripts/data/catalog.gd")
const Style = preload("res://scripts/ui/ui_style.gd")
const Tile = preload("res://scripts/ui/item_tile.gd")

signal craft_requested(id: String, count: int)
signal cancel_requested(job_id: int)
signal cancel_all_requested

var world: RefCounted
var selected_id := ""
var search: LineEdit
var category: OptionButton
var craftable_only: CheckButton
var recipe_buttons: Dictionary = {}
var recipe_empty: Label
var title: Label
var description: Label
var result_label: Label
var ingredient_rows: Dictionary = {}
var ingredient_counts: Dictionary = {}
var ingredient_actions: Dictionary = {}
var craft_one: Button
var craft_five: Button
var craft_max: Button
var missing_label: Label
var queue_label: Label
var queue_progress: ProgressBar
var jobs_box: HBoxContainer
var job_buttons: Dictionary = {}
var cancel_all_button: Button
var queue_scroll: ScrollContainer
var detail_content: VBoxContainer

func _ready() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	var filters := HBoxContainer.new()
	add_child(filters)
	search = LineEdit.new()
	search.placeholder_text = "Search recipes..."
	search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search.clear_button_enabled = true
	filters.add_child(search)
	category = OptionButton.new()
	for text in ["All", "Buildings", "Components"]: category.add_item(text)
	filters.add_child(category)
	craftable_only = CheckButton.new()
	craftable_only.text = "Ready only"
	filters.add_child(craftable_only)
	search.text_changed.connect(func(_text): refresh(world))
	category.item_selected.connect(func(_index): refresh(world))
	craftable_only.toggled.connect(func(_value): refresh(world))
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 18)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(body)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.x = 666
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	var recipes := VBoxContainer.new()
	recipes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(recipes)
	recipes.add_child(Style.label("RECIPES  •  count = craftable batches", 13, Style.MUTED))
	var grid := GridContainer.new()
	grid.columns = 8
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	recipes.add_child(grid)
	var recipe_order: Array = ["furnace", "drill", "belt", "inserter", "chest", "fuel_depot", "assembler", "lab", "gear", "wire", "science", "fast_belt", "splitter", "underground_belt", "repair_kit", "wall", "service_rifle", "ammo", "turret", "cannon_turret", "pulse_turret"]
	for id in Catalog.RECIPES:
		if id not in recipe_order: recipe_order.append(id)
	for id in recipe_order:
		if not Catalog.RECIPES[id].get("hand", false): continue
		var tile := Tile.new()
		tile.item_id = id
		tile.compact = true
		grid.add_child(tile)
		tile.activated.connect(func(item, _gesture): select_recipe(item))
		recipe_buttons[id] = tile
	recipe_empty = Style.label("No matching recipes.", 14, Style.MUTED)
	recipes.add_child(recipe_empty)
	var detail_scroll := ScrollContainer.new()
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(detail_scroll)
	var detail := VBoxContainer.new()
	detail_content = detail
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_theme_constant_override("separation", 8)
	detail_scroll.add_child(detail)
	title = Style.label("Choose a recipe", 23, Style.ACCENT)
	detail.add_child(title)
	description = Style.label("", 14, Style.MUTED)
	description.hide()
	detail.add_child(description)
	result_label = Style.label("", 16, Style.GOLD)
	detail.add_child(result_label)
	var actions := HBoxContainer.new()
	detail.add_child(actions)
	craft_one = Style.button(actions, "Craft 1", func(): craft_requested.emit(selected_id, 1))
	craft_five = Style.button(actions, "Craft 5", func(): craft_requested.emit(selected_id, 5))
	craft_max = Style.button(actions, "Craft max", func(): craft_requested.emit(selected_id, world.craft_maximum(selected_id)))
	detail.add_child(Style.label("INGREDIENTS   have / need for 1 batch", 13, Style.MUTED))
	for item in Catalog.ITEMS:
		var row := HBoxContainer.new()
		detail.add_child(row)
		var label := Style.label(Catalog.item_name(item), 15)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.tooltip_text = Catalog.item_description(item)
		row.add_child(label)
		var count := Style.label("", 15)
		count.custom_minimum_size.x = 62
		row.add_child(count)
		var action := Style.button(row, "Craft missing", func(): _craft_missing(item))
		action.add_theme_font_size_override("font_size", 13)
		ingredient_rows[item] = row
		ingredient_counts[item] = count
		ingredient_actions[item] = action
	missing_label = Style.label("", 14, Style.ERROR)
	detail.add_child(missing_label)
	var queue_header := HBoxContainer.new()
	add_child(queue_header)
	queue_label = Style.label("QUEUE 0 / 20", 15)
	queue_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	queue_header.add_child(queue_label)
	cancel_all_button = Style.button(queue_header, "Cancel all / refund", func(): cancel_all_requested.emit())
	queue_progress = ProgressBar.new()
	queue_progress.custom_minimum_size.y = 6
	queue_progress.show_percentage = false
	add_child(queue_progress)
	queue_scroll = ScrollContainer.new()
	queue_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	queue_scroll.custom_minimum_size.y = 54
	add_child(queue_scroll)
	jobs_box = HBoxContainer.new()
	queue_scroll.add_child(jobs_box)

func select_recipe(id: String) -> void:
	selected_id = id
	refresh(world)

func _missing_jobs(item: String) -> int:
	if selected_id.is_empty() or not Catalog.RECIPES.has(item): return 0
	var need: int = int(Catalog.RECIPES[selected_id]["in"].get(item, 0)) - world.player.count(item)
	var yield_count: int = int(Catalog.RECIPES[item]["out"].get(item, 1))
	return ceili(maxi(0, need) / float(yield_count))

func _craft_missing(item: String) -> void:
	var jobs := _missing_jobs(item)
	if jobs > 0: craft_requested.emit(item, jobs)

func refresh(state: RefCounted) -> void:
	world = state
	if world == null or search == null: return
	if selected_id.is_empty() or not world.Crafting.available(world, selected_id):
		selected_id = ""
		for id in recipe_buttons:
			if world.Crafting.available(world, id):
				selected_id = id
				break
	var shown := 0
	for id in recipe_buttons:
		var tile: Button = recipe_buttons[id]
		var maximum: int = world.craft_maximum(id)
		tile.visible = world.Crafting.available(world, id) and (search.text.is_empty() or Catalog.item_name(id).to_lower().contains(search.text.to_lower())) and (category.selected == 0 or Catalog.category(id) == category.get_item_text(category.selected)) and (not craftable_only.button_pressed or maximum > 0)
		if tile.visible: shown += 1
		tile.update_count(maximum, selected_id == id)
		tile.tooltip_text = "%s\nSelect to see ingredients and batch controls.\nMakes: %s" % [Catalog.item_name(id), Catalog.describe(Catalog.RECIPES[id]["out"])]
	recipe_empty.visible = shown == 0
	detail_content.visible = shown > 0
	if shown > 0 and not recipe_buttons[selected_id].visible:
		for id in recipe_buttons:
			if recipe_buttons[id].visible:
				selected_id = id
				break
		for id in recipe_buttons: recipe_buttons[id].update_count(world.craft_maximum(id), selected_id == id)
	if not selected_id.is_empty():
		var recipe: Dictionary = Catalog.RECIPES[selected_id]
		title.text = Catalog.item_name(selected_id)
		description.text = Catalog.item_description(selected_id)
		result_label.text = "Makes %s  |  %.2f sec / batch avg  |  %d Fabrication XP" % [Catalog.describe(recipe["out"]), float(recipe.get("ticks", 5)) / world.skills.multiplier("fabrication") / 10.0, int(world.Skills.Definitions.CRAFT_XP.get(selected_id, 0))]
		var maximum: int = world.craft_maximum(selected_id)
		craft_one.disabled = maximum < 1
		craft_five.disabled = maximum < 5
		craft_max.disabled = maximum < 1
		craft_max.text = "Max (%d)" % maximum
		var missing := PackedStringArray()
		for item in ingredient_rows:
			var need: int = int(recipe["in"].get(item, 0))
			ingredient_rows[item].visible = need > 0
			if need == 0: continue
			var have: int = world.player.count(item)
			ingredient_counts[item].text = "%d / %d" % [have, need]
			ingredient_counts[item].add_theme_color_override("font_color", Style.ACCENT if have >= need else Style.ERROR)
			if have < need: missing.append("%d %s" % [need - have, Catalog.item_name(item)])
			var action: Button = ingredient_actions[item]
			action.visible = have < need and world.Crafting.available(world, item)
			var jobs := _missing_jobs(item)
			action.text = "Make %d" % jobs
			action.disabled = world.craft_maximum(item) < jobs
			action.tooltip_text = "Craft the missing %s first. Ingredients are reserved now; wait for completion before crafting %s." % [Catalog.item_name(item), Catalog.item_name(selected_id)]
		missing_label.text = "Missing: " + ", ".join(missing) if not missing.is_empty() else ("Queue full. Finish or cancel a job." if world.craft_queue.size() >= 20 else "Ready. Ingredients are reserved when queued.")
		missing_label.add_theme_color_override("font_color", Style.ACCENT if missing.is_empty() and maximum > 0 else Style.ERROR)
		for button in [craft_one, craft_five, craft_max]: button.tooltip_text = missing_label.text + "\nBatch counts are recipe runs, not individual output items."
	_refresh_queue()

func _refresh_queue() -> void:
	var active: Dictionary = {}
	for job in world.craft_queue:
		var id: int = int(job.id)
		active[id] = true
		if not job_buttons.has(id):
			var button := Style.button(jobs_box, "", func(): cancel_requested.emit(id))
			button.add_theme_font_size_override("font_size", 13)
			job_buttons[id] = button
		job_buttons[id].text = Catalog.item_name(job.recipe) + "  ×"
		job_buttons[id].tooltip_text = "Cancel this job and refund its reserved ingredients."
	for id in job_buttons.keys():
		if not active.has(id):
			job_buttons[id].queue_free()
			job_buttons.erase(id)
	cancel_all_button.disabled = world.craft_queue.is_empty()
	cancel_all_button.visible = not world.craft_queue.is_empty()
	queue_scroll.visible = not world.craft_queue.is_empty()
	queue_progress.visible = not world.craft_queue.is_empty()
	queue_label.text = "QUEUE %d / 20  •  click a job to cancel" % world.craft_queue.size()
	queue_progress.value = 0
	if not world.craft_queue.is_empty():
		var job: Dictionary = world.craft_queue[0]
		var duration: int = int(Catalog.RECIPES[job.recipe].get("ticks", 5))
		queue_progress.value = 100.0 * (duration - int(job.remaining) + float(job.get("work", 0)) / 100.0) / duration
		if int(job.remaining) == 0: queue_label.text = "QUEUE %d / 20  •  waiting for pack space" % world.craft_queue.size()
