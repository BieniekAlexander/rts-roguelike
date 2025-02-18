# References: https://www.redblobgames.com/grids/hexagons/
class_name HU

### ROTATIONS
static func get_evenq_rotated(evenq_coordinates: Vector2i, rotation: int, evenq_center: Vector2i=Vector2i.ZERO) -> Vector2i:
	var cube_coordinates: Vector3i = evenq_to_cube(evenq_coordinates)
	var cube_center: Vector3i = evenq_to_cube(evenq_center)
	var cube_vec: Vector3i = cube_coordinates-cube_center
	var cube_vec_rotated: Vector3i = get_cube_rotated(cube_vec, rotation)
	return cube_to_evenq(cube_vec_rotated)+evenq_center
	
static func get_cube_rotated(cube_coordinates: Vector3i, rotation: int, cube_center: Vector3i=Vector3i.ZERO) -> Vector3i:
	assert(rotation%360==0)
	var ret: Vector3i = cube_coordinates-cube_center
	
	while rotation!=0:
		if rotation>0:
			ret = Vector3i(-ret.z, -ret.x, -ret.y)
			rotation -= 60
		elif rotation<0:
			ret = Vector3i(-ret.y, -ret.z, -ret.x)
			rotation += 60
	
	return ret+cube_center

### ROUNDING
static func cube_round(cube_coordinates: Vector3) -> Vector3i:
	# reference: https://www.redblobgames.com/grids/hexagons/#rounding
	var rx = int(round(cube_coordinates.x))
	var ry = int(round(cube_coordinates.y))
	var rz = int(round(cube_coordinates.z))

	var x_diff = abs(rx - cube_coordinates.x)
	var y_diff = abs(ry - cube_coordinates.y)
	var z_diff = abs(rz - cube_coordinates.z)

	if x_diff > y_diff and x_diff > z_diff:
		rx = -ry-rz
	elif y_diff > z_diff:
		ry = -rx-rz
	else:
		rz = -rx-ry

	return Vector3i(rx, ry, rz)

### CONVERSIONS
@warning_ignore("integer_division")
static func axial_to_cube(axial_coordinates: Vector2i) -> Vector3i:
	return Vector3i(
		axial_coordinates.x,
		axial_coordinates.y,
		-axial_coordinates.x-axial_coordinates.y
	)

@warning_ignore("integer_division")
static func cube_to_axial(cube_coordinates: Vector3i) -> Vector2i:
	return Vector2i(
		cube_coordinates.x,
		cube_coordinates.y
	)

@warning_ignore("integer_division")
static func evenq_to_axial(evenq_coordinates: Vector2i) -> Vector2i:
	var q = evenq_coordinates.y
	var r = evenq_coordinates.x - (evenq_coordinates.y + (evenq_coordinates.y&1)) / 2
	return Vector2i(q, r)

@warning_ignore("integer_division")
static func cube_to_evenq(cube_coordinates: Vector3i) -> Vector2i:
	var col = cube_coordinates.x
	var row = cube_coordinates.y  + (cube_coordinates.x + (cube_coordinates.x&1)) / 2
	return Vector2i(col, row)

@warning_ignore("integer_division")
static func evenq_to_cube(evenq_coordinates: Vector2i) -> Vector3i:
	var q = evenq_coordinates.x
	var r = evenq_coordinates.y - (evenq_coordinates.x + (evenq_coordinates.x&1)) / 2
	return axial_to_cube(Vector2i(q, r))

static func world_to_evenq(point: Vector2) -> Vector2i:
	# reference: https://www.redblobgames.com/grids/hexagons/#pixel-to-hex
	var q = ( point.x*2.0/3.0					) / (HexCell.TILE_SIZE)
	var r = (-point.x/3.0 + point.y*sqrt(3)/3.0	) / (HexCell.TILE_SIZE)
	return cube_to_evenq(cube_round(axial_to_cube(Vector2i(q, r))))

#### NEIGHBORS QUESTION MARK?
static func get_evenq_neighbor_coordinates(evenq_center: Vector2i, cube_neighbor_coords: Array[Vector3i]) -> Array:
	return cube_neighbor_coords.map(
		func(a): return cube_to_evenq(evenq_to_cube(evenq_center)+a)
	)
