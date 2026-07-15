#include "MecchaCommon.fxh"

uniform int MecchaColorDiagnosticMode <
	ui_type = "combo";
	ui_items = "Luminance\0 Raw Sobel\0 Thresholded Sobel\0";
	ui_label = "Color diagnostic";
> = 0;

uniform float MecchaDiagnosticEdgeThreshold <
	ui_type = "drag";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_step = 0.002;
	ui_label = "Sobel threshold";
> = 0.15;

uniform float MecchaDiagnosticSampleDistance <
	ui_type = "drag";
	ui_min = 0.5;
	ui_max = 8.0;
	ui_step = 0.25;
	ui_label = "Sample distance";
> = 1.0;

texture2D MecchaColorDiagnosticBuffer : COLOR;

sampler2D MecchaColorDiagnosticSampler
{
	Texture = MecchaColorDiagnosticBuffer;
};

float MecchaDiagnosticLuminance(float2 texcoord)
{
	return dot(tex2D(MecchaColorDiagnosticSampler, texcoord).rgb, float3(0.2126, 0.7152, 0.0722));
}

float MecchaDiagnosticSobel(float2 texcoord)
{
	float2 offset = MECCHA_PIXEL_SIZE * MecchaDiagnosticSampleDistance;
	float tl = MecchaDiagnosticLuminance(texcoord + offset * float2(-1.0, -1.0));
	float tc = MecchaDiagnosticLuminance(texcoord + offset * float2( 0.0, -1.0));
	float tr = MecchaDiagnosticLuminance(texcoord + offset * float2( 1.0, -1.0));
	float ml = MecchaDiagnosticLuminance(texcoord + offset * float2(-1.0,  0.0));
	float mr = MecchaDiagnosticLuminance(texcoord + offset * float2( 1.0,  0.0));
	float bl = MecchaDiagnosticLuminance(texcoord + offset * float2(-1.0,  1.0));
	float bc = MecchaDiagnosticLuminance(texcoord + offset * float2( 0.0,  1.0));
	float br = MecchaDiagnosticLuminance(texcoord + offset * float2( 1.0,  1.0));
	float gx = -tl - 2.0 * ml - bl + tr + 2.0 * mr + br;
	float gy = -tl - 2.0 * tc - tr + bl + 2.0 * bc + br;
	return saturate(sqrt(gx * gx + gy * gy) * 0.25);
}

float4 PS_MecchaColorDiagnostics(float4 position : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
	float value = MecchaColorDiagnosticMode == 0
		? MecchaDiagnosticLuminance(texcoord)
		: MecchaDiagnosticSobel(texcoord);
	if (MecchaColorDiagnosticMode == 2)
		value = step(MecchaDiagnosticEdgeThreshold, value);
	return value.xxxx;
}

technique MecchaColorDiagnostics
{
	pass
	{
		VertexShader = MecchaPostProcessVS;
		PixelShader = PS_MecchaColorDiagnostics;
	}
}
