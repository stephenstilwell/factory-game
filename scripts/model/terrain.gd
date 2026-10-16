extends RefCounted
## Terrain is generated on demand in 16x16 chunks. Only depletion overrides are saved.

const CHUNK_SIZE := 16
const START_PATCHES := [
	[Vector2i(14, 16), 4, "iron_ore"], [Vector2i(28, 23), 4, "copper_ore"],
	[Vector2i(9, 23), 3, "coal"], [Vector2i(26, 9), 3, "stone"],
]

var seed_value := 74103
const GENERATOR_VERSION := 2
const REGION_SIZE := 96
const MAX_RADIUS := 16
const RESOURCE_IDS := ["iron_ore", "copper_ore", "coal", "stone"]
var stock_scale := 4
var generator_version := 1
var chunks: Dictionary = {}
var depleted: Dictionary = {}
var dirty_chunks: Dictionary = {}

func _init(world_seed: int = 74103) -> void:
	seed_value = world_seed

func chunk_at(cell: Vector2i) -> Vector2i:
	return Vector2i(floori(float(cell.x) / CHUNK_SIZE), floori(float(cell.y) / CHUNK_SIZE))

func tile(cell: Vector2i) -> Dictionary:
	var chunk := chunk_at(cell)
	if not chunks.has(chunk): _generate(chunk)
	var data: Dictionary = chunks[chunk].get(cell, {})
	if data.is_empty(): return {}
	var amount: int = int(depleted.get(cell, data.amount))
	return {"item": data.item, "amount": amount} if amount > 0 else {}

func mine(cell: Vector2i) -> String:
	var data := tile(cell)
	if data.is_empty(): return ""
	depleted[cell] = int(data.amount) - 1
	dirty_chunks[chunk_at(cell)] = true
	return data.item

func _generate(chunk: Vector2i) -> void:
	if generator_version == 2:
		_generate_frontier(chunk)
		return
	var deposits: Dictionary = {}
	# Neighbor patch centers allow deposits to cross chunk boundaries seamlessly.
	var patches: Array = START_PATCHES.duplicate()
	for cx in range(chunk.x - 1, chunk.x + 2):
		for cy in range(chunk.y - 1, chunk.y + 2):
			if cx >= -1 and cx <= 3 and cy >= -1 and cy <= 3: continue
			var rng := RandomNumberGenerator.new()
			rng.seed = seed_value + cx * 73856093 + cy * 19349663
			if rng.randf() > 0.38: continue
			patches.append([Vector2i(cx * 16 + rng.randi_range(2, 13), cy * 16 + rng.randi_range(2, 13)), rng.randi_range(2, 5), ["iron_ore", "copper_ore", "coal", "stone"][rng.randi_range(0, 3)]])
	for x in range(chunk.x * 16, chunk.x * 16 + 16):
		for y in range(chunk.y * 16, chunk.y * 16 + 16):
			var cell := Vector2i(x, y)
			for patch in patches:
				if Vector2(cell - patch[0]).length() <= float(patch[1]):
					deposits[cell] = {"item": patch[2], "amount": (120 + posmod(x * 17 + y * 31 + seed_value, 100)) * stock_scale}
	chunks[chunk] = deposits

func _rng(coordinate: Vector2i, salt: int = 0) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + coordinate.x * 73856093 + coordinate.y * 19349663 + salt * 83492791
	return rng

func _region_at(cell: Vector2i) -> Vector2i:
	return Vector2i(floori(float(cell.x) / REGION_SIZE), floori(float(cell.y) / REGION_SIZE))

