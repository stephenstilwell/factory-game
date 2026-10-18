extends Node2D
## Scene composition and input adapter. Gameplay rules live in scripts/simulation.

const World = preload("res://scripts/simulation/world.gd")
const Simulation = preload("res://scripts/simulation/simulation.gd")
const SaveService = preload("res://scripts/persistence/save_service.gd")
const WorldView = preload("res://scripts/view/world_view.gd")
const HUD = preload("res://scripts/ui/factory_hud.gd")
const Catalog = preload("res://scripts/data/catalog.gd")
const InterfacePolish = preload("res://scripts/ui/interface_polish.gd")
const AudioDirector = preload("res://scripts/audio/audio_director.gd")
const TILE := 48

const SaveSlots = preload("res://scripts/persistence/save_slots.gd")
var autosave_toggle: CheckButton
var last_autosave := 0
var home_was_paused := false
var pending_restoration := ""
var save_dialog: ConfirmationDialog
var presentation: Node
var audio: Node
var world: RefCounted
var view: Node2D
var hud: CanvasLayer
var camera: Camera2D
var copy_mode := false
var copy_dragging := false
var copy_origin := Vector2i.ZERO
var pasting := false
var underground_exit := false
var selected_kind := ""
var facing := 0
var paused := false
var save_path := SaveService.PATH
var menu_was_paused := false
var story_was_paused := false
var reclaim_cell := Vector2i(999999, 999999)
var reclaim_progress := 0.0
var firing_held := false
var mining_held := false
var accumulator := 0.0
var painting := false
var last_painted := Vector2i(999999, 999999)
var selected_cell := Vector2i(999999, 999999)

func _ready() -> void:
	camera = Camera2D.new()
	add_child(camera)
	view = WorldView.new()
	add_child(view)
	audio = AudioDirector.new()
	add_child(audio)
	hud = HUD.new()
	add_child(hud)
	save_dialog = preload("res://scripts/ui/save_recovery_dialog.gd").new()
	add_child(save_dialog)
	save_dialog.load_selected.connect(_load_from_path)
	save_dialog.save_selected.connect(_save_to_slot)
	autosave_toggle = CheckButton.new()
	autosave_toggle.text = "Autosave every 5 simulated minutes (separate recovery file)"
	autosave_toggle.tooltip_text = "Off by default. Autosaves never replace your manual save or its backup. Paused time does not count."
	hud.pause_content.add_child(autosave_toggle)
	autosave_toggle.toggled.connect(func(enabled):
		var error := SaveSlots.set_autosave(save_path, enabled)
		if error != OK: hud.show_notice("Could not save autosave preference: " + error_string(error)))
	var sound_controls := VBoxContainer.new()
	hud.pause_content.add_child(sound_controls)
	hud.pause_content.move_child(sound_controls, 1)
	audio.create_controls(sound_controls)
	presentation = InterfacePolish.new()
	add_child(presentation)
	presentation.configure(hud, view)
	audio.watch_ui(hud)
	hud.home_requested.connect(_enter_home)
	hud.home_panel.close_requested.connect(_leave_home)
	hud.home_panel.save_requested.connect(_save)
	hud.produce_requested.connect(func(): world.orchard_project.deliver_market(world))
	hud.maintenance_requested.connect(func(): world.TownServices.dispatch(world))
	hud.supplies_order_requested.connect(func(): world.settlements.order_supplies(world))
	hud.town_panel.chapter_lead_requested.connect(func(id):
		if id == "technology": _open_factory("research")
		else: _open_frontier(id))
	hud.history_requested.connect(_open_history)
	hud.history.navigate.connect(_history_navigate)
	hud.factory_requested.connect(func(): _open_factory("research"))
	hud.workspace.machine.technology_requested.connect(func(): _open_factory("research"))
	hud.factory_panel.research_requested.connect(func(id): world.select_research(id); hud.refresh())
	hud.factory_panel.recipe_requested.connect(func(id):
		hud.factory_panel.close_panel()
		hud.toggle_crafting()
		hud.crafting.select_recipe(id))
	hud.factory_panel.copy_requested.connect(_start_copy)
	hud.factory_panel.paste_requested.connect(_start_paste)
	hud.factory_panel.build_requested.connect(_build_plans)
	hud.factory_panel.clear_requested.connect(func(): world.plans.clear(world))
	hud.underground_mode_requested.connect(func(enabled): world.set_underground_exit(selected_cell, enabled))
	hud.weapon_requested.connect(_toggle_weapon)
	hud.build_selected.connect(_select)
	hud.upgrade_requested.connect(func(id, rank): world.upgrade_character(id, rank))
	hud.beacon_requested.connect(func(): world.defense.begin(world))
	hud.beacon_cancel_requested.connect(func(): world.defense.cancel(world))
	hud.structure_repair_requested.connect(_repair_selected)
	hud.building_pickup_requested.connect(_pickup_selected)
	hud.save_requested.connect(_save)
	hud.save_as_requested.connect(_save_as)
	hud.load_requested.connect(_load_save)
	hud.pause_requested.connect(_toggle_pause)
	hud.menu_close_requested.connect(_close_menu)
	hud.survey_target_selected.connect(func(data):
		view.resource_target = data
		if not data.is_empty(): world.navigation.track(0)
		if not data.is_empty(): hud.show_notice("Tracking %s at (%d, %d). Follow the teal compass; M changes the survey marker." % [Catalog.item_name(data.item), data.cell.x, data.cell.y]))
	hud.fullscreen_requested.connect(_toggle_fullscreen)
	_update_display_button()
	hud.supply_requested.connect(func(): world.supply(selected_cell))
	hud.collect_requested.connect(func(): world.collect_output(selected_cell))
	hud.recipe_requested.connect(func(): world.cycle_recipe(selected_cell))
	hud.craft_requested.connect(_request_craft)
	hud.craft_cancel_requested.connect(func(): world.cancel_craft())
	hud.job_cancel_requested.connect(func(id): world.cancel_craft_job(id))
	hud.cancel_all_requested.connect(func(): world.cancel_all_crafts())
	hud.transfer_requested.connect(func(item, amount, from, to, token): world.transfer_item(item, amount, from, to, token))
	hud.recipe_selected.connect(func(id): world.set_recipe(selected_cell, id))
	hud.site_selected.connect(_inspect_site)
	hud.site_supply_requested.connect(func(id): world.supply_site(id))
	hud.age_requested.connect(func(): world.early.advance(world))
	hud.site_restore_requested.connect(func(id): world.restore_site(id))
	hud.site_talk_requested.connect(func(id): world.talk_to_site(id))
	hud.journal_requested.connect(_open_journal)
	hud.story_panel.finished.connect(_story_finished)
	hud.story_panel.discoveries_requested.connect(func(): hud.story_panel.close_panel(); _open_frontier())
	hud.story_panel.project_requested.connect(_inspect_site)
	hud.site_withdraw_requested.connect(func(id): world.withdraw_site(id))
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var initial_seed := rng.randi_range(0, 2000000000)
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--world-seed=") and argument.trim_prefix("--world-seed=").is_valid_int():
			initial_seed = clampi(int(argument.trim_prefix("--world-seed=")), -2000000000, 2000000000)
	var initial := World.new(initial_seed)
	initial.start()
	_bind_world(initial)
	if not world.story.seen.has("arrival"): _open_story("arrival")

