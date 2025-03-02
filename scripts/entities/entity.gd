@tool
class_name Entity
extends CharacterBody3D


### IDENTIFIERS
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
	1: Color.AQUA,
	2: Color.YELLOW,
	3: Color.WEB_GREEN,
	4: Color.RED
}


### COLLISION
var map: Map
var pc_set: Set = Set.new()
@onready var collider: CollisionShape3D = $Collider
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
		# TODO remove this stupid Structure check
		# I have to revisit Structure colliders
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
