class_name RTSController extends Node3D

@export var selection_box: ColorRect = ColorRect.new()
@export var camera: Camera3D

## CONTROL VARIABLES
@onready var next_command_type = null
@onready var next_command_additive: bool = false
var mouse_position: Vector2 = Vector2.ZERO
var select_down_position: Vector2 = Vector2.ZERO
var selected_unit_types: Set = Set.new()
var active_command_context: Variant = CommandContext.NULL

## GAMESTATE
@onready var map: HexGrid = get_tree().current_scene.find_child("Map")
var selection: Array[Node] = []

## NODE
func _ready():
	selection_box.visible = false
	if !selection_box.is_inside_tree():
		add_child(selection_box)
		
func _process(delta: float) -> void:
	# fog of war stuff
	pass

func _input(event: InputEvent):
	## MOUSE MOVEMENT
	if event is InputEventMouseMotion:
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
	## QUEUING
	elif event.is_action_pressed("command_additive"):
		next_command_additive = true
	elif event.is_action_released("command_additive"):
		next_command_additive = false
	## COMMAND STATE MODIFIERS
	# TODO cleanup mapping of event to action - Godot does not make this easy
	elif get_action_names_from_event(event).size()>0:
		var action_name = get_action_names_from_event(event)[0]
		var next = active_command_context.get_new_context(action_name)
		
		
		if next is CommandContext:
			active_command_context = next
		elif next==Command or next.get_base_script()==Command:
			next_command_type = next
			# TODO find a better way to make this check
			if !next.requires_position():
				assign_command_to_units(
					Vector3.ZERO,
					next_command_type,
					next_command_additive
				)
	# ISSUING COMMANDS
	elif event.is_action_pressed("command_move"):
		assign_command_to_units(
			map.get_mouse_world_position(mouse_position),
			next_command_type,
			next_command_additive
		)
	elif event.is_action_pressed("command_stop"):
		cancel_command_for_units()
		set_active_command_context(selection)

func set_selection(selection_start_position: Vector2, selection_end_position: Vector2):
	var drag_distance = abs(selection_start_position - selection_end_position)
	if drag_distance < Vector2(10, 10):
		set_selected_unit(selection_start_position)
	else:
		set_selected_units()

func set_selected_unit(position: Vector2):
	# TODO select the unit with something different from get_obstruction
	# that method checks for a collider, but the sprite is generally bigger in screen space than the collider,
	# and I probably want to check for sprite collision
	var hex_coorinate: Vector2 = VU.inXZ(map.get_mouse_world_position(position))
	var entity: Entity = map.get_entity_at_position(hex_coorinate)
	
	if entity != null and entity is Commandable:
		selection.append(entity)
		entity.set_selected()
	
	set_active_command_context(selection)

func set_selected_units():
	var selection_box_geometry: PackedVector2Array = [
		selection_box.position,
		selection_box.position + Vector2(selection_box.size.x, 0.0),
		selection_box.position + selection_box.size,
		selection_box.position + Vector2(0.0, selection_box.size.y)
	]
	
	for c: Commandable in get_tree().get_nodes_in_group("commandable"):
		# TODO collect units from spatial partitioning
		var selected_screen_position = camera.unproject_position(c.global_position)
		if Geometry2D.is_point_in_polygon(selected_screen_position, selection_box_geometry):
			selection.append(c)
			c.set_selected()
	
	set_active_command_context(selection)

func set_active_command_context(a_commandables: Array) -> void:
	selected_unit_types.clear()
	
	for c: Commandable in a_commandables:
		selected_unit_types.add(c.get_script())
	
	active_command_context = selected_unit_types.map(
		func(t): return t.get_command_context()
	).reduce(
		func(a, b): return CommandContext.merge(a, b),
		CommandContext.NULL
	)

func cancel_command_for_units() -> void:
	var selection = selection.filter(func(u): return is_instance_valid(u)) # TODO refactor so I dont have to do this smh
	
	if selection.size()==0:
		return
		
	for c: Commandable in selection:
		c.update_commands(
			null,
			false
		)

func assign_command_to_units(
	world_position: Vector3,
	a_command_type,
	add_to_queue: bool
) -> void:
	var selection = selection.filter(func(u): return is_instance_valid(u)) # TODO refactor so I dont have to do this smh
	
	if selection.size()==0:
		return
	
	var targeted_entity = map.get_entity_at_position(VU.inXZ(world_position))
	if targeted_entity == null:
		targeted_entity = VU.onXZ(world_position)
	
	if a_command_type==null:
		a_command_type = selection[0].get_default_interaction_command_type(targeted_entity)
	
	var new_command: Command = a_command_type.new(targeted_entity)
	
	for c: Commandable in selection:
		if c.get_script().get_command_context().commands.has(a_command_type):
			c.update_commands(
				new_command,
				add_to_queue
			)
	
	if !add_to_queue:
		next_command_type = null
		set_active_command_context(selection)

func deselect():
	for c in selection:
		if is_instance_valid(c):
			c.set_deselected()
	selection = []
	selected_unit_types = Set.new()

static func get_action_names_from_event(event: InputEvent) -> Array:
	return InputMap.get_actions().filter(
		func(action): return "command_state" in action
	).filter(
		func(action): return event.is_action_pressed(action, true)
	)
