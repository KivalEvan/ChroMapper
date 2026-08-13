#ifndef CHROMAPPER_SPECTROGRAM_SHARED_INCLUDED
#define CHROMAPPER_SPECTROGRAM_SHARED_INCLUDED

inline uint CalculateSpectrogramIndex(float horizontalUv)
{
    return uint(max(horizontalUv * 63.0, 0.0));
}

inline float3 ApplySpectrogramPeakOffset(
    float3 objectPosition, float verticalUv, float sample, float3 peakOffset)
{
    return objectPosition - verticalUv * (1.0 - sample) * peakOffset;
}

inline float CalculateSpectrogramVisibility(
    float verticalUv, float sample, float spectrogramScale)
{
    return step(verticalUv, (sample + 0.05) * spectrogramScale);
}

#endif
