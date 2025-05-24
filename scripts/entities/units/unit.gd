@tool
class_name Unit
extends Commandable

## WEAPONS
static var unit_weapon_patterns: Array[Pattern] = [
	Pattern.new(func(e): return true, Weapon.new(null, null, Weapon.AttackType.BALLISTIC))
]

static func get_weapon_evaluation_patterns() -> Array:
	return unit_weapon_patterns

## NODE
func _ready() -> void:
	super()
	add_to_group("unit")
	_nav_agent.avoidance_layers = 1<commander.id
	_nav_agent.avoidance_mask = 1<commander.id
	_nav_agent.velocity_computed.connect(Callable(_on_velocity_computed))


func initialize(a_map: Map, a_commander: Commander):
	super(a_map, a_commander)


func _process(delta: float) -> void:
	super(delta)
	
	if velocity.x>0:
		$Sprite.flip_h = true
	elif velocity.x<0:
		$Sprite.flip_h = false
	elif velocity.x==0 and _command!=null:
		$Sprite.flip_h = _command.message.position.x > global_position.x
	
	if $Sprite.hframes>1: # NOTE hardcoding this to get Sentry to have animation, TODO generalize
		if attack_timer==ATTACK_DURATION:
			$Sprite.frame = 2
		elif _command is Attack:
			$Sprite.frame = 1
		else:
			$Sprite.frame = 0
