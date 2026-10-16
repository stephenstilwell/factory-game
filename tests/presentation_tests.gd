extends RefCounted
const World = preload("res://scripts/simulation/world.gd")
const Saves = preload("res://scripts/persistence/save_service.gd")

static func run(test: SceneTree) -> void:
	var scene = load("res://main.tscn").instantiate()
	test.root.add_child(scene)
	var world := World.new()
	scene._bind_world(world)
	scene.paused = true
	var polish = scene.presentation
	var path := "user://presentation_verification_%d.cfg" % Time.get_ticks_usec()
	polish.settings_path = path
	polish.reduced_motion = false
	polish.ambient_enabled = true
	polish.reduced_control.set_pressed_no_signal(false)
	polish.ambient_control.set_pressed_no_signal(true)
	polish.apply_preferences()
	var before: Dictionary = Saves.encode(world)
	world.feedback_requested.emit("build", Vector2i.ZERO)
	test.check(scene.view.effects.rings.size() == 1, "Successful construction produces a transient confirmation ring")
	for i in range(150):
		world.feedback_requested.emit("build", Vector2i(i, 0))
	test.check(scene.view.effects.rings.size() <= 16 and scene.view.effects.particles.size() <= 96, "Action effects remain bounded during mass construction")
	scene.view.effects.step(1.0)
	test.check(scene.view.effects.rings.is_empty() and scene.view.effects.particles.is_empty(), "Presentation particles and rings expire completely")
	test.check(Saves.encode(world) == before, "Presentation feedback cannot change authoritative factory state")
	var button: Button = scene.hud.pause_button
	polish._tint(button, Color(1.1, 1.1, 1.1), 0.1)
	polish._tint(button, Color.WHITE, 0.1)
	test.check(polish.tweens.size() <= 1, "Repeated hover feedback replaces its tween rather than stacking animations")
	polish.reduced_control.button_pressed = true
	test.check(polish.reduced_motion and scene.view.reduced_motion and polish.tweens.is_empty(), "Reduced motion cancels active interface tweens immediately")
	world.feedback_requested.emit("build", Vector2i.ZERO)
	test.check(scene.view.effects.rings.is_empty() and scene.view.effects.particles.is_empty(), "Reduced motion prevents new action pulses and bursts")
	scene.hud.toggle_inventory()
	test.check(scene.hud.workspace.modulate.a == 1.0 and not scene.hud.world_has_pointer(), "Reduced-motion menus open immediately and keep input blocking")
	scene.hud.close_workspace()
	polish.ambient_control.button_pressed = false
	var config := ConfigFile.new()
	test.check(config.load(path) == OK and config.get_value("visuals", "reduced_motion") == true and config.get_value("visuals", "ambient_enabled") == false, "Presentation choices persist separately from world saves")
	polish.reduced_control.button_pressed = false
	polish.ambient_control.button_pressed = true
	world.feedback_requested.emit("build", Vector2i.ZERO)
	scene._bind_world(World.new())
	test.check(scene.view.effects.rings.is_empty(), "Loading another world clears old action effects")
	world.feedback_requested.emit("build", Vector2i.ZERO)
	test.check(scene.view.effects.rings.is_empty(), "Old worlds cannot send visual events after rebinding")
	var temporary := Button.new()
	scene.hud.add_child(temporary)
	temporary.free()
	await test.process_frame
	test.check(is_instance_valid(scene), "Deferred styling tolerates a transient button freed before decoration")
	# Teardown while a menu tween is active exercises signal and tween ownership.
	scene.hud.toggle_inventory()
	scene.queue_free()
	await test.process_frame
	DirAccess.remove_absolute(path)
