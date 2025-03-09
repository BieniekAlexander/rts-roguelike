@tool
class_name Well
extends Structure

### RESOURCES
const TICK_RATE := 150
@onready var frame: int = 0
@onready var aqua_rate := 25


### NODE
func _physics_process(delta: float) -> void:
	super(delta)
	frame += 1
	
	if frame==TICK_RATE:
		if cell.aqua>0:
			commander.aqua += aqua_rate
			cell.aqua -= aqua_rate
			frame = 0
			
			if cell.aqua <= 0:
				cell.set_shallow()
