extends ColorRect
const Catalog = preload("res://scripts/data/catalog.gd")
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
var plan_status: Label
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
	var title := Style.label("FACTORY WORKBENCH", 23, Style.ACCENT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	Style.button(header, "Close [Esc / F]", close_panel)
	var controls := HBoxContainer.new()
	box.add_child(controls)
	for id in ["research", "production", "plans"]:
		tabs[id] = Style.button(controls, id.capitalize(), func(): tab = id; refresh())
		var section := VBoxContainer.new()
		section.add_theme_constant_override("separation", 10)
		box.add_child(section)
		sections[id] = section
	research_status = Style.label("", 16, Style.GOLD)
	sections.research.add_child(research_status)
	for definition in Catalog.TECHNOLOGIES:
		var button := Style.button(sections.research, "", func(): research_requested.emit(definition.id))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		research_buttons[definition.id] = button
	sections.research.add_child(Style.label("Labs spend real science packs. Choose either routing or metallurgy after Logistics I. Switching projects preserves invested science.", 15, Style.MUTED))
	window_label = Style.label("", 14, Style.MUTED)
	sections.production.add_child(window_label)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(740, 210)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sections.production.add_child(scroll)
	production_rows = GridContainer.new()
	production_rows.columns = 4
	production_rows.add_theme_constant_override("h_separation", 25)
	scroll.add_child(production_rows)
	for label in ["ITEM", "MADE / MIN", "USED / MIN", "NET / MIN"]:
		production_rows.add_child(Style.label(label, 13, Style.ACCENT))
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
	demand = Style.label("", 14, Style.MUTED)
	demand.max_lines_visible = 4
	sections.production.add_child(demand)
	plan_status = Style.label("", 16, Style.GOLD)
	sections.plans.add_child(plan_status)
	sections.plans.add_child(Style.label("Ctrl+C: drag a rectangle around a factory module.\nCtrl+V: stamp its ghosts; R rotates the module.\nShift+click while building: place a single ghost.\nB: build reachable ghosts using buildings in your pack.\nRight-click a ghost: remove it. Esc / Q: leave planning.\n\nPlans copy direction, recipe, and tunnel mode. They never copy items, fuel, health, or production.", 16))
	var actions := HBoxContainer.new()
	sections.plans.add_child(actions)
	Style.button(actions, "Copy area", func(): close_panel(); copy_requested.emit())
	Style.button(actions, "Stamp clipboard", func(): close_panel(); paste_requested.emit())
	Style.button(actions, "Build nearby [B]", func(): build_requested.emit(); refresh())
	Style.button(actions, "Clear ghosts", func(): clear_requested.emit(); refresh())
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
		var active: String = world.current_research()
		research_status.text = "Choose a research project" if active.is_empty() else "ACTIVE: %s  •  %d / %d science" % [Catalog.technology(active).name, world.research_progress, Catalog.technology(active).cost]
		for definition in Catalog.TECHNOLOGIES:
			var done: bool = definition.id in world.researched
			var available: bool = world.research_available(definition.id) and world.content_available("lab")
			var progress: int = world.research_progress if definition.id == active else int(world.research_banks.get(definition.id, 0))
			if done: progress = int(definition.cost)
			var condition := "Complete" if done else ("Active" if definition.id == active else ("Select" if available else "Needs: " + ", ".join(definition.requires)))
			research_buttons[definition.id].text = "%s  •  %s  •  %d/%d science\n%s" % [definition.name, condition, progress, definition.cost, definition.unlock]
			research_buttons[definition.id].disabled = done or not available or definition.id == active
			Style.select(research_buttons[definition.id], definition.id == active and not done)
			research_buttons[definition.id].tooltip_text = "Finish the introductory lab lesson to select research." if not world.content_available("lab") else definition.unlock
	elif tab == "production":
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
		for kind in ["drill", "furnace", "assembler", "lab", "underground_belt"]:
			for id in world.by_kind[kind]:
				var entity = world.entities[id]
				if entity.status in ["Working", "Transporting"] or entity.status.begins_with("Mining ") or entity.status.begins_with("Researching"): continue
				var reason: String = entity.status
				counts[reason] = int(counts.get(reason, 0)) + 1
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
		var wanted: Dictionary = {}
		for ghost in world.plans.ghosts.values(): wanted[ghost.kind] = int(wanted.get(ghost.kind, 0)) + 1
		plan_status.text = "%d planned buildings • %d in clipboard\nNeeded: %s" % [world.plans.ghosts.size(), world.plans.clipboard.size(), Catalog.describe(wanted)]
