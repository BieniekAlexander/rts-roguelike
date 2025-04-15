class_name Build
extends Command

var build_cells: Set = null

static func command_class():
	pass # TODO clean this up - this was added to let me check if a class inherits Command

 # TODO refactor this - I implemented commands to potentially use Scenes as a tool,
# and I would check the scene for the appropriate script to do some precondition checks,
# but it doesn't look like I have any guarantees around parsing the Script from the scene,
# so I'll just store the scnee and a reference to the script in an array and pass that around, I guess? fuck
static var tool_selector: Dictionary = {
	"command_tool_well": Tool.new(Structure.Type.MINE, preload("res://scenes/structures/mine.tscn")),
	"command_tool_forest": Tool.new(Structure.Type.DWELLING, preload("res://scenes/structures/dwelling.tscn")),
	"command_tool_core": Tool.new(Structure.Type.OUTPOST, preload("res://scenes/structures/outpost.tscn"))
}

static func meets_precondition(a_actor: Commandable, a_message: CommandMessage) -> bool:
	if a_message.tool==null: return false
	if !a_actor.commander.has_resources_for(a_message.tool.type): return false
	for cell: HexCell in Structure.get_arrangement_cells(
		a_message.map,
		VU.inXZ(a_message.position),
		StructureSpec.structure_type_spec_map[a_message.tool.type].cube_grid_arrangement
	).get_values():
		if cell.structure != null:
			return false
	
	var hex_cell: HexCell = a_message.map.get_map_cell(VU.inXZ(a_message.world_position))
	return Structure.valid_placement(a_message)

func can_act(a_actor: Commandable) -> bool:
	# TODO update this check such that the position is centered with respect to the build location
	return SU.unit_is_close_to_cells(a_actor, build_cells)

func fulfill_action(a_actor: Commandable) -> Command:
	var new_structure: Structure = message.tool.packed_scene.instantiate()
	var hex_location: Vector2i = HU.world_to_evenq(VU.inXZ(message.world_position))
	
	new_structure.initialize(message.map, a_actor.commander)
	message.map.add_structure(new_structure, hex_location, 0)
	new_structure.build_progress = .1
	
	return Repair.new(CommandMessage.new(message.map, new_structure))

func should_move(a_actor: Commandable) -> bool:
	return a_actor.global_position.distance_squared_to(message.world_position) >= .25


### NODE
func _init(a_message: CommandMessage) -> void:
	super(a_message)
	build_cells = Structure.get_arrangement_cells(
		a_message.map,
		VU.inXZ(a_message.position),
		StructureSpec.structure_type_spec_map[a_message.tool.type].cube_grid_arrangement
	)
