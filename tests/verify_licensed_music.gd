extends SceneTree
## Native decoder and playlist smoke. Uses isolated preferences, never the player's save.
const Director = preload("res://scripts/audio/audio_director.gd")
var failures := 0
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var audio := Director.new()
	audio.settings_path = "user://licensed_music_smoke_unused.cfg"
	root.add_child(audio)
	audio.set_process(false)
	var score: Node = audio.music
	for context_id in score.Catalog.PLAYLISTS:
		for id in score.Catalog.PLAYLISTS[context_id]:
			score.fade = score.FADE_SECONDS
			score.bags[context_id] = [id]
			score.request(context_id, true)
			score.step(score.FADE_SECONDS, null, true, false)
			await create_timer(0.4).timeout
			var player: AudioStreamPlayer = score.players[score.incoming]
			if score.output_enabled and (not player.playing or player.get_playback_position() <= 0):
				push_error("Native recording failed: " + id)
				failures += 1
			print("Native recording: ", id, " / ", player.get_playback_position(), "s / ", player.stream.get_length(), "s total")
			if score.output_enabled:
				player.seek(player.stream.get_length() - 1.0)
				await create_timer(0.1).timeout
				score.step(0.1, null, true, false)
				if score.track == id:
					push_error("End-of-song rotation failed: " + id)
					failures += 1
	audio.settings_timer.stop()
	audio.queue_free()
	await process_frame
	print("Licensed music native smoke: ", failures, " failures")
	quit(1 if failures else 0)
