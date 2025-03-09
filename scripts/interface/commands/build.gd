class_name Build
extends Command


static func evaluator(c: Commandable, t: Variant) -> Variant:
	if meets_precondition(c.map, t):
		return Build
	else:
		return null

static func meets_precondition(a_map: Map, a_position: Vector3) -> bool:
	var hex_cell: HexCell = a_map.get_map_cell(VU.inXZ(a_position))
	return hex_cell.aqua > 0

func can_act(a_commandable: Commandable) -> bool:
	return a_commandable.global_position.distance_squared_to(position)<=3

func fulfill_action(a_commandable: Commandable) -> Command:
	var scene = load("res://scenes/structures/well.tscn")
	var new_guy: Structure = scene.instantiate()
	var hex_location: Vector2i = HU.world_to_evenq(VU.inXZ(position))
	
	new_guy.initialize(a_commandable.map, a_commandable.commander)
	a_commandable.map.add_structure(new_guy, hex_location, 0)
	new_guy.build_progress = .1
	
	return Repair.new(new_guy)
	

func should_move(a_commandable: Commandable) -> bool:
	return a_commandable.global_position.distance_squared_to(position) >= .25
