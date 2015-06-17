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
//This shader should not be attached directly to a camera. Instead, use the bloom script effect.
#version 400

uniform sampler2D texture0;
uniform sampler2D texture1;
uniform bool isbackbuffer;
uniform vec2 buffersize;
uniform float currenttime;

out vec4 fragData0;

float Gaussian (float x, float deviation)
{
	return (1.0 / sqrt(2.0 * 3.141592 * deviation)) * exp(-((x * x) / (2.0 * deviation)));  
}

void main(void)
{
	vec2 icoord = vec2(gl_FragCoord.xy/buffersize);
	if (isbackbuffer) icoord.y = 1.0 - icoord.y;

	vec2 orientation=vec2(1,0);
	float BlurStrength=0.2;
	float halfBlur = 12.0 * 0.5;
	vec4 colour = vec4(0.0);
	vec4 texColour = vec4(0.0);
	
	fragData0 = vec4(0);
	fragData0 += texture2D(texture0, icoord+ vec2(-0.028/2.0, 0.0))*0.0044299121055113265;
	fragData0 += texture2D(texture0, icoord+ vec2(-0.024/2.0, 0.0))*0.00895781211794;
	fragData0 += texture2D(texture0, icoord+ vec2(-0.020/2.0, 0.0))*0.0215963866053;
	fragData0 += texture2D(texture0, icoord+ vec2(-0.016/2.0, 0.0))*0.0443683338718;
	fragData0 += texture2D(texture0, icoord+ vec2(-0.012/2.0, 0.0))*0.0776744219933;
	fragData0 += texture2D(texture0, icoord+ vec2(-0.008/2.0, 0.0))*0.115876621105;
	fragData0 += texture2D(texture0, icoord+ vec2(-0.004/2.0, 0.0))*0.147308056121;
	fragData0 += texture2D(texture0, icoord)*0.159576912161;
	fragData0 += texture2D(texture0, icoord+ vec2( 0.004/2.0, 0.0))*0.147308056121;
	fragData0 += texture2D(texture0, icoord+ vec2( 0.008/2.0, 0.0))*0.115876621105;
	fragData0 += texture2D(texture0, icoord+ vec2( 0.012/2.0, 0.0))*0.0776744219933;
	fragData0 += texture2D(texture0, icoord+ vec2( 0.016/2.0, 0.0))*0.0443683338718;
	fragData0 += texture2D(texture0, icoord+ vec2( 0.020/2.0, 0.0))*0.0215963866053;
	fragData0 += texture2D(texture0, icoord+ vec2( 0.024/2.0, 0.0))*0.00895781211794;
	fragData0 += texture2D(texture0, icoord+ vec2( 0.028/2.0, 0.0))*0.0044299121055113265;
	//fragData0 = colour;
	//fragData0 /= (0.0776744219933+0.115876621105+0.147308056121)*2.0+0.159576912161;
}
