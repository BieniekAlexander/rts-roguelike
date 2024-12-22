class_name CU

static func point_in_collider_2d(point: Vector2, collider: CollisionShape3D) -> bool:
	# TODO currently, I'm planning for all unit collisions to involve a square shape,
	# with the sides diagonal to the X-Z axes, so the following implementation should work with that assumption
	if collider.shape is BoxShape3D:
		return point_in_collider_2d_diamond(point, collider)
	else:
		push_error("Unsupported collider type: %s" % collider.shape)
		return true

static func point_in_collider_2d_diamond(point: Vector2, diamond_collider: CollisionShape3D) -> bool:
	return (
		VU.l1Norm(point - VU.inXZ(diamond_collider.global_position))
		< diamond_collider.shape.size.x * sqrt(2)/2.0
	)
 
static func check_penetration_vector(
	unit1: Unit,
	unit2: Unit,
	movement: Vector2
) -> Vector2:
	return get_peneration_vector(
		unit1.xz_position + movement,
		unit1.collider.shape,
		unit2.xz_position,
		unit2.collider.shape,
	)

static func get_peneration_vector(
	pos1: Vector2,
	shape1: BoxShape3D,
	pos2: Vector2,
	shape2: BoxShape3D
) -> Vector2:
	# NOTE: as above, still assuming diamonds (45deg-rotated-squares)
	# returns the XZ depth with which one diamond is penetrating another, or 0 if not applicable
	var pos_diff = pos2-pos1
	var pen_abs = (VU.inXZ(shape1.size*sqrt(2)/2+shape2.size*sqrt(2)/2)-abs(pos_diff)).maxf(0)
	return sign(pos_diff)*pen_abs
