class_name Unit
extends Commandable


## COMMANDS
@export var SPEED: float = .1


## NAVIGATION AGENT
@onready var _nav_agent: NavigationAgent3D = $NavigationAgent
@onready var velocity: Vector3 = Vector3.ZERO

func move(safe_velocity: Vector3) -> void:
	global_position = global_position.move_toward(global_position + safe_velocity, SPEED)
	
func set_destination_from_command(command: Command):
	#_nav_agent.max_speed = SPEED*30
	if _command._target != null:
		_nav_agent.set_target_position(_command._target.global_position)
	else:
		_nav_agent.set_target_position(_command.position)


## NODE
func _ready() -> void:
	super()

func _recalculate_state() -> void:
	super()
	
	if _command!=null:
		set_destination_from_command(_command)

	if _nav_agent.is_navigation_finished():
		_command = null

func _physics_process(delta: float) -> void:
	_recalculate_state()
	
	if _command != null:
		# check if we can attack our target
		if _command.target_attackable() and _target_is_in_range(_command._target):
			if attack_timer==0:
				_command._target.hp -= DAMAGE
				attack_timer = ATTACK_DURATION
				
				if ATTACK_RANGE>0:
					shotParticles.look_at(
						Vector3(
							_command._target.global_position.x, 
							shotParticles.global_position.y, 
							_command._target.global_position.z
						)
					)
		elif !_nav_agent.is_navigation_finished():
			var next_path_position: Vector3 = _nav_agent.get_next_path_position()
			velocity = global_position.direction_to(next_path_position)*SPEED
			move(velocity)
			
			if _command.type == Command.TYPE.ATTACK_MOVE:
				_check_aggro()
	else:
		pass
		_check_aggro()
