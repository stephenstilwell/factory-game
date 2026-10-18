extends RefCounted
## Derived topology; only generator reserves and installed retrofits are saved.
const Catalog = preload("res://scripts/data/catalog.gd")
const COST := {"steel": 2, "wire": 4}
const LOAD := {"drill": 2, "furnace": 4, "assembler": 3, "lab": 2}
const FUEL_ENERGY := 2400
const GENERATOR_RATE := 8
const LINK_RADIUS := 6
const SERVICE_RADIUS := 3
var revision := -1
var members: Dictionary = {}
var networks: Dictionary = {}
var links: Array = []
var granted: Dictionary = {}
var allocations: Dictionary = {}

func rebuild(world: RefCounted) -> void:
	if revision == world.navigation_revision: return
	revision = world.navigation_revision
	members.clear()
	networks.clear()
	links.clear()
	var poles: Array = world.by_kind.power_pole.duplicate()
	poles.sort()
	for id in poles:
		if members.has(id) or world.entities[id].health <= 0: continue
		var network := {"generators": [], "consumers": [], "demand": 0, "supplied": 0, "capacity": 0}
		networks[id] = network
		var queue: Array = [id]
		members[id] = id
		var index := 0
		while index < queue.size():
			var pole = world.entities[queue[index]]
			index += 1
			for x in range(-LINK_RADIUS, LINK_RADIUS + 1):
				for y in range(-LINK_RADIUS, LINK_RADIUS + 1):
					if x * x + y * y > LINK_RADIUS * LINK_RADIUS: continue
					var neighbor = world.at(pole.cell + Vector2i(x, y))
					if neighbor == null or neighbor.kind != "power_pole" or neighbor.health <= 0 or members.has(neighbor.id): continue
					members[neighbor.id] = id
					queue.append(neighbor.id)
					links.append([pole.cell, neighbor.cell])
	for kind in ["generator", "drill", "furnace", "assembler", "lab"]:
		for id in world.by_kind[kind]:
			var entity = world.entities[id]
			if entity.health <= 0 or (kind != "generator" and not entity.electric_mode): continue
			var best := 0
			var distance := 1000
			for x in range(-SERVICE_RADIUS, SERVICE_RADIUS + 1):
				for y in range(-SERVICE_RADIUS, SERVICE_RADIUS + 1):
					var squared := x * x + y * y
					if squared > SERVICE_RADIUS * SERVICE_RADIUS: continue
					var pole = world.at(entity.cell + Vector2i(x, y))
					if pole == null or pole.kind != "power_pole" or not members.has(pole.id): continue
					if squared < distance or (squared == distance and pole.id < best):
						best = pole.id
						distance = squared
			if best == 0: continue
			members[id] = members[best]
			networks[members[id]]["generators" if kind == "generator" else "consumers"].append(id)
			links.append([world.entities[best].cell, entity.cell])
	for network in networks.values():
		network.generators.sort()
		network.consumers.sort()

func wants_work(world: RefCounted, entity: RefCounted) -> bool:
	if entity.health <= 0: return false
	if entity.kind == "lab": return not world.current_research().is_empty() and entity.inventory.count("science") > 0
	if entity.kind == "drill": return not world.terrain.tile(entity.cell).is_empty() and entity.output.total() < entity.output.capacity
	var recipe: Dictionary = Catalog.RECIPES[entity.recipe]
	return entity.inventory.has_all(recipe["in"]) and entity.output.can_exchange({}, recipe["out"])

