class_name Repair
extends Command

static func meets_precondition(
	a_actor: Commandable,
	a_message: CommandMessage
) -> bool:
	# TODO this should only be performable by certain units
	return true

func can_act(a_actor: Commandable) -> bool:
	return a_actor.global_position.distance_squared_to(message.target.global_position)<5

func fulfill_action(a_actor: Commandable) -> Command:
	var repairable: Structure = message.target
	repairable.build_progress += .01 # TODO build rate
	return null if repairable.build_progress >= 1 else self
