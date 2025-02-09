## Handles a serialized representation of an "event",
## which encapsulates a group of entities entering the map from "nothing",
## e.g. a random spawning of a star or a player casting a spell
class_name EventUtils

static func render_event_config(a_event_config: Dictionary, a_frame: int) -> Variant:
	## Sets the next timer frame for event activation, and decreases counts
	# TODO find better function name annd wording
	var time_spec = a_event_config["time_specs"][0]
	if !time_spec.has("count"): time_spec["count"] = 1
	
	if time_spec["count"]==0:
		a_event_config["time_specs"].remove_at(0)
		
		if a_event_config["time_specs"].size()==0:
			return null
		else:
			time_spec = a_event_config["time_specs"][0]
	
	a_event_config["timer"] = TimeUtils.get_frame_duration_from_time_spec(time_spec)+a_frame
	time_spec["count"] -= 1
	return a_event_config
	

static func load_entities_from_event(a_event_config: Dictionary, map: Map) -> Array[Entity]:
	var new_entitites: Array[Entity] = []
	
	for key in a_event_config["owners"].keys():
		var owner_config = a_event_config["owners"][key]
		var entities_data = owner_config["entities"]
		var commander: Commander = map.find_child("Players").get_children()[int(key)]
		var new_guys = []
		
		for data in entities_data:
			var count: int = int(data.get("count", 1))
			var scene = load(data["res"])
			
			for n in range(count):
				var new_guy = scene.instantiate()
				new_entitites.append(new_guy)
				new_guys.append(new_guy)
				var x: int = data["loc"][0]
				var y: int = data["loc"][1]
				
				if new_guy is Structure:
					new_guy.initialize(map, commander, map.evenq_grid[x][y].global_position)
					# TODO clean this up
					map.remove_child(new_guy)
					map.evenq_grid[x][y].add_child(new_guy)
					new_guy.global_position = map.evenq_grid[x][y].global_position
				else:
					# TODO handle if the entities from the event don't fit
					new_guy.initialize(map, commander, Vector3.ZERO)
					new_guy.global_position = VU.fromXZ(
						CollisionUtils.get_nonoverlapping_points(
							map,
							VU.inXZ(map.evenq_grid[x][y].global_position),
							new_guy.collision_radius,
							5.
						)[0]
					)+(map.evenq_grid[x][y].global_position.y+.5)*Vector3.UP

				map.reassign_unit_in_spatial_partition(new_guy)
			
			var command = (
				# TODO pass around map better
				Command.load_command_from_dictionary(owner_config["command"], new_guys[0].map)
				if owner_config.has("command")
				else null
			)
			
			if command!=null:
				for g in new_guys:
					if g is Commandable:
						g.update_commands(command)

	
	return new_entitites
