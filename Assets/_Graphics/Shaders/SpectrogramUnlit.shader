// Replacement for the Beat Saber game shader Custom/UnlitSpectrogram.
Shader "ChroMapper/Spectrogram Unlit"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _SpectrogramScale ("Spectrogram Scale", float) = 0.5

        [Space]
        _FogStartOffset ("Fog Start Offset", float) = 0
        _FogScale ("Fog Scale", float) = 1

        [Space]
        [KeywordEnum(None, Deferred, Mixed)] _BloomType ("White Boost", float) = 0

        [Space]
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendModeSrc ("Blend Src Factor", float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendModeDst ("Blend Dst Factor", float) = 10
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendModeSrcA ("Blend Src Factor A", float) = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendModeDstA ("Blend Dst Factor A", float) = 10
    }
    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
            "RenderType"="Transparent"
            "DisableBatching"="True"
        }

        LOD 200
        Blend [_BlendModeSrc] [_BlendModeDst], [_BlendModeSrcA] [_BlendModeDstA]
        Cull Off
        ZTest LEqual
        ZWrite Off

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing

            #pragma shader_feature_local_fragment _ _BLOOMTYPE_DEFERRED _BLOOMTYPE_MIXED

            #pragma multi_compile_fragment _ BLOOM_FOG
            #pragma multi_compile _ POST_BLOOM
            #pragma multi_compile _ STEREO_INSTANCING_ON

            #include "UnityCG.cginc"
            #include "ShaderLibrary/Fog.hlsl"
            #include "ShaderLibrary/CustomBloom.hlsl"
            #include "ShaderLibrary/SpectrogramShared.hlsl"

            float _SpectrogramData[64];
            float _SpectrogramScale;

            float _FogStartOffset;
            float _FogScale;

            float4 _Color;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float4 screenPos : TEXCOORD2;
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

                o.vertex = UnityObjectToClipPos(i.vertex);
                o.worldPos = mul(unity_ObjectToWorld, i.vertex).xyz;
                o.uv.xy = i.uv.xy;
                o.screenPos = ComputeScreenPosCustom(o.vertex);

                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                uint index = CalculateSpectrogramIndex(i.uv.x);
                float visible = CalculateSpectrogramVisibility(
                    i.uv.y, _SpectrogramData[index], _SpectrogramScale);
                float4 albedo = float4(_Color.rgb, _Color.a * visible);

                // The source family has no retained white-boost variant. Use the
                // masked alpha as the bloom value, following simple transparent shaders.
                albedo = ApplyBloomTypeWhiteBoost(
                    albedo, 1.0, albedo.a, 1.0,
                    _BaseColorBoost, _BaseColorBoostThreshold);

                #if defined(BLOOM_FOG)
                albedo = ApplyBloomFog(albedo, i.screenPos, i.worldPos, _FogStartOffset, _FogScale);
                #endif

                return albedo;
            }
            ENDHLSL
        }
    }
}
