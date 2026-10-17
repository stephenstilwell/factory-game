extends RefCounted
## Third-party CC0 recordings. Stable context IDs are independent of track IDs.
const TRACKS := {
	"tower_inn": {"title": "The Old Tower Inn", "artist": "RandomMind", "stream": preload("res://assets/audio/licensed/tower_inn.mp3"), "gain_db": -2.7},
	"kings_feast": {"title": "King's Feast", "artist": "RandomMind", "stream": preload("res://assets/audio/licensed/kings_feast.mp3"), "gain_db": -6.8},
	"market_day": {"title": "Market Day", "artist": "RandomMind", "stream": preload("res://assets/audio/licensed/market_day.mp3"), "gain_db": -12.2},
	"field_of_dreams": {"title": "The Field Of Dreams", "artist": "pauliuw", "stream": preload("res://assets/audio/licensed/field_of_dreams.mp3"), "gain_db": 3.3},
	"beautiful_forest": {"title": "Beautiful Forest [Orchestra]", "artist": "nene", "stream": preload("res://assets/audio/licensed/beautiful_forest.ogg"), "gain_db": -5.4},
	"iremos_forest": {"title": "Iremos Forest Theme Loop", "artist": "beardalaxy", "stream": preload("res://assets/audio/licensed/iremos_forest.ogg"), "gain_db": -7.8},
	"rising_moon": {"title": "Rising Moon", "artist": "RandomMind", "stream": preload("res://assets/audio/licensed/rising_moon.mp3"), "gain_db": -6.4},
	"cave_theme": {"title": "Cave Theme", "artist": "Brandon75689 (Brandon Morris / HaelDB)", "stream": preload("res://assets/audio/licensed/cave_theme.ogg"), "gain_db": -8.9},
	"hope": {"title": "Hope (Orchestral battle music)", "artist": "MintoDog", "stream": preload("res://assets/audio/licensed/hope.ogg"), "gain_db": -10.5},
	"battle": {"title": "Battle Theme", "artist": "Wolfgang_ (Theodore Kerr)", "stream": preload("res://assets/audio/licensed/battle.mp3"), "gain_db": -7.7},
}
const PLAYLISTS := {
	"hearth": ["tower_inn","kings_feast"],
	"wilds": ["beautiful_forest","iremos_forest"],
	"farmlands": ["market_day","field_of_dreams"],
	"highlands": ["rising_moon","cave_theme"],
	"beacon": ["hope","battle"],
}

static func credits_text() -> String:
	var lines := PackedStringArray(["MUSIC / CC0 1.0 Universal", "Source: OpenGameArt.org", "creativecommons.org/publicdomain/zero/1.0/", ""])
	for id in TRACKS:
		lines.append(TRACKS[id].title + " — " + TRACKS[id].artist)
	lines.append("\nFull source links and licenses: MUSIC-CREDITS.txt included with the game.")
	return "\n".join(lines)
