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
	var hex_cell: HexCell = a_message.map.get_map_cell(VU.inXZ(a_message.position))
	
	if hex_cell.structure!=null and hex_cell.structure.commander_id!=0:
		return true
	else:
		return false
		print("failing to start cap")

func can_act(a_actor: Commandable) -> bool:
	return a_actor.global_position.distance_squared_to(message.position)<=5

func fulfill_action(a_actor: Commandable) -> Command:
	message.target.build_progress += .00222222222
	
	if message.target.build_progress<2:
		return self
	else:
		message.target.commander = a_actor.commander
		a_actor.commander.terra_max += message.target.terra_provided
		return null
	

func should_move(a_actor: Commandable) -> bool:
	return a_actor.global_position.distance_squared_to(message.position) >= .25
