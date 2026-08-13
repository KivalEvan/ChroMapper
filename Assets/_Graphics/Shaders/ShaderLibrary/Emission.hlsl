#ifndef CHROMAPPER_EMISSION_INCLUDED
#define CHROMAPPER_EMISSION_INCLUDED

#include "Data.hlsl"
#include "CustomTime.hlsl"
#include "CustomBloom.hlsl"
#include "Surface.hlsl"

// Per-material emission inputs are passed in as arguments; the library does not
// read uniforms the consumer shader must declare.

inline float4 ResolveTime(float timeOffset)
{
    return GetTime(timeOffset);
}

inline float2 SampleSimpleEmissionRaw(
    SurfaceData surface, float4 timeValue, float2 inputUvMultiplier,
    sampler2D emissionTex, float4 emissionTex_ST, float2 emissionTexSpeed)
{
    #if defined(SECONDARY_UVS_EMISSION)
    float2 baseUv = surface.uv1;
    #else
    float2 baseUv = surface.uv0 * inputUvMultiplier;
    #endif
    float2 emissionUv = baseUv * emissionTex_ST.xy + emissionTex_ST.zw;
    emissionUv += timeValue.xx * emissionTexSpeed * emissionTex_ST.xy;
    return tex2D(emissionTex, emissionUv).rg;
}

inline float2 SampleDistortedSimpleEmissionRaw(
    SurfaceData surface, float4 timeValue, float2 inputUvMultiplier,
    sampler2D emissionTex, float4 emissionTex_ST, float2 emissionTexSpeed,
    sampler2D distortionTex, float4 distortionTex_ST, float2 distortionPanning,
    float2 distortionAxes, float distortionStrength)
{
    #if defined(SECONDARY_UVS_EMISSION)
    float2 baseUv = surface.uv1;
    #else
    float2 baseUv = surface.uv0 * inputUvMultiplier;
    #endif
    float2 distortionUv = baseUv * distortionTex_ST.xy + distortionTex_ST.zw;
    distortionUv += timeValue.yy * distortionPanning * distortionTex_ST.xy * 0.1;
    float2 distortion = tex2D(distortionTex, distortionUv).rg;
    distortion = distortion * distortionStrength * 0.1 * distortionAxes * 2.0 - 1.0;
    float2 emissionUv = (baseUv + distortion) * emissionTex_ST.xy + emissionTex_ST.zw;
    emissionUv += timeValue.xx * emissionTexSpeed * emissionTex_ST.xy;
    return tex2D(emissionTex, emissionUv).rg;
}

inline float2 SamplePulseEmissionRaw(
    SurfaceData surface, float4 timeValue, float2 inputUvMultiplier,
    sampler2D pulseMask, float4 pulseMask_ST,
    float pulseWidth, float pulseSpeed, float pulseSmooth)
{
    #if defined(SECONDARY_UVS_PULSE)
    float2 baseUv = surface.uv1;
    #else
    float2 baseUv = surface.uv0 * inputUvMultiplier;
    #endif
    float2 pulseUv = baseUv * pulseMask_ST.xy + pulseMask_ST.zw;
    float pulseTexture = tex2D(pulseMask, pulseUv).r;
    #if defined(INVERT_PULSE)
    pulseTexture = 1.0 - pulseTexture;
    #endif
    float pulsePhase = frac(pulseTexture - timeValue.x * pulseSpeed);
    float pulseDistance = min(pulsePhase, 1.0 - pulsePhase);
    float pulse = 1.0 - smoothstep(
        max(pulseWidth, 0.0), max(pulseWidth + pulseSmooth, 0.00001),
        pulseDistance);
    #if defined(PULSE_MULTIPLY_TEXTURE)
    pulse *= pulseTexture;
    #endif
    return pulse.xx;
}

inline float2 ApplyPrimaryEmissionMask(
    SurfaceData surface, float4 timeValue, float2 emissionInput,
    float2 inputUvMultiplier, sampler2D emissionMask, float4 emissionMask_ST,
    float2 emissionMaskSpeed, float emissionMaskIntensity,
    float secondaryEmissionMaskIntensity)
{
    #if defined(SECONDARY_UVS_EMISSION_MASK)
    float2 maskBaseUv = surface.uv1;
    #else
    float2 maskBaseUv = surface.uv0 * inputUvMultiplier;
    #endif
    float2 maskUv = maskBaseUv * emissionMask_ST.xy + emissionMask_ST.zw;
    maskUv += timeValue.xx * emissionMaskSpeed * emissionMask_ST.xy;
    float2 mask = tex2D(emissionMask, maskUv).rg;
    #if defined(_MASKBLEND_ADD)
    emissionInput += mask * emissionMaskIntensity;
    #elif defined(_MASKBLEND_MASKED_ADD)
    emissionInput += emissionInput * mask * emissionMaskIntensity;
    #else
    #if defined(TEXTURE3D_LOOKUP) && defined(TEXTURE3D_EMISSION)
    emissionInput *= mask * emissionMaskIntensity +
        (1.0 - secondaryEmissionMaskIntensity);
    #else
    emissionInput *= mask * emissionMaskIntensity + (1.0 - emissionMaskIntensity);
    #endif
    #endif
    return emissionInput;
}

