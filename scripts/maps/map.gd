@tool
class_name Map
extends Node3D


### SPACE THINGS
#### STRUCTURE HEX GRID
var evenq_grid: Dictionary = {}
static var hex_cell_scene: PackedScene = load("res://scenes/hex_cell.tscn")
const structure_scene: PackedScene = preload("res://scenes/structures/well.tscn")
const TILE_WIDTH = HexCell.TILE_SIZE*2.0
const TILE_HORIZ = TILE_WIDTH * .75
const TILE_HEIGHT = TILE_WIDTH * sqrt(3)/2.0


#### UNIT LOCATION AND NAVIGATION
@onready var nav_region: NavigationRegion3D = load("res://scenes/navigation_region.tscn").instantiate()
static var SPATIAL_PARTITION_CELL_RADIUS: float = 5.
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

func reassign_entities_in_spatial_partition(entities: Array, force: bool = false) -> void:
	# NOTE: to be called each physics tick, after units have moved
	for e: Entity in entities:
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


### MOVEMENT AND COLLISION
var units: Array: # TODO check
	get: return get_tree().get_nodes_in_group("commandable").filter(func(c: Commandable): return c is Unit)

func get_entity_at_position(xz_position: Vector2) -> Entity:
	var potential_entities: Set = get_entities_near_point(xz_position)
	
	for e: Entity in potential_entities.get_values():
		if CU.point_in_collider_2d(xz_position, e.collider):
			return e
	
	return null


### NODE
func load_grid(a_grid_config: Array):
	assert(a_grid_config.size()>0)
	
	evenq_grid = {}
	var grid_height: int = a_grid_config[0].size()
	var grid_width: int = (
		a_grid_config.size()
		if a_grid_config[-1].size()!=0
		else a_grid_config.size()-1
	)
	
	for x in range(grid_width):
		evenq_grid[x] = {}
		for y in range(grid_height): 
			var hex_cell: HexCell = hex_cell_scene.instantiate()
			evenq_grid[x][y] = hex_cell
			nav_region.add_child(hex_cell)
			hex_cell.set_owner(self)
			hex_cell.load_config(
				a_grid_config[x][y],
				Vector2(
					x*TILE_HORIZ,
					(y+((x&1)/2.0))*TILE_HEIGHT
				)
			)

@export var grid_config: Array

func _ready() -> void:
	add_child(nav_region)
	nav_region.set_owner(self)
	load_grid(grid_config)
	
	spatial_partition_grid = range(ceili(evenq_grid.size()*TILE_WIDTH)/SPATIAL_PARTITION_CELL_RADIUS).map(
		func(_row): return range(ceili(evenq_grid[0].size()*TILE_HEIGHT)/SPATIAL_PARTITION_CELL_RADIUS).map(
			func(_col): return Set.new()
		)
	)


### EDITOR
func _purge() -> void:
	if nav_region!=null:
		nav_region.queue_free()

@export_category("Debug")
static func from_config(
	a_grid_config: Array
) -> Map:
	var ret_map := Map.new()
	ret_map.grid_config = a_grid_config
	return ret_map

func load_config(
	a_config: Array
) -> void:
	grid_config = a_config

@export var grid_config_path: String = ""
@export var load_from_file: bool = true:
	set(value):
		grid_config = FU.get_data_from_csv_file(grid_config_path)
		_purge()
		_ready()

@export var export: bool = true:
	set(value):
		var rows: Array[String] = []
		
		for i in evenq_grid:
			var row_str = ""
			for j in evenq_grid[i]:
				row_str += evenq_grid[i][j].get_config()+","
			
			row_str = row_str.trim_suffix(",")
			rows.append(row_str)
		
		var file = FileAccess.open(grid_config_path, FileAccess.WRITE_READ)
		
		for row_str: String in rows:
			file.store_line(row_str)
		
		file.close()

@export var time_rebake: bool = true:
	set(value):
		var start_time = Time.get_unix_time_from_system()
		nav_region.bake_navigation_mesh()
		var end_time = Time.get_unix_time_from_system()
		push_error(end_time-start_time)
