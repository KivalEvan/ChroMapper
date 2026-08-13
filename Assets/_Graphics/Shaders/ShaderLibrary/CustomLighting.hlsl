#ifndef CHROMAPPER_CUSTOM_LIGHTING_INCLUDED
#define CHROMAPPER_CUSTOM_LIGHTING_INCLUDED

#include "Data.hlsl"

uniform float4 _DirectionalLightPositions[5];
uniform float _DirectionalLightRadii[5];
uniform float4 _DirectionalLightDirections[5];
uniform float4 _DirectionalLightColors[5];
uniform float4 _PrivatePointLightPosition;
uniform float _PrivatePointLightIntensity;

// Ambient inputs — nominal diffuse level, minimal value, and multiplier — are
// passed in by the consumer (its per-material/instanced values vary by shader)
// rather than read from uniforms the library cannot assume are declared.
inline float3 CalculateAmbient(float3 nominalDiffuseLevel, float3 ambientMinimalValue,
                               float ambientMultiplier = 1.0)
{
    return max(ambientMultiplier * nominalDiffuseLevel, ambientMinimalValue);
}

inline float CalculateLightFalloff(float3 worldPosition, int lightIndex)
{
    float3 lightOffset = worldPosition - _DirectionalLightPositions[lightIndex].xyz;
    float radiusSquared = _DirectionalLightRadii[lightIndex] * _DirectionalLightRadii[lightIndex];
    return 1.0 / (dot(lightOffset, lightOffset) / radiusSquared * 25.0 + 1.0);
}

inline float3 CalculateLightFalloffDiffuse(float3 worldPosition, float3 normalWS);
inline float3 CalculateLightFalloffSpecular(float3 worldPosition, float3 normalWS,
                                            float smoothness);

inline float CalculateDirectionalDiffuseTerm(float normalDot,
                                             float bothSidesDiffuseMultiplier = 1.0)
{
    #if defined(BOTH_SIDES_DIFFUSE)
    return max(normalDot, 0.0) + min(normalDot, 0.0) * (-bothSidesDiffuseMultiplier);
    #else
    return max(normalDot, 0.0);
    #endif
}

inline float3 CalculateLightDiffuse(float3 normalWS,
                                    float bothSidesDiffuseMultiplier = 1.0)
{
    float3 direct = CalculateDirectionalDiffuseTerm(
        dot(normalWS, _DirectionalLightDirections[1].xyz),
        bothSidesDiffuseMultiplier) * _DirectionalLightColors[1].rgb;
    direct += CalculateDirectionalDiffuseTerm(
        dot(normalWS, _DirectionalLightDirections[0].xyz),
        bothSidesDiffuseMultiplier) * _DirectionalLightColors[0].rgb;
    direct += CalculateDirectionalDiffuseTerm(
        dot(normalWS, _DirectionalLightDirections[2].xyz),
        bothSidesDiffuseMultiplier) * _DirectionalLightColors[2].rgb;
    direct += CalculateDirectionalDiffuseTerm(
        dot(normalWS, _DirectionalLightDirections[3].xyz),
        bothSidesDiffuseMultiplier) * _DirectionalLightColors[3].rgb;
    direct += CalculateDirectionalDiffuseTerm(
        dot(normalWS, _DirectionalLightDirections[4].xyz),
        bothSidesDiffuseMultiplier) * _DirectionalLightColors[4].rgb;
    return direct;
}

inline float3 CalculateViewReflectionDirection(float3 worldPosition, float3 normalWS)
{
    float3 viewDirection = normalize(worldPosition - _WorldSpaceCameraPos);
    return viewDirection - 2.0 * dot(viewDirection, normalWS) * normalWS;
}

inline float CalculateSpecularLobeFactor(
    float3 lightDirection, float3 reflectionDirection, float specularScale)
{
    float3 difference = lightDirection - reflectionDirection;
    float lobe = saturate(1.0 - dot(difference, difference) * specularScale * 0.5);
    lobe *= lobe;
    lobe *= lobe;
    lobe *= lobe;
    return lobe;
}

