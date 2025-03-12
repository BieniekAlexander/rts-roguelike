## Represents the possible set of commands, given the context provided by the selected units
## The controller interface will decide which units will receive commands as defined in this object
class_name CommandContext

var mapping: Dictionary
var evaluator: Callable

static var NULL: CommandContext = CommandContext.new(
	func(commandable, target): return null, 
	{}
)

func _init(
	a_evaluator: Callable,
	a_mapping: Dictionary = {}
):
	mapping = a_mapping
	evaluator = a_evaluator

func get_new_context(a_input_event: String) -> Variant:
	## Returns a command if applicable, and otherwise returns the relevant command context
	return mapping.get(a_input_event, self)

static func merge(a: CommandContext, b: CommandContext) -> CommandContext:
	return CommandContext.new(
		FU.default_evaluate(a.evaluator, b.evaluator),
		a.mapping.merged(b.mapping)
	)

func has(a_input_event: String) -> bool:
	return mapping.has(a_input_event)

func plus(b: CommandContext) -> CommandContext:
	evaluator = FU.default_evaluate(evaluator, b.evaluator)
	mapping = mapping.merged(b.mapping)
	return self
