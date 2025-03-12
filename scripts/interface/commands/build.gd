class_name Build
extends Command

static func meets_precondition(a_actor: Commandable, a_message: CommandMessage) -> bool:
	var hex_cell: HexCell = a_message.map.get_map_cell(VU.inXZ(a_message.world_position))
	return hex_cell.aqua > 0

func can_act(a_actor: Commandable) -> bool:
	# TODO update this check such that the position is centered with respect to the build location
	return a_actor.global_position.distance_squared_to(message.world_position)<=3

func fulfill_action(a_actor: Commandable) -> Command:
	var scene = load("res://scenes/structures/well.tscn")
	var new_guy: Structure = scene.instantiate()
	var hex_location: Vector2i = HU.world_to_evenq(VU.inXZ(message.world_position))
	
	new_guy.initialize(message.map, a_actor.commander)
	message.map.add_structure(new_guy, hex_location, 0)
	new_guy.build_progress = .1
	
	return Repair.new(CommandMessage.new(message.map, new_guy))
	

func should_move(a_actor: Commandable) -> bool:
	return a_actor.global_position.distance_squared_to(message.world_position) >= .25
