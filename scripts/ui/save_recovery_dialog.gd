extends ConfirmationDialog
## Read-only file inspection; confirmation asks the composition root to validate and load again.
const Style = preload("res://scripts/ui/ui_style.gd")
const Saves = preload("res://scripts/persistence/save_service.gd")
signal load_selected(path: String)
signal save_selected(path: String, title: String)
const Slots = preload("res://scripts/persistence/save_slots.gd")
var slot_picker: OptionButton
var slot_name: LineEdit
var explanation: Label
var base := ""
var saving := false
var selected_slot_path := ""
var choices: Array[Button] = []
var records: Array = []
var selected_path := ""

func _ready() -> void:
	theme = Style.theme()
	title = "Saved games and recovery"
	exclusive = true
	get_ok_button().text = "Load selected save"
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	add_child(box)
	var slot_row := HBoxContainer.new()
	box.add_child(slot_row)
	slot_picker = OptionButton.new()
	slot_picker.custom_minimum_size.x = 230
	slot_row.add_child(slot_picker)
	slot_name = LineEdit.new()
	slot_name.placeholder_text = "Factory name"
	slot_name.max_length = 40
	slot_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot_row.add_child(slot_name)
	slot_picker.item_selected.connect(func(_index): _slot_changed())
	explanation = Label.new()
	explanation.text = "Choose a save to load. This replaces your current session.\nFiles stay unchanged until you choose Save game."
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explanation.custom_minimum_size.x = 640
	box.add_child(explanation)
	for heading in ["CURRENT SAVE", "PREVIOUS SAVE / BACKUP", "AUTOSAVE / SEPARATE RECOVERY", "PREVIOUS AUTOSAVE"]:
		var button := Button.new()
		button.custom_minimum_size = Vector2(640, 95)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.toggle_mode = true
		button.set_meta("heading", heading)
		var index := choices.size()
		button.pressed.connect(func(): select(index))
		box.add_child(button)
		choices.append(button)
	confirmed.connect(func():
		if saving: save_selected.emit(selected_slot_path, slot_name.text)
		elif not selected_path.is_empty(): load_selected.emit(selected_path))

func open(path: String, save_mode: bool = false) -> void:
	base = Slots.base_path(path)
	saving = save_mode
	title = "Save factory to slot" if saving else "Saved games and recovery"
	get_ok_button().text = "Save to selected slot" if saving else "Load selected save"
	slot_name.visible = saving
	explanation.text = "Saving replaces this slot's current save and preserves its previous save as backup. Other slots and autosaves remain unchanged." if saving else "Choose a slot and recovery copy. Loading replaces your current session; files stay unchanged until you choose Save game."
	slot_picker.clear()
	for index in range(4): slot_picker.add_item(Slots.label(base, index), index)
	slot_picker.select(Slots.index_for(path))
	_slot_changed()
	popup_centered()

func _slot_changed() -> void:
	var path := Slots.slot_path(base, slot_picker.selected)
	selected_slot_path = path
	slot_name.text = Slots.label(base, slot_picker.selected)
	records = [Saves.describe(path, true), Saves.describe(path + ".bak"), Saves.describe(path + ".auto.json"), Saves.describe(path + ".auto.json.bak")]
	selected_path = ""
	get_ok_button().disabled = true
	for index in range(choices.size()):
		var record: Dictionary = records[index]
		choices[index].text = str(choices[index].get_meta("heading")) + "\n" + record.summary
		choices[index].disabled = not record.valid
		choices[index].button_pressed = false
		Style.select(choices[index], false)
	for index in range(records.size()):
		if records[index].valid:
			select(index)
			break
	if saving: get_ok_button().disabled = false

func select(index: int) -> void:
	if index < 0 or index >= records.size() or not records[index].valid: return
	selected_path = records[index].path
	for i in range(choices.size()):
		choices[i].button_pressed = i == index
		Style.select(choices[i], i == index)
	get_ok_button().disabled = false
