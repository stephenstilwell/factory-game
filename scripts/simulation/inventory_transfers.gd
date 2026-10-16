extends RefCounted
## Shared, authoritative transfer boundary for clicks, shortcuts, and drag/drop.
## UI descriptors contain stable owner IDs, never a mutable inventory reference.

const Catalog = preload("res://scripts/data/catalog.gd")

static func resolve(world: RefCounted, descriptor: Dictionary, destination: bool) -> Dictionary:
	if not descriptor.get("kind") is String: return {"error": "Invalid inventory descriptor."}
	var kind: String = descriptor.kind
	if kind == "player": return {"storage": world.player, "kind": kind}
	if kind == "site":
		var id = descriptor.get("site_id")
		if not id is String or not world.settlements.enabled or not world.settlements.sites.has(id): return {"error": "This town project is no longer available."}
		var site = world.settlements.sites[id]
		if not world.in_reach(site.port()): return {"error": "Out of reach. Walk closer to the delivery hatch."}
		return {"storage": site.inventory, "kind": kind, "site": site}
	if kind not in ["input", "output", "hand"]: return {"error": "Invalid inventory destination."}
	var owner_id = descriptor.get("entity_id")
	if not owner_id is int or not world.entities.has(owner_id): return {"error": "This machine has been removed."}
	var entity = world.entities[owner_id]
	if not world.in_reach(entity.cell): return {"error": "Out of reach. Walk closer to the machine."}
	if destination and kind in ["output", "hand"]: return {"error": "Outputs are for collection. Insert items into input or fuel."}
	if kind == "hand":
		if entity.kind != "inserter": return {"error": "This machine has no inserter hand."}
		return {"kind": kind, "entity": entity}
	return {"storage": entity.inventory if kind == "input" else entity.output, "kind": kind, "entity": entity}

static func inspect(world: RefCounted, item: String, source: Dictionary, target: Dictionary, token: int = 0) -> Dictionary:
	if token != 0 and token != world.get_instance_id(): return {"error": "The factory changed. Start the transfer again.", "limit": 0}
	if not Catalog.ITEMS.has(item): return {"error": "Unknown item.", "limit": 0}
	var from := resolve(world, source, false)
	var to := resolve(world, target, true)
	if from.has("error") or to.has("error"): return {"error": from.get("error", to.get("error", "")), "limit": 0}
	if from.has("storage") and from.storage == to.storage: return {"error": "Already in that inventory.", "limit": 0}
	var available: int = (1 if from.entity.carried == item else 0) if from.kind == "hand" else from.storage.count(item)
	if available == 0: return {"error": "There are no %s to transfer." % Catalog.item_name(item), "limit": 0}
	var limit: int = mini(available, to.storage.capacity - to.storage.total())
	if to.kind == "input":
		if not world.accepts(to.entity, item): return {"error": "This machine does not accept %s for its current recipe." % Catalog.item_name(item), "limit": 0}
		if to.entity.kind not in (["chest", "lab"] + Catalog.TRANSPORT): limit = mini(limit, maxi(0, world.input_limit(to.entity, item) - to.storage.count(item)))
	elif to.kind == "site": limit = mini(limit, world.settlements.receiving_limit(to.site.id, item))
	return {"source": from, "target": to, "limit": limit, "error": "Destination is full or does not need this item." if limit <= 0 else ""}

static func execute(world: RefCounted, item: String, quantity: int, source: Dictionary, target: Dictionary, token: int = 0) -> int:
	if quantity < 0: return 0
	var plan := inspect(world, item, source, target, token)
	if plan.limit <= 0:
		world.message.emit(plan.error)
		return 0
	var amount: int = plan.limit if quantity == 0 else mini(quantity, int(plan.limit))
	var moved: int
	if plan.source.kind == "hand":
		moved = plan.target.storage.add(item, amount)
		if moved > 0: plan.source.entity.carried = ""
	else: moved = plan.source.storage.move_to(plan.target.storage, item, amount)
	if plan.target.kind == "player": world.record("collected:" + item, moved)
	if plan.target.kind == "input" and plan.target.entity.kind == "furnace": world.record("fed:" + item, moved)
	if moved > 0: world.feedback_requested.emit("transfer", Vector2i(world.player_position.floor()))
	world.changed.emit()
	return moved
