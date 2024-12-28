class_name Command

enum TYPE {
	MOVE,
	ATTACK_MOVE,
	HOLD,
	STOP
}

## MOVEMENT
var _target: Node3D = null
var _position: Vector3 = Vector3.INF
var position: Vector3:
	get:
		if _target!=null and is_instance_valid(_target):
			return VU.onXZ(_target.global_position)
		else:
			return _position

## BEHAVIOR
var type: TYPE

func target_attackable() -> bool:
	if _target == null:
		return false
	elif is_instance_valid(_target):
		return true
	else:
		return false

## CONSTRUCTOR
func _init(a_target: Variant, a_type: TYPE) -> void:
	type = a_type
	
	if a_target is Vector3:
		_position = a_target
	elif a_target is Commandable:
		_target = a_target
	else:
		assert(false, "Unsupported command a_target type %s" % a_target)
