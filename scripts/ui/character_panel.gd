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
var skill_box: VBoxContainer
var equipment_box: VBoxContainer
var section_buttons: Dictionary = {}
var section := "skills"

func _ready() -> void:
	add_theme_constant_override("separation", 14)
	add_child(Style.label("THE ENGINEER", 24, Style.ACCENT))
	add_child(Style.label("Train skills through play. Hover a skill to see how to earn XP.", 15, Style.MUTED))
	stats = Style.label("", 16, Style.GOLD)
	add_child(stats)
	var tabs := HBoxContainer.new()
	add_child(tabs)
	for id in ["skills", "equipment"]:
		section_buttons[id] = Style.button(tabs, "Skills • 1–99" if id == "skills" else "Equipment upgrades", func(): show_section(id))
	skill_box = VBoxContainer.new()
	skill_box.add_theme_constant_override("separation", 10)
	add_child(skill_box)
	for id in SkillDefinitions.SKILLS:
		var panel := PanelContainer.new()
		skill_box.add_child(panel)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 5)
		panel.add_child(box)
		var heading := HBoxContainer.new()
		box.add_child(heading)
		var title := Style.label("", 18, Style.ACCENT)
		title.autowrap_mode = TextServer.AUTOWRAP_OFF
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		heading.add_child(title)
		var progress := Style.label("", 14, Style.MUTED)
		progress.autowrap_mode = TextServer.AUTOWRAP_OFF
		heading.add_child(progress)
		var bar := ProgressBar.new()
		bar.custom_minimum_size.y = 10
		bar.show_percentage = false
		box.add_child(bar)
		var bonus := Style.label("", 14, Style.GOLD)
		box.add_child(bonus)
		panel.tooltip_text = SkillDefinitions.SKILLS[id].description
		skill_rows[id] = {"title": title, "bar": bar, "progress": progress, "bonus": bonus}
	equipment_box = VBoxContainer.new()
	equipment_box.add_theme_constant_override("separation", 14)
	add_child(equipment_box)
	equipment_box.add_child(Style.label("First tiers: working-drill lesson. Tier 2: Logistics I. Tier 3: Metallurgy and the restored workshop.", 14, Style.MUTED))
	for id in Definitions.UPGRADES:
		var panel := PanelContainer.new()
		equipment_box.add_child(panel)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 6)
		panel.add_child(box)
		var title := Style.label("", 19, Style.ACCENT)
		box.add_child(title)
		box.add_child(Style.label(Definitions.UPGRADES[id].description, 14, Style.MUTED))
		var effect := Style.label("", 16)
		box.add_child(effect)
		var materials := Style.label("", 14)
		box.add_child(materials)
		var button := Style.button(box, "", func():
			if world != null: upgrade_requested.emit(id, int(cards[id].rank)))
		cards[id] = {"title": title, "effect": effect, "materials": materials, "button": button, "rank": 1}
	show_section(section)

func show_section(id: String) -> void:
	section = id
	skill_box.visible = id == "skills"
	equipment_box.visible = id == "equipment"
	for key in section_buttons: section_buttons[key].modulate = Style.ACCENT if key == id else Color.WHITE

func refresh(state: RefCounted) -> void:
	world = state
	if world == null or stats == null: return
	var character = world.character
	stats.text = "Move %.2f tiles/s • Mine %.2f items/s • Reach %.0f tiles • Pack %d" % [world.movement_speed(), 10.0 * world.skills.multiplier("mining") / float(world.mining_duration()), world.interaction_reach(), world.player.capacity]
	for id in skill_rows:
		var row: Dictionary = skill_rows[id]
		var level: int = world.skills.level(id)
		var xp: int = world.skills.xp[id]
		row.title.text = "%s  %d / 99" % [SkillDefinitions.SKILLS[id].name, level]
		var start := SkillDefinitions.threshold(level)
		var next := SkillDefinitions.threshold(mini(99, level + 1))
		row.bar.value = 100.0 if level == 99 else 100.0 * (xp - start) / (next - start)
		row.progress.text = "%d XP • Mastered!" % xp if level == 99 else "%d XP • %d to level %d" % [xp, next - xp, level + 1]
		var next_milestone := 0
		for milestone in SkillDefinitions.MILESTONES:
			if milestone > level:
				next_milestone = milestone
				break
		var activity: String = {"mining": "hand mining", "fabrication": "hand crafting", "exploration": "movement"}[id]
		row.bonus.text = "+%.0f%% %s speed%s" % [(world.skills.multiplier(id) - 1.0) * 100.0, activity, " • Next milestone: %d" % next_milestone if next_milestone > 0 else " • All milestones earned"]
		if id == "exploration": row.bonus.text += " • Survey radius: %d regions" % world.skills.survey_radius()
	for id in cards:
		var definition: Dictionary = Definitions.UPGRADES[id]
		var card: Dictionary = cards[id]
		var level: int = character.level(id)
		card.title.text = "%s — %d/%d" % [definition.name, level, definition.values.size()]
		card.rank = level + 1
		if level >= definition.values.size():
			card.effect.text = "Current: " + Definitions.format_stat(definition.stat, character.stat(definition.stat))
			card.materials.text = "All tiers installed."
			card.button.text = "Fully upgraded"
			card.button.disabled = true
			continue
		card.effect.text = "%s → %s" % [Definitions.format_stat(definition.stat, character.stat(definition.stat)), Definitions.format_stat(definition.stat, definition.values[level])]
		var parts := PackedStringArray()
		for item in definition.costs[level]:
			parts.append("%s %d/%d" % [Catalog.item_name(item), world.player.count(item), definition.costs[level][item]])
		card.materials.text = "Materials (have/need): " + " • ".join(parts)
		var reason: String = character.error(world, id, level + 1)
		card.button.disabled = not reason.is_empty()
		card.button.text = reason if not reason.is_empty() else "Install tier %d" % (level + 1)
		card.button.tooltip_text = "Materials are consumed immediately. This upgrade is permanent and stays through saving and loading."
