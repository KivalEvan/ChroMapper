#ifndef CHROMAPPER_DISSOLVE_INCLUDED
#define CHROMAPPER_DISSOLVE_INCLUDED

// Dissolve inputs are passed in by value; the library does not read
// uniforms the consumer shader must declare.

inline float ResolveDissolve(
    float3 worldPosition, float2 uv, float timeValue, float facing,
    float3 axisVector, float offset, float progress, float startValue, float endValue,
    float invert, float cutColorFalloff, float cutColorBacksideFalloff,
    float dissolveColorAlpha,
    sampler2D dissolveTexture, float4 dissolveTexture_ST,
    float2 dissolveTextureSpeed, float dissolveTextureInfluence)
{
    float3 axis = normalize(axisVector);
    #if defined(DISSOLVE_PROGRESS)
    float direction = progress < -0.001 ? -1.0 : 1.0;
    axis *= direction;
    float threshold = abs(progress) * (endValue - startValue) + startValue;
    #else
    float threshold = offset;
    #endif

    #if defined(_DISSOLVE_SPACE_WORLD_CENTERED)
    float3 localOffset = worldPosition - unity_ObjectToWorld._m03_m13_m23;
    #else
    float3 localOffset = worldPosition;
    #endif
    float projected = dot(localOffset, axis);
    float dissolveValue = projected - threshold;
    #if defined(DISSOLVE_TEXTURE)
    float2 dissolveUv = uv * dissolveTexture_ST.xy + dissolveTexture_ST.zw;
    dissolveUv += timeValue.xx * dissolveTextureSpeed * dissolveTexture_ST.xy;
    float textureOffset = tex2D(dissolveTexture, dissolveUv).r * 2.0 - 1.0;
    dissolveValue += textureOffset * dissolveTextureInfluence;
    #endif
    dissolveValue *= (invert > 0.5) ? -1.0 : 1.0;

    if (dissolveValue < 0.0)
        discard;

    #if defined(DISSOLVE_COLOR)
    float facingMultiplier = facing > 0.0 ? 1.0 : cutColorBacksideFalloff;
    float edgeFalloff = saturate(
        -dissolveValue * cutColorFalloff * facingMultiplier + 1.0);
    edgeFalloff = edgeFalloff * edgeFalloff * edgeFalloff;
    return edgeFalloff * dissolveColorAlpha;
    #else
    return 0.0;
    #endif
}

#endif
