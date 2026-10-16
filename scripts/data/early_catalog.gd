extends RefCounted
const BUILDINGS := ["lumber_camp", "cart_post", "communal_hearth", "watermill", "charcoal_kiln"]
const TIMBER_RECIPES := ["stone_axe", "plank", "lumber_camp", "cart_post", "communal_hearth"]
const STONE_RECIPES := ["watermill", "charcoal_kiln", "sawn_plank", "charcoal"]
const SHELTER_COST := {"timber": 12, "plank": 8, "foraged_food": 4, "stone": 8}
const CROSSING_COST := {"stone": 30, "plank": 12, "coal": 4}
const START_FORAGE := {
	Vector2i(23, 13): "timber", Vector2i(25, 14): "timber", Vector2i(22, 12): "timber",
	Vector2i(26, 14): "foraged_food", Vector2i(24, 16): "foraged_food",
}
const NAMES := ["Timber & Hearth", "Stone & Water", "Iron & Industry"]
