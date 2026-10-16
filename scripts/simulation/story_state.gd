extends RefCounted
## Narrative memory is independent of technology, inventories, and settlement rewards.
const Definitions = preload("res://scripts/data/story_catalog.gd")
var seen: Array = ["arrival"] # Existing worlds and fixtures do not get a new-game interruption.

func fresh() -> void:
	seen.clear()

func conversation(world: RefCounted, site_id: String) -> String:
	if not world.settlements.enabled or not Definitions.NPCS.has(site_id): return ""
	var site = world.settlements.sites[site_id]
	if site_id == "workshop" and world.settlements.age >= 1: return "stone_homecoming"
	if site_id == "town_hall" and site.repaired:
		if site.health == 0: return "ada_recovery"
		if world.defense.cleared > 0: return "first_homecoming"
	return Definitions.NPCS[site_id].after if site.repaired else Definitions.NPCS[site_id].before

func available(world: RefCounted, chapter: String) -> bool:
	if not Definitions.CHAPTERS.has(chapter): return false
	if chapter == "arrival": return true
	if not world.settlements.enabled: return false
	var data: Dictionary = Definitions.CHAPTERS[chapter]
	if chapter == "stone_homecoming": return world.settlements.age >= 1
	if chapter == "first_homecoming": return world.settlements.sites.town_hall.repaired and world.defense.cleared > 0
	if chapter == "ada_recovery": return world.settlements.sites.town_hall.repaired
	if chapter.ends_with("_after"): return world.settlements.sites[data.site].repaired
	return true

func mark_seen(world: RefCounted, chapter: String) -> bool:
	if not available(world, chapter): return false
	if not seen.has(chapter): seen.append(chapter)
	return true

func serialize() -> Dictionary:
	return {"seen": seen.duplicate()}

func restore(data: Variant, world: RefCounted) -> bool:
	if not data is Dictionary or not data.get("seen") is Array or data.seen.size() > Definitions.CHAPTERS.size(): return false
	var valid: Array = []
	for chapter in data.seen:
		if not chapter is String or valid.has(chapter) or not available(world, chapter): return false
		valid.append(chapter)
	seen = valid
	return true

func goal(world: RefCounted) -> String:
	if not world.settlements.enabled: return "Give Oldbridge a reason to welcome people home."
	var sites: Dictionary = world.settlements.sites
	if not sites.trading_post.repaired: return "Reopen Mira's market so the supply wagons and first families can return."
	if not sites.workshop.repaired: return "Keep Mira's contracts running. Fund Oren's crew and reopen the workshop."
	if not sites.town_hall.repaired: return "Build Ada a safe shelter before inviting more families down the eastern road."
	if sites.town_hall.health == 0: return "Repair the hall. A setback does not erase the town you've rebuilt."
	if world.settlements.age == 0: return "Recover the orchard and Greybank mason pattern [L]. Rebuild at the Hall [Y] to enter Stone & Water."
	if world.defense.cleared == 0: return "Prepare the eastern defenses, then choose when to light the beacon."
	return "Keep the eastern road safe. More families are waiting beyond the ridge."

func unread(world: RefCounted) -> Array:
	var result: Array = []
	if not seen.has("arrival"): result.append("arrival")
	if world.settlements.enabled:
		for site_id in Definitions.NPCS:
			var chapter := conversation(world, site_id)
			if not chapter.is_empty() and not seen.has(chapter) and chapter not in result: result.append(chapter)
	return result

func journal_entries() -> Array:
	var entries: Array = []
	for chapter in Definitions.CHAPTERS:
		if seen.has(chapter): entries.append(chapter)
	return entries

func npc_cell(world: RefCounted, site_id: String) -> Vector2i:
	var origin: Vector2i = world.settlements.sites[site_id].origin
	# Derive positions from migrated landmarks; never occupy or move real machines.
	for offset in [Vector2i(-1, 2), Vector2i(-1, 0), Vector2i(1, 3), Vector2i(3, 2), Vector2i(3, 0), Vector2i(0, 3), Vector2i(2, 3)]:
		var cell: Vector2i = origin + offset
		if world.at(cell) == null and world.settlements.at(cell) == null and world.terrain.tile(cell).is_empty(): return cell
	return origin + Vector2i(1, 2)

func npc_at(world: RefCounted, cell: Vector2i) -> String:
	if not world.settlements.enabled: return ""
	for id in Definitions.NPCS:
		if npc_cell(world, id) == cell: return id
	return ""