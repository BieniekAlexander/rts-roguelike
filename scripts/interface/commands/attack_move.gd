class_name AttackMove
extends Command

static func command_class():
	pass
	
static func evaluator(c: Commandable, t: Variant):
	if t is Commandable:
		return Attack
	else:
		return AttackMove

### STATE UPDATES
func get_updated_state(a_commandable: Commandable):
	var aggro_command: Command = a_commandable.get_aggro_near_position(VU.inXZ(a_commandable.global_position), a_commandable.ATTACK_RANGE)
	return [aggro_command, self] if aggro_command!=null else self
