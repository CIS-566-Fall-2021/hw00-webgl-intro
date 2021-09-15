#version 300 es
precision highp float;

// This is a fragment shader. If you've opened this file first, please
// open and read lambert.vert.glsl before reading on.
// Unlike the vertex shader, the fragment shader actually does compute
// the shading of geometry. For every pixel in your program's output
// screen, the fragment shader is run for every bit of geometry that
// particular pixel overlaps. By implicitly interpolating the position
// data passed into the fragment shader by the vertex shader, the fragment shader
// can compute what color to apply to its pixel based on things like vertex
// position, light position, and vertex color.

uniform vec4 u_Color; // The color with which to render this instance of geometry.
uniform float u_Tick;

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

float random(float p, float frequency){
    p = ceil(p * frequency);
 	return abs(fract(1284.421631 * fract((p * 32891.3851 + 58304.1820) / 128.1803246)));
}

vec3 fbm(vec3 v) {
    //v /= 10000.0;
    int octave = 3;
	float a = 0.5;
    vec3 newVec = vec3(0.0, 0.0, 0.0);
	for (int i = 0; i < octave; ++i) {
        float frequency = pow(2.0, float(i));
		newVec.x += a * random(v.x, frequency);
        newVec.y += a * random(v.y, frequency);
        newVec.z += a * random(v.z, frequency);
		a *= 0.75;
	}
	return (newVec / 2.0) - .5;
}

void main()
{
    // Material base color (before shading)
        vec4 diffuseColor = u_Color;

        // Calculate the diffuse term for Lambert shading
        float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
        // Avoid negative lighting values
        // diffuseTerm = clamp(diffuseTerm, 0, 1);

        float ambientTerm = 0.2;

        float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                            //to simulate ambient lighting. This ensures that faces that are not
                                                            //lit by our point light are not completely black.

        // Compute final shaded color
        //out_Col = vec4((vec3(diffuseColor)) * lightIntensity, diffuseColor.a);
        //out_Col = vec4(vec3(mod(u_Tick, 255.0) / 255.0) * lightIntensity, diffuseColor.a);
        vec3 timeAdj = vec3((mod(u_Tick, 255.0) / 255.0));
        out_Col = vec4((vec3(diffuseColor) + fbm(vec3(fs_Pos))) * lightIntensity, diffuseColor.a);
}