inline float3 CalculateLightSpecularLobe(float3 lightDirection, float3 lightColor,
                                         float3 reflectionDirection, float specularScale)
{
    float lobe = CalculateSpecularLobeFactor(
        lightDirection, reflectionDirection, specularScale);
    return lobe * lightColor * specularScale;
}

inline float3 CalculateSpecularReflectionDirection(
    float3 worldPosition, float3 normalWS, float smoothness, out float specularScale)
{
    float3 reflectionDirection = CalculateViewReflectionDirection(worldPosition, normalWS);
    float smoothnessSquared = smoothness * smoothness;
    specularScale = smoothnessSquared * smoothnessSquared * 500.0;
    return reflectionDirection;
}

inline float3 CalculateLightSpecular(float3 worldPosition, float3 normalWS, float smoothness)
{
    float specularScale;
    float3 reflectionDirection = CalculateSpecularReflectionDirection(
        worldPosition, normalWS, smoothness, specularScale);

    float3 specular = CalculateLightSpecularLobe(
        _DirectionalLightDirections[1].xyz, _DirectionalLightColors[1].rgb,
        reflectionDirection, specularScale);
    specular += CalculateLightSpecularLobe(
        _DirectionalLightDirections[0].xyz, _DirectionalLightColors[0].rgb,
        reflectionDirection, specularScale);
    specular += CalculateLightSpecularLobe(
        _DirectionalLightDirections[2].xyz, _DirectionalLightColors[2].rgb,
        reflectionDirection, specularScale);
    specular += CalculateLightSpecularLobe(
        _DirectionalLightDirections[3].xyz, _DirectionalLightColors[3].rgb,
        reflectionDirection, specularScale);
    specular += CalculateLightSpecularLobe(
        _DirectionalLightDirections[4].xyz, _DirectionalLightColors[4].rgb,
        reflectionDirection, specularScale);
    return specular;
}

inline float3 CalculateLightSpecularFromCamera(
    float3 worldPosition, float3 cameraPosition, float3 normalWS, float smoothness)
{
    float3 viewDirection = normalize(worldPosition - cameraPosition);
    float3 reflectionDirection = viewDirection - 2.0 * dot(viewDirection, normalWS) * normalWS;
    float smoothnessSquared = smoothness * smoothness;
    float specularScale = smoothnessSquared * smoothnessSquared * 500.0;
    float3 specular = CalculateLightSpecularLobe(
        _DirectionalLightDirections[1].xyz, _DirectionalLightColors[1].rgb,
        reflectionDirection, specularScale);
    specular += CalculateLightSpecularLobe(
        _DirectionalLightDirections[0].xyz, _DirectionalLightColors[0].rgb,
        reflectionDirection, specularScale);
    specular += CalculateLightSpecularLobe(
        _DirectionalLightDirections[2].xyz, _DirectionalLightColors[2].rgb,
        reflectionDirection, specularScale);
    specular += CalculateLightSpecularLobe(
        _DirectionalLightDirections[3].xyz, _DirectionalLightColors[3].rgb,
        reflectionDirection, specularScale);
    specular += CalculateLightSpecularLobe(
        _DirectionalLightDirections[4].xyz, _DirectionalLightColors[4].rgb,
        reflectionDirection, specularScale);
    return specular;
}

