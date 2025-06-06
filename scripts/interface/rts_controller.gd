class_name RTSController extends CanvasLayer

## GAME STATE
@onready var map: Map = get_tree().current_scene.find_child("Map")


## CAMERA
@onready var camera: RTSCamera3D = get_viewport().get_camera_3d()


## MOUSE
### VISUALS
const free_cursor: Resource = preload("res://assets/interface/cursor_free.png")
const selection_cursor: Resource = preload("res://assets/interface/cursor_selection.png")
const attack_cursor: Resource = preload("res://assets/interface/cursor_attack.png")
const unknown_cursor: Resource = preload("res://assets/interface/cursor_unknown.png")
const invalid_cursor: Resource = preload("res://assets/interface/cursor_invalid.png")

static func cursor_evaluator(a_selection: Array, a_command_type: Script, a_command_message: CommandMessage) -> Resource:
	if a_command_type==Command:
		if a_command_message.target!=null:
			return selection_cursor
		else:
			return free_cursor
	elif a_command_type==Attack:
		return attack_cursor
	else:
		return unknown_cursor

### GAMESTATE
var cursor_target: Variant = Vector3.ZERO
var mouse_position: Vector2 = Vector2.ZERO

func get_cursor_target(a_mouse_position: Vector2) -> Entity:
	var hex_coorinate: Vector2 = VU.inXZ(camera.get_mouse_world_position(mouse_position, .5))
	return map.get_entity_at_position(hex_coorinate)


## CONTROL VARIABLES
@export var selection_box: ColorRect = ColorRect.new()
@onready var command_message: CommandMessage = CommandMessage.new(map)
@onready var next_command_additive: bool = false
var selection: Array[Node] = []
var select_down_position: Vector2 = Vector2.ZERO
var selected_unit_types: Set = Set.new()
var current_command_type: Script = null

var _active_command_context: CommandContext = CommandContext.NULL
var active_command_context: CommandContext:
	get: return _active_command_context
	set(value):
		_active_command_context = value
		upate_hud_buttons()

## NODE
func _ready():
	Input.set_custom_mouse_cursor(free_cursor)
	upate_hud_buttons()
	
	selection_box.visible = false
	if !selection_box.is_inside_tree():
		add_child(selection_box)

func _process(delta: float) -> void:
	command_message.world_position = camera.get_mouse_world_position(mouse_position)
	command_message.target = get_cursor_target(mouse_position)
	
	for i in range(selection.size()-1, -1, -1):
		if not is_instance_valid(selection[i]):
			selection.remove_at(i)
	
	current_command_type = active_command_context.evaluate_command(
		selection[0],
		command_message
	) if !selection.is_empty() else null
	
	if current_command_type==null:
		Input.set_custom_mouse_cursor(free_cursor)
	else:
		var check: Command.PreconditionFailureCause = current_command_type.meets_precondition(selection[0] if !selection.is_empty() else null, command_message)
		$CommandErrorMessage.text = Command.precondition_message_map[check]
		
		if check==Command.PreconditionFailureCause.NONE:
			Input.set_custom_mouse_cursor(cursor_evaluator(selection, current_command_type, command_message))
		else:
			Input.set_custom_mouse_cursor(invalid_cursor)


func _unhandled_input(event: InputEvent) -> void:
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
	## COMMAND CONTEXT UPDATES
	elif get_action_names_by_prefix(event, "command_").size()>0:
		process_command(get_action_names_by_prefix(event, "command_")[0])
	# ISSUING COMMANDS
	elif event.is_action_pressed("move"):
		assign_command_to_units(
			current_command_type,
			command_message,
			next_command_additive
		)

