extends ColorRect
const Style = preload("res://scripts/ui/ui_style.gd")
const Definitions = preload("res://scripts/data/frontier_catalog.gd")
signal close_requested
var world: RefCounted
var selected := ""
var site_buttons: Dictionary = {}
var title: Label
var description: Label
var reward: Label
var state_label: Label
var claim_button: Button
var track_button: Button
var orchard_box: VBoxContainer
var orchard_text: Label
var bed_button: Button
var orchard_supply: Button
var orchard_collect: Button
var orchard_withdraw: Button
var road_box: VBoxContainer
var road_text: Label
var road_deliver: Button
var road_withdraw: Button
var marsh_box: VBoxContainer
var marsh_text: Label
var marsh_build: Button
var marsh_remove: Button
var marsh_restore: Button
var marsh_supply: Button
var marsh_collect: Button
var marsh_withdraw: Button
var puzzle: VBoxContainer
var cells: Dictionary = {}
var result_label: Label
var timer := 0.0
var leads_hint: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color = Color(0.02, 0.04, 0.045, 0.86)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(920, 600)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var header := HBoxContainer.new()
	box.add_child(header)
	var heading := Style.label("BEYOND OLDBRIDGE • DISCOVERIES", 22, Style.ACCENT)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	Style.button(header, "Close [Esc / L]", func(): close_requested.emit())
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 18)
	box.add_child(body)
	var list := VBoxContainer.new()
	list.custom_minimum_size.x = 230
	body.add_child(list)
	list.add_child(Style.label("PLACES & LEADS", 14, Style.GOLD))
	for id in Definitions.SITES:
		var button := Style.button(list, Definitions.SITES[id].name, func(): selected = id; refresh())
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		site_buttons[id] = button
	leads_hint = Style.label("", 13, Style.MUTED)
	list.add_child(leads_hint)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(630,465)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_RESERVE
	body.add_child(scroll)
	var detail := VBoxContainer.new()
	detail.custom_minimum_size.x = 595
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_theme_constant_override("separation", 8)
	scroll.add_child(detail)
	title = Style.label("", 22, Style.ACCENT)
	detail.add_child(title)
	state_label = Style.label("", 14, Style.GOLD)
	detail.add_child(state_label)
	description = Style.label("", 15)
	detail.add_child(description)
	reward = Style.label("", 14, Style.GOLD)
	detail.add_child(reward)
	var actions := HBoxContainer.new()
	detail.add_child(actions)
	track_button = Style.button(actions, "Track lead", func():
		world.frontier.target = "" if world.frontier.target == selected else selected
		if not world.frontier.target.is_empty(): world.navigation.track(0)
		world.changed.emit()
		refresh())
	claim_button = Style.button(actions, "Recover discovery", func(): world.frontier.claim(world, selected); refresh())
	orchard_box = VBoxContainer.new()
	detail.add_child(orchard_box)
	orchard_text = Style.label("", 15)
	orchard_box.add_child(orchard_text)
	bed_button = Style.button(orchard_box, "Restore growing bed", func(): world.orchard_project.restore_bed(world); refresh())
	var orchard_actions := HBoxContainer.new()
	orchard_box.add_child(orchard_actions)
	orchard_supply = Style.button(orchard_actions, "Supply growing beds", func(): world.orchard_project.supply(world); refresh())
	orchard_collect = Style.button(orchard_actions, "Collect produce", func(): world.orchard_project.collect(world); refresh())
	orchard_withdraw = Style.button(orchard_actions, "Withdraw inputs", func(): world.orchard_project.withdraw(world); refresh())
	road_box = VBoxContainer.new()
	detail.add_child(road_box)
	road_text = Style.label("", 15)
	road_box.add_child(road_text)
	var road_actions := HBoxContainer.new()
	road_box.add_child(road_actions)
	road_deliver = Style.button(road_actions, "Deliver up to one load", func(): world.quarry_project.deliver(world); refresh())
	road_withdraw = Style.button(road_actions, "Withdraw buffer", func(): world.quarry_project.withdraw(world); refresh())
	marsh_box = VBoxContainer.new()
	detail.add_child(marsh_box)
	marsh_text = Style.label("",14)
	marsh_box.add_child(marsh_text)
	var crossing_actions := HBoxContainer.new()
	marsh_box.add_child(crossing_actions)
	marsh_build = Style.button(crossing_actions,"Build next span",func(): world.frontier.marsh.build_span(world); refresh())
	marsh_remove = Style.button(crossing_actions,"Reclaim last span",func(): world.frontier.marsh.remove_span(world); refresh())
	marsh_restore = Style.button(marsh_box,"Restore maintenance lodge",func(): world.frontier.marsh.restore_lodge(world); refresh())
	var service_actions := HBoxContainer.new()
	marsh_box.add_child(service_actions)
	marsh_supply = Style.button(service_actions,"Supply one batch",func(): world.frontier.marsh.supply(world); refresh())
	marsh_collect = Style.button(service_actions,"Collect kits",func(): world.frontier.marsh.collect(world); refresh())
	marsh_withdraw = Style.button(service_actions,"Withdraw inputs",func(): world.frontier.marsh.collect(world,true); refresh())
	puzzle = VBoxContainer.new()
	puzzle.add_theme_constant_override("separation", 6)
	detail.add_child(puzzle)
	puzzle.add_child(Style.label("LOANED SORTING TABLE • no pack items used\nLeft-click places / rotates a conveyor. Right-click removes. Route A and B to their matching docks around the wall.", 13, Style.MUTED))
	var grid := GridContainer.new()
	grid.columns = 7
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	puzzle.add_child(grid)
	for y in range(5):
		for x in range(7):
			var cell := Vector2i(x, y)
			var button := Style.button(grid, "", func(): world.frontier.edit_belt(world, cell); refresh())
			button.custom_minimum_size = Vector2(63, 32)
			for state in ["normal", "hover", "pressed", "disabled", "focus"]:
				var tile_style := Style.panel(Color("293e40"), Color("688278"))
				tile_style.set_content_margin_all(4)
				button.add_theme_stylebox_override(state, tile_style)
			button.add_theme_font_size_override("font_size", 15)
			button.gui_input.connect(func(event):
				if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
					world.frontier.edit_belt(world, cell, true)
					refresh()
					button.accept_event())
			cells[cell] = button
	result_label = Style.label("", 13, Style.GOLD)
	puzzle.add_child(result_label)
	var table_actions := HBoxContainer.new()
	puzzle.add_child(table_actions)
	Style.button(table_actions, "Test cargo routes", _test_routes)
	Style.button(table_actions, "Clear table", func():
		world.frontier.reset_table(world)
		refresh())
	hide()

