SHADER version 1
@OpenGL2.Vertex
uniform mat4 projectionmatrix;
uniform mat4 drawmatrix;
uniform vec2 offset;
uniform vec2 position[4];
uniform vec2 texcoords[4];
uniform vec2 texturescale;
uniform float alphamapscale;
uniform float terrainresolution;
uniform vec3 terrainscale;
uniform vec2 layerscale;

attribute vec3 vertex_position;
attribute vec2 vertex_texcoords0;
attribute vec2 vertex_texcoords1;

varying vec2 ex_texcoords0;
varying vec2 ex_texcoords1;
varying vec2 ex_texcoords2;

uniform vec2 alphacoordoffset;
uniform vec2 texcoordoffset;

void main(void)
{
	vec4 position = projectionmatrix * (vec4(vertex_position,1.0) + vec4(offset,0,0));	
	gl_Position = position;
	ex_texcoords1 = ((vertex_texcoords1-0.5) * alphamapscale + 0.5 + alphacoordoffset);
	ex_texcoords0 = vertex_texcoords0;


	//ex_texcoords0 = (((vertex_texcoords1-0.5) * alphamapscale + 0.5 + alphacoordoffset)) * terrainscale.x * terrainresolution / layerscale;

	/*
	int i = int(vertex_position.x);//gl_VertexID was implemented in GLSL 1.30, not available in 1.20.
	//ex_texcoords2 = texcoords[i];
	ex_texcoords1 = texcoords[i] * alphamapscale;
	ex_texcoords1 = ((texcoords[i]-0.5) * alphamapscale + 0.5 + alphacoordoffset);
	gl_Position = projectionmatrix * (drawmatrix * vec4(position[i], 1.0, 1.0));
	//ex_texcoords0 = texcoords[i] * texturescale;
	ex_texcoords0 = (((texcoords[i]-0.5) * alphamapscale + 0.5 + alphacoordoffset)) * terrainscale.x * terrainresolution;
	*/
}
@OpenGL2.Fragment
#define TERRAIN_LOW_FREQUENCY_BLEND 8.0

//Uniforms
uniform sampler2D texture0;// heightmap
uniform sampler2D texture1;// normalmap
uniform sampler2D texture2;// layer alpha
uniform sampler2D texture3;// previous layer diffuse
uniform sampler2D texture4;// previous layer normal + displacement
uniform sampler2D texture5;// diffuse
uniform sampler2D texture6;// normal
uniform sampler2D texture7;// displacement
uniform vec2 buffersize;
uniform vec4 drawcolor;
uniform vec2 alphacoordoffset;
uniform vec4 layermask;
uniform vec2 layerscale;
uniform int isfirstlayer;
uniform vec3 layerslopeconstraints;
uniform vec3 layerheightconstraints;
uniform vec3 terrainscale;
uniform vec2 texcoordoffset;
uniform float terrainresolution;
uniform int blendwithprevious;
uniform int displacementblend;
uniform float clipmaplevel;

//Varyings
varying vec2 ex_texcoords0;
varying vec2 ex_texcoords1;
varying vec2 ex_texcoords2;