func _frontier_patches(region: Vector2i) -> Array:
	# One of each material per region, in shuffled quadrants with safe spacing.
	var rng := _rng(region, 17)
	var resources: Array = RESOURCE_IDS.duplicate()
	for i in range(resources.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap = resources[i]
		resources[i] = resources[j]
		resources[j] = swap
	var result: Array = []
	for i in range(4):
		var center := region * REGION_SIZE + Vector2i((i % 2) * 48 + rng.randi_range(16, 32), (i / 2) * 48 + rng.randi_range(16, 32))
		var radius := rng.randi_range(6, 10) + mini(4, floori(Vector2(center).distance_to(Vector2(24, 12)) / 256.0))
		# Keep lessons, walking space, and settlement landmarks free of random overlap.
		if Rect2i(-8, -8, 56, 48).grow(MAX_RADIUS).has_point(center): continue
		result.append([center, radius, resources[i]])
	return result

func _patches_for_area(minimum: Vector2i, maximum: Vector2i) -> Array:
	var patches: Array = START_PATCHES.duplicate()
	var first := _region_at(minimum - Vector2i.ONE * MAX_RADIUS)
	var last := _region_at(maximum + Vector2i.ONE * MAX_RADIUS)
	for x in range(first.x, last.x + 1):
		for y in range(first.y, last.y + 1): patches.append_array(_frontier_patches(Vector2i(x, y)))
	return patches

func _patch_contains(cell: Vector2i, patch: Array) -> bool:
	var offset := Vector2(cell - patch[0])
	# Angular lobes produce irregular edges without holes or chunk seams.
	var phase := float(posmod(seed_value + patch[0].x * 7 + patch[0].y * 13, 628)) / 100.0
	var angle := offset.angle()
	var edge := float(patch[1]) * (0.88 + 0.07 * sin(angle * 3.0 + phase) + 0.05 * sin(angle * 5.0 - phase))
	return offset.length() <= edge

func _generate_frontier(chunk: Vector2i) -> void:
	var deposits: Dictionary = {}
	var minimum := chunk * CHUNK_SIZE
	var patches := _patches_for_area(minimum, minimum + Vector2i.ONE * (CHUNK_SIZE - 1))
	for patch in patches:
		var center: Vector2i = patch[0]
		var radius: int = patch[1]
		var depth := mini(4, floori(Vector2(center).distance_to(Vector2(24, 12)) / 256.0))
		var starter: bool = patch in START_PATCHES
		for x in range(maxi(minimum.x, center.x - radius), mini(minimum.x + CHUNK_SIZE, center.x + radius + 1)):
			for y in range(maxi(minimum.y, center.y - radius), mini(minimum.y + CHUNK_SIZE, center.y + radius + 1)):
				var cell := Vector2i(x, y)
				if not _patch_contains(cell, patch): continue
				var variation := posmod(x * 17 + y * 31 + seed_value, 180)
				deposits[cell] = {"item": patch[2], "amount": ((180 if starter else 450 + depth * 450) + variation) * stock_scale}
	chunks[chunk] = deposits

func find_resource(item: String, origin: Vector2i, region_radius: int = 3) -> Dictionary:
	if item not in RESOURCE_IDS: return {}
	# An explicit, bounded survey: no persistent map nodes or per-frame world scan.
	var region := _region_at(origin)
	var bounds := Rect2i((region - Vector2i.ONE * region_radius) * REGION_SIZE, Vector2i.ONE * REGION_SIZE * (region_radius * 2 + 1))
	var patches := _patches_for_area((region - Vector2i.ONE * region_radius) * REGION_SIZE, (region + Vector2i.ONE * (region_radius + 1)) * REGION_SIZE - Vector2i.ONE) if generator_version == 2 else _legacy_survey_patches(origin, region_radius * REGION_SIZE)
	patches = patches.filter(func(patch): return patch[2] == item and bounds.has_point(patch[0]))
	patches.sort_custom(func(a, b): return Vector2(a[0]).distance_squared_to(Vector2(origin)) < Vector2(b[0]).distance_squared_to(Vector2(origin)))
	for patch in patches:
		var center: Vector2i = patch[0]
		var radius: int = patch[1]
		var nearest := Vector2i.ZERO
		var distance := INF
		var remaining := 0
		for x in range(center.x - radius, center.x + radius + 1):
			for y in range(center.y - radius, center.y + radius + 1):
				var cell := Vector2i(x, y)
				if cell.distance_squared_to(center) > radius * radius: continue
				var data := tile(cell)
				if data.is_empty() or data.item != item: continue
				remaining += int(data.amount)
				var candidate := Vector2(cell).distance_squared_to(Vector2(origin))
				if candidate < distance:
					distance = candidate
					nearest = cell
		if remaining > 0: return {"item": item, "cell": nearest, "remaining": remaining, "distance": sqrt(distance)}
	return {}

func _legacy_survey_patches(origin: Vector2i, radius: int) -> Array:
	var patches: Array = START_PATCHES.duplicate()
	var first := chunk_at(origin - Vector2i.ONE * radius)
	var last := chunk_at(origin + Vector2i.ONE * radius)
	for cx in range(first.x, last.x + 1):
		for cy in range(first.y, last.y + 1):
			if cx >= -1 and cx <= 3 and cy >= -1 and cy <= 3: continue
			var rng := _rng(Vector2i(cx, cy))
			if rng.randf() > 0.38: continue
			patches.append([Vector2i(cx * 16 + rng.randi_range(2, 13), cy * 16 + rng.randi_range(2, 13)), rng.randi_range(2, 5), RESOURCE_IDS[rng.randi_range(0, 3)]])
	return patches

func patch_at(cell: Vector2i) -> Dictionary:
	var candidates := _patches_for_area(cell, cell) if generator_version == 2 else _legacy_survey_patches(cell, CHUNK_SIZE)
	# Later patches take precedence, matching chunk generation.
	candidates.reverse()
	for patch in candidates:
		var inside := _patch_contains(cell, patch) if generator_version == 2 else Vector2(cell - patch[0]).length() <= float(patch[1])
		if inside: return {"center": patch[0], "item": patch[2]}
	return {}

func has_patch(center: Vector2i, item: String) -> bool:
	var candidates := _patches_for_area(center, center) if generator_version == 2 else _legacy_survey_patches(center, CHUNK_SIZE)
	for patch in candidates:
		if patch[0] == center and patch[2] == item: return true
	return false
