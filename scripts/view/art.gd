extends RefCounted
## Shared illustrated materials. Draw helpers never modify simulation state.
const INK := Color("223331")
const STEEL := Color("52767a")
const STEEL_LIGHT := Color("8caaa4")
const COPPER := Color("bf8259")
const AMBER := Color("efbb70")
const STONE := Color("b4a78b")
const CREAM := Color("e6d9b7")
static var boxes: Dictionary = {}
# One antialiased mask replaces per-frame polygon construction and triangulation.
static var ellipse_mask: GradientTexture2D
static var shadow_mask: GradientTexture2D
static var grain: ImageTexture

static func box(canvas: CanvasItem, rect: Rect2, color: Color, radius: int = 4, border: Color = Color.TRANSPARENT) -> void:
	var key := "%s:%d:%s" % [color.to_html(), radius, border.to_html()]
	if not boxes.has(key):
		var style := StyleBoxFlat.new()
		style.bg_color = color
		style.set_corner_radius_all(radius)
		style.anti_aliasing = true
		style.border_color = border
		style.set_border_width_all(1 if border.a > 0 else 0)
		boxes[key] = style
	canvas.draw_style_box(boxes[key], rect)

static func ellipse(canvas: CanvasItem, center: Vector2, radius: Vector2, color: Color) -> void:
	if ellipse_mask == null:
		var gradient := Gradient.new()
		gradient.offsets = PackedFloat32Array([0.0, 0.98, 1.0])
		gradient.colors = PackedColorArray([Color.WHITE, Color.WHITE, Color(1, 1, 1, 0)])
		ellipse_mask = GradientTexture2D.new()
		ellipse_mask.gradient = gradient
		ellipse_mask.width = 128
		ellipse_mask.height = 128
		ellipse_mask.fill = GradientTexture2D.FILL_RADIAL
		ellipse_mask.fill_from = Vector2(0.5, 0.5)
		ellipse_mask.fill_to = Vector2(1, 0.5)
	canvas.draw_texture_rect(ellipse_mask, Rect2(center - radius, radius * 2), false, color)

static func shadow(canvas: CanvasItem, center: Vector2, radius: Vector2) -> void:
	if shadow_mask == null:
		var gradient := Gradient.new()
		gradient.offsets = PackedFloat32Array([0,0.4,0.8,1])
		gradient.colors = PackedColorArray([Color(0.04,0.07,0.10,0.34),Color(0.04,0.07,0.10,0.24),Color(0.04,0.07,0.10,0.07),Color(0.04,0.07,0.10,0)])
		shadow_mask = GradientTexture2D.new()
		shadow_mask.gradient = gradient
		shadow_mask.width = 128
		shadow_mask.height = 128
		shadow_mask.fill = GradientTexture2D.FILL_RADIAL
		shadow_mask.fill_from = Vector2(0.5,0.5)
		shadow_mask.fill_to = Vector2(1,0.5)
	canvas.draw_texture_rect(shadow_mask,Rect2(center+Vector2(3,4)-radius-Vector2(5,4),(radius+Vector2(5,4))*2),false)

static func glow(canvas: CanvasItem, center: Vector2, radius: float, color: Color, strength: float = 1.0) -> void:
	for i in range(3, 0, -1):
		var tint := color
		tint.a = 0.045 * strength * (4 - i)
		canvas.draw_circle(center, radius * i / 2.0, tint)

static func bolt(canvas: CanvasItem, at: Vector2) -> void:
	canvas.draw_circle(at + Vector2(0, 1), 1.9, INK)
	canvas.draw_circle(at, 1.4, STEEL_LIGHT)

static func smoke(canvas: CanvasItem, chimney: Vector2, time: float, seed_value: int) -> void:
	for i in range(5):
		var age := fposmod(time * 0.27 + i * 0.20 + seed_value * 0.13, 1.0)
		var drift := Vector2(age * 10 + sin(age * 5 + i) * 2, -age * 36)
		canvas.draw_circle(chimney + drift, 2.5 + age * 6, Color(0.70, 0.72, 0.63, (1.0 - age) * 0.12))

static func cast_shadow(canvas: CanvasItem, center: Vector2, size: Vector2, height: float) -> void:
	var projection := Vector2(0.78,0.52)*height
	for layer in range(2,-1,-1):
		var extent := size*0.5+Vector2.ONE*layer*2
		var offset := projection+Vector2.ONE*layer
		var a := center+Vector2(-extent.x,-extent.y)
		var b := center+Vector2(extent.x,-extent.y)
		var c := center+extent
		var d := center+Vector2(-extent.x,extent.y)
		canvas.draw_colored_polygon(PackedVector2Array([a,b,b+offset,c+offset,d+offset,d]),Color(0.035,0.065,0.10,0.08 if layer == 0 else 0.03))

static func surface_grain(canvas: CanvasItem, rect: Rect2, cell: Vector2i) -> void:
	if grain == null:
		var image := Image.create(128,128,false,Image.FORMAT_RGBA8)
		var rng := RandomNumberGenerator.new()
		rng.seed = 49217
		for x in range(128):
			for y in range(128):
				var value := rng.randf()
				image.set_pixel(x,y,Color(0.85,0.91,0.78,0.035*value) if value > 0.5 else Color(0.08,0.12,0.10,0.045*(1-value)))
		grain = ImageTexture.create_from_image(image)
	var uv := Rect2(Vector2(posmod(cell.x*48,128),posmod(cell.y*48,128)),rect.size)
	canvas.draw_texture_rect_region(grain,rect,uv)
