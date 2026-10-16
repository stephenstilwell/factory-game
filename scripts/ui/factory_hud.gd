extends CanvasLayer
## Compact field HUD plus a focused, shared inventory workspace.

const Catalog = preload("res://scripts/data/catalog.gd")
const Style = preload("res://scripts/ui/ui_style.gd")
const Workspace = preload("res://scripts/ui/inventory_workspace.gd")
const Survey = preload("res://scripts/ui/resource_survey.gd")
const SkillDefinitions = preload("res://scripts/data/skill_catalog.gd")

signal build_selected(kind: String)
signal upgrade_requested(id: String, rank: int)
signal beacon_requested
signal beacon_cancel_requested
signal structure_repair_requested
signal building_pickup_requested
signal save_requested
signal load_requested
signal pause_requested
signal menu_close_requested
signal survey_target_selected(data: Dictionary)
signal fullscreen_requested
signal supply_requested
signal collect_requested
signal recipe_requested
signal recipe_selected(id: String)
signal craft_requested(id: String, count: int)
signal craft_cancel_requested
signal job_cancel_requested(id: int)
signal cancel_all_requested
signal transfer_requested(item: String, amount: int, source: Dictionary, target: Dictionary, token: int)
signal site_selected(id: String)
signal site_supply_requested(id: String)
signal site_restore_requested(id: String)
signal site_withdraw_requested(id: String)

var world: RefCounted
var top: PanelContainer
var bottom: PanelContainer
var status: Label
var objective: Label
var lesson_hint: Label
var research: Label
var defense_status: Label
var hover_label: Label
var inventory_label: Label
var xp_label: Label
var xp_time := 0.0
var notice_label: Label
var pause_button: Button
var fullscreen_button: Button
var tool_buttons: Dictionary = {}
var workspace: PanelContainer
var backdrop: ColorRect
var pause_menu: ColorRect
var survey: ColorRect
var crafting: VBoxContainer
var craft_buttons: Dictionary = {}
var inspector: VBoxContainer
var inspector_text: Label
var town_panel: VBoxContainer
var inspected = null
var site_id := ""
var town_open := false
var crafting_open := false
var selection := ""
var notice := "Mine nearby stone to begin. E opens crafting; M surveys resources; T shows town projects."
var notice_time := 12.0
var refresh_time := 0.0