func step(world: RefCounted) -> void:
	rebuild(world)
	granted.clear()
	allocations.clear()
	for id in world.by_kind.generator:
		var generator = world.entities[id]
		generator.status = "Disabled - repair with H" if generator.health <= 0 else ("Disconnected - place a pole within 3 tiles" if not members.has(id) else "Idle - no demand")
	for network in networks.values():
		network.demand = 0
		network.supplied = 0
		network.capacity = 0
		var remaining: Dictionary = {}
		for id in network.generators:
			var generator = world.entities[id]
			var capacity := mini(GENERATOR_RATE, generator.energy + generator.inventory.count("coal") * FUEL_ENERGY)
			remaining[id] = capacity
			network.capacity += capacity
		var reserved := 0
		var consumers: Array = network.consumers
		for offset in range(consumers.size()):
			var id: int = consumers[(world.ticks + offset) % consumers.size()]
			var entity = world.entities[id]
			if not wants_work(world, entity): continue
			var demand: int = LOAD[entity.kind]
			network.demand += demand
			if network.capacity - reserved < demand: continue
			var needed := demand
			var allocation: Array = []
			for generator_id in network.generators:
				var use := mini(needed, int(remaining[generator_id]))
				if use <= 0: continue
				allocation.append([generator_id, use])
				remaining[generator_id] -= use
				needed -= use
				if needed == 0: break
			granted[id] = true
			allocations[id] = allocation
			reserved += demand
		for id in network.generators:
			var generator = world.entities[id]
			if generator.energy == 0 and generator.inventory.count("coal") == 0: generator.status = "No generator fuel - load coal/charcoal"

func consume(world: RefCounted, entity: RefCounted) -> bool:
	if not allocations.has(entity.id):
		entity.status = reason(world, entity)
		return false
	for pair in allocations[entity.id]:
		var generator = world.entities[pair[0]]
		var use: int = pair[1]
		if generator.energy < use:
			generator.inventory.remove("coal", 1)
			generator.energy += FUEL_ENERGY
			world.metrics.record(world.ticks, "used", "coal", 1)
		generator.energy -= use
		generator.status = "Generating - supplying district"
	networks[members[entity.id]].supplied += int(LOAD[entity.kind])
	allocations.erase(entity.id)
	world.settlements.homecoming.observe_work(world,entity)
	return true

func reason(world: RefCounted, entity: RefCounted) -> String:
	rebuild(world)
	if not members.has(entity.id): return "Disconnected - place a pole within 3 tiles"
	var network: Dictionary = networks[members[entity.id]]
	if network.generators.is_empty(): return "No generator on this network"
	if not wants_work(world, entity): return "Connected - idle"
	if not granted.has(entity.id): return "Power shortage - add fuel or generation"
	return "Powered"

func retrofit_reason(world: RefCounted, entity: RefCounted) -> String:
	if not LOAD.has(entity.kind): return "This building has no electric drive."
	if entity.electric_mode: return "Electric drive installed."
	if "metallurgy" not in world.researched: return "Research Foundry craft [T] first."
	if not world.in_reach(entity.cell): return "Walk closer to retrofit."
	if entity.health <= 0: return "Repair this machine first."
	if not world.player.has_all(COST): return "Needs 2 steel and 4 wire."
	return ""

func retrofit(world: RefCounted, entity: RefCounted) -> bool:
	var blocker := retrofit_reason(world, entity)
	if not blocker.is_empty():
		world.message.emit(blocker)
		return false
	if not world.player.exchange(COST, {}): return false
	world.metrics.consume(world.ticks, COST)
	entity.electric_mode = true
	revision = -1
	world.message.emit("Electric drive installed: double work speed. Connect poles to a fueled generator; no burner fuel is used. Pickup returns the drive's steel and wire.")
	world.feedback_requested.emit("success", entity.cell)
	world.changed.emit()
	return true

func summary(world: RefCounted) -> String:
	rebuild(world)
	var demand := 0
	var supplied := 0
	var capacity := 0
	for network in networks.values():
		demand += int(network.demand)
		supplied += int(network.supplied)
		capacity += int(network.capacity)
	return "DISTRICT POWER / %d networks / %d supplied of %d demand / %d available units per tick\nFoundry craft unlocks generators, poles and electric drives (2 steel + 4 wire in machine inspection)." % [networks.size(), supplied, demand, capacity]
