@tool
class_name HexCell
extends Node3D

### SPATIAL
@onready var body: StaticBody3D = $StaticBody3D
@onready var tile: Sprite3D = $Tile
var index: Vector2i
const TILE_SIZE: float = 1.5
var structure: Structure = null

### NODE
func _ready() -> void:
	scale = TILE_SIZE*.72*Vector3.ONE

func initialize(a_map: Map, a_position: Vector3) -> void:
	global_position = a_position
	set_owner(a_map)

func get_config() -> String:
	return "C"

func set_occupied(a_structure: Structure) -> void:
	structure = a_structure
	remove_child(body)
	
func unset_occupied() -> void:
	structure = null
	add_child(body)
