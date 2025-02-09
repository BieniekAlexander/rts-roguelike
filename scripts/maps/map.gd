@tool
class_name Map
extends Node


### INPUT HANDLING
@onready var camera: RTSCamera3D = get_viewport().get_camera_3d()


### SCENARIO CONFIG
var frame: int = 0
@onready var grid_config: Array = FU.get_data_from_csv_file("res://configs/scenarios/scenario1/grid.csv")
@onready var init_event_config: Dictionary = FU.get_data_from_json_file("res://configs/scenarios/scenario1/init.json")
@onready var event_queue: Array = AU.sort_on_key(
	func(e): return e["timer"],
	FU.get_data_from_json_file("res://configs/scenarios/scenario1/events.json").map(
		func(e): return EventUtils.render_event_config(e, 0)
	)
)


func process_events_from_queue() -> void:
	## Every timestep, go through the event queue and see if there's anything to activate
	var i: int = 0
	
	while i<event_queue.size():
		var current_event = event_queue[i]
		
		if current_event["timer"] == frame:
			EventUtils.load_entities_from_event(current_event, self)
			var updated_event = EventUtils.render_event_config(current_event, frame)
			event_queue.remove_at(i)
			
			if updated_event != null:
				AU.priority_queue_push(func(e): return e["timer"], current_event, event_queue)
		elif current_event["timer"] > frame:
			return
		else:
			i+=1


### SPACE THINGS
#### STRUCTURE HEX GRID
var active_entities: Array[Entity] = []
var evenq_grid: Dictionary = {}
var hex_cell_scene: PackedScene = load("res://scenes/hex_cell.tscn")
const structure_scene: PackedScene = preload("res://scenes/structures/well.tscn")
const TILE_WIDTH = HexCell.TILE_SIZE*2.0
const TILE_HORIZ = TILE_WIDTH * .75
const TILE_HEIGHT = TILE_WIDTH * sqrt(3)/2.0


#### UNIT LOCATION AND NAVIGATION
@onready var nav_region := _init_nav_region()
@onready var navmesh := nav_region.navigation_mesh
@onready var SPATIAL_PARTITION_CELL_RADIUS: float = 5.
var spatial_partition_grid: Array

func get_map_hex_cell(point: Vector2) -> HexCell:
	var index: Vector2i = HU.world_to_evenq_hex(point)
	
	if evenq_grid.has(index.x):
		if evenq_grid[index.x].has(index.y):
			return evenq_grid[index.x][index.y]
			
	return null
	
func get_map_spatial_partition_index(point: Vector2) -> Vector2i:
	return Vector2i(
		floori((point.x)/SPATIAL_PARTITION_CELL_RADIUS),
		floori((point.y)/SPATIAL_PARTITION_CELL_RADIUS)
	)

func get_entities_in_range(xz_position: Vector2, radius: float) -> Array:
	var ret: Set = Set.new()
	
	for coordinates: Vector2i in get_spatial_partition_coordinates_in_range(xz_position, radius).get_values():
		ret.add_all(spatial_partition_grid[coordinates.x][coordinates.y].get_values())
	
	return ret.get_values()

func get_spatial_partition_coordinates_in_range(xz_position: Vector2, radius: float) -> Set:
	var ret: Set = Set.new()
	var center: Vector2i = get_map_spatial_partition_index(xz_position)
	var top_left: Vector2i = get_map_spatial_partition_index(xz_position-Vector2.ONE*radius)
	var bot_right: Vector2i = get_map_spatial_partition_index(xz_position+Vector2.ONE*radius)
	
	for i in range(top_left.x, bot_right.x+1):
		for j in range(top_left.y, bot_right.y+1):
			if i>=0 and i<spatial_partition_grid.size() and j>=0 and j<spatial_partition_grid[0].size():
				ret.add(Vector2i(i, j))
	
	return ret

func reassign_unit_in_spatial_partition(a_entity: Entity) -> void:
	var partition_coordinates_set = get_spatial_partition_coordinates_in_range(
		VU.inXZ(a_entity.global_position),
		a_entity.collision_radius
	)
	
	assert(partition_coordinates_set.size()>0, "Entity is nowhere in spatial partitioning")
	var new_coords_set: Set = partition_coordinates_set.difference(a_entity.pc_set)
	var old_coords_set: Set = a_entity.pc_set.difference(partition_coordinates_set)
	
	for partition_coords: Vector2i in old_coords_set.get_values():
		spatial_partition_grid[partition_coords.x][partition_coords.y].remove(a_entity)
		
	for partition_coords: Vector2i in new_coords_set.get_values():
		spatial_partition_grid[partition_coords.x][partition_coords.y].add(a_entity)
	
	a_entity.pc_set = partition_coordinates_set

