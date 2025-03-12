## Abstracts the set of arguments that can be provided to a command
class_name CommandMessage

var map: Map				# the game map, passed for gamestate checks
var target: Entity			# The entity which will be the recipient of the command
var tool: Entity			# Any potential thing that is used in the fulfillment of a command
var world_position: Vector3	# The raw position at which the command is requested (NOTE: `target` might not always be relevant)

var position: Vector3:
	get:
		if target!=null and is_instance_valid(target):
			return VU.onXZ(target.global_position)
		else:
			return world_position


## NODE
func _init(a_map: Map, a_target: Entity = null, a_tool: Entity = null, a_world_position: Vector3 = Vector3.ZERO) -> void:
	map = a_map
	target = a_target
	tool = a_tool
	world_position = a_world_position

static func deep_copy(a_message: CommandMessage) -> CommandMessage:
	return CommandMessage.new(
		a_message.map,
		a_message.target,
		a_message.tool,
		a_message.world_position
	)
