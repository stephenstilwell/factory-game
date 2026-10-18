extends RefCounted
## Stable string IDs are shared by simulation, saves, crafting, and presentation.
## Durations are integer simulation ticks (10 ticks = 1 second).

const Combat = preload("res://scripts/data/combat_catalog.gd")
const FUEL_TICKS := 240
const TRANSPORT := ["belt", "fast_belt", "splitter", "underground_belt"]
const ITEMS := {
	"cottage": {"name": "Personal cottage", "color": "c3b28a"},
	"generator": {"name": "Charcoal dynamo", "color": "d2aa68"},
	"power_pole": {"name": "District power pole", "color": "91c8be"},
	"timber": {"name": "Timber", "color": "ab8253"},
	"plank": {"name": "Wood plank", "color": "d1ad72"},
	"foraged_food": {"name": "Fresh produce", "color": "be8c83"},
	"stone_axe": {"name": "Stone axe", "color": "9da692"},
	"lumber_camp": {"name": "Lumber camp", "color": "b99563"},
	"cart_post": {"name": "Handcart collection post", "color": "b49c72"},
	"communal_hearth": {"name": "Communal shelter", "color": "d8bb8d"},
	"watermill": {"name": "Waterwheel sawmill", "color": "8fae9e"},
	"charcoal_kiln": {"name": "Charcoal clamp", "color": "827a60"},
	"sawn_plank": {"name": "Water-sawn planks", "color": "d1ad72"},
	"charcoal": {"name": "Charcoal fuel", "color": "555c4e"},
	"fuel_depot": {"name": "Supply Hearth", "color": "d8a269"},
	"service_rifle": {"name": "Service rifle", "color": "c9ad79"},
	"marksman_rifle": {"name": "Precision rifle", "color": "9bb7c2"},
	"cannon_turret": {"name": "Piercing cannon", "color": "a6b7b0"},
	"pulse_turret": {"name": "Pulse turret", "color": "81c7be"},
	"splitter": {"name": "Splitter junction", "color": "c9a46c"},
	"underground_belt": {"name": "Underground conveyor", "color": "8bb3ab"},
	"construction_kit": {"name": "Construction kit", "color": "b69b72"},
	"wall": {"name": "Stone wall", "color": "b1a48a"},
	"reinforced_wall": {"name": "Reinforced barricade", "color": "95a5ab"},
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
	"science": {"name": "Engineering dossier", "color": "ef7974"},
	"steel": {"name": "Steel plate", "color": "e1e5d5"},
	"belt": {"name": "Conveyor", "color": "b8a565"},
	"drill": {"name": "Burner drill", "color": "cfa95d"},
	"furnace": {"name": "Stone furnace", "color": "b86f53"},
	"inserter": {"name": "Inserter", "color": "e5b95a"},
	"chest": {"name": "Storage chest", "color": "ad825b"},
	"assembler": {"name": "Assembler", "color": "709cae"},
	"lab": {"name": "Drafting bench", "color": "79bca9"},
	"fast_belt": {"name": "Fast conveyor", "color": "ce725c"},
}

const BUILD_ORDER := ["belt", "drill", "furnace", "inserter", "chest", "assembler", "lab", "fast_belt"]
const BUILDINGS := {
	"cottage": {"capacity": 0, "output_capacity": 0, "solid": true, "health": 150},
	"generator": {"capacity": 50, "output_capacity": 0, "solid": true, "fuel": true, "technology": "metallurgy"},
	"power_pole": {"capacity": 0, "output_capacity": 0, "solid": true, "technology": "metallurgy"},
	"lumber_camp": {"capacity": 0, "output_capacity": 40, "solid": true, "work_ticks": 40},
	"cart_post": {"capacity": 100, "solid": true, "work_ticks": 40},
	"communal_hearth": {"capacity": 0, "solid": true},
	"watermill": {"capacity": 40, "output_capacity": 40, "solid": true, "recipes": ["sawn_plank"]},
	"charcoal_kiln": {"capacity": 40, "output_capacity": 20, "solid": true, "recipes": ["charcoal"]},
	"fuel_depot": {"capacity": 200, "solid": true},
	"cannon_turret": {"capacity": 30, "solid": true, "health": 140, "technology": "metallurgy"},
	"pulse_turret": {"capacity": 30, "solid": true, "health": 100, "technology": "routing"},
	"splitter": {"capacity": 1, "solid": false, "technology": "routing"},
	"underground_belt": {"capacity": 1, "solid": false, "technology": "routing"},
	"wall": {"capacity": 0, "solid": true, "health": 120},
	"reinforced_wall": {"capacity": 0, "solid": true, "health": 320, "technology": "metallurgy"},
	"turret": {"capacity": 30, "solid": true, "health": 100, "technology": "logistics"},
	"belt": {"capacity": 1, "solid": false},
	"fast_belt": {"capacity": 1, "solid": false, "technology": "logistics"},
	"drill": {"capacity": 20, "solid": true, "fuel": true},
	"furnace": {"capacity": 30, "solid": true, "fuel": true, "recipes": ["iron_plate", "copper_plate", "steel"]},
	"inserter": {"capacity": 1, "solid": false},
	"chest": {"capacity": 200, "solid": true},
	"assembler": {"capacity": 40, "solid": true, "recipes": ["gear", "fuel_depot", "wire", "science", "ammo", "repair_kit", "belt", "inserter", "chest", "drill", "furnace", "assembler", "lab", "fast_belt", "wall", "reinforced_wall", "turret", "splitter", "underground_belt", "construction_kit", "service_rifle", "marksman_rifle", "cannon_turret", "pulse_turret", "generator", "power_pole", "cottage"]},
	"lab": {"capacity": 40, "solid": true},
}

