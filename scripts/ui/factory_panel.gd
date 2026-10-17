extends ColorRect
const Catalog = preload("res://scripts/data/catalog.gd")
const Diagnostics = preload("res://scripts/simulation/factory_diagnostics.gd")
const Style = preload("res://scripts/ui/ui_style.gd")
signal research_requested(id: String)
signal copy_requested
signal paste_requested
signal build_requested
signal clear_requested
var world: RefCounted
var tab := "research"
var sections: Dictionary = {}
var tabs: Dictionary = {}
var research_buttons: Dictionary = {}
var research_status: Label
var production_rows: GridContainer
var production_labels: Dictionary = {}
var diagnostics: Label
var window_label: Label
var demand: Label
var power_status: Label
var plan_rows: Dictionary = {}
var nearby_plans: CheckButton
var locate_button: Button
var plan_status: Label
var undo_button: Button
var redo_button: Button
var refresh_time := 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color = Color(0.02, 0.04, 0.045, 0.85)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(780, 540)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	var header := HBoxContainer.new()
	box.add_child(header)
	var title := Style.label("OLDBRIDGE WORKSHOP", 23, Style.ACCENT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	Style.button(header, "Close [Esc]", close_panel)
	var controls := HBoxContainer.new()
	box.add_child(controls)
	for id in ["research", "production", "plans"]:
		tabs[id] = Style.button(controls, ("Technology [T]" if id == "research" else id.capitalize()), func(): tab = id; refresh())
		var section := VBoxContainer.new()
		section.add_theme_constant_override("separation", 10)
		box.add_child(section)
		sections[id] = section
	research_status = Style.label("", 16, Style.GOLD)
	sections.research.add_child(research_status)
	var project_grid := GridContainer.new()
	project_grid.columns = 2
	project_grid.add_theme_constant_override("h_separation", 12)
	project_grid.add_theme_constant_override("v_separation", 12)
	sections.research.add_child(project_grid)
	for definition in Catalog.TECHNOLOGIES:
		var button := Style.button(project_grid, "", func(): research_requested.emit(definition.id))
		button.custom_minimum_size = Vector2(358, 130)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		research_buttons[definition.id] = button
	sections.research.add_child(Style.label("HOW IT WORKS: Choose a project, then deliver engineering dossiers to a drafting bench. Switching banks invested dossiers. Completion waits for your next choice. Equipment also needs the restored workshop.", 15, Style.MUTED))
	window_label = Style.label("", 14, Style.MUTED)
	sections.production.add_child(window_label)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(740, 210)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sections.production.add_child(scroll)
	production_rows = GridContainer.new()
	production_rows.columns = 4
	production_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	production_rows.add_theme_constant_override("h_separation", 25)
	scroll.add_child(production_rows)
	for column in range(4):
		var heading := Style.label(["ITEM", "MADE / MIN", "USED / MIN", "NET / MIN"][column], 13, Style.ACCENT)
		heading.autowrap_mode = TextServer.AUTOWRAP_OFF
		heading.custom_minimum_size.x = 215 if column == 0 else 110
		production_rows.add_child(heading)
	for id in Catalog.ITEMS:
		var row: Array = []
		for i in range(4):
			var label := Style.label("", 14)
			label.custom_minimum_size.x = 215 if i == 0 else 110
			production_rows.add_child(label)
			row.append(label)
		production_labels[id] = row
	diagnostics = Style.label("", 14, Style.GOLD)
	diagnostics.max_lines_visible = 3
	sections.production.add_child(diagnostics)
	locate_button = Style.button(sections.production, "Locate nearest stalled machine", _locate_stalled)
	power_status = Style.label("", 14, Style.ACCENT)
	sections.production.add_child(power_status)
	demand = Style.label("", 14, Style.MUTED)
	demand.max_lines_visible = 4
	sections.production.add_child(demand)
	plan_status = Style.label("", 16, Style.GOLD)
	sections.plans.add_child(plan_status)
	nearby_plans = CheckButton.new()
	nearby_plans.text = "Nearby plans only (within building reach)"
	nearby_plans.button_pressed = true
	nearby_plans.toggled.connect(func(_value): refresh())
	sections.plans.add_child(nearby_plans)
	var supply_scroll := ScrollContainer.new()
	supply_scroll.custom_minimum_size = Vector2(740, 155)
	supply_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sections.plans.add_child(supply_scroll)
	var supplies := GridContainer.new()
	supplies.columns = 6
	supplies.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	supplies.add_theme_constant_override("h_separation", 14)
	supply_scroll.add_child(supplies)
	for heading in ["BUILDING", "PLAN", "PACK", "QUEUED", "MISSING", ""]:
		var heading_label := Style.label(heading, 13, Style.ACCENT)
		heading_label.custom_minimum_size.x = 210 if heading == "BUILDING" else 60
		supplies.add_child(heading_label)
	for kind in Catalog.BUILDINGS:
		var labels: Array = []
		for i in range(5):
			var label := Style.label("", 14)
			label.custom_minimum_size.x = 210 if i == 0 else 60
			supplies.add_child(label)
			labels.append(label)
		var craft := Style.button(supplies, "Craft", func():
			world.plans.craft_missing(world, kind, nearby_plans.button_pressed)
			refresh())
		craft.tooltip_text = "Queue only missing buildings, accounting for pack stock and existing jobs. Uses available ingredients."
		plan_rows[kind] = {"labels": labels, "button": craft}
	sections.plans.add_child(Style.label("Ctrl+C: copy area / Ctrl+V: stamp / R: rotate / Shift+build: ghost\nB: build nearby / RMB: remove / Ctrl+Z: undo / Ctrl+Y: redo\nCraft buttons reserve real ingredients. Plans never copy items or fuel.", 16))
	var actions := HBoxContainer.new()
	sections.plans.add_child(actions)
	Style.button(actions, "Copy area", func(): close_panel(); copy_requested.emit())
	Style.button(actions, "Stamp clipboard", func(): close_panel(); paste_requested.emit())
	Style.button(actions, "Build nearby [B]", func(): build_requested.emit(); refresh())
	Style.button(actions, "Clear ghosts", func(): clear_requested.emit(); refresh())
	var history_actions := HBoxContainer.new()
	sections.plans.add_child(history_actions)
	undo_button = Style.button(history_actions, "Undo plan edit [Ctrl+Z]", func(): world.plans.undo(world); refresh())
	redo_button = Style.button(history_actions, "Redo [Ctrl+Y]", func(): world.plans.redo(world); refresh())
	hide()

func open_panel(state: RefCounted, next_tab: String = "") -> void:
	world = state
	if sections.has(next_tab): tab = next_tab
	refresh()
	show()

func close_panel() -> void:
	hide()
	var focused := get_viewport().gui_get_focus_owner()
	if focused != null: focused.release_focus()

func _process(delta: float) -> void:
	if not visible: return
	refresh_time += delta
	if refresh_time >= 0.5:
		refresh_time = 0
		refresh()

func refresh() -> void:
	if world == null: return
	for id in sections:
		sections[id].visible = id == tab
		Style.select(tabs[id], id == tab)
	if tab == "research":
		world.guidance.view_projects(world)
		var active: String = world.current_research()
		research_status.text = "Choose what Oldbridge needs next - click an available project" if active.is_empty() else "ACTIVE: %s  •  %d / %d dossiers" % [Catalog.technology(active).name, world.research_progress, Catalog.technology(active).cost]
		for definition in Catalog.TECHNOLOGIES:
			var done: bool = definition.id in world.researched
			var available: bool = world.research_available(definition.id) and world.content_available("lab")
			var progress: int = world.research_progress if definition.id == active else int(world.research_banks.get(definition.id, 0))
			if done: progress = int(definition.cost)
			var prerequisites := PackedStringArray()
			for required in definition.requires: prerequisites.append(Catalog.technology(required).name)
			var condition := "COMPLETE" if done else ("ACTIVE" if definition.id == active else ("BEGIN PROJECT" if available else ("Finish the drafting lesson" if prerequisites.is_empty() else "Needs: " + ", ".join(prerequisites))))
			research_buttons[definition.id].text = "%s\n%s  •  %d/%d dossiers\n%s\n%s" % [definition.name, condition, progress, definition.cost, definition.purpose, definition.unlock]
			research_buttons[definition.id].disabled = done or not available or definition.id == active
			Style.select(research_buttons[definition.id], definition.id == active and not done)
			research_buttons[definition.id].tooltip_text = "Finish the introductory drafting lesson to select a project." if not world.content_available("lab") else definition.unlock
	elif tab == "production":
		power_status.text = world.power.summary(world)
		var stats: Dictionary = world.metrics.snapshot(world.ticks)
		window_label.text = "Actual output and recipe / fuel / delivery use. Recent %.1f simulated seconds; history starts on load." % stats.seconds
		if stats.made.is_empty() and stats.used.is_empty(): window_label.text += " No activity recorded yet."
		for item in production_labels:
			var labels: Array = production_labels[item]
			var made := int(stats.made.get(item, 0))
			var used := int(stats.used.get(item, 0))
			for label in labels: label.visible = made > 0 or used > 0
			labels[0].text = Catalog.item_name(item)
			labels[1].text = "%.1f" % (made * 60.0 / stats.seconds)
			labels[2].text = "%.1f" % (used * 60.0 / stats.seconds)
			labels[3].text = "%+.1f" % ((made - used) * 60.0 / stats.seconds)
			labels[3].add_theme_color_override("font_color", Style.ERROR if used > made else Style.ACCENT)
		var counts: Dictionary = {}
		var stalled := Diagnostics.stalled(world)
		for record in stalled:
			counts[record.reason] = int(counts.get(record.reason, 0)) + 1
		locate_button.disabled = stalled.is_empty()
		locate_button.text = "Locate nearest stalled machine" if stalled.is_empty() else "Locate %s / %s (%d tiles)" % [Catalog.item_name(stalled[0].kind), stalled[0].reason, ceili(sqrt(float(stalled[0].distance)))]
		var parts := PackedStringArray()
		for reason in counts:
			if parts.size() == 4: break
			parts.append("%d × %s" % [counts[reason], reason])
		diagnostics.text = "CHECK THESE FIRST\n" + ("No stalled production machines." if parts.is_empty() else "  •  ".join(parts))
		demand.text = "TOWN DEMAND\n"
		for id in world.settlements.sites:
			var site = world.settlements.sites[id]
			var definition: Dictionary = world.settlements.Definitions.SITES[id]
			if site.repaired and definition.has("contract"):
				var contract: Dictionary = world.settlements.Definitions.CONTRACTS[definition.contract]
				demand.text += "%s: %s\n" % [definition.name, ("Housing complete" if id == "town_hall" and world.settlements.district_level() >= 3 else "%s per %.0fs" % [Catalog.describe(contract.goods), contract.ticks / 10.0])]
	else:
		undo_button.disabled = world.plans.undo_stack.is_empty()
		redo_button.disabled = world.plans.redo_stack.is_empty()
		var report: Dictionary = world.plans.supply_report(world, nearby_plans.button_pressed)
		plan_status.text = "%d planned buildings / %d in clipboard\n%d ready nearby / %d out of reach / %d blocked" % [world.plans.ghosts.size(), world.plans.clipboard.size(), report.ready, report.distant, report.blocked]
		for kind in plan_rows:
			var controls: Dictionary = plan_rows[kind]
			var row: Dictionary = report.rows.get(kind, {})
			for label in controls.labels: label.visible = not row.is_empty()
			controls.button.visible = not row.is_empty()
			if row.is_empty(): continue
			var values := [Catalog.item_name(kind), str(row.needed), str(row.pack), str(row.queued), str(row.missing)]
			for i in range(values.size()): controls.labels[i].text = values[i]
			controls.labels[4].add_theme_color_override("font_color", Style.ERROR if row.missing > 0 else Style.ACCENT)
			controls.button.text = "Craft %d batches" % row.craft_batches if row.craft_batches > 0 else ("Covered" if row.missing == 0 else "Need ingredients")
			controls.button.disabled = row.craft_batches <= 0

func _locate_stalled() -> void:
	var stalled := Diagnostics.stalled(world)
	if stalled.is_empty(): return
	var record: Dictionary = stalled[0]
	var title := ("Check: " + Catalog.item_name(record.kind)).left(40)
	var pin_id := 0
	for id in world.navigation.pins:
		if world.navigation.pins[id].cell == record.cell and world.navigation.pins[id].title == title: pin_id = id
	if pin_id == 0: pin_id = world.navigation.add(record.cell, title)
	if pin_id == 0:
		world.message.emit("Map pin limit reached. Remove an old pin in M to track this machine.")
		return
	world.navigation.track(pin_id)
	world.message.emit("Follow the purple compass: %s at (%d, %d) / %s. M manages pins." % [Catalog.item_name(record.kind), record.cell.x, record.cell.y, record.reason])
	world.changed.emit()
	close_panel()
