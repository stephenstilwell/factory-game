extends RefCounted
## Physical water and a material-funded regional maintenance service.
const Inventory = preload("res://scripts/model/inventory.gd")
const SECTION_COST := {"plank":6,"stone":4}
const RESTORE_COST := {"plank":20,"stone":30,"wire":8}
const INPUTS := {"iron_plate":4,"copper_plate":2,"plank":2}
const OUTPUT := {"repair_kit":3}
const WORK_TICKS := 600
const SECTIONS := 4
var kind := "marsh_port"
var sections := 0
var restored := false
var inventory := Inventory.new(32)
var output := Inventory.new(12)
var work_ticks := 0
static func bounds(origin: Vector2i) -> Rect2i:
	return Rect2i(origin+Vector2i(-9,-8),Vector2i(24,22))
static func wet_offset(offset: Vector2i) -> bool:
	if not Rect2i(-6,-6,18,17).has_point(offset) or Rect2i(-2,-2,10,9).has_point(offset): return false
	var delta := (Vector2(offset)-Vector2(2.5,2))/Vector2(9.5,8.5)
	return delta.length_squared() < 1.0
func water_at(frontier: RefCounted, cell: Vector2i) -> bool:
	return frontier.enabled and frontier.sites.has("marsh") and wet_offset(cell-frontier.sites.marsh.origin)
func span(frontier: RefCounted, index: int) -> Vector2i:
	return frontier.sites.marsh.origin+Vector2i(-6+index,2)
func boardwalk(frontier: RefCounted, cell: Vector2i) -> bool:
	if not frontier.enabled or not frontier.sites.has("marsh"): return false
	var offset: Vector2i = cell-frontier.sites.marsh.origin
	return offset.y == 2 and offset.x >= -6 and offset.x < -6+sections
func blocked(frontier: RefCounted, cell: Vector2i) -> bool:
	return water_at(frontier,cell) and not boardwalk(frontier,cell)
func shore(frontier: RefCounted) -> Vector2i:
	return frontier.sites.marsh.origin+Vector2i(-7,2)
func build_reason(world: RefCounted) -> String:
	if not world.frontier.sites.has("marsh"): return "Reedwater has not been placed."
	if sections == SECTIONS: return "All four causeway sections are open."
	if world.early.active(): return "Rebuild Oldbridge's crossing first [Y]."
	if world.defense.phase in ["warning","active"]: return "Finish the beacon defense first."
	if not world.in_reach(span(world.frontier,sections)): return "Approach the next marked span from the western bank or completed causeway."
	if not world.player.can_exchange(SECTION_COST,{}): return "Each span needs 6 planks and 4 stone in your pack."
	return ""
func build_span(world: RefCounted) -> bool:
	var reason := build_reason(world)
	if not reason.is_empty():
		world.message.emit(reason)
		return false
	world.player.exchange(SECTION_COST,{})
	world.metrics.consume(world.ticks,SECTION_COST)
	sections += 1
	world.navigation_revision += 1
	world.frontier._discover(world,"marsh")
	world.feedback_requested.emit("build",span(world.frontier,sections-1))
	world.message.emit("Reedwater causeway %d/4: walk along the completed spans to reach the maintenance lodge." % sections)
	world.changed.emit()
	return true
func remove_reason(world: RefCounted) -> String:
	if sections == 0: return "No causeway section to reclaim."
	if restored: return "The restored service depends on this causeway."
	var cell := span(world.frontier,sections-1)
	if not world.in_reach(cell): return "Walk back toward the western bank to reclaim the last span."
	if world.player_position.x+0.23 >= cell.x: return "Stand fully west of the last span before reclaiming it."
	if world.at(cell) != null: return "Pick up the building on the last span first."
	if world.defense.phase in ["warning","active"]: return "Finish the beacon defense first."
	if not world.player.can_exchange({},SECTION_COST): return "Make pack space for the full refund."
	return ""
func remove_span(world: RefCounted) -> bool:
	var reason := remove_reason(world)
	if not reason.is_empty():
		world.message.emit(reason)
		return false
	world.player.exchange({},SECTION_COST)
	sections -= 1
	world.navigation_revision += 1
	world.changed.emit()
	return true
