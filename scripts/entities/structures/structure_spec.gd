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
	Structure.Type.MINE: StructureSpec.new(Mine.valid_placement, [Vector3i.ZERO]),
	Structure.Type.DWELLING: StructureSpec.new(Structure.valid_placement, [Vector3i.ZERO]),
	Structure.Type.OUTPOST: StructureSpec.new(Structure.valid_placement, [Vector3i.ZERO, Vector3i(-1,1,0), Vector3i(-1,0,1), Vector3i(0,-1,1), Vector3i(0,1,-1), Vector3i(1,0,-1), Vector3i(1,-1,0)]),
	Structure.Type.LAB: StructureSpec.new(Structure.valid_placement, [Structure.valid_placement, Vector3i(-1,1,0), Vector3i(-1,0,1)]),
	Structure.Type.COMPOUND: StructureSpec.new(Structure.valid_placement, [Vector3i.ZERO, Vector3i(-1,1,0), Vector3i(-1,0,1)]),
	Structure.Type.ARMORY: StructureSpec.new(Structure.valid_placement, [Vector3i.ZERO])
}

#static var structure_type_spec_map: Dictionary[int, StructureSpec] = {
	#Structure.Type.MINE: StructureSpec.new(null, [Vector3i.ZERO]),
	#Structure.Type.DWELLING: StructureSpec.new(null, [Vector3i.ZERO]),
	#Structure.Type.OUTPOST: StructureSpec.new(null, [Vector3i.ZERO, Vector3i(-1,1,0), Vector3i(-1,0,1), Vector3i(0,-1,1), Vector3i(0,1,-1), Vector3i(1,0,-1), Vector3i(1,-1,0)]),
	#Structure.Type.LAB: StructureSpec.new(null, [Vector3i.ZERO, Vector3i(-1,1,0), Vector3i(-1,0,1)]),
	#Structure.Type.COMPOUND: StructureSpec.new(null, [Vector3i.ZERO, Vector3i(-1,1,0), Vector3i(-1,0,1)]),
	#Structure.Type.ARMORY: StructureSpec.new(null, [Vector3i.ZERO])
#}
