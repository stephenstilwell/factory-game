extends RefCounted
## Civic projects are fixed world landmarks, not craftable or reclaimable machines.

const SITES := {
	"trading_post": {
		"name": "Oldbridge trading post", "origin": Vector2i(30, 13), "size": Vector2i(3, 3), "port": Vector2i(0, 1),
		"repair": {"stone": 10, "iron_plate": 20, "gear": 5}, "credits": 0,
		"description": "Reopen the abandoned market so supplies can reach nearby families.",
		"keeper": "Mira, the trader", "greeting": "You got the doors open! Keep the parts coming; I can find buyers in the other villages.",
		"contract": "machine_parts", "reward": "Recurring supply contracts; earn trade credits for the next restoration.",
	},
	"workshop": {
		"name": "Engineers' workshop", "origin": Vector2i(35, 18), "size": Vector2i(3, 3), "port": Vector2i(0, 1),
		"repair": {"iron_plate": 20, "gear": 5, "copper_plate": 10}, "credits": 60, "requires": "trading_post",
		"description": "Fund a construction crew and reopen the region's maintenance workshop.",
		"keeper": "Oren, the engineer", "greeting": "The workshop is back. We've tuned every burner in the region to make its coal last longer.",
		"effect": {"burner_ticks": 16}, "reward": "GLOBAL: each new coal burns for 20% more active work in drills and furnaces.",
	},
	"town_hall": {
		"name": "Oldbridge Town Hall", "origin": Vector2i(42, 12), "size": Vector2i(3, 3), "port": Vector2i(0, 1),
		"repair": {"stone": 40, "iron_plate": 40, "gear": 10, "wire": 10}, "credits": 0, "requires": "workshop", "health": 300,
		"description": "Rebuild Oldbridge's heart and signal beacon. The light guides families home, but draws old salvage sentries down the eastern road. Light it only when your defenses are ready.",
		"keeper": "Ada, the warden", "greeting": "The hall is our shelter. Prepare walls, gun turrets, ammunition, and repair kits before we light the beacon.",
		"reward": "Voluntary beacon defenses. First victory brings road crews home: +5% movement while the hall is operational.",
	},
}

const CONTRACTS := {
	"machine_parts": {"name": "Parts for our neighbors", "goods": {"iron_plate": 4, "gear": 1}, "ticks": 300, "reward": 10, "buffer_batches": 10},
}
