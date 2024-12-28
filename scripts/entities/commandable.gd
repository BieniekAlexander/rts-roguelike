class_name Commandable
extends Node3D


## IDENTIFIERS
@export_range(0, 3) var owner_id: int
const TEAM_COLOR_MAP = {
	0: Color.WEB_GREEN,
	1: Color.RED,
	2: Color.AQUA,
	3: Color.YELLOW
}


## RESOURCES
@export var hpMax: float = 100
@onready var hp: float = hpMax


## COMMANDS
var map: HexGrid
var cells: Set = Set.new()
@export var AGGRO_RANGE: float = 5
@onready var _command: Command = null
@onready var _command_queue: Array[Command] = []


## COLLISION
@onready var collider: CollisionShape3D = $Body/Collider

func get_collision_extents() -> Array[Vector2]:
	var collider_radius = (
		collider.shape.size.x*sqrt(2)
		if collider.shape is BoxShape3D
		else collider.shape.radius
	)
	
	return [
		VU.inXZ(global_position),
		VU.inXZ(global_position)+Vector2.UP*collider_radius,
		VU.inXZ(global_position)+Vector2.DOWN*collider_radius,
		VU.inXZ(global_position)+Vector2.LEFT*collider_radius,
		VU.inXZ(global_position)+Vector2.RIGHT*collider_radius
	]


## ATTACK
@export var DAMAGE: float = 10
@export var ATTACK_RANGE: float = 0
@export var ATTACK_DURATION: int = 10
var attack_timer = 0

func _target_is_in_range(target: Commandable) -> bool:
	return (
		(VU.inXZ(global_position)-VU.inXZ(target.global_position)).length_squared()
		- pow(target.collider.shape.radius + collider.shape.radius, 2)
	) < pow(max(1, ATTACK_RANGE) , 2)


## AI
func _check_aggro() -> void:
	var commandables = get_tree().get_nodes_in_group("commandable")
	
	for c: Commandable in commandables:
		if (
			c.owner_id != owner_id
			and (global_position-c.global_position).length_squared() < pow(AGGRO_RANGE, 2)
		):
			_command = Command.new(c, Command.TYPE.MOVE)
			return


## VISUALS
@onready var hpBarFill: Sprite3D = $HPBar/HPBarFill
@onready var shotParticles: GPUParticles3D = $ShotParticles
var SHOT_DURATION: int = 2

func _process(delta: float) -> void:
	if hp<hpMax:
		$HPBar.visible = true
		
	if hpBarFill.visible:
		hpBarFill.scale.x = hp/hpMax
		hpBarFill.position.x = -scale.x * (1-hp/hpMax)
	
	if ATTACK_RANGE>0:
		shotParticles.emitting = attack_timer>0


## NODE
func _ready() -> void:
	$Sprite.modulate = TEAM_COLOR_MAP[owner_id]

func initialize(_map: HexGrid):
	map = _map

func _on_death() -> void:
	for cell: HexCell in cells.get_values():
		cell.remove_unit(self)
	
	queue_free()

func _recalculate_state() -> void:
	if hp <= 0:
		_on_death()
	
	if attack_timer>0:
		attack_timer-=1

	if _command!=null && !is_instance_valid(_command._target):
		_command = null
	
	if _command == null and not _command_queue.is_empty():
		_command = _command_queue.pop_front()

func _physics_process(delta: float) -> void:
	assert(false, "ABC method called from %s, please implement this in subclasses" % self)


## CONTROLS
func set_selected() -> void:
	$SelectionIndicator.visible = true
	$HPBar.visible = true

func set_deselected() -> void:
	$SelectionIndicator.visible = false

	if hp==hpMax:
		$HPBar.visible = false


func set_command(command: Command, add_to_queue: bool) -> void:
	if add_to_queue:
		_command_queue.append(command)
	elif command.type==Command.TYPE.STOP:
		print("stoppin")
		_command = null
	else:
		_command_queue = []
		_command = command
