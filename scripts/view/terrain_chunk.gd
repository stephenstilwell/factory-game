extends Node2D

const Catalog = preload("res://scripts/data/catalog.gd")
const Frontier = preload("res://scripts/model/frontier.gd")
const Art = preload("res://scripts/view/art.gd")
const TILE := 48
var terrain: RefCounted
var frontier: RefCounted
var chunk := Vector2i.ZERO
var noise := FastNoiseLite.new()

func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	noise.seed = terrain.seed_value
	noise.frequency = 0.045

func _draw() -> void:
	var corners: Dictionary = {}
	for x in range(17):
		for y in range(17):
			var cell := chunk*16+Vector2i(x,y)
			corners[Vector2i(x,y)] = _ground_color(cell)
	for x in range(16):
		for y in range(16):
			var cell := chunk * 16 + Vector2i(x, y)
			var origin := Vector2(x, y) * TILE
			var variation := posmod(cell.x * 7381 + cell.y * 1933 + terrain.seed_value, 101)
			var region: int = frontier.landscape_index(cell) if frontier != null else 0
			var ground: Color = corners[Vector2i(x,y)]
			if frontier != null and frontier.marsh.water_at(frontier,cell):
				_water(origin,cell,variation)
				continue
			draw_polygon(PackedVector2Array([origin,origin+Vector2(TILE,0),origin+Vector2(TILE,TILE),origin+Vector2(0,TILE)]),PackedColorArray([ground,corners[Vector2i(x+1,y)],corners[Vector2i(x+1,y+1)],corners[Vector2i(x,y+1)]]))
			for i in range(3):
				var at := origin + Vector2(6 + posmod(variation * 7 + i * 17, 35), 6 + posmod(variation * 13 + i * 11, 35))
				Art.ellipse(self, at, Vector2(8 + i * 2, 3), ground.darkened(0.025))
			var deposit: Dictionary = terrain.tile(cell)
			if not deposit.is_empty():
				_ore(origin, cell, deposit, variation)
			else:
				if region == 1 and variation % 5 == 0:
					for row in range(3): draw_line(origin + Vector2(5, 13 + row * 9), origin + Vector2(42, 13 + row * 9), ground.darkened(0.12), 2)
				elif region == 2 and variation % 3 == 0:
					Art.ellipse(self, origin + Vector2(25, 32), Vector2(14, 6), ground.darkened(0.16))
					draw_line(origin + Vector2(14, 29), origin + Vector2(33, 27), ground.lightened(0.18), 2)
				for i in range(2 if variation < 60 else 4):
					var at := origin + Vector2(5 + posmod(variation * 7 + i * 13, 38), 8 + posmod(variation * 3 + i * 17, 33))
					var grass := ground.lightened(0.12) if i % 2 == 0 else ground.darkened(0.12)
					draw_line(at, at + Vector2(-3, -4), grass, 1, true)
					draw_line(at, at + Vector2(1, -6), grass, 1, true)
					if variation % 17 == 0: draw_circle(at + Vector2(1, -7), 1.4, Color("d3c99a"))
				if variation % 13 == 0: Art.ellipse(self, origin + Vector2(16, 31), Vector2(4, 2), Color("85907b"))

	Art.surface_grain(self,Rect2(Vector2.ZERO,Vector2.ONE*16*TILE),chunk*16)

func _ore(origin: Vector2, cell: Vector2i, deposit: Dictionary, variation: int) -> void:
	var color := Catalog.color(deposit.item)
	var earth := Color("454b40").lerp(color.darkened(0.55), 0.3)
	Art.ellipse(self, origin + Vector2(24, 27), Vector2(25, 22), earth)
	for i in range(3 if int(deposit.amount) > 20 else 2):
		var at := origin + Vector2(10 + posmod(variation + i * 17, 27), 10 + posmod(variation * 3 + i * 13, 27))
		var size := 6.0 + posmod(cell.x + cell.y + i, 4)
		Art.shadow(self, at + Vector2(0, 2), Vector2(size, size * 0.55))
		var polygon := PackedVector2Array([at + Vector2(-size, 0), at + Vector2(-size * 0.6, -size * 0.7), at + Vector2(size * 0.35, -size), at + Vector2(size, -size * 0.1), at + Vector2(size * 0.6, size * 0.65), at + Vector2(-size * 0.5, size * 0.6)])
		draw_colored_polygon(polygon, color.darkened(0.14))
		draw_colored_polygon(PackedVector2Array([polygon[0], polygon[1], polygon[2], at]), color.lightened(0.16))
		draw_colored_polygon(PackedVector2Array([at, polygon[2], polygon[3], polygon[4]]), color)
		draw_line(polygon[1], polygon[2], color.lightened(0.34), 1, true)

func _ground_color(cell: Vector2i) -> Color:
	var moisture := noise.get_noise_2d(cell.x,cell.y)
	var ground := Color("4b654d").lerp(Color("7a8459"),clampf(moisture+0.3,0,0.7))
	ground = ground.lerp(Color("857451"),clampf(-moisture-0.05,0,0.42))
	if frontier != null and frontier.enabled:
		ground = ground.lerp([Color("858365"),Color("3b6853"),Color("71825a")][Frontier.biome(cell,terrain.seed_value)],0.1)
		for id in frontier.Definitions.SITES:
			if not preload("res://scripts/data/biome_catalog.gd").REGIONS.has(id): continue
			var profile: Dictionary = preload("res://scripts/data/biome_catalog.gd").REGIONS[id]
			ground = ground.lerp(Color(profile.ground),0.65*frontier.landscape_weight(cell,id))
	return ground

func _water(origin: Vector2, cell: Vector2i, variation: int) -> void:
	var shade := Color("294f5c").lerp(Color("527e7b"),clampf(noise.get_noise_2d(cell.x,cell.y)+0.35,0,1))
	draw_rect(Rect2(origin,Vector2.ONE*TILE),shade)
	var sides := [
		[Vector2i.LEFT,Vector2(2,0),Vector2(2,48)],
		[Vector2i.RIGHT,Vector2(46,0),Vector2(46,48)],
		[Vector2i.UP,Vector2(0,2),Vector2(48,2)],
		[Vector2i.DOWN,Vector2(0,46),Vector2(48,46)]]
	for side in sides:
		if frontier.marsh.water_at(frontier,cell+side[0]): continue
		draw_line(origin+side[1],origin+side[2],Color("586e58"),6,true)
		draw_line(origin+side[1],origin+side[2],Color(0.66,0.78,0.67,0.35),2,true)
	for ripple in range(2):
		var at := origin+Vector2(8+variation%13,12+ripple*20)
		draw_line(at,at+Vector2(18,0),Color(0.59,0.77,0.76,0.15),1,true)
