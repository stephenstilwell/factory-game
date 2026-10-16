# Adaptive audio

The game uses five original synthesized 48-second scores, alongside its existing action and UI effects. Tracks are rendered ahead of time and committed as WAV assets; there is no runtime music synthesis, streaming service, external sample dependency, or new gameplay clock.

## Music contexts

| Context | Track | Character |
| --- | --- | --- |
| Wilderness / the empty timber opening | Paths Beyond the Crossing | Sparse plucked notes and a soft harmonic bed |
| Within ten tiles of a healthy communal shelter or restored civic building | A Place to Stay | Warm mallets and settled major harmonies |
| Orchard farmlands | Blossom by the Market | Brighter melody with quiet answering plucks |
| Greybank highlands | Greybank Stone | Sparse airy notes and minor harmonies |
| Beacon warning or active defense | Keep the Light | Low pulse and a more active repeating figure |

Defense takes priority, then home, then landmark biome, then wilderness. Ruined civic landmarks do not claim the home theme. The score reads player location, existing region boundaries and defense state without changing any of them. It works in existing saves too.

## Transitions and controls

Peaceful changes require five seconds in the new context and at least twenty seconds since the previous transition. A one-second polling interval bounds context work. Defense bypasses the peaceful hold; if a fade is already running, it finishes before the next change. Brief crossings and repeated menu openings do not restart the current track.

Transitions use a three-second equal-power crossfade with exactly two reusable music players. Once a fade completes, the previous player's stream is released. Tracks use a common 80 BPM grid and compatible tonal material; their second halves vary the voicing and melody. Loop tails wrap through the start during rendering, and samples remain below clipping.

**Esc** opens sound controls. Master, Music and Sound effects volume keep their existing behavior. **Music follows places and beacon activity** defaults on; disabling it selects a fixed calm home theme. A Now playing label identifies the selected track. Volume zero still mutes music in either mode.

Music quietly continues while paused, with a smooth six-decibel reduction. Context decisions stop while gameplay is paused; focus loss suspends both music players and their transition clock. World loading replaces listeners, reevaluates location and preserves the current track if it still fits. Preferences, including the adaptive toggle, live in `user://audio_settings.cfg` rather than factory saves.

## Sound effects

The original thirteen synthesized effects cover menus, mining, building, pickup, transfer, crafting, restoration, repair, machinery, warnings and shots. Damage reuses the mining accent. Ten reusable SFX voices and short per-cue cooldowns prevent unbounded overlap. Distance attenuates world cues; machine ambience checks a bounded neighborhood every 1.8 seconds and emits at most one accent. Menu sounds remain available during pause.

## Authoring and verification

Generate the current score:

```powershell
godot --headless --path . --script res://tools/generate_music.gd
godot --headless --path . --editor --import
```

The deterministic generator renders mono 16-bit PCM at 22,050 Hz. Godot imports the committed assets with its configured audio compression. Normal development and exported builds do not run the generator. `scripts/data/music_catalog.gd` maps stable musical IDs to titles and streams; `scripts/audio/adaptive_music.gd` owns selection and mixing, while the existing audio director owns buses and preferences.

The older `tools/generate_audio.gd` still regenerates the original effects and legacy Oldbridge loop; that legacy loop is no longer the active score.

Tests cover distinct audible assets, safe peaks and loop seams, context priority, boundary hysteresis, crossfade gains and cleanup, fixed mode, pause/focus handling, settings, and save-state conservation. `tests/capture_music.gd` exercises native playback in all five contexts and captures the small-window options panel. Native playback checks confirm device decoding and advancing playback positions; musical taste and long-session repetition still benefit from playtesting.
