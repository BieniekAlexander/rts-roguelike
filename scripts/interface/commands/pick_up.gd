class_name PickUp
extends Command

func should_move(a_commandable: Commandable) -> bool:
	return !_target_is_in_range(a_commandable, .1)

func can_act(a_commandable: Commandable) -> bool:
	return _target_is_in_range(a_commandable, .1) \
		and a_commandable.inventory.size()<a_commandable.inventory_capacity

func fulfill_action(a_commandable: Commandable) -> Command:
	# TODO:
	# 1: make sure that the star is getting removed from the map in every which way
	# 2: the anima is not interpreting any commands queued after pickup - why?
	var item: Entity = _target
	item.get_parent().remove_child(item)
	a_commandable.inventory.push_back(item)
	return null
