class_name HexCell
extends Node3D

### SPATIAL
var map: Map
@onready var tile: Sprite3D = $Tile
@onready var body: StaticBody3D = $Body
var index: Vector2i
const TILE_SIZE: float = 1.5


### COMMANDABLES
var structure: Node
var commandables: Set

func create_structure(commander: Commander, rebake_navmesh: bool = false) -> Structure:
	var s: Structure = load("res://scenes/structures/structure.tscn").instantiate()
	s.initialize(map, commander, global_position)
	add_child(s)
	map.remove_child(body)
	
	if rebake_navmesh:
		map.navmesh.bake_navigation_mesh()
	
	return s


### NODE
func _ready() -> void:
	scale = TILE_SIZE*.72*Vector3.ONE
	commandables = Set.new()

func init(a_index: Vector2i, a_map: Map) -> void:
	index = a_index
	map = a_map
