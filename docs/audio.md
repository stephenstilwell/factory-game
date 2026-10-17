# Adaptive music

The active soundtrack uses ten downloaded CC0 recordings by seven credited artist names,
about 19.5 minutes in total. These are full composed recordings, not variants of the
prototype synthesizer arrangement. Audio is local; gameplay never contacts a music service.

## Context playlists

| Context | Recordings | Direction |
| --- | --- | --- |
| Settlement / healthy shelter | The Old Tower Inn; King's Feast | Warm medieval folk and town music |
| Farmlands / Lost Orchard | Market Day; The Field Of Dreams | Lively pastoral music alternating with a gentler instrumental piece |
| Wilderness | Beautiful Forest [Orchestra]; Iremos Forest Theme Loop | Forest orchestration and mysterious woodland atmosphere |
| Greybank Highlands | Rising Moon; Cave Theme | Windy, cold fantasy atmosphere and spacious underground ambience |
| Beacon warning / active defense | Hope (Orchestral battle music); Battle Theme | Bright battle orchestration and a tense orchestral theme |

Defense takes priority, then a healthy nearby home, then the landmark biome, then
wilderness. Existing saves use the playlists immediately. Regions themselves are unchanged.

## Playback

Each context owns a shuffle bag. Every track in that context plays before its bag
refills, and the last track cannot immediately repeat across refills or returning visits.
A dedicated random generator keeps musical selection independent of seeded simulation.

Exactly two reusable players crossfade for three seconds at context changes and near song
endings. Recordings are not forced into hard loops. Continuing in one biome rotates its
playlist. Paused gameplay still advances music; focus loss suspends playback and clocks.
Peaceful context changes retain the existing five-second settling period, twenty-second
minimum dwell and one-second polling. Defense bypasses the peaceful dwell.

Esc exposes music volume, the adaptive toggle, actual title/composer, Next music track,
and Music credits. Disabling adaptation selects the settlement playlist; tracks still
rotate. Next music track is available after the current crossfade completes.

## Levels and provenance

assets/audio/licensed/manifest.json records original download URLs, source pages, artists,
license URLs, verification date and SHA-256 hashes. MUSIC-CREDITS.txt and the full CC0 legal
text are copied beside the executable by tools/build-windows.ps1. Credits are also visible
in the audio menu. CC0 is the selected license for all ten recordings, including the
dual-licensed Cave Theme.

tools/analyze_music.gd decodes recordings offline with Godot, measures full-track stereo
RMS and peak levels, and records levels.json. Catalog gains target -23 dBFS RMS, capped at
-3 dBFS peak before the existing master music attenuation. This is RMS matching, not LUFS
normalization; perceived loudness and musical fit still benefit from playtesting.
The downloaded source recordings remain byte-for-byte unchanged.

The former WAV prototype music remains in the source tree but is not used by the active
catalog. tools/generate_music.gd only regenerates those original prototype files and never
overwrites the licensed recordings.

## Verification

verify_factory.gd covers source hashes, decoded sample energy, level adjustments, unique
recordings, shuffle rotation, context selection, pause/focus behavior and save conservation.
tests/verify_licensed_music.gd runs native device decoding and actual end-of-song rotation
for all ten files without loading or modifying the player's save.
