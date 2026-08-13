// Replacement for the Beat Saber game shader Custom/OpaqueNeonLight.
Shader "ChroMapper/Parametric Box Opaque"
{
    Properties
    {
        _Color ("Color", Color) = (1, 1, 1, 1)

        [Header(Neon Settings)] [Space]
        [KeywordEnum(None, Deferred, Mixed)] _BloomType ("White Boost", float) = 0

        [Header(Fog Settings)] [Space]
        _FogStartOffset ("Fog Start Offset", float) = 1
        _FogScale ("Fog Scale", float) = 1
        [Space]
        [Toggle(HEIGHT_FOG)] _EnableHeightFog ("Enable Height Fog", float) = 1
        [ShowIfAny(HEIGHT_FOG)] _FogHeightOffset ("Fog Height Offset", float) = 0
        [ShowIfAny(HEIGHT_FOG)] _FogHeightScale ("Fog Height Scale", float) = 1

        [Header(Settings)] [Space]
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode ("Cull Mode", float) = 2
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("Z Test", float) = 4
        [Enum(Off, 0, On, 1)] _ZWrite ("Z Write", float) = 1
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200
        Cull [_CullMode]
        ZTest [_ZTest]
        ZWrite [_ZWrite]

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            #pragma multi_compile _ STEREO_INSTANCING_ON

            #pragma shader_feature_local_fragment HEIGHT_FOG
            #pragma shader_feature_local_fragment _ _BLOOMTYPE_DEFERRED _BLOOMTYPE_MIXED
            #pragma multi_compile_fragment _ BLOOM_FOG
            #pragma multi_compile_fragment _ ACES_TONE_MAPPING
            #pragma multi_compile_fragment _ NOISE_DITHERING
            #pragma multi_compile _ POST_BLOOM

            #include "UnityCG.cginc"
            #include "ShaderLibrary/Camera.hlsl"
            #include "ShaderLibrary/Fog.hlsl"
            #include "ShaderLibrary/CustomBloom.hlsl"
            #include "ShaderLibrary/PostProcess.hlsl"
            #include "ShaderLibrary/ParametricShared.hlsl"
            #include "ShaderLibrary/CustomTonemapping.hlsl"

            sampler2D _GlobalBlueNoiseTex;
            float _FogStartOffset;
            float _FogScale;
            float _FogHeightOffset;
            float _FogHeightScale;

            UNITY_INSTANCING_BUFFER_START(Props)
                UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
            UNITY_INSTANCING_BUFFER_END(Props)

            struct appdata
            {
                float4 vertex : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float4 screenPos : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert(appdata i)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_TRANSFER_INSTANCE_ID(i, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = UnityObjectToClipPos(i.vertex);
                o.worldPos = mul(unity_ObjectToWorld, i.vertex).xyz;
                o.screenPos = ComputeScreenPosCustom(o.vertex);
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                float4 color = UNITY_ACCESS_INSTANCED_PROP(Props, _Color);
                float alpha = color.a * color.a;
                float fogBlend = 0.0;
                float heightFactor = 1.0;

                #if defined(HEIGHT_FOG)
                heightFactor = CalculateParametricHeightRamp(
                    i.worldPos.y, _FogHeightScale, _FogHeightOffset,
                    _CustomFogHeightFogHeight, _CustomFogHeightFogStartY);
                #endif

                float3 cameraPosition = GetStereoAwareCameraPosition();

                #if defined(BLOOM_FOG)
                alpha *= heightFactor * CalculateParametricDistanceTransmission(
                    i.worldPos, cameraPosition, _FogStartOffset, _FogScale, color.a,
                    _CustomFogOffset, _CustomFogAttenuation);
                fogBlend = 1.0 - heightFactor * CalculateParametricDistanceTransmission(
                    i.worldPos, cameraPosition, _FogStartOffset, _FogScale, alpha,
                    _CustomFogOffset, _CustomFogAttenuation);
                #else
                alpha *= heightFactor;
                #endif

                float3 rgb = color.rgb * alpha;
                // The source has no white-boost selector: local boost is its
                // default route and MAIN_EFFECT_ENABLED disables it. Mixed is
                // a target extension that keeps the boost in both states.
                #if defined(_BLOOMTYPE_MIXED) || !defined(POST_BLOOM)
                rgb = CalculateBloomComposition(color.rgb, alpha, alpha, 1,
                                                 _BaseColorBoost, _BaseColorBoostThreshold);
                #endif
                #if defined(NOISE_DITHERING)
                rgb = ApplyNoiseDither(float4(rgb, alpha), i.screenPos, _GlobalBlueNoiseTex).rgb;
                #endif
                rgb *= 2.0;
                #if defined(ACES_TONE_MAPPING)
                rgb = ApplyAcesTonemapping(float4(rgb, alpha)).rgb;
                #endif

                #if defined(BLOOM_FOG)
                float2 fogUv = (i.screenPos.xy / i.screenPos.w - 0.5) * _CustomFogTextureToScreenRatio + 0.5;
                rgb = lerp(rgb, tex2D(_BloomPrePassTexture, fogUv).rgb, fogBlend);
                #endif

                return float4(rgb, alpha);
            }
            ENDHLSL
        }
    }
}
