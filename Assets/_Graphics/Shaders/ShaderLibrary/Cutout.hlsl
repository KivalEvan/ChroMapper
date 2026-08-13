#ifndef CHROMAPPER_CUTOUT_INCLUDED
#define CHROMAPPER_CUTOUT_INCLUDED

inline float3 CalculateObjectSpaceCutoutPosition(
    float3 worldPosition, float3 objectOrigin, float3 textureOffset, float textureScale)
{
    return (worldPosition - objectOrigin + textureOffset) * textureScale;
}

inline void ApplyCutoutNoise(float noiseSample, float cutout)
{
    clip(noiseSample - 1.1 * cutout + 0.1);
}

#endif
