class_name Build
extends Command

func meets_precondition(a_commandable: Commandable) -> bool:
	return true

func can_act(a_commandable: Commandable) -> bool:
	return a_commandable.global_position.distance_squared_to(position)<=3

func fulfill_action(a_commandable: Commandable) -> Command:
	var scene = load("res://scenes/structures/well.tscn")
	var new_guy: Structure = scene.instantiate()
	var hex_location: Vector2i = HU.world_to_evenq(VU.inXZ(position))
	print(position)
	print(hex_location)
	
	new_guy.initialize(a_commandable.map, a_commandable.commander)
	a_commandable.map.add_structure(new_guy, hex_location, 0)
	new_guy.build_progress = .1
	
	return Repair.new(new_guy)
	

func should_move(a_commandable: Commandable) -> bool:
	return a_commandable.global_position.distance_squared_to(position) >= .25