func _bind_world(state: RefCounted) -> void:
	pending_restoration = ""
	if world != null:
		if world.defense_won.is_connected(_defense_won): world.defense_won.disconnect(_defense_won)
		if world.chapter_progressed.is_connected(_chapter_completed): world.chapter_progressed.disconnect(_chapter_completed)
		if world.technology_completed.is_connected(_technology_completed): world.technology_completed.disconnect(_technology_completed)
		if world.hand_craft_completed.is_connected(_craft_completed): world.hand_craft_completed.disconnect(_craft_completed)
		if world.equipment_upgraded.is_connected(_equipment_completed): world.equipment_upgraded.disconnect(_equipment_completed)
		if world.settlement_restored.is_connected(_restoration_completed): world.settlement_restored.disconnect(_restoration_completed)
		if world.region_restored.is_connected(_region_completed): world.region_restored.disconnect(_region_completed)
	hud.history.hide()
	hud.history.clear()
	hud.completion.clear()
	hud.workspace.reward_card.clear()
	if world != null: world.home.leave()
	hud.home_panel.hide()
	last_autosave = state.ticks
	if autosave_toggle != null: autosave_toggle.set_pressed_no_signal(SaveSlots.autosave_enabled(save_path))
	if hud.story_panel.visible:
		hud.story_panel.dismiss_silently()
		if paused != story_was_paused: _toggle_pause()
	if world != null and world.story_requested.is_connected(_open_story): world.story_requested.disconnect(_open_story)
	hud.factory_panel.close_panel()
	hud.frontier_panel.hide()
	_cancel_planning()
	firing_held = false
	world = state
	world.defense_won.connect(_defense_won)
	world.chapter_progressed.connect(_chapter_completed)
	world.technology_completed.connect(_technology_completed)
	world.hand_craft_completed.connect(_craft_completed)
	world.equipment_upgraded.connect(_equipment_completed)
	world.settlement_restored.connect(_restoration_completed)
	world.region_restored.connect(_region_completed)
	world.story_requested.connect(_open_story)
	audio.bind_world(world)
	world.message.connect(func(text): hud.show_notice(text))
	world.changed.connect(func(): hud.request_refresh())
	world.skill_progressed.connect(func(id, amount, level, leveled): hud.show_skill_xp(id, amount, level, leveled))
	accumulator = 0
	painting = false
	selected_cell = Vector2i(999999, 999999)
	selected_kind = ""
	hud.selection = ""
	hud.workspace.entity_id = -1
	hud.workspace.site_id = ""
	hud.workspace.selected_item = ""
	hud.survey.hide()
	hud.hotbar.close_picker()
	hud.xp_time = 0.0
	hud.xp_label.hide()
	view.resource_target = {}
	view.selected = selected_cell
	view.selected_site = ""
	view.bind(world, camera)
	view.animation_time = world.ticks * World.TICK_SECONDS
	hud.world = world
	hud.inspect(null)
	camera.position = world.player_position * TILE
	hud.refresh()

