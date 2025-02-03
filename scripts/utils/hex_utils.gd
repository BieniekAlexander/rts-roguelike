class_name HU

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

@warning_ignore("integer_division")
static func cube_to_evenq(cube_coordinates: Vector3i) -> Vector2i:
	var col = cube_coordinates.x
	var row = cube_coordinates.z + (cube_coordinates.x - (cube_coordinates.x&1)) / 2
	return Vector2i(col, row)

static func world_to_evenq_hex(point: Vector2) -> Vector2i:
	# reference: https://www.redblobgames.com/grids/hexagons/#pixel-to-hex
	var q = ( point.x*2.0/3.0					) / (HexCell.TILE_SIZE)
	var r = (-point.x/3.0 + point.y*sqrt(3)/3.0	) / (HexCell.TILE_SIZE)
	return cube_to_evenq(cube_round(Vector3(q, -q-r, r)))
