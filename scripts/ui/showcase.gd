extends Control
## Fixed-size, reusable product / restoration / equipment illustration.
const Icon = preload("res://scripts/ui/item_icon.gd")
const Illustration = preload("res://scripts/ui/showcase_art.gd")
const Catalog = preload("res://scripts/data/catalog.gd")
const Style = preload("res://scripts/ui/ui_style.gd")
var item_icon: Control
var illustration: Node2D
var subject := ""
var domain := ""
var restored := true
var reduced_motion := false
var flash := 0.0
var charge := 0.0
var charge_colors: Array[Color] = []

func _ready() -> void:
	custom_minimum_size = Vector2(112, 112)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	item_icon = Icon.new()
	add_child(item_icon)
	illustration = Illustration.new()
	add_child(illustration)
	resized.connect(_layout)
	_layout()
	set_process(false)

func _layout() -> void:
	if item_icon == null: return
	item_icon.position = Vector2(12,12)
	item_icon.size = size - Vector2(24,24)
	illustration.position = size / 2
	illustration.scale = Vector2.ONE * minf(size.x, size.y) / (174.0 if domain == "site" else 110.0)
	queue_redraw()

func present(kind: String, id: String, is_restored: bool = true) -> void:
	if domain == kind and subject == id and restored == is_restored: return
	domain = kind
	subject = id
	restored = is_restored
	_layout()
	item_icon.visible = kind == "item"
	illustration.visible = kind != "item"
	if kind == "item":
		item_icon.item_id = id
		item_icon.queue_redraw()
	else: illustration.present(kind, id, is_restored)
	charge = 0.0
	flash = 0.0 if reduced_motion else 1.0
	set_process(flash > 0)
	queue_redraw()

func set_reduced_motion(enabled: bool) -> void:
	reduced_motion = enabled
	if enabled: flash = 0; charge = 0; set_process(false); queue_redraw()

func _process(delta: float) -> void:
	flash = maxf(0.0, flash - delta * 3.5)
	charge = maxf(0.0, charge - delta * 1.8)
	queue_redraw()
	if not is_visible_in_tree(): flash = 0; charge = 0
	if flash == 0 and charge == 0: set_process(false)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size), Color("202b31"))
	for x in range(12, int(size.x), 20): draw_line(Vector2(x,0),Vector2(x,size.y),Color(0.7,0.8,0.75,0.035))
	for y in range(12, int(size.y), 20): draw_line(Vector2(0,y),Vector2(size.x,y),Color(0.7,0.8,0.75,0.035))
	draw_line(Vector2(12,size.y-10),Vector2(size.x-12,size.y-10),Color(0.9,0.68,0.46,0.35),1)
	if charge > 0:
		for i in charge_colors.size():
			var t := clampf((1.0-charge)*1.6-float(i)*0.1,0.0,1.0)
			var start := Vector2(6, size.y * 0.65 + (i-2)*7)
			var at := start.lerp(size/2,t)
			at.y -= sin(t*PI)*16
			draw_circle(at,3.0,Color(charge_colors[i],1.0-t*0.7))
	if flash > 0: draw_rect(Rect2(Vector2.ONE,size-Vector2.ONE*2),Color(0.9,0.68,0.46,flash*0.7),false,2)

func absorb(items: Array) -> void:
	if reduced_motion: return
	charge_colors.clear()
	for i in range(mini(5,items.size())): charge_colors.append(Catalog.color(items[i]))
	charge = 1.0
	set_process(true)
	queue_redraw()
