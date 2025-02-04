extends MeshInstance3D


### SHADER
## The set of values representing whether an area of the fog mesh should be drawn
## The number of shader points representing the width of 1 distance unit of space
const points_per_unit: float = 4
var fog_texture: PortableCompressedTexture2D
@onready var fog_image: Image = Image.create(
	scale.x*points_per_unit,
	scale.z*points_per_unit,
	false,
	Image.FORMAT_L8
)

func world_to_image(world_position: Vector2) -> Vector2i:
	return Vector2i(
		round((world_position.x+scale.x/2)*points_per_unit),
		round((world_position.y+scale.z/2)*points_per_unit)
	)

func image_to_world(image_coordinate: Vector2i) -> Vector2:
	return Vector2(
		image_coordinate.x/points_per_unit-scale.x/2,
		image_coordinate.y/points_per_unit-scale.z/2
	)


### NODE
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	# https://forum.godotengine.org/t/how-to-create-texture-from-fog_image-in-editorscript/52267/2
	for x in range(fog_image.get_width()):
		for y in range(fog_image.get_height()):
			if fog_image.get_pixelv(Vector2i(x, y))==Color.WHITE:
				fog_image.set_pixelv(Vector2i(x, y), Color.WHITE)
			else:
				fog_image.set_pixelv(Vector2i(x, y), Color.GRAY)
	
	for unit: Commandable in get_tree().get_nodes_in_group("commandable"):
		if unit.commander_id!=1: continue # TODO hardcoding for now - find some method of identifying the ID of the player
		var indices: Vector2i = world_to_image(VU.inXZ(unit.global_position))
		for x in range(max(indices.x-unit.sight_range, 0), min(indices.x+unit.sight_range, fog_image.get_width())):
			for y in range(max(indices.y-unit.sight_range, 0), min(indices.y+unit.sight_range, fog_image.get_height())):
				fog_image.set_pixelv(Vector2i(x, y), Color.BLACK)
	
	fog_texture = PortableCompressedTexture2D.new()
	fog_texture.create_from_image(fog_image, PortableCompressedTexture2D.COMPRESSION_MODE_LOSSLESS) 

func _process(delta: float) -> void:
	get_active_material(0).set_shader_parameter("fog_texture", fog_texture)

func _ready() -> void:
	# setup shader
	get_active_material(0).set_shader_parameter("mesh_scale", scale)
	get_active_material(0).set_shader_parameter("points_per_unit", points_per_unit)
	# set up fog image
	fog_image.fill(Color.WHITE)
