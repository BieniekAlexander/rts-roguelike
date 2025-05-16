@tool
class_name Map
extends Node3D


### SPACE THINGS
#### HEX GRID
var evenq_grid: Dictionary = {}
var structure_cell_map: Dictionary = {}
const TILE_WIDTH = HexCell.TILE_SIZE*2.0
const TILE_HORIZ = TILE_WIDTH * .75
const TILE_HEIGHT = TILE_WIDTH * sqrt(3)/2.0


func add_structure(a_structure: Structure, evenq_location: Vector2i, rotation: int, rebake: bool = true) -> void:
	var cells: Set = Set.new()
	a_structure.global_position = VU.fromXZ(HU.evenq_to_world(evenq_location))
	var x_locs = []; var z_locs = []
	
	for location: Vector2i in HU.get_evenq_neighbor_coordinates(
		evenq_location,
		a_structure.cube_grid_arrangement
	):
		var cell: HexCell = evenq_grid[location.x][location.y]
		cell.set_occupied(a_structure)
		cells.add(cell)
		x_locs.append(cell.xz_position.x)
		z_locs.append(cell.xz_position.y)
		
		if a_structure is Mine:
			cell.set_deposit()
			# TODO not a good spot for this - but I'm looking to guarantee that,
			# if the game adds a well somewhere, it forces the tile to be a spring
	
	# TODO maybe find better solution - guarantee that the structure's position
	# is in the center of the cells that it's occupying
	a_structure.global_position.x = AU.mean(x_locs)
	a_structure.global_position.z = AU.mean(z_locs)
	
	structure_cell_map[a_structure] = cells
	a_structure.map = self
	
	if rebake:
		nav_region.bake_navigation_mesh()

func remove_structure(a_structure: Structure, rebake: bool = true) -> void:
	var cells: Set = structure_cell_map[a_structure]
	structure_cell_map.erase(a_structure)
	
	for cell: HexCell in cells.get_values():
		cell.unset_occupied()
	
	if rebake:
		nav_region.bake_navigation_mesh()

#### UNIT LOCATION AND NAVIGATION
var evenq_grid_width:
	get: return evenq_grid.size()
var evenq_grid_height:
	get: return evenq_grid[0].size()

@onready var nav_region: NavigationRegion3D = load("res://scenes/navigation_region.tscn").instantiate()
static var SPATIAL_PARTITION_CELL_RADIUS: float = 5.
var spatial_partition_grid: Array

func grid_coordinates_in_bounds(evenq_grid_coordinates: Vector2i) -> bool:
	return (
		evenq_grid_coordinates.x>=0
		and evenq_grid_coordinates.x<evenq_grid_width
		and evenq_grid_coordinates.y>=0
		and evenq_grid_coordinates.y<evenq_grid_height
	)

func get_map_cell(point: Vector2) -> HexCell:
	var index: Vector2i = HU.world_to_evenq(point)
	
	if evenq_grid.has(index.x):
		if evenq_grid[index.x].has(index.y):
			return evenq_grid[index.x][index.y]
			
	return null

func get_map_spatial_partition_index(point: Vector2) -> Vector2i:
	return Vector2i(
		floori((point.x)/SPATIAL_PARTITION_CELL_RADIUS),
		floori((point.y)/SPATIAL_PARTITION_CELL_RADIUS)
	)

func get_nearby_entities(xz_position: Vector2, radius: float) -> Array:
	var ret: Set = Set.new()
	
	for coordinates: Vector2i in get_nearby_spatial_partitions(xz_position, radius).get_values():
		ret.add_all(spatial_partition_grid[coordinates.x][coordinates.y].get_values())
	
	return ret.get_values()

func get_nearby_spatial_partitions(xz_position: Vector2, radius: float) -> Set:
	var ret: Set = Set.new()
	var top_left: Vector2i = get_map_spatial_partition_index(xz_position-Vector2.ONE*radius)
	var bot_right: Vector2i = get_map_spatial_partition_index(xz_position+Vector2.ONE*radius)
	
	for i in range(top_left.x, bot_right.x+1):
		for j in range(top_left.y, bot_right.y+1):
			if i>=0 and i<spatial_partition_grid.size() and j>=0 and j<spatial_partition_grid[0].size():
				ret.add(Vector2i(i, j))
	
	return ret

func reassign_entity_in_spatial_partition(a_entity: Entity) -> void:
	var partition_coordinates_set = get_nearby_spatial_partitions(
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
			reassign_entity_in_spatial_partition(e)
			e.spatial_partition_dirty = false

func get_entities_at_spatial_partition(partition_index: Vector2i) -> Set:
	if (
		partition_index.x<0 or partition_index.x>=spatial_partition_grid.size()
		or partition_index.y<0 or partition_index.y>=spatial_partition_grid[0].size()
	):
		return Set.Empty
	else:
		return spatial_partition_grid[partition_index.x][partition_index.y]

func get_entities_near_point(xz_position: Vector2) -> Set:
	## Returns units "near" the indicated point, as interpreted from the spatial partitioning
	return get_entities_at_spatial_partition(
		get_map_spatial_partition_index(xz_position)
	)


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
func load_grid(a_grid_config: Array):
	assert(a_grid_config.size()>0)
	
	evenq_grid = {}
	var grid_height: int = a_grid_config[0].size()
	var grid_width: int = (
		a_grid_config.size()
		if a_grid_config[-1].size()!=0
		else a_grid_config.size()-1
	)
	
	spatial_partition_grid = range(ceili(grid_width*TILE_WIDTH)/SPATIAL_PARTITION_CELL_RADIUS+1).map(
		func(_row): return range(ceili(grid_height*TILE_HEIGHT)/SPATIAL_PARTITION_CELL_RADIUS+1).map(
			func(_col): return Set.new()
		)
	)
	
	for x in range(grid_height):
		evenq_grid[x] = {}
		for y in range(grid_width):
			var next_terrain: HexCell = HexCell.instantiate(a_grid_config[y][x])
			nav_region.add_child(next_terrain)
			next_terrain.initialize(self, VU.fromXZ(HU.evenq_to_world(Vector2i(x, y))))
			evenq_grid[x][y] = next_terrain
			if next_terrain.structure!=null:
				add_structure(next_terrain.structure, Vector2i(x, y), 0, false)
				reassign_entity_in_spatial_partition(next_terrain.structure)

@export var grid_config: Array

func _ready() -> void:
	add_child(nav_region)
	nav_region.set_owner(self)
	load_grid(grid_config)


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
		grid_config = FSU.get_data_from_csv_file(grid_config_path)
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
