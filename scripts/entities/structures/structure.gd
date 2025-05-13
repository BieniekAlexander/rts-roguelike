@tool
class_name Structure
extends Commandable

### POSITION
var cube_grid_arrangement: Array:
	get: return StructureSpec.structure_type_spec_map.get(type, null).cube_grid_arrangement

var map_cells: Set:
	get: return map.structure_cell_map.get(self, null)

static func get_arrangement_cells(
	a_map: Map,
	a_point: Vector2,
	a_cube_grid_arrangement: Array
) -> Set:
	var center_coords: Vector2i = HU.world_to_evenq(a_point)
	var neighbor_coordinates = HU.get_evenq_neighbor_coordinates(
		center_coords,
		a_cube_grid_arrangement
	)
	
	if neighbor_coordinates.any(
		func(c: Vector2i): return not a_map.grid_coordinates_in_bounds(c)
	):
		return Set.Empty
	else:
		return Set.new(
			neighbor_coordinates.map(
			func(coords): return a_map.evenq_grid[coords.x][coords.y]
		)
	)

static func valid_placement(a_command_message: CommandMessage, a_cube_grid_arrangement: Array) -> bool:
	var cells_to_check: Set = Structure.get_arrangement_cells(
		a_command_message.map,
		VU.inXZ(a_command_message.position),
		StructureSpec.structure_type_spec_map[a_command_message.tool.type].cube_grid_arrangement
	)
	
	if cells_to_check.is_empty(): return false
	
	for cell: HexCell in cells_to_check.get_values():
		if cell.structure!=null:
			return false
			
	return true

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
		$TrainBar/TrainBarFill.scale.x = float(training_queue[0][0])/450 # TODO remove hardcode, sooo lazy
		$TrainBar/TrainBarFill.position.x = -scale.x * (1-$TrainBar/TrainBarFill.scale.x)

func initialize(a_map: Map, a_commander: Commander):
	super(a_map, a_commander)
	a_commander.add_structure(self)
	commander.population_max += population_provided
	commander.population_used += population_required

func _on_death() -> void:
	commander.remove_structure(self)
	map.remove_structure(self)
	
	if commander!=null:
		commander.population_max -= population_provided
		commander.population_used -= population_required
		
	super()