inline EmissionData ResolveVertexEmission(
    float4 vertexColor, float4 emissionColor,
    float emissionThreshold, float emissionStrength,
    float baseColorBoost, float baseColorBoostThreshold,
    float questWhiteboostMultiplier, float emissionBloomIntensity)
{
    float threshold = saturate((vertexColor.g - emissionThreshold) /
        (1.0 - emissionThreshold));
    threshold = threshold * threshold * (3.0 - 2.0 * threshold) * emissionStrength;
    EmissionData emission = InitializeEmissionData();
    #if defined(_VERTEX_WHITEBOOSTTYPE_MAINEFFECT) || \
        defined(_VERTEX_WHITEBOOSTTYPE_ALWAYS)
    float4 squaredEmissionColor = emissionColor * emissionColor;
    float whiteBoost = threshold * squaredEmissionColor.a * vertexColor.a;
    whiteBoost = whiteBoost * whiteBoost * baseColorBoost - baseColorBoostThreshold;
    emission.color = saturate(squaredEmissionColor.rgb * threshold + whiteBoost) *
        questWhiteboostMultiplier;
    #else
    emission.color = emissionColor.rgb * emissionColor.a * threshold;
    #endif
    emission.bloomAlpha = vertexColor.a * vertexColor.a * emissionColor.a *
        emissionBloomIntensity;
    return emission;
}

inline float ResolveSdfField(
    float3 worldPosition, float timeOffset,
    float4 sdfPointArray[3], float sdfNegativeIntensity, float sdfPointIntensity,
    float sdfNoiseScale, float3 sdfNoisePanning, float3 sdfNoiseOffset,
    float sdfNoiseIntensity, sampler3D sdfNoiseTex)
{
    float sdfMask = 1.0;
    float sdfAccumulator = 0.0;
    for (int pointIndex = 0; pointIndex < 3; pointIndex++)
    {
        float3 pointOffset = worldPosition - sdfPointArray[pointIndex].xyz;
        float distanceSquared = dot(pointOffset, pointOffset);
        float pointDistance = pow(2.0, log(distanceSquared) * 0.25);
        float isPositive = sdfPointArray[pointIndex].w > 0.0 ? 1.0 : 0.0;
        float isNegative = sdfPointArray[pointIndex].w < 0.0 ? 1.0 : 0.0;
        float pointSign = floor(isNegative - isPositive);
        float pointIntensity = pointSign < 0.0 ?
            sdfNegativeIntensity : sdfPointIntensity;
        float pointDistanceField = max(
            abs(sdfPointArray[pointIndex].w) - pointDistance, 0.0);
        float accumulated = pointDistanceField * pointIntensity + sdfAccumulator;
        float occlusion = saturate(-pointDistanceField * pointIntensity + 1.0);
        float masked = sdfMask * occlusion;
        if (pointSign >= 0.0)
            sdfAccumulator = accumulated;
        else
            sdfMask = masked;
    }
    float3 noiseUv = sdfNoiseScale.xxx * worldPosition;
    noiseUv += sdfNoisePanning * timeOffset + sdfNoiseOffset;
    return sdfAccumulator * sdfMask +
        tex3D(sdfNoiseTex, noiseUv).r * sdfNoiseIntensity;
}

inline float3 ResolveGradientEmission(
    float2 emissionInput, float frozenTime,
    float gradientPosition, float gradientPanningSpeed,
    sampler2D gradientTex, float4 gradientTex_ST, float gradientIntensity,
    out float resolvedGradientIntensity)
{
    float gradientPhase = frac(
        gradientPanningSpeed * frozenTime + gradientPosition);
    float2 gradientUv = float2(emissionInput.y, gradientPhase) *
        gradientTex_ST.xy;
    float3 gradient = tex2D(gradientTex, gradientUv).rgb;
    resolvedGradientIntensity = gradientIntensity;
    return gradientIntensity * saturate(emissionInput.x * gradient);
}

