#version 300 es
#define PI 3.1415926535897932384626433832795

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

uniform highp float u_Time;

// Procedural Controls
uniform highp float terrainFreq;    // Sets the frequency of noise that outputs terrain elevations
uniform highp float earthToAlien;    // 0.0 -> earth color palette, 1.0 -> alien color palette


// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.


// FBM Noise ------------------------------------
#define NUM_OCTAVES 3

float mod289(float x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4 mod289(vec4 x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4 perm(vec4 x){return mod289(((x * 34.0) + 1.0) * x);}

float noise(vec3 p){
    vec3 a = floor(p);
    vec3 d = p - a;
    d = d * d * (3.0 - 2.0 * d);

    vec4 b = a.xxyy + vec4(0.0, 1.0, 0.0, 1.0);
    vec4 k1 = perm(b.xyxy);
    vec4 k2 = perm(k1.xyxy + b.zzww);

    vec4 c = k2 + a.zzzz;
    vec4 k3 = perm(c);
    vec4 k4 = perm(c + 1.0);

    vec4 o1 = fract(k3 * (1.0 / 41.0));
    vec4 o2 = fract(k4 * (1.0 / 41.0));

    vec4 o3 = o2 * d.z + o1 * (1.0 - d.z);
    vec2 o4 = o3.yw * d.x + o3.xz * (1.0 - d.x);

    return o4.y * d.y + o4.x * (1.0 - d.y);
}

float fbm(vec3 x) {
	float v = 0.0;
	float a = 0.5;
	vec3 shift = vec3(100);
	for (int i = 0; i < NUM_OCTAVES; ++i) {
		v += a * noise(x);
		x = x * 2.0 + shift;
		a *= 0.5;
	}
	return v;
}

// Noise2 ------------------------------------
float hash(float n) { return fract(sin(n) * 1e4); }
float hash(vec2 p) { return fract(1e4 * sin(17.0 * p.x + p.y * 0.1) * (0.1 + abs(sin(p.y * 13.0 + p.x)))); }

float noise2(vec3 x) {
	const vec3 step = vec3(110, 241, 171);

	vec3 i = floor(x);
	vec3 f = fract(x);
 
    float n = dot(i, step);

	vec3 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix( hash(n + dot(step, vec3(0, 0, 0))), hash(n + dot(step, vec3(1, 0, 0))), u.x),
                   mix( hash(n + dot(step, vec3(0, 1, 0))), hash(n + dot(step, vec3(1, 1, 0))), u.x), u.y),
               mix(mix( hash(n + dot(step, vec3(0, 0, 1))), hash(n + dot(step, vec3(1, 0, 1))), u.x),
                   mix( hash(n + dot(step, vec3(0, 1, 1))), hash(n + dot(step, vec3(1, 1, 1))), u.x), u.y), u.z);
}

// Noise3 ------------------------------------
float noise3(float x) {
	float i = floor(x);
	float f = fract(x);
	float u = f * f * (3.0 - 2.0 * f);
	return mix(hash(i), hash(i + 1.0), u);
}

// Perlin Noise ------------------------------------
float map(float value, float old_lo, float old_hi, float new_lo, float new_hi)
{
	float old_range = old_hi - old_lo;
    if (old_range == 0.0) {
	    return new_lo; 
	} else {
	    float new_range = new_hi - new_lo;  
	    return (((value - old_lo) * new_range) / old_range) + new_lo;
	}
}

/**
 * The canonical GLSL hash function
 */
float hash1(float x)
{
	return fract(sin(x) * 43758.5453123);
}

/** 
 * Nothing is mathematically sound about anything below: 
 * I just chose values based on experimentation and some 
 * intuitions I have about what makes a good hash function
 */