func _process(delta: float) -> void:
	if hud.home_panel.visible:
		world.move_direction = Vector2.ZERO
		world.mining = false
		world.combat.firing = false
		view.paused = true
		audio.set_interface_state(true, true)
		return
	var mouse_cell := _mouse_cell()
	var pointer: bool = hud.world_has_pointer()
	audio.set_interface_state(hud.workspace.visible or hud.pause_menu.visible or hud.survey.visible or hud.hotbar.picker.visible or hud.story_panel.visible or hud.factory_panel.visible or hud.history.visible or hud.frontier_panel.visible, paused)
	if not view.resource_target.is_empty() and world.terrain.tile(view.resource_target.cell).is_empty():
		view.resource_target = world.terrain.find_resource(view.resource_target.item, Vector2i(world.player_position.floor()), world.survey_radius())
		hud.show_notice("Tracked tile exhausted. Survey marker updated to remaining resources." if not view.resource_target.is_empty() else "No remaining patch found nearby. Explore farther and press M to survey again.")
	world.move_direction = Vector2(
		float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),
		float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	if hud.workspace.visible or hud.pause_menu.visible or hud.survey.visible or hud.hotbar.picker.visible or hud.story_panel.visible or hud.factory_panel.visible or hud.frontier_panel.visible or hud.history.visible or paused:
		world.move_direction = Vector2.ZERO
		painting = false
		mining_held = false
		firing_held = false
	world.combat.aim = get_global_mouse_position() / TILE
	world.combat.firing = pointer and not paused and firing_held and world.combat.armed
	if mouse_cell != world.mining_cell: world.mining_progress = 0
	world.mining_cell = mouse_cell
	world.mining = pointer and not paused and not world.combat.armed and mining_held and world.at(mouse_cell) == null and not painting
	_update_reclaim(mouse_cell, pointer and not paused and mining_held, delta)
	if not paused:
		accumulator += minf(delta, 0.5)
		while accumulator >= World.TICK_SECONDS and not paused:
			accumulator -= World.TICK_SECONDS
			Simulation.step(world)
	if not paused and world.ticks - last_autosave >= SaveSlots.INTERVAL and autosave_toggle.button_pressed:
		last_autosave = world.ticks
		var auto_error := SaveService.save_world(world, save_path + ".auto.json")
		hud.show_notice("Autosaved to separate recovery file." if auto_error.is_empty() else auto_error)
	view.interpolation = 1.0 if paused else accumulator / World.TICK_SECONDS
	var rendered_position: Vector2 = world.previous_position.lerp(world.player_position, view.interpolation) * TILE
	camera.position = camera.position.lerp(rendered_position, 1.0 - exp(-delta * 12))
	view.hover = mouse_cell
	view.selected_site = hud.site_id
	view.pointer_in_world = pointer
	view.ghost_kind = "" if pasting or copy_mode else selected_kind
	view.underground_exit = underground_exit
	view.plan_layer.pasting = pasting and pointer
	view.plan_layer.paste_origin = mouse_cell
	view.copy_rect = _copy_rectangle(mouse_cell) if copy_dragging else Rect2i()
	view.facing = facing
	view.paused = paused
	if painting and pointer and mouse_cell != last_painted and not selected_kind.is_empty(): _paint_to(mouse_cell)
	if pointer:
		var deposit: Dictionary = world.terrain.tile(mouse_cell)
		var entity = world.at(mouse_cell)
		var site = world.settlements.at(mouse_cell)
		var npc: String = world.story.npc_at(world, mouse_cell)
		var text := "(%d, %d)  " % [mouse_cell.x, mouse_cell.y]
		var enemy_id: int = world.defense.enemy_at(mouse_cell)
		if enemy_id != -1:
			var enemy: Dictionary = world.defense.enemies[enemy_id]
			var definition: Dictionary = Catalog.Combat.ENEMIES[enemy.kind]
			text += "%s • %d/%d HP • Armor %d • %s" % [definition.name, enemy.health, world.defense.enemy_health(enemy.kind), definition.armor, definition.role]
		elif entity != null: text += Catalog.item_name(entity.kind) + " - " + entity.status + "  |  Hold right mouse to pick up"
		elif not npc.is_empty(): text += world.story.Definitions.NPCS[npc].name + " • Click to talk [Q clears build cursor]"
		elif site != null: text += world.settlements.Definitions.SITES[site.id].name + " - " + world.settlements.status(site.id)
		elif world.frontier.at(mouse_cell) != "": text += world.frontier.Definitions.SITES[world.frontier.at(mouse_cell)].name + " • Click to investigate [L]"
		elif not world.early.resource_at(world, mouse_cell).is_empty(): text += "%s • %d remaining • Hold RMB to gather" % [Catalog.item_name(world.early.resource_at(world, mouse_cell).item), world.early.resource_at(world, mouse_cell).amount]
		elif world.frontier.tree_at(world, mouse_cell): text += ("Grove tree • Hold RMB to fell for 4 timber • Building clears brush" if world.early.enabled else "Grove tree • Hold right mouse to clear • Building clears brush automatically")
		elif not deposit.is_empty(): text += "%s: %d remaining  |  Hold right mouse to mine" % [Catalog.item_name(deposit.item), deposit.amount]
		elif world.frontier.marsh.water_at(world.frontier,mouse_cell): text += "Reedwater causeway" if world.frontier.marsh.boardwalk(world.frontier,mouse_cell) else "Reedwater water • Causeway project in Discoveries [L]"
		else: text += "Old watercourse • Waterwheel sawmill site" if world.early.enabled and world.early.water_at(mouse_cell) else "Grassland"
		if world.early.active() and not deposit.is_empty() and deposit.item != "stone": text += " • Rebuild the crossing to unlock ore mining [Y]"
		if not world.in_reach(mouse_cell): text += "  |  Out of reach"
		if selected_kind != "": text += "  |  Facing " + ["EAST", "SOUTH", "WEST", "NORTH"][facing]
		hud.hover_label.text = text


