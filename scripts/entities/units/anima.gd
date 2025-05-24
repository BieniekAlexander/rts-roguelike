@tool
class_name Anima
extends Unit

static var command_patterns_anima: Array[Pattern] = [
	Pattern.new(func(a): return a[1].target is Star, PickUp),
	Pattern.new(func(a): return (
		!a[0].inventory.is_empty() 
		and a[0].inventory[0] is Star
		and a[1].target.type==Entity.Type.STRUCTURE_OUTPOST
	), DropOff)
]

static var anima_command_context: CommandContext = CommandContext.merge(
	Commandable.get_command_context(),
	CommandContext.new(
		command_patterns_anima,
		{
			"command_ability": CommandContext.new(
				[
					Pattern.new(func(a): return true, Build)
				],
				{}
			)
		}
	)
)

static func get_command_context() -> CommandContext:
	return anima_command_context
