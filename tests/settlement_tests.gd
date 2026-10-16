extends RefCounted

const World = preload("res://scripts/simulation/world.gd")
const Settlements = preload("res://scripts/simulation/settlements.gd")
const SaveService = preload("res://scripts/persistence/save_service.gd")
const Fixtures = preload("res://tests/fixtures.gd")

static func run(test: SceneTree) -> void:
	var world := World.new()
	world.settlements = Settlements.new(true)
	var region = world.settlements
	var post = region.sites.trading_post
	var workshop = region.sites.workshop
	world.player_position = Vector2(28.5, 15.5)
	test.check(world.entities.is_empty() and region.credits == 0 and not post.repaired, "Ruins grant no machines, supplies, or money")
	test.check(world.solid(post.port()) and world.logistics_receiver(post.port()) == post, "Landmark has a solid footprint and a distinct logistics hatch")
	test.check(world.logistics_receiver(post.origin) == null, "Inserters cannot deliver through arbitrary building walls")
	world.player.add("belt")
	test.check(not world.build("belt", post.port(), 0) and world.player.count("belt") == 1, "Construction cannot overwrite settlement land")
	test.check(not world.reclaim(post.port()), "Landmarks cannot become free building items")
	test.check(not world.restore_site("trading_post"), "Missing repair materials cannot restore a project")
	test.advance(world, 1000)
	test.check(region.credits == 0 and post.shipment_ticks == 0, "Unrepaired trading post produces no income")
	world.player.contents = {"iron_plate": 30, "gear": 7, "stone": 10, "coal": 5}
	world.player_position = Vector2.ZERO
	world.supply_site("trading_post")
	test.check(post.inventory.total() == 0, "Manual civic delivery enforces interaction reach")
	world.player_position = Vector2(28.5, 15.5)
	world.supply_site("trading_post")
	test.check(post.inventory.contents == {"iron_plate": 20, "gear": 5, "stone": 10} and world.player.count("iron_plate") == 10 and world.player.count("coal") == 5, "Repair contribution takes only needed materials and leaves unrelated goods")
	test.advance(world, 30)
	test.check(not post.repaired and region.credits == 0, "Fully supplied ruins wait for an explicit restoration")
	world.withdraw_site("trading_post")
	test.check(post.inventory.total() == 0 and world.player.count("iron_plate") == 30, "Unused repair materials can be retrieved before commitment")
	world.supply_site("trading_post")
	test.check(world.restore_site("trading_post") and post.repaired and post.inventory.total() == 0, "Restoration consumes materials once and permanently opens trade")
	test.check(not world.restore_site("trading_post") and region.total_earned == 0, "Duplicate restoration cannot generate rewards")
	test.check(not world.accepts(post, "coal") and world.accepts(post, "iron_plate"), "Contract hatch accepts only its requested goods")
	test.advance(world, 600)
	test.check(region.credits == 0 and post.repaired, "A supply shortage pauses earnings without undoing restoration")
	world.supply_site("trading_post")
	test.check(post.inventory.count("iron_plate") == 4 and post.inventory.count("gear") == 1, "Manual contract supply contributes one physical shipment")
	test.advance(world, 1)
	test.check(post.inventory.total() == 0 and post.shipment_ticks == 299 and region.credits == 0, "Dispatch reserves goods before the delivery timer pays")
	world.withdraw_site("trading_post")
	test.check(post.inventory.total() == 0, "Dispatched goods cannot be withdrawn and sold again")
	var result := SaveService.decode(JSON.parse_string(JSON.stringify(SaveService.encode(world))))
	test.check(result.has("world"), "Mid-shipment save validates")
	if not result.has("world"): return
	var restored = result.world
	test.advance(world, 298)
	test.advance(restored, 298)
	test.check(region.credits == 0, "Shipment cannot pay before its complete duration")
	test.advance(world, 1)
	test.advance(restored, 1)
	test.check(region.credits == 10 and region.total_earned == 10 and post.shipments == 1, "One completed shipment pays exactly once")
	test.check(SaveService.encode(world) == SaveService.encode(restored), "Saved in-flight shipment continues deterministically")
	test.advance(world, 1000)
	test.check(region.credits == 10 and post.shipments == 1, "Idle time cannot bank free shipments or duplicate a payout")
	world.player_position = Vector2(34.5, 20.5)
	world.player.contents = {"iron_plate": 20, "gear": 5, "copper_plate": 10}
	world.supply_site("workshop")
	test.check(not world.restore_site("workshop") and workshop.inventory.total() == 35 and region.credits == 10, "Unfunded crew project preserves delivered materials and wallet")
	# Use real inserter delivery for the five remaining paid shipments.
	var source = world.spawn("chest", post.port() - Vector2i(2, 0), 0)
	var arm = world.spawn("inserter", post.port() - Vector2i(1, 0), 0)
	source.inventory.contents = {"iron_plate": 20, "gear": 5, "coal": 3}
	test.advance(world, 1800)
	test.check(region.credits == 60 and post.shipments == 6 and source.inventory.count("coal") == 3 and arm.carried == "", "Inserters fulfill repeated contracts autonomously and leave rejected goods at source")
	test.check(world.restore_site("workshop") and region.credits == 0 and workshop.inventory.total() == 0, "Earned trade credits fund the next restoration alongside physical materials")
	test.check(world.burner_fuel_duration() == 288 and not world.restore_site("workshop"), "Unique workshop grants its global fuel bonus once")
	var furnace = world.spawn("furnace", Vector2i(24, 17), 0)
	furnace.inventory.contents = {"iron_ore": 3, "coal": 1}
	test.advance(world, 1)
	test.check(furnace.burn_ticks == 287, "Restoration bonus applies to a newly consumed coal")
	var upgraded := SaveService.decode(SaveService.encode(world))
	test.check(upgraded.has("world") and upgraded.world.burner_fuel_duration() == 288, "Bonus state and upgraded fuel timers survive save/load")
	test.advance(world, 95)
	test.check(furnace.output.count("iron_plate") == 3 and furnace.inventory.count("coal") == 0, "Workshop coal powers all three queued plates without extra coal")
	test.advance(world, 1000)
	test.check(workshop.repaired and post.repaired and region.credits == 0 and world.burner_fuel_duration() == 288, "Permanent repairs and global bonus survive later supply shortages")
	var malformed := SaveService.encode(world)
	malformed.settlements.credits = 100
	test.check(not SaveService.decode(malformed).has("world"), "Currency inconsistent with earned income and restoration spending is rejected")
	malformed = SaveService.encode(world)
	malformed.settlements.sites[0].shipment_ticks = 300
	test.check(not SaveService.decode(malformed).has("world"), "Invalid contract timer is rejected")
	malformed = SaveService.encode(world)
	malformed.settlements.sites[0].inventory.coal = 1
	test.check(not SaveService.decode(malformed).has("world"), "Invalid civic inventory goods are rejected")
	malformed = SaveService.encode(world)
	malformed.settlements.sites[0].x = workshop.origin.x
	malformed.settlements.sites[0].y = workshop.origin.y
	test.check(not SaveService.decode(malformed).has("world"), "Overlapping landmarks are rejected")
	# No settlement extension existed in older saves: migrate into vacant land.
	var old := Fixtures.demo()
	old.spawn("chest", Vector2i(30, 14), 0)
	old.player_position = Vector2(31.5, 14.5)
	var old_data := SaveService.encode(old)
	old_data.erase("settlements")
	var migrated := SaveService.decode(old_data)
	test.check(migrated.has("world") and migrated.world.at(Vector2i(30, 14)) != null and migrated.world.settlements.sites.trading_post.origin != Vector2i(30, 13), "Older factories gain ruins on vacant land without overwriting buildings or trapping the engineer")
	# Repair intake and contract intake have strict, separate stock limits.
	var repairing := World.new()
	repairing.settlements = Settlements.new(true)
	var repair_hatch = repairing.settlements.sites.trading_post
	var repair_source = repairing.spawn("chest", repair_hatch.port() - Vector2i(2, 0), 0)
	repair_source.inventory.contents = {"stone": 10, "iron_plate": 20, "gear": 5}
	repairing.spawn("inserter", repair_hatch.port() - Vector2i(1, 0), 0)
	test.advance(repairing, 300)
	test.check(repair_source.inventory.total() == 0 and repairing.settlements.repair_reason("trading_post").is_empty() and not repair_hatch.repaired, "Inserters can complete repair material delivery while leaving restoration to the player")
	repairing.player_position = Vector2(28.5, 15.5)
	test.check(repairing.restore_site("trading_post"), "Automatically supplied repairs can be committed from the hatch")
	var capped := World.new()
	capped.settlements = Settlements.new(true)
	var hatch = capped.settlements.sites.trading_post
	hatch.inventory.contents = {"iron_plate": 20, "gear": 5, "stone": 10}
	test.check(not capped.accepts(hatch, "iron_plate"), "Repair intake rejects excess materials")
	capped.settlements.restore("trading_post")
	hatch.inventory.contents = {"iron_plate": 40, "gear": 10}
	test.check(not capped.accepts(hatch, "iron_plate") and not capped.accepts(hatch, "gear"), "Contract intake caps its buffer at ten shipments")
	var feeder = capped.spawn("chest", hatch.port() - Vector2i(2, 0), 0)
	var hand = capped.spawn("inserter", hatch.port() - Vector2i(1, 0), 0)
	feeder.inventory.add("iron_plate")
	hand.carried = "iron_plate"
	hatch.shipment_ticks = 100
	test.advance(capped, 10)
	test.check(hand.carried == "iron_plate" and hatch.inventory.count("iron_plate") == 40, "Full settlement buffer preserves blocked inserter hands")
