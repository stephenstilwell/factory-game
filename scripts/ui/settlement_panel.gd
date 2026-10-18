extends VBoxContainer
## Presentation and intent only; repair, reach, currency, and contracts are model rules.

const Style = preload("res://scripts/ui/ui_style.gd")
const Showcase = preload("res://scripts/ui/showcase.gd")
const Definitions = preload("res://scripts/data/settlement_catalog.gd")
const Catalog = preload("res://scripts/data/catalog.gd")
const Grid = preload("res://scripts/ui/inventory_grid.gd")

signal site_selected(id: String)
signal supply_requested(id: String)
signal restore_requested(id: String)
signal talk_requested(id: String)
signal withdraw_requested(id: String)
signal transfer_requested(item: String, amount: int, source: Dictionary, target: Dictionary, token: int)
signal age_requested
signal produce_requested
signal maintenance_requested
signal supplies_order_requested
signal beacon_requested
signal beacon_cancel_requested
signal repair_requested

var current_preview: Control
var restored_preview: Control
var restoration_reward: Label
var reward_heading: Label
var preview_arrow: Label
var selected_id := ""
var age_box: VBoxContainer
var age_text: Label
var age_button: Button
var overview: VBoxContainer
var detail: VBoxContainer
var overview_text: Label
var project_buttons: Dictionary = {}
var project_cards: Dictionary = {}
const Reports = preload("res://scripts/ui/project_reports.gd")
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
var produce_button: Button
var produce_info: Label
var crew_button: Button
var crew_info: Label
var order_button: Button
var beacon_button: Button
var cancel_beacon_button: Button
var damage_button: Button
var supplies_title: Label
const Quartermaster = preload("res://scripts/simulation/quartermaster.gd")
var defense_card: PanelContainer
var readiness: Label
var after_action: Label
var nell_card: PanelContainer
var nell_text: Label
var nell_stock: Button
var nell_rearm: Button
var chapter_box: PanelContainer
var chapter_title: Label
var chapter_text: Label
var chapter_deliver: Button
var chapter_finish: Button
var chapter_lead: Button
signal chapter_lead_requested(id: String)
var cottage_button: Button
var cottage_info: Label

