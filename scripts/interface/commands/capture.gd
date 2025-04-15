class_name Capture
extends Command


static func evaluator(a_actor: Commandable, a_message: CommandMessage) -> Variant:
	if meets_precondition(a_actor, a_message):
		return Capture
	else:
		return null

static func meets_precondition(
	a_actor: Commandable,
	a_message: CommandMessage
) -> bool:
	return a_message.target is Structure and a_message.target.commander_id==0

func can_act(a_actor: Commandable) -> bool:
	return a_actor.global_position.distance_squared_to(message.position)<=5

func fulfill_action(a_actor: Commandable) -> Command:
	message.target.build_progress += .00222222222
	
	if message.target.build_progress<2:
		return self
	else:
		message.target.commander = a_actor.commander
		a_actor.commander.population_max += message.target.population_provided
		return null
	

func should_move(a_actor: Commandable) -> bool:
	return a_actor.global_position.distance_squared_to(message.position) >= .25
