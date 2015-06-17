SHADER version 1
@OpenGL2.Vertex
#define VIRTUAL_TEXTURE_STAGES 7

//Uniforms
uniform mat4 entitymatrix;
uniform vec4 materialcolordiffuse;
uniform mat4 projectioncameramatrix;
uniform mat4 camerainversematrix;
 
//Attributes
attribute vec3 vertex_position;
attribute vec4 vertex_color;
attribute vec3 vertex_normal;

//Outputs
varying vec4 ex_color;
varying float ex_selectionstate;
varying vec3 ex_VertexCameraPosition;
varying vec3 ex_normal;
varying vec2 ex_texcoords[VIRTUAL_TEXTURE_STAGES];
//varying vec2 ex_texcoords1;
//varying vec2 ex_texcoords2;
//varying vec2 ex_texcoords3;

uniform float terrainsize;
uniform float texturerange[VIRTUAL_TEXTURE_STAGES];
//uniform float terrainheight;

uniform vec2 renderposition[8];

uniform sampler2D texture0;

void main()
{
	mat4 entitymatrix_=entitymatrix;
	entitymatrix_[0][3]=0.0;
	entitymatrix_[1][3]=0.0;
	entitymatrix_[2][3]=0.0;
	entitymatrix_[3][3]=1.0;
	//entitymatrix_ * 
	//ex_texcoords0.x = 1.0 - ex_texcoords0.x;
	
	vec4 modelvertexposition = entitymatrix_ * (vec4(vertex_position,1.0));
	
	ex_texcoords[0] = (modelvertexposition.xz) / terrainsize + 0.5;
	for (int i=0; i<VIRTUAL_TEXTURE_STAGES; ++i)
	{
		ex_texcoords[i] = (modelvertexposition.xz - renderposition[i]) / texturerange[i] + 0.5;
	}

	/*ex_texcoords[1] = (modelvertexposition.xz - renderposition[1]) / texturerange[1] + 0.5;
	ex_texcoords[2] = (modelvertexposition.xz - renderposition[2]) / texturerange[2] + 0.5;
	ex_texcoords[3] = (modelvertexposition.xz - renderposition[3]) / texturerange[3] + 0.5;
	ex_texcoords[4] = (modelvertexposition.xz - renderposition[4]) / texturerange[4] + 0.5;
	ex_texcoords[5] = (modelvertexposition.xz - renderposition[5]) / texturerange[5] + 0.5;
	ex_texcoords[6] = (modelvertexposition.xz - renderposition[6]) / texturerange[6] + 0.5;
	ex_texcoords[7] = (modelvertexposition.xz - renderposition[7]) / texturerange[7] + 0.5;*/
	
	float terrainheight = length(entitymatrix_[1].xyz);
	modelvertexposition.y = texture2D(texture0, (modelvertexposition.xz+0.5)/ terrainsize + 0.5).r * terrainheight;
	
	ex_VertexCameraPosition = vec3(camerainversematrix * modelvertexposition);
	gl_Position = projectioncameramatrix * modelvertexposition;
	//ex_VertexCameraPosition = vec3(camerainversematrix * vec4(vertex_position, 1.0));
	//gl_Position = projectioncameramatrix * entitymatrix_ * vec4(vertex_position, 1.0);
	
	mat3 nmat = mat3(camerainversematrix[0].xyz,camerainversematrix[1].xyz,camerainversematrix[2].xyz);//39
	nmat = nmat * mat3(entitymatrix[0].xyz,entitymatrix[1].xyz,entitymatrix[2].xyz);//40
	ex_normal = (nmat * vertex_normal);	
	
	ex_color = vec4(entitymatrix[0][3],entitymatrix[1][3],entitymatrix[2][3],entitymatrix[3][3]);
	
	//If an object is selected, 10 is subtracted from the alpha color.
	//This is a bit of a hack that packs a per-object boolean into the alpha value.
	ex_selectionstate = 0.0;
	if (ex_color.a<-5.0)
	{
		ex_color.a += 10.0;
		ex_selectionstate = 1.0;
	}
	ex_color *= vec4(1.0-vertex_color.r,1.0-vertex_color.g,1.0-vertex_color.b,vertex_color.a) * materialcolordiffuse;
}
@OpenGL2.Fragment
#define VIRTUAL_TEXTURE_STAGES 7

varying vec2 ex_texcoords[VIRTUAL_TEXTURE_STAGES];

uniform sampler2D texture8;
uniform sampler2D texture9;

