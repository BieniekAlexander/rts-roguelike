class_name Structure
extends Commandable

func _physics_process(delta: float) -> void:
	_recalculate_state()
	# assert(false, "ABC method called from %s, please implement this in subclasses" % self)
