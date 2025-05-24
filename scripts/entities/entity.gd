@tool
class_name Entity
extends CharacterBody3D


### IDENTIFIERS


#### TYPE ENUMERATION
# I need to enumerate because I can't peek into packed scenes
@export var type: Type

enum Type {
	# 3 - Faction {0: generic, 1: tech}
	# 2 - Type {0: entity, 1: unit, 2: structure}
	# 1 - Index
	# 0 - Index
	UNDEFINED=-1,
	STRUCTURE_OUTPOST=0x1200,
	STRUCTURE_DWELLING=0x1201,
	STRUCTURE_MINE=0x1202,
	STRUCTURE_LAB=0x1203,
	STRUCTURE_COMPOUND=0x1204,
	STRUCTURE_ARMORY=0x1205,
	UNIT_TECHNICIAN=0x1100,
	UNIT_SENTRY=0x1101,
	UNIT_VANGUARD=0x1102
}

var _commander: Commander
var commander: Commander:
	get: return _commander
	set(value):
		_commander = value
		$Sprite.modulate = TEAM_COLOR_MAP.get(commander_id)
var commander_id: int:
	get: return _commander.id if _commander!=null else 0
const TEAM_COLOR_MAP: Dictionary = {
	0: Color.WHITE,
	1: Color(.2, 1, 1),
	2: Color(1, 1, .2),
	3: Color(.1, .6, .1),
	4: Color(1, .2, .2)
}


### VISION
@export_range(0, 100) var sight_range: int = 20


### COLLISION
var xz_position: Vector2:
	get: return VU.inXZ(global_position)
	set(value): global_position = VU.fromXZ(value)

var map: Map
var pc_set: Set = Set.new()
@onready var collider: CollisionShape3D = get_node_or_null("Collider")
@onready var spatial_partition_dirty: bool = false

func get_collision_extents() -> Array[Vector2]:
	var collider_radius
	match typeof(collider.shape):
		SphereShape3D: collider_radius = collider.shape.radius
		BoxShape3D: collider_radius = collider.shape.size.x*sqrt(2)
		ConcavePolygonShape3D:  collider_radius = 1
		_: collider_radius = 1
	
	return [
		VU.inXZ(global_position),
		VU.inXZ(global_position)+Vector2.UP*collider_radius,
		VU.inXZ(global_position)+Vector2.DOWN*collider_radius,
		VU.inXZ(global_position)+Vector2.LEFT*collider_radius,
		VU.inXZ(global_position)+Vector2.RIGHT*collider_radius
	]

var collision_radius: float:
	get:
		var shape = $Collider.shape
		if shape is SphereShape3D: return shape.radius
		elif shape is BoxShape3D: return max(shape.size.x, shape.size.z)
		else:
			assert(false, "unhandled collider type %s" % typeof(shape))
			return -1.0


### NODE
func _ready() -> void:
	add_to_group("entity")

func initialize(a_map: Map, a_commander: Commander):
	map = a_map
	commander = a_commander
	commander.add_child(self)

func _on_death() -> void:
	for coords: Vector2i in pc_set.get_values():
		map.spatial_partition_grid[coords.x][coords.y].remove(self)
	
	queue_free()
