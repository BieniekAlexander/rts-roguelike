@tool
class_name Mine
extends Structure

### RESOURCES
static var TICK_RATE := 5*Engine.physics_ticks_per_second
@onready var frame: int = 0
@onready var ore_rate := 25

static func valid_placement(a_command_message: CommandMessage) -> bool:
	return (
		Structure.valid_placement(a_command_message)
		and a_command_message.map.get_map_cell(VU.inXZ(a_command_message.world_position)).ore>0
	)

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