inline EmissionData ResolvePlainEmission(
    float2 emissionInput, float4 emissionColor, float emissionTexBloomIntensity)
{
    EmissionData emission = InitializeEmissionData();
    emission.color = emissionInput.r * emissionColor.rgb * emissionColor.a;
    emission.bloomAlpha = emissionInput.g * emissionInput.g * emissionColor.a *
        3.5 * emissionTexBloomIntensity;
    return emission;
}

inline EmissionData ResolveFlipbookEmission(
    float2 flipbookUv, float4 frameSelector,
    sampler2D emissionTex, float4 emissionTex_ST,
    float emissionBrightness, float4 emissionTexColor,
    float emissionTexBloomIntensity)
{
    float2 emissionUv = flipbookUv * emissionTex_ST.xy + emissionTex_ST.zw;
    float emissionInput = dot(tex2D(emissionTex, emissionUv), frameSelector) *
        emissionBrightness;
    return ResolvePlainEmission(
        emissionInput.xx, emissionTexColor, emissionTexBloomIntensity);
}

inline float2 ApplySecondaryEmissionMask(
    SurfaceData surface, float4 timeValue, float2 emissionInput,
    float2 inputUvMultiplier, sampler2D secondaryEmissionMask,
    float4 secondaryEmissionMask_ST, float2 secondaryEmissionMaskSpeed,
    float secondaryEmissionMaskIntensity, float occlusionDetailIntensity)
{
    #if defined(SECONDARY_UVS_EMISSION_MASK2)
    float2 maskBaseUv = surface.uv1;
    #else
    float2 maskBaseUv = surface.uv0 * inputUvMultiplier;
    #endif
    float2 maskUv = maskBaseUv * secondaryEmissionMask_ST.xy +
        secondaryEmissionMask_ST.zw;
    maskUv += timeValue.xx * secondaryEmissionMaskSpeed *
        secondaryEmissionMask_ST.xy;
    float2 mask = tex2D(secondaryEmissionMask, maskUv).rg;
    #if defined(_SECONDARY_MASK_BLEND_ADD)
    emissionInput += mask * secondaryEmissionMaskIntensity;
    #elif defined(_SECONDARY_MASK_BLEND_MASKED_ADD)
    emissionInput += emissionInput * mask * secondaryEmissionMaskIntensity;
    #else
    #if defined(TEXTURE3D_LOOKUP) && defined(TEXTURE3D_EMISSION)
    emissionInput *= mask * secondaryEmissionMaskIntensity +
        (1.0 - occlusionDetailIntensity);
    #else
    emissionInput *= mask * secondaryEmissionMaskIntensity +
        (1.0 - secondaryEmissionMaskIntensity);
    #endif
    #endif
    return emissionInput;
}

inline EmissionData ResolveMainEffectEmission(
    float2 emissionInput, float4 emissionColor,
    float emissionTexWhiteBoostMultiplier, float emissionTexBloomIntensity,
    float baseColorBoost, float baseColorBoostThreshold)
{
    float4 configured = calculate_main_effect_emission(
        emissionInput.r, emissionInput.g, emissionColor,
        emissionTexWhiteBoostMultiplier, emissionTexBloomIntensity,
        baseColorBoost, baseColorBoostThreshold);
    EmissionData emission = InitializeEmissionData();
    emission.color = configured.rgb;
    emission.bloomAlpha = configured.a;
    return emission;
}

