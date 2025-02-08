@tool
class_name Core
extends Structure


static var core_command_context = CommandContext.new({
	null: Command,
	"command_state_train": Train
})

static func get_command_context() -> CommandContext:
	return core_command_context


func _update_state() -> void:
	super()
	
	if !training_queue.is_empty():
		training_queue[0] -= 1
		
		if training_queue[0]==0:
			train(load("res://scenes/units/anima.tscn"))
			training_queue.pop_front()
	
	if _command != null:
		if _command is Train:
			if commander.aqua>=100:
				training_queue.push_back(450)
				commander.aqua -= 100
		
		_command = null
