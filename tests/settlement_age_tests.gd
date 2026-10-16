extends RefCounted
const World = preload("res://scripts/simulation/world.gd")
const Saves = preload("res://scripts/persistence/save_service.gd")
const Fixtures = preload("res://tests/fixtures.gd")

static func ready_town() -> RefCounted:
 var world = Fixtures.defense_town(false)
 world.frontier.install(world)
 for id in ["orchard", "quarry"]:
  world.player_position = Vector2(world.frontier.port(id)) + Vector2.ONE * 0.5
  world.previous_position = world.player_position
  world.frontier.claim(world, id)
 world.player_position = Vector2(world.settlements.sites.town_hall.port()) + Vector2(-0.5, 0.5)
 world.previous_position = world.player_position
 world.player.contents = world.settlements.Ages.STONE_GOODS.duplicate()
 return world

static func run(test: SceneTree) -> void:
 var fresh = World.new()
 fresh.start(false)
 test.check(fresh.settlements.age == 0 and fresh.entities.is_empty() and fresh.player.total() == 0, "Timber age keeps the empty opening")
 test.check(not fresh.settlements.advance_age(fresh), "Town age requires civic restoration")
 var world = ready_town()
 var saved = Saves.encode(world)
 test.check(world.settlements.age_reason(world).is_empty(), "Hall, orchard, mason pattern and materials make Stone age ready")
 world.player_position += Vector2(12, 0)
 test.check(not world.settlements.advance_age(world) and world.settlements.age == 0 and world.player.contents == saved.player, "Age project cannot spend materials remotely")
 world.player_position = Vector2(saved.position[0], saved.position[1])
 world.defense.phase = "warning"
 test.check(not world.settlements.advance_age(world), "Age project waits for beacon defenses")
 world.defense.phase = "idle"
 world.frontier.sites.quarry.claimed = false
 test.check(world.settlements.age_reason(world).contains("Quarry"), "Age project requires the recovered quarry pattern")
 world.frontier.sites.quarry.claimed = true
 world.player.contents.stone -= 1
 test.check(not world.settlements.advance_age(world) and world.player.count("iron_plate") == 20 and world.settlements.age == 0, "Incomplete age supplies leave every material untouched")
 world.player.contents.stone += 1
 var xp: int = world.skills.xp.fabrication
 test.check(world.settlements.advance_age(world) and world.settlements.age == 1 and world.player.total() == 0 and world.skills.xp.fabrication == xp + 500, "Stone age atomically consumes supplies and grants one milestone")
 test.check(not world.settlements.advance_age(world) and world.skills.xp.fabrication == xp + 500, "Completed town ages cannot grant duplicate rewards")
 test.check(world.story.conversation(world, "workshop") == "stone_homecoming" and "stone_homecoming" in world.story.unread(world), "Oren has an unread conversation explaining the new civic age")
 test.check(not fresh.story.available(fresh, "stone_homecoming"), "Future-age conversations stay locked until restoration")
 for site in world.settlements.sites.values():
  site.inventory.contents.clear()
  site.shipment_ticks = 0
 world.settlements.sites.trading_post.inventory.contents = {"iron_plate": 4, "gear": 1}
 var earned: int = world.settlements.total_earned
 for i in range(300): world.settlements.step(world)
 test.check(world.settlements.total_earned == earned + 12 and world.settlements.stone_shipments == 1, "Stone market pays 12 credits only after a supplied shipment completes")
 for i in range(600): world.settlements.step(world)
 test.check(world.settlements.total_earned == earned + 12, "Stone age provides no income without goods")
 var data = Saves.encode(world)
 var loaded = Saves.decode(JSON.parse_string(JSON.stringify(data)))
 test.check(loaded.error.is_empty() and loaded.world.settlements.age == 1 and loaded.world.settlements.stone_shipments == 1, "Age progress and market premiums reconcile through JSON saves")
 var bad = data.duplicate(true)
 bad.settlements.age = 2
 test.check(not Saves.decode(bad).error.is_empty(), "Unknown future ages are rejected")
 bad = data.duplicate(true)
 bad.settlements.stone_shipments += 1
 test.check(not Saves.decode(bad).error.is_empty(), "Forged premium totals fail economy reconciliation")
 bad = data.duplicate(true)
 bad.frontier.sites.quarry.claimed = false
 test.check(not Saves.decode(bad).error.is_empty(), "Stone age saves require their recovered discoveries")
 var old = saved.duplicate(true)
 old.settlements.erase("age")
 old.settlements.erase("stone_shipments")
 old.frontier.sites.erase("quarry")
 old.frontier.sites.orchard.claimed = false
 var original = old.frontier.sites.duplicate(true)
 loaded = Saves.decode(old)
 test.check(loaded.error.is_empty() and loaded.world.settlements.age == 0 and loaded.world.frontier.sites.has("quarry"), "Older saves gain a quarry and begin in Timber age")
 var unchanged: bool = loaded.error.is_empty()
 if unchanged:
  for id in original:
   var record: Dictionary = original[id]
   if loaded.world.frontier.sites[id].origin != Vector2i(record.x, record.y): unchanged = false
 test.check(unchanged, "Adding the quarry preserves every existing landmark origin")
 var center: Vector2i = world.frontier.sites.orchard.origin + Vector2i(2, 2)
 test.check(world.frontier.landscape_index(center) == 1 and world.frontier.landscape_index(world.frontier.sites.quarry.origin) == 2 and world.frontier.landscape_index(Vector2i(900, 900)) == 0, "Farmland and highland regions follow their saved landmarks")
 var depletion = world.terrain.depleted.duplicate()
 for x in range(-30, 30): world.frontier.landscape_index(Vector2i(x, x))
 test.check(depletion == world.terrain.depleted, "Biome presentation never depletes or moves ore")
 world.start(false)
 test.check(world.settlements.age == 0 and world.settlements.stone_shipments == 0, "New games reset age and income history")

static func ui(test: SceneTree) -> void:
 var scene = load("res://main.tscn").instantiate()
 test.root.add_child(scene)
 await test.process_frame
 scene.set_process(false)
 scene.paused = true
 scene.view.paused = true
 var world = ready_town()
 scene._bind_world(world)
 scene._inspect_site("town_hall")
 var panel = scene.hud.town_panel
 test.check(panel.age_box.visible and not panel.age_button.disabled and panel.age_text.text.contains("Stone 80 / 80"), "Town age UI exposes exact pack costs and an available project action")
 panel.age_button.pressed.emit()
 scene.hud.refresh()
 test.check(world.settlements.age == 1 and world.player.total() == 0 and not panel.age_button.visible and panel.age_text.text.contains("Stone & Water"), "Town UI completes the authoritative project and displays its new age")
 scene.queue_free()
 await test.process_frame
