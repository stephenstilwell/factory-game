extends RefCounted
## Disposable map-only terrain cache. Never touches authoritative terrain or exploration.
const Terrain = preload("res://scripts/model/terrain.gd")
const MAX_CHUNKS := 512
const BATCH := 4
var terrain: RefCounted
var token := 0
var pending: Dictionary = {}
func bind(world: RefCounted) -> void:
	if token == world.get_instance_id(): return
	token = world.get_instance_id()
	terrain = Terrain.new(world.terrain.seed_value)
	pending.clear()
func known_chunk(world: RefCounted, chunk: Vector2i) -> bool:
	for x in range(2):
		for y in range(2):
			if world.exploration.cells.has(chunk * 2 + Vector2i(x, y)): return true
	return false
func request(world: RefCounted, chunk: Vector2i) -> Dictionary:
	bind(world)
	if not known_chunk(world, chunk): return {}
	if terrain.chunks.has(chunk): return terrain.chunks[chunk]
	if pending.size() < MAX_CHUNKS: pending[chunk] = true
	return {}
func step(world: RefCounted) -> bool:
	bind(world)
	var built := false
	var count := 0
	for chunk in pending.keys():
		pending.erase(chunk)
		if not known_chunk(world, chunk): continue
		terrain.tile(chunk * Terrain.CHUNK_SIZE)
		if terrain.chunks.size() > MAX_CHUNKS: terrain.chunks.erase(terrain.chunks.keys()[0])
		built = true
		count += 1
		if count == BATCH: break
	return built
