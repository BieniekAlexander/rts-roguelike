## A node that handles mouse input for an IsometricCamera3D
class_name RTSMouseInput extends Nodot3D

@export var enabled: bool = true
## The ColorRect to use as a selection box
@export var selection_box: ColorRect = ColorRect.new()
## The associated camera (usually an IsometricCamera3D)
@export var camera: Camera3D
## Maximum projection distance (the distance from camera to the ground)
@export var max_projection_distance: float = 500.0

@export_category("Input Actions")
@export var select_action: String = "isometric_camera_select"
@export var action_action: String = "isometric_camera_action"
@export var am_action: String = "isometric_camera_am"

## Emitted when a node is selected
signal selected(node: Node)
## Emitted when multiple nodes are selected
signal selected_multiple(nodes: Array[Node])
## Emitted when an action is requested
signal action_requested(collision: Dictionary)

@onready var map: HexGrid = get_tree().current_scene.find_child("Map")
var selected_nodes: Array[Node] = []
var mouse_position: Vector2 = Vector2.ZERO
var select_down_position: Vector2 = Vector2.ZERO

func _init():
	register_mouse_actions()

func _ready():
	selection_box.visible = false
	if !selection_box.is_inside_tree():
		add_child(selection_box)

func _input(event):
	if !enabled: return
	
	if event is InputEventMouseMotion:
		mouse_position = event.position
		# TODO make htis beter, but I'm fuckin lazy right now
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
	elif event.is_action_pressed(select_action):
		select_down_position = mouse_position
		selection_box.visible = true
		selection_box.set_size(Vector2.ZERO)
	elif event.is_action_released(select_action):
		select()
		selection_box.visible = false
	elif event.is_action_pressed(action_action):
		action(false) # TODO hacking together move and attack_move commands
	elif event.is_action_pressed(am_action):
		action(true)

func get_3d_position(position_2d: Vector2):
	return camera.project_position(position_2d, max_projection_distance)

func select():
	deselect()
	var drag_distance = abs(select_down_position - mouse_position)
	if drag_distance < Vector2(10, 10):
		get_selectable()
	else:
		get_selectables()
		
func get_selectable():
	deselect()
	var hex_coorinate: Vector2 = VU.inXZ(map.get_mouse_world_position(mouse_position))
	var target: Unit = map.get_obstruction(hex_coorinate)
	
	if target != null:
		print("clicking target %s" % target)
		var selectable: RTSSelectable = target.get_node("RTSSelectable")
		selected_nodes = [selectable]
		selectable.select()
		emit_signal("selected", target)
	
func get_selectables():
	var selection_box_geometry: PackedVector2Array = [
		selection_box.position,
		selection_box.position + Vector2(selection_box.size.x, 0.0),
		selection_box.position + selection_box.size,
		selection_box.position + Vector2(0.0, selection_box.size.y)
	]
	
	for selectable in get_tree().get_nodes_in_group("rts_selectable"):
		var selected_screen_position = camera.unproject_position(selectable.global_position)
		if Geometry2D.is_point_in_polygon(selected_screen_position, selection_box_geometry):
			selected_nodes.append(selectable)
			Nodot.get_first_child_of_type(selectable, RTSSelectable).select()
			
	emit_signal("selected_multiple", selected_nodes)

func action(a_angery: bool):
	var world_position: Vector3 = map.get_mouse_world_position(mouse_position)
	var active_selection = selected_nodes.filter(func(u): return is_instance_valid(u)) # TODO refactor so I dont have to do this smh
	
	if active_selection.size()==0:
		return
	else: # calculating centroid TODO make more efficient
		var xs: Array = active_selection.map(func(u: Unit): return u.xz_position.x)
		var zs: Array = active_selection.map(func(u: Unit): return u.xz_position.y)
		var centroid: Vector3 = Vector3((xs.max()+xs.min())/2, world_position.y, (zs.max()+zs.min())/2)
		var path = world_position-centroid
		
		for u: Unit in active_selection:
			var rts_selectable = Nodot.get_first_child_of_type(u, RTSSelectable)
			var command: Command = Command.new(VU.onXZ(u.global_position+path), a_angery)
			rts_selectable.action(command)
	
	#for selected_node in selected_nodes:
			#if is_instance_valid(selected_node):
				#
				#if rts_selectable:
					#rts_selectable.action(world_position)
	return # TODO stuff below is deprecated
	

func deselect():
	for selected_node in selected_nodes:
		if is_instance_valid(selected_node):
			Nodot.get_first_child_of_type(selected_node, RTSSelectable).deselect()
	selected_nodes = []

func register_mouse_actions():
	var action_names = [select_action, action_action, am_action] # TODO refactor for actual good controls later
	var default_keys = [
		MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE
	]
	for i in action_names.size():
		var action_name = action_names[i]
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
			InputManager.add_action_event_mouse(action_name, default_keys[i])
