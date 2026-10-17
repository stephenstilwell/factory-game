extends RefCounted
const World = preload("res://scripts/simulation/world.gd")
const Simulation = preload("res://scripts/simulation/simulation.gd")
const Saves = preload("res://scripts/persistence/save_service.gd")

static func move(world: RefCounted, cell: Vector2i) -> void:
	world.player_position = Vector2(cell) + Vector2(0.5, 1.5)
	world.previous_position = world.player_position

static func craft(test: SceneTree, world: RefCounted, id: String, count: int = 1) -> void:
	test.check(world.craft_many(id, count), "Primitive recipe can be crafted from earned materials: " + id)
	test.advance(world, int(world.Catalog.RECIPES[id].ticks) * count + 2)

static func gather_pile(world: RefCounted, cell: Vector2i) -> void:
	move(world, cell)
	for i in range(12):
		if not world.early.gather(world, cell): break

static func mine(test: SceneTree, world: RefCounted, cell: Vector2i, count: int) -> void:
	move(world, cell)
	world.mining_cell = cell
	world.mining = true
	test.advance(world, world.mining_duration() * count)
	world.mining = false

static func run(test: SceneTree) -> void:
	for seed_value in [0, 1, 74103, -2000000000, 2000000000]:
		var opening := World.new(seed_value)
		opening.start()
		var timber := 0
		var food := 0
		for cell in opening.early.Definitions.START_FORAGE:
			var pile: Dictionary = opening.early.resource_at(opening, cell)
			if pile.get("item") == "timber": timber += int(pile.amount)
			elif pile.get("item") == "foraged_food": food += int(pile.amount)
		test.check(timber == 36 and food == 16, "Starter forage stays accessible across seed %d" % seed_value)
	var world := World.new()
	world.start()
	test.check(world.early.active() and world.early.phase == 0 and world.player.total() == 0 and world.entities.is_empty(), "New worlds begin with an empty timber opening")
	test.check(not world.content_available("furnace") and not world.content_available("drill") and world.content_available("lumber_camp"), "Metal machines are gated behind the actual opening")
	var before: Dictionary = world.terrain.tile(Vector2i(14, 16))
	mine(test, world, Vector2i(14, 16), 3)
	test.check(world.player.count("iron_ore") == 0 and world.terrain.tile(Vector2i(14, 16)) == before, "Hands cannot mine metal before the crossing")
	move(world, world.frontier.port("camp"))
	test.check(not world.frontier.claim(world, "camp") and world.player.count("gear") == 0, "Exploration cannot bypass early metal progression with camp salvage")
	move(world, Vector2i(23, 13))
	world.player.capacity = 0
	test.check(not world.early.gather(world, Vector2i(23, 13)) and world.early.gathered.is_empty(), "Full packs cannot consume finite forage")
	world.player.capacity = int(world.character.stat("inventory_capacity"))
	world.player_position += Vector2(20, 0)
	test.check(not world.early.gather(world, Vector2i(23, 13)) and world.early.gathered.is_empty(), "Forage requires physical proximity")
	for cell in world.early.Definitions.START_FORAGE: gather_pile(world, cell)
	test.check(world.player.count("timber") == 36 and world.player.count("foraged_food") == 16, "Opening piles provide finite timber and food without mining metals")
	var remaining: int = world.player.count("timber")
	gather_pile(world, Vector2i(23, 13))
	test.check(world.player.count("timber") == remaining, "Exhausted fallen timber cannot be harvested again")
	mine(test, world, Vector2i(26, 9), 64)
	craft(test, world, "stone_axe")
	craft(test, world, "lumber_camp")
	craft(test, world, "plank", 4)
	craft(test, world, "cart_post")
	craft(test, world, "communal_hearth")
	# Find a productive grove close enough to the millrace for a compact starter village.
	var camp_cell := Vector2i.ZERO
	var most := -1
	for x in range(18, 34):
		for y in range(27, 40):
			var cell := Vector2i(x, y)
			if not world.terrain.tile(cell).is_empty() or world.settlements.at(cell) != null: continue
			var trees := 0
			for dx in range(-4, 5):
				for dy in range(-4, 5):
					if world.frontier.tree_at(world, cell + Vector2i(dx, dy)): trees += 1
			if trees > most:
				most = trees
				camp_cell = cell
	move(world, camp_cell)
	test.check(world.build("lumber_camp", camp_cell, 0), "First lumber camp uses physical construction items")
	var post_cell := camp_cell + Vector2i(0, 2)
	move(world, post_cell)
	test.check(world.build("cart_post", post_cell, 0), "Workers start from a placed handcart collection post")
	var home_cell := post_cell + Vector2i(2, 0)
	move(world, home_cell)
	test.check(world.build("communal_hearth", home_cell, 0), "Players build their first shelter rather than receiving a prebuilt town")
	test.advance(world, 400)
	test.check(world.early.delivered >= 8 and world.at(post_cell).inventory.count("timber") >= 8 and not world.frontier.cleared.is_empty(), "Workers deliver real timber harvested from depleted trees")
	move(world, post_cell)
	world.collect_output(post_cell)
	craft(test, world, "plank", 4)
	move(world, home_cell)
	test.check(world.early.advance(world) and world.early.phase == 1 and world.settlements.age == 1, "Earned timber, food and worker deliveries establish Stone age")
	test.check(not world.content_available("furnace") and world.content_available("watermill"), "Stone age unlocks water power while metal remains locked")
	test.check(Saves.decode(JSON.parse_string(JSON.stringify(Saves.encode(world)))).error.is_empty(), "A primitive Stone town saves without requiring the industrial Hall")
	# Bring timber from the post; missing quantities are gathered from additional finite fallen-log sites.
	for x in range(0, 5):
		for cell in world.early.forage_cells(Vector2i(x, 2), world.terrain.seed_value): gather_pile(world, cell)
	move(world, post_cell)
	world.collect_output(post_cell)
	craft(test, world, "plank", 4)
	craft(test, world, "watermill")
	craft(test, world, "charcoal_kiln")
	var mill_cell := Vector2i(24, 30)
	# Reserved industrial or ore tiles do not prevent a primitive building; avoid the existing camp.
	if world.at(mill_cell) != null: mill_cell += Vector2i(0, 1)
	move(world, mill_cell)
	test.check(world.build("watermill", mill_cell, 0), "Sawmill is constructed beside the real millrace location")
	var kiln_cell := mill_cell + Vector2i(2, 0)
	if world.at(kiln_cell) != null: kiln_cell += Vector2i(0, 1)
	move(world, kiln_cell)
	test.check(world.build("charcoal_kiln", kiln_cell, 0), "Charcoal production requires a built clamp")
	# Reposition the same physical collection post to serve both timber machines.
	move(world, post_cell)
	test.check(world.reclaim(post_cell), "Collection posts can be reclaimed with their stored timber")
	var connected := false
	for x in range(mill_cell.x - 4, mill_cell.x + 5):
		for y in range(mill_cell.y - 4, mill_cell.y + 5):
			var cell := Vector2i(x, y)
			if cell.distance_squared_to(camp_cell) > 100 or cell.distance_squared_to(mill_cell) > 25 or cell.distance_squared_to(kiln_cell) > 25: continue
			if world.at(cell) != null or world.settlements.at(cell) != null: continue
			move(world, cell)
			if world.build("cart_post", cell, 0):
				post_cell = cell
				connected = true
				break
		if connected: break
	test.check(connected, "A compact handcart route can connect grove and water-powered production")
	move(world, post_cell)
	world.deposit(post_cell, "timber", 12)
	test.advance(world, 160)
	test.check(world.early.sawn > 0 and world.at(mill_cell).inventory.count("timber") + world.at(mill_cell).output.total() > 0, "Handcart posts feed watermills using physical stored timber")
	move(world, mill_cell)
	world.supply(mill_cell)
	move(world, kiln_cell)
	world.supply(kiln_cell)
	test.advance(world, 125)
	move(world, kiln_cell)
	world.supply(kiln_cell)
	test.advance(world, 125)
	move(world, mill_cell)
	world.collect_output(mill_cell)
	move(world, kiln_cell)
	world.collect_output(kiln_cell)
	test.check(world.early.sawn >= 12 and world.early.charcoal >= 4 and world.player.count("coal") >= 4, "Water and timber produce planks and usable charcoal without metal")
	move(world, world.frontier.port("quarry"))
	test.check(world.frontier.claim(world, "quarry"), "Stone masons recover the quarry pattern before first iron")
	move(world, home_cell)
	test.check(world.early.advance(world) and world.early.phase == 2, "Real stone production and quarry knowledge reopen the crossing")
	test.check(world.content_available("furnace") and not world.content_available("drill"), "Iron starts with furnaces; drills still need their manufacturing lesson")
	craft(test, world, "furnace")
	var furnace_cell := Vector2i(21, 11)
	move(world, furnace_cell)
	test.check(world.build("furnace", furnace_cell, 0), "The first metal furnace is built after two civic chapters")
	mine(test, world, Vector2i(14, 16), 5)
	move(world, furnace_cell)
	world.supply(furnace_cell)
	test.advance(world, 170)
	world.collect_output(furnace_cell)
	test.check(world.player.count("iron_plate") >= 5, "Full empty-start playthrough reaches first iron using earned charcoal")
	var encoded := Saves.encode(world)
	var loaded := Saves.decode(JSON.parse_string(JSON.stringify(encoded)))
	test.check(loaded.error.is_empty() and Saves.encode(loaded.world) == encoded, "All primitive production, gathering and age state roundtrips exactly")
	var corrupt := encoded.duplicate(true)
	corrupt.early.phase = 3
	test.check(not Saves.decode(corrupt).error.is_empty(), "Unsupported opening phases fail validation")
	corrupt = encoded.duplicate(true)
	corrupt.early.gathered.append([23, 13, 1])
	test.check(not Saves.decode(corrupt).error.is_empty(), "Duplicated forage depletion fails validation")
	var old := World.new()
	old.start(false)
	var old_data := Saves.encode(old)
	old_data.erase("early")
	old_data.onboarding.erase("timber_opening")
	loaded = Saves.decode(old_data)
	test.check(loaded.error.is_empty() and not loaded.world.early.enabled and loaded.world.content_available("furnace"), "Older factories keep their original progression and remain playable")
	world.start()
	test.check(world.early.phase == 0 and world.early.gathered.is_empty() and world.early.delivered == 0, "New game resets primitive supplies and milestones")