void main(void)
{
	vec4 outcolor = vec4(1.0);	
	vec4 outcolor1 = vec4(0.5,0.5,1.0,0.0);
	float displacement=1.0;
	
	vec4 alpha4 = texture2D(texture2,ex_texcoords1) * layermask;
	float alpha = alpha4[0]+alpha4[1]+alpha4[2]+alpha4[3];
	float height = texture2D(texture0,ex_texcoords1).r;// * terrainscale.y;
	vec4 normalcolor = texture2D(texture1,ex_texcoords1);
	vec3 normal = normalcolor.xyz * 2.0 - 1.0;
	float slope = normalcolor.a * 90.0;//90.0 - asin(normal.z) * 57.2957795;	
	//vec3 normal = texture2D(texture1,ex_texcoords1).xyz * 2.0 - 1.0;
	//float slope = 90.0 - asin(normal.z) * 57.2957795;
	vec4 ic;
	
	vec2 mix;
	float sum = abs(normal.x) + abs(normal.z);
	mix.y = abs(normal.x) / sum;
	mix.x = abs(normal.z) / sum;	
	
	vec2 texcoordsxy;
	texcoordsxy.x = ex_texcoords0.x;
	texcoordsxy.y = height * terrainscale.y;
	
	vec2 texcoordszy;
	texcoordszy.x = ex_texcoords0.y;
	texcoordszy.y = height * terrainscale.y;
	
	//Adjust alpha based on constraints
	if (isfirstlayer==0)
	{
		alpha *= (1.0 - clamp(layerslopeconstraints.x - slope, 0.0, layerslopeconstraints.z) / layerslopeconstraints.z);
		alpha *= (1.0 - clamp(slope - layerslopeconstraints.y, 0.0, layerslopeconstraints.z) / layerslopeconstraints.z);
		alpha *= 1.0 - clamp(layerheightconstraints.x-height,0.0,layerheightconstraints.z)/layerheightconstraints.z;
		alpha *= 1.0 - clamp(height-layerheightconstraints.y,0.0,layerheightconstraints.z)/layerheightconstraints.z;
	}
	else
	{
		alpha=1.0;
	}
	
	float layerblendcutoff = 0.9;
	
#ifdef TERRAIN_LOW_FREQUENCY_BLEND
	float lowfrequencymix = clamp(clipmaplevel/7.0,0.0,1.0)*0.75+0.25;
	//const float lowfrequencymix = 0.5;
#endif

	// Normal
#ifdef TERRAIN_LOW_FREQUENCY_BLEND
	outcolor1 = texture2D(texture6,ex_texcoords0)*lowfrequencymix + texture2D(texture6,ex_texcoords0/TERRAIN_LOW_FREQUENCY_BLEND)*(1.0-lowfrequencymix);
#else
	outcolor1 = texture2D(texture6,ex_texcoords0);
#endif
	float normalalpha = alpha;
	
	//Displacement
	if (displacementblend!=0)
	{
#ifdef TERRAIN_LOW_FREQUENCY_BLEND
		displacement = texture2D(texture7,ex_texcoords0).r*lowfrequencymix + texture2D(texture7,ex_texcoords0/TERRAIN_LOW_FREQUENCY_BLEND).r*(1.0-lowfrequencymix);
#else
		displacement = texture2D(texture7,ex_texcoords0).r;
#endif
		alpha += displacement * alpha;
		if (alpha<1.0) alpha *= max(0.0,alpha-layerblendcutoff) / (1.0-layerblendcutoff);
		alpha = clamp(alpha,0.0,1.0);
	}
	
	// Diffuse
#ifdef TERRAIN_LOW_FREQUENCY_BLEND
	outcolor = texture2D(texture5,ex_texcoords0)*lowfrequencymix + texture2D(texture5,ex_texcoords0/TERRAIN_LOW_FREQUENCY_BLEND)*(1.0-lowfrequencymix);
#else
	outcolor = texture2D(texture5,ex_texcoords0);
#endif
	
	gl_FragData[0] = vec4(outcolor.rgb,alpha);
	gl_FragData[1] = vec4(outcolor1.rgb,alpha);
	
	//gl_FragData[0] = vec4(normalcolor.a);

	/*if (blendwithprevious==0)
	{
		//gl_FragData[0]=vec4(1.0,0.0,0.0,1.0);
		gl_FragData[0] = vec4(outcolor.rgb,alpha);
		gl_FragData[1] = vec4(normalize(outcolor1.rgb),normalalpha);

	}
	else
	{
		//gl_FragData[0]=vec4(0.0,1.0,0.0,1.0);
		gl_FragData[0] = outcolor * alpha + texture2D(texture3,ex_texcoords2) * (1.0-alpha);
		gl_FragData[1] = vec4(normalize(outcolor1.rgb),displacement) * normalalpha + texture2D(texture4,ex_texcoords2) * (1.0-normalalpha);
if (layermask[2]>0.5)
{
	gl_FragData[0] = texture2D(texture3,ex_texcoords2);
}
	}*/
}
@OpenGLES2.Vertex
precision highp float;

//Uniforms
uniform mat4 projectionmatrix;
uniform mat4 drawmatrix;
uniform vec2 offset;
uniform vec2 position[4];
uniform vec2 texcoords[4];
uniform vec2 texturescale;
uniform float alphamapscale;
uniform vec2 alphacoordoffset;
uniform vec2 texcoordoffset;
uniform float terrainresolution;
uniform vec3 terrainscale;

//Attributes
attribute vec4 vertex_position;
attribute vec2 vertex_texcoords0;
attribute vec2 vertex_texcoords1;

//Varyings
varying vec2 ex_texcoords0;
varying vec2 ex_texcoords1;
varying vec2 ex_texcoords2;

