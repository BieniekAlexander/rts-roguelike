@tool
class_name HexCell
extends Node3D

### SPATIAL
@onready var body: StaticBody3D = $StaticBody3D
@onready var tile: Sprite3D = $Tile
var index: Vector2i
var structure: Structure = null
const TILE_SIZE: float = 1.5

static func get_height(level: int) -> float:
	# NOTE: hardcoded height relationship, but it's ok
	return float(level)*.5-2.5
	
static func get_level(height: float) -> int:
	return int(snapped(2*height, 1)+5)

var is_occupied: bool:
	get: return body.get_parent()!=null

func set_occupied(a_structure: Structure) -> void:
	structure = a_structure
	remove_child(body)
	
func unset_occupied() -> void:
	structure = null
	add_child(body)

### NODE
func _ready() -> void:
	scale = TILE_SIZE*.72*Vector3.ONE

func load_config(a_config: String, a_position: Vector2) -> void:
	global_position = Vector3(
		a_position.x,
		get_height(int(a_config[0])),
		a_position.y
	)

func get_config() -> String:
	return "%sC" % get_level(global_position.y)
