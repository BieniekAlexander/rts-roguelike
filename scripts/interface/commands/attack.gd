class_name Attack
extends Command

# TODO organize
var projectile_scene: PackedScene = preload("res://scenes/projectiles/projectile.tscn")


## COMMAND PRECONDITIONS
static func requires_position() -> bool:
	return true

static func meets_precondition(
	a_actor: Commandable,
	a_message: CommandMessage
) -> bool:
	return _target_attackable(a_message)


### UTILS
static func _target_attackable(a_message: CommandMessage) -> bool:
	if a_message.target==null: # fine if we're attacking empty air
		return true
	else:
		return a_message.target!=null and is_instance_valid(a_message.target)


### STATE UPDATES
func get_updated_state(a_actor: Commandable):
	## Potentially return a new command based on a state check
	return self

func should_move(a_actor: Commandable) -> bool:
	return !_target_attackable(message) or !_target_is_in_range(a_actor, a_actor.ATTACK_RANGE)

func can_act(a_actor: Commandable) -> bool:
	return (
		_target_attackable(message)
		and message.target!=a_actor
		and _target_is_in_range(a_actor, a_actor.ATTACK_RANGE)
		and a_actor.attack_timer<=0
	)

func fulfill_action(a_actor: Commandable) -> Variant:
	## Perform the command's action and return any relevant follow-up commands
	a_actor.attack_timer = a_actor.ATTACK_DURATION
	
	if a_actor.ATTACK_RANGE>0:
		var projectile: Projectile = projectile_scene.instantiate()
		projectile.initialize(a_actor.map, a_actor.commander)
		projectile.initialize_projectile(a_actor, message.target)
	else:
		message.target.receive_damage(a_actor, a_actor.DAMAGE)
	
	return self

func is_finished() -> bool:
	## Check whether the action should be discontinued
	# For the basic command, if targeting a commandable, check if it still exists
	# ref: https://forum.godotengine.org/t/distinguish-between-freed-object-and-null/3838
	if hash(message.target)==hash(null):
		return false
	elif !is_instance_valid(message.target):
		return true
	else:
		return false


## DEBUG
func _to_string() -> String:
	return "Attack: %s" % message.position
