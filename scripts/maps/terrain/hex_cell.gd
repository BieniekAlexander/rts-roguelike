@tool
class_name HexCell
extends Node3D

### SPATIAL
@onready var body: StaticBody3D = $StaticBody3D
@onready var tile: Sprite3D = $Tile
var index: Vector2i
const TILE_SIZE: float = 1.5
var structure: Structure = null

### INSTANTIATION
static var terrain_scene: PackedScene = load("res://scenes/map/terrain.tscn")
static var water_scene: PackedScene = load("res://scenes/map/water.tscn")
static var tree_scene: PackedScene = load("res://scenes/structures/forest.tscn")
static var mountain_scene: PackedScene = load("res://scenes/structures/mountain.tscn")

static func instantiate(config_string: String) -> HexCell:
	print("parsing from %s" % config_string)
	var ret: HexCell = null
	var structure: Structure = null
	
	if config_string=="-":
		ret = terrain_scene.instantiate()
	elif config_string=="t":
		ret = terrain_scene.instantiate()
		structure = tree_scene.instantiate()
		ret.set_occupied(tree_scene.instantiate())
		ret.add_child(structure)
	elif config_string=="A":
		ret = terrain_scene.instantiate()
		structure = mountain_scene.instantiate()
		ret.set_occupied(structure)
		ret.add_child(structure)
	elif config_string=="#":
		ret = water_scene.instantiate()
	else:
		assert(false, "unrecognized cell config string: %s" % config_string)
	
	return ret

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
