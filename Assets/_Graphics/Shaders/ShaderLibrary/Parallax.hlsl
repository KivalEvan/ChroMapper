#ifndef CHROMAPPER_PARALLAX_INCLUDED
#define CHROMAPPER_PARALLAX_INCLUDED

#include "Data.hlsl"
#include "Camera.hlsl"
#include "CustomTime.hlsl"
#include "Iridescence.hlsl"

// Parallax inputs are passed in by value; the library does not read
// uniforms the consumer shader must declare.

inline float4 ApplyParallax(
    float4 result, SurfaceData surface, float4 vertexColor,
    float2 inputUvMultiplier, float timeOffset, float2 parallaxTexSpeed,
    float parallaxIntensity, float parallaxIntensityStep,
    float layers, float startOffset, float offsetStep,
    float iridescenceColorInfluence,
    sampler2D parallaxTex, float4 parallaxTex_ST,
    sampler2D parallaxMaskingTex, float4 parallaxMaskingTex_ST,
    float parallaxMaskSpeed, float parallaxMaskIntensity,
    float3 iridescenceAxesMultiplier, float iridescenceTiling,
    float4 parallaxColor)
{
    float2 baseUv = surface.uv0 * inputUvMultiplier;
    float4 timeValue = GetTime(timeOffset);
    float3 cameraPosition = GetStereoAwareCameraPosition();
    float3 directionToCamera = normalize(surface.worldPosition - cameraPosition);
    #if defined(_PARALLAX_FLEXIBLE_REFLECTED)
    float3 parallaxDirection = directionToCamera -
        2.0 * dot(directionToCamera, surface.normalWS) * surface.normalWS;
    #else
    float3 parallaxDirection = directionToCamera;
    #endif

    // Iridescence hue-shift and per-layer color live in Iridescence.hlsl;
    // the reflected-direction variant is selected by _PARALLAX_FLEXIBLE_REFLECTED.
    float3 hueShift = ResolveIridescence(
        directionToCamera, surface.normalWS,
        iridescenceAxesMultiplier, iridescenceTiling);

    #if defined(SECONDARY_UVS_PARALLAX) && USE_SECONDARY_UV
    float2 parallaxUv = TransformSecondaryUv(surface, parallaxTex_ST);
    #else
    float2 parallaxUv = baseUv * parallaxTex_ST.xy + parallaxTex_ST.zw;
    #endif
    parallaxUv += timeValue.x * parallaxTexSpeed * parallaxTex_ST.xy;

    float3 layerColor = float3(0.0, 0.0, 0.0);
    for (float layer = 0.0; layer < layers; layer += 1.0)
    {
        float layerIndex = floor(layer);
        float offset = offsetStep * layerIndex + startOffset;
        float2 sampleUv = offset.xx * parallaxDirection.xy + parallaxUv;
        float4 parallaxSample = tex2D(parallaxTex, sampleUv);

        float3 layerIridescence = ResolveIridescenceLayerColor(hueShift, layerIndex);

        float intensity = (parallaxIntensityStep * layerIndex + parallaxIntensity) *
            parallaxSample.x;
        layerColor += intensity * layerIridescence;
    }
    #if defined(_PARALLAX_MASKING_VERTEX_COLOR)
    layerColor *= vertexColor.g;
    #elif defined(_PARALLAX_MASKING_TEXTURE)
    float4 maskSample = tex2D(
        parallaxMaskingTex,
        TRANSFORM_TEX(baseUv, parallaxMaskingTex) + parallaxMaskSpeed * timeValue.y);
    layerColor = lerp(layerColor, layerColor * maskSample.r, parallaxMaskIntensity);
    #endif
    #if defined(PARALLAX_IRIDESCENCE)
    float grayscaleLayer = (layerColor.r + layerColor.g + layerColor.b) * 0.5;
    float3 blended = iridescenceColorInfluence.xxx *
        (grayscaleLayer.xxx * parallaxColor.rgb - layerColor) + layerColor;
    result.rgb += blended * parallaxColor.a;
    #else
    result.rgb += layerColor * parallaxColor.rgb;
    #endif
    return result;
}

#endif
