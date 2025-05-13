@tool
class_name Mine
extends Structure

### RESOURCES
static var TICK_RATE := 5*Engine.physics_ticks_per_second
@onready var frame: int = 0
@onready var ore_rate := 25

static func valid_placement(a_command_message: CommandMessage, a_cube_grid_arrangement: Array) -> bool:
	var cells_to_check: Set = Structure.get_arrangement_cells(
		a_command_message.map,
		VU.inXZ(a_command_message.position),
		StructureSpec.structure_type_spec_map[a_command_message.tool.type].cube_grid_arrangement
	)
	
	if cells_to_check.is_empty(): return false
	
	for cell: HexCell in cells_to_check.get_values():
		if cell.structure!=null or cell.ore<=0:
			return false
			
	return true

### NODE
func _physics_process(delta: float) -> void:
	super(delta)
	frame += 1
	
	if frame==TICK_RATE:
		var cell: HexCell = map_cells.get_values()[0]
		if cell.ore>0:
			commander.ore += ore_rate
			cell.ore -= ore_rate
			frame = 0
			
			if cell.ore <= 0:
				cell.set_shallow()
