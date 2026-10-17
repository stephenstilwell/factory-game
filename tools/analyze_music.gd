extends SceneTree
## Offline decode and RMS/peak analysis. Does not run during gameplay.
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var catalog = load("res://scripts/data/music_catalog.gd")
	var report: Dictionary = {}
	for id in catalog.TRACKS:
		var stream: AudioStream = catalog.TRACKS[id].stream
		var playback := stream.instantiate_playback()
		playback.start()
		var energy := 0.0
		var peak := 0.0
		var frames := 0
		var remaining := ceili(stream.get_length() * AudioServer.get_mix_rate())
		while remaining > 0:
			var block := playback.mix_audio(1.0, mini(8192, remaining))
			for sample in block:
				energy += sample.length_squared()
				peak = maxf(peak, maxf(absf(sample.x), absf(sample.y)))
			frames += block.size()
			remaining -= block.size()
			if block.is_empty(): break
		playback.stop()
		var rms := sqrt(energy / maxf(1.0, frames * 2.0))
		# Match average levels conservatively; never boost beyond -3 dB peak.
		var gain_db := minf(-23.0 - linear_to_db(maxf(rms, 0.000001)), -3.0 - linear_to_db(maxf(peak, 0.000001)))
		report[id] = {"seconds": stream.get_length(), "rms_db": linear_to_db(rms), "peak_db": linear_to_db(peak), "gain_db": snappedf(gain_db, 0.1)}
		print(id, ": ", report[id])
	var file := FileAccess.open("res://assets/audio/licensed/levels.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	quit()
