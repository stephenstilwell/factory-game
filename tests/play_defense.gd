extends SceneTree
## Optional interactive sandbox. Normal project startup never uses this fixture.
const Fixtures = preload("res://tests/fixtures.gd")

func _initialize() -> void:
	call_deferred("_play")

func _play() -> void:
	var game = load("res://main.tscn").instantiate()
	game.save_path = "user://defense_playtest_v2.json"
	root.add_child(game)
	root.title = "Oldbridge — Defense Playtest"
	var world := Fixtures.combat_town()
	world.player.add("cannon_turret", 2)
	world.player.add("pulse_turret", 2)
	world.player.add("reinforced_wall", 6)
	world.player.add("marksman_rifle", 1)
	world.player.add("ammo", 120)
	world.player_position = Vector2(47.5, 16.5)
	world.previous_position = world.player_position
	game._bind_world(world)
	game.camera.zoom = Vector2.ONE * 0.8
	game._inspect_site("town_hall")
	game.hud.show_notice("Defense sandbox: mixed loaded defenses, service and precision rifles, reinforced barricades, and spare ammo. Light the beacon, Esc to close, then V to draw/switch weapons and hold LMB to shoot. Saves use a separate playtest slot.")
