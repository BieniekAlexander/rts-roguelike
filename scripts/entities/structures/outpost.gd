@tool
class_name Outpost
extends Structure

static var core_command_context = CommandContext.merge(
	CommandContext.new(
		Commandable.command_evaluator_commandable,
		[],
		{"command_state_train": CommandContext.new(Train, [], {})}
	),
	Commandable.commandable_command_context
)

static func get_command_context() -> CommandContext:
	return core_command_context


func _update_state() -> void:
	super()
	
	if !training_queue.is_empty():
		training_queue[0] -= 1
		
		if training_queue[0]==0:
			train(load("res://scenes/units/technician.tscn"))
			training_queue.pop_front()
	
	if _command != null:
		if _command is Train:
			if commander.ore>=100:
				training_queue.push_back(300)
				commander.ore -= 100
		
		_command = null
