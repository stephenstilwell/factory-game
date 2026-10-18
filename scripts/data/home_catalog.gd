extends RefCounted
## Decoration definitions are separate from machine recipes and production inventories.
const SIZE := Vector2i(10, 8)
const KIT_COST := {"timber": 12, "plank": 12, "stone": 8}
const PIECES := {
 "chair": {"name": "Wooden chair", "size": Vector2i(1, 1), "cost": {"plank": 3}, "description": "A chair for the kitchen table or a quiet reading corner.", "color": "b98d5c"},
 "table": {"name": "Dining table", "size": Vector2i(2, 1), "cost": {"plank": 4}, "description": "A broad table for a shared meal. Rotate it to suit your room.", "color": "c39966"},
 "bed": {"name": "Patchwork bed", "size": Vector2i(2, 2), "cost": {"plank": 6, "timber": 2}, "description": "A cozy bed with a salvaged quilt. Decoration only; no sleep timer or stat bonus.", "color": "8fae9e"},
 "shelf": {"name": "Bookcase", "size": Vector2i(2, 1), "cost": {"plank": 4}, "description": "Shelves for recovered stories and workshop notebooks.", "color": "9b7857"},
 "lamp": {"name": "Copper lantern", "size": Vector2i(1, 1), "cost": {"iron_plate": 2, "wire": 2}, "description": "A warm pool of light for your room. Decorative; draws no factory power.", "color": "edc77f"},
 "planter": {"name": "Leafy planter", "size": Vector2i(1, 1), "cost": {"plank": 2, "stone": 2}, "description": "Bring a little green indoors. Needs no watering or production upkeep.", "color": "8eaf76"},
 "bench": {"name": "Timber bench", "size": Vector2i(2, 1), "cost": {"plank": 4}, "description": "A long seat for an entryway or beside the hearth.", "color": "c29a69"},
 "hearth": {"name": "Stone fireplace", "size": Vector2i(2, 1), "cost": {"stone": 8}, "description": "A welcoming decorative fireplace. Uses no fuel and grants no production bonus.", "color": "a4a698"},
 "screen": {"name": "Room divider", "size": Vector2i(2, 1), "cost": {"plank": 4, "timber": 2}, "description": "Create a bedroom nook or separate your reading corner.", "color": "bcae87"},
 "crate": {"name": "Keepsake box", "size": Vector2i(1, 1), "cost": {"plank": 2}, "description": "A decorative box for the stories of your travels. Not a factory storage chest.", "color": "ae8154"},
 "plinth": {"name": "Stone display stand", "size": Vector2i(1, 1), "cost": {"stone": 4, "plank": 2}, "description": "Give a recovered ornament pride of place. Includes a small ceramic keepsake.", "color": "c1b9a3"},
 "rug": {"name": "Market woven rug", "size": Vector2i(2, 2), "layer": 0, "cost": {"foraged_food": 4}, "market": true, "description": "Barter four fresh produce at the restored market for a woven rug. Furniture can sit on top.", "color": "ba7a68"}
}
const STYLES := [
 {"name": "Timber & cream", "floor": "b49469", "wall": "d8cdb2", "requires": ""},
 {"name": "Orchard greens", "floor": "b9a37b", "wall": "8da88b", "requires": "orchard"},
 {"name": "Greybank stone", "floor": "8f9791", "wall": "b9bbb0", "requires": "quarry"}
]
static func footprint(kind: String, direction: int) -> Vector2i:
	var size: Vector2i = PIECES[kind].size
	return Vector2i(size.y, size.x) if posmod(direction, 2) == 1 else size
