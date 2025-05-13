## Represents the possible set of commands, given the context provided by the selected units
## The controller interface will decide which units will receive commands as defined in this object
class_name CommandContext

var evaluator: Variant
var mapping: Dictionary
var tools: Array

func _init(
	a_evaluator: Variant,
	a_mapping: Dictionary = {},
	a_tools: Array = []
):
	evaluator = a_evaluator
	mapping = a_mapping
	tools = a_tools

func requires_position() -> bool:
	if evaluator is Callable:
		return true
	elif "command_class" in evaluator:
		return evaluator.requires_position()
	else:
		push_error("unexpected type for evaluator: %s" % evaluator)
		return false

func evaluate_command(a_actor: Commandable, a_message: CommandMessage) -> Variant:
	# returns the Command type that is applicable for [a_actor], given [a_message]
	# e.g. if a_actor can shoot up and a_message points at a flying unit, return Attack; otherwise, return null
	if evaluator is Callable:
		return evaluator.call(a_actor, a_message)
	else:
		return evaluator

func get_new_context(a_input_event: String) -> Variant:
	## Returns a new command context if one is found; otherwise, returns itself (so as to maintain the existing context)
	return mapping.get(a_input_event, self)

static func merge(a: CommandContext, b: CommandContext) -> CommandContext:
	return CommandContext.new(
		FU.default_evaluate([a.evaluator, b.evaluator]),
		a.mapping.merged(b.mapping),
		Set.new(a.tools).union(Set.new(b.tools)).get_values()
	)

func has(a_input_event: String) -> bool:
	return mapping.has(a_input_event) or tools.has(a_input_event)

static var NULL: CommandContext = CommandContext.new(
	func(commandable, target): return null
)
