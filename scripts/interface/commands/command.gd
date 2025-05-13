class_name Command

static var command_class: bool = true

## COMMAND PRECONDITIONS
static func get_valid_tool_names() -> Array:
	return []

enum PreconditionFailureCause {
	NONE,
	NOT_ENOUGH_RESOURCES,
	TECHNOLOGY_NOT_AVAILABLE,
	INVALID_PLACEMENT,
	UNENUMERATED_FAILURE_CAUSE
}

static var precondition_message_map: Dictionary = {
	PreconditionFailureCause.NONE: "",
	PreconditionFailureCause.NOT_ENOUGH_RESOURCES: "Not enough resources",
	PreconditionFailureCause.TECHNOLOGY_NOT_AVAILABLE: "Technology not available",
	PreconditionFailureCause.INVALID_PLACEMENT: "Invalid Placement",
	PreconditionFailureCause.UNENUMERATED_FAILURE_CAUSE: "Unspecified failure"
}

static func requires_position() -> bool:
	## Indicates whether this command requires a specified position to be issued
	return true

static func meets_precondition(
	a_actor: Commandable,
	a_message: CommandMessage
) -> PreconditionFailureCause:
	## Checks whether the relevant command is allowable, given the situation
	# examples:
	# - can the unit can perform this operation on the specified target?
	# - can the unit can place the specified building in the specified position?
	return PreconditionFailureCause.NONE


### STATE
var message: CommandMessage


### UTILS
func _target_is_in_range(a_actor: Commandable, range: float) -> bool:
	return SU.unit_is_close_to_target(
		a_actor,
		message.target,
		range**2
	)


### STATE UPDATES
func get_updated_state(a_commandable: Commandable):
	## Potentially return a new command based on a state check
	return self

func should_move(a_commandable: Commandable) -> bool:
	return true

func can_act(a_commandable: Commandable) -> bool:
	return false

func fulfill_action(a_commandable: Commandable) -> Variant:
	push_error("no action should have been performed")
	return self

func is_finished() -> bool:
	return false

### NODE
func _init(a_message: CommandMessage) -> void:
	message = CommandMessage.deep_copy(a_message)

static func load_command_from_dictionary(a_dictionary: Dictionary, map: Map) -> Command:
	var command_class = {
		"move": Command,
		"attack_move": AttackMove,
		"defend": Defend
	}[a_dictionary["type"]]
	
	var command = command_class.new(
		CommandMessage.new(
			map,
			null,
			null,
			map.evenq_grid[
				int(a_dictionary["loc"][0])
			][
				int(a_dictionary["loc"][1])
			].global_position	
		)
	)
	return command


## DEBUG
func _to_string() -> String:
	return "Command: %s" % message.position
