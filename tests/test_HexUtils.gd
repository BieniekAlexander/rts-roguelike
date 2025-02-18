extends GutTest

func test_evenq_to_cube():
	for evenq in [
		Vector2i(10, 15),
		Vector2i(-10, 14),
		Vector2i(11, -15),
		Vector2i(-10, -14),
		Vector2i(0, -15),
		Vector2i(0, 14),
		Vector2i(-9, 0),
		Vector2i(10, 0)
	]:
		assert_eq(evenq, HU.cube_to_evenq(HU.evenq_to_cube(evenq)))

func test_cube_to_evenq():
	for axial in [
		Vector2i(10, 15),
		Vector2i(-10, 14),
		Vector2i(11, -15),
		Vector2i(-10, -14),
		Vector2i(0, -15),
		Vector2i(0, 14),
		Vector2i(-9, 0),
		Vector2i(10, 0)
	]:
		var cube: Vector3i = HU.axial_to_cube(axial)
		assert_eq(cube, HU.evenq_to_cube(HU.cube_to_evenq(cube)))

func test_cube_to_axial():
	var cube: Vector3i = Vector3i(7, 3, -10)
	assert_eq(cube, HU.axial_to_cube(HU.cube_to_axial(cube)))
	
func test_axial_to_cube():
	var axial: Vector2i = Vector2i(7, 3)
	assert_eq(axial, HU.cube_to_axial(HU.axial_to_cube(axial)))
