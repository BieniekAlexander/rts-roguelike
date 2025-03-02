class_name Command
static func command_class():
	pass # TODO clean this up - this was added to let me check if a class inherits Command

### MOVEMENT
var _target: Entity = null
var _position: Vector3 = Vector3.INF
var position: Vector3:
	get:
		if _target!=null and is_instance_valid(_target):
			return VU.onXZ(_target.global_position)
		else:
			return _position

static func requires_position() -> bool:
	## Indicates whether this command requires a specified position to be issued
	return true


### UTILS
func _target_attackable() -> bool:
	if _target == null:
		return false
	elif is_instance_valid(_target):
		return true
	else:
		return false

func _target_is_in_range(a_commandable: Commandable, range: float) -> bool:
	return (
		(VU.inXZ(a_commandable.global_position)-VU.inXZ(_target.global_position)).length_squared()
		- pow(a_commandable.collision_radius + _target.collision_radius, 2)
	) < pow(max(1, range), 2)


### STATE UPDATES
func get_updated_state(a_commandable: Commandable):
	## Potentially return a new command based on a state check
	return self

func meets_precondition(a_commandable: Commandable) -> bool:
	## TODO I forget when this is checked
	return true

func should_move(a_commandable: Commandable) -> bool:
	return !_target_attackable() or !_target_is_in_range(a_commandable, a_commandable.ATTACK_RANGE)

func can_act(a_commandable: Commandable) -> bool:
	return (
		_target_attackable()
		and _target!=a_commandable
		and _target_is_in_range(a_commandable, a_commandable.ATTACK_RANGE)
		and a_commandable.attack_timer<=0
	)

func fulfill_action(a_commandable: Commandable) -> Variant:
	## Perform the command's action and return any relevant follow-up commands
	_target.receive_damage(a_commandable, a_commandable.DAMAGE)
	a_commandable.attack_timer = a_commandable.ATTACK_DURATION
	
	if a_commandable.ATTACK_RANGE>0:
		a_commandable.find_child("ShotParticles").look_at(
			Vector3(
				_target.global_position.x, 
				a_commandable.find_child("ShotParticles").global_position.y, 
				_target.global_position.z
			)
		)
	
	return self

func is_finished() -> bool:
	## Check whether the action should be discontinued
	# For the basic command, if targeting a commandable, check if it still exists
	# ref: https://forum.godotengine.org/t/distinguish-between-freed-object-and-null/3838
	if hash(_target)==hash(null):
		return false
	elif !is_instance_valid(_target):
		return true
	else:
		return false


### NODE
func _init(a_target: Variant) -> void:
	if requires_position():
		if a_target is Vector3:
			_position = a_target
		elif a_target is Entity:
			_target = a_target
		else:
			# TODO devise some method for different units to receive different commands based on the type of entity clicked
			assert(false, "Unsupported command a_target type %s" % a_target)

static func load_command_from_dictionary(a_dictionary: Dictionary, map: Map) -> Command:
	var command_class = {
		"move": Command,
		"attack": AttackMove,
		"defend": Defend
	}[a_dictionary["type"]]
	
	var command = command_class.new(
		map.evenq_grid[
			int(a_dictionary["loc"][0])
		][
			int(a_dictionary["loc"][1])
		].global_position
	)
	return command