func _ready() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = Style.theme()
	add_child(root)
	top = PanelContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = 132
	root.add_child(top)
	var box := VBoxContainer.new()
	top.add_child(box)
	var row := HBoxContainer.new()
	box.add_child(row)
	var title := Style.label("IRONWORKS / OLDBRIDGE", 20, Style.ACCENT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)
	Style.button(row, "Pack [E]", toggle_inventory)
	Style.button(row, "Craft [C]", toggle_crafting)
	Style.button(row, "Town [T]", toggle_town)
	Style.button(row, "Survey [M]", toggle_survey)
	pause_button = Style.button(row, "Pause", func(): pause_requested.emit())
	pause_button.tooltip_text = "Pause key: pause or resume. Escape opens the pause menu."
	Style.button(row, "Save", func(): save_requested.emit())
	Style.button(row, "Load", func(): load_requested.emit())
	fullscreen_button = Style.button(row, "Window [F11]", func(): fullscreen_requested.emit())
	status = Style.label("", 14, Style.MUTED)
	box.add_child(status)
	objective = Style.label("", 16, Style.GOLD)
	box.add_child(objective)
	lesson_hint = Style.label("", 14)
	box.add_child(lesson_hint)
	research = Style.label("", 14, Style.GOLD)
	box.add_child(research)
	defense_status = Style.label("", 14, Style.GOLD)
	box.add_child(defense_status)
	bottom = PanelContainer.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -122
	root.add_child(bottom)
	var bottom_box := VBoxContainer.new()
	bottom.add_child(bottom_box)
	var info := HBoxContainer.new()
	bottom_box.add_child(info)
	hover_label = Style.label("", 13, Style.MUTED)
	hover_label.max_lines_visible = 1
	hover_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(hover_label)
	xp_label = Style.label("", 13, Style.ACCENT)
	xp_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	info.add_child(xp_label)
	inventory_label = Style.label("PACK [E]", 13, Style.ACCENT)
	inventory_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	info.add_child(inventory_label)
	var tools := HBoxContainer.new()
	tools.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_box.add_child(tools)
	for i in range(Catalog.BUILD_ORDER.size()):
		var id: String = Catalog.BUILD_ORDER[i]
		var button := Style.button(tools, "", func(): build_selected.emit(id))
		button.custom_minimum_size = Vector2(126, 44)
		button.add_theme_font_size_override("font_size", 14)
		tool_buttons[id] = button
	notice_label = Style.label("", 13, Style.GOLD)
	notice_label.max_lines_visible = 1
	bottom_box.add_child(notice_label)
	backdrop = ColorRect.new()
	backdrop.color = Color(0.025, 0.045, 0.055, 0.76)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT: close_workspace())
	root.add_child(backdrop)
	workspace = Workspace.new()
	workspace.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	workspace.offset_left = 24
	workspace.offset_top = 80
	workspace.offset_right = -24
	workspace.offset_bottom = -104
	root.add_child(workspace)
	workspace.close_requested.connect(close_workspace)
	workspace.upgrade_requested.connect(func(id, rank): upgrade_requested.emit(id, rank))
	workspace.beacon_requested.connect(func(): beacon_requested.emit())
	workspace.beacon_cancel_requested.connect(func(): beacon_cancel_requested.emit())
	workspace.structure_repair_requested.connect(func(): structure_repair_requested.emit())
	workspace.building_pickup_requested.connect(func(): building_pickup_requested.emit())
	workspace.context_changed.connect(_sync_context)
	workspace.build_requested.connect(func(id): build_selected.emit(id))
	workspace.transfer_requested.connect(func(item, amount, from, to, token): transfer_requested.emit(item, amount, from, to, token))
	workspace.craft_requested.connect(func(id, count): craft_requested.emit(id, count))
	workspace.cancel_requested.connect(func(id): job_cancel_requested.emit(id))
	workspace.cancel_all_requested.connect(func(): cancel_all_requested.emit())
	workspace.recipe_requested.connect(func(id): recipe_selected.emit(id))
	workspace.supply_requested.connect(func(): supply_requested.emit())
	workspace.collect_requested.connect(func(): collect_requested.emit())
	workspace.site_selected.connect(func(id): site_selected.emit(id))
	workspace.site_supply_requested.connect(func(id): site_supply_requested.emit(id))
	workspace.site_restore_requested.connect(func(id): site_restore_requested.emit(id))
	workspace.site_withdraw_requested.connect(func(id): site_withdraw_requested.emit(id))
	crafting = workspace.crafting
	craft_buttons = crafting.recipe_buttons
	inspector = workspace.machine
	inspector_text = inspector.status_label
	town_panel = workspace.town
	close_workspace()
	pause_menu = ColorRect.new()
	pause_menu.color = Color(0.025, 0.045, 0.055, 0.92)
	pause_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(pause_menu)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_menu.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 560
	center.add_child(panel)
	var menu := VBoxContainer.new()
	menu.add_theme_constant_override("separation", 16)
	panel.add_child(menu)
	menu.add_child(Style.label("PAUSED", 26, Style.ACCENT))
	menu.add_child(Style.label("WASD — Move\nE — Inventory & crafting / close interface\nLeft click — Build / open machine\nHold right mouse — Mine / reclaim building\nQ — Clear build cursor / pick hovered building\nR / Shift+R — Rotate clockwise / counterclockwise\nCtrl+left click — Quick-load hovered machine\nShift+click item — Transfer all that fits\nEscape — Close interface / clear cursor / pause menu\nH — Repair hovered structure with a kit\nP — Engineer upgrades\nPause key — Pause or resume • F11 — Fullscreen", 16))
	Style.button(menu, "Resume [Esc]", func(): menu_close_requested.emit())
	Style.button(menu, "Save game", func(): save_requested.emit())
	Style.button(menu, "Load game", func(): load_requested.emit())
	pause_menu.hide()
	survey = Survey.new()
	root.add_child(survey)
	survey.close_requested.connect(func(): survey.hide())
	survey.target_selected.connect(func(data):
		survey_target_selected.emit(data)
		survey.hide())

func _process(delta: float) -> void:
	xp_time = maxf(0.0, xp_time - delta)
	xp_label.visible = xp_time > 0.0
	notice_time = maxf(0, notice_time - delta)
	refresh_time += delta
	if refresh_time >= 0.15:
		refresh_time = 0
		refresh()

func show_notice(text: String) -> void:
	notice = text
	notice_time = 7
	refresh()

func show_skill_xp(id: String, amount: int, level: int, leveled: bool) -> void:
	xp_time = 4.0
	xp_label.text = "+%d %s XP%s" % [amount, SkillDefinitions.SKILLS[id].name, " • Level %d!" % level if leveled else ""]
	xp_label.show()