void main(void)
{
	//vec4 position = projectionmatrix * (drawmatrix * vertex_position + vec4(offset,0,0));
	vec4 position = projectionmatrix * (vertex_position + vec4(offset,0,0));
	
	gl_Position = position;
	//ex_texcoords1 = ((vertex_texcoords0-0.5) * alphamapscale + 0.5 + alphacoordoffset);
	ex_texcoords1 = ((vertex_texcoords1-0.5) * alphamapscale + 0.5 + alphacoordoffset);
	
	//iOS will produce bright texture lookups past certain texcoord range:
	//https://devforums.apple.com/message/874797#874797
	//ex_texcoords0 = ((vertex_texcoords0-0.5) * alphamapscale + 0.5 + alphacoordoffset) * terrainscale.x * terrainresolution;
	ex_texcoords0 = vertex_texcoords0;
}
@OpenGLES2.Fragment
precision highp float;

#define TERRAIN_LOW_FREQUENCY_BLEND 8.0

//Uniforms
uniform sampler2D texture0;// heightmap
uniform sampler2D texture1;// normalmap
uniform sampler2D texture2;// layer alpha
uniform sampler2D texture3;// previous layer diffuse
uniform sampler2D texture4;// previous layer normal + displacement
uniform sampler2D texture5;// diffuse
//uniform sampler2D texture6;// normal
//uniform sampler2D texture7;// displacement
uniform vec2 buffersize;
uniform vec4 drawcolor;
uniform vec2 alphacoordoffset;
uniform vec4 layermask;
uniform vec2 layerscale;
uniform int isfirstlayer;
uniform vec3 layerslopeconstraints;
uniform vec3 layerheightconstraints;
uniform vec3 terrainscale;
uniform vec2 texcoordoffset;
uniform float terrainresolution;
uniform int blendwithprevious;
uniform int displacementblend;
uniform float clipmaplevel;

//Varyings
varying vec2 ex_texcoords0;
varying vec2 ex_texcoords1;
//varying vec2 ex_texcoords2;

highp vec4 texture2DBilinear( sampler2D textureSampler, vec2 uv, float textureSize )
{
	highp float texelSize = 1.0 / textureSize;
	// in vertex shaders you should use texture2DLod instead of texture2D
	highp vec4 tl = texture2D(textureSampler, uv);
	highp vec4 tr = texture2D(textureSampler, uv + vec2(texelSize, 0));
	highp vec4 bl = texture2D(textureSampler, uv + vec2(0, texelSize));
	highp vec4 br = texture2D(textureSampler, uv + vec2(texelSize , texelSize));
	highp vec2 f = fract( uv.xy * textureSize ); // get the decimal part
	highp vec4 tA = mix( tl, tr, f.x ); // will interpolate the red dot in the image
	highp vec4 tB = mix( bl, br, f.x ); // will interpolate the blue dot in the image
	return mix( tA, tB, f.y ); // will interpolate the green dot in the image
}

void main(void)
{
	vec4 outcolor = vec4(1.0);	
	vec4 outcolor1 = vec4(0.5,0.5,1.0,0.0);
	float displacement=1.0;
	
#ifdef TERRAIN_LOW_FREQUENCY_BLEND
	float lowfrequencymix = clamp(clipmaplevel/7.0,0.0,1.0)*0.75+0.25;
	//const float lowfrequencymix = 0.5;
#endif
	
	vec4 alpha4 = texture2D(texture2,ex_texcoords1) * layermask;
	float alpha = alpha4[0]+alpha4[1]+alpha4[2]+alpha4[3];
	float height;// = texture2D(texture0,ex_texcoords1).r;// * terrainscale.y;

	//Implement our own bilinear filtering.  iOS won't filter finer than unsigned char resolution, apparently:
	height = texture2DBilinear(texture0,ex_texcoords1,terrainresolution).r;

	vec4 normalcolor = texture2D(texture1,ex_texcoords1);
	vec3 normal = normalcolor.xyz * 2.0 - 1.0;
	float slope = normalcolor.a * 90.0;//90.0 - asin(normal.z) * 57.2957795;
	
	//Adjust alpha based on constraints
	if (isfirstlayer==0)
	{
		alpha *= (1.0 - clamp(layerslopeconstraints.x - slope, 0.0, layerslopeconstraints.z) / layerslopeconstraints.z);
		alpha *= (1.0 - clamp(slope - layerslopeconstraints.y, 0.0, layerslopeconstraints.z) / layerslopeconstraints.z);
		alpha *= 1.0 - clamp(layerheightconstraints.x-height,0.0,layerheightconstraints.z)/layerheightconstraints.z;
		alpha *= 1.0 - clamp(height-layerheightconstraints.y,0.0,layerheightconstraints.z)/layerheightconstraints.z;
	}
	else
	{
		alpha=1.0;
	}
	
	// Diffuse
#ifdef TERRAIN_LOW_FREQUENCY_BLEND	
	outcolor = texture2D(texture5,ex_texcoords0) * lowfrequencymix + texture2D(texture5,ex_texcoords0/TERRAIN_LOW_FREQUENCY_BLEND) * (1.0-lowfrequencymix);
#else
	outcolor = texture2D(texture5,ex_texcoords0) * mix + (1.0-mix);
#endif	
	gl_FragData[0] = vec4(outcolor.rgb,alpha);
	//gl_FragData[0] = vec4(texture2D(texture0,ex_texcoords1).xyz,1.0);
}
@OpenGL4.Vertex
#version 400

