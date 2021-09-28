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
in float fs_elevation;
out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

float rand(float co) { return fract(sin(co*(91.3458)) * 47453.5453); }


vec4 mod289(vec4 x){
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}
vec4 perm(vec4 x){
    return mod289(((x * 34.0) + 1.0) * x);
}

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
	vec3 shift = vec3(100.0);
	for (int i = 0; i < 20; ++i) {
		v += a * noise(x);
		x = x * 2.0 + shift;
		a *= 0.5;
	}
	return v;
}



void main()
{
    // Material base color (before shading)
         // Compute final shaded color
        vec4 col;
        // creating some building like stuff
        if(fs_elevation>0.9){                
            col = vec4(0.0039, 0.7686, 1.0, 1.0);   
        }
        else if(fs_elevation>0.80){                
            col = vec4(1.0, 0.0, 0.0, 1.0);   
        }
        else if(fs_elevation>0.75){                 
            col = vec4(0.9333, 1.0, 0.0, 1.0);   
        }
        else if(fs_elevation>0.4){                 
            col = vec4(0.1725, 1.0, 1.0, 1.0);   
        }
        else if (fs_elevation> 0.3){
            col = vec4(0.0078, 1.0, 0.4235, 1.0);    
        }
        else if (fs_elevation > 0.0){
            col = vec4(0.9451, 0.9333, 0.7176, 1.0);    
        }
        else if (fs_elevation > -1.0){
            col = vec4(0.0, 0.1843, 1.0, 1.0);    
        }
        else if (fs_elevation == -1.0)
            col = vec4(0.0, 0.0, 0.0, 1.0);    
        }
        vec4 diffuseColor = col;

        // Calculate the diffuse term for Lambert shading
        float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
        // Avoid negative lighting values
        diffuseTerm = clamp(diffuseTerm, 0.0, 1.0);

        float ambientTerm = 0.8;

        float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                            //to simulate ambient lighting. This ensures that faces that are not
                                                            //lit by our point light are not completely black.


        out_Col = vec4(diffuseColor.rgb* lightIntensity, diffuseColor.a);
}
