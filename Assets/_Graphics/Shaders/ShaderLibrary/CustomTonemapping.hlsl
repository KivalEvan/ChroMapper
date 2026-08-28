// ETAN dropped great piece of information and gave us this
// Tonemapping: https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/
// Bloom: Reinhard Tone Mapping
#ifndef CUSTOM_TONEMAPPING_CG_INCLUDED
#define CUSTOM_TONEMAPPING_CG_INCLUDED

inline float4 ApplyAcesTonemapping(float4 col)
{
    const float a = 2.51;
    const float b = 0.03;
    const float c = 2.43;
    const float d = 0.59;
    const float e = 0.14;
    col.rgb = saturate(col.rgb * (a * col.rgb + b) / (col.rgb * (c * col.rgb + d) + e));
    return col;
}

inline float4 ApplyReinhardTonemapping(float4 col)
{
    // Hidden/PostProcessing/Bloom pass 11 (e2c5d62d): the recovered bloom
    // Reinhard variant includes the quadratic shoulder term.
    col.rgb = col.rgb * (col.rgb * 0.25 + 1.0) / (col.rgb + 1.0);
    return col;
}

#endif // CUSTOM_TONEMAPPING_CG_INCLUDED
