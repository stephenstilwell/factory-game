extends RefCounted
## Capacity counts individual items. Transactions check the entire exchange first.
const Catalog = preload("res://scripts/data/catalog.gd")

var capacity: int
var contents: Dictionary = {}

func _init(limit: int = 10000) -> void:
	capacity = maxi(0, limit)

func count(id: String) -> int:
	return int(contents.get(id, 0))

func total() -> int:
	var result := 0
	for amount in contents.values(): result += int(amount)
	return result

func has_all(required: Dictionary) -> bool:
	if not _valid_counts(required): return false
	for id in required:
		if count(id) < int(required[id]): return false
	return true

func can_exchange(consumed: Dictionary, produced: Dictionary) -> bool:
	if not _valid_counts(produced): return false
	if not has_all(consumed): return false
	var size := total()
	for amount in consumed.values(): size -= int(amount)
	for amount in produced.values(): size += int(amount)
	return size <= capacity

func exchange(consumed: Dictionary, produced: Dictionary) -> bool:
	if not can_exchange(consumed, produced): return false
	for id in consumed: remove(id, int(consumed[id]))
	for id in produced: add(id, int(produced[id]))
	return true

func add(id: String, amount: int = 1) -> int:
	if not Catalog.ITEMS.has(id): return 0
	var accepted := clampi(amount, 0, capacity - total())
	if accepted > 0: contents[id] = count(id) + accepted
	return accepted

func remove(id: String, amount: int = 1) -> int:
	var removed := clampi(amount, 0, count(id))
	var remaining := count(id) - removed
	if remaining > 0: contents[id] = remaining
	else: contents.erase(id)
	return removed

func move_to(other: RefCounted, id: String, amount: int = 1) -> int:
	if other == self or amount <= 0: return 0
	var accepted: int = other.add(id, mini(amount, count(id)))
	remove(id, accepted)
	return accepted

func _valid_counts(data: Dictionary) -> bool:
	for id in data:
		if not Catalog.ITEMS.has(id) or not data[id] is int or int(data[id]) <= 0: return false
	return true
