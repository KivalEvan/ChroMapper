#ifndef CHROMAPPER_RIM_LIGHT_INCLUDED
#define CHROMAPPER_RIM_LIGHT_INCLUDED

// Rim light helpers. Per-material inputs are passed in as arguments. The
// consumer shader decides which rim-light mode to use by calling one or the other.

#include "Camera.hlsl"

inline float CalculateRimLightMask(
    float3 worldPosition, float3 normalWS, float rimLightEdgeStart,
    float3 rimPerpendicularAxis)
{
    float3 cameraPosition = GetStereoAwareCameraPosition();
    float3 viewDirection = normalize(worldPosition - cameraPosition);
    float rimLight = 1.0 - abs(dot(normalWS, viewDirection));
    rimLight = smoothstep(0.0, 1.0, saturate(
        (rimLight - rimLightEdgeStart) / max(1.0 - rimLightEdgeStart, 0.00001)));
    #if defined(DIRECTIONAL_RIM)
    float3 directionalAxis = normalize(
        rimPerpendicularAxis + (dot(rimPerpendicularAxis, rimPerpendicularAxis) < 0.00001 ?
            float3(0.0, 1.0, 0.0) : float3(0.0, 0.0, 0.0)));
    rimLight *= 1.0 - abs(dot(normalWS, directionalAxis));
    #endif
    return rimLight;
}

inline float3 ResolveRimLightTarget(
    float3 rimColor, float rimScale, float rimLight,
    float rimLightWhiteboostMultiplier,
    float baseColorBoost, float baseColorBoostThreshold)
{
    float3 target = rimColor * rimScale;
    #if defined(_RIM_WHITEBOOSTTYPE_MAINEFFECT) && !defined(POST_BLOOM)
    float whiteBoost = rimLight * rimScale;
    whiteBoost = whiteBoost * whiteBoost * baseColorBoost - baseColorBoostThreshold;
    target = saturate(target + whiteBoost) * rimLightWhiteboostMultiplier;
    #endif
    return target;
}

inline float4 ApplyAdditiveRimLight(
    float4 result, float3 worldPosition, float3 normalWS,
    float rimLightEdgeStart, float4 rimLightColor,
    float rimLightIntensity, float rimLightBloomIntensity,
    float3 rimPerpendicularAxis, float rimLightWhiteboostMultiplier,
    float baseColorBoost, float baseColorBoostThreshold)
{
    float rimLight = CalculateRimLightMask(
        worldPosition, normalWS, rimLightEdgeStart, rimPerpendicularAxis);
    float rimLightScale = rimLightColor.a * rimLightIntensity;
    float3 rimTarget = ResolveRimLightTarget(
        rimLightColor.rgb, rimLightScale, rimLight,
        rimLightWhiteboostMultiplier, baseColorBoost, baseColorBoostThreshold);
    result.rgb += rimTarget * rimLight * rimLightScale;
    result.a = rimLight * rimLightScale * rimLightBloomIntensity;
    return result;
}

inline float4 ApplyRimLight(
    float4 result, float3 worldPosition, float3 normalWS,
    float rimLightEdgeStart, float4 rimLightColor,
    float rimLightIntensity, float rimLightBloomIntensity,
    float3 rimPerpendicularAxis, float rimLightWhiteboostMultiplier,
    float baseColorBoost, float baseColorBoostThreshold)
{
    float rimLight = CalculateRimLightMask(
        worldPosition, normalWS, rimLightEdgeStart, rimPerpendicularAxis);
    float rimLightScale = rimLightColor.a * rimLightIntensity;
    float3 rimTarget = ResolveRimLightTarget(
        rimLightColor.rgb, rimLightScale, rimLight,
        rimLightWhiteboostMultiplier, baseColorBoost, baseColorBoostThreshold);
    result.rgb = lerp(result.rgb, rimTarget, rimLight);
    result.a = rimLightScale * rimLight * rimLightBloomIntensity;
    return result;
}

#endif
