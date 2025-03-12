class_name Command
static func command_class():
	pass # TODO clean this up - this was added to let me check if a class inherits Command


## COMMAND PRECONDITIONS
static func requires_position() -> bool:
	## Indicates whether this command requires a specified position to be issued
	return true

static func meets_precondition(
	a_actor: Commandable,
	a_message: CommandMessage
) -> bool:
	## Checks whether the relevant command is allowable, given the situation
	# examples:
	# - can the unit can perform this operation on the specified target?
	# - can the unit can place the specified building in the specified position?
	return true


### STATE
var message: CommandMessage


### UTILS
func _target_is_in_range(a_actor: Commandable, range: float) -> bool:
	return ( # TODO account for when target is null
		(VU.inXZ(a_actor.global_position)-VU.inXZ(message.position)).length_squared()
		- pow(a_actor.collision_radius + message.target.collision_radius, 2)
	) < pow(max(1, range), 2)


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
