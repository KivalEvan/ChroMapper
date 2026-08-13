#ifndef CHROMAPPER_IRIDESCENCE_INCLUDED
#define CHROMAPPER_IRIDESCENCE_INCLUDED

// Iridescence hue-shift family, shared by the parallax layer pipeline and any
// other lit-material feature that consumes view-dependent iridescence.
// _PARALLAX_FLEXIBLE_REFLECTED selects the reflected-direction variant;
// ResolveIridescenceLayerColor applies the per-layer color permutation.

inline float3 ResolveIridescence(
    float3 directionToCamera, float3 normalWS,
    float3 iridescenceAxesMultiplier, float iridescenceTiling)
{
    #if defined(_PARALLAX_FLEXIBLE_REFLECTED)
    float3 iridescenceDirection = directionToCamera -
        2.0 * dot(directionToCamera, normalWS) * normalWS;
    #else
    float3 iridescenceDirection = directionToCamera;
    #endif

    #if defined(PARALLAX_IRIDESCENCE)
    float iridescenceDot = dot(iridescenceDirection, iridescenceAxesMultiplier);
    iridescenceDot = frac(iridescenceDot * iridescenceTiling);
    float3 hueShift = iridescenceDot.xxx * 6.0 + float3(0.0, 4.0, 2.0);
    hueShift = frac(hueShift * (1.0 / 6.0)) * 6.0 - 3.0;
    hueShift = saturate(abs(hueShift) - 1.0);
    float3 hueShiftSquared = hueShift * hueShift;
    hueShift = (-hueShift * 2.0 + 3.0) * hueShiftSquared;
    return hueShift;
    #else
    return float3(1.0, 1.0, 1.0);
    #endif
}

inline float3 ResolveIridescenceLayerColor(float3 hueShift, float layerIndex)
{
    if (layerIndex <= 0.1) return hueShift.xyz;
    else if (layerIndex <= 1.1) return hueShift.zxy;
    else if (layerIndex <= 2.1) return hueShift.yzx;
    else if (layerIndex <= 3.1) return hueShift.xzy;
    return hueShift.yzx;
}

#endif
