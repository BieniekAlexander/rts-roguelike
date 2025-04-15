class_name Tool

var type: Variant
var packed_scene: PackedScene

func _init(
	a_type: Variant,
	a_packed_scene: PackedScene
) -> void:
	type = a_type
	packed_scene = a_packed_scene
