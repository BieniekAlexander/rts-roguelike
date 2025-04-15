class_name StructureSpec

var cube_grid_arrangement: Array
var type: Script

func _init(
	a_script: Variant,
	a_cube_grid_arrangement: Array
) -> void:
	type = a_script
	cube_grid_arrangement = a_cube_grid_arrangement

static var structure_type_spec_map: Dictionary[int, StructureSpec] = {
	Structure.Type.MINE: StructureSpec.new(Mine, [Vector3i.ZERO]),
	Structure.Type.DWELLING: StructureSpec.new(Structure, [Vector3i.ZERO]),
	Structure.Type.OUTPOST: StructureSpec.new(Outpost, [Vector3i.ZERO, Vector3i(-1,1,0), Vector3i(-1,0,1), Vector3i(0,-1,1), Vector3i(0,1,-1), Vector3i(1,0,-1), Vector3i(1,-1,0)]),
	Structure.Type.LAB: StructureSpec.new(Lab, [Vector3i.ZERO, Vector3i(-1,1,0), Vector3i(-1,0,1)]),
	Structure.Type.COMPOUND: StructureSpec.new(Structure, [Vector3i.ZERO, Vector3i(-1,1,0), Vector3i(-1,0,1)]),
	Structure.Type.ARMORY: StructureSpec.new(Structure, [Vector3i.ZERO])
}

#static var structure_type_spec_map: Dictionary[int, StructureSpec] = {
	#Structure.Type.MINE: StructureSpec.new(null, [Vector3i.ZERO]),
	#Structure.Type.DWELLING: StructureSpec.new(null, [Vector3i.ZERO]),
	#Structure.Type.OUTPOST: StructureSpec.new(null, [Vector3i.ZERO, Vector3i(-1,1,0), Vector3i(-1,0,1), Vector3i(0,-1,1), Vector3i(0,1,-1), Vector3i(1,0,-1), Vector3i(1,-1,0)]),
	#Structure.Type.LAB: StructureSpec.new(null, [Vector3i.ZERO, Vector3i(-1,1,0), Vector3i(-1,0,1)]),
	#Structure.Type.COMPOUND: StructureSpec.new(null, [Vector3i.ZERO, Vector3i(-1,1,0), Vector3i(-1,0,1)]),
	#Structure.Type.ARMORY: StructureSpec.new(null, [Vector3i.ZERO])
#}
