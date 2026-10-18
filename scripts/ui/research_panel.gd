extends VBoxContainer
const Catalog = preload("res://scripts/data/catalog.gd")
const Style = preload("res://scripts/ui/ui_style.gd")
const Reports = preload("res://scripts/ui/project_reports.gd")
const TreeView = preload("res://scripts/ui/technology_tree.gd")
const Showcase = preload("res://scripts/ui/showcase.gd")
signal research_requested(id: String)
signal recipe_requested(id: String)
var world: RefCounted
var selected_id := ""
var tree: Control
var status: Label
var recommendation: Button
var title: Label
var purpose: Label
var unlocks: Label
var requirements: Label
var progress: ProgressBar
var start_button: Button
var bench_button: Button
var prerequisite_button: Button
var art: Control
var world_token := 0

func _ready() -> void:
	add_theme_constant_override("separation",10)
	var header := HBoxContainer.new()
	add_child(header)
	status = Style.label("",14,Style.GOLD)
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(status)
	recommendation = Style.button(header,"Next achievable project",_select_recommended)
	recommendation.add_theme_font_size_override("font_size",13)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation",14)
	add_child(body)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(570,332)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_RESERVE
	body.add_child(scroll)
	tree = TreeView.new()
	scroll.add_child(tree)
	tree.selected.connect(select)
	var detail := PanelContainer.new()
	detail.custom_minimum_size.x = 310
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(detail)
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation",12)
	detail.add_child(row)
	art = Showcase.new()
	row.add_child(art)
	art.custom_minimum_size = Vector2(64,64)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	title = Style.label("",21,Style.TEXT)
	text.add_child(title)
	purpose = Style.label("",13,Style.MUTED)
	text.add_child(purpose)
	unlocks = Style.label("",13,Style.ACCENT)
	text.add_child(unlocks)
	requirements = Style.label("",13,Style.GOLD)
	text.add_child(requirements)
	progress = ProgressBar.new()
	progress.custom_minimum_size.y = 6
	progress.show_percentage = false
	text.add_child(progress)
	var actions := VBoxContainer.new()
	text.add_child(actions)
	start_button = Style.button(actions,"Start project",func(): research_requested.emit(selected_id))
	Style.action(start_button)
	prerequisite_button = Style.button(actions,"View prerequisite",_select_prerequisite)
	bench_button = Style.button(actions,"Drafting bench recipe [C]",func(): recipe_requested.emit("lab"))
	add_child(Style.label("Select a card to inspect it. Dossiers are consumed at a drafting bench; switching projects keeps your invested progress.",12,Style.MUTED))

func select(id: String) -> void:
	selected_id = id
	refresh(world)

func _select_recommended() -> void:
	var id := Reports.recommended_technology(world)
	if not id.is_empty(): select(id)

func _select_prerequisite() -> void:
	var report := Reports.technology(world,selected_id)
	if not report.missing.is_empty(): select(report.missing[0])

func refresh(state: RefCounted) -> void:
	if state == null: return
	world = state
	world.guidance.view_projects(world)
	if world_token != world.get_instance_id():
		world_token = world.get_instance_id()
		selected_id = ""
	var recommended := Reports.recommended_technology(world)
	if selected_id.is_empty(): selected_id = recommended if not recommended.is_empty() else Catalog.TECHNOLOGIES[0].id
	var reports: Dictionary = {}
	for definition in Catalog.TECHNOLOGIES: reports[definition.id] = Reports.technology(world,definition.id)
	tree.refresh(reports,selected_id)
	var definition: Dictionary = Catalog.technology(selected_id)
	var report: Dictionary = reports[selected_id]
	var active: String = world.current_research()
	status.text = "Complete the settlement opening to begin technology." if world.early.active() else ("Choose your next contribution to Oldbridge." if active.is_empty() else "ACTIVE: %s • %d/%d dossiers" % [Catalog.technology(active).name,world.research_progress,Catalog.technology(active).cost])
	if world.researched.size() == Catalog.TECHNOLOGIES.size(): status.text = "All workshop projects completed."
	recommendation.disabled = recommended.is_empty()
	title.text = definition.name
	purpose.text = definition.purpose
	unlocks.text = "UNLOCKS  " + definition.unlock
	requirements.text = report.reason if not report.reason.is_empty() else ("%d / %d dossiers • %s" % [report.progress,report.cost,"Complete" if report.state == "complete" else ("Processing at a drafting bench" if report.state == "active" else "Ready to begin")])
	progress.value = 100.0 * report.progress / report.cost
	start_button.disabled = report.state != "available"
	start_button.text = {"complete":"Project completed","active":"Current project","locked":"Requirements not met","available":"Switch to project" if not active.is_empty() else "Start project"}[report.state]
	start_button.tooltip_text = report.reason if not report.reason.is_empty() else "Select this project; no dossiers are spent by this button."
	prerequisite_button.visible = not report.missing.is_empty()
	if prerequisite_button.visible: prerequisite_button.text = "View " + Catalog.technology(report.missing[0]).name
	bench_button.disabled = not world.content_available("lab")
	art.present("item",definition.get("preview","science"))