static func ui(test: SceneTree) -> void:
	var scene = load("res://main.tscn").instantiate()
	test.root.add_child(scene)
	await test.process_frame
	scene.set_process(false)
	scene.hud.story_panel.dismiss_silently()
	scene.paused = true
	scene.view.paused = true
	var world := World.new()
	world.start()
	scene._bind_world(world)
	test.check(scene.hud.hotbar.layout.item(0, 0) == "lumber_camp" and not scene.hud.hotbar.available("furnace"), "Timber hotbar uses its own saved preferences without overwriting industrial shortcuts")
	scene.hud.story_panel.present(world, "arrival")
	test.check(scene.hud.story_panel.text.text.contains("foundry") and scene.hud.story_panel.title.text.contains("hearth"), "The new arrival explains shelter before foundries")
	scene.hud.story_panel.project_button.pressed.emit()
	test.check(scene.hud.workspace.visible and scene.hud.workspace.mode == "town" and scene.hud.workspace.site_id.is_empty(), "The arrival project button opens primitive restoration rather than an industrial ruin")
	scene.hud.close_workspace()
	scene.paused = true
	var cell := Vector2i(23, 17)
	world.spawn("communal_hearth", cell, 0)
	move(world, cell)
	world.early.delivered = 8
	world.player.contents = world.early.Definitions.SHELTER_COST.duplicate()
	scene.hud.workspace.open_mode("town")
	scene.hud.refresh()
	var panel = scene.hud.town_panel
	test.check(panel.age_box.visible and not panel.age_button.disabled and panel.age_text.text.contains("Fresh produce"), "Town explains primitive project costs and enables its real delivery action")
	panel.age_button.pressed.emit()
	scene.hud.refresh()
	test.check(world.early.phase == 1 and world.player.total() == 0 and panel.age_text.text.contains("Water-sawn"), "Town UI spends the actual shelter supplies and reveals stone production goals")
	var before: Dictionary = Saves.encode(world)
	for i in range(5): await test.process_frame
	test.check(Saves.encode(world) == before, "Drawing forage, water and settlers never changes authoritative progress")
	scene.queue_free()
	await test.process_frame