void main(void)
{
	vec4 normalcolor = texture2D(texture9,ex_texcoords[0]);
	vec3 normal = normalize( texture2D(texture8,ex_texcoords[0]).xyz * 2.0 - 1.0 );
	
	vec3 tangent = vec3(1,0,0);
	vec3 binormal = vec3(0,1,0);
	vec3 n = normalize( normalcolor.xyz * 2.0 - 1.0 );
	n = normalize( tangent*n.x + binormal*n.y + normal*n.z );
	
	vec4 outcolor = vec4(0.0,1.0,0.0,1.0);
	vec4 lightdir = vec4(-0.4,-0.7,0.5,1.0);
	float intensity = dot(n,lightdir.xyz);
	outcolor *= 0.25 + intensity * 0.75;

	gl_FragData[0] = outcolor;
}
@OpenGLES2.Vertex
//Uniforms
uniform mat4 entitymatrix;
uniform vec4 materialcolordiffuse;
uniform mat4 projectioncameramatrix;
uniform mat4 camerainversematrix;

//Attributes
attribute vec3 vertex_position;
attribute vec4 vertex_color;
attribute vec3 vertex_normal;

//Outputs
varying highp vec4 ex_color;
varying highp float ex_selectionstate;
varying highp vec3 ex_VertexCameraPosition;
varying highp vec3 ex_normal;

void main()
{
	mat4 entitymatrix_=entitymatrix;
	entitymatrix_[0][3]=0.0;
	entitymatrix_[1][3]=0.0;
	entitymatrix_[2][3]=0.0;
	entitymatrix_[3][3]=1.0;
	//entitymatrix_ * 
	
	vec4 modelvertexposition = entitymatrix_ * vec4(vertex_position,1.0);
	ex_VertexCameraPosition = vec3(camerainversematrix * modelvertexposition);
	gl_Position = projectioncameramatrix * modelvertexposition;
	//ex_VertexCameraPosition = vec3(camerainversematrix * vec4(vertex_position, 1.0));
	//gl_Position = projectioncameramatrix * entitymatrix_ * vec4(vertex_position, 1.0);
	
	mat3 nmat = mat3(camerainversematrix[0].xyz,camerainversematrix[1].xyz,camerainversematrix[2].xyz);//39
	nmat = nmat * mat3(entitymatrix[0].xyz,entitymatrix[1].xyz,entitymatrix[2].xyz);//40
	ex_normal = (nmat * vertex_normal);	
	
	ex_color = vec4(entitymatrix[0][3],entitymatrix[1][3],entitymatrix[2][3],entitymatrix[3][3]);
	ex_color *= vec4(1.0-vertex_color.r,1.0-vertex_color.g,1.0-vertex_color.b,vertex_color.a) * materialcolordiffuse;
}
@OpenGLES2.Fragment
//Uniforms	
uniform highp vec2 buffersize;
uniform highp vec2 camerarange;
uniform highp float camerazoom;
uniform highp vec4 materialcolorspecular;
uniform highp vec4 lighting_ambient;

#define MAXLIGHTS 2

//Lighting
uniform highp vec3 lightdirection[MAXLIGHTS];
uniform highp vec4 lightcolor[MAXLIGHTS];
uniform highp vec4 lightposition[MAXLIGHTS];
uniform highp float lightrange[MAXLIGHTS];
uniform highp vec3 lightingcenter[MAXLIGHTS];
uniform highp vec2 lightingconeanglescos[MAXLIGHTS];
uniform highp vec4 lightspecular[MAXLIGHTS];

//Inputs
varying highp vec4 ex_color;
varying highp vec3 ex_VertexCameraPosition;
varying highp vec3 ex_normal;

void main(void)
{
	highp vec4 outcolor = ex_color;
	highp vec4 color_specular = materialcolorspecular;
	highp vec3 normal = normalize(ex_normal);	
	
	//Calculate lighting
	highp vec4 lighting_diffuse = vec4(0);
	highp vec4 lighting_specular = vec4(0);
	highp float attenuation=1.0;
	highp vec3 lightdir;
	highp vec3 lightreflection;
	int i;
	highp float anglecos;
	highp float diffspotangle;
	highp float denom;
	
	//One equation, three light types
	for (i=0; i<MAXLIGHTS; i++)
	{
		//Get light direction to this pixel
		lightdir = normalize(ex_VertexCameraPosition - lightposition[i].xyz) * lightposition[i].w + lightdirection[i] * (1.0 - lightposition[i].w);
		
		//Distance attenuation
		attenuation = lightposition[i].w * max(0.0, 1.0 - distance(lightposition[i].xyz,ex_VertexCameraPosition) / lightrange[i]) + (1.0 - lightposition[i].w);
		
		//Normal attenuation
		attenuation *= max(0.0,dot(normal,-lightdir));
		
		//Spot cone attenuation
		denom = lightingconeanglescos[i].y-lightingconeanglescos[i].x;	
		if (denom>-1.0)
		{
			anglecos = max(0.0,dot(lightdirection[i],lightdir));
			attenuation *= 1.0 - clamp((lightingconeanglescos[i].y-anglecos)/denom,0.0,1.0);
		}

		lighting_diffuse += lightcolor[i] * attenuation;
	}
	
	//Write final output color
	gl_FragData[0] = (lighting_diffuse + lighting_ambient) * outcolor;
}
@OpenGL4.Vertex
#version 400
#define VIRTUAL_TEXTURE_STAGES 7
#define MAX_INSTANCES 256

