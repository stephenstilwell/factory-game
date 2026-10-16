extends RefCounted
## Stable string IDs are shared by simulation, saves, crafting, and presentation.
## Durations are integer simulation ticks (10 ticks = 1 second).

const Combat = preload("res://scripts/data/combat_catalog.gd")
const TRANSPORT := ["belt", "fast_belt", "splitter", "underground_belt"]
const ITEMS := {
	"service_rifle": {"name": "Service rifle", "color": "c9ad79"},
	"cannon_turret": {"name": "Piercing cannon", "color": "a6b7b0"},
	"pulse_turret": {"name": "Pulse turret", "color": "81c7be"},
	"splitter": {"name": "Splitter junction", "color": "c9a46c"},
	"underground_belt": {"name": "Underground conveyor", "color": "8bb3ab"},
	"construction_kit": {"name": "Construction kit", "color": "b69b72"},
	"wall": {"name": "Stone wall", "color": "b1a48a"},
	"turret": {"name": "Gun turret", "color": "85a6a6"},
	"ammo": {"name": "Ammo rounds", "color": "e2b06b"},
	"repair_kit": {"name": "Repair kit", "color": "83c6a1"},
	"iron_ore": {"name": "Iron ore", "color": "93a9b9"},
	"copper_ore": {"name": "Copper ore", "color": "d68d59"},
	"coal": {"name": "Coal", "color": "444c56"},
	"stone": {"name": "Stone", "color": "b8ae95"},
	"iron_plate": {"name": "Iron plate", "color": "c3dbe4"},
	"copper_plate": {"name": "Copper plate", "color": "e8a16c"},
	"gear": {"name": "Iron gear", "color": "a0b8bd"},
	"wire": {"name": "Copper wire", "color": "e7b07b"},
	"science": {"name": "Science pack", "color": "ef7974"},
	"steel": {"name": "Steel plate", "color": "e1e5d5"},
	"belt": {"name": "Conveyor", "color": "b8a565"},
	"drill": {"name": "Burner drill", "color": "cfa95d"},
	"furnace": {"name": "Stone furnace", "color": "b86f53"},
	"inserter": {"name": "Inserter", "color": "e5b95a"},
	"chest": {"name": "Storage chest", "color": "ad825b"},
	"assembler": {"name": "Assembler", "color": "709cae"},
	"lab": {"name": "Research lab", "color": "79bca9"},
	"fast_belt": {"name": "Fast conveyor", "color": "ce725c"},
}

const BUILD_ORDER := ["belt", "drill", "furnace", "inserter", "chest", "assembler", "lab", "fast_belt"]
const BUILDINGS := {
	"cannon_turret": {"capacity": 30, "solid": true, "health": 140, "technology": "metallurgy"},
	"pulse_turret": {"capacity": 30, "solid": true, "health": 100, "technology": "routing"},
	"splitter": {"capacity": 1, "solid": false, "technology": "routing"},
	"underground_belt": {"capacity": 1, "solid": false, "technology": "routing"},
	"wall": {"capacity": 0, "solid": true, "health": 120},
	"turret": {"capacity": 30, "solid": true, "health": 100, "technology": "logistics"},
	"belt": {"capacity": 1, "solid": false},
	"fast_belt": {"capacity": 1, "solid": false, "technology": "logistics"},
	"drill": {"capacity": 20, "solid": true, "fuel": true},
	"furnace": {"capacity": 30, "solid": true, "fuel": true, "recipes": ["iron_plate", "copper_plate", "steel"]},
	"inserter": {"capacity": 1, "solid": false},
	"chest": {"capacity": 200, "solid": true},
	"assembler": {"capacity": 40, "solid": true, "recipes": ["gear", "wire", "science", "ammo", "repair_kit", "belt", "inserter", "chest", "drill", "furnace", "assembler", "lab", "fast_belt", "wall", "turret", "splitter", "underground_belt", "construction_kit", "service_rifle", "cannon_turret", "pulse_turret"]},
	"lab": {"capacity": 40, "solid": true},
}

