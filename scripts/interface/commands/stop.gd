class_name Stop
extends Command

static func evaluator(a_actor: Commandable, a_message: CommandMessage):
	if a_message.target!=null and a_message.target is Commandable:
		return Attack
	else:
		return AttackMove

static func requires_position() -> bool:
	return false

### STATE UPDATES
func should_move(a_commandable: Commandable) -> bool:
	return false

func can_act(a_actor: Commandable) -> bool:
	return true
	
func fulfill_action(a_commandable: Commandable) -> Variant:
	return null

func is_finished() -> bool:
	return true

## DEBUG
func _to_string() -> String:
	return "Stop: %s" % message.position
