SHADER version 1
@OpenGL2.Vertex

@OpenGLES2.Vertex

@OpenGLES2.Fragment

@OpenGL4.Vertex
#version 400

uniform mat4 projectioncameramatrix;
uniform mat4 drawmatrix;
uniform vec2 offset;
uniform vec2 position[4];
uniform vec3 lightglobalposition;
uniform vec2 lightrange;

in vec3 vertex_position;

void main(void)
{
	gl_Position = projectioncameramatrix * vec4(lightglobalposition + vertex_position * lightrange.y * 2.0,1.0);
}
@OpenGL4.Fragment
#version 400
#ifndef SAMPLES
	#define SAMPLES 1
#endif
#define LOWERLIGHTTHRESHHOLD 0.001
#define PI 3.14159265359
#define HALFPI PI/2.0
#ifndef KERNEL
	#define KERNEL 3
#endif
#define KERNELF float(KERNEL)
#define GLOSS 10.0

uniform sampler2DMS texture0;
uniform sampler2DMS texture1;
uniform sampler2DMS texture2;
uniform sampler2DMS texture3;
uniform sampler2DMS texture4;
uniform samplerCubeShadow texture5;//shadowmap
uniform vec4 ambientlight;
uniform vec2 buffersize;
uniform vec3 lightposition;
uniform vec4 lightcolor;
uniform vec4 lightspecular;
uniform vec2 lightrange;
uniform vec3 lightglobalposition;
uniform vec2 camerarange;
uniform float camerazoom;
uniform mat4 lightprojectionmatrix;
uniform mat4 lightprojectioninversematrix;
uniform mat4 projectioncameramatrix;
uniform mat4 cameramatrix;
uniform mat4 camerainversematrix;
uniform mat4 projectionmatrix;
uniform vec2 lightshadowmapoffset;
uniform mat3 lightnormalmatrix;
uniform float shadowmapsize;
uniform bool isbackbuffer;

out vec4 fragData0;

float shadowLookup(in samplerCubeShadow shadowmap, in vec4 shadowcoord, in vec3 sampleroffsetx, in vec3 sampleroffsety)
{
	float f=0.0;
	const float cornerdamping = 0.7071067;
	vec3 shadowcoord3 = shadowcoord.xyz;
	int x,y;
	vec2 sampleoffset;

	for (x=0; x<KERNEL; ++x)
	{
		sampleoffset.x = float(x) - KERNELF*0.5 + 0.5;
		for (y=0; y<KERNEL; ++y)
		{
			sampleoffset.y = float(y) - KERNELF*0.5 + 0.5;
			f += texture(shadowmap,vec4(shadowcoord3+sampleoffset.x*sampleroffsetx+sampleoffset.y*sampleroffsety,shadowcoord.w));
		}
	}
	return f/(KERNEL*KERNEL);
}

float depthToPosition(in float depth, in vec2 depthrange)
{
	return depthrange.x / (depthrange.y - depth * (depthrange.y - depthrange.x)) * depthrange.y;
}

float positionToDepth(in float z, in vec2 depthrange) {
	return (depthrange.x / (z / depthrange.y) - depthrange.y) / -(depthrange.y - depthrange.x);
}

int getMajorAxis(in vec3 v)
{
	vec3 b = abs(v);
	if (b.x>b.y)
	{
		if (b.x>b.z)
		{
			return 0;
		}
		else
		{
			return 2;
		}
	}
	else
	{
		if (b.y>b.z)
		{
			return 1;
		}
		else
		{
			return 2;
		}
	}
}

