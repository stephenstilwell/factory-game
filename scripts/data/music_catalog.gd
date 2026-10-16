extends RefCounted
## Original rendered score assets; all share an 80 BPM musical grid.
const TRACKS := {
	"hearth": {"title": "A Place to Stay", "stream": preload("res://assets/audio/music_hearth.wav")},
	"wilds": {"title": "Paths Beyond the Crossing", "stream": preload("res://assets/audio/music_wilds.wav")},
	"farmlands": {"title": "Blossom by the Market", "stream": preload("res://assets/audio/music_farmlands.wav")},
	"highlands": {"title": "Greybank Stone", "stream": preload("res://assets/audio/music_highlands.wav")},
	"beacon": {"title": "Keep the Light", "stream": preload("res://assets/audio/music_beacon.wav")},
}
