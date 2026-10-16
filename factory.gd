extends Node2D
## Scene composition and input adapter. Gameplay rules live in scripts/simulation.

const World = preload("res://scripts/simulation/world.gd")
const Simulation = preload("res://scripts/simulation/simulation.gd")
const SaveService = preload("res://scripts/persistence/save_service.gd")
const WorldView = preload("res://scripts/view/world_view.gd")
const HUD = preload("res://scripts/ui/factory_hud.gd")
const Catalog = preload("res://scripts/data/catalog.gd")
const AudioDirector = preload("res://scripts/audio/audio_director.gd")
const TILE := 48

var audio: Node
var world: RefCounted
var view: Node2D
var hud: CanvasLayer
var camera: Camera2D
var selected_kind := ""
var facing := 0
var paused := false
var save_path := SaveService.PATH
var menu_was_paused := false
var story_was_paused := false
var reclaim_cell := Vector2i(999999, 999999)
var reclaim_progress := 0.0
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
	var sound_controls := VBoxContainer.new()
	hud.pause_content.add_child(sound_controls)
	hud.pause_content.move_child(sound_controls, 1)
	audio.create_controls(sound_controls)
	audio.watch_ui(hud)
	hud.build_selected.connect(_select)
	hud.upgrade_requested.connect(func(id, rank): world.upgrade_character(id, rank))
	hud.beacon_requested.connect(func(): world.defense.begin(world))
	hud.beacon_cancel_requested.connect(func(): world.defense.cancel(world))
	hud.structure_repair_requested.connect(_repair_selected)
	hud.building_pickup_requested.connect(_pickup_selected)
	hud.save_requested.connect(_save)
	hud.load_requested.connect(_load_save)
	hud.pause_requested.connect(_toggle_pause)
	hud.menu_close_requested.connect(_close_menu)
	hud.survey_target_selected.connect(func(data):
		view.resource_target = data
		if not data.is_empty(): hud.show_notice("Tracking %s at (%d, %d). Follow the teal compass; M changes the survey marker." % [Catalog.item_name(data.item), data.cell.x, data.cell.y]))
	hud.fullscreen_requested.connect(_toggle_fullscreen)
	_update_display_button()
	hud.supply_requested.connect(func(): world.supply(selected_cell))
	hud.collect_requested.connect(func(): world.collect_output(selected_cell))
	hud.recipe_requested.connect(func(): world.cycle_recipe(selected_cell))
	hud.craft_requested.connect(func(id, count): world.craft_many(id, count))
	hud.craft_cancel_requested.connect(func(): world.cancel_craft())
	hud.job_cancel_requested.connect(func(id): world.cancel_craft_job(id))
	hud.cancel_all_requested.connect(func(): world.cancel_all_crafts())
	hud.transfer_requested.connect(func(item, amount, from, to, token): world.transfer_item(item, amount, from, to, token))
	hud.recipe_selected.connect(func(id): world.set_recipe(selected_cell, id))
	hud.site_selected.connect(_inspect_site)
	hud.site_supply_requested.connect(func(id): world.supply_site(id))
	hud.site_restore_requested.connect(func(id): world.restore_site(id))
	hud.site_talk_requested.connect(func(id): world.talk_to_site(id))
	hud.journal_requested.connect(_open_journal)
	hud.story_panel.finished.connect(_story_finished)
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
	if hud.story_panel.visible:
		hud.story_panel.dismiss_silently()
		if paused != story_was_paused: _toggle_pause()
	if world != null and world.story_requested.is_connected(_open_story): world.story_requested.disconnect(_open_story)
	world = state
	world.story_requested.connect(_open_story)
	audio.bind_world(world)
	world.message.connect(func(text): hud.show_notice(text))
	world.changed.connect(func(): hud.refresh())
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
	var mouse_cell := _mouse_cell()
	var pointer: bool = hud.world_has_pointer()
	audio.set_interface_state(hud.workspace.visible or hud.pause_menu.visible or hud.survey.visible or hud.hotbar.picker.visible or hud.story_panel.visible, paused)
	if not view.resource_target.is_empty() and world.terrain.tile(view.resource_target.cell).is_empty():
		view.resource_target = world.terrain.find_resource(view.resource_target.item, Vector2i(world.player_position.floor()), world.skills.survey_radius())
		hud.show_notice("Tracked tile exhausted. Survey marker updated to remaining resources." if not view.resource_target.is_empty() else "No remaining patch found nearby. Explore farther and press M to survey again.")
	world.move_direction = Vector2(
		float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),
		float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	if hud.workspace.visible or hud.pause_menu.visible or hud.survey.visible or hud.hotbar.picker.visible or hud.story_panel.visible or paused:
		world.move_direction = Vector2.ZERO
		painting = false
		mining_held = false
	if mouse_cell != world.mining_cell: world.mining_progress = 0
	world.mining_cell = mouse_cell
	world.mining = pointer and not paused and mining_held and world.at(mouse_cell) == null and not painting
	_update_reclaim(mouse_cell, pointer and not paused and mining_held, delta)
	if not paused:
		accumulator += minf(delta, 0.5)
		while accumulator >= World.TICK_SECONDS and not paused:
			accumulator -= World.TICK_SECONDS
			Simulation.step(world)
	view.interpolation = 1.0 if paused else accumulator / World.TICK_SECONDS
	var rendered_position: Vector2 = world.previous_position.lerp(world.player_position, view.interpolation) * TILE
	camera.position = camera.position.lerp(rendered_position, 1.0 - exp(-delta * 12))
	view.hover = mouse_cell
	view.selected_site = hud.site_id
	view.pointer_in_world = pointer
	view.ghost_kind = selected_kind
	view.facing = facing
	view.paused = paused
	if painting and pointer and mouse_cell != last_painted and not selected_kind.is_empty(): _paint_to(mouse_cell)
	if pointer:
		var deposit: Dictionary = world.terrain.tile(mouse_cell)
		var entity = world.at(mouse_cell)
		var site = world.settlements.at(mouse_cell)
		var npc: String = world.story.npc_at(world, mouse_cell)
		var text := "(%d, %d)  " % [mouse_cell.x, mouse_cell.y]
		if entity != null: text += Catalog.item_name(entity.kind) + " - " + entity.status + "  |  Hold right mouse to pick up"
		elif not npc.is_empty(): text += world.story.Definitions.NPCS[npc].name + " • Click to talk [Q clears build cursor]"
		elif site != null: text += world.settlements.Definitions.SITES[site.id].name + " - " + world.settlements.status(site.id)
		elif not deposit.is_empty(): text += "%s: %d remaining  |  Hold right mouse to mine" % [Catalog.item_name(deposit.item), deposit.amount]
		else: text += "Grassland"
		if not world.in_reach(mouse_cell): text += "  |  Out of reach"
		if selected_kind != "": text += "  |  Facing " + ["EAST", "SOUTH", "WEST", "NORTH"][facing]
		hud.hover_label.text = text

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if hud.story_panel.visible: hud.story_panel.close_panel()
		elif hud.hotbar.picker.visible: hud.hotbar.close_picker()
		elif hud.pause_menu.visible: _close_menu()
		elif hud.survey.visible: hud.survey.hide()
		elif hud.workspace.visible: hud.close_workspace()
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
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed: painting = false
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
	if hud.story_panel.visible:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_J and hud.story_panel.chapter_id.is_empty(): hud.story_panel.close_panel()
		return
	if hud.pause_menu.visible or hud.hotbar.picker.visible: return
	if hud.survey.visible:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_M: hud.survey.hide()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if hud.workspace.visible and event.keycode not in [KEY_I, KEY_C, KEY_T, KEY_M, KEY_P, KEY_H, KEY_PAUSE, KEY_E, KEY_X, KEY_J]: return
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
				var turn := -1 if event.shift_pressed else 1
				facing = posmod(facing + turn, 4)
				var entity = world.at(_mouse_cell())
				if selected_kind == "" and entity != null and world.in_reach(entity.cell): entity.direction = posmod(entity.direction + turn, 4)
			KEY_PAUSE: _toggle_pause()
			KEY_J: _open_journal()
			KEY_C: hud.toggle_crafting()
			KEY_P: hud.toggle_character()
			KEY_H:
				if hud.workspace.visible: _repair_selected()
				elif hud.world_has_pointer(): world.repair_at(_mouse_cell())
			KEY_M: hud.toggle_survey()
			KEY_I: hud.toggle_inventory()
			KEY_T:
				painting = false
				hud.toggle_town()
			KEY_E:
				if hud.workspace.visible: hud.close_workspace()
				else: hud.toggle_crafting()
			KEY_X:
				if hud.site_id != "": world.withdraw_site(hud.site_id)
				elif not hud.workspace.visible or hud.workspace.mode == "machine": world.collect_output(selected_cell)
			KEY_Q:
				if selected_kind != "": _select("")
				else:
					var hovered = world.at(_mouse_cell())
					if hovered != null: _select(hovered.kind)
	if event is InputEventMouseButton and event.pressed and hud.world_has_pointer():
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				var cell := _mouse_cell()
				if event.ctrl_pressed:
					var site = world.settlements.at(cell)
					if site != null: world.supply_site(site.id)
					else: world.supply(cell)
				elif not world.story.npc_at(world, cell).is_empty(): _inspect(cell)
				elif selected_kind == "": _inspect(cell)
				else:
					painting = true
					last_painted = cell
					world.build(selected_kind, cell, facing)
			MOUSE_BUTTON_RIGHT:
				painting = false
				mining_held = true
				reclaim_progress = 0.0
			MOUSE_BUTTON_WHEEL_UP: camera.zoom = Vector2.ONE * minf(1.7, camera.zoom.x + 0.1)
			MOUSE_BUTTON_WHEEL_DOWN: camera.zoom = Vector2.ONE * maxf(0.65, camera.zoom.x - 0.1)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
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
		hud.show_notice("Research Logistics I to unlock fast conveyors.")
		return
	selected_kind = kind
	hud.close_workspace()
	hud.selection = kind
	painting = false
	hud.refresh()

func _inspect(cell: Vector2i) -> void:
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
		if world.at(cursor) == null and world.can_build(selected_kind, cursor).is_empty(): world.build(selected_kind, cursor, facing)
	last_painted = cell

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
	if not chapter.is_empty(): world.story.mark_seen(world, chapter)
	if paused != story_was_paused: _toggle_pause()
	hud.refresh()

func _save() -> void:
	var error := SaveService.save_world(world, save_path)
	hud.show_notice("Factory saved. Previous save retained as .bak." if error.is_empty() else error)

func _load_save() -> void:
	var result := SaveService.load_world(save_path)
	if not result.get("error", "").is_empty():
		hud.show_notice(result.error)
		return
	_bind_world(result.world)
	if not world.story.seen.has("arrival"): _open_story("arrival")
	hud.show_notice("Legacy factory imported; old file preserved. Add inserters between belts and machines." if result.get("legacy", false) else "Factory restored.")
