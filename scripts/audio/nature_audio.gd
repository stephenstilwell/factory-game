extends AudioStreamPlayer2D
## One quiet, synthesized bird voice on the existing SFX bus.
var timer := 4.0
func _ready() -> void:
	bus = "SFX" if AudioServer.get_bus_index("SFX") >= 0 else "Master"
	volume_db = -23
	max_distance = 1000
	var sample := AudioStreamWAV.new()
	sample.format = AudioStreamWAV.FORMAT_16_BITS
	sample.mix_rate = 22050
	var bytes := PackedByteArray()
	bytes.resize(11025 * 2)
	var phase := 0.0
	for i in range(11025):
		var time := i / 22050.0
		var pulse := fposmod(time, 0.17)
		var envelope := maxf(0, sin(pulse / 0.13 * PI)) if pulse < 0.13 else 0.0
		phase += TAU * (2100 + 1200 * sin(pulse * 15)) / 22050.0
		bytes.encode_s16(i * 2, roundi(sin(phase) * envelope * 6500))
	sample.data = bytes
	stream = sample

func step(delta: float, view: Node2D) -> void:
	if not view.ambient_enabled or view.paused or not view.world.frontier.enabled:
		stop()
		return
	if AudioServer.get_bus_index("SFX") >= 0: bus = "SFX"
	if DisplayServer.get_name() == "headless": return
	timer -= delta
	if timer > 0: return
	timer = 8.0 + fposmod(view.animation_time, 5.0)
	position = view.camera.position + Vector2(sin(view.animation_time) * 180, -110)
	play()
