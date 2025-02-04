class_name AttackMove
extends Command

static func command_class():
	pass

### STATE UPDATES
func get_updated_state(a_commandable: Commandable):
	var aggro_command: Command = a_commandable.get_aggro_near_position(VU.inXZ(a_commandable.global_position), a_commandable.ATTACK_RANGE)
	return [aggro_command, self] if aggro_command!=null else self
