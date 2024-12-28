class_name CU

static func point_in_collider_2d(point: Vector2, collider: CollisionShape3D) -> bool:
	# TODO currently, I'm planning for all unit collisions to involve a square shape,
	# with the sides diagonal to the X-Z axes, so the following implementation should work with that assumption
	if collider.shape is BoxShape3D:
		return point_in_collider_2d_diamond(point, collider)
	elif collider.shape is SphereShape3D:
		return point_in_collider_2d_circle(point, collider)
	else:
		push_error("Unsupported collider type: %s" % collider.shape)
		return true

static func point_in_collider_2d_diamond(point: Vector2, diamond_collider: CollisionShape3D) -> bool:
	return (
		VU.l1Norm(point - VU.inXZ(diamond_collider.global_position))
		< diamond_collider.shape.size.x * sqrt(2)/2.0
	)
	
static func point_in_collider_2d_circle(point: Vector2, sphere_collider: CollisionShape3D) -> bool:
	return (
		(point-VU.inXZ(sphere_collider.global_position)).length_squared()
		< pow(sphere_collider.shape.radius, 2)
	)
 
static func check_penetration_vector(
	c1: Commandable,
	c2: Commandable,
	movement: Vector2
) -> Vector2:
	return get_peneration_vector(
		VU.inXZ(c1.global_position) + movement,
		c1.collider.shape,
		VU.inXZ(c2.global_position),
		c2.collider.shape,
	)

static func get_peneration_vector(
	pos1: Vector2,
	shape1: Shape3D,
	pos2: Vector2,
	shape2: Shape3D
) -> Vector2:
	if shape1 is BoxShape3D:
		return get_peneration_vector_square(pos1, shape1, pos2, shape2)
	elif shape1 is SphereShape3D:
		return get_peneration_vector_circle(pos1, shape1, pos2, shape2)
	else:
		assert(false, "Unsupported Shape3D shape %s" % shape1)
		return Vector2.INF
	
static func get_peneration_vector_square(
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

static func get_peneration_vector_circle(
	pos1: Vector2,
	shape1: SphereShape3D,
	pos2: Vector2,
	shape2: SphereShape3D
) -> Vector2:
	var pos_diff = pos2-pos1
	var distance = pos_diff.length()
	
	if distance > shape1.radius+shape2.radius:
		return Vector2.ZERO
	else:
		return -pos_diff.normalized()*(shape1.radius+shape2.radius-distance)