inline float3 CalculateLightFalloffDiffuse(float3 worldPosition, float3 normalWS)
{
    float3 direct = max(dot(normalWS, _DirectionalLightDirections[1].xyz), 0.0) *
        _DirectionalLightColors[1].rgb * CalculateLightFalloff(worldPosition, 1);
    direct += max(dot(normalWS, _DirectionalLightDirections[0].xyz), 0.0) *
        _DirectionalLightColors[0].rgb * CalculateLightFalloff(worldPosition, 0);
    direct += max(dot(normalWS, _DirectionalLightDirections[2].xyz), 0.0) *
        _DirectionalLightColors[2].rgb * CalculateLightFalloff(worldPosition, 2);
    direct += max(dot(normalWS, _DirectionalLightDirections[3].xyz), 0.0) *
        _DirectionalLightColors[3].rgb * CalculateLightFalloff(worldPosition, 3);
    direct += max(dot(normalWS, _DirectionalLightDirections[4].xyz), 0.0) *
        _DirectionalLightColors[4].rgb * CalculateLightFalloff(worldPosition, 4);
    return direct;
}

inline float3 CalculateLightFalloffSpecularLobe(float3 lightDirection, float3 lightColor,
                                                float3 reflectionDirection,
                                                float specularScale, float falloff)
{
    float lobe = CalculateSpecularLobeFactor(
        lightDirection, reflectionDirection, specularScale);
    return lobe * lightColor * falloff * specularScale;
}

inline float3 CalculateLightFalloffSpecular(float3 worldPosition, float3 normalWS,
                                            float smoothness)
{
    float specularScale;
    float3 reflectionDirection = CalculateSpecularReflectionDirection(
        worldPosition, normalWS, smoothness, specularScale);

    float3 specular = CalculateLightFalloffSpecularLobe(
        _DirectionalLightDirections[1].xyz, _DirectionalLightColors[1].rgb,
        reflectionDirection, specularScale,
        CalculateLightFalloff(worldPosition, 1));
    specular += CalculateLightFalloffSpecularLobe(
        _DirectionalLightDirections[0].xyz, _DirectionalLightColors[0].rgb,
        reflectionDirection, specularScale,
        CalculateLightFalloff(worldPosition, 0));
    specular += CalculateLightFalloffSpecularLobe(
        _DirectionalLightDirections[2].xyz, _DirectionalLightColors[2].rgb,
        reflectionDirection, specularScale,
        CalculateLightFalloff(worldPosition, 2));
    specular += CalculateLightFalloffSpecularLobe(
        _DirectionalLightDirections[3].xyz, _DirectionalLightColors[3].rgb,
        reflectionDirection, specularScale,
        CalculateLightFalloff(worldPosition, 3));
    specular += CalculateLightFalloffSpecularLobe(
        _DirectionalLightDirections[4].xyz, _DirectionalLightColors[4].rgb,
        reflectionDirection, specularScale,
        CalculateLightFalloff(worldPosition, 4));
    return specular;
}

inline float3 CalculateComposablePrivatePointDiffuse(
    float3 worldPosition, float3 normalWS, float3 privatePointLightColor)
{
    #if defined(POINT_LIGHT_IS_LOCAL)
    float3 lightPosition = mul(
        unity_ObjectToWorld, float4(_PrivatePointLightPosition.xyz, 1.0)).xyz;
    #else
    float3 lightPosition = _PrivatePointLightPosition.xyz;
    #endif
    float3 lightVector = lightPosition - worldPosition;
    float distanceSquared = max(dot(lightVector, lightVector), 0.00001);
    float3 lightDirection = lightVector / sqrt(distanceSquared);
    #if defined(BOTH_SIDES_DIFFUSE)
    float diffuse = abs(dot(normalWS, lightDirection));
    #else
    float diffuse = max(dot(normalWS, lightDirection), 0.0);
    #endif
    return diffuse * privatePointLightColor *
        _PrivatePointLightIntensity / distanceSquared;
}

