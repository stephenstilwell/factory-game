extends Control
## Bounded milestone accents; drawing only, with no layout or world mutations.
var elapsed := 1.0
var reduced_motion := false
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	set_process(false)
func celebrate() -> void:
	elapsed = 1.0 if reduced_motion else 0.0
	set_process(not reduced_motion)
	queue_redraw()
func set_reduced_motion(enabled: bool) -> void:
	reduced_motion = enabled
	if enabled:
		elapsed = 1.0
		set_process(false)
		queue_redraw()
func _process(delta: float) -> void:
	elapsed = minf(1.0,elapsed + delta / 0.75)
	if not is_visible_in_tree(): elapsed = 1.0
	queue_redraw()
	if elapsed >= 1.0: set_process(false)
func _draw() -> void:
	if elapsed >= 1.0 or reduced_motion: return
	var alpha := (1.0-elapsed)*0.5
	draw_rect(Rect2(0,0,size.x,2),Color(0.9,0.7,0.45,alpha))
	var origin := Vector2(40,size.y*0.5)
	for index in range(10):
		var angle := TAU*index/10.0
		var direction := Vector2.from_angle(angle)
		var at := origin + direction*(12+elapsed*34)
		draw_line(at,at+direction*4,Color(0.93,0.76,0.5,alpha),1.5,true)

func finish() -> void:
	elapsed = 1.0
	set_process(false)
	queue_redraw()
