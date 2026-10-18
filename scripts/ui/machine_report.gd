extends RefCounted
## Read-only explanations of the simulation's last reported machine state.
const Catalog = preload("res://scripts/data/catalog.gd")
static func inspect(world: RefCounted, entity: RefCounted) -> Dictionary:
	var result := {"title":entity.status,"hint":"","action":"","action_text":"","input":"","process":"","output":"","flow":false,"tone":"neutral"}
	var status: String = entity.status.to_lower()
	if entity.health <= 0:
		result.title = "Building disabled"
		result.hint = "Use a repair kit to restore this building before it can work."
		result.action = "repair"
		result.action_text = "Repair with kit [H]"
		result.tone = "blocked"
	elif status.contains("output full") or status == "output blocked" or status == "drop target blocked":
		result.title = "Output blocked"
		result.hint = "Collect stored output or clear the receiving container. Automate collection with an inserter; lumber camps use a handcart post."
		result.action = "collect"
		result.action_text = "Collect output [X]"
		result.tone = "blocked"
	elif status.contains("no fuel") or status.contains("needs coal") or status.contains("no generator fuel"):
		result.title = "Waiting for fuel"
		result.hint = "Load coal or charcoal into FUEL. A shared fuel depot can supply nearby burner machines automatically."
		result.action = "supply"
		result.action_text = "Load fuel"
		result.tone = "blocked"
	elif status.contains("disconnected") or status.contains("no generator") or status.contains("power shortage"):
		result.title = "Waiting for district power"
		result.hint = "Connect a fueled dynamo through district poles. Poles link within 6 tiles and serve machines within 3; add generation if demand exceeds supply."
		result.tone = "blocked"
	elif status == "missing ingredients" or status == "needs engineering dossiers":
		result.title = "Waiting for ingredients"
		result.action = "supply"
		result.action_text = "Load ingredients"
		result.tone = "blocked"
	elif status.begins_with("choose a workshop"):
		result.title = "Choose a technology project"
		result.hint = "Select a project in Technology [T], then feed engineering dossiers into this drafting bench."
		result.action = "technology"
		result.action_text = "Choose technology [T]"
	elif status == "deposit depleted":
		result.title = "Deposit depleted"
		result.hint = "Use Map [M] to find another deposit. Empty this drill and pick it up to relocate it."
		result.tone = "blocked"
	elif status.contains("trees to mature"):
		result.hint = "This managed grove is regrowing. Let the saplings mature; use another grove to maintain supply meanwhile."
	elif status.contains("no harvestable grove"):
		result.hint = "Replant previously cleared plots after restoring the shelter, or move the camp closer to trees."
	elif status.contains("watercourse"):
		result.hint = "The sawmill needs the old watercourse. Pick it up and place it beside the water."
		result.tone = "blocked"
	elif status == "no pickup source":
		result.hint = "Place a supplying machine, container, or conveyor behind the inserter; its arrow points toward delivery."
	elif status == "no drop target":
		result.hint = "Place a receiving machine, container, or conveyor in front of the inserter."
	elif status == "no ammunition":
		result.hint = "Load ammunition manually or supply it with an inserter."
		result.action = "supply"
		result.action_text = "Load ammunition"
		result.tone = "blocked"
	elif status == "idle - no demand":
		result.hint = "The dynamo saves fuel until a connected electric drive needs energy."
	elif status == "working" or status.begins_with("mining ") or status.begins_with("harvesting") or status.begins_with("researching") or status.begins_with("generating"):
		result.tone = "working"
	if not entity.recipe.is_empty():
		var recipe: Dictionary = Catalog.RECIPES[entity.recipe]
		result.flow = true
		result.input = Catalog.describe(recipe["in"])
		result.process = "%.1fs / batch" % (recipe.ticks / (20.0 if entity.electric_mode else 10.0))
		result.output = Catalog.describe(recipe["out"])
		if status == "missing ingredients":
			var missing: Dictionary = {}
			for item in recipe["in"]:
				var shortage: int = int(recipe["in"][item]) - entity.inventory.count(item)
				if shortage > 0: missing[item] = shortage
			result.hint = "Missing for the next batch: " + Catalog.describe(missing) + ". Load from your pack or automate an inserter supply."
	if entity.kind == "drill":
		var deposit: Dictionary = world.terrain.tile(entity.cell)
		result.merge({"flow":true,"input":"Deposit depleted" if deposit.is_empty() else "%s • %d left" % [Catalog.item_name(deposit.item),deposit.amount],"process":"%.2fs / unit" % (0.75 if entity.electric_mode else 1.5),"output":"Mined resource" if deposit.is_empty() else Catalog.item_name(deposit.item)},true)
	elif entity.kind == "lab":
		var active: String = world.current_research()
		result.merge({"flow":true,"input":"1 engineering dossier","process":"%.1fs / dossier" % (1.5 if entity.electric_mode else 3.0),"output":"Choose a project [T]" if active.is_empty() else Catalog.technology(active).name},true)
		if status == "needs engineering dossiers": result.hint = "Load engineering dossiers into INPUT, manually or with an inserter. Each processed dossier advances the selected project."
	elif entity.kind == "lumber_camp":
		result.merge({"flow":true,"input":"Managed grove","process":"4s / harvest attempt","output":"4 timber"},true)
	elif entity.kind == "generator":
		result.merge({"flow":true,"input":"Coal / charcoal","process":"District power","output":"%d / 2400 stored energy" % entity.energy},true)
	if result.hint.is_empty(): result.hint = Catalog.item_description(entity.kind)
	return result