inline LightingData ResolveLitDirectLighting(
    SurfaceData surface, float3 ambientLight, float3 privatePointLightColor,
    sampler2D lightMap1, sampler2D lightMap2,
    float3 lightMapLightBakeIdA, float3 lightMapLightBakeIdB,
    float3 lightMapLightBakeIdC, float3 lightMapLightBakeIdD,
    float3 lightMapLightBakeIdE, float3 lightMapLightBakeIdF,
    float bothSidesDiffuseMultiplier = 1.0, float specularIntensity = 1.0,
    float groundFadeScale = 0.5, float groundFadeOffset = 1.0)
{
    LightingData lighting = InitializeLightingData();
    float3 directBaseColor = surface.baseColor.rgb;
    float groundFade = 1.0;
    #if defined(GROUND_FADE)
    groundFade = 1.0 - saturate(
        -surface.worldPosition.y * groundFadeScale + groundFadeOffset);
    directBaseColor *= groundFade;
    #endif
    #if defined(_PROBE_CALCULATION_PRECISE)
    float minimumColor = min(directBaseColor.r,
                             min(directBaseColor.g, directBaseColor.b));
    float maximumColor = max(directBaseColor.r,
                             max(directBaseColor.g, directBaseColor.b));
    float saturation = (maximumColor - minimumColor) / maximumColor;
    lighting.ambient = directBaseColor * ambientLight *
        ((saturation + 1.0) * (1.0 - surface.metallic));
    #else
    lighting.ambient = directBaseColor * ambientLight;
    #endif

    float3 diffuseLights = 0.0;
    #if defined(DIFFUSE)
    #if defined(LIGHT_FALLOFF)
    diffuseLights = CalculateLightFalloffDiffuse(
        surface.worldPosition, surface.normalWS);
    #else
    diffuseLights = CalculateLightDiffuse(
        surface.normalWS, bothSidesDiffuseMultiplier);
    #endif
    #endif
    #if defined(PRIVATE_POINT_LIGHT)
    diffuseLights += CalculateComposablePrivatePointDiffuse(
        surface.worldPosition, surface.normalWS, privatePointLightColor);
    #endif

    float3 directColor = diffuseLights * directBaseColor;
    #if defined(DIFFUSE) && defined(SPECULAR)
    lighting.directDiffuse = directColor * (0.96 * (1.0 - surface.metallic));
    #else
    lighting.directDiffuse = directColor * (1.0 - surface.metallic);
    #endif
    #if defined(SPECULAR)
    #if defined(DIFFUSE)
    float3 specularColor = 0.04 + surface.metallic * (directColor - 0.04);
    #else
    float3 specularColor = 0.04 + surface.metallic * (directBaseColor - 0.04);
    #endif
    #if defined(LIGHT_FALLOFF)
    float3 specularLights = CalculateLightFalloffSpecular(
        surface.worldPosition, surface.normalWS, surface.smoothness);
    #else
    float3 specularLights = CalculateLightSpecular(
        surface.worldPosition, surface.normalWS, surface.smoothness);
    #endif
    lighting.directSpecular = specularLights * specularColor *
        (specularIntensity * groundFade);
    #if defined(OCCLUSION)
    lighting.directSpecular *= surface.occlusion;
    #endif
    #endif
    #if defined(LIGHTMAP)
    float3 lightmap1 = tex2D(lightMap1, surface.lightmapUv).rgb;
    float3 lightmap2 = tex2D(lightMap2, surface.lightmapUv).rgb;
    float3 decodedLightmap =
        lightmap1.r * lightMapLightBakeIdA +
        lightmap1.g * lightMapLightBakeIdB +
        lightmap1.b * lightMapLightBakeIdC +
        lightmap2.r * lightMapLightBakeIdD +
        lightmap2.g * lightMapLightBakeIdE +
        lightmap2.b * lightMapLightBakeIdF;
    lighting.directDiffuse += decodedLightmap * 4.594793 *
        (1.0 - surface.metallic) * directBaseColor;
    #endif
    return lighting;
}

inline float4 ComposeLitLighting(LightingData lighting)
{
    return float4(
        lighting.reflection + lighting.ambient +
        (lighting.directDiffuse + lighting.directSpecular),
        0.0);
}

#endif
