@tool
class_name Well
extends Structure

### RESOURCES
const TICK_RATE := 150
@onready var frame: int = 0
@onready var aqua_rate := 10


### NODE
func _physics_process(delta: float) -> void:
	super(delta)
	frame += 1
	
	if frame==TICK_RATE:
		commander.aqua += aqua_rate
		frame = 0