func _input(event: InputEvent) -> void:
	if hud.home_panel.visible:
		if event is InputEventKey:
			if event.keycode == KEY_F11 and event.pressed and not event.echo: _toggle_fullscreen()
			else: hud.home_panel.handle_key(event)
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if hud.history.visible: hud.history.hide()
		elif hud.story_panel.visible: hud.story_panel.close_panel()
		elif hud.frontier_panel.visible: hud.frontier_panel.hide()
		elif hud.factory_panel.visible: hud.factory_panel.close_panel()
		elif copy_mode or pasting: _cancel_planning()
		elif hud.hotbar.picker.visible: hud.hotbar.close_picker()
		elif hud.pause_menu.visible: _close_menu()
		elif hud.survey.visible: hud.survey.hide()
		elif hud.workspace.visible: hud.close_workspace()
		elif world.combat.armed: _toggle_weapon()
		elif selected_kind != "": _select("")
		else: _open_menu()
		painting = false
		get_viewport().set_input_as_handled()
		return
	if hud.story_panel.visible and event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ENTER, KEY_SPACE]:
		hud.story_panel.advance()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		_toggle_fullscreen()
		get_viewport().set_input_as_handled()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		painting = false
		firing_held = false
		world.combat.firing = false
		if copy_dragging:
			var error: String = world.plans.capture(world, _copy_rectangle(_mouse_cell()))
			hud.show_notice(error if not error.is_empty() else "Copied %d buildings. Ctrl+V to stamp a plan." % world.plans.clipboard.size())
			_cancel_planning()
	if event is InputEventKey and event.keycode == KEY_SPACE and not event.pressed:
		firing_held = false
		world.combat.firing = false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
		mining_held = false
		reclaim_progress = 0.0

func _toggle_fullscreen() -> void:
	var window := get_window()
	window.mode = Window.MODE_WINDOWED if window.mode in [Window.MODE_FULLSCREEN, Window.MODE_EXCLUSIVE_FULLSCREEN] else Window.MODE_FULLSCREEN
	_update_display_button()

func _update_display_button() -> void:
	var fullscreen := get_window().mode in [Window.MODE_FULLSCREEN, Window.MODE_EXCLUSIVE_FULLSCREEN]
	hud.fullscreen_button.text = "Window [F11]" if fullscreen else "Fullscreen [F11]"