const RECIPES := {
	"cottage": {"in": {"timber": 12, "plank": 12, "stone": 8}, "out": {"cottage": 1}, "ticks": 60, "machine": "assembler"},
	"generator": {"in": {"steel": 6, "gear": 6, "wire": 8, "stone": 10}, "out": {"generator": 1}, "ticks": 60, "hand": true, "machine": "assembler", "technology": "metallurgy"},
	"power_pole": {"in": {"plank": 2, "wire": 2}, "out": {"power_pole": 2}, "ticks": 15, "hand": true, "machine": "assembler", "technology": "metallurgy"},
	"stone_axe": {"in": {"timber": 2, "stone": 2}, "out": {"stone_axe": 1}, "ticks": 15, "hand": true},
	"plank": {"in": {"timber": 1}, "out": {"plank": 2}, "ticks": 15, "hand": true},
	"lumber_camp": {"in": {"timber": 6, "stone_axe": 1}, "out": {"lumber_camp": 1}, "ticks": 25, "hand": true},
	"cart_post": {"in": {"timber": 4, "plank": 4}, "out": {"cart_post": 1}, "ticks": 20, "hand": true},
	"communal_hearth": {"in": {"timber": 8, "plank": 4}, "out": {"communal_hearth": 1}, "ticks": 25, "hand": true},
	"watermill": {"in": {"timber": 8, "stone": 8, "plank": 4}, "out": {"watermill": 1}, "ticks": 35, "hand": true},
	"charcoal_kiln": {"in": {"stone": 6, "plank": 4}, "out": {"charcoal_kiln": 1}, "ticks": 25, "hand": true},
	"sawn_plank": {"in": {"timber": 2}, "out": {"plank": 6}, "ticks": 40, "machine": "watermill"},
	"charcoal": {"in": {"timber": 3}, "out": {"coal": 2}, "ticks": 60, "machine": "charcoal_kiln"},
	"fuel_depot": {"in": {"iron_plate": 10, "gear": 4, "stone": 10}, "out": {"fuel_depot": 1}, "ticks": 30, "hand": true, "machine": "assembler"},
	"service_rifle": {"in": {"iron_plate": 8, "gear": 4, "copper_plate": 4}, "out": {"service_rifle": 1}, "ticks": 35, "hand": true, "machine": "assembler", "technology": "logistics"},
	"marksman_rifle": {"in": {"steel": 6, "gear": 4, "wire": 6}, "out": {"marksman_rifle": 1}, "ticks": 45, "hand": true, "machine": "assembler", "technology": "metallurgy"},
	"cannon_turret": {"in": {"iron_plate": 8, "steel": 6, "gear": 4, "copper_plate": 4}, "out": {"cannon_turret": 1}, "ticks": 50, "hand": true, "machine": "assembler", "technology": "metallurgy"},
	"pulse_turret": {"in": {"iron_plate": 8, "wire": 6, "gear": 4}, "out": {"pulse_turret": 1}, "ticks": 45, "hand": true, "machine": "assembler", "technology": "routing"},
	"splitter": {"in": {"iron_plate": 4, "gear": 2}, "out": {"splitter": 1}, "ticks": 20, "hand": true, "machine": "assembler", "technology": "routing"},
	"underground_belt": {"in": {"iron_plate": 6, "belt": 4}, "out": {"underground_belt": 2}, "ticks": 20, "hand": true, "machine": "assembler", "technology": "routing"},
	"construction_kit": {"in": {"steel": 2, "gear": 2, "wire": 4}, "out": {"construction_kit": 1}, "ticks": 40, "machine": "assembler", "technology": "construction"},
	"wall": {"in": {"stone": 5}, "out": {"wall": 1}, "ticks": 5, "hand": true, "machine": "assembler"},
	"reinforced_wall": {"in": {"stone": 4, "steel": 2}, "out": {"reinforced_wall": 1}, "ticks": 10, "hand": true, "machine": "assembler", "technology": "metallurgy"},
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
	{"id": "logistics", "preview": "fast_belt", "name": "Supply routes", "purpose": "Move supplies faster; equip returning crews.", "cost": 10, "requires": [], "unlock": "Fast conveyors; workshop rifles, gun turrets, and ammunition"},
	{"id": "metallurgy", "preview": "generator", "name": "Foundry craft", "purpose": "Make strong steel for homes and defenses.", "cost": 20, "requires": ["logistics"], "unlock": "Steel, piercing cannons, precision rifles, reinforced barricades, charcoal dynamos, district poles and electric machine drives"},
	{"id": "routing", "preview": "splitter", "name": "District distribution", "purpose": "Branch and cross supply routes in a growing town.", "cost": 20, "requires": ["logistics"], "unlock": "Splitters, underground conveyors, and workshop pulse turrets"},
	{"id": "construction", "preview": "construction_kit", "name": "Homes for Oldbridge", "purpose": "Deliver housing supplies; restore three neighborhoods.", "cost": 25, "requires": ["metallurgy"], "unlock": "Construction kits and housing supply lines"},
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
	if id in ["service_rifle", "marksman_rifle"]: return "Components"
	if BUILDINGS.has(id): return "Buildings"
	if id in ["timber", "foraged_food", "iron_ore", "copper_ore", "coal", "stone"]: return "Resources"
	return "Components"

static func item_description(id: String) -> String:
	var descriptions := {
		"cottage": "Your optional home. Town [Y] makes a kit after shelter restoration. Place it and inspect the entrance to furnish a saved private interior. Outdoor time pauses inside. Pick up the entrance to move it without losing your room.",
		"drill": "Automatically mines the finite deposit beneath it. Uses coal or charcoal fuel. Face its chute toward a conveyor to carry ore away; move it when the deposit runs out.",
		"furnace": "Smelts iron and copper ore into plates for machines and town repairs. Load ore and coal/charcoal, then collect the plates or unload them by inserter. Select its recipe to change the metal.",
		"assembler": "Automates components and building production, freeing you from hand-crafting. Choose a recipe, feed its ingredients and remove the output with inserters.",
		"lab": "Turns engineering dossiers into the workshop project you select with T. Unlocks new production, routing and restoration options. Feed dossiers by hand or inserter.",
		"belt": "Moves items between machines and storage. R rotates its direction. Use inserters to load and unload most machines; a drill can drop ore directly onto a conveyor.",
		"fast_belt": "Carries items faster than a standard conveyor. Useful when a busy production line cannot move supplies or output quickly enough. R rotates its direction.",
		"inserter": "Moves one item at a time from the tile behind it to the tile in front. Use it to feed machines from conveyors or chests and to collect their output. R rotates pickup and drop direction.",
		"chest": "Stores supplies and finished goods in one place. Feed or empty it with inserters to buffer a production line. Manual transfers help organize your pack.",
		"generator": "Burns real coal/charcoal on demand: 2400 energy per fuel, maximum 8 units per tick. Place a district pole within 3 tiles. Idle generators preserve fuel and stored energy. Automate coal delivery by inserter.",
		"power_pole": "Links healthy poles within 6 tiles and serves electric drives and dynamos within 3 tiles. No wire item needed after construction. Inspect a drill, furnace, assembler or drafting bench to install a drive after Foundry craft.",
		"timber": "Gather fallen logs with RMB, fell a tree, or let a lumber camp harvest nearby groves. Finite resources; no starting goods.",
		"plank": "Hand-cut from timber; a waterwheel sawmill makes six planks from two timber after shelter restoration.",
		"foraged_food": "Gather berries with RMB. Supply the communal shelter; there is no hunger or spoilage.",
		"stone_axe": "Carry in your pack to gather fallen timber and berries twice as quickly. A lumber camp needs its own axe during construction.",
		"lumber_camp": "Produces 4 timber every 4 seconds within a 9 × 9 grove. Each tree lasts six harvests. Supply the first shelter to unlock automatic replanting: harvested trees regrow in 2 minutes. About six trees sustain one camp; overlapping camps share trees. Hand-cleared ground stays clear. No fuel.",
		"cart_post": "A worker collects up to four timber from the nearest lumber camp within ten tiles every four seconds. Stores timber; after Stone age, supplies mills and charcoal clamps within five tiles. No belts or fuel needed.",
		"communal_hearth": "A home for the first returning neighbors. Place near your work area, then use Town [Y] to deliver the shelter and crossing projects.",
		"watermill": "Place beside the marked old watercourse south of spawn. Two timber becomes six planks every four seconds; runs without coal. Nearby collection posts supply its timber.",
		"charcoal_kiln": "Turns three timber into two units of burner fuel every six seconds without metal or coal inputs. Charcoal uses the same fuel stock as mined coal.",
		"fuel_depot": "Shared coal storage. Automatically delivers real coal to healthy drills and furnaces within 8 tiles. Returning beacon crews extend coverage up to 12 tiles; restored depot runners add one more. Load all carried coal with Load coal, or feed continuously by inserter.",
		"service_rifle": "Carry in your pack. V draws/holsters it; hold left mouse or Space while drawn to fire during a wave. Uses one ammo per shot. Range 8, damage 16; enemy armor reduces damage. Shots can miss. Engineer [P] offers a workshop protective coat to reduce incoming damage.",
		"marksman_rifle": "Heavy precision long-rifle. V draws/holsters it; hold left mouse or Space while drawn to fire during a wave. Uses two ammo per shot. Range 11, damage 36 armor-piercing; punches through hauler armor at range with a slower fire rate. Double-click in pack or use [V] to switch between carried rifles.",
		"cannon_turret": "Range 8, 32 armor-piercing damage. Uses 2 ammunition every 1.5 seconds. Prioritizes armored haulers. Supply by inserter or manual loading.",
		"pulse_turret": "Range 4.5, 8 armor-piercing damage in a 1.8-tile burst. Slows targets for 2.5 seconds. Uses 2 ammunition per pulse. Combine with guns and cannons.",
		"splitter": "A one-tile junction. Alternates items between forward and RIGHT outputs, bypassing blocked branches. Feed from behind; R rotates.",
		"underground_belt": "A pair crosses up to six tiles. Both ends face the flow direction. G toggles entrance/exit while building; the inspector can change existing ends.",
		"construction_kit": "Automated steel, gear, and wire supplies for Town Hall housing deliveries. Three deliveries restore a neighborhood.",
		"wall": "A 120-health barrier. Equip from your pack and place across the marked eastern approach. Scavengers must break it to advance. Repair with H.",
		"reinforced_wall": "A 320-health steel-plated barrier. Absorbs heavy dismantler strikes and anchors defensive chokepoints. Costs stone and steel; repair with H.",
		"turret": "Fires at old-network constructs within six tiles. Each shot consumes one ammunition. Load by drag, Ctrl-click, or inserter. Equip from your pack to build.",
		"ammo": "Five rounds per batch. Gun turrets consume one per shot; automate production and delivery with an assembler and inserters.",
		"repair_kit": "Press H over a damaged building or civic landmark to consume one kit and restore structure health. Repair-rig upgrades and the restored Reedwater lodge improve each kit. Also available in inspection panels.",
		"coal": "Mined coal and timber charcoal share this burner fuel stock. 24 seconds of active burner work per unit. Load a nearby Supply Hearth to serve several drills and furnaces, or feed burners directly by inserter.",
		"stone": "Mine by hand to craft your first furnace. Also used in civic repairs.",
		"iron_ore": "Smelt in a coal-fueled furnace to produce iron plates.",
		"copper_ore": "Select Copper plate in a furnace to smelt this ore.",
		"iron_plate": "A foundation material for gears, buildings, science, and town repairs.",
		"copper_plate": "Used in wire, engineering dossiers, and workshop restoration.",
		"gear": "A manufactured component used in drills, inserters, assemblers, and trade shipments.",
		"wire": "One copper plate makes two wire. Used in drafting bench construction.",
		"science": "Working prototypes and plans. Supply a drafting bench to complete the workshop project you choose with T.",
		"steel": "Advanced material unlocked through Foundry craft research.",
	}
	if descriptions.has(id): return descriptions[id]
	return "A placeable building. Equip it from your pack or use its numbered hotbar shortcut."
