#@tool
class_name Scenario
extends Node3D


### GAME STATE
var frame: int = 0
@onready var commanders: Array = range(3).map(
	func(o):
		var c = (
			load("res://scenes/player.tscn").instantiate()
			if o == 1
			else Commander.new()
		)
		c.id = o
		return c
)


### SCENARIO CONFIG
@onready var grid_config: Array = FSU.get_data_from_csv_file("res://configs/scenarios/scenario1/grid.csv")
@onready var init_event_config: Dictionary = FSU.get_data_from_json_file("res://configs/scenarios/scenario1/init.json")
@onready var event_queue: Array = AU.sort_on_key(
	func(e): return e["timer"],
	FSU.get_data_from_json_file("res://configs/scenarios/scenario1/events.json").map(
		func(e): return EventUtils.render_event_config(e, 0)
	)
)

static func process_event_queue(
	a_queue: Array,
	a_map: Map,
	commanders: Array,
	a_frame: int
) -> void:
	## With respect to the timestep, go through the event queue and see if there's anything to activate
	var i: int = 0
	
	while i<a_queue.size():
		var current_event = a_queue[i]
		
		if current_event["timer"] == a_frame:
			EventUtils.load_entities_from_event(current_event, a_map, commanders)
			var updated_event = EventUtils.render_event_config(current_event, a_frame)
			a_queue.remove_at(i)
			
			if updated_event != null:
				AU.priority_queue_push(func(e): return e["timer"], current_event, a_queue)
		elif current_event["timer"] > a_frame:
			return
		else:
			i+=1


### GAME WORLD
var map: Map


### NODE
func _ready() -> void:
	purge()
	
	map = Map.from_config(grid_config)
	map.name = "Map"
	add_child(map, true)
	map.set_owner(self)
	
	var players_node = Node3D.new()
	players_node.name = "Players"
	add_child(players_node, true)
	players_node.set_owner(self)
	
	for commander in commanders:
		players_node.add_child(commander)
		commander.set_owner(self)
	
	EventUtils.load_entities_from_event(init_event_config, map, commanders, false)
	
	for commander: Commander in commanders: # setting camera
		if commander.has_node("Camera"):
			for commandable: Commandable in commander.get_commandables():
				if commandable is Outpost:
					commander.get_node("Camera").center_on_entity(commandable)
	
	map.nav_region.bake_navigation_mesh()
	
	if Engine.is_editor_hint():
		set_physics_process(false)

func _physics_process(delta: float) -> void:
	map.reassign_entities_in_spatial_partition(get_tree().get_nodes_in_group("entity"))
	process_event_queue(event_queue, map, commanders, frame)
	frame += 1

func purge() -> void:
	if map != null:
		map.queue_free()
	if has_node("Players"):
		$Players.queue_free()
	
