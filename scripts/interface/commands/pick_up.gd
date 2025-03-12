class_name PickUp
extends Command

func should_move(a_actor: Commandable) -> bool:
	return !_target_is_in_range(a_actor, .1)

func can_act(a_actor: Commandable) -> bool:
	return _target_is_in_range(a_actor, .1) \
		and a_actor.inventory.size()<a_actor.inventory_capacity

func fulfill_action(a_actor: Commandable) -> Command:
	# TODO:
	# 1: make sure that the star is getting removed from the map in every which way
	# 2: the anima is not interpreting any commands queued after pickup - why?
	var item: Entity = message.target
	item.get_parent().remove_child(item)
	a_actor.inventory.push_back(item)
	return null
