// Replacement for the Beat Saber game shader Custom/SimpleLightning.
Shader "ChroMapper/Lightning"
{
    Properties
    {
        [PerRendererData] _Color ("Color", Color) = (1, 1, 1, 1)

        [NoScaleOffset] _MainTex ("Main Texture", 2D) = "white" {}
        [NoScaleOffset] _NoiseTex ("Noise Texture", 2D) = "black" {}
        [NoScaleOffset] _TimingTex ("Timing Texture", 2D) = "black" {}

        [PerRendererData] _TargetPoint ("Target Point", Vector) = (0, 0, 0, 0)
        [Toggle(TARGET_POINT)] _EnableTargetPoint ("Enable Target Point", Float) = 0
        [Toggle(TIME_OFFSET)] _EnableTimeOffset ("Enable Time Offset", Float) = 0
        _TimeOffset ("Time Offset", Float) = 0.1
        _NoiseSmallScale ("Noise Small Scale", Float) = 1
        _SmallScaleNoiseStrength ("Small Scale Noise Strength", Float) = 2
        _SmallScaleNoiseScrollingSpeed ("Small Scale Noise Scrolling Speed", Float) = 5
        [Space] _NoiseBigScale ("Noise Big Scale", Float) = 0.1
        _BigScaleNoiseStrength ("Big Scale Noise Strength", Float) = 5
        _BigScaleNoiseScrollingSpeed ("Big Scale Noise Scrolling Speed", Float) = 1
        _NoiseScrollingSpeed ("Noise Scrolling Speed", Float) = 5
        _XNoiseOffsetStrength ("X Noise Offset Strength", Float) = 0.5
        [Space] _Extrude ("Extrude", Float) = 1
        _ColorBoost ("Color Boost", Float) = 1
        _WhiteBoost ("White Boost", Float) = 0.2
        _EdgeFadeStrength ("Edge Fade Strength", Float) = 5

        [Enum(UnityEngine.Rendering.CompareFunction)] _StencilComp ("Stencil Compare", Float) = 8
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendModeSrc ("Blend Source", Float) = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendModeDst ("Blend Destination", Float) = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendModeSrcA ("Blend Source Alpha", Float) = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendModeDstA ("Blend Destination Alpha", Float) = 10
        [Enum(UnityEngine.Rendering.BlendOp)] _BlendOp ("Blend Operation", Float) = 0
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode ("Cull Mode", Float) = 0
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilPass ("Stencil Pass", Float) = 0
        _StencilRefValue ("Stencil Reference", Float) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("Z Test", Float) = 4
        _OffsetFactor ("Offset Factor", Float) = 0
        _OffsetUnits ("Offset Units", Float) = 0
    }

    SubShader
    {
        Tags
        {
            "Queue" = "Transparent"
            "IgnoreProjector" = "True"
            "RenderType" = "Transparent"
        }

        Blend [_BlendModeSrc] [_BlendModeDst], [_BlendModeSrcA] [_BlendModeDstA]
        BlendOp [_BlendOp]
        Cull [_CullMode]
        ZTest [_ZTest]
        ZWrite Off
        Offset [_OffsetFactor], [_OffsetUnits]

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
            #pragma shader_feature_local_vertex _ TARGET_POINT
            #pragma shader_feature_local_vertex _ TIME_OFFSET

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            sampler2D _NoiseTex;
            sampler2D _TimingTex;

            float _NoiseSmallScale;
            float _SmallScaleNoiseStrength;
            float _SmallScaleNoiseScrollingSpeed;
            float _NoiseBigScale;
            float _BigScaleNoiseStrength;
            float _BigScaleNoiseScrollingSpeed;
            float _NoiseScrollingSpeed;
            float _XNoiseOffsetStrength;
            float _Extrude;
            float _ColorBoost;
            float _WhiteBoost;
            float _EdgeFadeStrength;

            UNITY_INSTANCING_BUFFER_START(Props)
                UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
                UNITY_DEFINE_INSTANCED_PROP(float4, _TargetPoint)
                UNITY_DEFINE_INSTANCED_PROP(float, _TimeOffset)
            UNITY_INSTANCING_BUFFER_END(Props)

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv1 : TEXCOORD1;
                float2 uv2 : TEXCOORD2;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 edgeColor : TEXCOORD0;
                float2 mainUv : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert(appdata i)
            {
                v2f o;

                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_TRANSFER_INSTANCE_ID(i, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                float2 sourceUv1 = i.uv1;
                float2 sourceUv2 = i.uv2;

                float3 localPath;
                #if defined(TARGET_POINT)
                float3 targetLocal = mul(unity_WorldToObject,
                                         float4(UNITY_ACCESS_INSTANCED_PROP(Props, _TargetPoint).xyz, 1)).xyz;
                localPath = targetLocal * sourceUv2.y;
                localPath.y += i.vertex.y * _XNoiseOffsetStrength;
                #else
                localPath = float3(i.vertex.x, i.vertex.y * _XNoiseOffsetStrength, i.vertex.z);
                #endif

                float objectTime = unity_ObjectToWorld._m03 + unity_ObjectToWorld._m23;
                #if defined(TIME_OFFSET)
                float lightningTime = objectTime + UNITY_ACCESS_INSTANCED_PROP(Props, _TimeOffset);
                #else
                float lightningTime = objectTime + _Time.y;
                #endif

                float timing = tex2Dlod(_TimingTex, float4(lightningTime, 0, 0, 0)).x;
                float2 smallNoiseUv = float2(sourceUv2.x,
                                             sourceUv2.y * _NoiseSmallScale + lightningTime *
                                             _SmallScaleNoiseScrollingSpeed +
                                             timing);
                float2 bigNoiseUv = float2(sourceUv2.x,
                                           sourceUv2.y * _NoiseBigScale + lightningTime *
                                           _BigScaleNoiseScrollingSpeed +
                                           timing);
                float2 smallNoise = tex2Dlod(_NoiseTex, float4(smallNoiseUv, 0, 0)).xy - 0.5;
                float2 bigNoise = tex2Dlod(_NoiseTex, float4(bigNoiseUv, 0, 0)).xy - 0.5;

                float edge = 1 - abs(sourceUv2.y - 0.5) * 2;
                float deformationMask = saturate(edge * edge * _EdgeFadeStrength);
                float edgeAlpha = saturate(edge * _EdgeFadeStrength);
                smallNoise *= deformationMask * _SmallScaleNoiseStrength;
                bigNoise *= deformationMask * _BigScaleNoiseStrength;
                smallNoise.x *= _Extrude;
                bigNoise.x *= _Extrude;
                localPath.xy += smallNoise;
                localPath.xy += bigNoise;

                o.vertex = UnityObjectToClipPos(float4(localPath, 1));
                o.edgeColor = float4(1, 1, 1, edgeAlpha);
                o.mainUv = sourceUv1;
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                half4 albedo = tex2D(_MainTex, i.mainUv.yx);
                albedo *= i.edgeColor;
                albedo *= UNITY_ACCESS_INSTANCED_PROP(Props, _Color);
                albedo.a *= albedo.a;

                half whiteBoost = albedo.a * _WhiteBoost;
                half3 boostedWhite = 1 - albedo.rgb * whiteBoost;
                half colorBoost = saturate(albedo.a * _ColorBoost);
                albedo.rgb = lerp(boostedWhite, albedo.rgb * whiteBoost, colorBoost);

                return albedo;
            }
            ENDHLSL
        }
    }
}
