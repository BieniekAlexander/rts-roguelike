@tool
class_name Vanguard
extends Unit


## NODE
func _process(delta: float) -> void:
	super(delta)
	if Engine.is_editor_hint():
		return
		
	if attack_timer > ATTACK_DURATION-5 and _command!=null:
		$Lazer.global_position = global_position + .5*(_command.message.position-global_position) + Vector3.UP*.5
		
		# TODO get the 3D mesh to be aligned correctly - I can't get the mesh's major axis to be correct
		$Lazer.rotation = Vector3(-VU.inXZ(_command.message.position-global_position).angle(), 0, deg_to_rad(90))
		
		$Lazer.scale.y = (_command.message.position-global_position).length()/2
		$Lazer.set_visible(true)
	else:
		$Lazer.set_visible(false)


## WEAPONS
static var vanguard_weapon_evaluator: PatternEvaluator = PatternEvaluator.new([
	[(func(e): return true), Weapon.new(null, null, Weapon.AttackType.LAZER)]
])

static func get_weapon_evaluator() -> PatternEvaluator:
	return vanguard_weapon_evaluator
