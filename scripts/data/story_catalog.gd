extends RefCounted
## Authored story data. IDs are save keys; dialogue never grants gameplay resources.
const NPCS := {
	"trading_post": {"name": "Mira", "role": "Trader of the crossing", "color": "bd795b", "before": "mira_before", "after": "mira_after"},
	"workshop": {"name": "Oren", "role": "Oldbridge's engineer", "color": "70999a", "before": "oren_before", "after": "oren_after"},
	"town_hall": {"name": "Ada", "role": "Warden of Oldbridge", "color": "88976a", "before": "ada_before", "after": "ada_after"},
}
const CHAPTERS := {
	"arrival": {
		"title": "At the broken crossing", "speaker": "trading_post", "site": "trading_post",
		"pages": [
			"You came. I was beginning to think my letter had washed out with the bridge. Oldbridge used to be the place every road led to. When the beacon chain went dark, the wagons stopped. Then the families left.",
			"They're waiting in camps beyond the ridge. I promised them a market, a working road, somewhere dry to sleep. I can find the buyers and Oren can mend the machines. What we need is someone who can make enough parts to keep us going.",
			"Start small. There's stone beside the road: gather five pieces and craft a furnace with C. Iron and coal will get your first machines working. Then help me reopen the trading post. Let's give people a reason to come home."
		], "goal": "Reopen the crossing. Bring the first families home.", "finish": "Begin rebuilding"
	},
	"mira_before": {
		"title": "A road needs somewhere to end", "speaker": "trading_post", "site": "trading_post",
		"pages": [
			"Renn asked if his children could come back before the cold. I told him yes. At the moment all I have for them is a boarded counter and that promise.",
			"Repair this post and I can send machine parts to our neighbors: four iron plates and a gear per shipment. Their trade will pay the crew we need at Oren's workshop. Every furnace you build gets those wagons a little closer."
		], "goal": "Restore the trading post, then keep its supply contracts running."
	},
	"mira_after": {
		"title": "The first wagon", "speaker": "trading_post", "site": "trading_post",
		"pages": [
			"Look at that counter. I haven't heard a wagon stop here in years. Renn and his sister's family have made camp by the market; they wanted to see the crossing with their own eyes.",
			"We can trade again. Keep the parts coming and I'll put the proceeds toward the workshop crew. Those crates aren't just sales. They're proof that Oldbridge can keep a promise."
		], "goal": "Earn 60 trade credits and help Oren restore the workshop."
	},
	"oren_before": {
		"title": "What still works", "speaker": "workshop", "site": "workshop",
		"pages": [
			"I stayed to listen. Before the Quiet, the beacon glass sang through every pipe in this town. Heat, light, the road signals: one enchanted network. Then it all stopped on the same night.",
			"Coal still burns. Gears still turn. Reopen my workshop and we'll build something we can maintain ourselves. Mira's contracts can pay the crew: sixty trade credits, plus the metal and gears. Once the benches are clear, I can make every burner use its coal better."
		], "goal": "Reopen the market, fund the crew, and restore the workshop."
	},
	"oren_after": {
		"title": "Under the workbench", "speaker": "workshop", "site": "workshop",
		"pages": [
			"The crew are back at their benches. We have tuned the region\'s burners: each new piece of coal now lasts twenty percent longer. We can also build you a service rifle. Research Supply routes, craft it, and press V to draw it. Keep real ammunition in your pack; we cannot fight the old network with empty barrels.",
			"Steel barrels make piercing cannons that stop armored haulers. With District distribution, we can turn salvaged relay coils into pulse turrets to slow groups. Keep their ammunition arriving by inserter. I found this relay plate under the old workbench. Someone scratched words across the maker's seal: 'Cut the chain before it answers.' The night the beacons failed, we called it an accident. I'm no longer sure. Keep the plate in mind when we repair Ada's beacon."
		], "goal": "Rebuild Town Hall so returning families have a safe shelter."
	},
	"ada_before": {
		"title": "A roof before a signal", "speaker": "town_hall", "site": "town_hall",
		"pages": [
			"A light can tell people where to go. It cannot keep the rain off their children. Before we call anyone down the eastern road, this hall needs a roof, dry beds, and Oren's bracing from the workshop.",
			"The old network still sends maintenance constructs to a beacon call. Scouts once inspected the roads, dismantlers cleared damaged buildings, and armored haulers carried the wreckage away. Now they treat our rebuilt homes as salvage. Repairing the hall will not wake them. Lighting its beacon will; that decision stays with you."
		], "goal": "Restore the workshop first, then rebuild Town Hall and prepare its defenses."
	},
	"ada_after": {
		"title": "Room for a name", "speaker": "town_hall", "site": "town_hall",
		"pages": [
			"Dry bedding. A sound roof. Space to write a family's name beside a door instead of a number on a camp list. You've given them somewhere they can stay.",
			"The hall is a beginning. Research Homes for Oldbridge at your workshop with T, then send construction kits, steel, and copper to our hatch. Every three housing deliveries will restore another neighborhood. Returning crews will help our burners use coal better. A steady supply line means real homes.",
			"When you are ready, light the beacon from this project. You will have fifteen seconds and a list of what is coming; you can cancel during that warning. Each safe arrival brings three families and relief credits; Mira can trade twenty credits for coal, ammunition, and repair kits. Every second arrival brings enough crew to extend our hearth delivery routes. Later calls draw constructs to three eastern gates. Until you choose to signal, we keep building."
		], "goal": "Restore neighborhoods with housing deliveries. Prepare defenses and signal when you choose."
	},
	"first_homecoming": {
		"title": "A place to come home to", "speaker": "town_hall", "site": "town_hall",
		"pages": [
			"Three families made it through. One of the children asked where the school was. She was already planning where she would sit, and which road her friends would take. I had forgotten what it sounded like to make plans here.",
			"The returning road crews have cleared our paths; you'll move five percent faster while the hall is operational. There are more people beyond the ridge. We can call them when we're ready. But Oren says something in the old relay answered our light. We need to understand that warning before we reconnect the chain."
		], "goal": "Keep the eastern road safe. Find out why the beacon chain went silent."
	},
	"ada_recovery": {
		"title": "Keep the promise", "speaker": "town_hall", "site": "town_hall",
		"pages": [
			"The light is out, but we're still here. Your factory and everything you've learned are intact. Use repair kits on the hall with H, then strengthen the eastern approach. The next signal is yours to choose; nobody is asking you to rush."
		], "goal": "Repair Town Hall to restore town services, then prepare before trying again."
	},
}