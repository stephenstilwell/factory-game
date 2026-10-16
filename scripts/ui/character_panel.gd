extends VBoxContainer
const Style = preload("res://scripts/ui/ui_style.gd")
const Catalog = preload("res://scripts/data/catalog.gd")
const Definitions = preload("res://scripts/data/character_catalog.gd")
const SkillDefinitions = preload("res://scripts/data/skill_catalog.gd")
signal upgrade_requested(id: String, rank: int)
var world: RefCounted
var stats: Label
var cards: Dictionary = {}
var skill_rows: Dictionary = {}
var skill_box: GridContainer
var equipment_box: VBoxContainer
var section_buttons: Dictionary = {}
var section := "skills"
var commission_label: Label

func _ready() -> void:
	add_theme_constant_override("separation", 10)

	stats = Style.label("", 15, Style.GOLD)
	add_child(stats)
	var tabs := HBoxContainer.new()
	add_child(tabs)
	for id in ["skills", "equipment"]:
		section_buttons[id] = Style.button(tabs, "Skills • 1–99" if id == "skills" else "Equipment upgrades", func(): show_section(id))
	skill_box = GridContainer.new()
	skill_box.columns = 3
	skill_box.add_theme_constant_override("h_separation", 12)
	add_child(skill_box)
	for id in SkillDefinitions.SKILLS:
		var panel := PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		skill_box.add_child(panel)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 6)
		panel.add_child(box)
		var title := Style.label("", 18, Style.ACCENT)
		box.add_child(title)
		var progress := Style.label("", 13, Style.MUTED)
		box.add_child(progress)
		var bar := ProgressBar.new()
		bar.custom_minimum_size.y = 10
		bar.show_percentage = false
		box.add_child(bar)
		box.add_child(Style.label({"mining": "EARN: Hand mining and productive drill commissions.", "fabrication": "EARN: Finished crafts, automated batch commissions, and town deliveries.", "exploration": "EARN: Walk into new areas (20 XP) and discover resource patches (40 XP)."}[id], 13, Style.MUTED))
		var bonus := Style.label("", 14, Style.GOLD)
		box.add_child(bonus)
		var reward_actions := HBoxContainer.new()
		box.add_child(reward_actions)
		var pin := Style.button(reward_actions, "Track reward", func(): _pin_skill(id))
		pin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pin.add_theme_font_size_override("font_size", 13)
		var ladder := Style.label("", 13, Style.MUTED)
		for level in SkillDefinitions.milestones(id):
			ladder.text += "Lv %d: +%d%% total speed%s\n" % [level, _bonus_at(id, level), " • +1 survey region" if id == "exploration" and level in [25, 75] else ""]
		var ladder_button := Style.button(reward_actions, "All rewards", func(): ladder.visible = not ladder.visible)
		ladder_button.add_theme_font_size_override("font_size", 13)
		box.add_child(ladder)
		ladder.hide()
		skill_rows[id] = {"title": title, "bar": bar, "progress": progress, "bonus": bonus, "pin": pin}
	commission_label = Style.label("", 14, Style.MUTED)
	add_child(commission_label)
	equipment_box = VBoxContainer.new()
	equipment_box.add_theme_constant_override("separation", 10)
	add_child(equipment_box)
	equipment_box.add_child(Style.label("Manufacture permanent equipment. Later tiers follow restored neighborhoods and rescued arrivals. Pin a goal to track materials while playing.", 14, Style.MUTED))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	equipment_box.add_child(grid)
	var upgrade_order: Array = ["boots", "pickaxe", "reach", "pack", "repair", "scanner"]
	for id in Definitions.UPGRADES:
		if id not in upgrade_order: upgrade_order.append(id)
	for id in upgrade_order:
		var panel := PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(panel)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 6)
		panel.add_child(box)
		var title := Style.label("", 19, Style.ACCENT)
		box.add_child(title)
		box.add_child(Style.label(Definitions.UPGRADES[id].description, 13, Style.MUTED))
		var effect := Style.label("", 15, Style.GOLD)
		box.add_child(effect)
		var materials := Style.label("", 13)
		box.add_child(materials)
		var actions := HBoxContainer.new()
		box.add_child(actions)
		var button := Style.button(actions, "", func():
			if world != null: upgrade_requested.emit(id, int(cards[id].rank)))
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 13)
		var pin := Style.button(actions, "Track", func():
			world.guidance.pin(world, "equipment", id, int(cards[id].rank))
			refresh(world))
		pin.add_theme_font_size_override("font_size", 13)
		cards[id] = {"title": title, "effect": effect, "materials": materials, "button": button, "pin": pin, "rank": 1}
	show_section(section)

func _bonus_at(id: String, level: int) -> int:
	var count := SkillDefinitions.milestone_count(level, id)
	return 0 if count == 0 else int((SkillDefinitions.MOVE_BONUSES if id == "exploration" else SkillDefinitions.WORK_BONUSES)[count - 1])