vec3 gradient(vec3 cell)
{
	float h_i = hash1(cell.x);
	float h_j = hash1(cell.y + pow(h_i, 3.0));
	float h_k = hash1(cell.z + pow(h_j, 5.0));
    float ii = map(fract(h_i + h_j + h_k), 0.0, 1.0, -1.0, 1.0);
    float jj = map(fract(h_j + h_k), 0.0, 1.0, -1.0, 1.0);
	float kk = map(h_k, 0.0, 1.0, -1.0, 1.0);
    return normalize(vec3(ii, jj, kk));
}

/**
 * Perlin's "ease-curve" fade function
 */
float fade(float t)
{
   	float t3 = t * t * t;
    float t4 = t3 * t;
    float t5 = t4 * t;
    return (6.0 * t5) - (15.0 * t4) + (10.0 * t3);        
}    

float pnoise(in vec3 coord)
{
    vec3 cell = floor(coord);
    vec3 unit = fract(coord);
   
    vec3 unit_000 = unit;
    vec3 unit_100 = unit - vec3(1.0, 0.0, 0.0);
    vec3 unit_001 = unit - vec3(0.0, 0.0, 1.0);
    vec3 unit_101 = unit - vec3(1.0, 0.0, 1.0);
    vec3 unit_010 = unit - vec3(0.0, 1.0, 0.0);
    vec3 unit_110 = unit - vec3(1.0, 1.0, 0.0);
    vec3 unit_011 = unit - vec3(0.0, 1.0, 1.0);
    vec3 unit_111 = unit - 1.0;

    vec3 c_000 = cell;
    vec3 c_100 = cell + vec3(1.0, 0.0, 0.0);
    vec3 c_001 = cell + vec3(0.0, 0.0, 1.0);
    vec3 c_101 = cell + vec3(1.0, 0.0, 1.0);
    vec3 c_010 = cell + vec3(0.0, 1.0, 0.0);
    vec3 c_110 = cell + vec3(1.0, 1.0, 0.0);
    vec3 c_011 = cell + vec3(0.0, 1.0, 1.0);
    vec3 c_111 = cell + 1.0;

    float wx = fade(unit.x);
    float wy = fade(unit.y);
    float wz = fade(unit.z);
 
    float x000 = dot(gradient(c_000), unit_000);
	float x100 = dot(gradient(c_100), unit_100);
	float x001 = dot(gradient(c_001), unit_001);
	float x101 = dot(gradient(c_101), unit_101);
	float x010 = dot(gradient(c_010), unit_010);
	float x110 = dot(gradient(c_110), unit_110);
	float x011 = dot(gradient(c_011), unit_011);
	float x111 = dot(gradient(c_111), unit_111);
   
    float y0 = mix(x000, x100, wx);
    float y1 = mix(x001, x101, wx);
    float y2 = mix(x010, x110, wx);
    float y3 = mix(x011, x111, wx);
    
	float z0 = mix(y0, y2, wy);
    float z1 = mix(y1, y3, wy);
    
    return mix(z0, z1, wz);
}	


float GetBias(float time, float bias) {
    return (time / ((((1.0/bias) - 2.0) * (1.0 - time)) + 1.0));
}

