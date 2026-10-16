# Audio

The first palette contains 13 original synthesized effects and a 24-second ambient music loop: soft chords and sparse bell-like notes for Oldbridge. No audio services, external downloads, or third-party sample licenses are required. WAV assets are committed; normal development and exports do not run a generator.

Press **Esc** to open the pause menu. **Master**, **Music**, and **Sound effects** sliders appear near the top. Zero mutes that channel. Preferences persist in `user://audio_settings.cfg`, separately from factory saves. Music is quieter while paused, and audio suspends when the application loses focus.

Gameplay emits semantic presentation events only on completed actions. Mining and repairs use their existing signals; placement, pickup, transfers, completed hand crafts, research/restoration, beacon warnings, and turret shots emit feedback events. Sound does not change simulation timing, consume gameplay randomness, or enter saved world data.

`scripts/audio/audio_director.gd` owns playback, volume buses, and settings. It disconnects the old world when loading. Effects use ten reusable voices and short per-cue cooldowns. World cues fade with player distance; machine ambience examines a bounded neighborhood every 1.8 seconds and plays at most one subdued accent. Pausing stops machine accents, while menu sounds remain available.

To replace a cue, update its WAV or the cue map. Regenerate the original palette with:

```powershell
godot --headless --path . --script res://tools/generate_audio.gd
godot --headless --path . --editor --import
```

The generator uses deterministic synthesis and no player data. Sound effects are mono, 16-bit PCM at 22,050 Hz before Godot import compression. The music has a short fade at the loop boundary.

Verification covers successful versus rejected action events, world rebinding, mute, cooldowns, distance attenuation, focus handling, settings persistence, and imported resources. A native device check complements the headless suite.

Implementation reference: [Godot audio streams](https://docs.godotengine.org/en/stable/classes/class_audiostreamwav.html).