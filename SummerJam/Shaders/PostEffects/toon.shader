SHADER version 1
@OpenGL2.Vertex
uniform mat4 projectionmatrix;
uniform mat4 drawmatrix;
uniform vec2 offset;
uniform vec2 position[4];
uniform vec2 texcoords[4];

attribute vec3 vertex_position;

varying vec2 ex_texcoords0;

void main(void)
{
	int i = int(vertex_position.x);//gl_VertexID was implemented in GLSL 1.30, not available in 1.20.
	gl_Position = projectionmatrix * (drawmatrix * vec4(position[i], 1.0, 1.0));
	ex_texcoords0 = texcoords[i];
}
@OpenGL2.Fragment
uniform sampler2D texture0;
uniform vec2 buffersize;
uniform vec4 drawcolor;

varying vec2 ex_texcoords0;

void main(void)
{
	gl_FragColor = texture2D(texture0,ex_texcoords0) * drawcolor;
}
@OpenGLES2.Vertex
uniform mediump mat4 projectionmatrix;
uniform mediump mat4 drawmatrix;
uniform mediump vec2 offset;

attribute mediump vec3 vertex_position;
attribute mediump vec2 vertex_texcoords0;

varying mediump vec2 ex_texcoords0;

void main(void)
{
	gl_Position = projectionmatrix * (drawmatrix * vec4(vertex_position, 1.0) + vec4(offset,0,0));
	ex_texcoords0 = vertex_texcoords0;
}
@OpenGLES2.Fragment
uniform sampler2D texture0;
uniform mediump vec2 buffersize;
uniform mediump vec4 drawcolor;

varying mediump vec2 ex_texcoords0;

void main(void)
{
	gl_FragData[0] = texture2D(texture0,ex_texcoords0) * drawcolor;
}
@OpenGL4.Vertex
#version 400

uniform mat4 projectionmatrix;
uniform mat4 drawmatrix;
uniform vec2 offset;
uniform vec2 position[4];

in vec3 vertex_position;

void main(void)
{
	gl_Position = projectionmatrix * (drawmatrix * vec4(position[gl_VertexID]+offset, 0.0, 1.0));
}
@OpenGL4.Fragment
//--------------------------------------
// Cartoon shader by Shadmar
//--------------------------------------

#version 400

uniform sampler2D texture1;
uniform bool isbackbuffer;
uniform vec2 buffersize;

out vec4 fragData0;

//Could possiibly be uniforms to control the effect
const float EdgeWidth = 1.0;
const float EdgeIntensity = 1.0;

const float NormalThreshold = 0.01;
const float DepthThreshold = 0.1;

const float NormalSensitivity = 1.0;
const float DepthSensitivity = 1.0;


void main(void)
{
	vec2 tcoord = vec2(gl_FragCoord.xy/buffersize);
	if (isbackbuffer) tcoord.y = 1.0 - tcoord.y;

	vec2 edgeOffset = EdgeWidth / buffersize;
	vec4 n1 = texture(texture1, tcoord + vec2(-1, -1) * edgeOffset);
	vec4 n2 = texture(texture1, tcoord + vec2( 1,  1) * edgeOffset);
	vec4 n3 = texture(texture1, tcoord + vec2(-1,  1) * edgeOffset);
	vec4 n4 = texture(texture1, tcoord + vec2( 1, -1) * edgeOffset);
	
        //Get diffuse color
        vec4 scene = texture(texture1,tcoord);
        
	// Work out how much the normal and depth values are changing.
	vec4 diagonalDelta = abs(n1 - n2) + abs(n3 - n4);

	float normalDelta = dot(diagonalDelta.xyz, vec3(1.0));
	float depthDelta = diagonalDelta.w;
        
	// Filter out very small changes, in order to produce nice clean results.
	normalDelta = clamp((normalDelta - NormalThreshold) * NormalSensitivity,0.0,1.0);
	depthDelta = clamp((depthDelta - DepthThreshold) * DepthSensitivity,0.0,1.0);

	// Does this pixel lie on an edge?
	float edgeAmount = clamp(normalDelta + depthDelta,0.0,1.0) * EdgeIntensity;
        
	// Apply the edge detection result to the main scene color.
	scene *= (1.0 - edgeAmount);

	//Modulate steps in 0.1
	scene.rgb -= mod(scene.rgb,0.1);
    
	//Render
	fragData0 = vec4(scene.rgb,1.0);
}