const RECIPES := {
	"service_rifle": {"in": {"iron_plate": 8, "gear": 4, "copper_plate": 4}, "out": {"service_rifle": 1}, "ticks": 35, "hand": true, "machine": "assembler", "technology": "logistics"},
	"cannon_turret": {"in": {"iron_plate": 8, "steel": 6, "gear": 4, "copper_plate": 4}, "out": {"cannon_turret": 1}, "ticks": 50, "hand": true, "machine": "assembler", "technology": "metallurgy"},
	"pulse_turret": {"in": {"iron_plate": 8, "wire": 6, "gear": 4}, "out": {"pulse_turret": 1}, "ticks": 45, "hand": true, "machine": "assembler", "technology": "routing"},
	"splitter": {"in": {"iron_plate": 4, "gear": 2}, "out": {"splitter": 1}, "ticks": 20, "hand": true, "machine": "assembler", "technology": "routing"},
	"underground_belt": {"in": {"iron_plate": 6, "belt": 4}, "out": {"underground_belt": 2}, "ticks": 20, "hand": true, "machine": "assembler", "technology": "routing"},
	"construction_kit": {"in": {"steel": 2, "gear": 2, "wire": 4}, "out": {"construction_kit": 1}, "ticks": 40, "machine": "assembler", "technology": "construction"},
	"wall": {"in": {"stone": 5}, "out": {"wall": 1}, "ticks": 5, "hand": true, "machine": "assembler"},
	"turret": {"in": {"iron_plate": 12, "gear": 5, "copper_plate": 5}, "out": {"turret": 1}, "ticks": 40, "hand": true, "machine": "assembler", "technology": "logistics"},
	"ammo": {"in": {"iron_plate": 2}, "out": {"ammo": 5}, "ticks": 15, "machine": "assembler", "hand": true, "technology": "logistics"},
	"repair_kit": {"in": {"iron_plate": 2, "copper_plate": 1}, "out": {"repair_kit": 1}, "ticks": 20, "machine": "assembler", "hand": true},
	"iron_plate": {"in": {"iron_ore": 1}, "out": {"iron_plate": 1}, "ticks": 32, "machine": "furnace"},
	"copper_plate": {"in": {"copper_ore": 1}, "out": {"copper_plate": 1}, "ticks": 32, "machine": "furnace"},
	"steel": {"in": {"iron_plate": 5}, "out": {"steel": 1}, "ticks": 80, "machine": "furnace", "technology": "metallurgy"},
	"gear": {"in": {"iron_plate": 2}, "out": {"gear": 1}, "ticks": 10, "machine": "assembler", "hand": true},
	"wire": {"in": {"copper_plate": 1}, "out": {"wire": 2}, "ticks": 5, "machine": "assembler", "hand": true},
	"science": {"in": {"iron_plate": 1, "gear": 1, "copper_plate": 1}, "out": {"science": 1}, "ticks": 40, "machine": "assembler", "hand": true},
	"belt": {"in": {"iron_plate": 1}, "out": {"belt": 2}, "ticks": 10, "hand": true, "machine": "assembler"},
	"drill": {"in": {"iron_plate": 5, "gear": 3, "stone": 5}, "out": {"drill": 1}, "ticks": 30, "hand": true, "machine": "assembler"},
	"furnace": {"in": {"stone": 5}, "out": {"furnace": 1}, "ticks": 15, "hand": true, "machine": "assembler"},
	"inserter": {"in": {"iron_plate": 1, "gear": 1}, "out": {"inserter": 1}, "ticks": 15, "hand": true, "machine": "assembler"},
	"chest": {"in": {"iron_plate": 2}, "out": {"chest": 1}, "ticks": 10, "hand": true, "machine": "assembler"},
	"assembler": {"in": {"iron_plate": 9, "gear": 5}, "out": {"assembler": 1}, "ticks": 40, "hand": true, "machine": "assembler"},
	"lab": {"in": {"iron_plate": 10, "gear": 5, "wire": 5}, "out": {"lab": 1}, "ticks": 40, "hand": true, "machine": "assembler"},
	"fast_belt": {"in": {"belt": 1, "gear": 2}, "out": {"fast_belt": 1}, "ticks": 15, "hand": true, "machine": "assembler", "technology": "logistics"},
}