//Uniforms
uniform vec4 materialcolordiffuse;
uniform mat4 projectioncameramatrix;
uniform mat4 camerainversematrix;
uniform float terrainsize;
uniform float texturerange[VIRTUAL_TEXTURE_STAGES];
//uniform float terrainheight;
uniform vec2 renderposition[8];
uniform sampler2D texture0;
uniform instancematrices { mat4 matrix[MAX_INSTANCES];} entity;

//Attributes
in vec3 vertex_position;
in vec4 vertex_color;
in vec3 vertex_normal;

//Outputs
out vec4 ex_color;
out float ex_selectionstate;
out vec3 ex_VertexCameraPosition;
out vec3 ex_normal;
out vec2 ex_texcoords0;
//out vec2 ex_texcoords1;
//out vec2 ex_texcoords2;
//out vec2 ex_texcoords3;
out float ty;

void main()
{
	mat4 entitymatrix = entity.matrix[gl_InstanceID];
	mat4 entitymatrix_=entitymatrix;
	entitymatrix_[0][3]=0.0;
	entitymatrix_[1][3]=0.0;
	entitymatrix_[2][3]=0.0;
	entitymatrix_[3][3]=1.0;
	//entitymatrix_ * 
	//ex_texcoords0.x = 1.0 - ex_texcoords0.x;
	
	vec4 modelvertexposition = entitymatrix_ * (vec4(vertex_position,1.0));
	
	ex_texcoords0 = (modelvertexposition.xz) / terrainsize + 0.5;

	/*ex_texcoords[1] = (modelvertexposition.xz - renderposition[1]) / texturerange[1] + 0.5;
	ex_texcoords[2] = (modelvertexposition.xz - renderposition[2]) / texturerange[2] + 0.5;
	ex_texcoords[3] = (modelvertexposition.xz - renderposition[3]) / texturerange[3] + 0.5;
	ex_texcoords[4] = (modelvertexposition.xz - renderposition[4]) / texturerange[4] + 0.5;
	ex_texcoords[5] = (modelvertexposition.xz - renderposition[5]) / texturerange[5] + 0.5;
	ex_texcoords[6] = (modelvertexposition.xz - renderposition[6]) / texturerange[6] + 0.5;
	ex_texcoords[7] = (modelvertexposition.xz - renderposition[7]) / texturerange[7] + 0.5;*/
	
	float terrainheight = length(entitymatrix_[1].xyz);
	modelvertexposition.y = texture(texture0, (modelvertexposition.xz+0.5)/ terrainsize + 0.5).r * terrainheight;	
	
	ex_VertexCameraPosition = vec3(camerainversematrix * modelvertexposition);
	gl_Position = projectioncameramatrix * modelvertexposition;
	//ex_VertexCameraPosition = vec3(camerainversematrix * vec4(vertex_position, 1.0));
	//gl_Position = projectioncameramatrix * entitymatrix_ * vec4(vertex_position, 1.0);
	
	mat3 nmat = mat3(camerainversematrix[0].xyz,camerainversematrix[1].xyz,camerainversematrix[2].xyz);//39
	nmat = nmat * mat3(entitymatrix[0].xyz,entitymatrix[1].xyz,entitymatrix[2].xyz);//40
	ex_normal = (nmat * vertex_normal);	
	
	ex_color = vec4(entitymatrix[0][3],entitymatrix[1][3],entitymatrix[2][3],entitymatrix[3][3]);
	
	//If an object is selected, 10 is subtracted from the alpha color.
	//This is a bit of a hack that packs a per-object boolean into the alpha value.
	ex_selectionstate = 0.0;
	if (ex_color.a<-5.0)
	{
		ex_color.a += 10.0;
		ex_selectionstate = 1.0;
	}
	ex_color *= vec4(1.0-vertex_color.r,1.0-vertex_color.g,1.0-vertex_color.b,vertex_color.a) * materialcolordiffuse;
}
@OpenGL4.Fragment
#version 400

//Uniforms
uniform sampler2D texture1;

//Inputs
in vec2 ex_texcoords0;

//Outputs
out vec4 fragData0;

void main(void)
{
	vec3 normal = texture(texture1,ex_texcoords0).xyz;
	vec4 outcolor = vec4(0.0,0.5,0.0,1.0);
	vec4 lightdir = vec4(-0.4,-0.7,0.5,1.0);
	float intensity = dot(normal,lightdir.xyz);
	outcolor *= 0.75 + intensity * 0.25;
	fragData0 = outcolor;
}
