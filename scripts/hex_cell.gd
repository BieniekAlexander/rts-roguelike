class_name HexCell
extends Node3D

@onready var tile: Sprite3D = $Tile
var structure: Node
var index: Vector2i
var commandables: Set
	
const TILE_SIZE: float = 1
const structure_scene: PackedScene = preload("res://scenes/structure.tscn")
	
func init(_index: Vector2i) -> void:
	index = _index
	commandables = Set.new()
	var frame = 5 if (index.y*index.x)%8>3 else 0
	if frame==5:
		structure = structure_scene.instantiate()
		add_child(structure)

func add_unit(c: Commandable) -> void:
	commandables.add(c)

func remove_unit(c: Commandable) -> void:
	if commandables.contains(c):
		commandables.remove(c)
	else:
		push_error("The following unit was not found in this cell: %s" % c)