func _unhandled_input(event: InputEvent) -> void:
	if hud.home_panel.visible or hud.history.visible: return
	if event is InputEventKey and event.pressed and not event.echo and event.ctrl_pressed and event.keycode in [KEY_Z, KEY_Y]:
		if not hud.workspace.visible and not hud.pause_menu.visible and not hud.survey.visible and not hud.frontier_panel.visible and not hud.story_panel.visible and not hud.hotbar.picker.visible and (not hud.factory_panel.visible or hud.factory_panel.tab == "plans"):
			var redo: bool = event.keycode == KEY_Y or event.shift_pressed
			var applied: bool = world.plans.redo(world) if redo else world.plans.undo(world)
			hud.show_notice(("Plan edit redone." if redo else "Plan edit undone.") if applied else "No plan edit to restore.")
			hud.factory_panel.refresh()
			get_viewport().set_input_as_handled()
			return
	if hud.frontier_panel.visible:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_L: hud.frontier_panel.hide()
		return
	if hud.story_panel.visible:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_J and hud.story_panel.chapter_id.is_empty(): hud.story_panel.close_panel()
		return
	if hud.factory_panel.visible:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_F: _open_factory("production")
			elif event.keycode == KEY_T: _open_factory("research")
			elif event.keycode == KEY_Y:
				hud.factory_panel.close_panel()
				hud.toggle_town()
		return
	if hud.pause_menu.visible or hud.hotbar.picker.visible: return
	if hud.survey.visible:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_M: hud.survey.hide()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if hud.workspace.visible and event.keycode not in [KEY_I, KEY_C, KEY_T, KEY_Y, KEY_L, KEY_M, KEY_P, KEY_H, KEY_PAUSE, KEY_E, KEY_X, KEY_J, KEY_F, KEY_G, KEY_V]: return
		if not hud.workspace.visible and event.ctrl_pressed and event.keycode in [KEY_C, KEY_V]:
			if event.keycode == KEY_C: _start_copy()
			else: _start_paste()
			get_viewport().set_input_as_handled()
			return
		if pasting and event.keycode == KEY_R:
			world.plans.rotate()
			return
		var slot := 9 if event.keycode == KEY_0 else int(event.keycode - KEY_1)
		if slot >= 0 and slot < 10:
			if event.alt_pressed:
				if not selected_kind.is_empty(): hud.hotbar.assign(slot, selected_kind)
			else: hud.hotbar.activate(slot)
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_TAB:
			hud.hotbar.change_page(-1 if event.shift_pressed else 1)
			get_viewport().set_input_as_handled()
			return
		match event.keycode:
			KEY_ESCAPE:
				_select("")
				_inspect(Vector2i(999999, 999999))
			KEY_R:
				if world.combat.armed:
					hud.show_notice("The rifle draws ammunition directly from your pack; no magazine reload needed.")
					return
				var turn := -1 if event.shift_pressed else 1
				facing = posmod(facing + turn, 4)
				var entity = world.at(_mouse_cell())
				if selected_kind == "" and entity != null and world.in_reach(entity.cell): entity.direction = posmod(entity.direction + turn, 4)
			KEY_V: _toggle_weapon()
			KEY_SPACE:
				if world.combat.armed: firing_held = true
			KEY_F: _open_factory()
			KEY_B: _build_plans()
			KEY_G:
				if not hud.workspace.visible and selected_kind == "underground_belt": underground_exit = not underground_exit
				else:
					var cell := selected_cell if hud.workspace.visible else _mouse_cell()
					var tunnel = world.at(cell)
					if tunnel != null: world.set_underground_exit(cell, not tunnel.underground_exit)
			KEY_PAUSE: _toggle_pause()
			KEY_J: _open_journal()
			KEY_L: _open_frontier()
			KEY_C: hud.toggle_crafting()
			KEY_P: hud.toggle_character()
			KEY_H:
				if hud.workspace.visible: _repair_selected()
				elif hud.world_has_pointer(): world.repair_at(_mouse_cell())
			KEY_M: hud.toggle_survey()
			KEY_I: hud.toggle_inventory()
			KEY_T: _open_factory("research")
			KEY_Y:
				painting = false
				hud.toggle_town()
			KEY_E:
				if hud.workspace.visible: hud.close_workspace()
				else: hud.toggle_crafting()
			KEY_X:
				if hud.site_id != "": world.withdraw_site(hud.site_id)
				elif not hud.workspace.visible or hud.workspace.mode == "machine": world.collect_output(selected_cell)
			KEY_Q:
				if world.combat.armed: _toggle_weapon()
				elif copy_mode or pasting: _cancel_planning()
				elif selected_kind != "": _select("")
				else:
					var hovered = world.at(_mouse_cell())
					if hovered != null: _select(hovered.kind)
	if event is InputEventMouseButton and event.pressed and hud.world_has_pointer():
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				var cell := _mouse_cell()
				if world.combat.armed:
					firing_held = true
				elif copy_mode:
					copy_origin = cell
					copy_dragging = true
				elif pasting:
					var error: String = world.plans.place(world, cell)
					hud.show_notice(error if not error.is_empty() else "Plan placed. B builds reachable ghosts using your pack.")
				elif event.shift_pressed and not selected_kind.is_empty():
					var error: String = world.plans.place_single(world, selected_kind, cell, facing, underground_exit)
					if not error.is_empty(): hud.show_notice(error)
				elif event.ctrl_pressed:
					var site = world.settlements.at(cell)
					if site != null: world.supply_site(site.id)
					else: world.supply(cell)
				elif not world.story.npc_at(world, cell).is_empty(): _inspect(cell)
				elif selected_kind == "" or world.at(cell) != null:
					_request_inspection(cell)
				else:
					painting = true
					last_painted = cell
					world.build(selected_kind, cell, facing, underground_exit)
			MOUSE_BUTTON_RIGHT:
				if world.combat.armed:
					_toggle_weapon()
					return
				painting = false
				if world.plans.ghosts.has(_mouse_cell()):
					world.plans.remove(world, _mouse_cell())
				else: mining_held = true
				reclaim_progress = 0.0
			MOUSE_BUTTON_WHEEL_UP: camera.zoom = Vector2.ONE * minf(1.7, camera.zoom.x + 0.1)
			MOUSE_BUTTON_WHEEL_DOWN: camera.zoom = Vector2.ONE * maxf(0.65, camera.zoom.x - 0.1)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		firing_held = false
		if world != null: world.combat.firing = false
		copy_dragging = false
		painting = false
		mining_held = false
		reclaim_progress = 0.0
		if world != null:
			world.mining = false
			world.move_direction = Vector2.ZERO

