@tool
class_name CollisionUtils

# ref: https://www.youtube.com/watch?v=7WcmyxyFO7o

static var rng = RandomNumberGenerator.new()

static func get_nonoverlapping_points(
	map: Map, center: Vector2, point_radius: float, region_radius: float, max_points: int = 1, sample_count: int = 10
) -> Array[Vector2]:
	## In a region of the map, yield points at which it would be valid to spawn things
	# TODO handle varying radii
	var nearby_entities: Array = AU.sort_on_key(
		func(e: Entity): return VU.inXZ(e.global_position).distance_squared_to(center),
		map.get_entities_in_range(center, region_radius+point_radius)
	)
	
	var occupied_points: Array = nearby_entities.map( # points which will block further placements
		func(e: Entity): return VU.inXZ(e.global_position)
	)
	
	var about_points := occupied_points.duplicate() # points about which we'll try to add adjacent points
	var ret_points: Array[Vector2] = [] # points to return, as valid positions
	
	if (
		nearby_entities.size()==0
		or VU.inXZ(nearby_entities[0].global_position).distance_squared_to(center)>point_radius**2
	):
		ret_points.insert(0, center)
		about_points.append(center)
		occupied_points.append(center)
		
		if max_points==1: return ret_points
	
	while about_points.size()>0:
		var about_point: Vector2 = about_points[0]
		var candidate_accepted: bool = false
		
		for i in range(sample_count):
			var angle: float = 2*PI*rng.randf()
			var vec := 2*point_radius*(1+rng.randf())*Vector2(sin(angle), cos(angle))
			var new_point := about_point + vec
			
			# TODO speed this check up
			if (
				occupied_points.filter(
					func(o: Vector2): return o.distance_squared_to(new_point)<point_radius*2
				).size()==0
				and (new_point-center).length_squared()<region_radius**2
			):
				about_points.insert(0, new_point)
				ret_points.append(new_point)
				occupied_points.append(new_point)
				
				if ret_points.size()==max_points: return ret_points
				candidate_accepted = true
				break
				
		if !candidate_accepted:
			about_points.remove_at(0)
	
	push_error("Not enough points collected - requested %s, got %s" % [max_points, ret_points.size()])
	return ret_points
	
