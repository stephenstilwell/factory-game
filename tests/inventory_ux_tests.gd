extends RefCounted

const World = preload("res://scripts/simulation/world.gd")
const Inventory = preload("res://scripts/model/inventory.gd")
const SaveService = preload("res://scripts/persistence/save_service.gd")
const Fixtures = preload("res://tests/fixtures.gd")
const Settlements = preload("res://scripts/simulation/settlements.gd")

static func models(test: SceneTree) -> void:
	var bag := Inventory.new(20)
	bag.add("iron_plate", 5)
	test.check(not bag.exchange({"iron_plate": -1}, {"gear": 1}) and bag.count("gear") == 0, "Negative recipe ingredients cannot manufacture free items")
	test.check(not bag.exchange({}, {"gear": -1}) and bag.count("iron_plate") == 5, "Malformed output counts are rejected atomically")
	test.check(bag.move_to(bag, "iron_plate", 3) == 0 and bag.count("iron_plate") == 5, "Self-transfer is a no-op")
	test.check(bag.add("unknown_item") == 0, "Inventory APIs reject unknown item identities")
	var world := World.new()
	world.player.add("iron_plate", 20)
	test.check(world.craft_many("gear", 5) and world.player.count("iron_plate") == 10 and world.craft_queue.size() == 5, "Batch crafting reserves every job's ingredients atomically")
	var next_id: int = world.next_craft_id
	test.check(not world.craft_many("gear", 6) and world.player.count("iron_plate") == 10 and world.craft_queue.size() == 5 and world.next_craft_id == next_id, "Unaffordable batch does not partially queue or spend ingredients")
	test.check(not world.craft_many("gear", -1), "Negative craft batches are rejected")
	var cancelled: int = world.craft_queue[2].id
	test.check(world.cancel_craft_job(cancelled) and world.player.count("iron_plate") == 12 and world.craft_queue.size() == 4, "Any queued job can be cancelled with its exact refund")
	var completed: int = world.craft_queue[0].id
	test.advance(world, 10)
	test.check(not world.cancel_craft_job(completed) and not world.cancel_craft_job(cancelled) and world.craft_queue.size() == 3, "Stale queue clicks cannot cancel a different job after the queue advances")
	test.check(world.cancel_all_crafts() and world.player.count("iron_plate") == 18 and world.player.count("gear") == 1, "Cancelling remaining work conserves completed output and reserved ingredients")
	test.check(world.craft_maximum("gear") == 9, "Craft maximum accounts for available materials and queue room")
	world.craft_many("gear", 9)
	world.player.capacity = 1
	test.check(not world.cancel_all_crafts() and world.craft_queue.size() == 9, "Full pack prevents destructive bulk cancellation")
	world.player.capacity = 10000
	world.cancel_all_crafts()
	world.craft_many("belt", 2)
	var saved := SaveService.decode(JSON.parse_string(JSON.stringify(SaveService.encode(world))))
	test.check(saved.has("world") and saved.world.craft_queue == world.craft_queue and saved.world.next_craft_id == world.next_craft_id, "Craft job IDs and next ID survive save/load")
	var old := SaveService.encode(world)
	old.erase("next_craft_id")
	for job in old.craft_queue: job.erase("id")
	var migrated := SaveService.decode(old)
	test.check(migrated.has("world") and migrated.world.craft_queue[0].id != migrated.world.craft_queue[1].id, "Older queued crafts receive distinct stable identities")
	var invalid := SaveService.encode(world)
	invalid.craft_queue[1].id = invalid.craft_queue[0].id
	test.check(not SaveService.decode(invalid).has("world"), "Duplicate craft job IDs are rejected")
	var transfers := World.new()
	transfers.player_position = Vector2(0.5, 1.5)
	transfers.player.contents = {"iron_ore": 30, "coal": 30, "copper_ore": 5, "gear": 2}
	var furnace = transfers.spawn("furnace", Vector2i(0, 0), 0)
	var player := {"kind": "player"}
	var input := {"kind": "input", "entity_id": furnace.id}
	var output := {"kind": "output", "entity_id": furnace.id}
	test.check(transfers.transfer_item("iron_ore", 0, player, input) == 10 and transfers.player.count("iron_ore") == 20, "Transfer-all obeys machine ingredient buffer limits")
	test.check(transfers.transfer_item("coal", 0, player, input) == 10 and furnace.inventory.count("coal") == 10, "Fuel transfer-all obeys the fuel buffer limit")
	test.check(transfers.transfer_item("gear", 1, player, input) == 0 and transfers.player.count("gear") == 2, "Transfers respect recipe input filters")
	test.check(transfers.transfer_item("coal", 1, player, output) == 0, "Players cannot inject items into machine outputs")
	test.check(transfers.transfer_item("iron_ore", 3, input, player) == 3 and furnace.inventory.count("iron_ore") == 7, "Individual machine ingredients can be withdrawn in exact quantities")
	test.check(transfers.transfer_item("iron_ore", 0, input, input) == 0, "Same-buffer drops cannot duplicate items")
	test.check(transfers.transfer_limit("coal", {"kind": 123}, player) == 0, "Malformed inventory descriptors are rejected safely")
	test.check(transfers.transfer_item("iron_ore", -5, player, input) == 0, "Negative transfer quantities cannot mutate inventories")
	furnace.burn_ticks = 20
	furnace.progress = 12
	furnace.output.add("iron_plate", 2)
	test.check(transfers.set_recipe(furnace.cell, "copper_plate") and furnace.inventory.count("coal") == 10 and furnace.inventory.count("iron_ore") == 0 and furnace.burn_ticks == 20 and furnace.progress == 0, "Recipe selection returns obsolete ingredients while retaining fuel and stored energy")
	furnace.inventory.add("copper_ore", 2)
	transfers.collect_output(furnace.cell)
	test.check(transfers.player.count("iron_plate") == 2 and furnace.inventory.count("copper_ore") == 2 and furnace.inventory.count("coal") == 10, "Output collection leaves machine inputs and fuel running")
	transfers.player_position = Vector2(50, 50)
	test.check(transfers.transfer_item("copper_ore", 1, player, input) == 0 and furnace.inventory.count("copper_ore") == 2, "Inventory commands recheck interaction reach")
	transfers.player_position = Vector2(0.5, 1.5)
	transfers.reclaim(furnace.cell)
	test.check(transfers.transfer_item("coal", 1, player, input) == 0, "Stale machine descriptors cannot target reclaimed inventories")
	var other := World.new()
	other.player.add("coal", 5)
	other.player_position = Vector2(0.5, 1.5)
	var chest = other.spawn("chest", Vector2i(0, 0), 0)
	var chest_input := {"kind": "input", "entity_id": chest.id}
	test.check(other.transfer_item("coal", 5, player, chest_input, transfers.get_instance_id()) == 0 and other.player.count("coal") == 5, "Drag payloads from a previous world cannot transfer into a newly loaded factory")
	chest.inventory.capacity = 2
	test.check(other.transfer_item("coal", 0, player, chest_input) == 2 and other.player.count("coal") == 3, "Partial transfers preserve source remainder when destination capacity is limited")
	chest.inventory.capacity = 200
	other.player.add("stone", 5)
	other.supply(chest.cell)
	test.check(other.player.count("stone") == 5 and chest.inventory.count("coal") == 5, "Chest quick-stack moves matching goods without dumping unrelated supplies")
	var arm = other.spawn("inserter", Vector2i(1, 0), 0)
	arm.carried = "gear"
	test.check(other.transfer_item("gear", 0, {"kind": "hand", "entity_id": arm.id}, player) == 1 and arm.carried == "", "Stuck inserter hands can be recovered without dismantling the machine")
	other.settlements = Settlements.new(true)
	other.player_position = Vector2(28.5, 15.5)
	other.player.add("iron_plate", 100)
	var site := {"kind": "site", "site_id": "trading_post"}
	test.check(other.transfer_item("iron_plate", 0, player, site) == 20 and other.player.count("iron_plate") == 80, "Town drag deliveries respect exact repair requirements")
	test.check(other.transfer_item("iron_plate", 2, site, player) == 2 and other.settlements.sites.trading_post.inventory.count("iron_plate") == 18, "Specific unused civic supplies can be withdrawn")