func _ready() -> void:
	age_box = VBoxContainer.new()
	add_child(age_box)
	age_text = _label("", 15, Color("e4c58b"))
	age_box.add_child(age_text)
	age_button = _button(age_box, "Town age project", func(): age_requested.emit())
	chapter_box = PanelContainer.new()
	add_child(chapter_box)
	var chapter_content := VBoxContainer.new()
	chapter_box.add_child(chapter_content)
	chapter_title = Style.label("",20,Style.GOLD)
	chapter_content.add_child(chapter_title)
	chapter_text = Style.label("",14,Style.TEXT)
	chapter_content.add_child(chapter_text)
	var chapter_actions := HBoxContainer.new()
	chapter_content.add_child(chapter_actions)
	chapter_deliver = Style.button(chapter_actions,"Deliver phase supplies",func(): world.settlements.homecoming.deliver(world); refresh(world,selected_id,quantity))
	chapter_finish = Style.button(chapter_actions,"Commission phase",func(): world.settlements.homecoming.commission(world); refresh(world,selected_id,quantity))
	Style.action(chapter_finish)
	chapter_lead = Style.button(chapter_content,"",func():
		var chapter = world.settlements.homecoming
		chapter_lead_requested.emit("orchard" if chapter.stage == 0 else ("technology" if chapter.stage == 1 else "quarry")))
	overview = VBoxContainer.new()
	add_child(overview)
	overview.add_child(_label("OLDBRIDGE RESTORATION", 18, Color("91d2b4")))
	overview_text = _label("")
	overview.add_child(overview_text)
	for id in Definitions.SITES:
		var card := PanelContainer.new()
		overview.add_child(card)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation",12)
		card.add_child(row)
		var art := Showcase.new()
		row.add_child(art)
		art.custom_minimum_size = Vector2(76,96)
		var content := VBoxContainer.new()
		content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(content)
		var heading := HBoxContainer.new()
		content.add_child(heading)
		var name_label := Style.label(Definitions.SITES[id].name,18,Style.TEXT)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		heading.add_child(name_label)
		var badge := Style.label("",11,Style.GOLD)
		badge.autowrap_mode = TextServer.AUTOWRAP_OFF
		heading.add_child(badge)
		var reward := Style.label(Definitions.SITES[id].reward,13,Style.ACCENT)
		content.add_child(reward)
		var bar := ProgressBar.new()
		bar.custom_minimum_size.y = 5
		bar.show_percentage = false
		content.add_child(bar)
		var supplies_label := Style.label("",13,Style.MUTED)
		content.add_child(supplies_label)
		var blocker := Style.label("",13,Style.GOLD)
		content.add_child(blocker)
		project_buttons[id] = Style.button(content,"Inspect project",func(): site_selected.emit(id))
		project_cards[id] = {"art":art,"badge":badge,"bar":bar,"supplies":supplies_label,"blocker":blocker}
	cottage_info = _label("PERSONAL COTTAGE / A home to furnish your way. Optional; no production bonuses.", 14, Color("a2cdb3"))
	overview.add_child(cottage_info)
	cottage_button = _button(overview, "Make cottage kit: 12 timber + 12 planks + 8 stone", func(): world.home.make_kit(world); refresh(world, selected_id, quantity))

	detail = VBoxContainer.new()
	add_child(detail)
	title = _label("",24,Style.TEXT)
	detail.add_child(title)
	var hero := PanelContainer.new()
	detail.add_child(hero)
	var hero_row := HBoxContainer.new()
	hero_row.add_theme_constant_override("separation",12)
	hero.add_child(hero_row)
	current_preview = Showcase.new()
	hero_row.add_child(current_preview)
	current_preview.custom_minimum_size = Vector2(92,100)
	preview_arrow = Style.label("→",24,Style.GOLD)
	preview_arrow.autowrap_mode = TextServer.AUTOWRAP_OFF
	hero_row.add_child(preview_arrow)
	restored_preview = Showcase.new()
	hero_row.add_child(restored_preview)
	restored_preview.custom_minimum_size = Vector2(92,100)
	var reward := VBoxContainer.new()
	reward.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero_row.add_child(reward)
	reward_heading = Style.label("RESTORATION REWARD",11,Style.GOLD)
	reward.add_child(reward_heading)
	restoration_reward = Style.label("",14,Style.TEXT)
	restoration_reward.max_lines_visible = 4
	reward.add_child(restoration_reward)
	state_label = _label("", 14, Color("e4c58b"))
	detail.add_child(state_label)
	talk_button = _button(detail, "Talk", func(): talk_requested.emit(selected_id))
	defense_status = _label("", 13, Style.GOLD)
	detail.add_child(defense_status)
	order_button = _button(detail, "Buy supply bundle — 20 credits", func(): supplies_order_requested.emit())
	order_button.tooltip_text = "20 coal + 10 ammunition + 2 repair kits. Trade credits and beacon relief credits share the same wallet."
	produce_info = _label("", 14, Color("a2cdb3"))
	detail.add_child(produce_info)
	produce_button = _button(detail, "Supply produce for market", func(): produce_requested.emit())
	crew_info = _label("", 14, Color("a2cdb3"))
	detail.add_child(crew_info)
	crew_button = _button(detail, "Hire maintenance crew", func(): maintenance_requested.emit())
	beacon_button = _button(detail, "Light beacon", func(): beacon_requested.emit())
	cancel_beacon_button = _button(detail, "Extinguish beacon — cancel arrival", func(): beacon_cancel_requested.emit())
	damage_button = _button(detail, "Repair with kit [H] (+50 health)", func(): repair_requested.emit())
	prerequisite_button = _button(detail, "View required project", func(): site_selected.emit(Definitions.SITES[selected_id].requires))
	supply_button = _button(detail, "Deliver materials", func(): supply_requested.emit(selected_id))
	restore_button = _button(detail, "Restore", func(): restore_requested.emit(selected_id))
	Style.action(restore_button)
	withdraw_button = _button(detail, "Withdraw unused goods [X]", func(): withdraw_requested.emit(selected_id))
	supplies_title = _label("SUPPLIES  •  click to take; drag to deliver", 13, Color("a0b3b2"))
	detail.add_child(supplies_title)
	supplies = Grid.new()
	detail.add_child(supplies)
	supplies.item_activated.connect(_item_clicked)
	supplies.transfer_dropped.connect(func(data, target): transfer_requested.emit(data.item, int(data.amount), data.source, target, int(data.world)))
	information = _label("")
	detail.add_child(information)
	_button(detail, "All town projects [Y]", func(): site_selected.emit(""))
	defense_card = PanelContainer.new()
	add_child(defense_card)
	move_child(defense_card,1)
	var briefing := VBoxContainer.new()
	defense_card.add_child(briefing)
	briefing.add_child(Style.label("BEACON DEFENSE • Know the stakes",20,Style.GOLD))
	after_action = Style.label("",12,Style.ACCENT)
	briefing.add_child(after_action)
	defense_status.reparent(briefing)
	readiness = Style.label("",12,Style.TEXT)
	briefing.add_child(readiness)
	beacon_button.reparent(briefing)
	cancel_beacon_button.reparent(briefing)
	briefing.move_child(beacon_button,defense_status.get_index()+1)
	briefing.move_child(cancel_beacon_button,beacon_button.get_index()+1)
	nell_card = PanelContainer.new()
	add_child(nell_card)
	move_child(nell_card,2)
	var nell := VBoxContainer.new()
	nell_card.add_child(nell)
	nell.add_child(Style.label("NELL • Quartermaster",20,Style.GOLD))
	nell_text = Style.label("",14,Style.TEXT)
	nell.add_child(nell_text)
	var nell_actions := HBoxContainer.new()
	nell.add_child(nell_actions)
	nell_stock = Style.button(nell_actions,"Stock reserve from pack",func(): Quartermaster.stock(world); refresh(world,selected_id,quantity))
	nell_rearm = Style.button(nell_actions,"Rearm local defenses",func(): Quartermaster.dispatch(world); refresh(world,selected_id,quantity))
	Style.action(nell_rearm)

