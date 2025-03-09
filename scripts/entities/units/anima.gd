@tool
class_name Anima
extends Unit

static func command_evaluator_anima(c: Commandable, target: Variant):
	if target is Star:
		return PickUp
	elif (
		!c.inventory.is_empty() 
		and c.inventory[0] is Star
		and target is Core
	):
		return DropOff
	else:
		return null

static var anima_command_context = CommandContext.new(
	FU.default_evaluate(command_evaluator_anima, Commandable.command_evaluator_commandable),
	{"command_state_ability": CommandContext.new(Build.evaluator, {})}
).plus(
	Commandable.commandable_command_context
)

static func get_command_context() -> CommandContext:
	return anima_command_context
