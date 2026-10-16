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
	noise.seed = terrain.seed_value
	noise.frequency = 0.045

func _draw() -> void:
	for x in range(16):
		for y in range(16):
			var cell := chunk * 16 + Vector2i(x, y)
			var origin := Vector2(x, y) * TILE
			var variation := posmod(cell.x * 7381 + cell.y * 1933 + terrain.seed_value, 101)
			var moisture := noise.get_noise_2d(cell.x, cell.y)
			var region: int = frontier.landscape_index(cell) if frontier != null else 0
			var ground := Color("4c6247").lerp(Color("667155"), clampf(moisture + 0.25, 0, 0.6))
			ground = ground.lerp(Color("786b50"), clampf(-moisture - 0.05, 0, 0.38))
			if frontier != null and frontier.enabled:
				ground = ground.lerp([Color("858365"), Color("3b6853"), Color("71825a")][Frontier.biome(cell, terrain.seed_value)], 0.14)
			if region == 1: ground = ground.lerp(Color("8a8058"), 0.48)
			elif region == 2: ground = ground.lerp(Color("7b8580"), 0.62)
			ground = ground.lightened((variation % 5) * 0.002)
			draw_rect(Rect2(origin, Vector2.ONE * TILE), ground)
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