static func ui(test: SceneTree) -> void:
	var scene = load("res://main.tscn").instantiate()
	test.root.add_child(scene)
	scene.paused = true
	scene.hud.workspace.simulation_paused = true
	scene._bind_world(Fixtures.demo())
	scene.hud.toggle_inventory()
	await test.process_frame
	var workspace = scene.hud.workspace
	test.check(workspace.visible and not scene.hud.world_has_pointer(), "Inventory workspace blocks world actions while open")
	workspace.search.text = "coal"
	workspace.search.text_changed.emit(workspace.search.text)
	test.check(workspace.pack_grid.buttons.coal.visible and not workspace.pack_grid.buttons.gear.visible, "Pack search filters item names")
	workspace.search.text = ""
	workspace.search.text_changed.emit(workspace.search.text)
	workspace.category.select(3)
	workspace.refresh(scene.world)
	test.check(workspace.pack_grid.buttons.furnace.visible and not workspace.pack_grid.buttons.coal.visible, "Pack category filter separates buildings and materials")
	workspace.category.select(0)
	workspace.refresh(scene.world)
	workspace._pack_click("furnace", "select")
	test.check(workspace.equip_button.visible and scene.selected_kind == "", "Selecting a building shows details without accidentally equipping it")
	workspace.equip_button.pressed.emit()
	test.check(not workspace.visible and scene.selected_kind == "furnace", "Equip action closes the workspace and activates construction")
	scene._inspect(Vector2i(19, 15))
	var machine = workspace.machine
	var furnace = scene.world.at(Vector2i(19, 15))
	var coal: int = scene.world.player.count("coal")
	machine.fuel_grid.item_activated.emit("coal", "one")
	test.check(furnace.inventory.count("coal") == 9 and scene.world.player.count("coal") == coal + 1, "Right-click gesture withdraws one fuel through the UI command boundary")
	workspace.pack_grid.item_activated.emit("coal", "all")
	test.check(furnace.inventory.count("coal") == 10 and scene.world.player.count("coal") == coal, "Shift-click pack transfer fills only the available destination space")
	scene.world.player.add("iron_ore", 12)
	scene.hud.refresh()
	var data := {"type": "inventory_item", "item": "iron_ore", "amount": 5, "source": {"kind": "player"}, "world": scene.world.get_instance_id()}
	test.check(machine.input_grid._can_drop_data(Vector2.ZERO, data), "Machine inputs expose a valid drop target for matching ore")
	test.check(not machine.fuel_grid._can_drop_data(Vector2.ZERO, data), "Fuel drop zone rejects ore even though the machine accepts it elsewhere")
	machine.input_grid._drop_data(Vector2.ZERO, data)
	test.check(furnace.inventory.count("iron_ore") == 5 and scene.world.player.count("iron_ore") == 7, "Dropping into a grid performs the selected-quantity transfer")
	var wrong := data.duplicate(true)
	wrong.item = "copper_ore"
	test.check(not machine.input_grid._can_drop_data(Vector2.ZERO, wrong), "Wrong-recipe drops are rejected before commit")
	furnace.output.add("iron_plate", 3)
	var plates: int = scene.world.player.count("iron_plate")
	machine.collect_button.pressed.emit()
	test.check(scene.world.player.count("iron_plate") == plates + 3 and furnace.inventory.count("coal") == 10 and furnace.inventory.count("iron_ore") == 5, "Collect-output UI preserves ongoing machine supplies")
	machine.recipe_picker.item_selected.emit(1)
	test.check(furnace.recipe == "copper_plate" and furnace.inventory.count("coal") == 10, "Direct recipe picker changes the machine without stripping its fuel")
	scene.hud.toggle_crafting()
	var craft = workspace.crafting
	scene.world.player.remove("gear", scene.world.player.count("gear"))
	craft.select_recipe("drill")
	test.check(craft.ingredient_actions.gear.visible and not craft.ingredient_actions.gear.disabled and craft.ingredient_counts.gear.text == "0 / 3", "Craft details show exact missing ingredients and a component-crafting action")
	craft.ingredient_actions.gear.pressed.emit()
	test.check(scene.world.craft_queue.size() == 3, "Make-missing action queues the required component count")
	test.advance(scene.world, 30)
	scene.hud.refresh()
	test.check(not craft.craft_one.disabled, "Main recipe becomes craftable after queued components finish")
	craft.craft_one.pressed.emit()
	var job_id: int = scene.world.craft_queue[0].id
	craft.job_buttons[job_id].pressed.emit()
	test.check(scene.world.craft_queue.is_empty() and scene.world.player.count("gear") == 3, "Queue chip cancels its own stable job ID and refunds ingredients")
	craft.search.text = "furnace"
	craft.search.text_changed.emit(craft.search.text)
	test.check(craft.recipe_buttons.furnace.visible and not craft.recipe_buttons.gear.visible and craft.selected_id == "furnace", "Recipe search selects a visible matching recipe")
	craft.search.text = "not-a-recipe"
	craft.search.text_changed.emit(craft.search.text)
	test.check(craft.recipe_empty.visible and not craft.detail_content.visible, "Empty recipe searches have an explicit empty state")
	craft.search.text = ""
	craft.search.text_changed.emit(craft.search.text)
	await test.process_frame
	await test.process_frame
	test.check(test.root.get_visible_rect().encloses(workspace.get_global_rect()), "Modern workspace stays inside the viewport")
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	scene._input(escape)
	test.check(not workspace.visible, "Escape closes inventory before changing world selection")
	scene._select("")
	if scene.paused: scene._toggle_pause()
	var inventory_key := InputEventKey.new()
	inventory_key.keycode = KEY_E
	inventory_key.pressed = true
	scene._unhandled_input(inventory_key)
	test.check(workspace.visible and workspace.mode == "crafting", "E opens inventory beside crafting")
	scene._unhandled_input(inventory_key)
	test.check(not workspace.visible, "E closes the current interface without loading ingredients")
	var space := InputEventKey.new()
	space.keycode = KEY_SPACE
	space.pressed = true
	scene._unhandled_input(space)
	test.check(not scene.paused, "Space no longer pauses gameplay")
	scene._input(escape)
	test.check(scene.paused and scene.hud.pause_menu.visible and not scene.hud.world_has_pointer(), "Escape opens a blocking paused menu")
	scene._input(escape)
	test.check(not scene.paused and not scene.hud.pause_menu.visible, "Escape resumes from the pause menu")
	scene._toggle_pause()
	scene._input(escape)
	scene._input(escape)
	test.check(scene.paused, "Closing the menu preserves a pre-existing manual pause")
	scene._toggle_pause()
	scene._select("furnace")
	var clear := InputEventKey.new()
	clear.keycode = KEY_Q
	clear.pressed = true
	scene._unhandled_input(clear)
	test.check(scene.selected_kind == "" and furnace.recipe == "copper_plate", "Q clears the cursor without changing a machine recipe")
	var cell: Vector2i = furnace.cell
	scene._update_reclaim(cell, true, 0.2)
	test.check(scene.world.at(cell) != null, "A brief right-click does not immediately reclaim a machine")
	scene._update_reclaim(cell, false, 0.0)
	scene._update_reclaim(cell, true, 0.3)
	test.check(scene.world.at(cell) != null, "Releasing right mouse resets reclamation progress")
	scene._update_reclaim(cell, true, 0.21)
	test.check(scene.world.at(cell) == null, "Holding right mouse reclaims the machine after its delay")
	scene.mining_held = true
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_RIGHT
	release.pressed = false
	scene._input(release)
	test.check(not scene.mining_held and scene.reclaim_progress == 0.0, "Right mouse release stops mining even over UI")
	var survey_key := InputEventKey.new()
	survey_key.keycode = KEY_M
	survey_key.pressed = true
	scene._unhandled_input(survey_key)
	test.check(scene.hud.survey.visible and scene.hud.survey.results.size() == 4 and not scene.hud.world_has_pointer(), "M opens a blocking survey with live results for all starting resources")
	scene.hud.survey.rows.iron_ore.button.pressed.emit()
	test.check(not scene.hud.survey.visible and scene.view.resource_target.get("item") == "iron_ore", "Tracking a survey result closes the panel and sets the compass target")
	scene._unhandled_input(survey_key)
	scene._input(escape)
	test.check(not scene.hud.survey.visible and not scene.hud.pause_menu.visible, "Escape closes a survey before opening the pause menu")
	scene._bind_world(Fixtures.demo())
	test.check(scene.view.resource_target.is_empty(), "Loading a world clears stale survey targets")
	var engineer_key := InputEventKey.new()
	engineer_key.keycode = KEY_P
	engineer_key.pressed = true
	scene._unhandled_input(engineer_key)
	var engineer = workspace.character_panel
	engineer.section_buttons.skills.pressed.emit()
	scene.world.award_skill("mining", 50)
	scene.hud.refresh()
	test.check(engineer.skill_box.visible and not engineer.equipment_box.visible and engineer.skill_rows.mining.title.text.contains("2 / 99") and engineer.skill_rows.mining.bar.value == 0, "Engineer Skills displays earned levels and progress toward the next level")
	test.check(scene.hud.xp_label.text.contains("+50 Mining XP") and scene.hud.xp_label.text.contains("Level 2"), "Successful XP events show compact level-up feedback")
	scene.world.award_skill("fabrication", scene.world.Skills.Definitions.threshold(99))
	scene.hud.refresh()
	test.check(engineer.skill_rows.fabrication.bar.value == 100 and engineer.skill_rows.fabrication.progress.text.contains("Mastered"), "Level 99 has a complete mastery display without a next-level division")
	engineer.section_buttons.equipment.pressed.emit()
	test.check(workspace.visible and workspace.mode == "character" and engineer.visible and not engineer.cards.boots.button.disabled, "P opens Engineer upgrades alongside the pack")
	var plates_before: int = scene.world.player.count("iron_plate")
	engineer.cards.boots.button.pressed.emit()
	test.check(scene.world.character.level("boots") == 1 and scene.world.player.count("iron_plate") == plates_before - 10 and engineer.cards.boots.button.disabled, "Upgrade UI installs the displayed tier then shows the next research gate")
	scene._unhandled_input(engineer_key)
	test.check(not workspace.visible, "P closes the Engineer workspace")
	scene._bind_world(Fixtures.defense_town())
	scene._inspect_site("town_hall")
	var town_panel = workspace.town
	test.check(town_panel.beacon_button.visible and not town_panel.beacon_button.disabled and scene.hud.defense_status.visible, "Restored Town Hall inspection exposes a deliberate beacon action and live HUD status")
	town_panel.beacon_button.pressed.emit()
	test.check(scene.world.defense.phase == "warning" and town_panel.cancel_beacon_button.visible, "Town Hall beacon UI starts the warning and exposes cancellation")
	town_panel.cancel_beacon_button.pressed.emit()
	test.check(scene.world.defense.phase == "idle", "Beacon cancellation UI reaches the authoritative model")
	scene.world.damage_structure(scene.world.settlements.sites.town_hall.port(), 60)
	scene.hud.refresh()
	var kit_count: int = scene.world.player.count("repair_kit")
	town_panel.damage_button.pressed.emit()
	test.check(scene.world.settlements.sites.town_hall.health == 290 and scene.world.player.count("repair_kit") == kit_count - 1, "Town inspection repairs damage using an actual kit")
	scene.hud.close_workspace()
	scene._inspect(Vector2i(51, 11))
	test.check(workspace.machine.input_grid.buttons.ammo.visible and not workspace.machine.output_box.visible, "Turret inspection presents ammunition as input rather than a machine output")
	# Reproduce donating everything to Town Hall before restoring the workshop.
	var staged_world := World.new()
	staged_world.start()
	var staged_hall = staged_world.settlements.sites.town_hall
	staged_world.player_position = Vector2(staged_hall.port()) + Vector2(-0.5, 0.5)
	staged_world.player.contents = staged_world.settlements.Definitions.SITES.town_hall.repair.duplicate()
	staged_world.supply_site("town_hall")
	var staged_save := SaveService.decode(JSON.parse_string(JSON.stringify(SaveService.encode(staged_world))))
	test.check(staged_save.error.is_empty() and staged_save.world.settlements.sites.town_hall.inventory.has_all(staged_world.settlements.Definitions.SITES.town_hall.repair), "Donated Town Hall materials survive save/load while its prerequisite is incomplete")
	scene._bind_world(staged_world)
	scene._inspect_site("town_hall")
	test.check(town_panel.restore_button.disabled and town_panel.state_label.text.contains("All repair materials delivered.") and town_panel.state_label.text.contains("workshop") and town_panel.state_label.text.contains("safely stored"), "Fully supplied Town Hall explains the workshop blocker beside restoration controls")
	test.check(town_panel.prerequisite_button.visible, "Blocked restoration exposes a direct link to its prerequisite")
	town_panel.prerequisite_button.pressed.emit()
	test.check(workspace.site_id == "workshop", "Required-project action opens the workshop instead of silently failing restoration")
	staged_world.settlements.sites.trading_post.repaired = true
	staged_world.settlements.sites.workshop.repaired = true
	scene._inspect_site("town_hall")
	test.check(not town_panel.restore_button.disabled and not town_panel.prerequisite_button.visible, "Previously donated materials become ready to restore when the prerequisite is completed")
	town_panel.restore_button.pressed.emit()
	test.check(staged_hall.repaired and staged_hall.health == staged_hall.max_health() and staged_hall.inventory.total() == 0, "Town Hall restoration UI consumes staged goods once and restores full health")

	var pickup_world := World.new()
	pickup_world.start()
	pickup_world.player_position = Vector2(19.5, 17.5)
	var pickup_furnace = pickup_world.spawn("furnace", Vector2i(20, 17), 0)
	pickup_furnace.inventory.contents = {"coal": 3, "iron_ore": 2}
	pickup_furnace.output.contents = {"iron_plate": 2}
	var pickup_drill = pickup_world.spawn("drill", Vector2i(21, 17), 0)
	pickup_drill.inventory.add("coal", 4)
	scene._bind_world(pickup_world)
	scene._inspect(pickup_furnace.cell)
	test.check(not workspace.machine.reclaim_button.disabled and workspace.machine.reclaim_button.tooltip_text.contains("right mouse"), "Inspection exposes a usable pickup action and teaches the world shortcut")
	pickup_world.player.capacity = 1
	scene.hud.refresh()
	test.check(workspace.machine.reclaim_button.disabled and workspace.machine.status_label.text.contains("Inventory full"), "Pickup explains insufficient pack space before the player clicks")
	test.check(not pickup_world.reclaim(pickup_furnace.cell) and pickup_furnace.inventory.count("coal") == 3, "Rejected pickup preserves the building and every stored item")
	pickup_world.player.capacity = 200
	pickup_furnace.health -= 1
	scene.hud.refresh()
	test.check(workspace.machine.reclaim_button.disabled and workspace.machine.status_label.text.contains("Repair"), "Damaged building pickup explains its repair requirement")
	pickup_furnace.health = pickup_furnace.max_health()
	pickup_world.player_position = Vector2.ZERO
	scene.hud.refresh()
	test.check(workspace.machine.reclaim_button.disabled and workspace.machine.status_label.text.contains("closer"), "Distant machine pickup explains interaction reach")
	pickup_world.player_position = Vector2(19.5, 17.5)
	scene.hud.refresh()
	workspace.machine.reclaim_button.pressed.emit()
	test.check(pickup_world.at(Vector2i(20, 17)) == null and pickup_world.player.count("furnace") == 1 and pickup_world.player.count("coal") == 3 and pickup_world.player.count("iron_ore") == 2 and pickup_world.player.count("iron_plate") == 2 and not workspace.visible, "Pickup button returns the furnace and all stored fuel, input, and output and closes inspection")
	scene._inspect(pickup_drill.cell)
	workspace.machine.reclaim_button.pressed.emit()
	test.check(pickup_world.at(Vector2i(21, 17)) == null and pickup_world.player.count("drill") == 1 and pickup_world.player.count("coal") == 7, "The same pickup action safely returns drills and their fuel")
	scene.queue_free()
	await test.process_frame
