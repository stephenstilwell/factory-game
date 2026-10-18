extends RefCounted
## Read-only view models shared by project cards and their navigation.
const Catalog = preload("res://scripts/data/catalog.gd")
const Sites = preload("res://scripts/data/settlement_catalog.gd")

static func technology(world: RefCounted, id: String) -> Dictionary:
	var definition: Dictionary = Catalog.technology(id)
	var missing: Array[String] = []
	for prerequisite in definition.requires:
		if prerequisite not in world.researched: missing.append(prerequisite)
	var complete: bool = id in world.researched
	var active: bool = world.current_research() == id
	var enabled: bool = world.content_available("lab")
	var state := "complete" if complete else ("locked" if not enabled or not missing.is_empty() else ("active" if active else "available"))
	var progress: int = int(definition.cost) if complete else (world.research_progress if active else int(world.research_banks.get(id,0)))
	var reason := ""
	if not complete:
		if world.early.active(): reason = "Restore the crossing to reach Iron & Industry."
		elif not enabled: reason = "Finish the introductory drafting lesson."
		elif not missing.is_empty():
			var names := PackedStringArray()
			for required in missing: names.append(Catalog.technology(required).name)
			reason = "Requires " + ", ".join(names) + "."
	return {"state":state,"progress":progress,"cost":int(definition.cost),"missing":missing,"reason":reason}

static func recommended_technology(world: RefCounted) -> String:
	var active: String = world.current_research()
	if not active.is_empty() and technology(world,active).state == "active": return active
	for definition in Catalog.TECHNOLOGIES:
		if technology(world,definition.id).state == "available": return definition.id
	return ""

static func settlement(world: RefCounted, id: String) -> Dictionary:
	var definition: Dictionary = Sites.SITES[id]
	var site = world.settlements.sites[id]
	var delivered := 0
	var required := 0
	var missing: Dictionary = {}
	for item in definition.repair:
		var needed: int = int(definition.repair[item])
		required += needed
		delivered += mini(needed,site.inventory.count(item))
		if site.inventory.count(item) < needed: missing[item] = needed - site.inventory.count(item)
	var reason: String = world.settlements.repair_reason(id)
	if world.early.active() and not site.repaired: reason = "Rebuild the crossing before restoring civic buildings."
	var state := "restored" if site.repaired else ("ready" if reason.is_empty() else "incomplete")
	if site.repaired and (site.health == 0 or not world.settlements.services_online()): state = "offline"
	if site.repaired: delivered = required; missing.clear()
	var prerequisite: String = definition.get("requires","")
	if prerequisite.is_empty() or world.settlements.sites[prerequisite].repaired: prerequisite = ""
	return {"state":state,"delivered":delivered,"required":required,"missing":missing,"reason":reason,"prerequisite":prerequisite,"credit_cost":int(definition.credits)}