func open_panel(state: RefCounted, id: String = "") -> void:
	world = state
	if world.frontier.sites.has(id): selected = id
	if not world.frontier.sites.has(selected):
		selected = "" if world.frontier.sites.is_empty() else world.frontier.sites.keys()[0]
	refresh()
	show()

func _process(delta: float) -> void:
	if not visible: return
	timer += delta
	if timer >= 0.5:
		timer = 0
		refresh()

func _test_routes() -> void:
	if world == null or selected != "depot": return
	var reason: String = world.frontier.interaction_reason(world, "depot")
	if not reason.is_empty():
		result_label.text = reason
		return
	result_label.text = world.frontier.evaluate().message
	if world.frontier.evaluate().success: world.feedback_requested.emit("success", world.frontier.port("depot"))

func refresh() -> void:
	if world == null: return
	leads_hint.text = "Walk to the marked entrance to investigate; tracking does not teleport.\n\n" + ("Greybank supports rebuilding the crossing. Other discoveries are optional. Beacon defenses remain your choice." if world.early.enabled else "The factory keeps running. Exploration is optional; beacon defenses remain your choice.")
	for id in site_buttons:
		var exists: bool = world.frontier.sites.has(id)
		var found: bool = exists and world.frontier.sites[id].discovered
		site_buttons[id].disabled = not exists
		site_buttons[id].text = Definitions.SITES[id].name + ("\nRECOVERED" if world.frontier.claimed(id) else ("\nDISCOVERED" if found else "\nRUMOR"))
		if id == "orchard" and world.frontier.claimed(id): site_buttons[id].text += "\nGrowing beds %d / 3" % world.orchard_project.beds
		if id == "quarry" and world.frontier.claimed(id): site_buttons[id].text += "\nRoad %d / 9 loads" % world.settlements.road_deliveries
		if id == "marsh" and exists: site_buttons[id].text += "\n" + ("Service online" if world.frontier.marsh.restored else "Causeway %d / 4" % world.frontier.marsh.sections)
		Style.select(site_buttons[id], id == selected)
	road_box.hide()
	orchard_box.hide()
	marsh_box.hide()
	if selected.is_empty():
		title.text = "No leads in this world yet."
		puzzle.hide()
		claim_button.hide()
		track_button.hide()
		return
	var definition: Dictionary = Definitions.SITES[selected]
	var record: Dictionary = world.frontier.sites[selected]
	var reason: String = world.frontier.interaction_reason(world, selected)
	title.text = definition.name
	if definition.has("biome"): state_label.tooltip_text = definition.biome
	else: state_label.tooltip_text = ""
	var distance: int = ceili(world.player_position.distance_to(Vector2(world.frontier.port(selected)) + Vector2.ONE * 0.5))
	state_label.text = ("RECOVERED" if record.claimed else ("DISCOVERED" if record.discovered else "RUMOR")) + " • %d tiles away" % distance
	if definition.has("biome"): state_label.text += "\n" + definition.biome
	description.text = definition.story if record.discovered else definition.hint
	description.visible = selected != "depot" or not record.discovered
	reward.text = "REWARD\n" + definition.reward
	track_button.show()
	track_button.text = "Stop tracking" if world.frontier.target == selected else ("Track west bank" if selected == "marsh" and world.frontier.marsh.sections < 4 else "Track entrance")
	claim_button.show()
	claim_button.disabled = record.claimed or not reason.is_empty() or (selected == "depot" and not world.frontier.evaluate().success)
	claim_button.text = "Recovered" if record.claimed else ("Restore depot" if selected == "depot" else "Recover discovery")
	claim_button.tooltip_text = reason if not reason.is_empty() else "Rewards are granted once. Salvage requires enough pack space for the whole bundle."
	road_box.visible = selected == "quarry" and record.claimed
	if road_box.visible:
		description.hide()
		reward.hide()
		var project: RefCounted = world.quarry_project
		var delivered: int = world.settlements.road_deliveries
		var port: Vector2i = world.frontier.port("quarry")
		road_text.text = "GREYBANK ROAD / %d of 9 loads / %d of 3 sections\n20 stone + 4 planks per 60-second load: +12 credits.\nEvery 3 loads: visible road, +15%% walking speed on restored sections, +300 Fabrication XP.\nBUFFER: %d stone / %d planks\n%s\nHATCH (%d, %d): inserter (%d, %d) facing EAST; pickup (%d, %d)." % [delivered, delivered / 3, project.inventory.count("stone"), project.inventory.count("plank"), "Road complete! All sections are open." if delivered == 9 else ("Load in transit: %.1fs remaining." % (project.shipment_ticks / 10.0) if project.shipment_ticks > 0 else "Waiting for a complete load."), port.x, port.y, port.x - 1, port.y, port.x - 2, port.y]
		if not project.available(world): road_text.text += "\nRebuild the crossing and reopen healthy market/town services to dispatch."
		var can_deliver := false
		for item in project.GOODS:
			if world.player.count(item) > 0 and project.receiving_limit(world, item) > 0: can_deliver = true
		road_deliver.disabled = not can_deliver or not world.in_reach(port)
		road_withdraw.disabled = project.inventory.total() == 0 or not world.in_reach(port) or not world.player.can_exchange({}, project.inventory.contents)
	else:
		reward.show()
	orchard_box.visible = selected == "orchard" and record.claimed
	if orchard_box.visible:
		description.hide()
		reward.hide()
		var garden: RefCounted = world.orchard_project
		var port: Vector2i = world.frontier.port("orchard")
		var close: bool = world.in_reach(port)
		orchard_text.text = "IONA'S GROWING BEDS / %d of 3 restored\nPer bed: 1 charcoal/coal + 1 plank -> 4 fresh produce per 45s.\nTrade at market: 4 produce -> 6 credits per 30s.\nINPUTS %d fuel / %d planks / HARVEST %d of 24\n%s\nHATCH (%d,%d): input inserter west, facing EAST.\nOutput inserter north, facing NORTH; pickup is the hatch." % [garden.beds, garden.inventory.count("coal"), garden.inventory.count("plank"), garden.output.count("foraged_food"), "Growing: %.1fs" % (garden.growth_ticks / 10.0) if garden.growth_ticks > 0 else ("Harvest storage full." if garden.output.total() == 24 else "Waiting for growing supplies."), port.x, port.y]
		var bed_reason: String = garden.restore_bed_reason(world)
		bed_button.text = "Restore bed %d: 10 stone + 8 planks + 15 credits (+250 Gathering XP)" % (garden.beds + 1) if garden.beds < 3 else "All three growing beds restored"
		bed_button.disabled = not bed_reason.is_empty()
		bed_button.tooltip_text = bed_reason
		if not bed_reason.is_empty() and garden.beds < 3: orchard_text.text += "\n" + bed_reason
		orchard_supply.disabled = not close or not garden.available(world) or garden.beds == 0 or not ((world.player.count("coal") > 0 and garden.receiving_limit(world, "coal") > 0) or (world.player.count("plank") > 0 and garden.receiving_limit(world, "plank") > 0))
		orchard_collect.disabled = not close or garden.output.total() == 0 or world.player.total() >= world.player.capacity
		orchard_withdraw.disabled = not close or garden.inventory.total() == 0 or not world.player.can_exchange({}, garden.inventory.contents)
	marsh_box.visible = selected == "marsh"
	if marsh_box.visible:
		description.hide()
		reward.hide()
		var marsh: RefCounted = world.frontier.marsh
		var bank: Vector2i = marsh.shore(world.frontier)
		var hatch: Vector2i = world.frontier.port("marsh")
		var close: bool = world.in_reach(hatch)
		if marsh.restored:
			marsh_text.text = "MAINTENANCE SERVICE ONLINE\nRepair kits restore 25%% more health (%d HP with your current rig).\n4 iron plates + 2 copper plates + 2 planks → 3 kits / 60s.\nBUFFER %d iron / %d copper / %d planks | KITS %d / 12\n%s\nHATCH (%d,%d): input SOUTH, facing NORTH; output NORTH, facing NORTH.\nBelts can cross the causeway; solid buildings belong on land." % [world.repair_power(),marsh.inventory.count("iron_plate"),marsh.inventory.count("copper_plate"),marsh.inventory.count("plank"),marsh.output.total(),"Batch: %.1fs remaining" % (marsh.work_ticks/10.0) if marsh.work_ticks > 0 else "Waiting for supplies / output space.",hatch.x,hatch.y]
		else:
			marsh_text.text = "RECONNECT NESSA'S MAINTENANCE KEEPERS\nWEST bank (%d,%d). Walk across completed spans.\nCAUSEWAY %d / 4: 6 planks + 4 stone per span.\nReclaim the last span from its west side for a full refund before restoring the lodge.\nLODGE: 20 planks + 30 stone + 8 wire after recovering the ledger.\nREWARD: +25%% repair-kit healing, +400 Fabrication XP.\nWORKSHOP: 4 iron + 2 copper plates + 2 planks → 3 kits / 60s." % [bank.x,bank.y,marsh.sections]
		var build_reason: String = marsh.build_reason(world)
		marsh_build.visible = marsh.sections < 4
		marsh_remove.visible = not marsh.restored
		marsh_restore.visible = marsh.sections == 4 and not marsh.restored
		marsh_build.disabled = not build_reason.is_empty()
		marsh_build.tooltip_text = build_reason
		var remove_reason: String = marsh.remove_reason(world)
		marsh_remove.disabled = not remove_reason.is_empty()
		marsh_remove.tooltip_text = remove_reason
		var lodge_reason: String = marsh.restore_reason(world)
		marsh_restore.disabled = not lodge_reason.is_empty()
		marsh_restore.tooltip_text = lodge_reason
		marsh_restore.text = "Lodge restored · repair bonus active" if marsh.restored else "Restore lodge: 20 planks + 30 stone + 8 wire"
		if not marsh.restored: marsh_text.text += "\n" + (build_reason if marsh.sections < 4 else lodge_reason)
		marsh_text.tooltip_text = definition.story
		marsh_supply.visible = marsh.restored
		marsh_collect.visible = marsh.restored
		marsh_withdraw.visible = marsh.restored
		marsh_supply.disabled = not close or not marsh.INPUTS.keys().any(func(item): return world.player.count(item) > 0 and marsh.receiving_limit(world,item) > 0)
		marsh_collect.disabled = not close or marsh.output.total() == 0 or not world.player.can_exchange({},marsh.output.contents)
		marsh_withdraw.disabled = not close or marsh.inventory.total() == 0 or not world.player.can_exchange({},marsh.inventory.contents)
	puzzle.visible = selected == "depot" and record.discovered
	if not reason.is_empty(): state_label.text += "\n" + reason
	if not puzzle.visible: return
	for cell in cells:
		var button: Button = cells[cell]
		button.disabled = not world.frontier.editable(cell) or not reason.is_empty() or record.claimed
		button.text = ["→", "↓", "←", "↑"][world.frontier.board[cell]] if world.frontier.board.has(cell) else "·"
		button.tooltip_text = "Place / rotate conveyor • Right-click to remove"
		if cell in Definitions.BLOCKED: button.text = "WALL"
		if cell.x == 0: button.text = "A →" if cell.y == 1 else ("B →" if cell.y == 3 else "")
		if cell.x == 6: button.text = "A" if cell.y == 1 else ("B" if cell.y == 3 else "")
		button.add_theme_color_override("font_color", Style.GOLD if cell.y <= 1 else Style.ACCENT)
	result_label.text = "%d / %d loaned conveyors\n%s" % [world.frontier.board.size(), Definitions.MAX_BELTS, world.frontier.evaluate().message]
