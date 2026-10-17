extends RefCounted
const World = preload("res://scripts/simulation/world.gd")
const Saves = preload("res://scripts/persistence/save_service.gd")
const Services = preload("res://scripts/simulation/town_services.gd")

static func town() -> RefCounted:
	var world := World.new()
	world.start(false)
	world.guide.enabled = false
	world.researched = ["logistics"]
	for site in world.settlements.sites.values():
		site.repaired = true
		site.health = site.max_health()
	world.settlements.sites.trading_post.shipments = 20
	world.settlements.total_earned = 200
	world.settlements.credits = 140 # 60 spent restoring the workshop.
	world.player_position = Vector2(world.settlements.sites.workshop.port()) + Vector2(-0.5, 0.5)
	world.previous_position = world.player_position
	world.player.add("repair_kit", 10)
	return world

static func run(test: SceneTree) -> void:
	var world := town()
	var broken = world.spawn("wall", Vector2i(39, 19), 0)
	broken.health = 0
	var damaged = world.spawn("furnace", Vector2i(40, 19), 0)
	damaged.health = damaged.max_health() - 10
	var distant = world.spawn("wall", Vector2i(90, 19), 0)
	distant.health = 0
	var quote := Services.quote(world)
	test.check(quote.reason.is_empty() and quote.jobs[0].target == broken and quote.jobs.size() == 2, "Crew prioritizes disabled local structures and excludes distant damage")
	var kits: int = world.player.count("repair_kit")
	var credits: int = world.settlements.credits
	var revision: int = world.navigation_revision
	test.check(Services.dispatch(world), "Workshop crew can be dispatched")
	test.check(world.player.count("repair_kit") == kits - int(quote.kits) and world.settlements.credits == credits - int(quote.credits), "Crew consumes exactly quoted kits and credits")
	test.check(damaged.health == damaged.max_health() and distant.health == 0 and world.navigation_revision > revision, "Maintenance clamps health, respects radius and invalidates disabled-blocker navigation")
	var loaded := Saves.decode(JSON.parse_string(JSON.stringify(Saves.encode(world))))
	test.check(loaded.error.is_empty() and loaded.world.settlements.maintenance_kits == quote.kits, "Maintenance spending reconciles and survives saving")
	var invalid := Saves.encode(world)
	invalid.settlements.maintenance_kits += 1
	test.check(not Saves.decode(invalid).error.is_empty(), "Unfunded maintenance ledger entries are rejected")
	var legacy := town()
	var old := Saves.encode(legacy)
	old.settlements.erase("maintenance_kits")
	test.check(Saves.decode(old).error.is_empty(), "Older settlements default to zero maintenance spending")
	world.defense.phase = "active"
	var before := [world.settlements.credits, world.player.count("repair_kit"), broken.health]
	test.check(not Services.dispatch(world) and [world.settlements.credits, world.player.count("repair_kit"), broken.health] == before, "Crew cannot heal during combat or spend on a rejected order")
	world.defense.phase = "warning"
	test.check(not Services.reason(world).is_empty(), "Beacon preparation also blocks instant maintenance")
	world.defense.phase = "idle"
	world.player_position = Vector2.ZERO
	test.check(not Services.reason(world).is_empty(), "Hire crews at the workshop instead of remotely")
	world.player_position = Vector2(world.settlements.sites.workshop.port()) + Vector2(-0.5, 0.5)
	world.settlements.sites.town_hall.health = 0
	test.check("Town Hall" in Services.reason(world), "Breach recovery still requires manual emergency repair")
	world.settlements.sites.town_hall.health = 250
	world.defense.phase = "recovery"
	test.check(Services.dispatch(world) and world.defense.phase == "idle", "Crew completes a stabilized Hall's post-defense recovery")
	var limited := town()
	limited.player.contents = {"repair_kit": 1}
	limited.settlements.credits = 2
	var wall = limited.spawn("wall", Vector2i(39, 19), 0)
	wall.health = 0
	quote = Services.quote(limited)
	test.check(quote.kits == 1 and quote.credits == 2 and quote.health == int(limited.character.stat("repair_power")), "Quotes honor both available funds and kits for partial repairs")
	limited.player.contents.clear()
	test.check(not Services.dispatch(limited) and wall.health == 0, "A stale affordable quote cannot bypass missing materials")

static func ui(test: SceneTree) -> void:
	var world := town()
	world.spawn("wall", Vector2i(39, 19), 0).health = 0
	var panel := preload("res://scripts/ui/settlement_panel.gd").new()
	test.root.add_child(panel)
	panel.refresh(world, "workshop")
	test.check(panel.crew_button.visible and not panel.crew_button.disabled and "credits" in panel.crew_button.text, "Workshop displays exact maintenance price and action")
	world.defense.phase = "active"
	panel.refresh(world, "workshop")
	test.check(panel.crew_button.disabled and "defenses" in panel.crew_info.text, "Unavailable maintenance shows its reason directly")
	panel.refresh(world, "trading_post")
	test.check(not panel.crew_button.visible, "Crew service belongs to its restored workshop")
	panel.queue_free()
	await test.process_frame
