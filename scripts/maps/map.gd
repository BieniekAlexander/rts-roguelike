class_name Map
extends Node


### INPUT HANDLING
@onready var camera: RTSCamera3D = get_viewport().get_camera_3d()


### SPACE THINGS
#### STRUCTURE HEX GRID
var evenq_grid: Dictionary = {}
var hex_cell_scene: PackedScene = load("res://scenes/hex_cell.tscn")
const structure_scene: PackedScene = preload("res://scenes/structures/well.tscn")
const WIDTH = HexCell.TILE_SIZE*2.0
const HORIZ = WIDTH * .75
const HEIGHT = WIDTH * sqrt(3)/2.0


#### UNIT LOCATION AND NAVIGATION
@export var X_RANGE: Vector2i = Vector2i(-10, 10)
@export var Y_RANGE: Vector2i = Vector2i(-8, 8)

@onready var navmesh: NavigationRegion3D = $NavigationRegion
@onready var SPACE_PARTITION_CELL_RADIUS: float = 5.
var spatial_partition_grid: Array

func get_map_hex_cell(point: Vector2) -> HexCell:
	var index: Vector2i = HU.world_to_evenq_hex(point)
	
	if evenq_grid.has(index.x):
		if evenq_grid[index.x].has(index.y):
			return evenq_grid[index.x][index.y]
			
	return null
	
func get_map_spatial_partition_index(point: Vector2) -> Vector2i:
	return Vector2i(
		floori((point.x+VU.range(X_RANGE)*HORIZ/2)/SPACE_PARTITION_CELL_RADIUS),
		floori((point.y+VU.range(Y_RANGE)*HEIGHT/2)/SPACE_PARTITION_CELL_RADIUS)
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
			print("right-clicked %s" % e)
			return e
			
	return null


### NODE
func _init_grid() -> void:
	for x in range(X_RANGE.x, X_RANGE.y):
		evenq_grid[x] = {}
		for y in range(Y_RANGE.x, Y_RANGE.y):
			var hex_cell: HexCell = hex_cell_scene.instantiate()
			hex_cell.init(Vector2i(x, y), self)
			evenq_grid[x][y] = hex_cell
			navmesh.add_child(hex_cell)
			
			hex_cell.position = Vector3(x*HORIZ, 0, (y+((x&1)/2.0))*HEIGHT)
	
	evenq_grid[-3][0].global_position.y = .5
	
func _load_commandables():
	var text = FileAccess.open("res://map_stuff.json", FileAccess.READ).get_as_text()
	var commandables_data_per_owner: Array = JSON.parse_string(text)
	
	for commander_id in range(len(commandables_data_per_owner)):
		var commandables_data = commandables_data_per_owner[commander_id]
		var commander: Commander = get_tree().current_scene.find_child("Players").get_children()[commander_id]
		var to_defend: Commandable # TODO very hacky means of giving units something to defend for testing
		
		for data in commandables_data:
			var scene = load("res://scenes/%s.tscn" % data["com"])
			var new_guy = scene.instantiate()
			var x: int = data["loc"][0]
			var y: int = data["loc"][1]
			
			if new_guy is Structure:
				new_guy.initialize(self, commander, evenq_grid[x][y].global_position)
				# TODO clean this up
				remove_child(new_guy)
				evenq_grid[x][y].add_child(new_guy)
				new_guy.global_position = evenq_grid[x][y].global_position

				if new_guy is Well:
					to_defend = new_guy
			else:
				new_guy.initialize(self, commander, evenq_grid[x][y].global_position+.5*Vector3.UP)
				
				if new_guy is Unit:
					new_guy.update_commands(Defend.new(to_defend))

func _ready() -> void:
	_init_grid()
	_load_commandables()
		
	spatial_partition_grid = range(ceili(VU.range(X_RANGE*WIDTH)/SPACE_PARTITION_CELL_RADIUS)).map(
		func(row): return range(ceili(VU.range(Y_RANGE*HEIGHT)/SPACE_PARTITION_CELL_RADIUS)).map(
			func(col): return Set.new()
		)
	)
	
	navmesh.bake_navigation_mesh()
	reassign_entities_in_spatial_partition(true)

func _physics_process(delta: float) -> void:
	reassign_entities_in_spatial_partition()
