#ifndef CHROMAPPER_POST_PROCESS_INCLUDED
#define CHROMAPPER_POST_PROCESS_INCLUDED

// Post-process effects that are not fog: distance darkening and blue-noise
// dithering. Fog functions live in Fog.hlsl; rim light lives in RimLight.hlsl.
// The consumer shader decides which effect applies by calling the
// corresponding function.

inline float CalculateSourceDistanceDarkening(
    float3 worldPosition, float3 darkeningCenter, float3 darkeningDirection,
    float darkeningScale, float darkeningIntensity)
{
    float3 offset = darkeningCenter - worldPosition;
    float weightedDistance = dot(
        offset * offset, darkeningDirection * float3(0.0001, 0.0001, 0.0001));
    return 1.0 - saturate(weightedDistance * darkeningScale) * darkeningIntensity;
}

inline float4 ApplyNoiseDither(
    float4 result, float4 noiseScreenPosition, sampler2D globalBlueNoiseTex)
{
    float2 noiseUv = noiseScreenPosition.xy / noiseScreenPosition.ww;
    float noise = tex2D(globalBlueNoiseTex, noiseUv).r - 0.5;
    result.rgb += noise.xxx * (1.0 / 255.0);
    return result;
}

inline float4 ScaleNoiseScreenPosition(float4 screenPosition, float2 noiseScale)
{
    screenPosition.xy *= noiseScale;
    return screenPosition;
}

inline float4 BuildNoiseScreenPosition(
    float4 screenPosition, float4 clipPosition, float2 noiseScale,
    float randomValue, float2 objectTranslation)
{
    screenPosition.xy *= noiseScale;
    screenPosition.xy += clipPosition.w * randomValue + objectTranslation;
    screenPosition.zw = clipPosition.zw;
    return screenPosition;
}

inline float3 ApplyNoiseDitherMasked(
    float3 result, float4 noiseScreenPosition, sampler2D globalBlueNoiseTex, float mask)
{
    float2 noiseUv = noiseScreenPosition.xy / noiseScreenPosition.ww;
    float noise = tex2D(globalBlueNoiseTex, noiseUv).r - 0.5;
    return result + noise.xxx * (1.0 / 255.0) * mask;
}

inline float4 ApplyHighlightSelection(
    float4 result, float3 worldPosition, float4 timeValue, float selectionMask)
{
    float pulse = frac(timeValue.w * 0.15 + worldPosition.x * 0.2 + worldPosition.y);
    pulse = max(1.0 - pulse * 5.0, 0.0);
    pulse = pulse * pulse * (3.0 - 2.0 * pulse);
    pulse *= saturate(100.0 - 100.0 * pulse);
    pulse = saturate(0.4 * pulse * pulse * selectionMask);
    result.rgb += pulse;
    return result;
}

#endif
