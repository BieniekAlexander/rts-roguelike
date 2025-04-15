# Specifies what things are available to a commander
class_name TechnologySpec

var available: bool
var ore_cost: int
var population_cost: int
var dominion_cost: int

func _init(
	a_available: bool,
	a_ore_cost: int,
	a_population_cost: int,
	a_dominion_cost: int
):
	available = a_available
	ore_cost = a_ore_cost
	population_cost = a_population_cost
	dominion_cost = a_dominion_cost
