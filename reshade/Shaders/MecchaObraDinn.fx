#include "MecchaCommon.fxh"

// Meccha Chameleon two-color post-process prototype.
// Depth-dependent features stay outside this effect until depth access is verified in-game.

uniform float3 MecchaDarkColor <
	ui_type = "color";
	ui_label = "Dark palette color";
> = float3(0.1059, 0.0706, 0.0471);

uniform float3 MecchaLightColor <
	ui_type = "color";
	ui_label = "Light palette color";
> = float3(0.8627, 0.7922, 0.6196);

uniform float MecchaLuminanceThreshold <
	ui_type = "drag";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_step = 0.005;
	ui_label = "Luminance threshold";
> = 0.5;

uniform float MecchaBrightness <
	ui_type = "drag";
	ui_min = -1.0;
	ui_max = 1.0;
	ui_step = 0.01;
	ui_label = "Brightness";
> = 0.0;

uniform float MecchaContrast <
	ui_type = "drag";
	ui_min = 0.0;
	ui_max = 3.0;
	ui_step = 0.01;
	ui_label = "Contrast";
> = 1.15;

uniform float MecchaGamma <
	ui_type = "drag";
	ui_min = 0.1;
	ui_max = 4.0;
	ui_step = 0.01;
	ui_label = "Gamma";
> = 1.0;

uniform float MecchaEffectStrength <
	ui_type = "drag";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_step = 0.01;
	ui_label = "Effect strength";
> = 1.0;

uniform bool MecchaEnableDither <
	ui_label = "Enable ordered dithering";
> = true;

uniform int MecchaDitherMatrix <
	ui_type = "combo";
	ui_items = "2x2 Bayer\0 4x4 Bayer\0 8x8 Bayer\0";
	ui_label = "Dither matrix";
> = 2;

uniform float MecchaDitherStrength <
	ui_type = "drag";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_step = 0.01;
	ui_label = "Dither strength";
> = 0.85;

uniform float MecchaDitherScale <
	ui_type = "drag";
	ui_min = 1.0;
	ui_max = 16.0;
	ui_step = 1.0;
	ui_label = "Dither scale";
> = 1.0;

uniform int2 MecchaDitherOffset <
	ui_type = "drag";
	ui_min = -64;
	ui_max = 64;
	ui_step = 1;
	ui_label = "Dither offset";
> = int2(0, 0);

uniform bool MecchaDitherUsesVirtualPixels <
	ui_label = "Align dither to virtual pixels";
> = true;

uniform bool MecchaInvertDither <
	ui_label = "Invert dither pattern";
> = false;

uniform bool MecchaEnableVirtualResolution <
	ui_label = "Enable virtual resolution";
> = true;

uniform int MecchaVirtualWidth <
	ui_type = "drag";
	ui_min = 160;
	ui_max = 3840;
	ui_step = 1;
	ui_label = "Virtual horizontal resolution";
> = 640;

uniform int MecchaVirtualHeight <
	ui_type = "drag";
	ui_min = 100;
	ui_max = 2160;
	ui_step = 1;
	ui_label = "Virtual vertical resolution";
> = 360;

uniform float MecchaPixelAspectCorrection <
	ui_type = "drag";
	ui_min = 0.25;
	ui_max = 4.0;
	ui_step = 0.01;
	ui_label = "Pixel aspect correction";
> = 1.0;

uniform bool MecchaFilteredSampling <
	ui_label = "Filtered virtual sampling";
> = false;

uniform bool MecchaIntegerScaleGrid <
	ui_label = "Integer-scale virtual grid";
> = false;

uniform bool MecchaEnableColorEdges <
	ui_label = "Enable color edges";
> = true;

uniform float MecchaColorEdgeThreshold <
	ui_type = "drag";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_step = 0.002;
	ui_label = "Color edge threshold";
> = 0.16;

uniform float MecchaColorEdgeThickness <
	ui_type = "drag";
	ui_min = 0.5;
	ui_max = 4.0;
	ui_step = 0.25;
	ui_label = "Color edge thickness";
> = 1.0;

uniform float MecchaColorEdgeStrength <
	ui_type = "drag";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_step = 0.01;
	ui_label = "Color edge strength";
> = 0.9;

uniform bool MecchaInvertEdges <
	ui_label = "Invert palette at edges";
> = false;

uniform bool MecchaEnableUIExclusion <
	ui_label = "Enable rectangular UI exclusion";