void main(void)
{
	vec3 flipcoord = vec3(1.0);
	if (!isbackbuffer) flipcoord.y = -1.0;
	
	//----------------------------------------------------------------------
	//Calculate screen texcoord
	//----------------------------------------------------------------------
	vec2 coord = gl_FragCoord.xy / buffersize;
	if (isbackbuffer) coord.y = 1.0 - coord.y;
	
	ivec2 icoord = ivec2(gl_FragCoord.xy);
	if (isbackbuffer) icoord.y = int(buffersize.y) - icoord.y;
	
	fragData0 = vec4(0.0);
	
	bool uselighting = false;

	for (int i=0; i<SAMPLES; i++)
	{
		//----------------------------------------------------------------------
		//Retrieve data from gbuffer
		//----------------------------------------------------------------------
		float depth = 		texelFetch(texture0,icoord,i).x;
		vec4 diffuse = 		texelFetch(texture1,icoord,i);
		vec4 normaldata =	texelFetch(texture2,icoord,i);
		vec3 normal = 		normalize(normaldata.xyz*2.0-1.0);
		float specularity =	normaldata.a;
		vec4 emission = 	texelFetch(texture3,icoord,i);
		int materialflags = 	int(emission.a*255.0+0.5);
		if ((1 & materialflags)!=0) uselighting=true;
		
		//----------------------------------------------------------------------
		//Discard pixel if no lighting is used
		//----------------------------------------------------------------------	
#if SAMPLES==1
		if (!uselighting) discard;
#endif		
		//----------------------------------------------------------------------
		//Calculate screen position and vector
		//----------------------------------------------------------------------
		vec3 screencoord = vec3(((gl_FragCoord.x/buffersize.x)-0.5) * 2.0 * (buffersize.x/buffersize.y),((-gl_FragCoord.y/buffersize.y)+0.5) * 2.0,depthToPosition(depth,camerarange));
		screencoord.x *= screencoord.z / camerazoom;
		screencoord.y *= -screencoord.z / camerazoom;
		vec3 screennormal = normalize(screencoord);
		
		//----------------------------------------------------------------------
		//Calculate lighting
		//----------------------------------------------------------------------
		float attenuation=1.0;
		vec4 specular;
		vec3 lightvector = (screencoord - lightposition * flipcoord) * flipcoord;
		vec3 lightnormal = normalize(lightvector);	
		
		//Directional attenuation
		attenuation = max(0.0,-dot(lightnormal,normal));
		
		//Distance attenuation
		attenuation *= min(1.0,1.0-length(lightvector)/lightrange.y);
		
#if SAMPLES==1
		if (attenuation<LOWERLIGHTTHRESHHOLD) discard;
#endif		
		if (!isbackbuffer) normal.y *= -1.0;
		vec3 lightreflection = normalize(reflect(lightvector*flipcoord,normal));
		specular = lightspecular * specularity * pow(clamp(-dot(lightreflection,screennormal),0.0,1.0),GLOSS); 
		specular *= lightcolor.r * 0.299 + lightcolor.g * 0.587 + lightcolor.b * 0.114;
		
		//----------------------------------------------------------------------
		//Shadow lookup
		//----------------------------------------------------------------------
#ifdef USESHADOW
		vec4 shadowcoord = vec4(lightnormalmatrix*lightvector,1.0);
		
		vec3 sampleroffsetx,sampleroffsety;
		switch (getMajorAxis(shadowcoord.xyz))
		{
		case 0:
			shadowcoord.w = abs(shadowcoord.x);
			sampleroffsetx = vec3(0.0,0.0,shadowcoord.x*2.0/shadowmapsize);
			sampleroffsety = vec3(0.0,shadowcoord.x*2.0/shadowmapsize,0.0);
			break;
		case 1:
			shadowcoord.w = abs(shadowcoord.y);
			sampleroffsetx = vec3(shadowcoord.y*2.0/shadowmapsize,0.0,0.0);
			sampleroffsety = vec3(0.0,0.0,shadowcoord.y*2.0/shadowmapsize);
			break;
		default:
			shadowcoord.w = abs(shadowcoord.z);
			sampleroffsetx = vec3(shadowcoord.z*2.0/shadowmapsize,0.0,0.0);
			sampleroffsety = vec3(0.0,shadowcoord.z*2.0/shadowmapsize,0.0);
			break;
		}
		shadowcoord.w = positionToDepth(shadowcoord.w * lightshadowmapoffset.y*0.98 - lightshadowmapoffset.x,lightrange);
		attenuation *= shadowLookup(texture5,shadowcoord,sampleroffsetx,sampleroffsety);	
#endif
#if SAMPLES==1
		if (attenuation<LOWERLIGHTTHRESHHOLD) discard;
#endif		
		//----------------------------------------------------------------------
		//Final light calculation
		//----------------------------------------------------------------------
		fragData0 += (diffuse * lightcolor + specular) * attenuation;
	}
	if (!uselighting) discard;

	fragData0 /= SAMPLES;
	//fragData0=vec4(1.0,0.0,0.0,1.0);
}
