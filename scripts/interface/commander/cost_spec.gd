# Specifies what things are available to a commander
class_name TechnologySpec

var ore_cost: int
var dominion_cost: int
var population_cost: int
var available: bool
var availability_evaluator: Callable
var creation_time: int

static var get_true: Callable = func(f): return true

func _init(
	a_ore_cost: int,
	a_population_cost: int,
	a_dominion_cost: int,
	a_available: bool,
	a_availability_evaluator: Callable = get_true,
	a_creation_time: int = 10*Engine.physics_ticks_per_second
):
	assert(
		(a_availability_evaluator==get_true)==(a_available),
		"Availability evaluator should only be supplied if and only if the Tech is not always available"
	)
	
	available = a_available
	ore_cost = a_ore_cost
	population_cost = a_population_cost
	dominion_cost = a_dominion_cost
	availability_evaluator = a_availability_evaluator
	creation_time = a_creation_time
