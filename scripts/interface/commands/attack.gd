class_name Attack
extends Command


## COMMAND PRECONDITIONS
static func requires_position() -> bool:
	return true

static func meets_precondition(
	a_actor: Commandable,
	a_message: CommandMessage
) -> PreconditionFailureCause:
	return (
		PreconditionFailureCause.UNENUMERATED_FAILURE_CAUSE
		if not _target_attackable(a_message)
		else PreconditionFailureCause.NONE
	)
	


### UTILS
static func _target_attackable(a_message: CommandMessage) -> bool:
	if a_message.target==null: # fine if we're attacking nothing
		print("no target")
		return true
	else:
		return a_message.target!=null and hash(a_message.target)!=hash(null)


### STATE UPDATES
func get_updated_state(a_actor: Commandable):
	## Potentially return a new command based on a state check
	return self

func should_move(a_actor: Commandable) -> bool:
	return !_target_attackable(message) or !SU.unit_is_close_to_target(a_actor, message.target, a_actor.ATTACK_RANGE**2)

func can_act(a_actor: Commandable) -> bool:
	return (
		a_actor.attack_timer<=0
		and _target_attackable(message)
		and message.target!=a_actor
		and SU.unit_is_close_to_target(a_actor, message.target, a_actor.ATTACK_RANGE**2)
	)

func fulfill_action(a_actor: Commandable) -> Variant:
	## Perform the command's action and return any relevant follow-up commands
	a_actor.attack_timer = a_actor.ATTACK_DURATION
	var weapon: Weapon = a_actor.get_weapon_evaluator().eval(message.target)
	weapon.fire(a_actor, message.target)
	return self

func is_finished() -> bool:
	## Check whether the action should be discontinued
	# For the basic command, if targeting a commandable, check if it still exists
	# ref: https://forum.godotengine.org/t/distinguish-between-freed-object-and-null/3838
	if hash(message.target)==hash(null):
		return false
	elif !is_instance_valid(message.target) or message.target.freed:
		return true
	else:
		return false


## DEBUG
func _to_string() -> String:
	return "Attack: %s" % message.position
