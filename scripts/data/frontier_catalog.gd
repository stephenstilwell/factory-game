extends RefCounted
## Authored discoveries placed by a separate, seed-stable frontier generator.
const SITES := {
	"camp": {"name": "Surveyor's Rest", "anchor": Vector2i(-17, 3), "size": Vector2i(4, 3), "hint": "Mira remembers a survey camp west of Oldbridge.", "story": "A rain-stained notebook maps the ridgelines beyond the old road. Its last page reads: Leave a useful trail for whoever comes after us.", "reward": "200 Exploration XP, 10 coal, 4 gears, 6 wire, and +1 survey region permanently.", "xp": 200, "goods": {"coal": 10, "gear": 4, "wire": 6}},
	"orchard": {"name": "The Lost Orchard", "anchor": Vector2i(7, 43), "size": Vector2i(5, 4), "hint": "Old fruit trees survived south of the settlement.", "story": "Iona's note hangs beneath a tin watering can: If anyone returns to Oldbridge, take a cutting. There should be blossom by the market again.", "reward": "250 Exploration XP and Iona's apple cutting. Reopening the trading post gives Iona a community garden to tend.", "xp": 250, "goods": {}},
	"depot": {"name": "Old Sorting Depot", "anchor": Vector2i(71, 26), "size": Vector2i(5, 4), "hint": "A cargo depot stands east of town, beyond the beacon approach.", "story": "The depot's hand-operated sorting table still works. Reconnect both cargo routes and local runners can carry shared fuel a little farther.", "reward": "500 Exploration XP and local runners: +1 Supply Hearth coverage while the trading post and town services operate.", "xp": 500, "goods": {}},
}
const MAX_BELTS := 14
const BOARD_SIZE := Vector2i(7, 5)
const BLOCKED := [Vector2i(3, 1), Vector2i(3, 2), Vector2i(3, 3)]
const DIRS := [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]
