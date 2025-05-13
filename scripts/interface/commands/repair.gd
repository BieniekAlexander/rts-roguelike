class_name Repair
extends Command

static func meets_precondition(
	a_actor: Commandable,
	a_message: CommandMessage
) -> Command.PreconditionFailureCause:
	# TODO this should only be performable by certain units
	return PreconditionFailureCause.NONE

func can_act(a_actor: Commandable) -> bool:
	return SU.unit_is_close_to_target(a_actor, message.target)

func fulfill_action(a_actor: Commandable) -> Variant:
	var repairable: Structure = message.target # TODO might be repairing osmething other than a structure
	repairable.build_progress += .01 # TODO build rate
	return null if repairable.build_progress >= 1 else self
