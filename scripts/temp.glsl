// https://www.shadertoy.com/new
vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d ) {
    return a + b*cos( 6.28318*(c*t+d) );
}

const float hex_size = .1;
const int grid_width = 4;
const int grid_height = 4;
const int grid_width_max = 2;
const int grid_height_max = 2;

vec2 cube_to_axial(vec3 cube){
    return vec2(cube.x, cube.z);
}

vec3 axial_to_cube(vec2 hex) {
    return vec3(hex.x, -hex.x-hex.y, hex.y);
}

vec3 cube_round(vec3 cube) {
    int rx = int(round(cube.x));
    int ry = int(round(cube.y));
    int rz = int(round(cube.z));
    float x_diff = abs(float(rx) - cube.x);
    float y_diff = abs(float(ry) - cube.y);
    float z_diff = abs(float(rz) - cube.z);

    if ((x_diff > y_diff) && (x_diff > z_diff)) {
        rx = -ry-rz;
    } else if (y_diff > z_diff) {
        ry = -rx-rz;
    } else {
        rz = -rx-ry;
    }

    return vec3(rx, ry, rz);
}

vec2 hex_round(vec2 hex){
    return cube_to_axial(cube_round(axial_to_cube(hex)));
}

vec2 pixel_to_hex(float x, float y) {
    float q = x * .666 / hex_size;
    float r = (-x /3.0 + sqrt(3.0)/3.0 * y) / hex_size;
    return hex_round(vec2(q, r));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float t = iTime/4.0;
    vec2 uv = fragCoord/iResolution.xy; 
    vec2 hex_coords = pixel_to_hex(uv.x+t, uv.y-.2*t);
    
    int x = (int(hex_coords.x)%grid_width)-grid_width_max;
    int y = (int(hex_coords.y)%grid_height)-grid_height_max;
    int i = (grid_height*x+y)%16;
    
    vec3 p = pal(
        7.18+sin(float(i)*.3),
        vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,0.5),vec3(0.8,0.90,0.30)
    );

    // Time varying pixel color
    vec3 col = p;

    // Output to screen
    fragColor = vec4(col,1.0);
}