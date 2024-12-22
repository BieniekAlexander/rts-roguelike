class_name Command

## MOVEMENT
var _target: Node3D = null
var _position: Vector3 = Vector3.INF
var position: Vector3:
	get:
		if _target!=null and is_instance_valid(_target):
			return VU.onXZ(_target.global_position)
		else:
			return _position

## ATTACK
var _angery
var aggro: bool:
	get:
		if _target!=null:
			return false
		else:
			return _angery

func target_attackable() -> bool:
	if _target == null:
		return false
	elif is_instance_valid(_target):
		return true
	else:
		return false

## CONSTRUCTOR
func _init(a_target: Variant, a_angery: bool = false) -> void:
	if a_target is Vector3:
		_position = a_target
	elif a_target is Unit:
		_target = a_target
	else:
		push_error("Unsupported command a_target type %s" % a_target)
		
	_angery = a_angery
