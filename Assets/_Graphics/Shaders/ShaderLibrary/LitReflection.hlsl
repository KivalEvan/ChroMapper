#ifndef CHROMAPPER_LIT_REFLECTION_INCLUDED
#define CHROMAPPER_LIT_REFLECTION_INCLUDED

#include "Data.hlsl"
#include "CustomLighting.hlsl"

// All per-material reflection inputs are passed in as arguments; the library
// does not read uniforms the consumer shader must declare.

inline float3 DecodeReflectionProbeChannel(float channel, float4 lightBakeId)
{
    float low = min(channel, 0.5);
    float high = max(channel - 0.5, 0.0) * lightBakeId.w;
    return low * lightBakeId.rgb + high * high;
}

inline float3 DecodeReflectionProbePair(
    float3 probe1, float3 probe2,
    float4 lightProbeLightBakeIdA, float4 lightProbeLightBakeIdB,
    float4 lightProbeLightBakeIdC, float4 lightProbeLightBakeIdD,
    float4 lightProbeLightBakeIdE, float4 lightProbeLightBakeIdF,
    float reflectionProbeIntensity)
{
    float3 decoded = DecodeReflectionProbeChannel(probe1.r, lightProbeLightBakeIdA);
    decoded += DecodeReflectionProbeChannel(probe1.g, lightProbeLightBakeIdB);
    decoded = DecodeReflectionProbeChannel(probe1.b, lightProbeLightBakeIdC) + decoded;
    decoded += DecodeReflectionProbeChannel(probe2.r, lightProbeLightBakeIdD);
    decoded = DecodeReflectionProbeChannel(probe2.g, lightProbeLightBakeIdE) + decoded;
    decoded = DecodeReflectionProbeChannel(probe2.b, lightProbeLightBakeIdF) + decoded;
    return saturate(decoded * 2.0) * reflectionProbeIntensity;
}

inline float3 SampleReflectionProbePairLod(
    float3 reflectionDirection, float reflectionLod,
    samplerCUBE reflectionProbeTexture1, samplerCUBE reflectionProbeTexture2,
    float4 lightProbeLightBakeIdA, float4 lightProbeLightBakeIdB,
    float4 lightProbeLightBakeIdC, float4 lightProbeLightBakeIdD,
    float4 lightProbeLightBakeIdE, float4 lightProbeLightBakeIdF,
    float reflectionProbeIntensity)
{
    float3 probe1 = texCUBElod(
        reflectionProbeTexture1, float4(reflectionDirection, reflectionLod)).rgb;
    float3 probe2 = texCUBElod(
        reflectionProbeTexture2, float4(reflectionDirection, reflectionLod)).rgb;
    return DecodeReflectionProbePair(
        probe1, probe2,
        lightProbeLightBakeIdA, lightProbeLightBakeIdB,
        lightProbeLightBakeIdC, lightProbeLightBakeIdD,
        lightProbeLightBakeIdE, lightProbeLightBakeIdF,
        reflectionProbeIntensity);
}

inline float3 SampleReflectionProbePair(
    float3 reflectionDirection, float smoothness,
    samplerCUBE reflectionProbeTexture1, samplerCUBE reflectionProbeTexture2,
    float4 lightProbeLightBakeIdA, float4 lightProbeLightBakeIdB,
    float4 lightProbeLightBakeIdC, float4 lightProbeLightBakeIdD,
    float4 lightProbeLightBakeIdE, float4 lightProbeLightBakeIdF,
    float reflectionProbeIntensity)
{
    float roughness = 1.0 - smoothness;
    float reflectionLod = roughness * (1.7 - 0.7 * roughness) * 6.0;
    return SampleReflectionProbePairLod(
        reflectionDirection, reflectionLod,
        reflectionProbeTexture1, reflectionProbeTexture2,
        lightProbeLightBakeIdA, lightProbeLightBakeIdB,
        lightProbeLightBakeIdC, lightProbeLightBakeIdD,
        lightProbeLightBakeIdE, lightProbeLightBakeIdF,
        reflectionProbeIntensity);
}

inline float CalculateLitReflectionTextureRimDim(
    float3 worldPosition, float rimFactor,
    float rimDistanceOffset, float rimDistanceScale, float rimScale)
{
    float3 cameraPosition = GetStereoAwareCameraPosition();
    float cameraDistance = length(worldPosition - cameraPosition);
    float rimDistance = max(cameraDistance - rimDistanceOffset, 0.0) *
        rimDistanceScale + rimScale;
    return rimDistance * rimFactor;
}