> = false;

uniform float2 MecchaUIExclusionMin <
	ui_type = "drag";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_step = 0.001;
	ui_label = "UI exclusion minimum UV";
> = float2(0.0, 0.0);

uniform float2 MecchaUIExclusionMax <
	ui_type = "drag";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_step = 0.001;
	ui_label = "UI exclusion maximum UV";
> = float2(1.0, 0.12);

uniform int MecchaDebugMode <
	ui_type = "combo";
	ui_items = "Final output\0 Original image\0 Grayscale luminance\0 Threshold mask\0 Raw Sobel magnitude\0 Thresholded edges\0 Palette without edges\0";
	ui_label = "Debug output";
> = 0;

texture2D MecchaBackBuffer : COLOR;

sampler2D MecchaBackSampler
{
	Texture = MecchaBackBuffer;
};

float MecchaLuminance(float3 color)
{
	return dot(color, float3(0.2126, 0.7152, 0.0722));
}

float MecchaShapeLuminance(float luminance)
{
	float shaped = saturate(luminance + MecchaBrightness);
	shaped = saturate((shaped - 0.5) * MecchaContrast + 0.5);
	return pow(max(shaped, 0.00001), 1.0 / max(MecchaGamma, 0.00001));
}

float2 MecchaVirtualSize()
{
	float2 requested = max(float2(MecchaVirtualWidth, MecchaVirtualHeight), 1.0);
	requested.x = max(1.0, requested.x / max(MecchaPixelAspectCorrection, 0.00001));
	if (MecchaIntegerScaleGrid)
	{
		float scale = max(1.0, floor(min(BUFFER_WIDTH / requested.x, BUFFER_HEIGHT / requested.y)));
		requested = floor(float2(BUFFER_WIDTH, BUFFER_HEIGHT) / scale);
	}
	return requested;
}

float2 MecchaVirtualPixel(float2 texcoord)
{
	return floor(saturate(texcoord) * MecchaVirtualSize());
}

float3 MecchaSampleScene(float2 texcoord)
{
	if (!MecchaEnableVirtualResolution)
		return tex2D(MecchaBackSampler, texcoord).rgb;

	float2 size = MecchaVirtualSize();
	if (!MecchaFilteredSampling)
	{
		float2 snapped = (floor(saturate(texcoord) * size) + 0.5) / size;
		return tex2D(MecchaBackSampler, snapped).rgb;
	}

	float2 position = saturate(texcoord) * size - 0.5;
	float2 base = floor(position);
	float2 blend = frac(position);
	float2 uv00 = saturate((base + float2(0.5, 0.5)) / size);
	float2 uv10 = saturate((base + float2(1.5, 0.5)) / size);
	float2 uv01 = saturate((base + float2(0.5, 1.5)) / size);
	float2 uv11 = saturate((base + float2(1.5, 1.5)) / size);
	float3 top = lerp(tex2D(MecchaBackSampler, uv00).rgb, tex2D(MecchaBackSampler, uv10).rgb, blend.x);
	float3 bottom = lerp(tex2D(MecchaBackSampler, uv01).rgb, tex2D(MecchaBackSampler, uv11).rgb, blend.x);
	return lerp(top, bottom, blend.y);
}

float MecchaBayer2(int x, int y)
{
	x = x % 2;
	y = y % 2;
	if (y == 0)
		return x == 0 ? 0.0 : 2.0;
	return x == 0 ? 3.0 : 1.0;
}

float MecchaBayer4(int x, int y)
{
	return 4.0 * MecchaBayer2(x % 2, y % 2) + MecchaBayer2((x / 2) % 2, (y / 2) % 2);
}

float MecchaBayer8(int x, int y)
{
	return 16.0 * MecchaBayer2(x % 2, y % 2) + MecchaBayer4((x / 2) % 4, (y / 2) % 4);
}

