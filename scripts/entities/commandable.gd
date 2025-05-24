@tool
class_name Commandable
extends Entity

### ATTRIBUTES
enum Movement { GROUNDED, FLYING }
enum Armor { LIGHT, HEAVY }
enum Attribute { MECH, BIO, UNMANNED }

@export var movement: Movement = Movement.GROUNDED
@export var armor: Armor = Armor.LIGHT
@export var attributes_list: Array[Attribute] = []
var attributes: Set

### WEAPON
static var weapon_patterns_empty: Array[Pattern] = []

static func get_weapon_evaluation_patterns() -> Array[Pattern]:
	return weapon_patterns_empty

### RESOURCES
@export var hpMax: float = 100
@onready var hp: float = hpMax
@onready var inventory: Array[Entity] = []
@onready var inventory_capacity: int = 1

func receive_damage(attacker: Commandable, amount: float) -> void:
	hp -= amount
	
	if hp>0 and _command==null and attacker!=null and !(_disposition==Disposition.PASSIVE):
		update_commands(
				Command.new(CommandMessage.new(map, attacker, null, attacker.global_position)
			),
			true,
			true
		)

static var _commandable_command_context: CommandContext

static func get_command_context() -> CommandContext:
	if _commandable_command_context==null:
		_commandable_command_context = CommandContext.new(
			[
				Pattern.new(
					func(a): return (
					a[1].target!=null
					and a[1].target is Commandable
					and a[1].target.commander_id!=a[0].commander_id
					and Pattern.eval(a[0].get_weapon_evaluation_patterns(), a[1].target) != null	
					), Attack
				),
				Pattern.new(func(a): return true, Command)
			],
			{
				"command_attack_move": CommandContext.new(
					[
						Pattern.new(func(a): return a[1].target!=null and a[1].target is Commandable, Attack),
						Pattern.new(func(a): return true, AttackMove)
					]
				),
				"command_stop": CommandContext.new(
					[Pattern.new(func(a): return true, Stop)]
				)
			}
		)
	
	return _commandable_command_context

### COMMANDS
@export var AGGRO_RANGE: float = 5
@onready var _command: Command = null
@onready var _fallback_command: Command = Command.new(CommandMessage.new(map, self, null))
@onready var _command_queue: Array[Command] = []


### ATTACK
@export var DAMAGE: float = 10
@export var ATTACK_RANGE: float = 0
@export var ATTACK_DURATION: int = 10
var attack_timer = 0


### BEHAVIOR
enum Disposition {
	PASSIVE,
	AGGRESSIVE
}

@onready var _disposition: Disposition = Disposition.PASSIVE

func get_aggro_near_position(a_position: Vector2, a_range: float) -> Command:
	var weapon_patterns: Array[Pattern] = get_weapon_evaluation_patterns()
	var entities = map.get_nearby_entities(a_position, a_range)
	var commandables = entities.filter(func(e: Entity): return e is Commandable)
	commandables = AU.sort_on_key(
		func(e: Entity): return a_position.distance_squared_to(VU.inXZ(e.global_position)),
		commandables.filter(
			func(e: Entity): return Pattern.eval(weapon_patterns, e)!=null
		)
	)
	
	for c: Commandable in commandables:
		if (
			c.commander_id>0 and c.commander_id != commander_id
			and (global_position-c.global_position).length_squared() < pow(a_range, 2)
		):
			# TODO I believe `AttackMove` is never finding any `Structure`s because the `Structure`s don't have colliders
			return Attack.new(CommandMessage.new(map, c, null))
	
	return null


### VISUALS
@onready var hpBarFill: Sprite3D = $HPBar/HPBarFill
var SHOT_DURATION: int = 2

func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	$HPBar.visible = hp<hpMax or $SelectionIndicator.visible
	
	if hpBarFill.visible:
		hpBarFill.scale.x = hp/hpMax
		hpBarFill.position.x = -scale.x * (1-hpBarFill.scale.x)
	
	if $SelectionIndicator.visible and Input.is_key_pressed(KEY_BACKSLASH):
		print("position: %s" % global_position)


## NAVIGATION AGENT
@export var SPEED: float = .1
@onready var SPEED_PER_SECOND: float = SPEED*Engine.physics_ticks_per_second
@onready var _nav_agent: NavigationAgent3D = get_node_or_null("NavigationAgent")
@onready var _stop_timer: Timer = get_node_or_null("Timer")

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

func load_destination(command: Command):
	_nav_agent.set_target_position(_command.message.position)


### NODE
func _ready() -> void:
	super()
	add_to_group("commandable")
	attributes = Set.new(attributes_list)

## Perform any sort of command handling
func _process_commands() -> void:
	var new_commands: Variant  = _command.get_updated_state(self) if _command!=null else _fallback_command.get_updated_state(self)
	
	if is_same(new_commands, null):
		_command = null
	elif !is_same(new_commands, _command) and !is_same(new_commands, null):
		update_commands(new_commands, true, true)
	elif _command.can_act(self):
		new_commands = _command.fulfill_action(self)
		_nav_agent.set_velocity(Vector3.ZERO)
		
		if is_same(new_commands, null):
			_command = null
		if new_commands!=_command and !is_same(new_commands, null):
			_command = null
			update_commands(new_commands, true, true)
	elif _nav_agent!=null and _command.should_move(self):
			if _nav_agent.target_position != _command.message.position:
				load_destination(_command)
				_stop_timer.start()
			
			if !_nav_agent.is_navigation_finished():
				var next_path_position: Vector3 = _nav_agent.get_next_path_position()
				var prelim_velocity = global_position.direction_to(next_path_position)*SPEED_PER_SECOND
				_nav_agent.set_velocity(prelim_velocity)
			else:
				_nav_agent.set_target_position(global_position)
				_command = null	

func _update_state() -> void:
	if hp <= 0:
		_on_death()
		return
	
	if attack_timer>0:
		attack_timer-=1
		
	if _command==null and not _command_queue.is_empty():
		_command = _command_queue.pop_front()
	
	_process_commands()

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	_update_state()


## CONTROLS
func set_selected() -> void:
	$SelectionIndicator.visible = true
	$HPBar.visible = true

func set_deselected() -> void:
	$SelectionIndicator.visible = false

	if hp==hpMax:
		$HPBar.visible = false

## Update the commandable's commands, accounting for queueing and arrays of commands
func update_commands(a_commands: Variant, add_to_queue: bool = false, prepend: bool = false) -> void:
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
