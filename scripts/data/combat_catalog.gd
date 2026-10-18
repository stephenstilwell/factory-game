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
const MAX_WEAPON_COOLDOWN := 15
const WEAPONS := {
	"service_rifle": {
		"name": "Service rifle",
		"range": 8.0,
		"damage": 16,
		"cooldown": 3,
		"ammo": 1,
		"piercing": false,
		"role": "Rapid-fire carbine. Effective against fast scouts; enemy armor reduces damage.",
		"technology": "logistics"
	},
	"marksman_rifle": {
		"name": "Precision rifle",
		"range": 11.0,
		"damage": 36,
		"cooldown": 9,
		"ammo": 2,
		"piercing": true,
		"role": "Heavy armor-piercing rifle. Consumes 2 ammo with slower fire rate; punches through hauler armor at range.",
		"technology": "metallurgy"
	}
}

static func kind_at(wave: int, index: int) -> String:
	return encounter(wave).units[index]

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

# Authored encounter lessons; sizes remain bounded at 4–22 constructs.
const MAX_SPAWN_DELAY := 100
const ENCOUNTERS := [
	{"name":"First signal","units":["scout","scout","scout","scout"],"gap":15,"breaks":[],"gates":[0],"lesson":"One central approach. Learn ammunition buffers and overlapping gunfire."},
	{"name":"The split road","units":["scout","scout","dismantler","scout","scout","dismantler"],"gap":15,"breaks":[],"gates":[0,1,2],"lesson":"Dismantlers join scouts across three eastern approaches."},
	{"name":"Freight from the Quiet","units":["scout","scout","dismantler","scout","hauler","scout","dismantler","scout"],"gap":15,"breaks":[],"gates":[0,1,2],"lesson":"First armored hauler. Ordinary bullets lose damage to armor."},
	{"name":"Survey rush","units":["scout","scout","scout","dismantler","scout","scout","scout","dismantler","scout","scout"],"gap":8,"breaks":[],"gates":[1,2,0],"lesson":"Fast scout-heavy arrivals. Cover both flanks rather than one gun cluster."},
	{"name":"Broken convoy","units":["scout","scout","hauler","dismantler","scout","scout","hauler","dismantler","scout","hauler","dismantler","scout"],"gap":18,"breaks":[6],"gates":[0,0,1,2],"lesson":"Armored freight in two groups; a 6-second reinforcement pause."},
	{"name":"Hold the crossing","units":["scout","dismantler","scout","scout","hauler","dismantler","scout","dismantler","scout","scout","hauler","dismantler","scout","scout"],"gap":10,"breaks":[7],"gates":[1,2,0],"lesson":"Two mixed groups; a 10-second reinforcement pause tests resupply."},
	{"name":"Scouts ahead of steel","units":["scout","scout","scout","scout","dismantler","hauler","hauler","dismantler","scout","scout","scout","scout","dismantler","hauler","hauler","dismantler"],"gap":12,"breaks":[8],"gates":[2,1,0],"lesson":"Scout screens followed by armored pairs; an 8-second pause between groups."},
	{"name":"The flanking sweep","units":["scout","dismantler","scout","scout","dismantler","scout","hauler","dismantler","scout","scout","dismantler","scout","hauler","dismantler","scout","scout","dismantler","scout"],"gap":7,"breaks":[9],"gates":[1,2,1,0,2],"lesson":"Rapid flanking packets; an 8-second reinforcement pause."},
	{"name":"The long freight","units":["scout","scout","hauler","dismantler","scout","scout","hauler","dismantler","scout","scout","hauler","dismantler","scout","scout","hauler","dismantler","scout","scout","hauler","dismantler"],"gap":15,"breaks":[10],"gates":[0,1,2],"lesson":"Heavy mixed traffic; a 10-second pause separates two supply tests."},
	{"name":"Last eastern arrival","units":["scout","dismantler","scout","hauler","dismantler","scout","scout","dismantler","scout","hauler","dismantler","scout","scout","dismantler","scout","hauler","dismantler","scout","scout","dismantler","hauler","dismantler"],"gap":10,"breaks":[7,14],"gates":[0,1,2,2,1,0],"lesson":"Three mixed groups with 10-second pauses. This secures the current eastern route."},
]

static func encounter(wave: int) -> Dictionary:
	return ENCOUNTERS[clampi(wave-1,0,ENCOUNTERS.size()-1)]

static func spawn_delay(wave: int, next_index: int) -> int:
	var definition := encounter(wave)
	if next_index in definition.breaks: return 60 if wave == 5 else (80 if wave in [7,8] else 100)
	return int(definition.gap)

static func gate_index(wave: int, index: int) -> int:
	var gates: Array = encounter(wave).gates
	return int(gates[index % gates.size()])
