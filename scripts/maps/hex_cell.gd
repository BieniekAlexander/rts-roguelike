@tool
class_name HexCell
extends Node3D

### SPATIAL
var map: Map
@onready var tile: Sprite3D = $Tile
var index: Vector2i
const TILE_SIZE: float = 1.5

static func get_height(level: int) -> float:
	# NOTE: hardcoded height relationship, but it's ok
	return float(level)*.5-2.5
	
static func get_level(height: float) -> int:
	return int(snapped(2*height, 1)+5)

### COMMANDABLES
var structure: Node
var commandables: Set

func create_structure(commander: Commander, rebake_navmesh: bool = true) -> Structure:
	var s: Structure = load("res://scenes/structures/structure.tscn").instantiate()
	s.initialize(map, commander, global_position)
	add_structure(s, commander, rebake_navmesh)
	return s

func add_structure(a_s: Structure, commander: Commander, rebake_navmesh: bool = true) -> void:
	structure = a_s
	remove_child($MeshInstance3D)
	
	if rebake_navmesh:
		map.navmesh.bake_navigation_mesh()


### NODE
func _ready() -> void:
	scale = TILE_SIZE*.72*Vector3.ONE
	commandables = Set.new()

func load_config(a_config: String, a_position: Vector2) -> void:
	global_position = Vector3(
		a_position.x,
		get_height(int(a_config[0])),
		a_position.y
	)

func get_config() -> String:
	return "%sC" % get_level(global_position.y)
