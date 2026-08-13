#ifndef CHROMAPPER_CLOUD_SHARED_INCLUDED
#define CHROMAPPER_CLOUD_SHARED_INCLUDED

inline float3 RotateCloudPositionY(float3 position, float angle)
{
    float sine;
    float cosine;
    sincos(angle, sine, cosine);
    return float3(
        cosine * position.x - sine * position.z,
        position.y,
        sine * position.x + cosine * position.z);
}

inline float CalculateSquaredRangeFade(float value, float minimumValue, float maximumValue)
{
    float fade = saturate((value - minimumValue) / max(maximumValue - minimumValue, 1e-5));
    return fade * fade;
}

inline float CalculateCloudRunwayFade(float3 worldPosition, float scale, float offset)
{
    float gate = worldPosition.z > 0.0 ? 1.0 : 0.0;
    float3 distanceVector = float3(worldPosition.x, worldPosition.y - 1.0, gate);
    return 1.0 - saturate(gate * scale / max(length(distanceVector), 1e-5) + offset);
}

#endif
