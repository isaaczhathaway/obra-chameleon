#include "MecchaCommon.fxh"

uniform int MecchaTrivialMode <
	ui_type = "combo";
	ui_items = "Grayscale\0 Invert\0 Contrast\0 Pixelate\0";
	ui_label = "Diagnostic effect";
> = 0;

uniform float MecchaTrivialContrast <
	ui_type = "drag";
	ui_min = 0.0;
	ui_max = 3.0;
	ui_step = 0.01;
	ui_label = "Contrast";
> = 1.4;

uniform float MecchaTrivialPixelSize <
	ui_type = "drag";
	ui_min = 1.0;
	ui_max = 64.0;
	ui_step = 1.0;
	ui_label = "Pixel size";
> = 8.0;

texture2D MecchaTrivialBackBuffer : COLOR;

sampler2D MecchaTrivialSampler
{
	Texture = MecchaTrivialBackBuffer;
};

float4 PS_MecchaTrivial(float4 position : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
	float2 sampleUV = texcoord;
	if (MecchaTrivialMode == 3)
	{
		float2 cells = float2(BUFFER_WIDTH, BUFFER_HEIGHT) / max(MecchaTrivialPixelSize, 1.0);
		sampleUV = (floor(texcoord * cells) + 0.5) / cells;
	}
	float3 color = tex2D(MecchaTrivialSampler, sampleUV).rgb;
	if (MecchaTrivialMode == 0)
		color = dot(color, float3(0.2126, 0.7152, 0.0722)).xxx;
	else if (MecchaTrivialMode == 1)
		color = 1.0 - color;
	else if (MecchaTrivialMode == 2)
		color = saturate((color - 0.5) * MecchaTrivialContrast + 0.5);
	return float4(color, 1.0);
}

technique MecchaTrivial
{
	pass
	{
		VertexShader = MecchaPostProcessVS;
		PixelShader = PS_MecchaTrivial;
	}
}
