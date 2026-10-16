extends RefCounted
## Shortcuts are preferences, never inventories. Stable item IDs survive content changes.
const Catalog = preload("res://scripts/data/catalog.gd")
const SLOTS := 10
const PAGES := 2
const PATH := "user://hotbar.cfg"
var pages: Array = []
var active_page := 0
var revision := 0
var settings_path: String

func _init(path: String = PATH, starting_slots: Array = []) -> void:
	settings_path = path
	for page in PAGES:
		var row: Array = []
		row.resize(SLOTS)
		row.fill("")
		pages.append(row)
	var defaults: Array = starting_slots if not starting_slots.is_empty() else Catalog.BUILD_ORDER + ["wall", "turret"]
	for slot in mini(SLOTS, defaults.size()): pages[0][slot] = defaults[slot]
	var config := ConfigFile.new()
	if config.load(settings_path) != OK: return
	for page in PAGES:
		var stored = config.get_value("hotbar", "page_%d" % page, pages[page])
		if not stored is Array or stored.size() != SLOTS: continue
		for slot in SLOTS:
			pages[page][slot] = stored[slot] if stored[slot] is String and (stored[slot].is_empty() or Catalog.BUILDINGS.has(stored[slot])) else ""
	var selected = config.get_value("hotbar", "active_page", 0)
	active_page = clampi(selected, 0, PAGES - 1) if selected is int else 0

func item(page: int, slot: int) -> String:
	return pages[page][slot] if _valid(page, slot) else ""

func assign(page: int, slot: int, id: String) -> bool:
	if not _valid(page, slot) or (not id.is_empty() and not Catalog.BUILDINGS.has(id)): return false
	pages[page][slot] = id
	revision += 1
	return true

func swap(from_page: int, from_slot: int, to_page: int, to_slot: int, expected_revision: int) -> bool:
	if expected_revision != revision or not _valid(from_page, from_slot) or not _valid(to_page, to_slot): return false
	var previous := item(from_page, from_slot)
	pages[from_page][from_slot] = item(to_page, to_slot)
	pages[to_page][to_slot] = previous
	revision += 1
	return true

func save() -> Error:
	var config := ConfigFile.new()
	for page in PAGES: config.set_value("hotbar", "page_%d" % page, pages[page])
	config.set_value("hotbar", "active_page", active_page)
	return config.save(settings_path)

func _valid(page: int, slot: int) -> bool:
	return page >= 0 and page < PAGES and slot >= 0 and slot < SLOTS