float GetGain(float time, float gain) {
    if (time < 0.5) {
        return GetBias(time * 2.0, gain) / 2.0;
    } else {
        return GetBias(time * 2.0 - 1.0, 1.0 - gain) / 2.0 + 0.5;
    }
}
vec3 rgb(float r, float g, float b) {
    return vec3(r / 255.0, g / 255.0, b / 255.0);
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
        out_Col = vec4(diffuseColor.rgb * lightIntensity, diffuseColor.a);

        vec3 noiseInput = fs_Pos.xyz * terrainFreq;
        float noise = fbm(noiseInput);

        vec3 surfaceColor = vec3(noise);

        // Earth color palette
        vec3 waterCol_e = rgb(10.0, 145.0, 175.0);
        vec3 deepWaterCol_e = rgb(0.0, 36.0, 118.0) * waterCol_e;
        vec3 landCol_e = rgb(12.0, 145.0, 82.0);
        vec3 deepLandCol_e = rgb(33.0, 125.0, 1.0) * landCol_e;
        vec3 beachCol_e = rgb(255.0, 234.0, 200.0);
        vec3 dirtCol_e = rgb(38.0, 11.0, 11.0);
        vec3 mountainCol_e = rgb(53.0, 43.0, 53.0);
        vec3 deepMountainCol_e = rgb(125.0, 97.0, 118.0) * mountainCol_e;

        // Alien color palette
        vec3 waterCol_a = rgb(84.0, 195.0, 195.0);
        vec3 deepWaterCol_a = rgb(42.0, 162.0, 147.0) * waterCol_a;
        vec3 landCol_a = rgb(122.0, 93.0, 122.0);
        vec3 deepLandCol_a = rgb(205.0, 16.0, 139.0) * landCol_a;
        vec3 beachCol_a = rgb(236.0, 148.0, 111.0);
        vec3 dirtCol_a = rgb(163.0, 8.0, 0.0);
        vec3 mountainCol_a = rgb(68.0, 39.0, 122.0);
        vec3 deepMountainCol_a = rgb(61.0, 61.0, 93.0) * mountainCol_a;

        vec3 waterCol = mix(waterCol_e, waterCol_a, earthToAlien);
        vec3 deepWaterCol = mix(deepWaterCol_e, deepWaterCol_a, earthToAlien) * waterCol;
        vec3 landCol = mix(landCol_e, landCol_a, earthToAlien);
        vec3 deepLandCol = mix(deepLandCol_e, deepLandCol_a, earthToAlien) * landCol;
        vec3 beachCol = mix(beachCol_e, beachCol_a, earthToAlien);
        vec3 dirtCol = mix(dirtCol_e, dirtCol_a, earthToAlien);
        vec3 mountainCol = mix(mountainCol_e, mountainCol_a, earthToAlien);
        vec3 deepMountainCol = mix(deepMountainCol_a, deepMountainCol_e, earthToAlien) * mountainCol;


        vec3 black = rgb(0.0, 0.0, 0.0);
        vec3 white = rgb(255.0, 255.0, 255.0);
        
        // Creates water level
        float x = noise2(3.0 * noise2((0.0006 * u_Time) + vec3(noiseInput) + noiseInput) + noiseInput);
        vec3 waterFinalCol = mix(deepWaterCol, waterCol, x);
        surfaceColor = waterFinalCol;

        // Creates beach level
        if (noise > 0.4 && noise < 0.52) {
            surfaceColor = beachCol;
        } else if (noise > 0.52 && noise < 0.53) {
            float x = GetBias((noise - 0.52) / 0.01, 0.3);
            surfaceColor = mix(beachCol, waterFinalCol, x);
        }

        // Creates land level
        if (noise > 0.48 && noise < 0.5) {
            float x = GetBias((noise - 0.48) / 0.02, 0.3);
            surfaceColor = mix(dirtCol, beachCol, x);
        } else if (noise > 0.4 && noise < 0.48) {
            float x = GetGain((noise - 0.4) / 0.08, 0.4);
            surfaceColor = mix(landCol, deepLandCol, x);
        } else if (noise < 0.5) {
            surfaceColor = landCol;
        }
        
        // Creates mountain level
        float mountainNoise = fbm(10.0 * noiseInput + 20.0);
        if (noise > 0.37 && noise < 0.4) {
            float x = GetGain((noise - 0.37) / 0.03, mountainNoise);
            surfaceColor = mix(deepMountainCol, landCol, x);
        } else if (noise > 0.32 && noise < 0.37) {
            float x = GetGain((noise - 0.32) / 0.05, mountainNoise);
            surfaceColor = mix(mountainCol, deepMountainCol, x);
        } else if (noise < 0.4) {
            float x = GetGain(noise / 0.32, mountainNoise);
            surfaceColor = mix(white, mountainCol, x);
        }

        out_Col = vec4(surfaceColor.xyz, 1.0);
        
               
}
