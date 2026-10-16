extends SceneTree
var samples: Array[float] = []
var scene
func _initialize() -> void: call_deferred("run")
func run() -> void:
 scene = load("res://main.tscn").instantiate()
 root.add_child(scene)
 var world = load("res://scripts/simulation/world.gd").new(74103)
 world.start(false)
 scene._bind_world(world)
 scene.camera.position = world.player_position * 48
 root.size = Vector2i(1920, 1080)
 scene.camera.zoom = Vector2(0.7, 0.7)
 scene.set_process(false)
 scene.view.paused = true
 for i in range(240):
  await process_frame
  if i >= 60: samples.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
 samples.sort()
 print("FRONTIER BENCH process ms median=%.3f p95=%.3f" % [samples[samples.size()/2], samples[int(samples.size()*0.95)]])
 quit()