inline float3 ResolveLitReflectionTexture(
    SurfaceData surface, float3 reflectionDirection, float rimDim,
    samplerCUBE environmentReflectionCube, float reflectionTexIntensity,
    float rimSmoothness, float rimDarkening)
{
    float smoothness = surface.smoothness;
#if defined(RIM_DIM)
smoothness= saturate(smoothness- rimDim* rimSmoothness);
#endif

float roughness = 1.0 - smoothness;
float reflectionLod = roughness * (1.7 - 0.7 * roughness) * 6.0;
float3 reflection = texCUBElod(
    environmentReflectionCube,
    float4(reflectionDirection, reflectionLod)).rgb;
reflection*= reflectionTexIntensity;
#if defined(MULTIPLY_REFLECTIONS)
reflection*= 1.0 + surface.metallic* (surface.baseColor.rgb- 1.0);
#endif
reflection*= 2.0 * (surface.metallic*0.8 + 0.2);
reflection*= smoothness;
#if defined(RIM_DIM)
reflection*= 1.0 - rimDim* rimDarkening;
#endif
return reflection;
}

inline float CalculateNormalGradient(float3 normalWS)
{
    float3 normalDx = ddx(normalWS);
    float3 normalDy = ddy(normalWS);
    return min(max(dot(normalDx, normalDx), dot(normalDy, normalDy)), 1.0);
}

inline float3 BoxProjectReflectionDirection(
    float3 reflectionDirection, float3 worldPosition,
    float3 boundsMin, float3 boundsMax, float3 probePosition)
{
    float3 intersectionBounds;
    intersectionBounds.x = reflectionDirection.x > 0.0 ? boundsMax.x : boundsMin.x;
    intersectionBounds.y = reflectionDirection.y > 0.0 ? boundsMax.y : boundsMin.y;
    intersectionBounds.z = reflectionDirection.z > 0.0 ? boundsMax.z : boundsMin.z;
    float3 intersectionFactors = (intersectionBounds - worldPosition) / reflectionDirection;
    float intersectionDistance = min(intersectionFactors.x,
                                     min(intersectionFactors.y, intersectionFactors.z));
    return reflectionDirection * intersectionDistance + worldPosition - probePosition;
}

inline float3 ResolveUnityReflectionProbe(
    SurfaceData surface, float3 reflectionNormal, float reflectionProbeIntensity,
    float3 boxProjectionSizeOffset, float3 boxProjectionPositionOffset)
{
    float3 reflectionDirection = CalculateViewReflectionDirection(
        surface.worldPosition, reflectionNormal);
    #if defined(REFLECTION_PROBE_BOX_PROJECTION)
    float3 boundsMin = unity_SpecCube0_BoxMin.xyz;
    float3 boundsMax = unity_SpecCube0_BoxMax.xyz;
    float3 probePosition = unity_SpecCube0_ProbePosition.xyz;
    #if defined(REFLECTION_PROBE_BOX_PROJECTION_OFFSET)
    boundsMin -= boxProjectionSizeOffset;
    boundsMax += boxProjectionSizeOffset;
    probePosition += boxProjectionPositionOffset;
    #endif
    if (unity_SpecCube0_ProbePosition.w > 0.0)
    {
        reflectionDirection = BoxProjectReflectionDirection(
            reflectionDirection, surface.worldPosition,
            boundsMin, boundsMax, probePosition);
    }
    #endif

    float roughness = 1.0 - surface.smoothness;
    float reflectionLod = roughness * (1.7 - 0.7 * roughness) * 6.0;
    half4 encodedReflection = UNITY_SAMPLE_TEXCUBE_LOD(
        unity_SpecCube0, reflectionDirection, reflectionLod);
    float3 reflection = DecodeHDR(encodedReflection, unity_SpecCube0_HDR);
    reflection *= reflectionProbeIntensity;
    reflection *= 1.0 + surface.metallic * (surface.baseColor.rgb - 1.0);
    reflection *= 2.0 * (surface.metallic * 0.8 + 0.2);
    reflection *= surface.smoothness;
    return reflection;
}

inline float CalculateComposableReflectionSmoothness(
    SurfaceData surface, float3 reflectionNormal, float rimDim,
    float rimSmoothness,
    float antiflickerDistanceOffset, float antiflickerDistanceScale,
    float antiflickerStrength)
{
    float smoothness = surface.smoothness;
    #if defined(RIM_DIM)
    smoothness = saturate(smoothness - rimDim * rimSmoothness);
    #endif
    #if defined(SPECULAR_ANTIFLICKER)
    float3 cameraPosition = GetStereoAwareCameraPosition();
    float cameraDistance = length(surface.worldPosition - cameraPosition);
    float weight = saturate(
            (antiflickerDistanceOffset - cameraDistance) * antiflickerDistanceScale) *
        antiflickerStrength;
    float gradient = CalculateNormalGradient(reflectionNormal);
    float filteredSmoothness = min(1.0 - pow(gradient, 0.333), smoothness);
    smoothness += weight * (filteredSmoothness - smoothness);
    #endif
    return smoothness;
}

