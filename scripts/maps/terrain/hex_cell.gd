@tool
class_name HexCell
extends Node3D

### SPATIAL
var xz_position: Vector2:
	get: return VU.inXZ(global_position)

@onready var body: StaticBody3D = $StaticBody3D
@onready var tile: Sprite3D = $Tile
var index: Vector2i
const TILE_SIZE: float = 1.5
var structure: Structure = null

func set_occupied(a_structure: Structure) -> void:
	structure = a_structure
	if body!=null: remove_child(body)
	
func unset_occupied() -> void:
	structure = null
	add_child(body)

### PROPERTIES
enum TerrainType {
	GRASS,
	SHALLOW,
	WATER,
	SPRING
}

var terrain_type: TerrainType
@onready var ore: int = 0

# ...

### VISUALS


### CONFIGURATION
func get_config() -> String:
	return "C"

func set_ground() -> void:
	$Tile.modulate = Color(.398, .54, .265)
	body.collision_layer = 1<<4

func set_shallow() -> void:
	$Tile.modulate = Color(.0, .481, .466)
	body.collision_layer = 1<<4
	
func set_water() -> void:
	$Tile.modulate = Color(.255, .31, .937)
	body.collision_layer = 1<<5
	
func set_deposit() -> void:
	set_ground()
	ore = 1500
	$Tile.modulate = Color(.7, .2, 1.)


static var terrain_scene: PackedScene = load("res://scenes/map/terrain.tscn")
static var tree_scene: PackedScene = load("res://scenes/structures/dwelling.tscn")
static var mountain_scene: PackedScene = load("res://scenes/structures/mountain.tscn")

static func instantiate(config_string: String) -> HexCell:
	var ret: HexCell = terrain_scene.instantiate()
	var structure: Structure = null
	
	if config_string=="-":
		ret.terrain_type = TerrainType.GRASS
	elif config_string=="t":
		ret.terrain_type = TerrainType.GRASS
		structure = tree_scene.instantiate()
	elif config_string=="A":
		ret.terrain_type = TerrainType.GRASS
		structure = mountain_scene.instantiate()
	elif config_string==".":
		ret.terrain_type = TerrainType.SHALLOW
	elif config_string==":":
		ret.terrain_type = TerrainType.SPRING
	elif config_string==" ":
		ret.terrain_type = TerrainType.WATER
	else:
		assert(false, "unrecognized cell config string: '%s'" % config_string)
	
	if structure!=null:
		ret.set_occupied(structure)
		ret.add_child(structure)
	
	return ret

### NODE
func _ready() -> void:
	if terrain_type==TerrainType.GRASS:
		set_ground()
	elif terrain_type==TerrainType.SHALLOW:
		set_shallow()
	elif terrain_type==TerrainType.SPRING:
		set_deposit()
	else:
		set_water()
	
	scale = TILE_SIZE*.72*Vector3.ONE

func initialize(a_map: Map, a_position: Vector3) -> void:
	global_position = a_position
	set_owner(a_map)
	
	if structure!=null:
		structure.global_position = global_position
