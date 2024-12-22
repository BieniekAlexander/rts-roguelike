class_name Unit
extends NodotCharacter3D

## IDENTIFIERS
@export_range(0, 3) var owner_id: int
const TEAM_COLOR_MAP = {
	0: Color.WEB_GREEN,
	1: Color.RED,
	2: Color.AQUA,
	3: Color.YELLOW
}

#@export var target: Node TODO I think I don't need this

## RESOURCES
@export var HP: float = 100
@onready var hpBarFill: Sprite3D = $HPBar/HPBarFill
	
## COLLISION
@onready var collider: CollisionShape3D = $Collider
var cells: Set = Set.new()

func get_collision_extents() -> Array[Vector2]:
	var collider_radius = $Collider.shape.size.x*sqrt(2)
	return [
		VU.inXZ(global_position),
		VU.inXZ(global_position)+Vector2.UP*collider_radius,
		VU.inXZ(global_position)+Vector2.DOWN*collider_radius,
		VU.inXZ(global_position)+Vector2.LEFT*collider_radius,
		VU.inXZ(global_position)+Vector2.RIGHT*collider_radius
	]
	
## MOVEMENT
var map: HexGrid
@export var AGGRO_RANGE: float = 5
@export var SPEED: float = .1
@onready var nav: NavigationAgent3D = $NavigationAgent
@onready var command_queue: Array[Dictionary] = []
@onready var _command: Command = null
@onready var path: Vector3 = Vector3.ZERO

var xz_position: Vector2:
	get: return VU.inXZ(global_position)
	
func _get_path(a_target_position: Vector3) -> Vector3:
	if a_target_position == Vector3.INF:
		return Vector3.ZERO 
	
	nav.target_position = a_target_position
	var path = VU.onXZ(nav.get_next_path_position() - global_position)
		
	if (abs(path.length())<.001):
		return Vector3.ZERO
	else:
		var d = min(SPEED, path.length())
		return VU.onXZ(d*path.normalized())

# VISUALS
@onready var shotParticles: GPUParticles3D = $ShotParticles
var SHOT_DURATION: int = 2

# ATTACK
@export var DAMAGE = 10
@export var ATTACK_RANGE = 0
@export var ATTACK_DURATION = 10
var attack_timer = 0

func _target_is_in_range(target: Unit) -> bool:
	return (
		(xz_position-target.xz_position).length_squared()
		- pow(target.collider.shape.size.x + collider.shape.size.x, 2)
	) < pow(ATTACK_RANGE, 2)

## AI
func _check_aggro() -> void:
	var selectables = get_tree().get_nodes_in_group("rts_selectable")
	
	for unit: Unit in selectables:
		if (
			unit.owner_id != owner_id
			and (global_position-unit.global_position).length_squared() < pow(AGGRO_RANGE, 2)
		):
			_command = Command.new(unit)
			return

## NODE
func initialize(_map: HexGrid):
	map = _map

func _ready() -> void:
	$Sprite.modulate = TEAM_COLOR_MAP[owner_id]
	
func _process(delta: float) -> void:
	if HP<100:
		$HPBar.visible = true
		
	if hpBarFill.visible:
		hpBarFill.scale.x = HP/100
		hpBarFill.position.x = -scale.x * (1-HP/100)
	
	if ATTACK_RANGE>0:
		shotParticles.emitting = attack_timer>0

func _recalculate_state() -> void:
	if HP <= 0:
		queue_free()
	
	if attack_timer>0:
		attack_timer-=1
	
	if _command == null and not command_queue.is_empty():
		_command = command_queue.pop_front()

func _physics_process(delta: float) -> void:
	_recalculate_state()
	
	if _command != null:
		if _command.target_attackable() and _target_is_in_range(_command._target):
			if attack_timer==0:
				_command._target.HP -= DAMAGE
				attack_timer = ATTACK_DURATION
				
				if ATTACK_RANGE>0:
					shotParticles.look_at(
						Vector3(
							_command._target.global_position.x, 
							shotParticles.global_position.y, 
							_command._target.global_position.z
						)
					)
		else:
			if _command.aggro:
				_check_aggro()
			
			var path = _get_path(_command.position)
			
			if path==Vector3.ZERO:
				_command = null
			elif map.evaluate_movement(self, path):
				_command = null
	else:
		_check_aggro()

## EVENTS
func on_select():
	$SelectionIndicator.visible = true
	$HPBar.visible = true
	
func on_deselect():
	$SelectionIndicator.visible = false
	
	if HP==100:
		$HPBar.visible = false
	
func on_send(command: Command):
	_command = command
	#command_queue = [collision]