inline float3 ResolveLitReflection(
    SurfaceData surface, float3 reflectionNormal, float rimDim,
    samplerCUBE reflectionProbeTexture1, samplerCUBE reflectionProbeTexture2,
    float4 lightProbeLightBakeIdA, float4 lightProbeLightBakeIdB,
    float4 lightProbeLightBakeIdC, float4 lightProbeLightBakeIdD,
    float4 lightProbeLightBakeIdE, float4 lightProbeLightBakeIdF,
    float reflectionProbeIntensity,
    float reflectionProbeGrayscale,
    float coloredMetalMultiplier,
    float whiteOffset,
    float3 reflectionProbeBoundsMin, float3 reflectionProbeBoundsMax,
    float3 reflectionProbePosition,
    float3 reflectionProbeBoxProjectionSizeOffset,
    float3 reflectionProbeBoxProjectionPositionOffset,
    float rimSmoothness, float rimDarkening,
    float antiflickerDistanceOffset, float antiflickerDistanceScale,
    float antiflickerStrength,
    float groundFadeScale, float groundFadeOffset)
{
    #if !defined(REFLECTION_PROBE)
    return 0.0;
    #else
    float smoothness = CalculateComposableReflectionSmoothness(
        surface, reflectionNormal, rimDim, rimSmoothness,
        antiflickerDistanceOffset, antiflickerDistanceScale,
        antiflickerStrength);
    #if defined(REFLECTION_STATIC)
    float3 reflectionDirection = surface.worldPosition + reflectionNormal;
    #else
    float3 reflectionDirection = CalculateViewReflectionDirection(
        surface.worldPosition, reflectionNormal);
    #endif

    #if defined(REFLECTION_PROBE_BOX_PROJECTION)
    float3 boundsMin = reflectionProbeBoundsMin;
    float3 boundsMax = reflectionProbeBoundsMax;
    float3 probePosition = reflectionProbePosition;
    #if defined(REFLECTION_PROBE_BOX_PROJECTION_OFFSET)
    boundsMin -= reflectionProbeBoxProjectionSizeOffset;
    boundsMax += reflectionProbeBoxProjectionSizeOffset;
    probePosition += reflectionProbeBoxProjectionPositionOffset;
    #endif
    reflectionDirection = BoxProjectReflectionDirection(
        reflectionDirection, surface.worldPosition,
        boundsMin, boundsMax, probePosition);
    #endif

    float3 reflection = SampleReflectionProbePair(
        reflectionDirection, smoothness,
        reflectionProbeTexture1, reflectionProbeTexture2,
        lightProbeLightBakeIdA, lightProbeLightBakeIdB,
        lightProbeLightBakeIdC, lightProbeLightBakeIdD,
        lightProbeLightBakeIdE, lightProbeLightBakeIdF,
        reflectionProbeIntensity);
    #if defined(_PROBE_CALCULATION_PRECISE)
    float grayscale = dot(float3(0.33, 0.33, 0.33), reflection);
    float metallicScale = surface.metallic * surface.metallic * 2.5 + 1.0;
    float3 grayscaleDelta = grayscale * metallicScale - reflection;
    float scaledGrayscale = grayscale * metallicScale;
    float minimumColor = min(surface.baseColor.r,
                             min(surface.baseColor.g, surface.baseColor.b));
    float maximumColor = max(surface.baseColor.r,
                             max(surface.baseColor.g, surface.baseColor.b));
    float saturation = (maximumColor - minimumColor) / maximumColor;
    float metallicSaturation = saturation * surface.metallic;
    float grayscaleFactor = max(metallicSaturation, reflectionProbeGrayscale);
    float coloredMetalScale = metallicSaturation * coloredMetalMultiplier + 1.0;
    reflection += grayscaleFactor * grayscaleDelta;
    float metallicFactor = saturate(
        surface.metallic - scaledGrayscale * scaledGrayscale * 0.1);
    metallicFactor *= max(saturation, 0.95);
    #if defined(MULTIPLY_REFLECTIONS)
    reflection *= 1.0 + metallicFactor *
        (surface.baseColor.rgb * coloredMetalScale - 1.0);
    float whiteFactor = (1.0 - saturation) * (1.0 + saturation) * whiteOffset *
        max(coloredMetalMultiplier, 1.0);
    reflection *= max(
        whiteFactor * surface.baseColor.rgb * surface.metallic, 1.0);
    #endif
    reflection *= smoothness;
    #if defined(RIM_DIM)
    reflection *= 1.0 - rimDim * rimDarkening;
    #endif
    return reflection;
    #else
    float groundFade = 1.0;
    float3 reflectionBaseColor = surface.baseColor.rgb;
    #if defined(GROUND_FADE)
    groundFade = 1.0 - saturate(
        -surface.worldPosition.y * groundFadeScale + groundFadeOffset);
    reflectionBaseColor *= groundFade;
    #endif
    #if defined(MULTIPLY_REFLECTIONS)
    reflection *= 1.0 + surface.metallic * (reflectionBaseColor - 1.0);
    #endif
    reflection *= 2.0 * (surface.metallic * 0.8 + 0.2);
    reflection *= smoothness * groundFade;
    #if defined(RIM_DIM)
    reflection *= 1.0 - rimDim * rimDarkening;
    #endif
    return reflection;
    #endif
    #endif
}

#endif
