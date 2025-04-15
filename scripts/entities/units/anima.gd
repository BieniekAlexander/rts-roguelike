@tool
class_name Anima
extends Unit

static func command_evaluator_anima(a_actor: Commandable, a_message: CommandMessage):
	if a_message.target is Star:
		return PickUp
	elif (
		!a_actor.inventory.is_empty() 
		and a_actor.inventory[0] is Star
		and a_message.target is Outpost
	):
		return DropOff
	else:
		return null

static var anima_command_context: CommandContext = CommandContext.merge(
	CommandContext.new(
		FU.default_evaluate(command_evaluator_anima, Commandable.command_evaluator_commandable),
		{"command_state_ability": CommandContext.new(Build, {})}
	),
	Commandable.commandable_command_context
)

static func get_command_context() -> CommandContext:
	return anima_command_context
