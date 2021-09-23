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

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Pos;

const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.

/**
 * Linearly Re-maps a value from one range to another
 */
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
float hash(float x)
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
	float h_i = hash(cell.x);
	float h_j = hash(cell.y + pow(h_i, 3.0));
	float h_k = hash(cell.z + pow(h_j, 5.0));
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

float noise(in vec3 coord)
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

void main()
{
    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation
    fs_Pos = vs_Pos;

    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. This is necessary to ensure the normals remain
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.
                                                            
    vec4 p = vs_Pos;

    float crater_freq = 1.7;
    float crater_density = 3.5;
    float crater_noise = 1.0;
    float mountain_noise = 1.f;

    // apply to one section of planet
    crater_noise = clamp(cos(crater_freq * noise(p.xyz * crater_density + (0.0006 * u_Time))), 0.9, 1.0);
    /* if (p.x <= 1.0 && p.x >= 0.0 && p.y <= 1.0 && p.y >= 0.0) {
        crater_noise = clamp(cos(crater_freq * noise(p.xyz * crater_density + (0.0006 * u_Time))), 0.9, 1.0);
    } */
    //crater_noise = clamp(p.x, 0.f, 1.f);
    //p.z = noise_val * fs_Nor.z * clamp(cos(0.01* u_Time), 0.5, 1.f);

    p.x = mountain_noise * crater_noise * fs_Nor.x;
    p.y = mountain_noise * crater_noise * fs_Nor.y;
    p.z = mountain_noise * crater_noise * fs_Nor.z;

    fs_Pos += p;

    vec4 modelposition = u_Model * p;   // Temporarily store the transformed vertex positions for use below

    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies

    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices
}
