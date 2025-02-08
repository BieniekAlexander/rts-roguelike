shader_type spatial;

uniform vec3 mesh_scale;
uniform float points_per_unit;
uniform sampler2D fog_texture;

varying vec2 texture_position;
varying vec2 fog_point;

void vertex() {
	texture_position = VERTEX.xz-.5;
	//mesh_position = VERTEX/points_per_unit;
	//fog_point = mesh_position.xz/(mesh_scale.xz*);
}

void fragment() {
	ALBEDO.xyz = vec3(0., 0., 0.);
	ALPHA = texture(fog_texture, texture_position).b;


	//if (texture(fog_texture, vertex_world_pos.xz).r!=0.) {
		//ALPHA = texture(fog_texture, vertex_world_pos.xz).r;
	//}

	//for (int i = 0; i < pos.length(); i++) {
		//if (distance(pos[i], VERTEX.xz)<1.) {
			//ALPHA = 0.;
			//break;
		//}
	//}
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
