# Utilities that deal with the relationships of things in space
# I'm hoping this will make my distance calculations more expressive,
# e.g. checking if a unit is adjacent to a structure, which sits on a set of hex cells
class_name SU

static var rng = RandomNumberGenerator.new()

static func unit_is_close_to_target(a_unit: Unit, a_target: Variant, distance_squared: float = .001) -> bool:
	if a_target is Structure:
		return SU.unit_is_close_to_structure(a_unit, a_target, distance_squared)
	elif a_target is Entity:
		return SU.unit_is_close_to_unit(a_unit, a_target, distance_squared)
	elif a_target is Vector2:
		return SU.unit_is_close_to_position(a_unit, a_target, distance_squared)
	else:
		push_error("unsuported distance target type")
		return false

static func unit_is_close_to_position(a_unit: Unit, a_position: Vector2, distance_squared: float = .001) -> bool:
	# specifically checks that the borders of the cillision circles is less than some distance
	return (
		a_position - a_unit.xz_position
	).length_squared() - a_unit.collision_radius**2 < distance_squared

static func unit_is_close_to_unit(a_unit: Unit, an_entity: Entity, distance_squared: float = .001) -> bool:
	# specifically checks that the borders of the cillision circles is less than some distance
	return (
		an_entity.xz_position - a_unit.xz_position
	).length_squared() - (an_entity.collision_radius+a_unit.collision_radius)**2 < distance_squared
	
static func unit_is_close_to_cells(a_unit: Unit, hex_cells: Set, distance_squared: float = .001) -> bool:
	# NOTE: in terms of implementation speed, I was going to sort the cells and then check the distance to the closest one,
	# but I think that redundantly calculates things and so performs an unnecessary sort
	for hex_cell: HexCell in hex_cells.get_values():
		if (
			a_unit.xz_position - hex_cell.xz_position
		).length_squared() - (a_unit.collision_radius+Map.TILE_HEIGHT)**2 < distance_squared:
			return true
	
	return false

static func unit_is_close_to_structure(a_unit: Unit, a_structure: Structure, distance_squared: float = .001) -> bool:
	return SU.unit_is_close_to_cells(a_unit, a_structure.map_cells, distance_squared)

static func get_nonoverlapping_points(
	map: Map, center: Vector2, point_radius: float, region_radius: float, max_points: int = 1, sample_count: int = 10
) -> Array[Vector2]:
	## In a region of the map, yield points at which it would be valid to spawn things
	# ref: https://www.youtube.com/watch?v=7WcmyxyFO7o
	# TODO handle varying radii
	var nearby_entities: Array = AU.sort_on_key(
		func(e: Entity): return VU.inXZ(e.global_position).distance_squared_to(center),
		map.get_nearby_entities(center, region_radius+point_radius)
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
	