uniform mat4 projectionmatrix;
uniform mat4 drawmatrix;
uniform vec2 offset;
uniform vec2 position[4];
uniform vec2 texcoords[4];
uniform vec2 texturescale;
uniform float alphamapscale;
uniform float terrainresolution;
uniform vec3 terrainscale;
uniform vec2 layerscale;
uniform vec2 alphacoordoffset;
uniform vec2 texcoordoffset;

in vec3 vertex_position;
in vec2 vertex_texcoords0;
in vec2 vertex_texcoords1;

out vec2 ex_texcoords0;
out vec2 ex_texcoords1;
out vec2 ex_texcoords2;

void main(void)
{
	vec4 position = projectionmatrix * (vec4(vertex_position,1.0) + vec4(offset,0,0));	
	gl_Position = position;
	ex_texcoords1 = ((vertex_texcoords1-0.5) * alphamapscale + 0.5 + alphacoordoffset);
	ex_texcoords0 = vertex_texcoords0;


	//ex_texcoords0 = (((vertex_texcoords1-0.5) * alphamapscale + 0.5 + alphacoordoffset)) * terrainscale.x * terrainresolution / layerscale;

	/*
	int i = int(vertex_position.x);//gl_VertexID was implemented in GLSL 1.30, not available in 1.20.
	//ex_texcoords2 = texcoords[i];
	ex_texcoords1 = texcoords[i] * alphamapscale;
	ex_texcoords1 = ((texcoords[i]-0.5) * alphamapscale + 0.5 + alphacoordoffset);
	gl_Position = projectionmatrix * (drawmatrix * vec4(position[i], 1.0, 1.0));
	//ex_texcoords0 = texcoords[i] * texturescale;
	ex_texcoords0 = (((texcoords[i]-0.5) * alphamapscale + 0.5 + alphacoordoffset)) * terrainscale.x * terrainresolution;
	*/
}
@OpenGL4.Fragment
#version 400
#define TERRAIN_LOW_FREQUENCY_BLEND 8.0

//Uniforms
uniform sampler2D texture0;// heightmap
uniform sampler2D texture1;// normalmap
uniform sampler2D texture2;// layer alpha
uniform sampler2D texture3;// previous layer diffuse
uniform sampler2D texture4;// previous layer normal + displacement
uniform sampler2D texture5;// diffuse
uniform sampler2D texture6;// normal
uniform sampler2D texture7;// displacement
uniform vec2 buffersize;
uniform vec4 drawcolor;
uniform vec2 alphacoordoffset;
uniform vec4 layermask;
uniform vec2 layerscale;
uniform int isfirstlayer;
uniform vec3 layerslopeconstraints;
uniform vec3 layerheightconstraints;
uniform vec3 terrainscale;
uniform vec2 texcoordoffset;
uniform float terrainresolution;
uniform int blendwithprevious;
uniform int displacementblend;
uniform float clipmaplevel;

//Varyings
in vec2 ex_texcoords0;
in vec2 ex_texcoords1;
in vec2 ex_texcoords2;

out vec4 fragData0;
out vec4 fragData1;

