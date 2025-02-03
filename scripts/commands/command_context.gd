## Represents the possible set of commands, given the context provided by the selected units
## The controller interface will decide which units will receive commands as defined in this object
class_name CommandContext

var mapping: Dictionary
static var NULL: CommandContext = CommandContext.new({})
var commands: Array

func _init(a_mapping: Dictionary = {}):
	mapping = a_mapping
	commands.assign(mapping.values().filter(
		func(v): return v==Command or v.get_base_script()==Command)
	)

func get_new_context(a_input_event: String) -> Variant:
	## Returns a command if applicable, and otherwise returns the relevant command context
	return mapping.get(a_input_event, self)

static func merge(a: CommandContext, b: CommandContext) -> CommandContext:
	return CommandContext.new(a.mapping.merged(b.mapping))

func has(a_input_event: String) -> bool:
	return mapping.has(a_input_event)
