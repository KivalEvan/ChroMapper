Shader "ChroMapper/Glowing"
{
    Properties
    {
        _Color ("Color", Color) = (1,0,0,0)

        [Space]
        _FogStartOffset ("Fog Start Offset", float) = 0
        _FogScale ("Fog Scale", float) = 1

        [Space]
        [Toggle(CUTOUT)] _CUTOUT ("Cutout Mode", float) = 0
        [ShowIfAny(CUTOUT)] _Cutout ("Cutout", Range(0, 1)) = 0
        [ShowIfAny(CUTOUT)] _CutoutTexScale ("Cutout Texture Scale", float) = 1
        [ShowIfAny(CUTOUT)] _CutoutTexOffset ("Cutout Texture Offset", Vector) = (0,0,0,0)
        [HideInInspector] _CutoutTex ("Cutout Texture", 3D) = "white" {}

        [Space]
        [KeywordEnum(None, Deferred, Mixed)] _BloomType ("White Boost", float) = 0

        [Space]
        [Toggle(NOISE_DITHERING)] _NoiseDithering ("Noise Dithering", float) = 0
    }
    SubShader
    {
        Tags
        {
            "Queue"="Geometry"
            "RenderType"="Opaque"
        }

        Cull Back
        ZTest LEqual
        ZWrite On

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            #pragma multi_compile _ STEREO_INSTANCING_ON

            #pragma shader_feature_local_fragment _ _BLOOMTYPE_DEFERRED _BLOOMTYPE_MIXED
            #pragma shader_feature_local_fragment _ CUTOUT
            #pragma shader_feature_local_fragment _ NOISE_DITHERING
            // Global: the post-process bloom runs (ChroMapper drives it via
            // Shader.EnableKeyword; mirrors the game's MAIN_EFFECT_ENABLED gate).
            #pragma multi_compile _ POST_BLOOM

            #pragma multi_compile_fragment _ BLOOM_FOG

            #include "UnityCG.cginc"
            #include "ShaderLibrary/Camera.hlsl"
            #include "ShaderLibrary/Fog.hlsl"
            #include "ShaderLibrary/CustomBloom.hlsl"
            #include "ShaderLibrary/Cutout.hlsl"
            #include "ShaderLibrary/PostProcess.hlsl"

            float _FogStartOffset;
            float _FogScale;
            sampler3D _CutoutTex;
            float _CutoutTexScale;
            #if defined(NOISE_DITHERING)
            sampler2D _GlobalBlueNoiseTex;
            float2 _GlobalBlueNoiseParams;
            #endif

            UNITY_INSTANCING_BUFFER_START(Props)
                UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
                UNITY_DEFINE_INSTANCED_PROP(float, _Cutout)
                UNITY_DEFINE_INSTANCED_PROP(float4, _CutoutTexOffset)
            UNITY_INSTANCING_BUFFER_END(Props)

            struct appdata
            {
                float4 vertex : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD1;
                float4 screenPos : TEXCOORD2;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert(appdata i)
            {
                v2f o;

                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_TRANSFER_INSTANCE_ID(i, o);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = UnityObjectToClipPos(i.vertex);
                o.worldPos.xyz = mul(unity_ObjectToWorld, i.vertex).xyz;
                o.screenPos = ComputeScreenPosCustom(o.vertex);

                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                float4 albedo = UNITY_ACCESS_INSTANCED_PROP(Props, _Color);

                #if defined(CUTOUT)
                float cutout = UNITY_ACCESS_INSTANCED_PROP(Props, _Cutout);
                float3 objectOrigin = unity_ObjectToWorld._m03_m13_m23;
                float3 cutoutOffset = UNITY_ACCESS_INSTANCED_PROP(Props, _CutoutTexOffset).xyz;
                float3 cutoutPosition = CalculateObjectSpaceCutoutPosition(
                    i.worldPos, objectOrigin, cutoutOffset, _CutoutTexScale);
                ApplyCutoutNoise(tex3D(_CutoutTex, cutoutPosition).r, cutout);
                #endif

                // The retained MainEffect route removes white boost but keeps the
                // unpremultiplied source color. Mixed estimates the stripped Always route.
                albedo = ApplyBloomTypeWhiteBoost(
                    albedo, 1.0, albedo.a, 1.0,
                    _BaseColorBoost, _BaseColorBoostThreshold);

                #if defined(BLOOM_FOG)
                float3 cameraPosition = GetStereoAwareCameraPosition();
                float3 cameraDelta = i.worldPos - cameraPosition;
                float distanceSq = dot(cameraDelta, cameraDelta);
                float fogStartOffset = albedo.a * _FogStartOffset;
                float fogScale = lerp(1.0, _FogScale, albedo.a);
                float fogFactor = CalculateCustomFogFactor(distanceSq, fogStartOffset, fogScale);
                albedo = ApplyBloomFogCalculatedFactor(albedo, i.screenPos, fogFactor);
                #endif

                #if defined(NOISE_DITHERING)
                float4 noiseScreenPosition = ScaleNoiseScreenPosition(
                    i.screenPos, _GlobalBlueNoiseParams);
                albedo = ApplyNoiseDither(albedo, noiseScreenPosition, _GlobalBlueNoiseTex);
                #endif

                return albedo;
            }
            ENDHLSL
        }
    }
}
