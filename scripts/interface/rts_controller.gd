class_name RTSController extends Node3D

@export var selection_box: ColorRect = ColorRect.new()
@export var camera: Camera3D

## CONTROL VARIABLES
@onready var next_command_type: Command.TYPE = Command.TYPE.MOVE
@onready var next_command_additive: bool = false
var mouse_position: Vector2 = Vector2.ZERO
var select_down_position: Vector2 = Vector2.ZERO

## GAMESTATE
@onready var map: HexGrid = get_tree().current_scene.find_child("Map")
var selection: Array[Node] = []

## NODE
func _ready():
	selection_box.visible = false
	if !selection_box.is_inside_tree():
		add_child(selection_box)

func _input(event: InputEvent):
	## COMMAND STATE MODIFIERS
	if event.is_action_pressed("command_state_additive"):
		next_command_additive = true
	elif event.is_action_released("command_state_additive"):
		next_command_additive = false	
	elif event.is_action_pressed("command_state_attack_move"):
		next_command_type = Command.TYPE.ATTACK_MOVE
	## MOUSE MOVEMENT
	elif event is InputEventMouseMotion:
		mouse_position = event.position
		if selection_box.visible == true:
			var selection_box_size = abs(mouse_position - select_down_position)
			selection_box.set_size(selection_box_size)
			if mouse_position.x > select_down_position.x && mouse_position.y > select_down_position.y:
				selection_box.position = select_down_position
			elif mouse_position.x < select_down_position.x && mouse_position.y < select_down_position.y:
				selection_box.position = mouse_position
			elif mouse_position.x > select_down_position.x:
				selection_box.position = Vector2(mouse_position.x - selection_box_size.x, mouse_position.y)
			else:
				selection_box.position = Vector2(mouse_position.x, mouse_position.y - selection_box_size.y)
	# UNIT SELECTION
	elif event.is_action_pressed("isometric_camera_select"):
		select_down_position = mouse_position
		selection_box.visible = true
		selection_box.set_size(Vector2.ZERO)
	elif event.is_action_released("isometric_camera_select"):
		selection_box.visible = false
		if !next_command_additive: deselect()
		set_selection(select_down_position, mouse_position)
	# ISSUING COMMANDS
	elif event.is_action_pressed("command_move"):
		assign_command_to_units(
			map.get_mouse_world_position(mouse_position),
			next_command_type,
			next_command_additive
		)
	elif event.is_action_pressed("command_stop"):
		assign_command_to_units(
			map.get_mouse_world_position(mouse_position),
			Command.TYPE.STOP,
			false
		)

func set_selection(selection_start_position: Vector2, selection_end_position: Vector2):
	var drag_distance = abs(selection_start_position - selection_end_position)
	if drag_distance < Vector2(10, 10):
		set_selected_unit()
	else:
		set_selected_units()
		
func set_selected_unit():
	# TODO select the unit with something different from get_obstruction
	# that method checks for a collider, but the sprite is generally bigger in screen space than the collider,
	# and I probably want to check for sprite collision
	var hex_coorinate: Vector2 = VU.inXZ(map.get_mouse_world_position(mouse_position))
	var unit: Commandable = map.get_commmandable_at_position(hex_coorinate)
	
	if unit != null:
		selection.append(unit)
		unit.set_selected()
	
func set_selected_units():
	var selection_box_geometry: PackedVector2Array = [
		selection_box.position,
		selection_box.position + Vector2(selection_box.size.x, 0.0),
		selection_box.position + selection_box.size,
		selection_box.position + Vector2(0.0, selection_box.size.y)
	]
	
	for unit: Commandable in get_tree().get_nodes_in_group("commandable"):
		var selected_screen_position = camera.unproject_position(unit.global_position)
		if Geometry2D.is_point_in_polygon(selected_screen_position, selection_box_geometry):
			selection.append(unit)
			unit.set_selected()


func assign_command_to_units(
	world_position: Vector3,
	a_command_type: Command.TYPE,
	add_to_queue: bool
) -> void:
	var active_selection = selection.filter(func(u): return is_instance_valid(u)) # TODO refactor so I dont have to do this smh
	
	if active_selection.size()==0:
		return
	else:
		var targeted_commandable = map.get_commmandable_at_position(VU.inXZ(world_position))
		
		if targeted_commandable!=null:
			print("attacking %s" % targeted_commandable)
			for unit: Unit in active_selection:
				unit.set_command(
					Command.new(
						targeted_commandable,
						Command.TYPE.MOVE
					),
					add_to_queue
				)
		else:
			for unit: Unit in active_selection:
				unit.set_command(
					Command.new(
						VU.onXZ(world_position),
						a_command_type
					),
					add_to_queue
				)
		
		if !add_to_queue:
			next_command_type = Command.TYPE.MOVE

func deselect():
	for c: Commandable in selection:
		if is_instance_valid(c):
			c.set_deselected()
	selection = []