inline EmissionData ResolveFeatureEmission(
    SurfaceData surface, float4 timeValue, float2 colorArrayId,
    float emissionAngle, float lookupEmission,
    float2 inputUvMultiplier, float emissionBrightness,
    sampler2D emissionTex, float4 emissionTex_ST, float2 emissionTexSpeed,
    sampler2D pulseMask, float4 pulseMask_ST,
    float pulseWidth, float pulseSpeed, float pulseSmooth,
    float emissionTexBloomIntensity,
    sampler2D distortionTex, float4 distortionTex_ST, float2 distortionPanning,
    float2 distortionAxes, float distortionStrength,
    sampler2D emissionMask, float4 emissionMask_ST, float2 emissionMaskSpeed,
    float emissionMaskIntensity,
    sampler2D secondaryEmissionMask, float4 secondaryEmissionMask_ST,
    float2 secondaryEmissionMaskSpeed, float secondaryEmissionMaskIntensity,
    float occlusionDetailIntensity,
    float emissionGradientPosition, float emissionGradientPanningSpeed,
    sampler2D emissionGradientTex, float4 emissionGradientTex_ST,
    float emissionGradientIntensity,
    float4 sdfPointArray[3], float sdfNegativeIntensity,
    float sdfPointIntensity, float sdfNoiseScale, float3 sdfNoisePanning,
    float3 sdfNoiseOffset, float sdfNoiseIntensity, sampler3D sdfNoiseTex,
    float4 colorsArray[200], float4 emissionTexColor,
    float emissionTexWhiteBoostMultiplier, float baseColorBoost,
    float baseColorBoostThreshold)
{
    float2 emissionInput = 0.0;
    #if defined(_EMISSION_TEXTURE_SOURCE_MPM_G) && defined(METAL_SMOOTHNESS_TEXTURE)
    emissionInput = surface.mpm.gg;
    #elif defined(_EMISSION_TEXTURE_SOURCE_SDF)
    float sdfEmission = ResolveSdfField(
        surface.worldPosition, timeValue.y, sdfPointArray, sdfNegativeIntensity,
        sdfPointIntensity, sdfNoiseScale, sdfNoisePanning, sdfNoiseOffset,
        sdfNoiseIntensity, sdfNoiseTex);
    emissionInput = sdfEmission.xx;
    #elif defined(_EMISSIONTEXTURE_PULSE)
    emissionInput = SamplePulseEmissionRaw(
        surface, timeValue, inputUvMultiplier,
        pulseMask, pulseMask_ST, pulseWidth, pulseSpeed, pulseSmooth);
    #elif defined(_EMISSIONTEXTURE_SIMPLE)
    #if defined(DISTORTION_SIMPLE) && \
        defined(_DISTORTION_TARGET_EMISSIONTEX)
    emissionInput = SampleDistortedSimpleEmissionRaw(
        surface, timeValue, inputUvMultiplier,
        emissionTex, emissionTex_ST, emissionTexSpeed,
        distortionTex, distortionTex_ST, distortionPanning, distortionAxes,
        distortionStrength);
    #else
    emissionInput = SampleSimpleEmissionRaw(
        surface, timeValue, inputUvMultiplier,
        emissionTex, emissionTex_ST, emissionTexSpeed);
    #endif
    #endif

    #if defined(ENABLE_EMISSION_ANGLE_DISAPPEAR)
    emissionInput *= emissionAngle;
    #endif

    #if defined(_EMISSION_ALPHA_SOURCE_COPY_EMISSION)
    emissionInput.y = emissionInput.x;
    #elif defined(_EMISSION_ALPHA_SOURCE_MPM_R) && defined(METAL_SMOOTHNESS_TEXTURE)
    emissionInput.y = surface.mpm.r;
    #endif
    #if defined(EMISSION_MASK)
    emissionInput = ApplyPrimaryEmissionMask(
        surface, timeValue, emissionInput, inputUvMultiplier,
        emissionMask, emissionMask_ST, emissionMaskSpeed, emissionMaskIntensity,
        secondaryEmissionMaskIntensity);
    #endif
    #if defined(SECONDARY_EMISSION_MASK)
    emissionInput = ApplySecondaryEmissionMask(
        surface, timeValue, emissionInput, inputUvMultiplier,
        secondaryEmissionMask, secondaryEmissionMask_ST,
        secondaryEmissionMaskSpeed, secondaryEmissionMaskIntensity,
        occlusionDetailIntensity);
    #endif
    emissionInput *= emissionBrightness;

    #if defined(COLOR_ARRAY)
    float colorIndex = round(colorArrayId.x * 10.0 + colorArrayId.y);
    float4 emissionColor = colorsArray[colorIndex];
    #else
    float4 emissionColor = emissionTexColor;
    #endif
    #if defined(TEXTURE3D_LOOKUP) && defined(TEXTURE3D_EMISSION)
    emissionColor.a *= lookupEmission;
    #endif

    #if defined(_EMISSIONCOLORTYPE_GRADIENT)
    EmissionData emission = InitializeEmissionData();
    float gradientIntensity;
    emission.color = ResolveGradientEmission(
        emissionInput, timeValue.x, emissionGradientPosition,
        emissionGradientPanningSpeed, emissionGradientTex,
        emissionGradientTex_ST, emissionGradientIntensity, gradientIntensity);
    emission.bloomAlpha = emissionTexBloomIntensity * gradientIntensity;
    return emission;
    #elif defined(_EMISSIONCOLORTYPE_MAINEFFECT) || \
        defined(_EMISSIONCOLORTYPE_WHITEBOOST)
    return ResolveMainEffectEmission(
        emissionInput, emissionColor, emissionTexWhiteBoostMultiplier,
        emissionTexBloomIntensity, baseColorBoost, baseColorBoostThreshold);
    #else
    return ResolvePlainEmission(
        emissionInput, emissionColor, emissionTexBloomIntensity);
    #endif
}

inline float4 ComposeEmission(float4 result, EmissionData emission)
{
    result.rgb += emission.color;
    result.a = emission.bloomAlpha;
    return result;
}

#endif
