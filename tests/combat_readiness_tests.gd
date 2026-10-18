extends RefCounted
const Fixtures = preload("res://tests/fixtures.gd")
const Simulation = preload("res://scripts/simulation/simulation.gd")
const Saves = preload("res://scripts/persistence/save_service.gd")
const Nell = preload("res://scripts/simulation/quartermaster.gd")
const Briefing = preload("res://scripts/ui/defense_briefing.gd")
static func winner() -> RefCounted:
	var world := Fixtures.defense_town()
	world.defense.begin(world)
	for i in range(900): Simulation.step(world)
	return world
static func run(test: SceneTree) -> void:
	var world := Fixtures.defense_town()
	test.check(not Nell.rescued(world) and world.defense.reward_preview(world).contains("Nell"),"First-wave briefing previews the named specialist before rescue")
	var before := Saves.encode(world)
	var text := Briefing.describe(world)
	test.check(text.contains("Loaded turrets") and text.contains("range samples") and Saves.encode(world) == before,"Readiness is advisory live information without mutating state")
	test.check(Nell.stock(world) == 0 and not Nell.dispatch(world),"Rearm service is inaccessible before actual first victory")
	world.defense.begin(world)
	world.defense.cancel(world)
	test.check(not Nell.rescued(world),"Canceling a countdown cannot rescue the specialist")
	world = winner()
	test.check(world.defense.cleared == 1 and Nell.rescued(world) and world.story.available(world,"nell_rescued"),"Winning the real first wave unlocks Nell and her story once through saved first-clear state")
	var shop = world.settlements.sites.workshop
	world.player_position = Vector2(shop.port())+Vector2(-0.5,0.5)
	world.previous_position = world.player_position
	world.player.contents = {"ammo":150}
	test.check(Nell.stock(world) == 100 and shop.inventory.count("ammo") == 100 and world.player.count("ammo") == 50,"Workshop reserve loading caps real transferred stock at 100")
	var a = world.entities[world.by_kind.turret[0]]
	var b = world.entities[world.by_kind.turret[1]]
	a.inventory.contents.clear()
	b.inventory.contents.clear()
	var far = world.spawn("turret",Vector2i(90,20),0)
	var disabled = world.spawn("turret",Vector2i(40,20),0)
	disabled.health = 0
	var quote := Nell.quote(world)
	test.check(quote.rounds == 20 and quote.jobs.size() == 2 and quote.shortage == 20,"Rearm quote includes only alive nearby defenses and normal turret buffer limits")
	var credits: int = world.settlements.credits
	test.check(Nell.dispatch(world) and a.inventory.count("ammo") == 10 and b.inventory.count("ammo") == 10 and shop.inventory.count("ammo") == 80,"Dispatch transfers exactly the quoted ammunition")
	test.check(far.inventory.total() == 0 and disabled.inventory.total() == 0 and world.settlements.credits == credits,"Rearm does not reach distant or disabled guns, create rounds, or charge undisclosed credits")
	test.check(not Nell.dispatch(world) and shop.inventory.count("ammo") == 80,"Repeated stale dispatch cannot refill full guns or consume reserves")
	a.inventory.contents.clear()
	shop.inventory.contents = {"ammo":3}
	test.check(Nell.quote(world).rounds == 3 and Nell.dispatch(world) and a.inventory.count("ammo") == 3 and shop.inventory.count("ammo") == 0,"Short reserves produce an honest partial rearm without phantom ammunition")
	a.inventory.contents.clear()
	shop.inventory.contents = {"ammo":10}
	world.defense.phase = "warning"
	test.check(not Nell.dispatch(world) and shop.inventory.count("ammo") == 10,"Rearm cannot be used after signaling, even during warning")
	world.defense.phase = "active"
	test.check(not Nell.dispatch(world),"Active-wave rearming cannot replace continuous ammunition logistics")
	world.defense.phase = "idle"
	world.player_position = Vector2(90,90)
	test.check(not Nell.dispatch(world),"Dispatch respects the workshop's interaction reach")
	world.player_position = Vector2(shop.port())+Vector2(-0.5,0.5)
	world.settlements.sites.town_hall.health = 0
	test.check(not Nell.dispatch(world) and Nell.rescued(world),"A Hall breach suspends rearming without losing the rescued specialist")
	world.settlements.sites.town_hall.health = 300
	var saved := Saves.decode(JSON.parse_string(JSON.stringify(Saves.encode(world))))
	test.check(saved.error.is_empty(),"Rescued specialist and physical workshop reserve survive save validation: " + saved.error)
	if saved.error.is_empty(): test.check(Nell.rescued(saved.world) and saved.world.settlements.sites.workshop.inventory.count("ammo") == 10,"Reload derives specialist unlock from validated first victory")
	var invalid := Saves.encode(world)
	invalid.settlements.sites[1].inventory.ammo = 101
	test.check(not Saves.decode(invalid).error.is_empty(),"Save validation rejects an oversized specialist reserve")
	var locked := Fixtures.defense_town()
	locked.settlements.sites.workshop.inventory.contents = {"ammo":1}
	test.check(not Saves.decode(Saves.encode(locked)).error.is_empty(),"Save validation rejects reserve stock before specialist rescue")
	var at: Vector2i = Nell.cell(world)
	test.check(world.at(at) == null and world.settlements.at(at) == null and world.story.npc_at(world,at) == "workshop","Nell's visible station avoids buildings and links to the workshop interaction")

static func ui(test: SceneTree) -> void:
	var scene = load("res://main.tscn").instantiate()
	test.root.add_child(scene)
	await test.process_frame
	scene.set_process(false)
	scene.hud.story_panel.dismiss_silently()
	var world := Fixtures.defense_town()
	scene._bind_world(world)
	scene._inspect_site("town_hall")
	var panel = scene.hud.town_panel
	test.check(panel.defense_card.visible and panel.defense_status.text.contains("RESCUE NELL") and panel.readiness.text.contains("Repair kits"),"Hall briefing presents first-clear stakes and live supply readiness together")
	world = winner()
	scene._bind_world(world)
	world.player_position = Vector2(world.settlements.sites.workshop.port())+Vector2(-0.5,0.5)
	world.previous_position = world.player_position
	world.player.contents = {"ammo":20}
	for id in world.by_kind.turret: world.entities[id].inventory.contents.clear()
	scene._inspect_site("workshop")
	test.check(panel.nell_card.visible and panel.nell_rearm.disabled and panel.supplies.buttons.has("ammo"),"Workshop exposes Nell's service and a loadable reserve slot after rescue")
	panel.nell_stock.pressed.emit()
	test.check(not panel.nell_rearm.disabled and world.player.count("ammo") == 0,"Stocking the reserve updates the dispatch quote")
	panel.nell_rearm.pressed.emit()
	test.check(world.settlements.sites.workshop.inventory.count("ammo") == 0 and panel.nell_rearm.disabled,"Dispatch UI reflects actual depletion and filled buffers")
	scene.queue_free()
	await test.process_frame
