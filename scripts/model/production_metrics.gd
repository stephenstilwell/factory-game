extends RefCounted
## Bounded, transient per-second history. A load starts a new observation window.
const Catalog = preload("res://scripts/data/catalog.gd")
var buckets: Dictionary = {}
var start_tick := 0

func record(tick: int, flow: String, item: String, amount: int) -> void:
	if amount <= 0 or not Catalog.ITEMS.has(item): return
	var second := tick / 10
	if not buckets.has(second): buckets[second] = {"made": {}, "used": {}}
	var counts: Dictionary = buckets[second][flow]
	counts[item] = int(counts.get(item, 0)) + amount
	prune(tick)

func consume(tick: int, goods: Dictionary) -> void:
	for item in goods: record(tick, "used", item, int(goods[item]))

func prune(tick: int) -> void:
	var oldest := tick / 10 - 59
	for second in buckets.keys():
		if int(second) < oldest: buckets.erase(second)

func snapshot(tick: int) -> Dictionary:
	prune(tick)
	var result := {"made": {}, "used": {}, "seconds": maxf(1.0, minf(60.0, (tick - start_tick) / 10.0))}
	for bucket in buckets.values():
		for flow in ["made", "used"]:
			for item in bucket[flow]:
				result[flow][item] = int(result[flow].get(item, 0)) + int(bucket[flow][item])
	return result
