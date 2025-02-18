@tool
class_name Structure
extends Commandable


### POSITION
var cell: HexCell = null
@export var cube_grid_arrangement: Array[Vector3i] = [Vector3i.ZERO]

### RESOURCES
var terra_amount := 0

### TRAINING
@onready var training_queue: Array = []
@onready var rally_command: Command = null

func train(scene) -> void:
	var unit: Unit = scene.instantiate()
	var spawn_bias: Vector3 = (
		(rally_command.position-global_position).normalized()
		if rally_command!=null
		else Vector3.ZERO
	)
	
	unit.initialize(map, commander)
	unit.global_position = NavigationServer3D.map_get_closest_point(get_world_3d().navigation_map, global_position+spawn_bias)
	unit.update_commands(rally_command)

### NODE
func _ready() -> void:
	assert(
	(
		cube_grid_arrangement.size()>0 
		and cube_grid_arrangement[0]==Vector3i.ZERO
	),
	"Make sure this is true for consistency")

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
	commander.terra += terra_amount

func _on_death() -> void:
	map.remove_structure(self)
	commander.terra -= terra_amount
	super()
