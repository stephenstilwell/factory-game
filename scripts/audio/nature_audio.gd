extends AudioStreamPlayer2D
## One regional ambient voice, with four cached synthesized sound palettes.
var timer := 4.0
var voices: Array[AudioStreamWAV] = []
var current_region := 0
func _ready() -> void:
	bus = "SFX" if AudioServer.get_bus_index("SFX") >= 0 else "Master"
	volume_db = -23
	max_distance = 1000
	for region in range(4): voices.append(build_voice(region))
	stream = voices[0]

static func build_voice(region: int) -> AudioStreamWAV:
	var sample := AudioStreamWAV.new()
	sample.format = AudioStreamWAV.FORMAT_16_BITS
	sample.mix_rate = 22050
	var frames := 26460 if region >= 2 else 11025
	var bytes := PackedByteArray()
	bytes.resize(frames*2)
	var phase := 0.0
	var filtered := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 71329
	for i in range(frames):
		var time := i/22050.0
		var value := 0.0
		if region == 3:
			filtered = lerpf(filtered,rng.randf_range(-1,1),0.12)
			var envelope := sin(PI*i/float(frames))
			value = filtered*envelope*6000+sin(TAU*(210+35*sin(time*9))*time)*envelope*maxf(0,sin(time*18))*1400
		elif region == 2:
			filtered = lerpf(filtered,rng.randf_range(-1,1),0.035)
			var envelope := sin(PI*i/float(frames))
			value = filtered*envelope*15000
			if time > 0.55:
				value += sin(TAU*860*time)*exp(-(time-0.55)*15)*900
		else:
			var pulse := fposmod(time,0.17 if region == 0 else 0.22)
			var duration := 0.13 if region == 0 else 0.18
			var envelope := maxf(0,sin(pulse/duration*PI)) if pulse < duration else 0.0
			var frequency := 2100+1200*sin(pulse*15) if region == 0 else 2900+500*sin(pulse*35)
			phase += TAU*frequency/22050.0
			value = sin(phase)*envelope*(6500 if region == 0 else 4300)
		bytes.encode_s16(i*2,roundi(clampf(value,-32767,32767)))
	sample.data = bytes
	return sample

func step(delta: float, view: Node2D) -> void:
	if not view.ambient_enabled or view.paused or not view.world.frontier.enabled:
		stop()
		return
	if DisplayServer.get_name() != "headless" and not get_window().has_focus():
		stop()
		return
	if AudioServer.get_bus_index("SFX") >= 0: bus = "SFX"
	var region: int = view.world.frontier.landscape_index(Vector2i(view.world.player_position.floor()))
	if region != current_region:
		current_region = region
		stop()
		stream = voices[region]
		timer = 1.5
	if DisplayServer.get_name() == "headless": return
	timer -= delta
	if timer > 0: return
	timer = (6.0 if region == 2 else 8.0)+fposmod(view.animation_time,5.0)
	position = view.camera.position+Vector2(sin(view.animation_time)*180,-110)
	play()
