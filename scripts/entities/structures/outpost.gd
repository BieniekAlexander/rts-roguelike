@tool
class_name Outpost
extends Structure

static func command_evaluator_structure(a_actor: Commandable, a_message: CommandMessage):
	if a_message.tool!=null:
		return Train
	else:
		return null

static var core_command_context: CommandContext = CommandContext.merge(
	CommandContext.new(
		command_evaluator_structure,
		{},
		Train.get_valid_tool_names()
	),
	Commandable.get_command_context()
)

static func get_command_context() -> CommandContext:
	return core_command_context 


func _update_state() -> void:
	super()
	
	if !training_queue.is_empty():
		training_queue[0][0] -= 1 # NOTE remove hardcode, as below
		
		if training_queue[0][0]<=0:  # NOTE remove hardcode, as below
			var spec: Variant = training_queue.pop_front()
			train(spec[1])
			
	
	if _command != null:
		if _command is Train:
			if commander.has_resources_for(_command.message.tool.type):
				training_queue.push_back([ # TODO remove hardcode
					commander.technology_mapping[_command.message.tool.type].creation_time,
					_command.message.tool.packed_scene
				])
				
				commander.use_resources_for(_command.message.tool.type)
			
		
		_command = null
