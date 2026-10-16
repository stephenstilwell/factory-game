extends VBoxContainer
## Presentation and intent only; repair, reach, currency, and contracts are model rules.

const Definitions = preload("res://scripts/data/settlement_catalog.gd")
const Catalog = preload("res://scripts/data/catalog.gd")
const Grid = preload("res://scripts/ui/inventory_grid.gd")

signal site_selected(id: String)
signal supply_requested(id: String)
signal restore_requested(id: String)
signal talk_requested(id: String)
signal withdraw_requested(id: String)
signal transfer_requested(item: String, amount: int, source: Dictionary, target: Dictionary, token: int)
signal beacon_requested
signal beacon_cancel_requested
signal repair_requested

var selected_id := ""
var overview: VBoxContainer
var detail: VBoxContainer
var overview_text: Label
var project_buttons: Dictionary = {}
var talk_button: Button
var title: Label
var state_label: Label
var information: Label
var supply_button: Button
var restore_button: Button
var prerequisite_button: Button
var withdraw_button: Button
var supplies: VBoxContainer
var world: RefCounted
var quantity := 5
var defense_status: Label
var beacon_button: Button
var cancel_beacon_button: Button
var damage_button: Button
var supplies_title: Label

func _ready() -> void:
	overview = VBoxContainer.new()
	add_child(overview)
	overview.add_child(_label("OLDBRIDGE RESTORATION", 18, Color("91d2b4")))
	overview_text = _label("")
	overview.add_child(overview_text)
	for id in Definitions.SITES:
		project_buttons[id] = _button(overview, Definitions.SITES[id].name, func(): site_selected.emit(id))
	detail = VBoxContainer.new()
	add_child(detail)
	title = _label("", 19, Color("91d2b4"))
	detail.add_child(title)
	state_label = _label("", 14, Color("e4c58b"))
	detail.add_child(state_label)
	talk_button = _button(detail, "Talk", func(): talk_requested.emit(selected_id))
	defense_status = _label("", 15, Color("e4c58b"))
	detail.add_child(defense_status)
	beacon_button = _button(detail, "Light beacon", func(): beacon_requested.emit())
	cancel_beacon_button = _button(detail, "Extinguish beacon — cancel arrival", func(): beacon_cancel_requested.emit())
	damage_button = _button(detail, "Repair with kit [H] (+50 health)", func(): repair_requested.emit())
	prerequisite_button = _button(detail, "View required project", func(): site_selected.emit(Definitions.SITES[selected_id].requires))
	supply_button = _button(detail, "Deliver materials", func(): supply_requested.emit(selected_id))
	restore_button = _button(detail, "Restore", func(): restore_requested.emit(selected_id))
	withdraw_button = _button(detail, "Withdraw unused goods [X]", func(): withdraw_requested.emit(selected_id))
	supplies_title = _label("SUPPLIES  •  click to take; drag to deliver", 13, Color("a0b3b2"))
	detail.add_child(supplies_title)
	supplies = Grid.new()
	detail.add_child(supplies)
	supplies.item_activated.connect(_item_clicked)
	supplies.transfer_dropped.connect(func(data, target): transfer_requested.emit(data.item, int(data.amount), data.source, target, int(data.world)))
	information = _label("")
	detail.add_child(information)
	_button(detail, "All town projects [T]", func(): site_selected.emit(""))

func _label(text: String, size: int = 16, color: Color = Color("e0e8df")) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

