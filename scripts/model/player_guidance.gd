extends RefCounted
## Saved personal goals and acknowledgements; badges derive from live world state.
const Equipment = preload("res://scripts/data/character_catalog.gd")
const Skills = preload("res://scripts/data/skill_catalog.gd")
const Catalog = preload("res://scripts/data/catalog.gd")
var pinned: Dictionary = {}
var acknowledged: Array = []
var introduced := false
var history: Array = []

func remember(text: String, tick: int) -> void:
	if text.is_empty(): return
	if not history.is_empty() and history.back().text == text and tick - int(history.back().tick) < 10: return
	history.append({"text": text.left(600), "tick": tick})
	if history.size() > 40: history.pop_front()

func observe(world: RefCounted) -> void:
	if introduced or not world.guide.enabled or Equipment.gate(world, 1) != "": return
	introduced = true
	if pinned.is_empty(): pinned = {"kind": "equipment", "id": "boots", "target": 1}
	world.message.emit("Engineer equipment unlocked! Press P for skills and permanent upgrades. Your first boots are tracked below. Discoveries [L / J] has leads beyond town.")

func equipment_status(world: RefCounted) -> Dictionary:
	var ready := 0
	var unseen := 0
	for id in Equipment.UPGRADES:
		var rank: int = world.character.level(id) + 1
		if rank > Equipment.UPGRADES[id].values.size(): continue
		if not Equipment.gate(world, rank, id).is_empty(): continue
		if not acknowledged.has("equipment:%s:%d" % [id, rank]): unseen += 1
		if world.character.error(world, id, rank).is_empty(): ready += 1
	return {"ready": ready, "new": unseen}

func view_equipment(world: RefCounted) -> void:
	for id in Equipment.UPGRADES:
		var rank: int = world.character.level(id) + 1
		if rank <= Equipment.UPGRADES[id].values.size() and Equipment.gate(world, rank, id).is_empty(): acknowledge("equipment:%s:%d" % [id, rank])

func acknowledge(key: String) -> void:
	if not acknowledged.has(key): acknowledged.append(key)

func project_new(world: RefCounted) -> bool:
	if not world.current_research().is_empty() or not world.content_available("lab"): return false
	for definition in Catalog.TECHNOLOGIES:
		if world.research_available(definition.id) and not acknowledged.has("project:" + definition.id): return true
	return false

func view_projects(world: RefCounted) -> void:
	for definition in Catalog.TECHNOLOGIES:
		if world.research_available(definition.id): acknowledge("project:" + definition.id)

func pin(world: RefCounted, kind: String, id: String, target: int) -> void:
	var goal := {"kind": kind, "id": id, "target": target}
	if not valid_goal(goal): return
	pinned = {} if pinned == goal else goal
	world.changed.emit()

func goal(world: RefCounted) -> Dictionary:
	if pinned.is_empty(): return {}
	var id: String = pinned.id
	if pinned.kind == "skill":
		var reached: bool = world.skills.level(id) >= int(pinned.target)
		var remaining: int = maxi(0, Skills.threshold(int(pinned.target)) - int(world.skills.xp[id]))
		return {"title": "%s level %d" % [Skills.SKILLS[id].name, pinned.target], "text": "%d XP remaining • Reward: +%d%% speed total%s" % [remaining, world.skills.bonus_percent(id, int(pinned.target)), " and +1 survey region" if id == "exploration" and int(pinned.target) in [25, 75] else ""], "complete": reached}
	var definition: Dictionary = Equipment.UPGRADES[id]
	var rank: int = pinned.target
	var reached: bool = world.character.level(id) >= rank
	if reached: return {"title": "%s tier %d" % [definition.name, rank], "text": "Installed • " + Equipment.format_stat(definition.stat, definition.values[rank - 1]), "complete": true}
	var parts := PackedStringArray()
	for item in definition.costs[rank - 1]: parts.append("%s %d/%d" % [Catalog.item_name(item), world.player.count(item), definition.costs[rank - 1][item]])
	var gate: String = Equipment.gate(world, rank, id)
	return {"title": "%s tier %d" % [definition.name, rank], "text": ("Ready to install [P]" if world.character.error(world, id, rank).is_empty() else (gate if not gate.is_empty() else ", ".join(parts))) + " • Reward: " + Equipment.format_stat(definition.stat, definition.values[rank - 1]), "complete": reached}

func valid_goal(data: Dictionary) -> bool:
	if data.is_empty(): return true
	if data.size() != 3 or not data.get("id") is String or not integer(data.get("target"), 1, 99): return false
	if data.get("kind") == "equipment": return Equipment.UPGRADES.has(data.id) and data.target <= Equipment.UPGRADES[data.id].values.size()
	return data.get("kind") == "skill" and Skills.SKILLS.has(data.id) and int(data.target) in Skills.milestones(data.id)

func integer(value, low: int, high: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value == floor(float(value)) and value >= low and value <= high

func serialize() -> Dictionary:
	return {"pinned": pinned.duplicate(), "acknowledged": acknowledged.duplicate(), "introduced": introduced, "history": history.duplicate(true)}

func restore(data, ticks: int) -> bool:
	if not data is Dictionary or not data.get("pinned") is Dictionary or not valid_goal(data.pinned) or not data.get("introduced") is bool: return false
	if not data.get("acknowledged") is Array or data.acknowledged.size() > 64 or not data.get("history") is Array or data.history.size() > 40: return false
	var allowed: Array = []
	for id in Equipment.UPGRADES:
		for rank in range(1, Equipment.UPGRADES[id].values.size() + 1): allowed.append("equipment:%s:%d" % [id, rank])
	for definition in Catalog.TECHNOLOGIES: allowed.append("project:" + definition.id)
	var seen: Array = []
	for key in data.acknowledged:
		if key not in allowed or key in seen: return false
		seen.append(key)
	var previous := 0
	for entry in data.history:
		if not entry is Dictionary or not entry.get("text") is String or entry.text.length() > 600 or not integer(entry.get("tick"), previous, ticks): return false
		previous = int(entry.tick)
	pinned = data.pinned.duplicate()
	if not pinned.is_empty(): pinned.target = int(pinned.target)
	acknowledged = seen
	introduced = data.introduced
	history = []
	for entry in data.history: history.append({"text": entry.text, "tick": int(entry.tick)})
	return true
