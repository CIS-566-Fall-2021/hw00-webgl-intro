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

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Pos;

const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.

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


    // Creates elevated terrain
    vec3 noiseInput = modelposition.xyz * terrainFreq;
    float noise = fbm(noiseInput);

    float waterElevation = 0.9;
    float beachElevation = 0.93;
    float landElevation = 1.0;
    float mountElevation1 = 1.05;
    float mountElevation2 = 1.7;
    float mountElevation3 = 1.7;

    float waveNoise = noise2(5.0 * noise2((0.0006 * u_Time) + vec3(noiseInput) + noiseInput) + noiseInput);
    float elevation = mix(waterElevation, waterElevation + 0.03, waveNoise);
;

    // Creates beach level
    if (noise > 0.4 && noise < 0.52) {
        elevation = beachElevation;
    } else if (noise > 0.52 && noise < 0.53) {
        float x = GetBias((noise - 0.52) / 0.01, 0.3);
        elevation = mix(beachElevation, waterElevation, x);
    }

    // Creates land level
    if (noise > 0.48 && noise < 0.5) {
        float x = GetBias((noise - 0.48) / 0.02, 0.7);
        elevation = mix(landElevation, beachElevation, x);
    } else if (noise < 0.48) {
        elevation = landElevation;
    }

    // Creates mountain level
    float mountainNoise = fbm(10.0 * noiseInput + 20.0);
    if (noise > 0.37 && noise < 0.4) {
        float x = GetBias((noise - 0.37) / 0.03, 0.9);
        elevation =  mix(mountElevation1, landElevation, x);
    } else if (noise < 0.37) {
        float x = GetGain(noise / 0.37, mountainNoise);
        elevation =  mix(mountElevation2, mountElevation1, x);
    }

    vec3 offsetAmount = vec3(vs_Nor) * elevation;
    vec3 noisyModelPosition = modelposition.xyz + offsetAmount;
    gl_Position = u_ViewProj * vec4(noisyModelPosition, 1.0);
    
    fs_Pos = vs_Pos;

}
