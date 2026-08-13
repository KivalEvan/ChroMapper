#ifndef CUSTOM_TIME_CG_INCLUDED
#define CUSTOM_TIME_CG_INCLUDED

// Time vectors use Unity's (t / 20, t, 2t, 3t) component convention.
// GetTime(offset) applies the per-material scalar offset in the same convention.
//   FREEZE    -> offset vector alone
//   SONG_TIME -> _SongTime + offset vector
//   Standard  -> _Time + offset vector

uniform float4 _SongTime;

inline float4 GetTimeOffsetVector(float offset)
{
    return float4(offset * 0.05, offset, offset * 2.0, offset * 3.0);
}

inline float4 GetTime(float offset)
{
    #if defined(_CUSTOM_TIME_FREEZE)
    return GetTimeOffsetVector(offset);
    #elif defined(_CUSTOM_TIME_SONG_TIME)
    return _SongTime + GetTimeOffsetVector(offset);
    #else
    return _Time + GetTimeOffsetVector(offset);
    #endif
}

#endif // CUSTOM_TIME_CG_INCLUDED