func _next_milestone(id: String) -> int:
	for level in SkillDefinitions.milestones(id):
		if level > world.skills.level(id): return level
	return 0

func _pin_skill(id: String) -> void:
	var level := _next_milestone(id)
	if level > 0:
		world.guidance.pin(world, "skill", id, level)
		refresh(world)

func show_section(id: String) -> void:
	section = id
	skill_box.visible = id == "skills"
	commission_label.visible = id == "skills"
	equipment_box.visible = id == "equipment"
	for key in section_buttons: Style.select(section_buttons[key], key == id)
	if world != null: refresh(world)

func refresh(state: RefCounted) -> void:
	world = state
	if world == null or stats == null: return
	var character = world.character
	if section == "equipment": world.guidance.view_equipment(world)
	var status: Dictionary = world.guidance.equipment_status(world)
	section_buttons.equipment.text = "Equipment • %d READY" % status.ready if status.ready > 0 else ("Equipment • NEW" if status.new > 0 else "Equipment upgrades")
	stats.text = "Move %.2f tiles/s • Mine %.2f items/s • Reach %.0f • Pack %d • Repair %d HP/kit • Survey %d regions" % [world.movement_speed(), 10.0 * world.skills.multiplier("mining") / float(world.mining_duration()), world.interaction_reach(), world.player.capacity, character.stat("repair_power"), world.survey_radius()]
	for id in skill_rows:
		var row: Dictionary = skill_rows[id]
		var level: int = world.skills.level(id)
		var xp: int = world.skills.xp[id]
		row.title.text = "%s  %d / 99" % [SkillDefinitions.SKILLS[id].name, level]
		var start := SkillDefinitions.threshold(level)
		var next := SkillDefinitions.threshold(mini(99, level + 1))
		row.bar.value = 100.0 if level == 99 else 100.0 * (xp - start) / (next - start)
		row.progress.text = "%d XP • Mastered!" % xp if level == 99 else "%d XP • %d to level %d" % [xp, next - xp, level + 1]
		var milestone := _next_milestone(id)
		row.bonus.text = "NOW: +%d%% %s speed" % [world.skills.bonus_percent(id), "movement" if id == "exploration" else "hand work"]
		if milestone > 0:
			row.bonus.text += "\nLv %d: %d XP → +%d%% total%s" % [milestone, SkillDefinitions.threshold(milestone) - xp, _bonus_at(id, milestone), " +1 survey region" if id == "exploration" and milestone in [25, 75] else ""]
		else: row.bonus.text += "\nAll mastery rewards earned."
		row.pin.disabled = milestone == 0
		row.pin.text = "Untrack reward" if world.guidance.pinned == {"kind": "skill", "id": id, "target": milestone} else "Track reward"
	var commissions := PackedStringArray()
	for key in world.skills.commissions:
		for i in range(SkillDefinitions.COMMISSIONS.size()):
			var target: int = SkillDefinitions.COMMISSIONS[i]
			if int(world.skills.commissions[key]) >= target: continue
			commissions.append("%s %d/%d batches → +%d XP" % [Catalog.item_name(key.get_slice(":", 1)), world.skills.commissions[key], target, SkillDefinitions.COMMISSION_XP[i]])
			break
		if commissions.size() >= 3: break
	commission_label.text = "WORKING SUPPLY LINES\n" + ("Produce 10, 50, 250, 1,000, and 5,000 automated batches per recipe/resource for graduated XP. Blocked machines earn nothing." if commissions.is_empty() else "\n".join(commissions))
	for id in cards:
		var definition: Dictionary = Definitions.UPGRADES[id]
		var card: Dictionary = cards[id]
		var level: int = character.level(id)
		card.title.text = "%s — %d/%d" % [definition.name, level, definition.values.size()]
		card.rank = level + 1
		card.pin.visible = level < definition.values.size()
		if level >= definition.values.size():
			card.effect.text = "Current: " + Definitions.format_stat(definition.stat, character.stat(definition.stat))
			card.materials.text = "All tiers installed."
			card.button.text = "Fully upgraded"
			card.button.disabled = true
			continue
		card.effect.text = "%s → %s" % [Definitions.format_stat(definition.stat, character.stat(definition.stat)), Definitions.format_stat(definition.stat, definition.values[level])]
		var parts := PackedStringArray()
		for item in definition.costs[level]: parts.append("%s %d/%d" % [Catalog.item_name(item), world.player.count(item), definition.costs[level][item]])
		card.materials.text = "Have / need: " + " • ".join(parts)
		var reason: String = character.error(world, id, level + 1)
		card.button.disabled = not reason.is_empty()
		card.button.text = reason if not reason.is_empty() else "READY • Install tier %d" % (level + 1)
		card.button.tooltip_text = "Consumes the listed materials once. Permanent; saved with your engineer."
		card.pin.text = "Untrack" if world.guidance.pinned == {"kind": "equipment", "id": id, "target": level + 1} else "Track"
