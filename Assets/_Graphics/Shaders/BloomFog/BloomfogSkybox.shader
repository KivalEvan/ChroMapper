Shader "ChroMapper/BloomfogSkybox"
{
    Properties {}
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque" "Queue"="Geometry+100"
        }
        LOD 200
        Cull Off
        ZWrite Off
        ZTest LEqual

        Pass
        {
            HLSLPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fragment _ BLOOM_FOG
            #pragma multi_compile_instancing

            #include "UnityCG.cginc"
            #include "../ShaderLibrary/PostProcess.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 bloomScreenPos : TEXCOORD0;
                float4 noiseScreenPos : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _BloomPrePassTexture;
            sampler2D _GlobalBlueNoiseTex;
            float2 _CustomFogTextureToScreenRatio;
            float2 _GlobalBlueNoiseParams;
            float _GlobalRandomValue;

            v2f vert(appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

#if defined(UNITY_REVERSED_Z)
                o.vertex = float4(v.vertex.xy, 0.0, 1.0);
#else
                o.vertex = float4(v.vertex.xy, 1.0, 1.0);
#endif

                float2 normalizedPosition =
                    float2(v.vertex.x, v.vertex.y * _ProjectionParams.x) * 0.5 + 0.5;
                o.bloomScreenPos = float4(
                    (normalizedPosition - 0.5) * _CustomFogTextureToScreenRatio + 0.5,
                    0.0,
                    1.0);
                o.noiseScreenPos = float4(
                    normalizedPosition * _GlobalBlueNoiseParams + _GlobalRandomValue,
                    0.0,
                    1.0);
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

#if defined(BLOOM_FOG)
                half4 col = tex2D(
                    _BloomPrePassTexture,
                    i.bloomScreenPos.xy / i.bloomScreenPos.ww);
#else
                half4 col = half4(0.1, 0.1, 0.1, 0.0);
#endif
                col = ApplyNoiseDither(col, i.noiseScreenPos, _GlobalBlueNoiseTex);
                col.a = 0;
                return col;
            }
            ENDHLSL
        }
    }
}
