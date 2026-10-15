extends SceneTree
## Optional interactive sandbox. Normal project startup never uses this fixture.
const Fixtures = preload("res://tests/fixtures.gd")

func _initialize() -> void:
	call_deferred("_play")

func _play() -> void:
	var game = load("res://main.tscn").instantiate()
	game.save_path = "user://defense_playtest_v1.json"
	root.add_child(game)
	root.title = "Oldbridge — Defense Playtest"
	var world := Fixtures.defense_town()
	world.player_position = Vector2(47.5, 16.5)
	world.previous_position = world.player_position
	game._bind_world(world)
	game.camera.zoom = Vector2.ONE * 0.8
	game._inspect_site("town_hall")
	game.hud.show_notice("Defense sandbox: two loaded turrets and a wall are ready. Light the beacon, then Esc to watch. Saves use a separate playtest slot.")