func _button(parent: Node, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.clip_text = true
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _can_drop(data: Dictionary, target: Dictionary) -> bool:
	return data.get("type") == "inventory_item" and data.get("item") is String and data.get("source") is Dictionary and data.get("world") is int and data.get("amount") is int and data.amount >= 0 and world.transfer_limit(data.item, data.source, target, int(data.world)) > 0

func _item_clicked(item: String, gesture: String) -> void:
	var amount := 1 if gesture == "one" else (0 if gesture == "all" else quantity)
	var site = world.settlements.sites[selected_id]
	var descriptor := {"kind": "site", "site_id": selected_id}
	if site.inventory.count(item) > 0: transfer_requested.emit(item, amount, descriptor, {"kind": "player"}, world.get_instance_id())
	else: transfer_requested.emit(item, amount, {"kind": "player"}, descriptor, world.get_instance_id())

func refresh(state: RefCounted, id: String = "", amount: int = 5) -> void:
	world = state
	quantity = amount
	selected_id = id
	overview.visible = id.is_empty()
	detail.visible = not id.is_empty()
	var region = world.settlements
	if id.is_empty():
		overview_text.text = "Mira promised the families beyond the ridge a market, a working road, and somewhere dry to sleep. Your factory can make that promise real.\n\nTrade credits: %d\nLifetime earned: %d\n\n%s\n" % [region.credits, region.total_earned, region.objective_text()]
		if region.effect("burner_ticks") > 0: overview_text.text += "\nACTIVE REGIONAL BONUS\nBurner coal lasts 20% longer.\n"
		for project in project_buttons:
			var landmark = region.sites[project]
			project_buttons[project].text = "%s\n%s" % [Definitions.SITES[project].name, ("Disabled — repair [H]" if landmark.health == 0 else "Restored") if landmark.repaired else "Ruined"]
			project_buttons[project].disabled = not region.enabled
		return
	if not region.sites.has(id): return
	var site = region.sites[id]
	var definition: Dictionary = Definitions.SITES[id]
	supplies.visible = not site.repaired or definition.has("contract")
	supplies_title.visible = supplies.visible
	withdraw_button.visible = supplies.visible
	var expected: Array = definition.repair.keys()
	if site.repaired: expected = Definitions.CONTRACTS[definition.contract].goods.keys() if definition.has("contract") else []
	supplies.descriptor = {"kind": "site", "site_id": id}
	supplies.destination = supplies.descriptor
	supplies.world_token = world.get_instance_id()
	supplies.transfer_amount = quantity
	supplies.can_transfer = _can_drop
	supplies.refresh(site.inventory.contents, expected)
	var port: Vector2i = site.port()
	var reachable: bool = world.in_reach(port)
	title.text = definition.name.to_upper()
	var npc: Dictionary = world.story.Definitions.NPCS[id]
	var chapter: String = world.story.conversation(world, id)
	talk_button.text = "Talk to " + npc.name + ("  •  New story" if not world.story.seen.has(chapter) else "")
	talk_button.disabled = not reachable and not world.in_reach(world.story.npc_cell(world, id))
	talk_button.tooltip_text = npc.role + ". Walk close to the person or the delivery hatch to talk."
	state_label.text = region.status(id) + ("\nOut of reach - walk to the hatch." if not reachable else "")
	if site.repaired: state_label.text += "\nHealth: %d / %d" % [site.health, site.max_health()]
	if id == "town_hall" and site.repaired:
		state_label.text += "\nNEIGHBORHOODS %d / 3 • Housing deliveries %d / 3" % [region.district_level(), site.shipments % 3]
		state_label.text += "\nAll neighborhoods restored; housing deliveries complete." if region.district_level() >= 3 else "\nSupply construction kits, steel, and copper to grow the town. Shortages pause growth."
		if region.district_level() > 0: state_label.text += "\nRegional coal efficiency: +%d%% from neighborhoods." % (region.district_level() * 5)
	defense_status.visible = id == "town_hall" and site.repaired
	beacon_button.visible = defense_status.visible
	cancel_beacon_button.visible = defense_status.visible and world.defense.phase == "warning"
	damage_button.visible = site.repaired and site.health < site.max_health()
	damage_button.disabled = not reachable or world.player.count("repair_kit") == 0
	if defense_status.visible:
		defense_status.text = "%s\nEAST approach: %d scavengers, %d health each. Turrets need ammunition.\nFirst victory: returning road crews grant +5%% movement. No wave starts automatically." % [world.defense.summary(), world.defense.wave_size(), world.defense.enemy_health()]
		if world.defense.cleared == world.defense.MAX_WAVES: defense_status.text = "%s\n%d families sheltered. Road crews remain active while the hall is operational." % [world.defense.summary(), world.defense.cleared * 3]
		var blocked: String = world.defense.ready_reason(world)
		beacon_button.disabled = not reachable or not blocked.is_empty()
		beacon_button.text = "Light beacon — wave %d in 15 seconds" % (world.defense.cleared + 1) if blocked.is_empty() else blocked
	var reason: String = region.repair_reason(id)
	var prerequisite: String = definition.get("requires", "")
	prerequisite_button.visible = not site.repaired and not prerequisite.is_empty() and not region.sites[prerequisite].repaired
	if prerequisite_button.visible:
		prerequisite_button.text = "View required project: " + Definitions.SITES[prerequisite].name
	if not site.repaired:
		var materials_ready: bool = site.inventory.has_all(definition.repair)
		state_label.text = ("All repair materials delivered." if materials_ready else "Repair materials still needed.")
		if not reason.is_empty(): state_label.text += "\n" + reason
		elif reachable: state_label.text += "\nReady! Click Restore below to finish the project."
		if materials_ready and not reason.is_empty(): state_label.text += "\nYour delivered materials are safely stored here."
		if not reachable: state_label.text += "\nWalk within %.0f tiles of the delivery hatch to restore." % world.interaction_reach()
	restore_button.visible = not site.repaired
	restore_button.text = "Restore - %d credits" % definition.credits if int(definition.credits) > 0 else "Restore " + definition.name
	if not site.repaired and not reason.is_empty(): restore_button.text = "Restore (requirements incomplete)"
	elif not site.repaired and not reachable: restore_button.text = "Walk closer to restore"
	restore_button.disabled = not reachable or not reason.is_empty()
	restore_button.tooltip_text = reason if reachable else "Walk within %.0f tiles of the hatch." % world.interaction_reach()
	supply_button.visible = not site.repaired or definition.has("contract")
	supply_button.text = "Supply one shipment" if site.repaired else "Deliver repair materials"
	withdraw_button.disabled = not reachable or site.inventory.total() == 0 or world.player.total() >= world.player.capacity
	var wanted: Dictionary = definition.repair
	if site.repaired and definition.has("contract"): wanted = Definitions.CONTRACTS[definition.contract].goods
	var can_supply := false
	for item in wanted:
		if world.player.count(item) > 0 and region.receiving_limit(id, item) > 0: can_supply = true
	supply_button.disabled = not reachable or not can_supply
	supply_button.tooltip_text = "Bring the goods shown below. Partial deliveries are accepted; excess stays in your pack."
	var text: String = "WHY WE REBUILD\n" + world.story.goal(world) + "\n\n" + definition.description + "\n\n"
	if not site.repaired:
		text += "REPAIR MATERIALS\n"
		for item in definition.repair: text += "%s  %d / %d\n" % [Catalog.item_name(item), site.inventory.count(item), definition.repair[item]]
		text += "\nCrew cost: %d credits\nWallet: %d credits\n\nREWARD\n%s\n" % [definition.credits, region.credits, definition.reward]
		if not reason.is_empty(): text += "\n" + reason + "\n"
	else:
		text += "%s\n\"%s\"\n\n" % [definition.keeper, definition.greeting]
		if definition.has("contract"):
			var contract: Dictionary = Definitions.CONTRACTS[definition.contract]
			var benefit := "Housing progress" if id == "town_hall" else "%d credits" % contract.reward
			text += "CONTRACT: %s\n%s\n%s per %.0f-second shipment.\n\nBuffered: %s\nDelivered shipments: %d\n" % [contract.name, Catalog.describe(contract.goods), benefit, contract.ticks / 10.0, Catalog.describe(site.inventory.contents), site.shipments]
			if id == "town_hall": text += "\nEvery 3 housing deliveries restores a neighborhood (3 total). Each adds 5% coal working time. Dispatch stops at full restoration.\n"
			else: text += "\nGoods are committed when a shipment departs. Income pauses when supplies run out. Repairs remain complete.\n"
		else: text += "RESTORATION REWARD\n" + definition.reward + "\n"
	text += "\nDELIVERY HATCH (%d, %d)\nManual: delivery button / Ctrl-click supplies; X withdraws.\nAutomation: inserter at (%d, %d), facing EAST; pickup at (%d, %d).\n" % [port.x, port.y, port.x - 1, port.y, port.x - 2, port.y]
	information.text = text
