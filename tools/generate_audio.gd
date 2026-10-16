extends SceneTree
## Original synthesized palette. Regenerate with godot --headless --script res://tools/generate_audio.gd.
const RATE := 22050
const DIRECTORY := "res://assets/audio/"
func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(DIRECTORY)
	var cues := {
		"ui": [0.07, [650.0, 980.0], 0.02],
		"open": [0.17, [330.0, 495.0, 660.0], 0.0],
		"close": [0.13, [440.0, 330.0], 0.0],
		"mine": [0.12, [160.0, 890.0, 1450.0], 0.5],
		"build": [0.22, [100.0, 210.0, 425.0], 0.3],
		"pickup": [0.18, [260.0, 520.0], 0.12],
		"transfer": [0.1, [520.0, 780.0], 0.09],
		"craft": [0.3, [523.25, 659.25, 783.99], 0.0],
		"success": [0.85, [261.63, 329.63, 392.0, 523.25], 0.0],
		"repair": [0.24, [185.0, 370.0, 740.0], 0.15],
		"machine": [0.25, [72.0, 144.0, 288.0], 0.12],
		"warning": [0.65, [220.0, 277.18], 0.0],
		"shot": [0.12, [80.0, 130.0], 0.75],
	}
	for id in cues:
		var spec: Array = cues[id]
		var samples := PackedFloat32Array()
		samples.resize(int(float(spec[0]) * RATE))
		var rng := RandomNumberGenerator.new()
		rng.seed = id.hash()
		for i in samples.size():
			var t := float(i) / RATE
			var envelope := minf(1.0, t / 0.004) * exp(-6.0 * t / float(spec[0]))
			var sample := rng.randf_range(-1.0, 1.0) * float(spec[2])
			for j in spec[1].size():
				var start := float(j) * float(spec[0]) * 0.13 if id in ["open", "close", "craft", "success"] else 0.0
				if t >= start:
					sample += sin(TAU * float(spec[1][j]) * (t - start)) / float(spec[1].size()) * exp(-float(j) * t * 4.0)
			samples[i] = sample * envelope * 0.5
		_write(id, samples)
	var music := PackedFloat32Array()
	var duration := 24.0
	music.resize(int(duration * RATE))
	var chords := [[130.81, 164.81, 196.0], [110.0, 130.81, 164.81], [87.31, 130.81, 174.61], [98.0, 146.83, 196.0]]
	var melody := [523.25, 0.0, 659.25, 587.33, 392.0, 0.0, 440.0, 523.25, 349.23, 0.0, 523.25, 440.0, 392.0, 587.33, 0.0, 392.0]
	for i in music.size():
		var t := float(i) / RATE
		var chord_time := fmod(t, 6.0)
		var chord: Array = chords[int(t / 6.0)]
		var pad_envelope := sin(PI * chord_time / 6.0)
		var sample := 0.0
		for frequency in chord:
			sample += (sin(TAU * float(frequency) * t) + 0.15 * sin(TAU * float(frequency) * 2.0 * t)) * pad_envelope * 0.07
		var note_time := fmod(t, 1.5)
		var frequency: float = melody[int(t / 1.5)]
		if frequency > 0:
			var envelope := minf(1.0, note_time / 0.015) * exp(-note_time * 4.0)
			sample += (sin(TAU * frequency * note_time) + 0.18 * sin(TAU * frequency * 2.0 * note_time)) * envelope * 0.12
		var boundary_fade := minf(1.0, minf(t, duration - t) / 0.08)
		music[i] = sample * boundary_fade
	_write("oldbridge", music)
	print("Generated 13 original effects and a 24-second ambient loop.")
	quit()
func _write(id: String, samples: PackedFloat32Array) -> void:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size(): bytes.encode_s16(i * 2, int(clampf(samples[i], -0.95, 0.95) * 32767.0))
	stream.data = bytes
	var error := stream.save_to_wav(DIRECTORY + id + ".wav")
	if error != OK:
		push_error("Could not generate " + id)
		quit(1)