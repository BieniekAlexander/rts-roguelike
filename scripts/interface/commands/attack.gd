class_name Attack
extends Command

# TODO organize
var projectile_scene: PackedScene = preload("res://scenes/projectiles/projectile.tscn")

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

static func meets_precondition(a_map: Map, a_position: Vector3) -> bool:
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
	a_commandable.attack_timer = a_commandable.ATTACK_DURATION
	
	if a_commandable.ATTACK_RANGE>0:
		var projectile: Projectile = projectile_scene.instantiate()
		projectile.initialize(a_commandable.map, a_commandable.commander)
		projectile.initialize_projectile(a_commandable, _target)
	else:
		_target.receive_damage(a_commandable, a_commandable.DAMAGE)
	
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
