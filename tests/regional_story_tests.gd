extends RefCounted
const Fixtures = preload("res://tests/fixtures.gd")
static func run(test: SceneTree) -> void:
	var world := Fixtures.defense_town(false)
	test.check(not world.story.available(world, "district_power") and not world.story.available(world, "orchard_market"), "New regional conversations wait for their actual prerequisites")
	world.researched = ["logistics", "metallurgy"]
	test.check(world.story.unread(world).has("district_power") and world.story.conversation(world, "workshop") == "district_power", "Foundry craft gives Oren an unread power introduction")
	var stock: Dictionary = world.player.contents.duplicate()
	test.check(world.story.mark_seen(world, "district_power") and not world.story.unread(world).has("district_power") and world.player.contents == stock, "Reading a regional conversation acknowledges it without free goods")
	world.settlements.produce_sales = 1
	test.check(world.story.available(world, "orchard_market") and world.story.conversation(world, "trading_post") == "orchard_market", "A real produce sale gives Mira a regional homecoming conversation")
	world.settlements.road_deliveries = 9
	test.check(world.story.available(world, "greybank_complete") and world.story.conversation(world, "workshop") == "greybank_complete", "Completed roadwork gives Oren a visible restoration payoff")
