#version 300 es

// This is a fragment shader. If you've opened this file first, please
// open and read lambert.vert.glsl before reading on.
// Unlike the vertex shader, the fragment shader actually does compute
// the shading of geometry. For every pixel in your program's output
// screen, the fragment shader is run for every bit of geometry that
// particular pixel overlaps. By implicitly interpolating the position
// data passed into the fragment shader by the vertex shader, the fragment shader
// can compute what color to apply to its pixel based on things like vertex
// position, light position, and vertex color.
precision highp float;

uniform vec4 u_Color; // The color with which to render this instance of geometry.
uniform float u_Time;

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

vec4 random(vec4 x){
    return fract(sin((x * 50.0) + 35.0)) * x;
}

// Refer to a simple noise function online
float noise(vec3 pos){
    vec3 i = floor(pos);
    vec3 f = fract(pos);
    f = f * f * (3.0 - 2.0 * f);

    vec4 a = i.xxyy + vec4(0.0, 1.0, 0.0, 1.0);
    vec4 k1 = random(a.xyxy);
    vec4 k2 = random(k1.xyxy + a.zzww);
    vec4 b = k2 + i.zzzz;
    vec4 k3 = random(b);
    vec4 k4 = random(b + 1.0);

    vec4 o1 = fract(k3 * (1.0 / 41.0));
    vec4 o2 = fract(k4 * (1.0 / 41.0));
    vec4 o3 = o2 * f.z + o1 * (1.0 - f.z);
    vec2 o4 = o3.yw * f.x + o3.xz * (1.0 - f.x);

    return o4.y * f.y + o4.x * (1.0 - f.y);
}

float fbm(vec3 pos) {
	float noiseOutput = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 6; i++) {
		noiseOutput += amplitude * noise(pos);
		pos = 2.5 * pos + vec3(10, 20, 30);
		amplitude *= 0.5;
	}
	return noiseOutput;
}

void main()
{
    vec3 color = vec3(1, 0.5, 0.3);
    color = mix(color, u_Color.rgb, fbm(fs_Pos.xyz + vec3(u_Time)));
    
    out_Col = vec4(color.rgb, 1);
}