float MecchaDitherValue(float2 texcoord)
{
	float2 pixel = MecchaDitherUsesVirtualPixels && MecchaEnableVirtualResolution
		? MecchaVirtualPixel(texcoord)
		: floor(saturate(texcoord) * float2(BUFFER_WIDTH, BUFFER_HEIGHT));
	pixel = floor(pixel / max(MecchaDitherScale, 1.0)) + float2(MecchaDitherOffset);
	int x = (int)abs(pixel.x);
	int y = (int)abs(pixel.y);
	float value;
	float count;
	if (MecchaDitherMatrix == 0)
	{
		value = MecchaBayer2(x, y);
		count = 4.0;
	}
	else if (MecchaDitherMatrix == 1)
	{
		value = MecchaBayer4(x, y);
		count = 16.0;
	}
	else
	{
		value = MecchaBayer8(x, y);
		count = 64.0;
	}
	float centered = (value + 0.5) / count - 0.5;
	return MecchaInvertDither ? -centered : centered;
}

float MecchaSobel(float2 texcoord)
{
	float2 stepSize = MecchaEnableVirtualResolution
		? 1.0 / MecchaVirtualSize()
		: MECCHA_PIXEL_SIZE;
	stepSize *= MecchaColorEdgeThickness;
	float tl = MecchaLuminance(MecchaSampleScene(texcoord + stepSize * float2(-1.0, -1.0)));
	float tc = MecchaLuminance(MecchaSampleScene(texcoord + stepSize * float2( 0.0, -1.0)));
	float tr = MecchaLuminance(MecchaSampleScene(texcoord + stepSize * float2( 1.0, -1.0)));
	float ml = MecchaLuminance(MecchaSampleScene(texcoord + stepSize * float2(-1.0,  0.0)));
	float mr = MecchaLuminance(MecchaSampleScene(texcoord + stepSize * float2( 1.0,  0.0)));
	float bl = MecchaLuminance(MecchaSampleScene(texcoord + stepSize * float2(-1.0,  1.0)));
	float bc = MecchaLuminance(MecchaSampleScene(texcoord + stepSize * float2( 0.0,  1.0)));
	float br = MecchaLuminance(MecchaSampleScene(texcoord + stepSize * float2( 1.0,  1.0)));
	float gx = -tl - 2.0 * ml - bl + tr + 2.0 * mr + br;
	float gy = -tl - 2.0 * tc - tr + bl + 2.0 * bc + br;
	return saturate(sqrt(gx * gx + gy * gy) * 0.25);
}

bool MecchaInsideUIExclusion(float2 texcoord)
{
	return MecchaEnableUIExclusion
		&& all(texcoord >= MecchaUIExclusionMin)
		&& all(texcoord <= MecchaUIExclusionMax);
}

float4 PS_MecchaObraDinn(float4 position : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
	float3 original = tex2D(MecchaBackSampler, texcoord).rgb;
	float3 scene = MecchaSampleScene(texcoord);
	float luminance = MecchaShapeLuminance(MecchaLuminance(scene));
	float dither = MecchaEnableDither ? MecchaDitherValue(texcoord) * MecchaDitherStrength : 0.0;
	float paletteMask = step(MecchaLuminanceThreshold, luminance + dither);
	float3 palette = lerp(MecchaDarkColor, MecchaLightColor, paletteMask);
	bool needsSobel = MecchaEnableColorEdges || MecchaDebugMode == 4 || MecchaDebugMode == 5;
	float sobel = needsSobel ? MecchaSobel(texcoord) : 0.0;
	float edgeMask = MecchaEnableColorEdges ? step(MecchaColorEdgeThreshold, sobel) : 0.0;
	float3 edgeColor = MecchaInvertEdges
		? lerp(MecchaLightColor, MecchaDarkColor, paletteMask)
		: MecchaDarkColor;
	float3 finalColor = lerp(palette, edgeColor, edgeMask * MecchaColorEdgeStrength);

	if (MecchaDebugMode == 1)
		finalColor = original;
	else if (MecchaDebugMode == 2)
		finalColor = luminance.xxx;
	else if (MecchaDebugMode == 3)
		finalColor = step(MecchaLuminanceThreshold, luminance).xxx;
	else if (MecchaDebugMode == 4)
		finalColor = sobel.xxx;
	else if (MecchaDebugMode == 5)
		finalColor = edgeMask.xxx;
	else if (MecchaDebugMode == 6)
		finalColor = palette;

	if (MecchaInsideUIExclusion(texcoord))
		finalColor = original;
	else if (MecchaDebugMode == 0)
		finalColor = lerp(original, finalColor, MecchaEffectStrength);

	return float4(finalColor, 1.0);
}

technique MecchaObraDinn
{
	pass
	{
		VertexShader = MecchaPostProcessVS;
		PixelShader = PS_MecchaObraDinn;
	}
}
