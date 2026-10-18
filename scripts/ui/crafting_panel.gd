extends VBoxContainer

const Catalog = preload("res://scripts/data/catalog.gd")
const Style = preload("res://scripts/ui/ui_style.gd")
const Showcase = preload("res://scripts/ui/showcase.gd")
const Icon = preload("res://scripts/ui/item_icon.gd")
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
var maximum_context: Dictionary = {}
var maximum_cache: Dictionary = {}
var recipe_hero: PanelContainer
var craft_actions: HBoxContainer
var detail_content: VBoxContainer
var preview: Control
var route_label: Label
var stock_cost: Label
var ingredient_states: Dictionary = {}
var ingredient_surfaces: Dictionary = {}
var show_breakdown := false

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
	var catalog_column := VBoxContainer.new()
	catalog_column.custom_minimum_size.x = 424
	body.add_child(catalog_column)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_RESERVE
	catalog_column.add_child(scroll)
	var recipes := VBoxContainer.new()
	recipes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(recipes)
	recipes.add_child(Style.label("RECIPES / count includes intermediate crafts", 13, Style.MUTED))
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	recipes.add_child(grid)
	var recipe_order: Array = ["furnace", "drill", "belt", "inserter", "chest", "fuel_depot", "assembler", "lab", "gear", "wire", "science", "fast_belt", "splitter", "underground_belt", "repair_kit", "wall", "reinforced_wall", "service_rifle", "marksman_rifle", "ammo", "turret", "cannon_turret", "pulse_turret"]
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
	var right_column := VBoxContainer.new()
	right_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(right_column)
	var detail_scroll := ScrollContainer.new()
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_RESERVE
	detail_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_column.add_child(detail_scroll)
	var detail := VBoxContainer.new()
	detail_content = detail
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_theme_constant_override("separation", 8)
	detail_scroll.add_child(detail)
	var hero := PanelContainer.new()
	recipe_hero = hero
	hero.add_theme_stylebox_override("panel", Style.panel(Style.SURFACE, Style.BORDER))
	catalog_column.add_child(hero)
	var hero_row := HBoxContainer.new()
	hero_row.add_theme_constant_override("separation",14)
	hero.add_child(hero_row)
	preview = Showcase.new()
	hero_row.add_child(preview)
	preview.custom_minimum_size = Vector2(116,116)
	var hero_text := VBoxContainer.new()
	hero_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero_row.add_child(hero_text)
	hero_text.add_child(Style.label("MAKE SOMETHING USEFUL",11,Style.GOLD))
	title = Style.label("Choose a recipe",24,Style.TEXT)
	hero_text.add_child(title)
	description = Style.label("",13,Style.MUTED)
	description.max_lines_visible = 3
	hero_text.add_child(description)
	result_label = Style.label("",13,Style.GOLD)
	detail.add_child(result_label)
	var actions := HBoxContainer.new()
	craft_actions = actions
	right_column.add_child(actions)
	craft_one = Style.button(actions, "Craft 1", func(): craft_requested.emit(selected_id, 1))
	Style.action(craft_one)
	craft_five = Style.button(actions, "Craft 5", func(): craft_requested.emit(selected_id, 5))
	craft_max = Style.button(actions, "Craft max", func(): craft_requested.emit(selected_id, world.craft_maximum(selected_id)))
	detail.add_child(HSeparator.new())
	detail.add_child(Style.label("MATERIALS  →  FINISHED ITEM",12,Style.GOLD))
	for item in Catalog.ITEMS:
		var card := PanelContainer.new()
		var surface := Style.panel(Color("1e2730"),Style.BORDER)
		surface.shadow_size = 0
		surface.set_content_margin_all(7)
		surface.border_width_left = 3
		card.add_theme_stylebox_override("panel",surface)
		detail.add_child(card)
		ingredient_surfaces[item] = surface
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation",8)
		card.add_child(row)
		var icon := Icon.new()
		row.add_child(icon)
		icon.item_id = item
		icon.custom_minimum_size = Vector2(24,24)
		var label := Style.label(Catalog.item_name(item),14)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.tooltip_text = Catalog.item_description(item)
		row.add_child(label)
		var count := Style.label("", 15)
		count.custom_minimum_size.x = 62
		row.add_child(count)
		var action := Style.button(row, "Craft missing", func(): _craft_missing(item))
		action.add_theme_font_size_override("font_size", 13)
		var state_label := Style.label("",11,Style.MUTED)
		state_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		row.add_child(state_label)
		ingredient_states[item] = state_label
		ingredient_rows[item] = card
		ingredient_counts[item] = count
		ingredient_actions[item] = action
	stock_cost = Style.label("",13,Style.TEXT)
	detail.add_child(stock_cost)
	route_label = Style.label("",12,Style.ACCENT)
	detail.add_child(route_label)
	var breakdown := Style.button(detail,"Full crafting breakdown",func(): show_breakdown = not show_breakdown; refresh(world))
	breakdown.add_theme_font_size_override("font_size",12)
	missing_label = Style.label("",13,Style.ERROR)
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
	var need: int = int(Catalog.RECIPES[selected_id]["in"].get(item, 0)) - world.player.count(item) - int(world.Crafting.free_outputs(world).get(item, 0))
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
	var available_recipes: Array = Catalog.RECIPES.keys().filter(func(id): return world.Crafting.available(world, id))
	var context := {"pack": world.player.contents.duplicate(), "queued": world.Crafting.free_outputs(world), "slots": world.craft_queue.size(), "recipes": available_recipes}
	if context != maximum_context:
		maximum_context = context
		maximum_cache.clear()
		for id in recipe_buttons: maximum_cache[id] = world.craft_maximum(id) if id in available_recipes else 0
	var shown := 0
	for id in recipe_buttons:
		var tile: Button = recipe_buttons[id]
		var maximum: int = int(maximum_cache.get(id, 0))
		tile.visible = world.Crafting.available(world, id) and (search.text.is_empty() or Catalog.item_name(id).to_lower().contains(search.text.to_lower())) and (category.selected == 0 or Catalog.category(id) == category.get_item_text(category.selected)) and (not craftable_only.button_pressed or maximum > 0)
		if tile.visible: shown += 1
		tile.update_count(maximum, selected_id == id)
		tile.tooltip_text = "%s\nSelect to see ingredients and batch controls.\nMakes: %s" % [Catalog.item_name(id), Catalog.describe(Catalog.RECIPES[id]["out"])]
	recipe_empty.visible = shown == 0
	detail_content.visible = shown > 0
	craft_actions.visible = shown > 0
	recipe_hero.visible = shown > 0
	if shown > 0 and not recipe_buttons[selected_id].visible:
		for id in recipe_buttons:
			if recipe_buttons[id].visible:
				selected_id = id
				break
		for id in recipe_buttons: recipe_buttons[id].update_count(int(maximum_cache.get(id, 0)), selected_id == id)
	if not selected_id.is_empty():
		var recipe: Dictionary = Catalog.RECIPES[selected_id]
		title.text = Catalog.item_name(selected_id)
		description.text = Catalog.item_description(selected_id)
		description.tooltip_text = description.text
		preview.present("item", selected_id)
		var planned: Dictionary = world.Crafting.plan(world, selected_id)
		var total_ticks: int = int(recipe.get("ticks", 5))
		var total_xp: int = int(world.Skills.Definitions.CRAFT_XP.get(selected_id, 0))
		if planned.error.is_empty():
			total_ticks = 0
			total_xp = 0
			for job in planned.jobs:
				total_ticks += int(Catalog.RECIPES[job.recipe].get("ticks", 5))
				total_xp += int(world.Skills.Definitions.CRAFT_XP.get(job.recipe, 0))
		result_label.text = "Result: %s  •  %.1fs  •  +%d Fabrication XP" % [Catalog.describe(recipe["out"]), total_ticks / world.skills.multiplier("fabrication") / 10.0, total_xp]
		var maximum: int = int(maximum_cache.get(selected_id, 0))
		craft_one.disabled = maximum < 1
		craft_five.disabled = maximum < 5
		craft_max.disabled = maximum < 1
		craft_max.text = "Max (%d)" % maximum
		var can_plan: bool = planned.error.is_empty()
		var queued_outputs: Dictionary = world.Crafting.free_outputs(world)
		var steps := PackedStringArray()
		for job in planned.jobs:
			if steps.size() < 4: steps.append(Catalog.item_name(job.recipe))
		route_label.text = " → ".join(steps) + (" → …" if planned.jobs.size() > 4 else "") if can_plan else "Gather the missing materials to continue."
		stock_cost.text = "From pack: " + Catalog.describe(planned.cost) if can_plan else "Materials are reserved only when you start a valid craft."
		missing_label.visible = show_breakdown or not can_plan
		var missing := PackedStringArray()
		for item in ingredient_rows:
			var need: int = int(recipe["in"].get(item, 0))
			ingredient_rows[item].visible = need > 0
			if need == 0: continue
			var have: int = world.player.count(item)
			ingredient_counts[item].text = "%d / %d" % [have, need]
			ingredient_counts[item].add_theme_color_override("font_color", Style.ACCENT if have >= need else (Style.GOLD if can_plan else Style.ERROR))
			var state_color := Style.ACCENT if have >= need else (Style.GOLD if can_plan else Style.ERROR)
			ingredient_states[item].text = "IN PACK" if have >= need else (("IN QUEUE" if int(queued_outputs.get(item, 0)) >= need - have else "AUTO-CRAFT") if can_plan else "MISSING %d" % (need - have))
			ingredient_states[item].add_theme_color_override("font_color", state_color)
			ingredient_surfaces[item].border_color = state_color.darkened(0.25)
			if have < need: missing.append("%d %s" % [need - have, Catalog.item_name(item)])
			var action: Button = ingredient_actions[item]
			action.visible = have < need and world.Crafting.available(world, item)
			var jobs := _missing_jobs(item)
			action.visible = action.visible and jobs > 0
			action.text = "Make %d only" % jobs
			action.disabled = world.craft_maximum(item) < jobs
			action.tooltip_text = "Only queue this %s. Craft 1 above automatically includes missing hand-craftable intermediates for %s." % [Catalog.item_name(item), Catalog.item_name(selected_id)]
		missing_label.text = world.Crafting.describe_plan(planned)
		missing_label.add_theme_color_override("font_color", Style.ACCENT if can_plan else Style.ERROR)
		craft_one.tooltip_text = world.Crafting.describe_plan(planned)
		craft_five.tooltip_text = world.Crafting.describe_plan(world.Crafting.plan(world, selected_id, 5))
		craft_max.tooltip_text = world.Crafting.describe_plan(world.Crafting.plan(world, selected_id, maxi(1, maximum))) + "\nBatch counts are target recipe runs, including space for intermediates."
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
		job_buttons[id].text = ("▶ " if job == world.craft_queue[0] else "") + Catalog.item_name(job.recipe) + "  ×"
		var cancellation: Dictionary = world.Crafting.cancellation(world, id)
		job_buttons[id].tooltip_text = "Cancel this craft%s.\nRefund: %s\nCompleted intermediates stay as real items; unmade parts are never refunded." % [" and %d dependent jobs" % (cancellation.ids.size() - 1) if cancellation.ids.size() > 1 else "", Catalog.describe(cancellation.refund)]
	for id in job_buttons.keys():
		if not active.has(id):
			job_buttons[id].queue_free()
			job_buttons.erase(id)
	cancel_all_button.disabled = world.craft_queue.is_empty()
	cancel_all_button.visible = not world.craft_queue.is_empty()
	queue_scroll.visible = not world.craft_queue.is_empty()
	queue_progress.visible = not world.craft_queue.is_empty()
	queue_label.text = "Your workbench is ready. Choose your next project." if world.craft_queue.is_empty() else "QUEUE %d / 20  •  click a job to cancel" % world.craft_queue.size()
	queue_progress.value = 0
	if not world.craft_queue.is_empty():
		var job: Dictionary = world.craft_queue[0]
		var duration: int = int(Catalog.RECIPES[job.recipe].get("ticks", 5))
		queue_progress.value = 100.0 * (duration - int(job.remaining) + float(job.get("work", 0)) / 100.0) / duration
		queue_label.text = "Making %s  •  %.1fs left  •  %d jobs" % [Catalog.item_name(job.recipe), maxf(0, float(job.remaining) - float(job.get("work", 0)) / 100.0) / world.skills.multiplier("fabrication") / 10.0, world.craft_queue.size()]
		if int(job.remaining) == 0: queue_label.text = "Finished %s • Waiting for pack space" % Catalog.item_name(job.recipe)
