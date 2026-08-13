#ifndef CHROMAPPER_FOG_INCLUDED
#define CHROMAPPER_FOG_INCLUDED

#include "Camera.hlsl"

// These are the global variable names the game uses by default,
// certain mods might want to use their own attenuation/offset variable names.
#ifndef CUSTOM_FOG_ATTENUATION_NAME
#define CUSTOM_FOG_ATTENUATION_NAME _CustomFogAttenuation
#endif
#ifndef CUSTOM_FOG_OFFSET_NAME
#define CUSTOM_FOG_OFFSET_NAME _CustomFogOffset
#endif

float CUSTOM_FOG_ATTENUATION_NAME;
float CUSTOM_FOG_OFFSET_NAME;

inline float distanceSquared(float3 pos)
{
    float3 distance = pos - GetStereoAwareCameraPosition();
    return dot(distance, distance);
}

inline float CalculateCustomFogFactor(float distanceSq, float fogStartOffset, float fogScale)
{
    float result = max(distanceSq + -fogStartOffset, 0);
    result = max(result * fogScale + -CUSTOM_FOG_OFFSET_NAME, 0);
    result = 1 / (result * CUSTOM_FOG_ATTENUATION_NAME + 1);
    return -result + 1;
}

inline float CalculateWaterLitFogStartOffset(
    float worldNormalY, float fogStartOffset, float fallingFogStartOffset)
{
    return mad(1.0 - saturate(worldNormalY), fallingFogStartOffset, fogStartOffset);
}

#ifndef CUSTOM_FOG_HEIGHT_FOG_START_Y_NAME
#define CUSTOM_FOG_HEIGHT_FOG_START_Y_NAME _CustomFogHeightFogStartY
#endif
#ifndef CUSTOM_FOG_HEIGHT_FOG_HEIGHT_NAME
#define CUSTOM_FOG_HEIGHT_FOG_HEIGHT_NAME _CustomFogHeightFogHeight
#endif

float CUSTOM_FOG_HEIGHT_FOG_START_Y_NAME;
float CUSTOM_FOG_HEIGHT_FOG_HEIGHT_NAME;

inline float CalculateCustomHeightFogFactor(float3 worldPos, float fogHeightOffset, float fogHeightScale)
{
    float result = CUSTOM_FOG_HEIGHT_FOG_HEIGHT_NAME + CUSTOM_FOG_HEIGHT_FOG_START_Y_NAME;
    result = ((worldPos.y * fogHeightScale) + fogHeightOffset) + -result;
    result = clamp(result / CUSTOM_FOG_HEIGHT_FOG_HEIGHT_NAME, 0, 1);
    return (-result * 2 + 3) * (result * result);
}

inline float CalculateBloomFogHeightFactor(
    float3 worldPosition, float fogHeightOffset, float fogHeightScale,
    float fogSoften, float fogSoftenOffset)
{
#if defined(HEIGHT_FOG_DEPTH_SOFTEN)
    float cameraDistance = length(worldPosition - GetStereoAwareCameraPosition());
    float heightInput = worldPosition.y *
        (fogHeightScale / (cameraDistance * fogSoften * 0.01));
    heightInput += fogHeightOffset - cameraDistance * fogSoftenOffset * 0.001;
    #else
    float heightInput = worldPosition.y * fogHeightScale + fogHeightOffset;
    #endif
    heightInput -= CUSTOM_FOG_HEIGHT_FOG_HEIGHT_NAME + CUSTOM_FOG_HEIGHT_FOG_START_Y_NAME;
    heightInput = clamp(heightInput / CUSTOM_FOG_HEIGHT_FOG_HEIGHT_NAME, 0.0, 1.0);
    return heightInput * heightInput * (3.0 - 2.0 * heightInput);
}

// Height fog and color fog helpers. Per-material inputs are passed in as
// arguments (fog altitude, softening, color fog tuning); the library only
// reads its own BloomFog-owned globals listed above.

inline float CalculateHeightFogFactor(float exactHeightInput)
{
    exactHeightInput -= CUSTOM_FOG_HEIGHT_FOG_HEIGHT_NAME + CUSTOM_FOG_HEIGHT_FOG_START_Y_NAME;
    exactHeightInput = saturate(exactHeightInput / CUSTOM_FOG_HEIGHT_FOG_HEIGHT_NAME);
    return 1.0 -
        exactHeightInput * exactHeightInput * (3.0 - 2.0 * exactHeightInput);
}

inline float4 ApplyHeightFogCurve(float4 result, float exactHeightInput)
{
    float exactHeightFog = CalculateHeightFogFactor(exactHeightInput);
    return exactHeightFog.xxxx * (float4(0.1, 0.1, 0.1, 0.0) - result) + result;
}

inline float4 ApplyHeightFog(
    float4 result, float3 worldPosition,
    float fogHeightScale, float fogHeightOffset)
{
    float exactHeightInput = worldPosition.y * fogHeightScale + fogHeightOffset;
    return ApplyHeightFogCurve(result, exactHeightInput);
}

