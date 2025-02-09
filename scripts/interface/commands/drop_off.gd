class_name DropOff
extends Command

func should_move(a_commandable: Commandable) -> bool:
	return !_target_is_in_range(a_commandable, .1)

func can_act(a_commandable: Commandable) -> bool:
	# TODO b nrevisit dropoff distance - I think it should work if distance is approximately zero, but it's not working
	return _target_is_in_range(a_commandable, 5.) \
		and a_commandable.inventory.size()>0

func fulfill_action(a_commandable: Commandable) -> Command:
	# TODO: for now, this'll just drop off stars specifically, but this'll need to be generalized
	var item: Entity = a_commandable.inventory.pop_back()
	item._on_death()
	a_commandable.commander.ignis += 1
	return null
