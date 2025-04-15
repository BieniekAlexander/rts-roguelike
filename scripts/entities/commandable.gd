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
static var weapon_evaluator_empty: PatternEvaluator = PatternEvaluator.new([])

static func get_weapon_evaluator() -> PatternEvaluator:
	return weapon_evaluator_empty

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

static func command_evaluator_commandable(a_actor: Commandable, a_message: CommandMessage):
	if (
		a_message.target!=null
		and a_message.target.commander_id!=a_actor.commander_id
		and a_actor.get_weapon_evaluator().eval(a_message.target) != null
	):
		return Attack
	else:
		return Command

### COMMANDS
@export var AGGRO_RANGE: float = 5
@onready var _command: Command = null
@onready var _fallback_command: Command = Command.new(CommandMessage.new(map, self, null))
@onready var _command_queue: Array[Command] = []
static var commandable_command_context: CommandContext = CommandContext.new(
	command_evaluator_commandable,
	{"command_state_attack_move": CommandContext.new(AttackMove.evaluator, {})
})

static func get_command_context() -> CommandContext:
	return commandable_command_context


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
	var weapon_evaluator: PatternEvaluator = get_weapon_evaluator()
	var entities = map.get_nearby_entities(a_position, a_range)
	var commandables = entities.filter(func(e: Entity): return e is Commandable)
	commandables = AU.sort_on_key(
		func(e: Entity): return a_position.distance_squared_to(VU.inXZ(e.global_position)),
		commandables.filter(
			func(e: Entity): return weapon_evaluator.eval(e)!=null
		)
	)
	
	for c: Commandable in commandables:
		if (
			c.commander_id>0 and c.commander_id != commander_id
			and (global_position-c.global_position).length_squared() < pow(a_range, 2)
		):
			# TODO find the closest one, with some sort of priority
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


### NODE
func _ready() -> void:
	super()
	add_to_group("commandable")
	attributes = Set.new(attributes_list)

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

func update_commands(a_commands: Variant, add_to_queue: bool = false, prepend: bool = false) -> void:
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
