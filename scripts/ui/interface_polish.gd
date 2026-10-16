extends Node
## Presentation preferences and bounded interaction tweens; never delays input.
const Style = preload("res://scripts/ui/ui_style.gd")
const PATH := "user://presentation_settings.cfg"
var settings_path := PATH
var reduced_motion := false
var ambient_enabled := true
var view: Node2D
var interface: CanvasLayer
var tweens: Dictionary = {}
var reduced_control: CheckButton
var ambient_control: CheckButton

func configure(hud: CanvasLayer, world_view: Node2D) -> void:
	interface = hud
	view = world_view
	var config := ConfigFile.new()
	if config.load(settings_path) == OK:
		var motion = config.get_value("visuals", "reduced_motion", false)
		var ambient = config.get_value("visuals", "ambient_enabled", true)
		if motion is bool: reduced_motion = motion
		if ambient is bool: ambient_enabled = ambient
	var box := VBoxContainer.new()
	hud.pause_content.add_child(box)
	hud.pause_content.move_child(box, 1)
	box.add_child(Style.label("PRESENTATION", 13, Style.GOLD))
	reduced_control = CheckButton.new()
	reduced_control.text = "Reduced motion"
	reduced_control.tooltip_text = "Remove interface fades, pulses, and ambient drift. Essential machine direction and progress remain visible."
	reduced_control.button_pressed = reduced_motion
	box.add_child(reduced_control)
	reduced_control.toggled.connect(func(value): reduced_motion = value; apply_preferences(); save_preferences())
	ambient_control = CheckButton.new()
	ambient_control.text = "Ambient light, wildlife and birdsong"
	ambient_control.tooltip_text = "Soft light, wildlife, birdsong, drifting motes, and action effects. Turning this off keeps the world fully readable."
	ambient_control.button_pressed = ambient_enabled
	box.add_child(ambient_control)
	ambient_control.toggled.connect(func(value): ambient_enabled = value; apply_preferences(); save_preferences())
	for panel in [hud.workspace, hud.frontier_panel, hud.factory_panel, hud.story_panel, hud.survey, hud.pause_menu, hud.hotbar.picker]:
		panel.visibility_changed.connect(_panel_changed.bind(panel))
	_watch(hud)
	get_tree().node_added.connect(_node_added)
	apply_preferences()

func _node_added(node: Node) -> void:
	if node is BaseButton: call_deferred("_decorate_later", weakref(node))

func _decorate_later(reference: WeakRef) -> void:
	_decorate(reference.get_ref())

func _watch(node: Node) -> void:
	_decorate(node)
	for child in node.get_children(): _watch(child)

func _decorate(node: Node) -> void:
	if not is_instance_valid(interface) or not is_instance_valid(node) or not node is BaseButton or not interface.is_ancestor_of(node) or node.has_meta("interface_polish"): return
	node.set_meta("interface_polish", true)
	node.mouse_entered.connect(func(): _tint(node, Color(1.12, 1.10, 1.04), 0.1))
	node.mouse_exited.connect(func(): _tint(node, Color.WHITE, 0.14))
	node.button_down.connect(func(): _tint(node, Color(0.83, 0.9, 0.88), 0.05))
	node.button_up.connect(func(): _tint(node, Color.WHITE, 0.12))
	node.tree_exiting.connect(func(): _stop(node.get_instance_id()))

func _stop(id: int) -> void:
	if tweens.has(id):
		tweens[id].kill()
		tweens.erase(id)

func _tint(button: BaseButton, color: Color, duration: float) -> void:
	if reduced_motion or not button.is_visible_in_tree() or button.disabled: return
	var id := button.get_instance_id()
	_stop(id)
	var tween := create_tween()
	tweens[id] = tween
	tween.tween_property(button, "self_modulate", color, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.finished.connect(func(): tweens.erase(id))

func _panel_changed(panel: Control) -> void:
	var id := panel.get_instance_id()
	_stop(id)
	panel.modulate.a = 1.0
	if not panel.visible or reduced_motion: return
	panel.modulate.a = 0.78
	var tween := create_tween()
	tweens[id] = tween
	tween.tween_property(panel, "modulate:a", 1.0, 0.14)
	tween.finished.connect(func(): tweens.erase(id))

func apply_preferences() -> void:
	for id in tweens.keys(): _stop(id)
	if interface != null: _reset_colors(interface)
	if view != null:
		view.reduced_motion = reduced_motion
		view.ambient_enabled = ambient_enabled
		if reduced_motion or not ambient_enabled: view.effects.clear()

func _reset_colors(node: Node) -> void:
	if node is BaseButton: node.self_modulate = Color.WHITE
	if node is ColorRect or node == interface.workspace: node.modulate.a = 1.0
	for child in node.get_children(): _reset_colors(child)

func save_preferences() -> void:
	var config := ConfigFile.new()
	config.set_value("visuals", "reduced_motion", reduced_motion)
	config.set_value("visuals", "ambient_enabled", ambient_enabled)
	if config.save(settings_path) != OK: interface.show_notice("Could not save presentation preferences.")
