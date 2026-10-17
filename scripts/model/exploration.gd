extends RefCounted
## Coarse exploration cells keep save size independent from generated terrain caches.
const SIZE := 8
var cells: Dictionary = {}
var last := Vector2i(2147483647, 2147483647)

func coordinate(position: Vector2) -> Vector2i:
	return Vector2i(floori(position.x / SIZE), floori(position.y / SIZE))

func reveal(position: Vector2) -> void:
	var center := coordinate(position)
	if center == last: return
	last = center
	for x in range(-2, 3):
		for y in range(-2, 3):
			if x * x + y * y <= 5: cells[center + Vector2i(x, y)] = true

func known(position: Vector2) -> bool:
	return cells.has(coordinate(position))

func serialize() -> Array:
	var result: Array = []
	for cell in cells: result.append([cell.x, cell.y])
	return result

func restore(data: Variant) -> bool:
	if not data is Array or data.size() > 100000: return false
	var restored: Dictionary = {}
	for entry in data:
		if not entry is Array or entry.size() != 2: return false
		for value in entry:
			if not (value is int or value is float): return false
			if not is_finite(float(value)) or absf(float(value)) > 125000 or float(value) != floorf(float(value)): return false
		restored[Vector2i(int(entry[0]), int(entry[1]))] = true
	cells = restored
	return true
