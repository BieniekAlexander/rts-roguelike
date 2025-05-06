class_name DropOff
extends Command

func should_move(a_actor: Commandable) -> bool:
	return !SU.unit_is_close_to_target(a_actor, message.target, .01)

func can_act(a_actor: Commandable) -> bool:
	# TODO b nrevisit dropoff distance - I think it should work if distance is approximately zero, but it's not working
	return SU.unit_is_close_to_target(a_actor, message.target, .02) \
		and a_actor.inventory.size()>0

func fulfill_action(a_actor: Commandable) -> Variant:
	# TODO: for now, this'll just drop off stars specifically, but this'll need to be generalized
	var item: Entity = a_actor.inventory.pop_back()
	item._on_death()
	a_actor.commander.dominion += 100
	return null