## CONTEXT SETTING
func process_command(command_name: String) -> void:
	if command_name.contains("tool"):
		if active_command_context.command_available(command_name, selection[0]):
			command_message.tool = Tool.command_tool_map[command_name]
	elif command_name.begins_with("command"):
		active_command_context = active_command_context.get_new_context(command_name)
	else:
		push_error("trying to process unknown action type: %s" % command_name)
		return
	
	var command: Script = active_command_context.evaluate_command(
		selection[0] if !selection.is_empty() else null,
		command_message
	)
	
	if command!=null and not command.requires_position():
		assign_command_to_units(
			command,
			command_message,
			next_command_additive
		)
	
	upate_hud_buttons()

func get_default_active_command_context(a_commandables: Array) -> CommandContext:
	a_commandables = a_commandables.filter(func(u): return is_instance_valid(u))
	selected_unit_types.clear()
	
	for c: Commandable in a_commandables:
		selected_unit_types.add(c.get_script())
	
	return selected_unit_types.map(
		func(t): return t.get_command_context()
	).reduce(
		func(a, b): return CommandContext.merge(a, b),
		CommandContext.NULL
	)


## SELECTION
func deselect():
	for c in selection:
		if is_instance_valid(c):
			c.set_deselected()
	selection = []
	selected_unit_types = Set.new()

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
	var hex_coorinate: Vector2 = VU.inXZ(camera.get_mouse_world_position(position, .5))
	var entity: Entity = map.get_entity_at_position(hex_coorinate)
	
	if entity != null and entity is Commandable:
		selection.append(entity)
		entity.set_selected()
	
	active_command_context = get_default_active_command_context(selection)

func set_selected_units():
	var selection_box_geometry: PackedVector2Array = [
		selection_box.position,
		selection_box.position + Vector2(selection_box.size.x, 0.0),
		selection_box.position + selection_box.size,
		selection_box.position + Vector2(0.0, selection_box.size.y)
	]
	
	for c: Commandable in get_tree().get_nodes_in_group("commandable"):
		# TODO collect units from spatial partitioning
		if c.commander_id!=1: continue
		var selected_screen_position = camera.unproject_position(c.global_position)
		if Geometry2D.is_point_in_polygon(selected_screen_position, selection_box_geometry):
			selection.append(c)
			c.set_selected()
	
	active_command_context = get_default_active_command_context(selection)


## SETTING COMMANDS
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
	a_command_type: Script,
	a_command_message: CommandMessage,
	add_to_queue: bool
) -> bool:
	# Returns whether or not the command was successfully assigned to any units
	selection = selection.filter(func(u): return is_instance_valid(u)) # TODO refactor so I dont have to do this smh
	
	if selection.size()==0:
		push_error("no selections")
		active_command_context = get_default_active_command_context(selection)
		return false
	
	if a_command_type==null:
		push_error("supplied a null command")
		active_command_context = get_default_active_command_context(selection)
		return false
	else:
		var check: Command.PreconditionFailureCause = a_command_type.meets_precondition(selection[0], a_command_message)
		
		if check!=Command.PreconditionFailureCause.NONE:
			active_command_context = get_default_active_command_context(selection)
			return false
		else:
			var new_command: Command = a_command_type.new(a_command_message)
			
			for c: Commandable in selection:
				c.update_commands(
					new_command,
					add_to_queue
				)
	
	if !add_to_queue:
		active_command_context = get_default_active_command_context(selection)
		command_message.clear()
		
	return true


## UTILS
static func get_action_names_by_prefix(event: InputEvent, event_prefix: String) -> Array:
	return InputMap.get_actions().filter(
		func(action_name: String): return event_prefix in action_name
	).filter(
		func(action_name: String): return event.is_action_pressed(action_name, true)
	)


## HUD
### HUD updates
func upate_hud_buttons() -> void:
	# TODO definitely gonna refactor
	for child: BoxContainer in $CommandsView.get_children():
		for subchild: Button in child.get_children():
			subchild.visible = !selection.is_empty() and active_command_context.command_available(
				subchild.name, selection[0]
			)

### HUD signals
func _on_control_button_pressed(control_name: String) -> void:
	process_command(control_name)
