class_name Repair
extends Command

static func meets_precondition(a_map: Map, a_position: Vector3) -> bool:
	# TODO this should only be performable by certain units
	return true

func can_act(a_commandable: Commandable) -> bool:
	return a_commandable.global_position.distance_squared_to(_target.global_position)<5

func fulfill_action(a_commandable: Commandable) -> Command:
	var repairable: Structure = _target
	repairable.build_progress += .01 # TODO build rate
	return null if repairable.build_progress >= 1 else self
