extends Node


# Load the custom images for the mouse cursor.
var free_indicator = preload("res://assets/interface/indicator_free.png")
var selection_indicator = preload("res://assets/interface/indicator_selection.png")
var attack_indicator = preload("res://assets/interface/indicator_attack.png")

@onready var map: Map = get_tree().current_scene.find_child("Map")
@onready var camera: RTSCamera3D = get_viewport().get_camera_3d()
var mouse_position: Vector2

func _ready():
	Input.set_custom_mouse_cursor(free_indicator)

func _input(event: InputEvent):
	## MOUSE MOVEMENT
	if event is InputEventMouseMotion:
		mouse_position = event.position

func _process(delta: float) -> void:
	var hex_coorinate: Vector2 = VU.inXZ(camera.get_mouse_world_position(mouse_position, .5))
	var entity: Entity = map.get_entity_at_position(hex_coorinate)
	
	if entity != null and entity is Commandable:
		if entity.commander_id == 1:
			Input.set_custom_mouse_cursor(selection_indicator)
		else:
			Input.set_custom_mouse_cursor(attack_indicator)
	else:
		Input.set_custom_mouse_cursor(free_indicator)