func _mouse_cell() -> Vector2i:
	return Vector2i((get_global_mouse_position() / TILE).floor())

func _select(kind: String) -> void:
	if kind != "" and not world.content_available(kind):
		hud.show_notice("This tool appears after its learning milestone. Follow the objective above.")
		return
	if kind != "" and not world.unlocked(Catalog.BUILDINGS[kind]):
		hud.show_notice("Research %s to unlock this building." % Catalog.technology(Catalog.BUILDINGS[kind].get("technology", "")).get("name", "the required technology"))
		return
	_cancel_planning()
	underground_exit = false
	if not kind.is_empty():
		world.combat.armed = false
		world.combat.firing = false
		firing_held = false
	selected_kind = kind
	hud.close_workspace()
	hud.selection = kind
	painting = false
	hud.refresh()

func _open_frontier(id: String = "") -> void:
	_cancel_planning()
	painting = false
	mining_held = false
	firing_held = false
	hud.close_workspace()
	hud.factory_panel.close_panel()
	hud.survey.hide()
	hud.hotbar.close_picker()
	hud.frontier_panel.open_panel(world, id)

func _request_inspection(cell: Vector2i) -> void:
	painting = false
	mining_held = false
	_apply_inspection.call_deferred(cell, world.get_instance_id())

func _apply_inspection(cell: Vector2i, world_token: int) -> void:
	if world != null and world.get_instance_id() == world_token: _inspect(cell)

func _inspect(cell: Vector2i) -> void:
	var landmark: String = world.frontier.at(cell)
	if not landmark.is_empty():
		_open_frontier(landmark)
		return
	var npc: String = world.story.npc_at(world, cell)
	if not npc.is_empty():
		world.talk_to_site(npc)
		return
	var site = world.settlements.at(cell)
	if site != null:
		_inspect_site(site.id)
		return
	selected_cell = cell
	view.selected = cell
	view.selected_site = ""
	hud.inspect(world.at(cell))

func _inspect_site(id: String) -> void:
	painting = false
	view.selected_site = id
	selected_cell = Vector2i(999999, 999999)
	view.selected = selected_cell
	hud.inspect_site(id)

func _paint_to(cell: Vector2i) -> void:
	var cursor := last_painted
	for i in range(64):
		if cursor == cell: break
		var offset := cell - cursor
		if absi(offset.x) >= absi(offset.y): cursor.x += signi(offset.x)
		else: cursor.y += signi(offset.y)
		if world.at(cursor) == null and world.can_build(selected_kind, cursor).is_empty(): world.build(selected_kind, cursor, facing, underground_exit)
	last_painted = cell

func _enter_home() -> void:
	if not hud.workspace.visible or hud.workspace.mode != "machine": return
	var id: int = hud.workspace.entity_id
	if not world.home.enter(world, id):
		hud.show_notice(world.home.entry_reason(world, id))
		return
	home_was_paused = paused
	_cancel_planning()
	painting = false
	mining_held = false
	firing_held = false
	world.mining = false
	world.combat.firing = false
	world.move_direction = Vector2.ZERO
	hud.close_workspace()
	if not paused: _toggle_pause()
	hud.home_panel.open(world, id)

func _leave_home() -> void:
	hud.home_panel.hide()
	world.home.leave()
	if paused != home_was_paused: _toggle_pause()
	view.paused = paused
	hud.refresh()

func _toggle_pause() -> void:
	paused = not paused
	hud.workspace.simulation_paused = paused
	hud.pause_button.text = "Resume" if paused else "Pause"
	hud.refresh()

func _pickup_selected() -> void:
	if not hud.workspace.visible or hud.workspace.mode != "machine": return
	var entity = world.entities.get(hud.workspace.entity_id)
	if entity != null and world.reclaim(entity.cell):
		_inspect(Vector2i(999999, 999999))
		painting = false
		mining_held = false
		reclaim_progress = 0.0

func _repair_selected() -> void:
	if hud.site_id != "": world.repair_at(world.settlements.sites[hud.site_id].port())
	elif hud.workspace.visible and hud.workspace.mode == "machine": world.repair_at(selected_cell)

func _open_menu() -> void:
	menu_was_paused = paused
	if not paused: _toggle_pause()
	painting = false
	world.mining = false
	hud.pause_menu.show()

func _close_menu() -> void:
	hud.pause_menu.hide()
	if paused != menu_was_paused: _toggle_pause()