func _label(text: String, size: int = 16, color: Color = Color("e0e8df")) -> Label:
	return Style.label(text,size,color)

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
	defense_card.visible = id == "town_hall" and region.sites.town_hall.repaired
	nell_card.visible = id == "workshop" and Quartermaster.rescued(world)
	if nell_card.visible:
		var quote := Quartermaster.quote(world)
		nell_text.text = "Rescued with the first arrival. Stock the workshop hatch manually or by inserter. Between defenses Nell fills healthy turret buffers within 28 tiles, using only your reserve. Continuous combat supply still needs automation.\nReserve %d/100 • Dispatch %d rounds to %d defenses • Total shortage %d\n%s" % [quote.reserve,quote.rounds,quote.jobs.size(),quote.shortage,quote.reason]
		nell_stock.disabled = world.player.count("ammo") == 0 or not world.in_reach(region.sites.workshop.port()) or region.receiving_limit("workshop","ammo",world) == 0
		nell_rearm.disabled = not quote.reason.is_empty()
		nell_rearm.tooltip_text = quote.reason if not quote.reason.is_empty() else "Rechecks live targets and reserve. No credit fee; every delivered round comes from your stock."
	var mission = region.homecoming
	chapter_box.visible = mission.unlocked(world) and (id.is_empty() or id == "town_hall")
	if chapter_box.visible:
		chapter_title.text = "HOMECOMING COMPLETE • Oldbridge lives again" if mission.stage == 3 else mission.objective(world)
		chapter_text.text = mission.describe(world)
		chapter_deliver.text = "Load public fuel depot" if mission.stage == 3 else "Deliver phase supplies"
		chapter_deliver.disabled = not world.in_reach(region.sites.town_hall.port())
		chapter_deliver.tooltip_text = "Walk to Town Hall's hatch. Inserters can deliver to the same hatch."
		chapter_finish.visible = mission.stage < 3
		chapter_finish.disabled = not mission.reason(world).is_empty() or not world.in_reach(region.sites.town_hall.port())
		chapter_finish.tooltip_text = mission.reason(world)
		chapter_lead.visible = mission.stage < 3
		chapter_lead.text = "View Orchard growing beds [L]" if mission.stage == 0 else ("View Foundry craft and power unlocks [T]" if mission.stage == 1 else "View Greybank road deliveries [L]")
	cottage_button.disabled = not world.home.kit_reason(world).is_empty()
	cottage_button.tooltip_text = world.home.kit_reason(world)
	cottage_info.text = "PERSONAL COTTAGE / Optional furnished home. " + world.home.kit_reason(world)
	age_box.visible = region.enabled and (world.early.active() or not id.is_empty()) and not chapter_box.visible and not defense_card.visible and not nell_card.visible
	age_text.text = world.early.summary(world)
	age_button.visible = world.early.active()
	age_button.text = "Supply shelter — enter Stone & Water" if world.early.phase == 0 else "Rebuild crossing — enter Iron & Industry"
	age_button.disabled = not world.early.project_reason(world).is_empty()
	age_button.tooltip_text = world.early.project_reason(world)
	if id.is_empty():
		overview_text.text = "A market, a working road, and somewhere dry to sleep. Build a town the families can return to.\n%d trade credits  •  %s" % [region.credits,region.objective_text()]
		for project in project_buttons:
			var report := Reports.settlement(world,project)
			var card: Dictionary = project_cards[project]
			var landmark = region.sites[project]
			card.art.present("site",project,landmark.repaired)
			card.badge.text = {"restored":"RESTORED","offline":"SERVICES OFFLINE","ready":"READY TO RESTORE","incomplete":"RESTORATION PROJECT"}[report.state]
			card.bar.value = 100.0 * report.delivered / report.required
			card.bar.visible = not landmark.repaired
			card.supplies.visible = not landmark.repaired
			card.supplies.text = "%d/%d materials delivered" % [report.delivered,report.required]
			if not report.missing.is_empty(): card.supplies.text += "  •  Missing: " + Catalog.describe(report.missing)
			if report.credit_cost > 0: card.supplies.text += "  •  %d/%d credits" % [mini(region.credits,report.credit_cost),report.credit_cost]
			card.blocker.text = ("Repair Town Hall to resume regional services." if landmark.health > 0 else "Building disabled; repair it with a kit [H].") if report.state == "offline" else ("" if landmark.repaired else report.reason)
			card.blocker.visible = not card.blocker.text.is_empty()
			project_buttons[project].text = "Manage building" if landmark.repaired else ("Review and restore" if report.state == "ready" else "Inspect requirements")
			project_buttons[project].disabled = not region.enabled
		return
	if not region.sites.has(id): return
	var site = region.sites[id]
	var definition: Dictionary = Definitions.SITES[id]
	current_preview.present("site",id,site.repaired)
	restored_preview.present("site",id,true)
	current_preview.visible = not site.repaired
	preview_arrow.visible = not site.repaired
	reward_heading.text = "RESTORED BENEFIT" if site.repaired else "RESTORATION REWARD"
	restoration_reward.text = definition.reward
	restoration_reward.tooltip_text = definition.reward
	supplies.visible = not site.repaired or definition.has("contract")
	supplies_title.visible = supplies.visible
	withdraw_button.visible = supplies.visible
	var expected: Array = definition.repair.keys()
	if site.repaired: expected = Definitions.CONTRACTS[definition.contract].goods.keys() if definition.has("contract") else []
	if id == "trading_post" and site.repaired and world.orchard_project.beds > 0: expected.append("foraged_food")
	if id == "workshop" and site.repaired and Quartermaster.rescued(world): expected.append("ammo")
	if id == "town_hall" and site.repaired:
		for item in mission.goods():
			if item not in expected: expected.append(item)
		if mission.stage == 3: expected.append("coal")
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
	if id == "trading_post" and site.repaired and world.frontier.claimed("orchard"): state_label.text += "\nIona tends the community garden: orchard cuttings recovered."
	if site.repaired: state_label.text += "\nHealth: %d / %d" % [site.health, site.max_health()]
	if id == "town_hall" and site.repaired:
		state_label.text += "\nNEIGHBORHOODS %d / 3 • Housing deliveries %d / 3" % [region.district_level(), site.shipments % 3]
		state_label.text += "\nAll neighborhoods restored; housing deliveries complete." if region.district_level() >= 3 else "\nSupply construction kits, steel, and copper to grow the town. Shortages pause growth."
		if region.district_level() > 0: state_label.text += "\nRegional coal efficiency: +%d%% from neighborhoods." % (region.district_level() * 5)
	defense_status.visible = id == "town_hall" and site.repaired
	produce_info.visible = id == "trading_post" and site.repaired and world.orchard_project.beds > 0
	produce_button.visible = produce_info.visible
	if produce_info.visible:
		produce_info.text = "IONA'S PRODUCE MARKET / 4 fresh produce -> 6 credits per 30s.\nBuffered %d/16 / %s" % [site.inventory.count("foraged_food"), "Delivery in transit: %.1fs" % (world.orchard_project.sale_ticks / 10.0) if world.orchard_project.sale_ticks > 0 else "Waiting for 4 produce."]
		produce_button.text = "Deliver up to 4 fresh produce"
		produce_button.disabled = not reachable or world.player.count("foraged_food") == 0 or world.orchard_project.market_limit(world) == 0
	crew_info.visible = id == "workshop" and site.repaired
	crew_button.visible = crew_info.visible
	if crew_info.visible:
		var quote: Dictionary = world.TownServices.quote(world)
		crew_info.text = "OREN'S MAINTENANCE CREW\nRepairs within 28 tiles of this workshop, most damaged first. Uses your repair power. Up to 10 kits per order."
		crew_button.disabled = not quote.reason.is_empty()
		crew_button.text = "Repair %d %s (+%d health): %d kits + %d credits" % [quote.jobs.size(), "structure" if quote.jobs.size() == 1 else "structures", quote.health, quote.kits, quote.credits] if quote.reason.is_empty() else "Maintenance crew unavailable"
		crew_button.tooltip_text = quote.reason if not quote.reason.is_empty() else "Instant town cleanup between defenses. Consumes the displayed kits from your pack and trade credits."
		if not quote.reason.is_empty(): crew_info.text += "\n" + quote.reason
	order_button.visible = id == "trading_post" and site.repaired
	order_button.disabled = not region.supply_order_reason(world).is_empty()
	order_button.text = "Buy supplies: 20 coal + 10 ammo + 2 kits (20 credits)"
	if order_button.disabled: order_button.tooltip_text = region.supply_order_reason(world)
	else: order_button.tooltip_text = "20 coal + 10 ammunition + 2 repair kits delivered to your pack. Costs 20 trade / relief credits."
	beacon_button.visible = defense_status.visible
	cancel_beacon_button.visible = defense_status.visible and world.defense.phase == "warning"
	damage_button.text = "Repair with kit [H] (+%d health)" % int(world.character.stat("repair_power"))
	damage_button.visible = site.repaired and site.health < site.max_health()
	damage_button.disabled = not reachable or world.player.count("repair_kit") == 0
	if defense_status.visible:
		var cleared: int = world.defense.cleared
		if cleared >= world.defense.MAX_WAVES:
			defense_status.text = "Eastern route secured • All ten arrivals rescued."
		else:
			defense_status.text = ("RESCUE NELL • Unlock workshop rearming from stocked ammunition.\n" if cleared == 0 else "")
			defense_status.text += Catalog.Combat.encounter(cleared+1).name + "\n"
			defense_status.text += "Arrival %d: %s • %s\n" % [cleared+1,Catalog.Combat.composition(cleared),"Central eastern gate" if cleared == 0 else "Three eastern gates"]
			defense_status.text += "Victory: +%d relief credits and 3 families. Crew benefits in tooltip.\n" % region.defense_reward(cleared+1)
			defense_status.text += ("Defense underway; reinforcement groups are committed. Next wave waits for your signal." if world.defense.phase == "active" else ("Repair the Hall fully to retry this arrival; previous victories are safe." if world.defense.phase == "recovery" else "15s initial warning; cancel before combat. Subsequent waves wait for your signal."))
			if world.defense.phase != "idle": defense_status.text += "\n" + world.defense.summary()
		defense_status.tooltip_text = world.defense.reward_preview(world) + "\nScouts flank walls; dismantlers demolish blockers; haulers resist ordinary rounds. Cannons pierce armor; pulses slow groups."
		readiness.text = preload("res://scripts/ui/defense_briefing.gd").describe(world)
		if cleared < world.defense.MAX_WAVES: readiness.text += "\nPLAN: " + Catalog.Combat.encounter(cleared+1).lesson
		after_action.visible = not world.defense.last_result.is_empty()
		after_action.text = world.defense.cost_summary()
		beacon_button.tooltip_text = world.defense.reward_preview(world)
		var blocked: String = world.defense.ready_reason(world)
		beacon_button.disabled = not reachable or not blocked.is_empty()
		beacon_button.visible = cleared < world.defense.MAX_WAVES and world.defense.phase in ["idle","recovery"]
		beacon_button.text = "Signal arrival %d — 15s warning" % (cleared+1) if blocked.is_empty() else blocked
	var reason: String = Reports.settlement(world,id).reason
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
			var benefit := "Housing progress" if id == "town_hall" else "%d credits" % (int(contract.reward) + (region.Ages.STONE_MARKET_BONUS if id == "trading_post" and region.age >= 1 else 0))
			text += "CONTRACT: %s\n%s\n%s per %.0f-second shipment.\n\nBuffered: %s\nDelivered shipments: %d\n" % [contract.name, Catalog.describe(contract.goods), benefit, contract.ticks / 10.0, Catalog.describe(site.inventory.contents), site.shipments]
			if id == "town_hall": text += "\nEvery 3 housing deliveries restores a neighborhood (3 total). Each adds 5% coal working time. Dispatch stops at full restoration.\n"
			else: text += "\nGoods are committed when a shipment departs. Income pauses when supplies run out. Repairs remain complete.\n"
		else: text += "RESTORATION REWARD\n" + definition.reward + "\n"
	text += "\nDELIVERY HATCH (%d, %d)\nManual: delivery button / Ctrl-click supplies; X withdraws.\nAutomation: inserter at (%d, %d), facing EAST; pickup at (%d, %d).\n" % [port.x, port.y, port.x - 1, port.y, port.x - 2, port.y]
	if world.early.active():
		restore_button.disabled = true
		supply_button.disabled = true
		state_label.text = "Later civic project — rebuild the crossing to enter Iron & Industry first. The shelter project above welcomes the first neighbors."
	information.text = text
