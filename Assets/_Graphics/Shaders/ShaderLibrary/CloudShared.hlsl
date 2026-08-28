#ifndef CHROMAPPER_CLOUD_SHARED_INCLUDED
#define CHROMAPPER_CLOUD_SHARED_INCLUDED

#include "ObjectShared.hlsl"

inline float CalculateSquaredRangeFade(float value, float minimumValue, float maximumValue)
{
    float fade = saturate((value - minimumValue) / (maximumValue - minimumValue));
    return fade * fade;
}

inline float CalculateCloudRunwayFade(float3 worldPosition, float scale, float offset)
{
    float gate = worldPosition.z < 0.0 ? 1.0 : 0.0;
    float3 distanceVector = float3(worldPosition.x, worldPosition.y - 1.0, gate);
    return 1.0 - saturate(gate * scale / length(distanceVector) + offset);
}

#endif
