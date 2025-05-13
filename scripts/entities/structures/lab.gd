@tool
class_name Lab
extends Structure

### RESOURCES
static var TICK_RATE := 5*Engine.physics_ticks_per_second
@onready var frame: int = 0
@onready var dominion_rate := 10

### NODE
func _physics_process(delta: float) -> void:
	super(delta)
	frame += 1
	
	if frame==TICK_RATE:
		commander.dominion += dominion_rate
		frame = 0
