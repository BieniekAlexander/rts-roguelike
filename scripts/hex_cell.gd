class_name HexCell
extends Node3D

@onready var tile: Sprite3D = $Tile
var structure: Node
var index: Vector2i
var units: Dictionary
	
const TILE_SIZE: float = 1
const structure_scene: PackedScene = preload("res://scenes/structure.tscn")
	
func init(_index: Vector2i) -> void:
	index = _index
	units = {}
	var frame = 5 if (index.y*index.x)%8>3 else 0
	if frame==5:
		structure = structure_scene.instantiate()
		add_child(structure)

func add_unit(unit: Unit) -> void:
	units[unit] = null

func remove_unit(unit: Unit) -> void:
	if units.has(unit):
		units.erase(unit)
	else:
		push_error("The following unit was not found in this cell: %s" % unit)
