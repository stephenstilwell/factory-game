extends RefCounted

const TEXT := Color("ece8da")
const MUTED := Color("a7b5aa")
const ACCENT := Color("a2cdb3")
const GOLD := Color("e6bd7c")
const ERROR := Color("ef9b8d")

static func panel(color: Color = Color("1c2c30"), border: Color = Color("3c5356")) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(7)
	style.set_content_margin_all(12)
	style.shadow_color = Color(0.015, 0.025, 0.028, 0.38)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 4)
	style.border_width_top = 2
	return style

static func theme() -> Theme:
	var result := Theme.new()
	result.default_font_size = 16
	var frame := panel(Color("192b30"), Color("577471"))
	frame.border_width_top = 3
	result.set_stylebox("panel", "PanelContainer", frame)
	result.set_stylebox("normal", "Button", panel(Color("2c4146")))
	result.set_stylebox("hover", "Button", panel(Color("38555a"), ACCENT.darkened(0.3)))
	result.set_stylebox("pressed", "Button", panel(Color("3c655f"), ACCENT))
	result.set_stylebox("disabled", "Button", panel(Color("243438"), Color("304448")))
	for state in ["normal", "hover", "pressed", "disabled"]:
		var button_style: StyleBox = result.get_stylebox(state, "Button")
		button_style.shadow_size = 2
		button_style.shadow_offset = Vector2(0, 2)
		button_style.content_margin_top = 7
		button_style.content_margin_bottom = 7
		button_style.content_margin_left = 10
		button_style.content_margin_right = 10
	var focus := panel(Color.TRANSPARENT, GOLD)
	focus.set_content_margin_all(0)
	focus.shadow_size = 0
	focus.set_border_width_all(2)
	result.set_stylebox("focus", "Button", focus)
	result.set_stylebox("focus", "OptionButton", focus)
	result.set_color("font_hover_color", "Button", Color("fff3d7"))
	result.set_color("font_pressed_color", "Button", Color("fff3d7"))
	result.set_color("font_color", "Button", TEXT)
	result.set_color("font_disabled_color", "Button", MUTED.darkened(0.18))
	result.set_stylebox("normal", "LineEdit", panel(Color("152327")))
	result.set_stylebox("focus", "LineEdit", panel(Color("152327"), ACCENT))
	result.set_color("font_color", "Label", TEXT)
	for state in ["normal", "hover", "pressed", "disabled"]:
		result.set_stylebox(state, "OptionButton", result.get_stylebox(state, "Button"))
	result.set_color("font_color", "OptionButton", TEXT)
	result.set_color("font_placeholder_color", "LineEdit", MUTED.darkened(0.1))
	result.set_color("font_color", "LineEdit", TEXT)
	var track := panel(Color("172725"), Color("344b42"))
	track.set_content_margin_all(0)
	track.shadow_size = 0
	var fill := panel(Color("83ab90"), Color("a4c4a7"))
	fill.set_content_margin_all(0)
	fill.shadow_size = 0
	result.set_stylebox("background", "ProgressBar", track)
	result.set_stylebox("fill", "ProgressBar", fill)
	result.set_color("font_color", "ProgressBar", TEXT)
	var tooltip := panel(Color("101f24"), GOLD.darkened(0.4))
	tooltip.set_content_margin_all(12)
	result.set_stylebox("panel", "TooltipPanel", tooltip)
	result.set_color("font_color", "TooltipLabel", TEXT)
	result.set_font_size("font_size", "TooltipLabel", 14)
	result.set_stylebox("panel", "PopupMenu", panel(Color("17292f"), Color("6a8982")))
	result.set_stylebox("hover", "PopupMenu", panel(Color("35574e"), ACCENT.darkened(0.3)))
	result.set_color("font_color", "PopupMenu", TEXT)
	result.set_color("font_hover_color", "PopupMenu", Color("fff3d7"))
	for axis in ["VScrollBar", "HScrollBar"]:
		var rail := panel(Color("102025"), Color("263d40"))
		rail.set_content_margin_all(4)
		rail.shadow_size = 0
		result.set_stylebox("scroll", axis, rail)
		for state in ["grabber", "grabber_highlight", "grabber_pressed"]:
			var handle := panel(Color("78988c") if state == "grabber" else GOLD, Color.TRANSPARENT)
			handle.set_content_margin_all(4)
			handle.shadow_size = 0
			result.set_stylebox(state, axis, handle)
	return result

static func label(text: String, size: int = 16, color: Color = TEXT) -> Label:
	var result := Label.new()
	result.text = text
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", color)
	return result

static func button(parent: Node, text: String, callback: Callable) -> Button:
	var result := Button.new()
	result.text = text
	result.focus_mode = Control.FOCUS_NONE
	result.pressed.connect(callback)
	parent.add_child(result)
	return result

static func select(button: Button, active: bool) -> void:
	if button.has_meta("selected_style") and button.get_meta("selected_style") == active: return
	button.set_meta("selected_style", active)
	var normal := panel(Color("304a46") if active else Color("293d43"), GOLD if active else Color("455e62"))
	normal.border_width_bottom = 3 if active else 1
	normal.shadow_size = 2
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("disabled", normal if active else panel(Color("203237"), Color("394e52")))
	button.add_theme_color_override("font_disabled_color", TEXT if active else MUTED.darkened(0.18))
