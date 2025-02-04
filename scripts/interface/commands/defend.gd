class_name Defend
extends Command


var range: float = 15.

### STATE UPDATES
func should_move(a_commandable: Commandable) -> bool:
	return (
		(VU.inXZ(a_commandable.global_position)-VU.inXZ(position)).length_squared()
	) > pow(range , 2)

func get_updated_state(a_commandable: Commandable):
	var new_command: Command = a_commandable.get_aggro_near_position(VU.inXZ(position), range)
	return [new_command, self] if new_command!=null else self

func fulfill_action(a_commandable: Commandable):
	return self
