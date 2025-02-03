class_name Commander
extends Control

### IDENTIFIERS
@export_range(0, 5) var id: int

### CONTROLS
@onready var selection: Array[Unit] = []
@onready var click_screen_pos: Vector2 = Vector2.ZERO

### RESOURCES
@onready var aqua: int = 1000
@onready var terra: int = 100
@onready var ignis: int = 10

### NODE
func _process(delta: float) -> void:
	if get_node_or_null("ResourceSummaryLabel") != null:
		$ResourceSummaryLabel.text = "\taqua: %s\n\tterra: %s\n\tignis: %s" % [aqua, terra, ignis]
