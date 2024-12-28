class_name HexGrid
extends Node

## INPUT HANDLING
@onready var camera: RTSCamera3D = get_viewport().get_camera_3d()
@onready var put: RTSController = get_tree().root.get_node("Root/Player/Controller")

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				var world_position = get_mouse_world_position(event.position)
				var map_position: Vector2 = VU.inXZ(world_position)
				var c: HexCell = get_map_cell(map_position)
				
				if c==null:
					print_rich("[color=#FF8888]NO CELL[/color]")
				elif c.structure==null:
					print_rich("[color=#0088AA]COORDS: %s[/color]" % c.index)
				else:
					print_rich("[color=#88FF88]STRUCTURE: %s[/color]" % c.index)
				# TODO position to hex grid index still isn't perfect - something seems to happen when rounding around 0?

## SPACE THINGS
@onready var navmesh: NavigationRegion3D = $NavigationRegion
@onready var floor_collider: CollisionShape3D = $NavigationRegion/Floor/Collider
@export var X_RANGE: Vector2i = Vector2i(-25, 25)
@export var Y_RANGE: Vector2i = Vector2i(-10, 10)
var evenq_grid: Dictionary = {}
var hex_cell_scene: PackedScene = load("res://scenes/hex_cell.tscn")
const WIDTH = HexCell.TILE_SIZE*2.0
const HORIZ = WIDTH * .75
const HEIGHT = WIDTH * sqrt(3)/2.0

func get_map_cell(point: Vector2) -> HexCell:
	var index: Vector2i = HU.world_to_evenq_hex(point)
	
	if evenq_grid.has(index.x):
		if evenq_grid[index.x].has(index.y):
			return evenq_grid[index.x][index.y]
			
	return null
	
func get_mouse_world_position(screen_position: Vector2) -> Vector3:
	var screen_pos_normalized: Vector2 = (screen_position*2/get_viewport().get_visible_rect().size)-Vector2.ONE
	var camera_point_alt: float = (
		camera.global_position.y 
		- screen_pos_normalized.y*(camera.size/2)/sqrt(2)
	)

	var depth = camera_point_alt * sqrt(2)
	return camera.project_position(screen_position, depth)

## MOVEMENT AND COLLISION
var units: Array:
	get: return get_tree().get_nodes_in_group("commandable").filter(func(c: Commandable): return c is Unit)

func update_commandable_position(c: Commandable) -> void:
	var cells = Set.new(
		c.get_collision_extents().map(
			func(pos: Vector2): return get_map_cell(pos)
		).filter(
			func(cell: HexCell): return cell != null
		)
	)
	var new_cells: Set = cells.difference(c.cells)
	var old_cells: Set = c.cells.difference(cells)
	
	for cell: HexCell in old_cells.get_values():
		cell.remove_unit(c)
		
	for cell: HexCell in new_cells.get_values():
		cell.add_unit(c)
		
	c.cells = cells

func get_commmandable_at_position(hex_coordinate: Vector2) -> Commandable:
	var cell: HexCell = get_map_cell(hex_coordinate)
	
	for c: Commandable in cell.commandables.get_values():
		if CU.point_in_collider_2d(hex_coordinate, c.collider):
			return c
			
	return null

## NODE
func _init_grid() -> void:
	for x in range(X_RANGE.x, X_RANGE.y):
		evenq_grid[x] = {}
		for y in range(Y_RANGE.x, Y_RANGE.y):
			var hex_cell: HexCell = hex_cell_scene.instantiate()
			hex_cell.init(Vector2i(x, y))
			evenq_grid[x][y] = hex_cell
			navmesh.add_child(hex_cell)
			
			hex_cell.position = Vector3(x*HORIZ, 0, (y+((x&1)/2.0))*HEIGHT)
			
	var top_left = evenq_grid[X_RANGE.x][Y_RANGE.x].position
	var bot_right = evenq_grid[X_RANGE.y-1][Y_RANGE.y-1].position
	floor_collider.shape.extents.x = bot_right.x-top_left.x
	floor_collider.shape.extents.y = top_left.y-bot_right.y

func _ready() -> void:
	_init_grid()

	for c: Commandable in get_tree().get_nodes_in_group("commandable"):
		c.initialize(self)
		#c.reparent(navmesh)
		update_commandable_position(c)
		
	navmesh.bake_navigation_mesh()

func _process(delta: float) -> void:
	if Input.is_key_pressed(KEY_SPACE):
		print("hi")