const TECHNOLOGIES := [
	{"id": "logistics", "name": "Logistics I", "cost": 10, "requires": [], "unlock": "Fast conveyors; workshop rifles, gun turrets, and ammunition"},
	{"id": "metallurgy", "name": "Metallurgy", "cost": 20, "requires": ["logistics"], "unlock": "Steel smelting and workshop piercing cannons"},
	{"id": "routing", "name": "Advanced routing", "cost": 20, "requires": ["logistics"], "unlock": "Splitters, underground conveyors, and workshop pulse turrets"},
	{"id": "construction", "name": "Construction engineering", "cost": 25, "requires": ["metallurgy"], "unlock": "Construction kits and housing supply lines"},
]

static func technology(id: String) -> Dictionary:
	for definition in TECHNOLOGIES:
		if definition.id == id: return definition
	return {}

static func item_name(id: String) -> String:
	return ITEMS.get(id, {}).get("name", id)

static func color(id: String) -> Color:
	return Color(ITEMS.get(id, {}).get("color", "ffffff"))

static func describe(contents: Dictionary) -> String:
	var parts := PackedStringArray()
	for id in contents:
		parts.append("%s x%d" % [item_name(id), contents[id]])
	return ", ".join(parts) if not parts.is_empty() else "empty"

static func category(id: String) -> String:
	if id == "service_rifle": return "Components"
	if BUILDINGS.has(id): return "Buildings"
	if id in ["iron_ore", "copper_ore", "coal", "stone"]: return "Resources"
	return "Components"

static func item_description(id: String) -> String:
	var descriptions := {
		"service_rifle": "Carry in your pack. V draws/holsters it; hold left mouse or Space while drawn to fire during a wave. Uses one ammo per shot. Range 8, damage 16; armor reduces damage. Shots can miss.",
		"cannon_turret": "Range 8, 32 armor-piercing damage. Uses 2 ammunition every 1.5 seconds. Prioritizes armored haulers. Supply by inserter or manual loading.",
		"pulse_turret": "Range 4.5, 8 armor-piercing damage in a 1.8-tile burst. Slows targets for 2.5 seconds. Uses 2 ammunition per pulse. Combine with guns and cannons.",
		"splitter": "A one-tile junction. Alternates items between forward and RIGHT outputs, bypassing blocked branches. Feed from behind; R rotates.",
		"underground_belt": "A pair crosses up to six tiles. Both ends face the flow direction. G toggles entrance/exit while building; the inspector can change existing ends.",
		"construction_kit": "Automated steel, gear, and wire supplies for Town Hall housing deliveries. Three deliveries restore a neighborhood.",
		"wall": "A 120-health barrier. Equip from your pack and place across the marked eastern approach. Scavengers must break it to advance. Repair with H.",
		"turret": "Fires at old-network constructs within six tiles. Each shot consumes one ammunition. Load by drag, Ctrl-click, or inserter. Equip from your pack to build.",
		"ammo": "Five rounds per batch. Gun turrets consume one per shot; automate production and delivery with an assembler and inserters.",
		"repair_kit": "Press H over a damaged building or civic landmark to consume one kit and restore 50 health. Also available in inspection panels.",
		"coal": "Fuel for burner drills and furnaces. Insert it into a machine's fuel area.",
		"stone": "Mine by hand to craft your first furnace. Also used in civic repairs.",
		"iron_ore": "Smelt in a coal-fueled furnace to produce iron plates.",
		"copper_ore": "Select Copper plate in a furnace to smelt this ore.",
		"iron_plate": "A foundation material for gears, buildings, science, and town repairs.",
		"copper_plate": "Used in wire, science packs, and workshop restoration.",
		"gear": "A manufactured component used in drills, inserters, assemblers, and trade shipments.",
		"wire": "One copper plate makes two wire. Used in research lab construction.",
		"science": "Supply a research lab to unlock new technologies.",
		"steel": "Advanced material unlocked through Metallurgy research.",
	}
	if descriptions.has(id): return descriptions[id]
	return "A placeable building. Equip it from your pack or use its numbered hotbar shortcut."
