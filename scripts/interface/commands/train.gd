class_name Train
extends Command


static func tool_applies_to(command_tool_name: String, entity_type: Entity.Type) -> bool:
	return command_tool_name in {
		Entity.Type.STRUCTURE_OUTPOST: [
			"command_tool_technician"
		], Entity.Type.STRUCTURE_COMPOUND: [
			"command_tool_sentry",
	"command_tool_vanguard"
		]
	}.get(entity_type, [])

static func requires_position() -> bool:
	## Indicates whether this command requires a specified position to be issued
	return false
