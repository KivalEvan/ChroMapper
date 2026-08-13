#ifndef CUSTOM_BLOOM_CG_INCLUDED
#define CUSTOM_BLOOM_CG_INCLUDED

// Main-effect white boost is camera-global. Do not expose these values in a
// shader Properties block because material values override Shader globals.
float _BaseColorBoost;
float _BaseColorBoostThreshold;

// Lit main-effect white-boost term, shared with the simple-shader white-boost routes:
// whiteBoost = (bloomValue * whiteboostMultiplier)^2 * baseColorBoost - baseColorBoostThreshold
inline float CalculateWhiteBoost(float bloomValue, float whiteboostMultiplier,
                                 float baseColorBoost, float baseColorBoostThreshold)
{
    float whiteBoost = bloomValue * whiteboostMultiplier;
    return whiteBoost * whiteBoost * baseColorBoost - baseColorBoostThreshold;
}

// Bloom composition: premultiplied color plus the Lit white-boost term, shared by
// the Deferred and Mixed bloom types (and the selector-free Opaque/Transparent route).
// bloomValue drives the white boost; premultiplyAlpha scales the color (pass 1
// for the game's additive, alpha-preserving routes).
// rgb = saturate(rgb * premultiplyAlpha
//                + (bloomValue * whiteboostMultiplier)^2 * baseColorBoost
//                - baseColorBoostThreshold)
inline float3 CalculateBloomComposition(float3 rgb, float premultiplyAlpha, float bloomValue,
                                        float whiteboostMultiplier, float baseColorBoost,
                                        float baseColorBoostThreshold)
{
    float whiteBoost = CalculateWhiteBoost(bloomValue, whiteboostMultiplier,
                                           baseColorBoost, baseColorBoostThreshold);
    return saturate(rgb * premultiplyAlpha + whiteBoost);
}

// Post-process bloom route (game: MAIN_EFFECT_ENABLED on, ChroMapper global
// POST_BLOOM on): the post-process bloom provides the glow, so the white-boost
// term compiles out. Plain premultiplied composition with alpha scaled by the
// bloom multiplier (pass 1 when the material has no multiplier slot).
inline float4 CalculateBloomPostComposition(float3 rgb, float alpha, float bloomMultiplier)
{
    return float4(rgb * alpha, alpha * bloomMultiplier);
}

// Applies the local white-boost selector without changing the post-process route.
// Deferred matches the game MainEffect mode. Mixed is the target Always mode.
inline float4 ApplyBloomTypeWhiteBoost(float4 color, float premultiplyAlpha,
                                       float bloomValue, float whiteboostMultiplier,
                                       float baseColorBoost, float baseColorBoostThreshold)
{
    #if defined(_BLOOMTYPE_MIXED) || \
        (defined(_BLOOMTYPE_DEFERRED) && !defined(POST_BLOOM))
    color.rgb = CalculateBloomComposition(
        color.rgb, premultiplyAlpha, bloomValue, whiteboostMultiplier,
        baseColorBoost, baseColorBoostThreshold);
    #endif
    return color;
}

// Shared Deferred/Mixed composition for shaders whose no-bloom route is already
// premultiplied. Set noBloomPremultiply to one only for the Unlit route, whose
// no-bloom source color is not premultiplied and clears alpha.
inline float4 ApplyBloomTypeComposition(
    float4 color, float3 postBloomRgb,
    float premultiplyAlpha, float bloomValue, float whiteboostMultiplier,
    float baseColorBoost, float baseColorBoostThreshold,
    float noBloomPremultiply, float noBloomAlpha)
{
    #if defined(_BLOOMTYPE_MIXED) || (defined(_BLOOMTYPE_DEFERRED) && !defined(POST_BLOOM))
    color.rgb = CalculateBloomComposition(
        color.rgb, premultiplyAlpha, bloomValue, whiteboostMultiplier,
        baseColorBoost, baseColorBoostThreshold);
    #elif defined(_BLOOMTYPE_DEFERRED)
    color = CalculateBloomPostComposition(postBloomRgb, color.a, 1.0);
    #else
    if (noBloomPremultiply > 0.5)
    {
        color.rgb *= color.a;
        color.a = noBloomAlpha;
    }
    #endif
    return color;
}

inline float4 calculate_main_effect_emission(float redInput, float greenInput,
                                             float4 emissionColor, float whiteboostMultiplier,
                                             float bloomIntensity, float baseColorBoost,
                                             float baseColorBoostThreshold)
{
    float3 emissionRgb = redInput * emissionColor.rgb;
    float bloomValue = greenInput * greenInput * emissionColor.a;
    float bloomAlpha = bloomValue * 3.5 * bloomIntensity;
    emissionRgb = CalculateBloomComposition(emissionRgb, emissionColor.a, bloomValue,
                                   whiteboostMultiplier, baseColorBoost, baseColorBoostThreshold);
    return float4(emissionRgb, bloomAlpha);
}

#endif
