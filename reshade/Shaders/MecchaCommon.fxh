#ifndef MECCHA_COMMON_FXH
#define MECCHA_COMMON_FXH

#define MECCHA_PIXEL_SIZE float2(1.0 / BUFFER_WIDTH, 1.0 / BUFFER_HEIGHT)

void MecchaPostProcessVS(
	uint vertexID : SV_VertexID,
	out float4 position : SV_Position,
	out float2 texcoord : TEXCOORD0)
{
	texcoord.x = vertexID == 2 ? 2.0 : 0.0;
	texcoord.y = vertexID == 1 ? 2.0 : 0.0;
	position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
}

#ifdef MECCHA_ENABLE_DEPTH_HELPERS

#ifndef RESHADE_DEPTH_LINEARIZATION_FAR_PLANE
#define RESHADE_DEPTH_LINEARIZATION_FAR_PLANE 1000.0
#endif

#ifndef RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN
#define RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN 0
#endif

#ifndef RESHADE_DEPTH_INPUT_IS_REVERSED
#define RESHADE_DEPTH_INPUT_IS_REVERSED 1
#endif

texture2D MecchaCommonDepthBuffer : DEPTH;

sampler2D MecchaCommonDepthSampler
{
	Texture = MecchaCommonDepthBuffer;
};

float2 MecchaDepthUV(float2 texcoord)
{
#if RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN
	texcoord.y = 1.0 - texcoord.y;
#endif
	return texcoord;
}

float MecchaGetRawDepth(float2 texcoord)
{
	return tex2Dlod(MecchaCommonDepthSampler, float4(MecchaDepthUV(texcoord), 0.0, 0.0)).x;
}

float MecchaGetLinearizedDepth(float2 texcoord)
{
	float depth = MecchaGetRawDepth(texcoord);
#if RESHADE_DEPTH_INPUT_IS_REVERSED
	depth = 1.0 - depth;
#endif
	const float nearPlane = 1.0;
	depth /= RESHADE_DEPTH_LINEARIZATION_FAR_PLANE
		- depth * (RESHADE_DEPTH_LINEARIZATION_FAR_PLANE - nearPlane);
	return depth;
}

#endif

#endif
