Shader "ChroMapper/Sky Gradient"
{
    Properties
    {
        _GradientTex("Gradient Texture", 2D) = "white" {}
        _Color("Color", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Background" "Queue"="Background"
        }
        LOD 100
        Cull Off
        ZWrite Off
        ZTest Always
        Blend One One, Zero Zero

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fragment _ USE_TONE_MAPPING
            #pragma multi_compile_fragment _ ACES_TONE_MAPPING

            #include "UnityCG.cginc"
            #include "../ShaderLibrary/CustomTonemapping.hlsl"

            struct appdata
            {
                float3 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            uniform float4x4 _InverseProjectionMatrix;
            uniform float4x4 _CameraToWorldMatrix;
            sampler2D _GradientTex;
            float4 _Color;

            v2f vert(appdata v)
            {
                v2f o;
                // Unity 6's Graphics.Blit mesh uses normalized [0, 1] positions.
                float2 uv = v.vertex.xy;
                o.vertex = float4(uv * 2.0 - 1.0, 0.0, 1.0);
                o.uv = uv;
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                float4 clipPosition = float4(i.uv * 2.0 - 1.0, 1.0, 1.0);
                float4 viewPosition = mul(_InverseProjectionMatrix, clipPosition);
                viewPosition.xyz /= viewPosition.w;

                float3 direction = normalize(
                    mul(_CameraToWorldMatrix, float4(viewPosition.xyz, 0.0)).xyz);
                float gradientCoordinate = direction.y * 0.5 + 0.5;
                half4 color = tex2D(_GradientTex, float2(gradientCoordinate, 0.5)) * _Color;

#if defined(USE_TONE_MAPPING) || defined(ACES_TONE_MAPPING)
                color = ApplyAcesTonemapping(color);
#endif
                return color;
            }
            ENDHLSL
        }
    }
}
