#ifndef CHROMAPPER_CAMERA_INCLUDED
#define CHROMAPPER_CAMERA_INCLUDED

float _StereoCameraEyeOffset;

inline float3 GetStereoAwareCameraPosition()
{
    #if defined(UNITY_SINGLE_PASS_STEREO) || defined(STEREO_INSTANCING_ON) || defined(STEREO_MULTIVIEW_ON)
    return unity_StereoWorldSpaceCameraPos[unity_StereoEyeIndex];
    #else
    return _WorldSpaceCameraPos;
    #endif
}

inline float4 ComputeScreenPosCustom(float4 pos)
{
    float4 screenPos = ComputeNonStereoScreenPos(pos);
    #if defined(UNITY_SINGLE_PASS_STEREO) || defined(STEREO_INSTANCING_ON) || defined(STEREO_MULTIVIEW_ON)
    float eyeOffset = (unity_StereoEyeIndex * (_StereoCameraEyeOffset + _StereoCameraEyeOffset)) + -
        _StereoCameraEyeOffset;
    screenPos.x = pos.w * eyeOffset + screenPos.x;
    #if !UNITY_UV_STARTS_AT_TOP
    screenPos.y = -screenPos.y + pos.w;
    #endif
    #endif
    return screenPos;
}

#endif
