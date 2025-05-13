class_name Train
extends Command


static var train_tool_names: Array = [
	"command_tool_technician",
	"command_tool_sentry",
	"command_tool_vanguard"
]

static func get_valid_tool_names() -> Array:
	return train_tool_names

static func requires_position() -> bool:
	## Indicates whether this command requires a specified position to be issued
	return false