func close_workspace() -> void:
	workspace.hide()
	backdrop.hide()
	var focused := get_viewport().gui_get_focus_owner()
	if focused != null: focused.release_focus()
	_sync_context()

func _open(mode: String) -> void:
	workspace.world = world
	backdrop.show()
	workspace.open_mode(mode)

func toggle_inventory() -> void:
	if workspace.visible and workspace.mode == "inventory": close_workspace()
	else: _open("inventory")

func toggle_crafting() -> void:
	if workspace.visible and workspace.mode == "crafting": close_workspace()
	else: _open("crafting")

func toggle_town() -> void:
	if workspace.visible and workspace.mode == "town" and workspace.site_id == "": close_workspace()
	else:
		workspace.site_id = ""
		_open("town")

func inspect_site(id: String) -> void:
	workspace.site_id = id
	_open("town")

func inspect(entity) -> void:
	workspace.entity_id = entity.id if entity != null else -1
	if entity != null: _open("machine")
	else: close_workspace()

func _sync_context() -> void:
	if world == null: return
	crafting_open = workspace.visible and workspace.mode == "crafting"
	town_open = workspace.visible and workspace.mode == "town"
	site_id = workspace.site_id if town_open else ""
	inspected = world.entities.get(workspace.entity_id) if workspace.visible and workspace.mode == "machine" else null
	refresh()

func refresh() -> void:
	if world == null or status == null: return
	defense_status.visible = world.settlements.enabled and world.settlements.sites.town_hall.repaired
	defense_status.text = "TOWN HALL %d/%d • %s [T]" % [world.settlements.sites.town_hall.health, world.settlements.sites.town_hall.max_health(), world.defense.summary()]
	objective.visible = world.guide.enabled
	lesson_hint.visible = world.guide.enabled and not world.guide.current().is_empty()
	if world.guide.enabled:
		objective.text = world.guide.objective_text() if not world.guide.current().is_empty() else world.settlements.objective_text()
		lesson_hint.text = world.guide.current().get("hint", "")
	research.visible = not world.guide.enabled or world.content_available("lab")
	status.text = "Credits %d  |  %d machines  |  Pack %d / %d  |  WASD move • Hold RMB mine • E inventory • Esc menu" % [world.settlements.credits, world.entities.size(), world.player.total(), world.player.capacity]
	if world.settlements.effect("burner_ticks") > 0: status.text += "  |  Fuel +20%"
	if world.researched.size() < Catalog.TECHNOLOGIES.size():
		var tech: Dictionary = Catalog.TECHNOLOGIES[world.researched.size()]
		research.text = "RESEARCH  %s  %d / %d science packs  •  %s" % [tech.name, world.research_progress, tech.cost, tech.unlock]
	else: research.text = "RESEARCH COMPLETE  •  Logistics I + Metallurgy"
	for i in range(Catalog.BUILD_ORDER.size()):
		var id: String = Catalog.BUILD_ORDER[i]
		var short_name: String = Catalog.item_name(id).replace("Conveyor", "Belt").replace("conveyor", "belt").replace("Burner ", "").replace("Stone ", "").replace("Storage ", "").replace("Research ", "").capitalize()
		tool_buttons[id].text = "%d %s  ·  %d" % [i + 1, short_name, world.player.count(id)]
		tool_buttons[id].visible = world.content_available(id)
		tool_buttons[id].disabled = not world.unlocked(Catalog.BUILDINGS[id])
		tool_buttons[id].modulate = Style.ACCENT if selection == id else Color.WHITE
	inventory_label.text = "PACK %d  [E]" % world.player.total()
	notice_label.text = notice if notice_time > 0 else "E inventory • Hold RMB mine • Q clear/pick • Ctrl-click load • Esc menu"
	notice_label.tooltip_text = notice_label.text
	if workspace.visible:
		workspace.refresh(world)
		inspected = world.entities.get(workspace.entity_id) if workspace.mode == "machine" else null
		site_id = workspace.site_id if workspace.mode == "town" else ""

func world_has_pointer() -> bool:
	if workspace.visible or pause_menu.visible or survey.visible: return false
	var pointer := get_viewport().get_mouse_position()
	return not top.get_global_rect().has_point(pointer) and not bottom.get_global_rect().has_point(pointer)

func toggle_survey() -> void:
	if survey.visible: survey.hide()
	else:
		close_workspace()
		survey.open(world)

func toggle_character() -> void:
	if workspace.visible and workspace.mode == "character": close_workspace()
	else: _open("character")
