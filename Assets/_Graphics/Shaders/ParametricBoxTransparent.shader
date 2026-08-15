// Replacement for the Beat Saber game shader Custom/TransparentNeonLight.
Shader "ChroMapper/Parametric Box Transparent"
{
    Properties
    {
        _Color ("Color", Color) = (1, 1, 1, 1)
        _AlphaWidth("Alpha Width", Vector) = (1,1,1,1)

        [Header(Neon Settings)] [Space]
        [KeywordEnum(None, Deferred, Mixed)] _BloomType ("White Boost", float) = 0

        [Space]
        [Toggle(WORLD_NOISE)] _EnableWorldNoise ("Enable World Noise", float) = 0
        _WorldNoiseScale ("World Noise Scale", float) = 1
        _WorldNoiseIntensityOffset ("World Noise Intensity Offset", float) = 0
        _WorldNoiseIntensityScale ("World Noise Intensity Scale", float) = 1
        _WorldNoiseScrolling ("World Noise Scrolling", Vector) = (0,0,0,1)
        [Toggle(WORLD_SPACE_FADE)] _EnableWorldSpaceFade ("Enable World Space Fade", float) = 0
        _WorldSpaceFadePos ("World Space Fade Position", float) = 0
        _WorldSpaceFadeSlope ("World Space Fade Slope", float) = 1
        [ToggleShowIfAny(WORLD_NOISE_WARP, WORLD_NOISE)] _WorldNoiseDistort ("Noise Field Warp", float) = 0
        _NoiseWarpZoomStrength ("Noise Warp Zoom Strength", float) = 0
        _NoiseWarpSkewStrength ("Noise Warp Skew Strength", float) = 0

        [Space(12)] [Toggle(SPECULAR)] _EnableSpecular ("Enable Specular", float) = 1
        [ShowIfAny(SPECULAR)] _SpecularIntensity ("Specular Intensity", float) = 1
        [ShowIfAny(SPECULAR)] _SpecularHardness ("Specular Hardness", float) = 64
        [Space(12)] [Toggle(NORMAL_MAP)] _EnableNormalMap ("Enable Normal Map", float) = 0
        [ShowIfAny(NORMAL_MAP)] _NormalTex ("Normal Texture", 2D) = "bump" {}
        [ShowIfAny(NORMAL_MAP)] _NormalScale ("Normal Scale", float) = 1
        [Space(12)] [Toggle(REFLECTION_PROBE)] _EnableReflectionProbe ("Enable Reflection Probe", float) = 0
        [ShowIfAny(REFLECTION_PROBE)] _Smoothness ("Smoothness", Range(0, 1)) = 1
        [ShowIfAny(REFLECTION_PROBE)] _ReflectionIntensity ("Probe Intensity", float) = 1
        [ShowIfAny(REFLECTION_PROBE)] _GlassOpacity ("Glass Opacity", float) = 1
        [ToggleShowIfAny(RIM_DIM, REFLECTION_PROBE)] _EnableRimDim ("Enable Rim Dim", float) = 0
        [ShowIfAny(RIM_DIM)] _RimScale ("Rim Scale", float) = 1
        [ShowIfAny(RIM_DIM)] _RimOffset ("Rim Offset", float) = 1
        [ShowIfAny(RIM_DIM)] _RimDistanceOffset ("Rim Camera Distance Offset", float) = 2
        [ShowIfAny(RIM_DIM)] _RimDistanceScale ("Rim Camera Distance Scale", float) = 0.3
        [ToggleShowIfAny(INVERT_RIM_DIM, RIM_DIM)] _InvertRimDim ("Invert Rim Dim", float) = 0

        [Header(Fog Settings)] [Space]
        _FogStartOffset ("Fog Start Offset", float) = 1
        _FogScale ("Fog Scale", float) = 1
        [Space]
        [Toggle(HEIGHT_FOG)] _EnableHeightFog ("Enable Height Fog", float) = 1
        [ShowIfAny(HEIGHT_FOG)] _FogHeightOffset ("Fog Height Offset", float) = 0
        [ShowIfAny(HEIGHT_FOG)] _FogHeightScale ("Fog Height Scale", float) = 1

        [Header(Settings)] [Space]
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendModeSrc ("Blend Src", float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendModeDst ("Blend Dst", float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendModeSrcA ("Blend Src A", float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendModeDstA ("Blend Dst A", float) = 1
        [Enum(UnityEngine.Rendering.BlendOp)] _BlendOp ("Blend Operation", float) = 0
        [Space]
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode ("Cull Mode", float) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("Z Test", float) = 4

        [Header(Stencil)] [Space]
        _StencilRefValue ("Stencil Ref Value", Float) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)] _StencilComp ("Stencil Comp Func", Float) = 8
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilPass ("Stencil Pass Op", Float) = 0
    }

    SubShader
    {
        Tags
        {
            "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"
        }

        Blend [_BlendModeSrc] [_BlendModeDst], [_BlendModeSrcA] [_BlendModeDstA]
        BlendOp [_BlendOp]
        Cull [_CullMode]
        ZTest [_ZTest]
        ZWrite Off

        Stencil
        {
            Ref [_StencilRefValue]
            Comp [_StencilComp]
            Pass [_StencilPass]
        }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            #pragma multi_compile _ STEREO_INSTANCING_ON

            #pragma shader_feature_local_fragment HEIGHT_FOG
            #pragma shader_feature_local_fragment WORLD_NOISE
            #pragma shader_feature_local_fragment WORLD_SPACE_FADE
            #pragma shader_feature_local_fragment WORLD_NOISE_WARP
            #pragma shader_feature_local_fragment SPECULAR
            #pragma shader_feature_local_fragment NORMAL_MAP
            #pragma shader_feature_local_fragment REFLECTION_PROBE
            #pragma shader_feature_local_fragment RIM_DIM
            #pragma shader_feature_local_fragment INVERT_RIM_DIM
            #pragma shader_feature_local_fragment _ _BLOOMTYPE_DEFERRED _BLOOMTYPE_MIXED
            #pragma multi_compile_fragment _ BLOOM_FOG
            #pragma multi_compile _ POST_BLOOM

            #include "UnityCG.cginc"
            #include "ShaderLibrary/Camera.hlsl"
            #include "ShaderLibrary/Fog.hlsl"
            #include "ShaderLibrary/CustomBloom.hlsl"
            #include "ShaderLibrary/ParametricShared.hlsl"
            #include "ShaderLibrary/CustomLighting.hlsl"

            sampler3D _CutoutTex;
            float4 _TimeHelperOffset;
            float _FogStartOffset;
            float _FogScale;
            float _FogHeightOffset;
            float _FogHeightScale;
            float _WorldNoiseScale;
            float _WorldNoiseIntensityOffset;
            float _WorldNoiseIntensityScale;
            float3 _WorldNoiseScrolling;
            float _WorldSpaceFadePos;
            float _WorldSpaceFadeSlope;
            float _NoiseWarpZoomStrength;
            float _NoiseWarpSkewStrength;
            sampler2D _NormalTex;
            float4 _NormalTex_ST;
            float _NormalScale;
            float _SpecularIntensity;
            float _SpecularHardness;
            float _Smoothness;
            float _ReflectionIntensity;
            float _GlassOpacity;
            float _RimScale;
            float _RimOffset;
            float _RimDistanceOffset;
            float _RimDistanceScale;
            float _InvertRimDim;

            UNITY_INSTANCING_BUFFER_START(Props)
                UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
                UNITY_DEFINE_INSTANCED_PROP(float4, _AlphaWidth)
            UNITY_INSTANCING_BUFFER_END(Props)

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float alphaFactor : TEXCOORD1;
                float2 uv : TEXCOORD2;
                float3 worldNormal : TEXCOORD3;
                float4 worldTangent : TEXCOORD4;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert(appdata i)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_TRANSFER_INSTANCE_ID(i, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                float4 alphaWidth = UNITY_ACCESS_INSTANCED_PROP(Props, _AlphaWidth);
                float top = i.vertex.y > 0.5 ? 1.0 : 0.0;
                float width = lerp(alphaWidth.z, alphaWidth.w, top);
                o.alphaFactor = lerp(alphaWidth.x, alphaWidth.y, top);
                i.vertex.xz *= width;

                o.vertex = UnityObjectToClipPos(i.vertex);
                o.worldPos = mul(unity_ObjectToWorld, i.vertex).xyz;
                o.uv = i.uv;
                o.worldNormal = normalize(UnityObjectToWorldNormal(i.normal));
                o.worldTangent = float4(
                    normalize(UnityObjectToWorldDir(i.tangent.xyz)),
                    i.tangent.w * unity_WorldTransformParams.w);
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                float4 color = UNITY_ACCESS_INSTANCED_PROP(Props, _Color);
                float alpha = i.alphaFactor * i.alphaFactor * i.alphaFactor * color.a;
                float3 worldNormal = normalize(i.worldNormal);
                #if defined(NORMAL_MAP)
                float3 tangentNormal = UnpackNormalWithScale(
                    tex2D(_NormalTex, TRANSFORM_TEX(i.uv, _NormalTex)), _NormalScale);
                float3 worldBitangent = cross(worldNormal, i.worldTangent.xyz) * i.worldTangent.w;
                worldNormal = normalize(mul(
                    tangentNormal, float3x3(i.worldTangent.xyz, worldBitangent, worldNormal)));
                #endif

                #if defined(WORLD_NOISE)
                float noise = SampleParametricWorldNoise(
                    i.worldPos, _CutoutTex, _WorldNoiseScrolling,
                    _Time.x + _TimeHelperOffset.x, _WorldNoiseScale,
                    _WorldNoiseIntensityOffset, _WorldNoiseIntensityScale,
                    _WorldSpaceFadePos, _WorldSpaceFadeSlope,
                    _NoiseWarpZoomStrength, _NoiseWarpSkewStrength);
                alpha *= noise;
                #endif

                float preSquareAlpha = alpha;
                alpha *= alpha;
                #if defined(HEIGHT_FOG)
                alpha *= CalculateParametricHeightRamp(
                    i.worldPos.y, _FogHeightScale, _FogHeightOffset,
                    _CustomFogHeightFogHeight, _CustomFogHeightFogStartY);
                #endif
                float3 cameraPosition = GetParametricCameraPosition();

                float3 surfaceAddition = 0.0;
                #if defined(SPECULAR)
                float specularSmoothness = saturate(_SpecularHardness / 128.0);
                surfaceAddition += CalculateLightSpecularFromCamera(
                    i.worldPos, cameraPosition, worldNormal, specularSmoothness) * _SpecularIntensity;
                #endif
                #if defined(REFLECTION_PROBE)
                float3 incident = normalize(i.worldPos - cameraPosition);
                float3 reflectionDirection = reflect(incident, worldNormal);
                half4 encodedReflection = UNITY_SAMPLE_TEXCUBE_LOD(
                    unity_SpecCube0, reflectionDirection, (1.0 - _Smoothness) * 6.0);
                float3 reflection = DecodeHDR(encodedReflection, unity_SpecCube0_HDR) * _ReflectionIntensity;
                #if defined(RIM_DIM)
                reflection *= CalculateParametricRimDim(
                    i.worldPos, worldNormal, cameraPosition, _RimScale, _RimOffset,
                    _RimDistanceOffset, _RimDistanceScale,
                    #if defined(INVERT_RIM_DIM)
                    1.0
                    #else
                    _InvertRimDim
                    #endif
                );
                #endif
                surfaceAddition += reflection;
                alpha *= _GlassOpacity;
                #endif
                #if defined(BLOOM_FOG)
                alpha *= CalculateParametricDistanceTransmission(
                    i.worldPos, cameraPosition, _FogStartOffset, _FogScale, preSquareAlpha,
                    _CustomFogOffset, _CustomFogAttenuation);
                #endif

                float3 rgb = color.rgb * alpha;
                // The source has no white-boost selector: local boost is its
                // default route and MAIN_EFFECT_ENABLED disables it. Mixed is
                // a target extension that keeps the boost in both states.
                #if defined(_BLOOMTYPE_MIXED) || !defined(POST_BLOOM)
                rgb = CalculateBloomComposition(color.rgb, alpha, alpha, 1,
                                                 _BaseColorBoost, _BaseColorBoostThreshold);
                #endif
                rgb += surfaceAddition * alpha;
                return float4(rgb, alpha);
            }
            ENDHLSL
        }
    }
}
