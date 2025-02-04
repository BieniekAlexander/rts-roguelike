class_name Commandable
extends Entity


### RESOURCES
@export var hpMax: float = 100
@onready var hp: float = hpMax
@export_range(0, 100) var sight_range: int = 10
@onready var build_progress: float = 1
@onready var inventory: Array[Entity] = []
@onready var inventory_capacity: int = 1

func receive_damage(attacker: Commandable, amount: float) -> void:
	hp -= amount
	
	if hp>0 and _command==null and !(_disposition==Disposition.PASSIVE):
		update_commands(Command.new(attacker), true, true)


### COMMANDS
@export var AGGRO_RANGE: float = 5
@onready var _command: Command = null
@onready var _fallback_command: Command = Command.new(self)
@onready var _command_queue: Array[Command] = []
static var commandable_command_context = CommandContext.new({
	null: Command,
})

static func get_command_context() -> CommandContext:
	return commandable_command_context


### ATTACK
@export var DAMAGE: float = 10
@export var ATTACK_RANGE: float = 0
@export var ATTACK_DURATION: int = 10
var attack_timer = 0

func _target_is_in_range(target: Commandable) -> bool:
	return (
		(VU.inXZ(global_position)-VU.inXZ(target.global_position)).length_squared()
		- pow(target.collision_radius + collision_radius, 2)
	) < pow(max(1, ATTACK_RANGE) , 2)


### BEHAVIOR
enum Disposition {
	PASSIVE,
	AGGRESSIVE
}

@onready var _disposition: Disposition = Disposition.AGGRESSIVE

func get_aggro_near_position(a_position: Vector2, a_range: float) -> Command:
	var entities = map.get_entities_in_range(a_position, a_range)
	var commandables = entities.filter(func(e: Entity): return e is Commandable)
	commandables = AU.sort_on_key(commandables, func(e: Entity): return a_position.distance_squared_to(VU.inXZ(e.global_position)))
	
	for c: Commandable in commandables:
		if (
			c.commander_id>0 and c.commander_id != commander_id
			and (global_position-c.global_position).length_squared() < pow(a_range, 2)
		):
			# TODO find the closest one, with some sort of priority
			return Command.new(c)
	
	return null


### VISUALS
@onready var hpBarFill: Sprite3D = $HPBar/HPBarFill
var SHOT_DURATION: int = 2

func _process(delta: float) -> void:
	$HPBar.visible = hp<hpMax or $SelectionIndicator.visible
	
	if hpBarFill.visible:
		hpBarFill.scale.x = hp/hpMax
		hpBarFill.position.x = -scale.x * (1-hpBarFill.scale.x)
	
	if ATTACK_RANGE>0:
		# TODO refactor particles
		var shotParticles: GPUParticles3D = $ShotParticles
		shotParticles.emitting = attack_timer>0
		
	if $SelectionIndicator.visible and Input.is_key_pressed(KEY_BACKSLASH):
		print("position: %s" % global_position)


### NODE
func _ready() -> void:
	super()
	add_to_group("commandable")

func _on_death() -> void:
	for coords: Vector2i in pc_set.get_values():
		map.spatial_partition_grid[coords.x][coords.y].remove(self)
	
	queue_free()

func _update_state() -> void:
	if hp <= 0:
		_on_death()
	
	if attack_timer>0:
		attack_timer-=1

	if _command!=null && _command.is_finished():
		_command = null
	
	if _command == null and not _command_queue.is_empty():
		_command = _command_queue.pop_front()
	
	var new_commands = _command.get_updated_state(self) if _command!=null else _fallback_command.get_updated_state(self)
	
	if (
		!is_same(new_commands, null)
	 	and !is_same(new_commands, _fallback_command)
		and (new_commands is Array or new_commands!=_command)
	):
		update_commands(new_commands, true, true)
		#_command = new_command

func _physics_process(delta: float) -> void:
	_update_state()


## CONTROLS
func set_selected() -> void:
	$SelectionIndicator.visible = true
	$HPBar.visible = true

func set_deselected() -> void:
	$SelectionIndicator.visible = false

	if hp==hpMax:
		$HPBar.visible = false

func update_commands(a_commands, add_to_queue: bool = false, prepend: bool = false) -> void:
	## Update the commandable's commands, accounting for queueing and arrays of commands
	if a_commands == null:
		_command_queue = []
		_command = null
	elif a_commands is Command:
		if add_to_queue and prepend:
			if _command != null:
				_command_queue.push_front(_command)
			_command = a_commands
		elif add_to_queue and !prepend:
			_command_queue.append(a_commands)
		else:
			_command_queue = []
			_command = a_commands
	elif a_commands is Array and a_commands.size()>0:
		if add_to_queue and prepend:
			if _command != null:
				_command_queue.assign(a_commands.slice(1)+[_command]+_command_queue)
			else:
				_command_queue.assign(a_commands.slice(1)+_command_queue)
			_command = a_commands[0]
		elif add_to_queue and !prepend:
			_command_queue.append_array(a_commands)
		else:
			_command = a_commands[0]
			_command_queue = a_commands.slice(1)
	else:
		push_error("Command argument is unsupported, arg=%s" % a_commands)

func get_default_interaction_command_type(target):
	if target is Commandable or target is Vector3:
		return Command
	else:
		push_error("Undefined interaction between this type and %s" % target)
