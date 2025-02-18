class_name Build
extends Command

func meets_precondition(a_commandable: Commandable) -> bool:
	return true

func can_act(a_commandable: Commandable) -> bool:
	return a_commandable.global_position.distance_squared_to(position)<=3

func fulfill_action(a_commandable: Commandable) -> Command:
	var scene = load("res://scenes/structures/well.tscn")
	var new_guy: Structure = scene.instantiate()
	var cell = a_commandable.map.get_map_hex_cell(VU.inXZ(position))
	
	new_guy.initialize(a_commandable.map, a_commandable.commander)
	new_guy.global_position = cell.global_position
	a_commandable.map.remove_child(new_guy)
	cell.add_structure(new_guy, a_commandable.commander)
	new_guy.build_progress = .1
	
	return Repair.new(new_guy)
	

func should_move(a_commandable: Commandable) -> bool:
	return a_commandable.global_position.distance_squared_to(position) >= .25
