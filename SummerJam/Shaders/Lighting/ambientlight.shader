SHADER version 1
@OpenGL2.Vertex

@OpenGLES2.Vertex

@OpenGLES2.Fragment

@OpenGL4.Vertex
#version 400

//APPENDED_DATA

uniform mat4 projectionmatrix;
uniform mat4 drawmatrix;
uniform vec2 offset;
uniform vec2 position[4];
uniform vec2 texcoords[4];

in vec3 vertex_position;
in vec2 vertex_texcoords0;

void main(void)
{
	gl_Position = projectionmatrix * (drawmatrix * vec4(position[gl_VertexID], 0.0, 1.0));
}
@OpenGL4.Fragment
#version 400
#ifndef SAMPLES
	#define SAMPLES 1
#endif

uniform sampler2DMS texture0;
uniform sampler2DMS texture1;
uniform sampler2DMS texture2;
uniform sampler2DMS texture3;
uniform sampler2DMS texture4;
uniform vec4 ambientlight;
uniform vec2 buffersize;
uniform vec2 camerarange;
uniform bool isbackbuffer;

in vec2 vTexCoord;

out vec4 fragData0;

float DepthToZPosition(in float depth)
{
	return camerarange.x / (camerarange.y - depth * (camerarange.y - camerarange.x)) * camerarange.y;
}

void main(void)
{
	//----------------------------------------------------------------------
	//Calculate screen texcoord
	//----------------------------------------------------------------------
	vec2 coord = gl_FragCoord.xy / buffersize;	
	if (isbackbuffer) coord.y = 1.0 - coord.y;
	
	ivec2 icoord = ivec2(gl_FragCoord.xy);
	if (isbackbuffer) icoord.y = int(buffersize.y) - icoord.y;
	
	vec4 diffuse = vec4(0.0);
	vec4 emission = vec4(0.0);
	
	float ao = 1.0;
	
	fragData0 = vec4(0.0);
	
	for (int i=0; i<SAMPLES; i++)
	{
		vec4 samplediffuse = texelFetch(texture1,icoord,i);
		emission = texelFetch(texture3,icoord,i);
		vec4 materialdata = texelFetch(texture3,icoord,i);
		ao=max(0.25,materialdata[1]);
		int materialflags = int(emission.a * 255.0 + 0.5);
		bool uselighting = false;
		if ((1 & materialflags)!=0) samplediffuse *= ambientlight;
		if ((2 & materialflags)!=0)
		{
			samplediffuse = (samplediffuse + vec4(1.0,0.0,0.0,0.0))/2.0;
		}
		fragData0 += samplediffuse + emission;
	}
	
	//----------------------------------------------------------------------
	//Calculate lighting
	//----------------------------------------------------------------------	
	fragData0 /= float(SAMPLES);
	gl_FragDepth = texelFetch(texture0,icoord,0).r;
}
