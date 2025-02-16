@tool
class_name Unit
extends Commandable


## COMMANDS
@export var SPEED: float = .1
@onready var SPEED_PER_SECOND: float = SPEED*Engine.physics_ticks_per_second
static var unit_command_context = CommandContext.new({
	null: Command,
	"command_state_attack_move": AttackMove
})

static func get_command_context() -> CommandContext:
	return unit_command_context

## NAVIGATION AGENT
@onready var _nav_agent: NavigationAgent3D = $NavigationAgent
@onready var _stop_timer: Timer = $Timer

func _on_velocity_computed(a_velocity: Vector3) -> void:
	## Update the position of the unit according to the navmesh's handle on our velocity
	velocity = a_velocity
	
	if velocity!=Vector3.ZERO:
		if move_and_slide():
			var c := get_slide_collision_count()
			for i in range(c):
				var collider = get_slide_collision(i).get_collider()
				if collider is Unit and collider._command==null:
					if _stop_timer.is_stopped():
						_command = null
		
		spatial_partition_dirty = true

func _update_velocity() -> void:
	if _command==null:
		_nav_agent.set_velocity(Vector3.ZERO)
	elif _command.can_act(self):
		var new_commands = _command.fulfill_action(self)
		
		if new_commands!=_command:
			update_commands(new_commands, true, true)
		_nav_agent.set_velocity(Vector3.ZERO)
	elif !_command.should_move(self):
		_nav_agent.set_velocity(Vector3.ZERO)
	elif !_nav_agent.is_navigation_finished():
		var next_path_position: Vector3 = _nav_agent.get_next_path_position()
		var prelim_velocity = global_position.direction_to(next_path_position)*SPEED_PER_SECOND
		_nav_agent.set_velocity(prelim_velocity)
	else:
		_command = null
		_nav_agent.set_velocity(Vector3.ZERO)

func load_destination(command: Command):
	if _command._target != null:
		_nav_agent.set_target_position(_command._target.global_position)
	else:
		_nav_agent.set_target_position(_command.position)

## NODE
func _ready() -> void:
	super()
	_nav_agent.avoidance_layers = 1<commander.id
	_nav_agent.avoidance_mask = 1<commander.id
	_nav_agent.velocity_computed.connect(Callable(_on_velocity_computed))


func initialize(a_map: Map, a_commander: Commander, a_position: Vector3):
	super(a_map, a_commander, a_position)
	

func _update_state() -> void:
	super()
	
	if _command!=null and _nav_agent.target_position != _command.position:
			load_destination(_command)
			_stop_timer.start()
	elif _nav_agent.is_navigation_finished():
		_nav_agent.set_target_position(global_position)

func _physics_process(delta: float) -> void:
	_update_state()
	_update_velocity()

func _process(delta: float) -> void:
	super(delta)
	
	if velocity.x>0:
		$Sprite.flip_h = true
	elif velocity.x<0:
		$Sprite.flip_h = false
