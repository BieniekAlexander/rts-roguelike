class_name StructureSpec

var placement_checker: Callable
var cube_grid_arrangement: Array

func _init(
	a_placement_checker: Callable,
	a_cube_grid_arrangement: Array
) -> void:
	placement_checker = a_placement_checker
	cube_grid_arrangement = a_cube_grid_arrangement

static var structure_type_spec_map: Dictionary[int, StructureSpec] = {
	# NOTE: I tried to supply the Script as one of hte fields of the StructureSpec, but Godot couldn't interpret it, so I'm just passing the placement checking function
	Entity.Type.UNDEFINED: StructureSpec.new(Structure.valid_placement, [Vector3i.ZERO]),
	Entity.Type.STRUCTURE_MINE: StructureSpec.new(Mine.valid_placement, [Vector3i.ZERO]),
	Entity.Type.STRUCTURE_DWELLING: StructureSpec.new(Structure.valid_placement, [Vector3i.ZERO]),
	Entity.Type.STRUCTURE_OUTPOST: StructureSpec.new(Structure.valid_placement, [Vector3i.ZERO, Vector3i(-1,1,0), Vector3i(-1,0,1), Vector3i(0,-1,1), Vector3i(0,1,-1), Vector3i(1,0,-1), Vector3i(1,-1,0)]),
	Entity.Type.STRUCTURE_LAB: StructureSpec.new(Structure.valid_placement, [Vector3i.ZERO, Vector3i(-1,1,0), Vector3i(-1,0,1)]),
	Entity.Type.STRUCTURE_COMPOUND: StructureSpec.new(Structure.valid_placement, [Vector3i.ZERO, Vector3i(-1,1,0), Vector3i(-1,0,1)]),
	Entity.Type.STRUCTURE_ARMORY: StructureSpec.new(Structure.valid_placement, [Vector3i.ZERO, Vector3i(-1,1,0), Vector3i(-1,0,1)])
}