inline float4 ApplySoftenedHeightFog(
    float4 result, float3 worldPosition,
    float fogHeightScale, float fogHeightOffset,
    float fogSoften, float fogSoftenOffset)
{
    float cameraDistance = length(worldPosition - GetStereoAwareCameraPosition());
    float exactHeightInput = worldPosition.y *
        (fogHeightScale / (cameraDistance * fogSoften * 0.01));
    exactHeightInput += fogHeightOffset - cameraDistance * fogSoftenOffset * 0.001;
    return ApplyHeightFogCurve(result, exactHeightInput);
}

inline float4 ApplyColorFog(
    float4 result, float3 worldPosition,
    float colorFogMultiplier, float colorFogMax, float colorFogHighlightMultiplier,
    float colorFogInfluence, float fogHeightScale, float fogHeightOffset)
{
    float resolvedColorFogMultiplier = min(0.0001 * colorFogMultiplier, colorFogMax);
    #if defined(FOG_COLOR_HIGHLIGHT)
    float colorFogHighlight = min(
        0.1 * colorFogHighlightMultiplier * (1.0 + resolvedColorFogMultiplier),
        colorFogMax);
    #else
    float colorFogHighlight = 0.0;
    #endif
    float4 colorFogResult = float4(
        result.rgb * colorFogInfluence + colorFogHighlight,
        result.a);
    #if defined(BLOOM_FOG) && defined(FOG)
    return colorFogResult;
    #else
    float exactHeightInput = worldPosition.y * fogHeightScale + fogHeightOffset;
    float exactHeightFog = CalculateHeightFogFactor(exactHeightInput);
    return exactHeightFog.xxxx *
        (float4(colorFogHighlight.xxx, 0.0) - colorFogResult) + colorFogResult;
    #endif
}

float2 _CustomFogTextureToScreenRatio;
sampler2D _BloomPrePassTexture;

inline float4 SampleBloomPrePass(float4 screenPos)
{
    #if defined(BLOOM_FOG)
    float2 customFogUV = screenPos.xy / screenPos.w;
    customFogUV = (customFogUV + -0.5) * _CustomFogTextureToScreenRatio + 0.5;
    return float4(tex2D(_BloomPrePassTexture, customFogUV).rgb, 0);
    #else
    return 0;
    #endif
}

inline float4 BlendFogColor(float4 col, float4 bloomfogCol)
{
    #if defined(_FOGTYPE_ALPHA)
    col.a = bloomfogCol.a;
    return col;
    #elif defined(_FOGTYPE_COLOR)
    col.rgb = bloomfogCol.rgb;
    return col;
    #else
    return bloomfogCol;
    #endif
}

inline float4 ApplyBloomFogCalculatedFactor(float4 col, float4 screenPos, float fogFactor)
{
    float4 bloomPrepassCol = SampleBloomPrePass(screenPos);
    float4 bloomfogCol = fogFactor * (-col + bloomPrepassCol) + col;
    return BlendFogColor(col, bloomfogCol);
}

inline float4 ApplyBloomFog(float4 col, float4 screenPos, float3 worldPos, float fogStartOffset, float fogScale)
{
    return ApplyBloomFogCalculatedFactor(
        col, screenPos, CalculateCustomFogFactor(distanceSquared(worldPos), fogStartOffset, fogScale));
}

inline float4 ApplyBloomHeightFogCalculatedFactor(float4 col, float4 screenPos, float fogFactor, float heightFogFactor)
{
    float4 bloomPrepassCol = SampleBloomPrePass(screenPos);
    fogFactor = -fogFactor + 1;
    float4 bloomfogCol = (heightFogFactor * -fogFactor + 1) * (-col + bloomPrepassCol) + col;
    return BlendFogColor(col, bloomfogCol);
}

inline float4 ApplyBloomHeightFog(float4 col, float4 screenPos, float3 worldPos, float fogStartOffset, float fogScale,
                                  float fogHeightOffset, float fogHeightScale)
{
    return ApplyBloomHeightFogCalculatedFactor(
        col, screenPos,
        CalculateCustomFogFactor(distanceSquared(worldPos), fogStartOffset, fogScale),
        CalculateCustomHeightFogFactor(worldPos, fogHeightOffset, fogHeightScale));
}

inline float4 ApplyTransparentBloomFogCalculatedFactor(float4 col, float fogFactor)
{
    fogFactor = (-fogFactor + 1) * col.a;
    float4 bloomfogCol = float4(fogFactor * col.rgb, fogFactor);
    return BlendFogColor(col, bloomfogCol);
}

inline float4 ApplyTransparentBloomFog(float4 col, float3 worldPos, float fogStartOffset, float fogScale)
{
    return ApplyTransparentBloomFogCalculatedFactor(
        col, CalculateCustomFogFactor(distanceSquared(worldPos), fogStartOffset, fogScale));
}

#endif // CHROMAPPER_FOG_INCLUDED
