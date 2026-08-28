#ifndef CHROMAPPER_DATA_INCLUDED
#define CHROMAPPER_DATA_INCLUDED

// Canonical data exchanged by the feature-composed pipeline. Each feature family
// populates only its source-active fields and preserves the source operation order
// documented in the reconstruction plan.
struct SurfaceData
{
    float3 worldPosition;
    float3 normalWS;
    float2 uv0;
    float2 uv1;
    float2 secondaryUvTiling;
    float2 secondaryUvOffset;
    float4 baseColor;
    float metallic;
    float smoothness;
    float4 mpm;
    float occlusion;
    float occlusionDetail;
    float2 lightmapUv;
};

struct LightingData
{
    float3 directDiffuse;
    float3 directSpecular;
    float3 reflection;
    float3 ambient;
};

struct EmissionData
{
    float3 color;
    float bloomAlpha;
};

inline SurfaceData InitializeSurfaceData(
    float3 worldPosition,
    float3 normalWS,
    float2 uv0,
    float2 uv1,
    float4 baseColor,
    float metallic,
    float smoothness)
{
    SurfaceData surface;
    surface.worldPosition = worldPosition;
    surface.normalWS = normalWS;
    surface.uv0 = uv0;
    surface.uv1 = uv1;
    surface.secondaryUvTiling = 1.0;
    surface.secondaryUvOffset = 0.0;
    surface.baseColor = baseColor;
    surface.metallic = metallic;
    surface.smoothness = smoothness;
    surface.mpm = 1.0;
    surface.occlusion = 1.0;
    surface.occlusionDetail = 1.0;
    surface.lightmapUv = 0.0;
    return surface;
}

inline float2 TransformSecondaryUv(SurfaceData surface, float4 texture_ST)
{
    return surface.uv1 * texture_ST.xy * surface.secondaryUvTiling +
        texture_ST.zw + surface.secondaryUvOffset;
}

inline float2 TransformScrollingSecondaryUv(
    SurfaceData surface, float4 texture_ST, float2 speed, float time)
{
    float2 scale = texture_ST.xy * surface.secondaryUvTiling;
    return surface.uv1 * scale + texture_ST.zw + surface.secondaryUvOffset +
        time * speed * scale;
}

inline LightingData InitializeLightingData()
{
    LightingData lighting;
    lighting.directDiffuse = 0.0;
    lighting.directSpecular = 0.0;
    lighting.reflection = 0.0;
    lighting.ambient = 0.0;
    return lighting;
}

inline EmissionData InitializeEmissionData()
{
    EmissionData emission;
    emission.color = 0.0;
    emission.bloomAlpha = 0.0;
    return emission;
}

#endif
