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
	style.set_corner_radius_all(8)
	style.set_content_margin_all(12)
	style.shadow_color = Color(0.02, 0.04, 0.035, 0.16)
	style.shadow_size = 2
	style.shadow_offset = Vector2(0, 2)
	return style

static func theme() -> Theme:
	var result := Theme.new()
	result.default_font_size = 16
	result.set_stylebox("panel", "PanelContainer", panel())
	result.set_stylebox("normal", "Button", panel(Color("2c4146")))
	result.set_stylebox("hover", "Button", panel(Color("38555a"), ACCENT.darkened(0.3)))
	result.set_stylebox("pressed", "Button", panel(Color("3c655f"), ACCENT))
	result.set_stylebox("disabled", "Button", panel(Color("243438"), Color("304448")))
	for state in ["normal", "hover", "pressed", "disabled"]:
		var button_style: StyleBox = result.get_stylebox(state, "Button")
		button_style.content_margin_top = 7
		button_style.content_margin_bottom = 7
		button_style.content_margin_left = 10
		button_style.content_margin_right = 10
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
