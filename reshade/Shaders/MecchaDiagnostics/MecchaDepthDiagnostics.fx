#define MECCHA_ENABLE_DEPTH_HELPERS 1
#include "MecchaCommon.fxh"

uniform int MecchaDepthDiagnosticMode <
	ui_type = "combo";
	ui_items = "Raw depth\0 Linearized depth\0 Depth gradients\0 Reconstructed normals\0";
	ui_label = "Depth diagnostic";
> = 0;

uniform float MecchaDepthSampleDistance <
	ui_type = "drag";
	ui_min = 0.5;
	ui_max = 8.0;
	ui_step = 0.25;
	ui_label = "Sample distance";
> = 1.0;

uniform float MecchaDepthGradientScale <
	ui_type = "drag";
	ui_min = 0.1;
	ui_max = 1000.0;
	ui_step = 0.1;
	ui_label = "Gradient/normal scale";
> = 50.0;

float MecchaRawDepth(float2 texcoord)
{
	return MecchaGetRawDepth(texcoord);
}

float MecchaLinearDepth(float2 texcoord)
{
	return MecchaGetLinearizedDepth(texcoord);
}

float4 PS_MecchaDepthDiagnostics(float4 position : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
	float raw = MecchaRawDepth(texcoord);
	float linearDepth = MecchaLinearDepth(texcoord);
	if (MecchaDepthDiagnosticMode == 0)
		return raw.xxxx;
	if (MecchaDepthDiagnosticMode == 1)
		return linearDepth.xxxx;

	float2 offset = MECCHA_PIXEL_SIZE * MecchaDepthSampleDistance;
	float left = MecchaLinearDepth(texcoord - float2(offset.x, 0.0));
	float right = MecchaLinearDepth(texcoord + float2(offset.x, 0.0));
	float top = MecchaLinearDepth(texcoord - float2(0.0, offset.y));
	float bottom = MecchaLinearDepth(texcoord + float2(0.0, offset.y));
	float2 gradient = float2(right - left, bottom - top) * MecchaDepthGradientScale;
	if (MecchaDepthDiagnosticMode == 2)
		return saturate(length(gradient)).xxxx;

	float3 normal = normalize(float3(-gradient.x, -gradient.y, 1.0));
	return float4(normal * 0.5 + 0.5, 1.0);
}

technique MecchaDepthDiagnostics
{
	pass
	{
		VertexShader = MecchaPostProcessVS;
		PixelShader = PS_MecchaDepthDiagnostics;
	}
}
