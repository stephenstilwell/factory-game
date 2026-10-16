extends Node2D
const Preview = preload("res://scripts/view/placement_preview.gd")
var world: RefCounted
var visible_cells := Rect2i()
var paste_origin := Vector2i.ZERO
var pasting := false
var nodes: Dictionary = {}

func _process(_delta: float) -> void:
	if world == null: return
	var wanted: Dictionary = world.plans.ghosts.duplicate()
	if pasting:
		for record in world.plans.clipboard:
			var cell := paste_origin + Vector2i(record.x, record.y)
			wanted[cell] = record
	for cell in nodes.keys():
		if not wanted.has(cell):
			nodes[cell].queue_free()
			nodes.erase(cell)
	for cell in wanted:
		if not visible_cells.has_point(cell): continue
		if not nodes.has(cell):
			var preview := Preview.new()
			add_child(preview)
			nodes[cell] = preview
		var record: Dictionary = wanted[cell]
		var valid := world.at(cell) == null and world.settlements.at(cell) == null
		nodes[cell].show_building(record.kind, cell, int(record.direction), valid)
		nodes[cell].preview.underground_exit = bool(record.underground_exit)
		nodes[cell].modulate = Color(0.5, 0.85, 1.0, 0.38) if valid else Color(1.0, 0.4, 0.3, 0.45)
	for cell in nodes: nodes[cell].visible = visible_cells.has_point(cell) and wanted.has(cell)