func _update_reclaim(cell: Vector2i, held: bool, delta: float) -> void:
	if not held or world.at(cell) == null or not world.in_reach(cell):
		reclaim_progress = 0.0
		reclaim_cell = cell
		return
	if reclaim_cell != cell:
		reclaim_cell = cell
		reclaim_progress = 0.0
	reclaim_progress += delta
	hud.show_notice("Reclaiming %s: %d%%" % [Catalog.item_name(world.at(cell).kind), mini(100, int(reclaim_progress / 0.5 * 100))])
	if reclaim_progress >= 0.5:
		world.reclaim(cell)
		reclaim_progress = 0.0

func _prepare_story() -> void:
	hud.history.hide()
	firing_held = false
	world.combat.firing = false
	_cancel_planning()
	hud.factory_panel.close_panel()
	hud.frontier_panel.hide()
	story_was_paused = paused
	if not paused: _toggle_pause()
	painting = false
	mining_held = false
	world.mining = false
	world.move_direction = Vector2.ZERO
	hud.close_workspace()
	hud.survey.hide()
	hud.hotbar.close_picker()

func _open_story(chapter: String) -> void:
	if not world.story.available(world, chapter): return
	if not hud.story_panel.visible: _prepare_story()
	hud.story_panel.present(world, chapter)

func _open_journal() -> void:
	if hud.story_panel.visible:
		hud.story_panel.close_panel()
		return
	_prepare_story()
	hud.story_panel.open_journal(world)

func _story_finished(chapter: String) -> void:
	if not pending_restoration.is_empty():
		var id := pending_restoration
		pending_restoration = ""
		_present_restoration.call_deferred(id,world.get_instance_id())
	if not chapter.is_empty(): world.story.mark_seen(world, chapter)
	if paused != story_was_paused: _toggle_pause()
	hud.refresh()

func _save_as() -> void:
	if not hud.pause_menu.visible: _open_menu()
	save_dialog.open(save_path, true)

func _save_to_slot(path: String, title: String) -> void:
	var error := SaveService.save_world(world, path)
	if not error.is_empty():
		hud.show_notice(error)
		return
	save_path = path
	var name_error := SaveSlots.rename(path, SaveSlots.index_for(path), title)
	last_autosave = world.ticks
	autosave_toggle.set_pressed_no_signal(SaveSlots.autosave_enabled(path))
	hud.show_notice("Factory saved to " + SaveSlots.label(path, SaveSlots.index_for(path)) + ("; could not store its name." if name_error != OK else "."))

func _save() -> void:
	var error := SaveService.save_world(world, save_path)
	hud.show_notice("Factory saved. Recovery copies are available through Load / recovery." if error.is_empty() else error)
	if hud.home_panel.visible: hud.home_panel.hint.text = "Cottage and factory saved." if error.is_empty() else error

func _load_save() -> void:
	if not hud.pause_menu.visible: _open_menu()
	save_dialog.open(save_path)

func _load_from_path(source: String) -> void:
	var result := SaveService.load_world(source)
	if not result.get("error", "").is_empty():
		hud.show_notice(result.error)
		return
	save_path = source.trim_suffix(".bak").trim_suffix(".auto.json")
	_bind_world(result.world)
	if hud.pause_menu.visible: _close_menu()
	if not world.story.seen.has("arrival"): _open_story("arrival")
	hud.show_notice("Recovery copy loaded. Save when ready to make this your current factory." if source.ends_with(".bak") or source.ends_with(".auto.json") else "Factory restored.")

func _cancel_planning() -> void:
	copy_mode = false
	copy_dragging = false
	pasting = false
	painting = false

func _copy_rectangle(end: Vector2i) -> Rect2i:
	var corner := Vector2i(mini(copy_origin.x, end.x), mini(copy_origin.y, end.y))
	return Rect2i(corner, Vector2i(absi(end.x - copy_origin.x) + 1, absi(end.y - copy_origin.y) + 1))

func _start_copy() -> void:
	if world.combat.armed: _toggle_weapon()
	_cancel_planning()
	hud.close_workspace()
	hud.factory_panel.close_panel()
	copy_mode = true
	hud.show_notice("Drag a rectangle around a factory module. Esc cancels.")

func _start_paste() -> void:
	if world.combat.armed: _toggle_weapon()
	_cancel_planning()
	if world.plans.clipboard.is_empty():
		hud.show_notice("Copy a factory area with Ctrl+C first.")
		return
	hud.close_workspace()
	hud.factory_panel.close_panel()
	pasting = true
	hud.show_notice("Click to stamp ghosts. R rotates; B builds nearby; Esc finishes.")

func _build_plans() -> void:
	var count: int = world.plans.build_nearby(world)
	var report: Dictionary = world.plans.supply_report(world, false)
	var missing: Dictionary = {}
	for kind in report.rows:
		if report.rows[kind].missing > 0: missing[kind] = report.rows[kind].missing
	hud.show_notice("Built %d / %d out of reach / %d blocked. Unqueued shortages: %s. F > Plans shows supplies." % [count, report.distant, report.blocked, Catalog.describe(missing)])
	hud.refresh()

