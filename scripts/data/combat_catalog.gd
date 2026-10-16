extends RefCounted
const TURRETS := {
	"turret": {"range": 6.0, "damage": 12, "cooldown": 4, "ammo": 1, "piercing": false, "splash": 0.0},
	"cannon_turret": {"range": 8.0, "damage": 32, "cooldown": 14, "ammo": 2, "piercing": true, "splash": 0.0},
	"pulse_turret": {"range": 4.5, "damage": 8, "cooldown": 11, "ammo": 2, "piercing": true, "splash": 1.8}
}
const ENEMIES := {
	"scout": {"name": "Signal scout", "health": 24, "scaling": 4, "armor": 0, "move": 3, "damage": 6, "weight": 8.0, "color": "d59a63", "role": "Fast survey construct. Routes around isolated walls."},
	"dismantler": {"name": "Dismantler", "health": 40, "scaling": 4, "armor": 2, "move": 5, "damage": 16, "weight": 1.5, "color": "c67865", "role": "Demolition construct. Breaks through obstacles and threatens structures."},
	"hauler": {"name": "Armored hauler", "health": 72, "scaling": 6, "armor": 6, "move": 7, "damage": 10, "weight": 3.0, "color": "8eaaa2", "role": "Heavy freight construct. Armor resists ordinary rounds; use piercing guns or pulses."}
}
const RIFLE_RANGE := 8.0
const RIFLE_DAMAGE := 16
const RIFLE_COOLDOWN := 3

static func kind_at(wave: int, index: int) -> String:
	if wave >= 3 and index % 5 == 4: return "hauler"
	if wave >= 2 and index % 3 == 2: return "dismantler"
	return "scout"

static func maximum(kind: String, cleared: int) -> int:
	return int(ENEMIES[kind].health) + cleared * int(ENEMIES[kind].scaling)

static func composition(cleared: int) -> String:
	var counts: Dictionary = {}
	for i in range(4 + cleared * 2):
		var kind := kind_at(cleared + 1, i)
		counts[kind] = int(counts.get(kind, 0)) + 1
	var parts := PackedStringArray()
	for kind in counts: parts.append("%d %s" % [counts[kind], ENEMIES[kind].name])
	return ", ".join(parts)
