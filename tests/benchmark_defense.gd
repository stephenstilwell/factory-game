extends SceneTree
## Finite-stock supply benchmark, not an unlimited per-tick ammo refill.
const Fixtures = preload("res://tests/fixtures.gd")
const Simulation = preload("res://scripts/simulation/simulation.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var results: Array = []
	for layout in ["two_guns","mixed","mixed_with_reserve","mixed_production","rifle_and_guns"]:
		var world = Fixtures.combat_town() if layout in ["mixed","mixed_with_reserve","mixed_production"] else Fixtures.defense_town()
		world.researched = ["logistics","metallurgy","routing"]
		world.player.contents = {"repair_kit":30}
		var assisted: bool = layout == "rifle_and_guns"
		if assisted:
			world.player.add("service_rifle")
			world.player.add("ammo",100)
			world.combat.toggle(world)
		var production_start: int = world.production.get("ammo",0)
		var initial_iron := 0
		var initial_ammo := 100 if assisted else 0
		if layout == "mixed_with_reserve":
			world.player.add("ammo",100)
			initial_ammo += 100
		for kind in world.Catalog.Combat.TURRETS:
			for id in world.by_kind[kind]:
				var turret = world.entities[id]
				turret.inventory.contents.clear()
				if layout == "mixed_production":
					var direction := Vector2i.LEFT if kind == "cannon_turret" and turret.cell.y != 13 else Vector2i.RIGHT
					var facing := 0 if direction == Vector2i.LEFT else 2
					world.spawn("inserter",turret.cell+direction,facing)
					var maker = world.spawn("assembler",turret.cell+direction*2,0)
					maker.recipe = "ammo"
					world.spawn("inserter",turret.cell+direction*3,facing)
					var source = world.spawn("chest",turret.cell+direction*4,0)
					source.inventory.contents = {"iron_plate":80}
					initial_iron += 80
				else:
					world.spawn("inserter",turret.cell+Vector2i.RIGHT,2)
					var source = world.spawn("chest",turret.cell+Vector2i(2,0),0)
					source.inventory.contents = {"ammo":100}
					initial_ammo += 100
		var rows: Array = []
		for arrival in range(1,11):
			world.player_position = Vector2(41.5,14.5)
			world.previous_position = world.player_position
			if not world.defense.begin(world): break
			if assisted: world.player_position = Vector2(57.5,13.5)
			var start: int = world.ticks
			for tick in range(3000):
				if assisted and not world.defense.enemies.is_empty():
					var nearest: Dictionary = {}
					var distance := 8.01
					for enemy in world.defense.enemies.values():
						var d: float = (Vector2(enemy.cell)+Vector2.ONE*0.5).distance_to(world.player_position)
						if d < distance: nearest = enemy; distance = d
					world.combat.firing = not nearest.is_empty()
					if not nearest.is_empty(): world.combat.aim = Vector2(nearest.cell)+Vector2.ONE*0.5
				Simulation.step(world)
				if world.defense.phase in ["idle","recovery"]: break
			var report: Dictionary = world.defense.last_result.duplicate()
			if report.get("wave",0) != arrival: report = {"wave":arrival,"victory":false,"ammo":world.defense.costs.ammo,"kits":world.defense.costs.kits,"damage":world.defense.costs.damage}
			report["seconds"] = (world.ticks-start)/10.0
			report["between_kits"] = 0
			if report.victory:
				world.player_position = Vector2(world.settlements.sites.workshop.port())+Vector2(-0.5,0.5)
				var before: int = world.player.count("repair_kit")
				for attempt in range(4):
					if not world.TownServices.dispatch(world): break
				report.between_kits = before-world.player.count("repair_kit")
				if layout == "mixed_with_reserve":
					preload("res://scripts/simulation/quartermaster.gd").stock(world)
					preload("res://scripts/simulation/quartermaster.gd").dispatch(world)
			rows.append(report)
			if not report.victory: break
		var remaining_ammo: int = world.player.count("ammo")
		for site in world.settlements.sites.values(): remaining_ammo += site.inventory.count("ammo")
		for entity in world.entities.values(): remaining_ammo += entity.inventory.count("ammo")+entity.output.count("ammo")+(1 if entity.carried == "ammo" else 0)
		var spent := 0
		for report in rows: spent += report.ammo
		var produced: int = int(world.production.get("ammo",0))-production_start
		if spent+remaining_ammo != initial_ammo+produced:
			push_error("Benchmark ammo conservation failed")
			quit(1)
			return
		results.append({"produced_ammo":produced,"initial_iron":initial_iron,"remaining_ammo":remaining_ammo,"layout":layout,"initial_ammo":initial_ammo,"rows":rows,"cleared":world.defense.cleared,"remaining_kits":world.player.count("repair_kit")})
	var file := FileAccess.open("res://.godot/verification/defense_tuning.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(results,"  "))
	print(JSON.stringify(results))
	quit()
