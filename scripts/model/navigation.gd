extends RefCounted
## Saved named destinations; independent from terrain generation and discoveries.
const MAX_PINS := 32
var pins: Dictionary = {}
var active := 0
var next_id := 1

func add(cell: Vector2i, title: String = "") -> int:
	if next_id >= 1000000 or pins.size() >= MAX_PINS or absi(cell.x) > 1000000 or absi(cell.y) > 1000000: return 0
	var id := next_id
	next_id += 1
	pins[id] = {"cell": cell, "title": clean_title(title, id)}
	active = id
	return id

func clean_title(title: String, id: int) -> String:
	var result := title.strip_edges().replace("\n", " ").replace("\r", " ").left(40)
	return result if not result.is_empty() else "Map pin %d" % id

func rename(id: int, title: String) -> void:
	if pins.has(id): pins[id].title = clean_title(title, id)

func remove(id: int) -> void:
	pins.erase(id)
	if active == id: active = 0

func track(id: int) -> void:
	active = id if pins.has(id) else 0

func target() -> Dictionary:
	return pins.get(active, {})

func serialize() -> Dictionary:
	var records: Array = []
	for id in pins: records.append({"id": id, "x": pins[id].cell.x, "y": pins[id].cell.y, "title": pins[id].title})
	return {"pins": records, "active": active, "next_id": next_id}

func restore(data: Variant) -> bool:
	if not data is Dictionary or not data.get("pins") is Array or data.get("pins").size() > MAX_PINS: return false
	var restored: Dictionary = {}
	var highest := 0
	for record in data.pins:
		if not record is Dictionary or not record.get("title") is String or record.title.length() > 40: return false
		for key in ["id", "x", "y"]:
			if not integer(record.get(key), -1000000, 1000000): return false
		var id := int(record.id)
		if id <= 0 or restored.has(id): return false
		if record.title != clean_title(record.title, id): return false
		restored[id] = {"cell": Vector2i(int(record.x), int(record.y)), "title": record.title}
		highest = maxi(highest, id)
	if not integer(data.get("active", 0), 0, 1000000) or not integer(data.get("next_id", 1), 1, 1000000): return false
	var chosen := int(data.get("active", 0))
	if chosen != 0 and not restored.has(chosen): return false
	if int(data.get("next_id", 1)) <= highest: return false
	pins = restored
	active = chosen
	next_id = int(data.get("next_id", 1))
	return true

func integer(value: Variant, minimum: int, maximum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floorf(float(value)) and value >= minimum and value <= maximum
