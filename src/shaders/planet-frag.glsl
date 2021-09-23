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

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

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

        float dist_to_center = length(fs_Pos);

        // Crater color
        float crater_border = 0.2;
        float crater_border_y = 0.1;
        vec4 grey = vec4(82.0 / 255.0, 73.0 / 255.0, 82.0 / 255.0, diffuseColor.a);
        vec4 crater_Col = vec4(grey.rgb * lightIntensity, diffuseColor.a);
        if (dist_to_center < 1.37) {
            crater_Col = vec4(27.0 / 255.0 , 27.0, 27.0, 0.0);
        }
        
        
        if (fs_Pos.x >= crater_border && fs_Pos.y >= crater_border) {
            out_Col = crater_Col;
        } else if (fs_Pos.x >= 0.0 && fs_Pos.x < crater_border && fs_Pos.y > 0.0){
            out_Col = mix(out_Col, crater_Col, fs_Pos.x / crater_border);
        } else if (fs_Pos.y >= 0.0 && fs_Pos.y < crater_border && fs_Pos.x > 0.0){
            out_Col = mix(out_Col, crater_Col, fs_Pos.y / crater_border);
        }
       
}