void main(void)
{
	vec4 outcolor = vec4(1.0);	
	vec4 outcolor1 = vec4(0.5,0.5,1.0,0.0);
	float displacement=1.0;
	
	vec4 alpha4 = texture(texture2,ex_texcoords1) * layermask;
	float alpha = alpha4[0]+alpha4[1]+alpha4[2]+alpha4[3];
	float height = texture(texture0,ex_texcoords1).r;// * terrainscale.y;
	vec4 normalcolor = texture(texture1,ex_texcoords1);
	vec3 normal = normalcolor.xyz * 2.0 - 1.0;
	float slope = normalcolor.a * 90.0;//90.0 - asin(normal.z) * 57.2957795;	
	//vec3 normal = texture(texture1,ex_texcoords1).xyz * 2.0 - 1.0;
	//float slope = 90.0 - asin(normal.z) * 57.2957795;
	vec4 ic;
	
	vec2 mix;
	float sum = abs(normal.x) + abs(normal.z);
	mix.y = abs(normal.x) / sum;
	mix.x = abs(normal.z) / sum;	
	
	vec2 texcoordsxy;
	texcoordsxy.x = ex_texcoords0.x;
	texcoordsxy.y = height * terrainscale.y;
	
	vec2 texcoordszy;
	texcoordszy.x = ex_texcoords0.y;
	texcoordszy.y = height * terrainscale.y;
	
	//Adjust alpha based on constraints
	if (isfirstlayer==0)
	{
		alpha *= (1.0 - clamp(layerslopeconstraints.x - slope, 0.0, layerslopeconstraints.z) / layerslopeconstraints.z);
		alpha *= (1.0 - clamp(slope - layerslopeconstraints.y, 0.0, layerslopeconstraints.z) / layerslopeconstraints.z);
		alpha *= 1.0 - clamp(layerheightconstraints.x-height,0.0,layerheightconstraints.z)/layerheightconstraints.z;
		alpha *= 1.0 - clamp(height-layerheightconstraints.y,0.0,layerheightconstraints.z)/layerheightconstraints.z;
	}
	else
	{
		alpha=1.0;
	}
	
	float layerblendcutoff = 0.9;
	
#ifdef TERRAIN_LOW_FREQUENCY_BLEND
	float lowfrequencymix = clamp(clipmaplevel/7.0,0.0,1.0)*0.75+0.25;
	//const float lowfrequencymix = 0.5;
#endif

	// Normal
#ifdef TERRAIN_LOW_FREQUENCY_BLEND
	outcolor1 = texture(texture6,ex_texcoords0)*lowfrequencymix + texture(texture6,ex_texcoords0/TERRAIN_LOW_FREQUENCY_BLEND)*(1.0-lowfrequencymix);
#else
	outcolor1 = texture(texture6,ex_texcoords0);
#endif
	float normalalpha = alpha;
	
	//Displacement
	if (displacementblend!=0)
	{
#ifdef TERRAIN_LOW_FREQUENCY_BLEND
		displacement = texture(texture7,ex_texcoords0).r*lowfrequencymix + texture(texture7,ex_texcoords0/TERRAIN_LOW_FREQUENCY_BLEND).r*(1.0-lowfrequencymix);
#else
		displacement = texture(texture7,ex_texcoords0).r;
#endif
		alpha += displacement * alpha;
		if (alpha<1.0) alpha *= max(0.0,alpha-layerblendcutoff) / (1.0-layerblendcutoff);
		alpha = clamp(alpha,0.0,1.0);
	}
	
	// Diffuse
#ifdef TERRAIN_LOW_FREQUENCY_BLEND
	outcolor = texture(texture5,ex_texcoords0)*lowfrequencymix + texture(texture5,ex_texcoords0/TERRAIN_LOW_FREQUENCY_BLEND)*(1.0-lowfrequencymix);
#else
	outcolor = texture(texture5,ex_texcoords0);
#endif
	
	fragData0 = vec4(outcolor.rgb,alpha);
	fragData1 = vec4(outcolor1.rgb,alpha);
	
	//gl_FragData[0] = vec4(normalcolor.a);

	/*if (blendwithprevious==0)
	{
		//gl_FragData[0]=vec4(1.0,0.0,0.0,1.0);
		gl_FragData[0] = vec4(outcolor.rgb,alpha);
		gl_FragData[1] = vec4(normalize(outcolor1.rgb),normalalpha);

	}
	else
	{
		//gl_FragData[0]=vec4(0.0,1.0,0.0,1.0);
		gl_FragData[0] = outcolor * alpha + texture(texture3,ex_texcoords2) * (1.0-alpha);
		gl_FragData[1] = vec4(normalize(outcolor1.rgb),displacement) * normalalpha + texture(texture4,ex_texcoords2) * (1.0-normalalpha);
if (layermask[2]>0.5)
{
	gl_FragData[0] = texture(texture3,ex_texcoords2);
}
	}*/
}
