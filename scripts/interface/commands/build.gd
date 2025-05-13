class_name Build
extends Command

var build_cells: Set = null

 # TODO refactor this - I implemented commands to potentially use Scenes as a tool,
# and I would check the scene for the appropriate script to do some precondition checks,
# but it doesn't look like I have any guarantees around parsing the Script from the scene,
# so I'll just store the scnee and a reference to the script in an array and pass that around, I guess? fuck
static var build_tool_names: Array = [
	"command_tool_outpost",
	"command_tool_dwelling",
	"command_tool_mine",
	"command_tool_lab",
	"command_tool_compound",
	"command_tool_armory"
]

static func get_valid_tool_names() -> Array:
	return build_tool_names

static func meets_precondition(a_actor: Commandable, a_message: CommandMessage) -> PreconditionFailureCause:
	if a_message.tool==null:
		return PreconditionFailureCause.UNENUMERATED_FAILURE_CAUSE
	elif not a_actor.commander.has_resources_for(a_message.tool.type):
		return PreconditionFailureCause.NOT_ENOUGH_RESOURCES
	elif not StructureSpec.structure_type_spec_map[a_message.tool.type].placement_checker.call(
		a_message,
		StructureSpec.structure_type_spec_map[a_message.tool.type].cube_grid_arrangement
	):
		return PreconditionFailureCause.INVALID_PLACEMENT
	else:
		return PreconditionFailureCause.NONE

func can_act(a_actor: Commandable) -> bool:
	# TODO update this check such that the position is centered with respect to the build location
	return SU.unit_is_close_to_cells(a_actor, build_cells)

func fulfill_action(a_actor: Commandable) -> Variant:
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