func restore_reason(world: RefCounted) -> String:
	if restored: return "Maintenance lodge restored. Repair kits restore 25% more health."
	if sections < SECTIONS: return "Complete all four causeway spans first."
	if not world.frontier.claimed("marsh"): return "Recover the keeper's ledger at the lodge entrance first."
	if not world.in_reach(world.frontier.port("marsh")): return "Visit the maintenance lodge entrance."
	if world.defense.phase in ["warning","active"]: return "Finish the beacon defense first."
	if not world.player.can_exchange(RESTORE_COST,{}): return "Bring 20 planks, 30 stone and 8 wire to restore the lodge."
	return ""
func restore_lodge(world: RefCounted) -> bool:
	var reason := restore_reason(world)
	if not reason.is_empty():
		world.message.emit(reason)
		return false
	world.player.exchange(RESTORE_COST,{})
	world.metrics.consume(world.ticks,RESTORE_COST)
	restored = true
	world.award_skill("fabrication",400)
	world.message.emit("Reedwater restored! Repair kits restore 25% more health. Supply the lodge to make 3 kits per batch. +400 Fabrication XP.")
	world.feedback_requested.emit("success",world.frontier.port("marsh"))
	world.region_restored.emit("marsh")
	world.changed.emit()
	return true
func receiving_limit(_world: RefCounted, item: String) -> int:
	return maxi(0,int(INPUTS.get(item,0))*3-inventory.count(item)) if restored else 0
func supply(world: RefCounted) -> bool:
	if not restored or not world.in_reach(world.frontier.port("marsh")): return false
	var moved := 0
	for item in INPUTS: moved += world.player.move_to(inventory,item,mini(int(INPUTS[item]),receiving_limit(world,item)))
	if moved == 0: world.message.emit("Bring iron plates, copper plates and planks, or withdraw the buffered supplies.")
	world.changed.emit()
	return moved > 0
func collect(world: RefCounted, inputs: bool = false) -> bool:
	if not world.frontier.sites.has("marsh") or not world.in_reach(world.frontier.port("marsh")): return false
	var source: RefCounted = inventory if inputs else output
	if source.total() == 0: return false
	if not world.player.exchange({},source.contents):
		world.message.emit("Make pack space for the complete bundle.")
		return false
	source.contents.clear()
	world.changed.emit()
	return true
func step(world: RefCounted) -> void:
	if not restored: return
	if work_ticks == 0:
		if not output.can_exchange({},OUTPUT) or not inventory.exchange(INPUTS,{}): return
		world.metrics.consume(world.ticks,INPUTS)
		work_ticks = WORK_TICKS
	work_ticks -= 1
	if work_ticks > 0: return
	output.exchange({},OUTPUT)
	world.production.repair_kit = int(world.production.get("repair_kit",0))+3
	world.metrics.record(world.ticks,"made","repair_kit",3)
	world.changed.emit()
func serialize() -> Dictionary:
	return {"sections":sections,"restored":restored,"inventory":inventory.contents.duplicate(),"output":output.contents.duplicate(),"work_ticks":work_ticks}
func restore(world: RefCounted, data: Variant) -> bool:
	if not data is Dictionary: return false
	for key in ["sections","restored","inventory","output","work_ticks"]:
		if not data.has(key): return false
	if not world.frontier.integer(data.sections,0,SECTIONS) or not data.restored is bool or not world.frontier.integer(data.work_ticks,0,WORK_TICKS-1): return false
	if not data.inventory is Dictionary or not data.output is Dictionary: return false
	sections = int(data.sections)
	restored = data.restored
	work_ticks = int(data.work_ticks)
	if (sections > 0 and (not world.frontier.sites.has("marsh") or not world.frontier.sites.marsh.discovered)) or (restored and (sections != SECTIONS or not world.frontier.claimed("marsh"))): return false
	for item in data.inventory:
		if not INPUTS.has(item) or not world.frontier.integer(data.inventory[item],1,int(INPUTS[item])*3): return false
		inventory.contents[item] = int(data.inventory[item])
	for item in data.output:
		if item != "repair_kit" or not world.frontier.integer(data.output[item],1,12): return false
		output.contents[item] = int(data.output[item])
	if not restored and (inventory.total() > 0 or output.total() > 0 or work_ticks > 0): return false
	if work_ticks > 0 and output.total() > 9: return false
	return true
