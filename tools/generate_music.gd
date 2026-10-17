extends SceneTree
## Original deterministic arrangements, rendered offline. No runtime synthesis or external samples.
const RATE := 22050
const SECONDS := 48
const BEAT := 0.75
const PROGRESSIONS := {
	"hearth": [[48,52,55],[53,57,60],[48,52,55],[55,59,62],[57,60,64],[53,57,60],[50,53,57],[55,59,62]],
	"wilds": [[45,48,52],[53,57,60],[48,52,55],[55,59,62],[45,48,52],[50,53,57],[53,57,60],[55,59,62]],
	"farmlands": [[53,57,60],[48,52,55],[50,53,57],[55,59,62],[53,57,60],[57,60,64],[50,53,57],[55,59,62]],
	"highlands": [[38,45,50],[38,45,53],[36,43,48],[41,48,53],[38,45,50],[34,41,46],[36,43,48],[38,45,50]],
	"beacon": [[45,48,52],[53,57,60],[50,53,57],[52,55,59],[45,48,52],[48,52,55],[53,57,60],[52,55,59]],
}
const MELODIES := {
	"hearth": [64,67,72,-1,69,67,64,62,64,67,69,-1,65,64,62,67],
	"wilds": [69,-1,72,76,74,-1,72,67,69,-1,64,67,65,-1,64,67],
	"farmlands": [72,76,79,76,74,72,69,67,69,72,77,76,74,72,71,67],
	"highlands": [62,-1,57,-1,65,-1,60,-1,62,-1,58,-1,60,-1,57,-1],
	"beacon": [69,72,76,72,65,69,72,69,62,65,69,65,64,67,71,67],
}
var samples := PackedFloat32Array()
func _initialize() -> void:
	for id in PROGRESSIONS:
		if not OS.get_cmdline_user_args().is_empty() and id not in OS.get_cmdline_user_args(): continue
		var beat: float = 0.6 if id == "farmlands" else (1.0 if id == "highlands" else BEAT)
		var bars := roundi(SECONDS / (4 * beat))
		samples.resize(SECONDS * RATE)
		samples.fill(0.0)
		for bar in range(bars):
			var chord: Array = PROGRESSIONS[id][bar % 8]
			var start: float = bar * 4 * beat
			for index in range(chord.size()): note(start, int(chord[index]) + (12 if bar >= 8 and index == 0 and id != "highlands" else 0), (beat * 4.9 if id in ["farmlands", "highlands"] else 3.7), 0.035 if id == "highlands" else (0.055 if id != "beacon" else 0.045), "pad")
			note(start, int(chord[0]) - (0 if id == "highlands" else 12), (beat * 3.7 if id in ["farmlands", "highlands"] else 2.8), 0.06, "bass")
			if id == "highlands" and bar % 3 == 0: note(start + beat * 2, int(chord[2]) + 24, 3.2, 0.095, "bell")
			var melody: Array = MELODIES[id]
			if id == "beacon":
				for step in range(8):
					note(start + step * beat / 2, int(chord[step % 3]) + 12, 0.65, 0.065, "pluck")
				for step in [0, 2]: note(start + step * beat, 36, 0.3, 0.07, "pulse")
			else:
				for step in range(2):
					var pitch: int = melody[(bar * 2 + step + (4 if bar >= 8 else 0)) % melody.size()]
					if pitch >= 0:
						var voice := "air" if id == "highlands" else ("pluck" if id == "farmlands" else ("mallet" if id == "hearth" else "pluck"))
						note(start + step * beat * 2, pitch, 2.8 if id == "highlands" else (1.1 if id == "farmlands" else 1.7), 0.14 if id in ["farmlands", "highlands"] else 0.12, voice)
				if id == "farmlands":
					for step in range(4): note(start + step * beat + beat * 0.5, int(chord[step % 3]) + 12, 0.42, 0.07, "mallet")
					note(start + beat, int(chord[1]) + 12, 0.9, 0.05, "pluck")
					note(start + beat * 3, int(chord[2]) + 12, 0.9, 0.05, "pluck")
			if id != "highlands" and bar >= 8 and bar % 2 == 0: note(start + 3 * beat, int(chord[1]) + 24, 1.2, 0.035, "pluck")
			if id != "highlands" and bar % 4 == 3: note(start + 3 * beat, int(chord[2]) + 24, 2.3, 0.035, "air")
		write_track(id)
	print("Rendered requested original 48-second adaptive music tracks.")
	quit()

func note(start: float, pitch: int, duration: float, gain: float, voice: String) -> void:
	var frequency := 440.0 * pow(2.0, (pitch - 69) / 12.0)
	var offset := roundi(start * RATE)
	for i in range(roundi(duration * RATE)):
		var t := i / float(RATE)
		var attack := minf(1, t / (0.4 if voice == "pad" else 0.012))
		var release := minf(1, (duration - t) / (0.8 if voice == "pad" else 0.15))
		var value := sin(TAU * frequency * t)
		match voice:
			"pad": value = (value + 0.18 * sin(TAU * frequency * 2 * t)) * (0.85 + 0.15 * sin(t * 2.2))
			"bass": value = (value + 0.12 * sin(TAU * frequency * 2 * t)) * exp(-t * 1.2)
			"pluck": value = (value + 0.28 * sin(TAU * frequency * 2 * t) + 0.09 * sin(TAU * frequency * 3 * t)) * exp(-t * 3.8)
			"mallet": value = (value + 0.12 * sin(TAU * frequency * 2.76 * t) * exp(-t * 5)) * exp(-t * 2.6)
			"air": value = (value + 0.07 * sin(TAU * frequency * 3 * t)) * sin(PI * t / duration)
			"bell": value = (value + 0.5 * sin(TAU * frequency * 2.71 * t) + 0.2 * sin(TAU * frequency * 4.13 * t)) * exp(-t * 1.4)
			"pulse": value = sin(TAU * (frequency * 0.7 * t + frequency * 0.012 * (1 - exp(-t * 30)))) * exp(-t * 16)
		samples[(offset + i) % samples.size()] += value * attack * release * gain

func write_track(id: String) -> void:
	var peak := 0.001
	for value in samples: peak = maxf(peak, absf(value))
	var gain := minf(1.8, 0.62 / peak)
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in range(samples.size()): data.encode_s16(i * 2, roundi(samples[i] * gain * 32767))
	var stream := AudioStreamWAV.new()
	stream.mix_rate = RATE
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.data = data
	var result := stream.save_to_wav("res://assets/audio/music_" + id + ".wav")
	if result != OK:
		push_error("Music render failed: " + id)
		quit(1)
