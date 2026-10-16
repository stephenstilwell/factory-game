extends ColorRect
const Definitions = preload("res://scripts/data/story_catalog.gd")
const Style = preload("res://scripts/ui/ui_style.gd")
const Portrait = preload("res://scripts/ui/npc_portrait.gd")
signal discoveries_requested
signal finished(chapter: String)
signal project_requested(site_id: String)
var world: RefCounted
var chapter_id := ""
var page := 0
var title: Label
var speaker: Label
var text: Label
var goal: Label
var progress: Label
var next_button: Button
var project_button: Button
var portrait: Control
var entries: VBoxContainer
var dialogue: VBoxContainer
var journal_content: VBoxContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color = Color(0.02, 0.04, 0.045, 0.86)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(700, 460)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	var header := HBoxContainer.new()
	box.add_child(header)
	title = Style.label("", 24, Style.ACCENT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	Style.button(header, "Close [Esc]", close_panel)
	dialogue = VBoxContainer.new()
	dialogue.add_theme_constant_override("separation", 12)
	box.add_child(dialogue)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	dialogue.add_child(row)
	portrait = Portrait.new()
	row.add_child(portrait)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(body)
	speaker = Style.label("", 18, Style.GOLD)
	body.add_child(speaker)
	text = Style.label("", 18)
	text.custom_minimum_size = Vector2(510, 155)
	body.add_child(text)
	progress = Style.label("", 13, Style.MUTED)
	dialogue.add_child(progress)
	next_button = Style.button(dialogue, "Continue", advance)
	journal_content = VBoxContainer.new()
	journal_content.add_theme_constant_override("separation", 12)
	box.add_child(journal_content)
	journal_content.add_child(Style.label("PEOPLE, PROMISES & THE QUIET", 14, Style.GOLD))
	Style.button(journal_content, "Discoveries & expedition leads [L]", func(): discoveries_requested.emit())
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(650, 205)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	journal_content.add_child(scroll)
	entries = VBoxContainer.new()
	entries.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(entries)
	goal = Style.label("", 16, Style.GOLD)
	box.add_child(goal)
	project_button = Style.button(box, "View town project", _view_project)
	hide()

func present(state: RefCounted, chapter: String) -> bool:
	if not state.story.available(state, chapter): return false
	world = state
	chapter_id = chapter
	page = 0
	dialogue.show()
	journal_content.hide()
	_refresh_page()
	show()
	return true

func _refresh_page() -> void:
	var chapter: Dictionary = Definitions.CHAPTERS[chapter_id]
	var npc: Dictionary = Definitions.NPCS[chapter.speaker]
	title.text = chapter.title
	speaker.text = "%s • %s" % [npc.name, npc.role]
	portrait.npc_id = chapter.speaker
	portrait.queue_redraw()
	text.text = chapter.pages[page]
	goal.text = "OUR PROMISE\n" + chapter.goal
	progress.text = "%d / %d   •   Enter / Space to continue • J opens your journal after the conversation" % [page + 1, chapter.pages.size()]
	next_button.text = "Continue" if page < chapter.pages.size() - 1 else chapter.get("finish", "Back to Oldbridge")
	project_button.text = "View " + world.settlements.Definitions.SITES[chapter.site].name
	project_button.show()

func advance() -> void:
	if chapter_id.is_empty(): return
	var chapter: Dictionary = Definitions.CHAPTERS[chapter_id]
	if page + 1 < chapter.pages.size():
		page += 1
		_refresh_page()
	else: close_panel()

func open_journal(state: RefCounted) -> void:
	world = state
	chapter_id = ""
	title.text = "A place to come home to"
	dialogue.hide()
	journal_content.show()
	for node in entries.get_children():
		entries.remove_child(node)
		node.queue_free()
	var unread: Array = world.story.unread(world)
	var chapters: Array = world.story.journal_entries()
	for id in chapters:
		var button := Style.button(entries, Definitions.CHAPTERS[id].title + "  •  Replay", func(): present(world, id))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	for id in unread:
		var button := Style.button(entries, "NEW • " + Definitions.CHAPTERS[id].title, func(): present(world, id))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	if chapters.is_empty() and unread.is_empty(): entries.add_child(Style.label("Speak with Mira at the ruined trading post to begin.", 16))
	if not world.guidance.history.is_empty():
		entries.add_child(Style.label("RECENT ACTIVITY", 14, Style.GOLD))
		for i in range(world.guidance.history.size() - 1, maxi(-1, world.guidance.history.size() - 11), -1):
			var entry: Dictionary = world.guidance.history[i]
			entries.add_child(Style.label("%.1fm • %s" % [entry.tick / 600.0, entry.text], 14, Style.MUTED))
	goal.text = "WHAT WE'RE WORKING TOWARD\n" + world.story.goal(world)
	if world.story.seen.has("oren_after"): goal.text += "\n\nUNANSWERED\nThe relay plate reads: 'Cut the chain before it answers.' Who wrote it?"
	project_button.text = "View town projects"
	project_button.show()
	show()

func close_panel() -> void:
	if not visible: return
	var completed := chapter_id if not chapter_id.is_empty() and page == Definitions.CHAPTERS[chapter_id].pages.size() - 1 else ""
	hide()
	chapter_id = ""
	finished.emit(completed)

func dismiss_silently() -> void:
	hide()
	chapter_id = ""

func _view_project() -> void:
	var site_id: String = Definitions.CHAPTERS[chapter_id].site if not chapter_id.is_empty() else ""
	close_panel()
	project_requested.emit(site_id)