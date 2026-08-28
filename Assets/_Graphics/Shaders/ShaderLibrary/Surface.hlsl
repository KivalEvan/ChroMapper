#ifndef CHROMAPPER_SURFACE_INCLUDED
#define CHROMAPPER_SURFACE_INCLUDED

#include "Data.hlsl"

// Per-material surface inputs are passed in as arguments; the library does not
// read uniforms the consumer shader must declare.

inline float4 ResolveSurfaceBaseColor(
    float2 uv, float4 baseColor, float2 inputUvMultiplier, float smoothness,
    float albedoMultiplier, sampler2D diffuseTex, float4 diffuseTex_ST,
    sampler2D metalSmoothnessTex, float4 metalSmoothnessTex_ST)
{
    #if defined(DIFFUSE_TEXTURE)
    float2 baseUv = uv * inputUvMultiplier;
    #if defined(METAL_SMOOTHNESS_TEXTURE) && defined(_DIFFUSE_TEXTURE_SOURCE_MPM_R)
    float2 mpmUv = baseUv * metalSmoothnessTex_ST.xy + metalSmoothnessTex_ST.zw;
    baseColor.rgb *= tex2D(metalSmoothnessTex, mpmUv).r;
    #elif defined(METAL_SMOOTHNESS_TEXTURE) && defined(_DIFFUSE_TEXTURE_SOURCE_MPM_A_SMOOTHNESS)
    float2 mpmUv = baseUv * metalSmoothnessTex_ST.xy + metalSmoothnessTex_ST.zw;
    baseColor.rgb *= tex2D(metalSmoothnessTex, mpmUv).a * smoothness;
    #else
    float2 diffuseUv = baseUv * diffuseTex_ST.xy + diffuseTex_ST.zw;
    baseColor.rgb *= tex2D(diffuseTex, diffuseUv).rgb;
    #endif
    baseColor.rgb *= albedoMultiplier;
    #endif
    return baseColor;
}

inline void ResolveSurfaceMaterial(
    inout SurfaceData surface, float4 vertexColor,
    float metallic, float smoothness, float2 inputUvMultiplier,
    sampler2D metalSmoothnessTex, float4 metalSmoothnessTex_ST,
    sampler2D dirtTex, float4 dirtTex_ST, float occlusionIntensity,
    sampler2D dirtDetailTex, float4 dirtDetailTex_ST,
    float occlusionDetailIntensity, float emissionMaskIntensity)
{
    #if defined(_VERTEXMODE_METALSMOOTHNESS)
    surface.metallic = vertexColor.r * metallic;
    surface.smoothness = vertexColor.a * smoothness;
    #elif defined(_VERTEXMODE_SPECIAL)
    surface.metallic = vertexColor.r;
    surface.smoothness = vertexColor.a;
    #endif

    #if defined(METAL_SMOOTHNESS_TEXTURE)
    #if defined(SECONDARY_UVS_MPM) && USE_SECONDARY_UV
    float2 mpmUv = TransformSecondaryUv(surface, metalSmoothnessTex_ST);
    #else
    float2 mpmBaseUv = surface.uv0 * inputUvMultiplier;
    float2 mpmUv = mpmBaseUv * metalSmoothnessTex_ST.xy + metalSmoothnessTex_ST.zw;
    #endif
    surface.mpm = tex2D(metalSmoothnessTex, mpmUv);

    #if defined(_METALLIC_TEXTURE_MPM_R)
    surface.metallic = surface.mpm.r * metallic;
    #elif defined(_METALLIC_TEXTURE_SOURCE_MPM_R)
    surface.metallic = surface.mpm.r;
    #elif defined(_METALLIC_TEXTURE_SOURCE_MPM_A)
    surface.metallic = surface.mpm.a;
    #endif

    #if defined(_SMOOTHNESS_TEXTURE_MPM_A)
    surface.smoothness = surface.mpm.a * smoothness;
    #elif defined(_SMOOTHNESS_TEXTURE_MPM_G_ROUGHNESS)
    surface.smoothness = 1.0 - (1.0 - surface.mpm.g) * smoothness;
    #elif defined(_SMOOTHNESS_TEXTURE_SOURCE_MPM_A)
    surface.smoothness = surface.mpm.a;
    #elif defined(_SMOOTHNESS_TEXTURE_SOURCE_MPM_G_ROUGHNESS)
    surface.smoothness = surface.mpm.g;
    #endif
    #endif

    #if defined(OCCLUSION)
    #if defined(_OCCLUSION_SOURCE_MPM_B) && defined(METAL_SMOOTHNESS_TEXTURE)
    float primaryOcclusionSample = surface.mpm.b;
    #else
    #if defined(SECONDARY_UVS_OCCLUSION) && USE_SECONDARY_UV
    float2 occlusionUv = TransformSecondaryUv(surface, dirtTex_ST);
    #else
    float2 occlusionBaseUv = surface.uv0 * inputUvMultiplier;
    float2 occlusionUv = occlusionBaseUv * dirtTex_ST.xy + dirtTex_ST.zw;
    #endif
    float primaryOcclusionSample = tex2D(dirtTex, occlusionUv).r;
    #endif
    surface.occlusion = occlusionIntensity * primaryOcclusionSample +
        (1.0 - occlusionIntensity);
    #endif

    #if defined(OCCLUSION_DETAIL)
    #if defined(SECONDARY_UVS_OCCLUSION_DETAIL) && USE_SECONDARY_UV
    float2 detailUv = TransformSecondaryUv(surface, dirtDetailTex_ST);
    #else
    float2 detailBaseUv = surface.uv0 * inputUvMultiplier;
    float2 detailUv = detailBaseUv * dirtDetailTex_ST.xy + dirtDetailTex_ST.zw;
    #endif
    surface.occlusionDetail = occlusionDetailIntensity *
        tex2D(dirtDetailTex, detailUv).r + (1.0 - occlusionDetailIntensity);
    #endif
}

inline float3 ResolveSurfaceNormal(
    float2 uv, float3 normalWS, float3 tangentWS, float3 bitangentWS,
    float2 inputUvMultiplier, sampler2D normalTexture, float4 normalTexture_ST,
    float normalScale)
{
    float2 normalUv = uv * inputUvMultiplier;
    normalUv = normalUv * normalTexture_ST.xy + normalTexture_ST.zw;
    float4 normalSample = tex2D(normalTexture, normalUv);
    float2 normalXY = float2(normalSample.a * normalSample.r, normalSample.g) * 2.0 - 1.0;
    float normalZ = sqrt(1.0 - min(dot(normalXY, normalXY), 1.0));
    normalXY *= normalScale;
    return normalize(
        normalXY.x * tangentWS + normalXY.y * bitangentWS + normalZ * normalWS);
}

#endif
