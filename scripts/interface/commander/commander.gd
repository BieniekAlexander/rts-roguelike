@tool
class_name Commander
extends Control

### IDENTIFIERS
@export_range(0, 5) var id: int

### CONTROLS
@onready var selection: Array[Unit] = []
@onready var click_screen_pos: Vector2 = Vector2.ZERO

### RESOURCES
@onready var ore: int = 500
@onready var population_used: int = 0
@onready var population_max: int = 0
@onready var dominion: int = 300
var population:
	get: return population_max-population_used

### TECHNOLOGY
# specifies what a commander can construct
var technology_mapping: Dictionary = {
	Structure.Type.OUTPOST: TechnologySpec.new(true, 400, 0, 250),
	Structure.Type.MINE: TechnologySpec.new(true, 250, 100, 250),
	Structure.Type.DWELLING: TechnologySpec.new(false, 150, 0, 0)
}

func has_resources_for(a_type: Variant) -> bool:
	var technology_spec: TechnologySpec = technology_mapping[a_type]
	return (
		technology_spec.available
		and ore >= technology_spec.ore_cost
		and population >= technology_spec.population_cost
		and dominion >= technology_spec.dominion_cost
	)

### UNITS
func get_commandables():
	return get_tree().get_nodes_in_group("commandable").filter(
		func(u): return u.commander == self
	)

### NODE
func _process(delta: float) -> void:
	if get_node_or_null("ResourceSummaryLabel") != null:
		$ResourceSummaryLabel.text = (
			"\tore: %s\n\tpopulation: %s\n\tdominion: %s" % [
		 	ore,
			("%s/%s" % [population_used, population_max]),
			dominion
		])
