@tool
class_name Structure
extends Commandable

### PROPERTIES
var type: Type

### POSITION
var cube_grid_arrangement: Array:
	get: return StructureSpec.structure_type_spec_map[type].cube_grid_arrangement

var map_cells: Set:
	get: return map.structure_cell_map.get(self, null)

static func get_arrangement_cells(
	a_map: Map,
	a_point: Vector2,
	a_cube_grid_arrangement: Array
) -> Set:
	var center_coords: Vector2i = HU.world_to_evenq(a_point)
	return Set.new(
			HU.get_evenq_neighbor_coordinates(
			center_coords,
			a_cube_grid_arrangement
		).map(
			func(coords): return a_map.evenq_grid[coords.x][coords.y]
		)
	)

static func valid_placement(a_command_message: CommandMessage) -> bool:
	return a_command_message.map.get_map_cell(VU.inXZ(a_command_message.world_position)).structure==null

### RESOURCES
@onready var build_progress: float = 1
@export var population_provided := 0
@export var population_required := 0

### TRAINING
@onready var training_queue: Array = []
@onready var rally_command: Command = null

func train(scene) -> void:
	var unit: Unit = scene.instantiate()
	var spawn_bias: Vector3 = (
		(rally_command.message.position-global_position).normalized()
		if rally_command!=null
		else Vector3.ZERO
	)
	
	unit.initialize(map, commander)
	unit.global_position = NavigationServer3D.map_get_closest_point(get_world_3d().navigation_map, global_position+spawn_bias)
	unit.update_commands(rally_command)

### NODE
func _ready() -> void:
	add_to_group("structure")
	super()

func _update_state() -> void:
	super()
	
	if _command!=null and _command.get_script()==Command:
		rally_command = _command
		_command = null

func _process(delta: float) -> void:
	super(delta)
	$Sprite.modulate.a = build_progress
	$TrainBar.visible = !training_queue.is_empty()
	
	if $TrainBar.visible:
		$TrainBar/TrainBarFill.scale.x = float(training_queue[0])/450 # TODO remove hardcode, sooo lazy
		$TrainBar/TrainBarFill.position.x = -scale.x * (1-$TrainBar/TrainBarFill.scale.x)

func initialize(a_map: Map, a_commander: Commander):
	super(a_map, a_commander)
	commander.population_max += population_provided
	commander.population_used += population_required

func _on_death() -> void:
	map.remove_structure(self)
	
	if commander!=null:
		commander.population_max -= population_provided
		commander.population_used -= population_required
		
	super()


## ENUMERATED STRUCTURES
# TODO use this enum to organize and persist global properties of structures before they're instantiated,
# because I can't peek into packed scenes
enum Type {
	MINE,
	DWELLING,
	OUTPOST,
	LAB,
	COMPOUND,
	ARMORY
}
