extends Node2D
## One reusable translucent preview, independent of placed world entities.
const Entity = preload("res://scripts/model/entity.gd")
const MachineArt = preload("res://scripts/view/machine_art.gd")
const DIRS := [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]
var preview: RefCounted

func show_building(kind: String, cell: Vector2i, facing: int, valid: bool) -> void:
	if preview == null or preview.kind != kind: preview = Entity.new(0, kind)
	preview.direction = facing
	position = (Vector2(cell) + Vector2.ONE * 0.5) * 48
	modulate = Color(1, 1, 1, 0.58) if valid else Color(1, 0.55, 0.42, 0.58)
	show()
	queue_redraw()

func _draw() -> void:
	if preview == null: return
	var direction: Vector2 = DIRS[preview.direction]
	MachineArt.draw(self, preview, Vector2.ZERO, 0.0, direction, false)
	var at := direction * 28
	draw_polyline(PackedVector2Array([at - direction * 6 + direction.orthogonal() * 6, at, at - direction * 6 - direction.orthogonal() * 6]), Color("e5edce"), 2, true)