func reassign_entities_in_spatial_partition(force: bool = false) -> void:
	# NOTE: to be called each physics tick, after units have moved
	for e: Entity in get_tree().get_nodes_in_group("entity"):
		if e.spatial_partition_dirty or force:
			reassign_unit_in_spatial_partition(e)
			e.spatial_partition_dirty = false

func get_entities_at_spatial_partition(partition_index: Vector2i) -> Set:
	return spatial_partition_grid[partition_index.x][partition_index.y]

func get_entities_near_point(xz_position: Vector2) -> Set:
	## Returns units "near" the indicated point, as interpreted from the spatial partitioning
	return get_entities_at_spatial_partition(
		get_map_spatial_partition_index(xz_position)
	)

func get_mouse_world_position(screen_position: Vector2) -> Vector3:
	var screen_pos_normalized: Vector2 = (screen_position*2/get_viewport().get_visible_rect().size)-Vector2.ONE
	var camera_point_alt: float = (
		camera.global_position.y 
		- screen_pos_normalized.y*(camera.size/2)/sqrt(2)
	)

	var depth = camera_point_alt * sqrt(2)
	return camera.project_position(screen_position, depth)


### MOVEMENT AND COLLISION
var units: Array:
	get: return get_tree().get_nodes_in_group("commandable").filter(func(c: Commandable): return c is Unit)

func get_entity_at_position(xz_position: Vector2) -> Entity:
	var potential_entities: Set = get_entities_near_point(xz_position)
	
	for e: Entity in potential_entities.get_values():
		if CU.point_in_collider_2d(xz_position, e.collider):
			return e
	
	return null


### NODE
func _init_nav_region() -> NavigationRegion3D:
	var navigation_region = NavigationRegion3D.new()
	navigation_region.navigation_mesh = NavigationMesh.new()
	#navigation_region.navigation_mesh.geometry_parsed_geometry_type = NavigationMesh.ParsedGeometryType.PARSED_GEOMETRY_STATIC_COLLIDERS
	navigation_region.navigation_mesh.agent_height = 1
	navigation_region.navigation_mesh.agent_radius = .25
	navigation_region.navigation_mesh.agent_max_climb = .6
	add_child(navigation_region)
	return navigation_region

func _init_grid(grid_config: Array) -> Dictionary:
	var grid_height: int = grid_config[0].size()
	var grid_width: int = grid_config.size() if grid_config[-1].size()!=0 else grid_config.size()-1
	var new_grid = {}
	
	for x in range(grid_width):
		new_grid[x] = {}
		for y in range(grid_height):
			var cell_spec: String = grid_config[x][y]
			var cell_height = float(cell_spec[0])*.5-2.5 # NOTE: hardcoded height relationship, but it's ok
			var hex_cell: HexCell = hex_cell_scene.instantiate()
			hex_cell.init(Vector2i(x, y), self)
			new_grid[x][y] = hex_cell
			nav_region.add_child(hex_cell)
			
			hex_cell.global_position = Vector3(x*TILE_HORIZ, cell_height, (y+((x&1)/2.0))*TILE_HEIGHT)
	
	return new_grid
	
func _ready() -> void:
	evenq_grid = _init_grid(grid_config)
	spatial_partition_grid = range(ceili(evenq_grid.size()*TILE_WIDTH)/SPATIAL_PARTITION_CELL_RADIUS).map(
		func(row): return range(ceili(evenq_grid[0].size()*TILE_HEIGHT)/SPATIAL_PARTITION_CELL_RADIUS).map(
			func(col): return Set.new()
		)
	)
	
	active_entities = EventUtils.load_entities_from_event(init_event_config, self)
	nav_region.bake_navigation_mesh()


func _physics_process(delta: float) -> void:
	reassign_entities_in_spatial_partition()
	process_events_from_queue()
	frame+=1


### EDITOR
func _purge() -> void:
	## Utility function for removing everything from the scene before reloading it
		active_entities.map(func(a): a.queue_free())
		get_tree().get_nodes_in_group("entity").map(func(a): a.queue_free())
		active_entities = []
		
		for x in evenq_grid:
			for y in evenq_grid[x]:
				evenq_grid[x][y].queue_free()
		evenq_grid = {}

@export_category("Debug")
@export var rebuild_map: bool = true:
	set(value):
		_purge()
		_ready()
