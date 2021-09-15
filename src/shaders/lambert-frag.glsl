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
uniform vec3 u_CameraPos;

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

vec3 random3( vec3 p ) {
    return fract(sin(vec3(dot(p,vec3(127.1, 311.7, 191.999)),
                          dot(p,vec3(269.5, 183.3, 765.54)),
                          dot(p, vec3(420.69, 631.2,109.21))))
                 *43758.5453);
}

float surflet(vec3 p, vec3 gridPoint) {
    // Compute the distance between p and the grid point along each axis, and warp it with a
    // quintic function so we can smooth our cells
    vec3 t2 = abs(p - gridPoint);
    vec3 t = vec3(1.0) - 6.0 * 
             vec3(pow(t2.x, 5.0), pow(t2.y, 5.0), pow(t2.z, 5.0)) + 15.0 * 
             vec3(pow(t2.x, 4.0), pow(t2.y, 4.0), pow(t2.z, 4.0)) - 10.0 * 
             vec3(pow(t2.x, 3.0), pow(t2.y, 3.0), pow(t2.z, 3.0));
    // Get the random vector for the grid point (assume we wrote a function random2
    // that returns a vec2 in the range [0, 1])
    vec3 gradient = random3(gridPoint);
    // Get the vector from the grid point to P
    vec3 diff = p - gridPoint;
    // Get the value of our height field by dotting grid->P with our gradient
    float height = dot(diff, gradient);
    // Scale our height field (i.e. reduce it) by our polynomial falloff function
    return height * t.x * t.y * t.z;
}

float perlinNoise3D(vec3 p) {
	float surfletSum = 0.f;
	// Iterate over the eight integer corners surrounding p
	for(int dx = 0; dx <= 1; ++dx) {
		for(int dy = 0; dy <= 1; ++dy) {
			for(int dz = 0; dz <= 1; ++dz) {
                float avg = (p.x + p.y + p.z) / 3.f;
				surfletSum += avg * surflet(p, floor(p) + vec3(dx, dy, dz));
			}
		}
	}
    // put in [0, 1] range
	return abs(surfletSum) * 2.0;
}

vec4 getGradient(float t){
    vec4 lightBlue = vec4(0.01176471, 0.98823529, 0.890196, 1.0);
    float a = 0.7;
    if (t <  0.01){ return lightBlue; }
    if (t <  0.25){ return mix(lightBlue, vec4(u_Color.rgb, a), (t - 0.05) / 0.24); }
    if (t <  0.3) { return vec4(u_Color.rgb, a); }
    if (t <  0.5) { return vec4(u_Color.rgb, a) - vec4(0.07, 0.07, 0.07, 0.0); }
    if (t <  0.7) { return vec4(u_Color.rgb, a) - vec4(0.14, 0.14, 0.14, 0.0); }
    if (t <= 1.0) { return vec4(u_Color.rgb, a) - vec4(0.21, 0.21, 0.21, 0.0); }
    return vec4(1.0,1.0,0.0,1.0);
}

void main()
{
    // Material base color (before shading)
        vec4 diffuseColor = u_Color;

        // Calculate the diffuse term for Lambert shading
        float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
        // Avoid negative lighting values
        diffuseTerm = clamp(diffuseTerm, 0.f, 1.f);

        float ambientTerm = 0.2;

        float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                            //to simulate ambient lighting. This ensures that faces that are not
                                                            //lit by our point light are not completely black.

        // Compute final shaded color

        // get perlin noise values using three differently scaled positions
        // then, get the corresponding gradient colors and average
        float perlin1 = perlinNoise3D(fs_Pos.rgb);
        float perlin2 = clamp(perlinNoise3D(fs_Pos.rgb * 2.0), 0.0, 1.0);
        float perlin3 = clamp(perlinNoise3D(fs_Pos.rgb * 0.5), 0.0, 1.0);
        float fadeStartDist = 3.5;
        float fadeDist = 2.5;
        float hardcodedCameraZ = 5.0;
        float distFromCam = abs(fs_Pos.z - hardcodedCameraZ) - fadeStartDist;
        vec4 gradientColor = (getGradient(perlin1) + getGradient(perlin2) + getGradient(perlin3)) / 3.0;
        vec4 mixedPerlin = mix(gradientColor, vec4(u_Color.rgb, 0.7), clamp(distFromCam / fadeDist, 0.0, 1.0));
        
        out_Col = vec4(mixedPerlin.rgb, mixedPerlin.a);
}
