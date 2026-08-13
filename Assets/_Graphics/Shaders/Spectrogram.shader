// Replacement for the Beat Saber game shader Custom/Spectrogram.
Shader "ChroMapper/Spectrogram"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _PeakOffset ("Peak Offset", Vector) = (0,10,0,1)

        _Metallic ("Metallic", Range(0, 1)) = 0
        _Smoothness ("Smoothness", Range(0, 1)) = 0.5

        [Space]
        [Toggle(DIFFUSE)] _EnableDiffuse ("Enable Diffuse", float) = 1
        [Space(12)]
        [ToggleHeader(SPECULAR)] _EnableSpecular ("Enable Specular", float) = 1
        [ShowIfAny(SPECULAR)]
        _SpecularIntensity ("Specular Intensity", float) = 1
        [Space(12)]
        [ToggleHeader(LIGHT_FALLOFF)] _EnableLightFalloff ("Enable Light Falloff", float) = 0

        [Space(12)]
        _FogStartOffset ("Fog Start Offset", float) = 0
        _FogScale ("Fog Scale", float) = 1

        [Space(12)]
        [KeywordEnum(None, Deferred, Mixed)] _BloomType ("White Boost", float) = 0

        [Space(12)]
        [Enum(Off, 0, On, 1)] _ZWrite ("Z Write", float) = 1
    }
    SubShader
    {
        Tags
        {
            "Queue"="Geometry"
            "RenderType"="Opaque"
            "DisableBatching"="True"
        }

        LOD 200
        Cull Back
        ZTest LEqual
        ZWrite [_ZWrite]

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing

            #pragma shader_feature_local_fragment DIFFUSE
            #pragma shader_feature_local_fragment SPECULAR
            #pragma shader_feature_local_fragment LIGHT_FALLOFF
            #pragma shader_feature_local_fragment _ _BLOOMTYPE_DEFERRED _BLOOMTYPE_MIXED

            #pragma multi_compile_fragment _ BLOOM_FOG
            #pragma multi_compile_fragment _ ACES_TONE_MAPPING
            #pragma multi_compile_fragment _ NOISE_DITHERING
            #pragma multi_compile _ POST_BLOOM
            #pragma multi_compile _ STEREO_INSTANCING_ON

            #include "UnityCG.cginc"
            #include "ShaderLibrary/Fog.hlsl"
            #include "ShaderLibrary/CustomLighting.hlsl"
            #include "ShaderLibrary/CustomTonemapping.hlsl"
            #include "ShaderLibrary/CustomBloom.hlsl"
            #include "ShaderLibrary/PostProcess.hlsl"
            #include "ShaderLibrary/SpectrogramShared.hlsl"

            float _SpectrogramData[64];
            float3 _PeakOffset;

            float _Smoothness;
            float _Metallic;
            float _SpecularIntensity;

            float _FogStartOffset;
            float _FogScale;

            float4 _Color;
            sampler2D _GlobalBlueNoiseTex;
            float2 _GlobalBlueNoiseParams;
            float _GlobalRandomValue;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                float4 screenPos : TEXCOORD3;
                float4 noiseScreenPos : TEXCOORD4;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert(appdata i)
            {
                v2f o;

                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                UNITY_TRANSFER_INSTANCE_ID(i, o);

                uint index = CalculateSpectrogramIndex(i.uv.x);
                i.vertex.xyz = ApplySpectrogramPeakOffset(
                    i.vertex.xyz, i.uv.y, _SpectrogramData[index], _PeakOffset.xyz);

                o.vertex = UnityObjectToClipPos(i.vertex);
                o.worldPos = mul(unity_ObjectToWorld, i.vertex).xyz;
                o.worldNormal = normalize(UnityObjectToWorldNormal(i.normal));
                o.uv.xy = i.uv.xy;
                o.screenPos = ComputeScreenPosCustom(o.vertex);
                o.noiseScreenPos.xy = o.screenPos.xy * _GlobalBlueNoiseParams;
                o.noiseScreenPos.xy += o.vertex.w * _GlobalRandomValue + unity_ObjectToWorld._m03_m13;
                o.noiseScreenPos.zw = o.vertex.zw;

                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                float3 lighting = 0;
                #if defined(DIFFUSE)
                #if defined(SPECULAR)
                #if defined(LIGHT_FALLOFF)
                float3 diffuseLighting = CalculateLightFalloffDiffuse(i.worldPos, i.worldNormal);
                float3 specularLighting = CalculateLightFalloffSpecular(i.worldPos, i.worldNormal, _Smoothness);
                #else
                float3 diffuseLighting = CalculateLightDiffuse(i.worldNormal);
                float3 specularLighting = CalculateLightSpecular(i.worldPos, i.worldNormal, _Smoothness);
                #endif
                float3 diffuseColor = diffuseLighting * _Color.rgb;
                float3 specularColor = _Metallic * (diffuseColor - 0.04) + 0.04;
                lighting = diffuseColor * (0.96 * (1.0 - _Metallic)) +
                    specularLighting * specularColor * _SpecularIntensity;
                #else
                #if defined(LIGHT_FALLOFF)
                lighting = CalculateLightFalloffDiffuse(i.worldPos, i.worldNormal) * _Color.rgb * (1.0 - _Metallic);
                #else
                lighting = CalculateLightDiffuse(i.worldNormal) * _Color.rgb * (1.0 - _Metallic);
                #endif
                #endif
                #endif

                float4 albedo = float4(lighting, 0);

                #if defined(ACES_TONE_MAPPING)
                albedo = ApplyAcesTonemapping(albedo);
                #endif

                // The source family has no retained white-boost variant. Use the
                // color alpha as the bloom value, following other opaque environment shaders.
                albedo = ApplyBloomTypeWhiteBoost(
                    albedo, 1.0, _Color.a, 1.0,
                    _BaseColorBoost, _BaseColorBoostThreshold);

                #if defined(BLOOM_FOG)
                float heightRetained = smoothstep(
                    0, 1, (i.worldPos.y - (_CustomFogHeightFogStartY + _CustomFogHeightFogHeight)) /
                    _CustomFogHeightFogHeight);
                float distanceFogFactor = CalculateCustomFogFactor(
                    distanceSquared(i.worldPos), _FogStartOffset, _FogScale);
                albedo = ApplyBloomFogCalculatedFactor(
                    albedo, i.screenPos, 1 - heightRetained * (1 - distanceFogFactor));
                #else
                float heightRetained = smoothstep(
                    0, 1, (i.worldPos.y - (_CustomFogHeightFogStartY + _CustomFogHeightFogHeight)) /
                    _CustomFogHeightFogHeight);
                albedo.rgb = lerp(0.1, albedo.rgb, heightRetained);
                #endif

                #if defined(NOISE_DITHERING)
                albedo = ApplyNoiseDither(albedo, i.noiseScreenPos, _GlobalBlueNoiseTex);
                #endif
                albedo.a = 0;

                return albedo;
            }
            ENDHLSL
        }
    }
    Fallback "Diffuse"
}
