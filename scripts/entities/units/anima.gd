@tool
class_name Anima
extends Unit


static var anima_command_context = CommandContext.new({
	null: Command,
	"command_state_attack_move": AttackMove,
	"command_state_ability": Build,
	1: PickUp,
	2: DropOff
})

static func get_command_context() -> CommandContext:
	return anima_command_context


func get_default_interaction_command_type(target):
	if target is Star:
		return PickUp
	elif (
		!inventory.is_empty() 
		and inventory[0] is Star
		and target is Core
	):
		return DropOff
	else:
		return super(target)
