extends RefCounted
## Shared Oldbridge interface tokens and component roles.
const TEXT := Color("f0eee7")
const MUTED := Color("a9b1ba")
const ACCENT := Color("b3cdbd")
const GOLD := Color("e5ae78")
const ERROR := Color("ed9a8d")
const BACKGROUND := Color("171c23")
const SURFACE := Color("222a33")
const BORDER := Color("3c4753")
const FONT = preload("res://assets/fonts/Manrope.ttf")
static var heading_font: FontVariation
static var body_font: FontVariation
static var tile_styles: Dictionary = {}

static func panel(color: Color = BACKGROUND, border: Color = BORDER) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(12)
	style.shadow_color = Color(0.015, 0.02, 0.025, 0.32)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 3)
	return style

static func _button_box(color: Color, border: Color) -> StyleBoxFlat:
	var style := panel(color, border)
	style.shadow_size = 0
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	return style

static func theme() -> Theme:
	var result := Theme.new()
	if body_font == null:
		body_font = FontVariation.new()
		body_font.base_font = FONT
		body_font.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 500.0}
	result.default_font = body_font
	result.default_font_size = 16
	result.set_stylebox("panel", "PanelContainer", panel())
	for state in ["normal", "hover", "pressed", "disabled"]:
		var color: Color = {"normal": SURFACE, "hover": Color("33404b"), "pressed": Color("403b34"), "disabled": Color("1b2128")}[state]
		var edge: Color = {"normal": BORDER, "hover": GOLD.darkened(0.25), "pressed": GOLD, "disabled": Color("303841")}[state]
		result.set_stylebox(state, "Button", _button_box(color, edge))
		result.set_stylebox(state, "OptionButton", _button_box(color, edge))
	for type in ["Button", "OptionButton", "CheckButton", "CheckBox"]:
		result.set_color("font_color", type, TEXT)
		result.set_color("font_hover_color", type, Color.WHITE)
		result.set_color("font_pressed_color", type, GOLD)
		result.set_color("font_disabled_color", type, Color("737e89"))
	var focus := _button_box(Color.TRANSPARENT, GOLD)
	focus.set_border_width_all(2)
	for type in ["Button", "OptionButton", "LineEdit"]:
		result.set_stylebox("focus", type, focus)
	result.set_stylebox("normal", "LineEdit", _button_box(Color("11171e"), BORDER))
	result.set_stylebox("read_only", "LineEdit", _button_box(BACKGROUND, BORDER))
	result.set_color("font_color", "LineEdit", TEXT)
	result.set_color("font_placeholder_color", "LineEdit", MUTED.darkened(0.12))
	result.set_color("caret_color", "LineEdit", GOLD)
	result.set_color("selection_color", "LineEdit", Color("4a5149"))
	result.set_color("font_color", "Label", TEXT)
	var track := panel(Color("10161c"), Color.TRANSPARENT)
	track.set_content_margin_all(0)
	track.set_border_width_all(0)
	track.set_corner_radius_all(2)
	track.shadow_size = 0
	var fill := track.duplicate()
	fill.bg_color = ACCENT.darkened(0.2)
	result.set_stylebox("background", "ProgressBar", track)
	result.set_stylebox("fill", "ProgressBar", fill)
	result.set_color("font_color", "ProgressBar", TEXT)
	result.set_font_size("font_size", "ProgressBar", 12)
	var tooltip := panel(Color("11171e"), GOLD.darkened(0.45))
	tooltip.set_content_margin_all(14)
	result.set_stylebox("panel", "TooltipPanel", tooltip)
	result.set_color("font_color", "TooltipLabel", TEXT)
	result.set_font_size("font_size", "TooltipLabel", 14)
	result.set_stylebox("panel", "PopupMenu", panel(BACKGROUND))
	result.set_stylebox("hover", "PopupMenu", _button_box(SURFACE.lightened(0.12), Color.TRANSPARENT))
	result.set_color("font_color", "PopupMenu", TEXT)
	result.set_color("font_hover_color", "PopupMenu", GOLD)
	var separator := StyleBoxLine.new()
	separator.color = BORDER
	separator.thickness = 1
	result.set_stylebox("separator", "HSeparator", separator)
	for axis in ["VScrollBar", "HScrollBar"]:
		var rail := panel(Color("11171e"), Color.TRANSPARENT)
		rail.set_content_margin_all(4)
		rail.set_border_width_all(0)
		rail.shadow_size = 0
		result.set_stylebox("scroll", axis, rail)
		for state in ["grabber", "grabber_highlight", "grabber_pressed"]:
			var handle := rail.duplicate()
			handle.bg_color = Color("63717d") if state == "grabber" else GOLD
			result.set_stylebox(state, axis, handle)
	return result

static func label(text: String, size: int = 16, color: Color = TEXT) -> Label:
	var result := Label.new()
	result.text = text
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", color)
	if size >= 20:
		if heading_font == null:
			heading_font = FontVariation.new()
			heading_font.base_font = FONT
			heading_font.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 700.0}
		result.add_theme_font_override("font", heading_font)
	return result

static func button(parent: Node, text: String, callback: Callable) -> Button:
	var result := Button.new()
	result.text = text
	result.focus_mode = Control.FOCUS_NONE
	result.pressed.connect(callback)
	parent.add_child(result)
	return result

static func action(button: Button, role: String = "primary") -> void:
	var color := GOLD if role == "primary" else ERROR
	for state in ["normal", "hover", "pressed", "disabled"]:
		var base := color if role == "primary" else Color("38282a")
		if state == "hover": base = base.lightened(0.12)
		if state == "pressed": base = base.darkened(0.12)
		if state == "disabled": base = SURFACE
		button.add_theme_stylebox_override(state, _button_box(base, color.darkened(0.3) if state != "disabled" else BORDER))
	button.add_theme_color_override("font_color", BACKGROUND if role == "primary" else ERROR)
	button.add_theme_color_override("font_hover_color", BACKGROUND if role == "primary" else TEXT)
	button.add_theme_color_override("font_pressed_color", BACKGROUND if role == "primary" else TEXT)

static func badge(label_node: Label, color: Color = ACCENT, padding: int = 8) -> void:
	var style := _button_box(Color(color, 0.09), Color(color, 0.22))
	style.content_margin_left = padding
	style.content_margin_right = padding
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	label_node.add_theme_stylebox_override("normal", style)
	label_node.add_theme_color_override("font_color", color)

static func tile(selected: bool, hovered: bool = false) -> StyleBoxFlat:
	var key := int(selected) * 2 + int(hovered)
	if not tile_styles.has(key):
		var style := _button_box(Color("363d41") if selected else (Color("303c47") if hovered else Color("202832")), GOLD if selected else (Color("697987") if hovered else BORDER))
		style.border_width_bottom = 3 if selected else 1
		tile_styles[key] = style
	return tile_styles[key]

static func select(button: Button, active: bool) -> void:
	if button.has_meta("selected_style") and button.get_meta("selected_style") == active: return
	button.set_meta("selected_style", active)
	var normal := _button_box(Color("343a3d") if active else Color("1d252d"), Color.TRANSPARENT)
	normal.border_width_bottom = 2
	normal.border_color = GOLD if active else BORDER
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("disabled", normal)
	button.add_theme_color_override("font_color", GOLD if active else MUTED)
	button.add_theme_color_override("font_disabled_color", TEXT if active else MUTED.darkened(0.18))
