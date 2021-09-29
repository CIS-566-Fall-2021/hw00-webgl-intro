#version 300 es

//This is a vertex shader. While it is called a "shader" due to outdated conventions, this file
//is used to apply matrix transformations to the arrays of vertex data passed to it.
//Since this code is run on your GPU, each vertex is transformed simultaneously.
//If it were run on your CPU, each vertex would have to be processed in a FOR loop, one at a time.
//This simultaneous transformation allows your program to run much faster, especially when rendering
//geometry with millions of vertices.

uniform mat4 u_Model;       // The matrix that defines the transformation of the
                            // object we're rendering. In this assignment,
                            // this will be the result of traversing your scene graph.

uniform mat4 u_ModelInvTr;  // The inverse transpose of the model matrix.
                            // This allows us to transform the object's normals properly
                            // if the object has been non-uniformly scaled.

uniform mat4 u_ViewProj;    // The matrix that defines the camera's transformation.
                            // We've written a static matrix for you to use for HW2,
                            // but in HW3 you'll have to generate one yourself

uniform highp float u_Time;

uniform vec4 center;

// Procedural Controls
uniform highp float terrainFreq;    // Sets the frequency of noise that outputs terrain elevations
uniform highp float brushScale;

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Pos;

out vec3 p1;                // Neighbors a tiny epsilon away from our point which we will use to calculate the deformed normal
out vec3 p2;
out vec3 p3; 
out vec3 p4;

const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.


// FBM Noise ------------------------------------
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

float fbm(vec3 x, int num_octaves) {
	float v = 0.0;
	float a = 0.5;
	vec3 shift = vec3(100);
	for (int i = 0; i < num_octaves; ++i) {
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

// Brush noise function
float brushNoise(vec3 noiseInput) {
    float smallBrushFreq = 30.0 * brushScale;
    float largeBrushFreq = 25.0 * brushScale;
    float smallBrushNoise = fbm(smallBrushFreq * noiseInput + 20.0, 5);
    float largeBrushNoise = 1.0 - pnoise(largeBrushFreq * noiseInput);
    float sizeNoise = fbm(noiseInput + 20.0, 7);
    return mix(smallBrushNoise, largeBrushNoise, sizeNoise);
}

// Calculates the elevation of a given point based on its noise value
float getElevation(vec3 noiseInput) {

    float noise = fbm(noiseInput, 3);

    float waterElevation = 0.9;
    float beachElevation = 0.93;
    float landElevation = 1.0;
    float mountElevation1 = 1.05;
    float mountElevation2 = 1.7;
    float mountElevation3 = 1.7;

    float waveNoise = noise2(5.0 * noise2((0.0006 * u_Time) + vec3(noiseInput) + noiseInput) + noiseInput);
    float elevation = mix(waterElevation, waterElevation + 0.05, waveNoise);

    // Creates beach level
    if (noise > 0.4 && noise < 0.52) {
        elevation = beachElevation;
    } else if (noise > 0.52 && noise < 0.53) {
        float x = GetBias((noise - 0.52) / 0.01, 0.3);
        elevation = mix(beachElevation, waterElevation, x);
    }

    // Creates land level
    float brushNoise = brushNoise(noiseInput);
    if (noise > 0.48 && noise < 0.5) {
        float x = GetBias((noise - 0.48) / 0.02, 0.7);
        elevation = mix(landElevation, beachElevation, x);
    } else if (noise > 0.4 && noise < 0.48) {
        float x = GetGain((noise - 0.4) / 0.08, 0.9);
        elevation = mix(landElevation * ((brushNoise * 0.08) + landElevation), landElevation, x);
    }

    // Creates mountain level
    float mountainNoise = fbm(10.0 * noiseInput + 20.0, 3);
    if (noise > 0.37 && noise < 0.4) {
        float x = GetBias((noise - 0.37) / 0.03, 0.9);
        elevation =  mix(mountElevation1, landElevation * ((brushNoise * 0.08) + landElevation), x);
    } else if (noise < 0.37) {
        float x = GetGain(noise / 0.37, mountainNoise);
        elevation =  mix(mountElevation2, mountElevation1, x);
    }

    return elevation;

}

void main()
{
    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation

    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. This is necessary to ensure the normals remain
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.

    vec4 modelposition = u_Model * vs_Pos;   // Temporarily store the transformed vertex positions for use below

    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies

    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices

    vec3 noiseInput = modelposition.xyz * terrainFreq;
    float noise = fbm(noiseInput, 3);

    float elevation = getElevation(noiseInput);                  

    vec3 offsetAmount = vec3(vs_Nor) * elevation;
    vec3 noisyModelPosition = modelposition.xyz + offsetAmount;
    gl_Position = u_ViewProj * vec4(noisyModelPosition, 1.0);
    
    fs_Pos = vs_Pos;

    // Calculate new normals!
    // Get tangent and bitangent vectors
    vec3 tangent = cross(vec3(0.0, 1.0, 0.0), fs_Nor.xyz);
    vec3 bitangent = cross(fs_Nor.xyz, tangent);

    // Get offset amount for epsilon distance away
    float e = 0.00001;
    vec3 noiseInput_e = noisyModelPosition.xyz + vec3(e) * terrainFreq;
    float elevation_e = getElevation(noiseInput_e);
    vec3 offsetAmount_e = vec3(vs_Nor) * elevation_e;

    // Get neighbors 
    p1 =  fs_Pos.xyz + vec3(e) * tangent + offsetAmount_e;
    p2 =  fs_Pos.xyz + vec3(e) * bitangent + offsetAmount_e;
    p3 =  fs_Pos.xyz - vec3(e) * tangent + offsetAmount_e;
    p4 =  fs_Pos.xyz - vec3(e) * bitangent + offsetAmount_e;
}