func _open_factory(next_tab: String = "production") -> void:
	if hud.factory_panel.visible and hud.factory_panel.tab == next_tab:
		hud.factory_panel.close_panel()
		return
	_cancel_planning()
	mining_held = false
	hud.close_workspace()
	hud.survey.hide()
	hud.hotbar.close_picker()
	hud.factory_panel.open_panel(world, next_tab)

func _toggle_weapon(specific: String = "") -> void:
	if not world.combat.toggle(world, specific): return
	_cancel_planning()
	selected_kind = ""
	hud.selection = ""
	mining_held = false
	firing_held = false
	hud.close_workspace()
	hud.refresh()

func _craft_completed(recipe: String, delivered: Dictionary) -> void:
	if delivered.is_empty(): return
	var item: String = delivered.keys()[0]
	var amount: int = int(delivered[item]) if delivered.size() == 1 else 0
	hud.history.record("craft:"+recipe,"Craft complete",Catalog.describe(delivered) if amount == 0 else Catalog.item_name(item),"crafting",recipe,amount)
	_reward_target().reveal("item", item, "Craft complete", Catalog.item_name(item) if amount > 0 else Catalog.describe(delivered), amount)

func _equipment_completed(id: String, rank: int) -> void:
	var definition: Dictionary = world.character.Definitions.UPGRADES[id]
	hud.history.record("equipment:"+id,"Equipment installed • Tier %d" % rank,definition.name + " / " + world.character.Definitions.format_stat(definition.stat,definition.values[rank-1]),"equipment",id)
	_reward_target().reveal("equipment",id,"Equipment installed • Tier %d" % rank,definition.name + " / " + world.character.Definitions.format_stat(definition.stat, definition.values[rank - 1]))

func _region_completed(id: String) -> void:
	var name: String = world.frontier.Definitions.SITES[id].name
	var detail := "+25% repair-kit healing; supply the lodge to produce maintenance kits. Discoveries [L]."
	hud.history.record("region:"+id,name+" restored",detail,"discoveries",id)
	_reward_target().reveal("item","repair_kit",name+" restored",detail,0,true)

func _restoration_completed(id: String) -> void:
	var definition: Dictionary = world.settlements.Definitions.SITES[id]
	hud.history.record("site:"+id,"A place brought back to life",definition.name + " / " + definition.reward,"town",id)
	_present_restoration.call_deferred(id,world.get_instance_id())

func _present_restoration(id: String, world_token: int) -> void:
	if world.get_instance_id() != world_token: return
	if hud.story_panel.visible:
		pending_restoration = id
		return
	var definition: Dictionary = world.settlements.Definitions.SITES[id]
	_reward_target().reveal("site",id,"A place brought back to life",definition.name + " / " + definition.reward)

func _reward_target() -> PanelContainer:
	return hud.workspace.reward_card if hud.workspace.visible else hud.completion

func _request_craft(id: String, count: int) -> void:
	if world.craft_many(id,count): hud.crafting.preview.absorb(Catalog.RECIPES[id]["in"].keys())

func _technology_completed(id: String) -> void:
	var definition: Dictionary = Catalog.technology(id)
	hud.history.record("technology:"+id,"Technology unlocked: " + definition.name,definition.unlock,"technology",id)
	_reward_target().reveal("item",definition.get("preview","science"),"Technology unlocked",definition.name + " / " + definition.unlock,0,true)

func _open_history() -> void:
	_cancel_planning()
	painting = false
	mining_held = false
	firing_held = false
	hud.close_workspace()
	hud.factory_panel.close_panel()
	hud.frontier_panel.hide()
	hud.survey.hide()
	hud.hotbar.close_picker()
	hud.history.open_history()

func _history_navigate(destination: String, id: String) -> void:
	match destination:
		"crafting":
			hud.toggle_crafting()
			hud.crafting.select_recipe(id)
		"technology":
			_open_factory("research")
			hud.factory_panel.research_panel.select(id)
		"equipment":
			hud.toggle_character()
			hud.workspace.character_panel.show_section("equipment")
		"town": _inspect_site(id)
		"discoveries": _open_frontier(id)

func _chapter_completed(stage: int) -> void:
	var chapter = world.settlements.homecoming
	var text: String = "The fair is open. Town Hall's public fuel depot is now available." if stage == 3 else chapter.STAGES[stage].purpose
	hud.history.record("homecoming:%d" % stage,"Homecoming • %d/3 complete" % stage,text,"town","town_hall")
	_reward_target().reveal("site","town_hall","Oldbridge comes to life • %d/3" % stage,text,0,true)

func _defense_won(wave: int) -> void:
	hud.history.record("defense:%d" % wave,"Nell rescued • Workshop rearming unlocked" if wave == 1 else "Arrival %d secured" % wave,"Visit the workshop hatch to stock ammunition and rearm local defenses between waves." if wave == 1 else "+%d relief credits; 3 families home. %s" % [world.settlements.defense_reward(wave),world.defense.cost_summary()],"town","workshop" if wave == 1 else "town_hall")
