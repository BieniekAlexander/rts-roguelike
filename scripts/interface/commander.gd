@tool
class_name Commander
extends Control

### IDENTIFIERS
@export_range(0, 5) var id: int

### CONTROLS
@onready var selection: Array[Unit] = []
@onready var click_screen_pos: Vector2 = Vector2.ZERO

### RESOURCES
@onready var aqua: int = 500
@onready var terra_used: int = 0
@onready var terra_max: int = 0
@onready var ignis: int = 300

### UNITS
func get_commandables():
	return get_tree().get_nodes_in_group("commandable").filter(
		func(u): return u.commander == self
	)

### NODE
func _process(delta: float) -> void:
	if get_node_or_null("ResourceSummaryLabel") != null:
		$ResourceSummaryLabel.text = (
			"\taqua: %s\n\tterra: %s\n\tignis: %s" % [
		 	aqua,
			("%s/%s" % [terra_used, terra_max]),
			ignis
		])
