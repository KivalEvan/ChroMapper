// ChroMapper/Rain
// Replacement for the Beat Saber game shader Custom/Rain (billie environment).
// Recovered from the 1.44.3 DXBC (billieenvironment_scenes_all bundle):
//   mask route: fragment-c09e7dfcd141e0bc.hlsl + vertex-3141d8a8b702cbc3.glsl
//   RGBA route: fragment-1c0a05a85c1600db.hlsl + vertex-92ac3d56d79743bb.glsl
//
//   vertex math (recovered):
//   phase   = frac(vSeed - (_Time.xy + _TimeOffset).x * _Speed)
//   pos     = mul(v.vertex - (phase * v.streakDir), ObjectToWorld)
//   uv      = (v.uv.x * _MainTex_ST.xy + _MainTex_ST.zw) + (phase * _MainTex_ST.xy) + v.uv.z
//   bottom  = smoothstep over (worldY - _BottomEnd, band 1/_BottomFadeScale)
//   top     = smoothstep over (_TopEnd - worldY, band 1/_TopFadeScale)
//   v2      = (v.uv2.xyz, bottom * top * v.uv2.w)
// Fragment math (source, MASK route):
//   alphaSource = tex.red                     (MASK_RED_IS_ALPHA)
//   color = tex.rgb * _Intensity * _Color.rgb
//   alpha = alpha * _Color.a
//   alpha *= (v2.y * 0.4 + 0.7)               (per-particle curve)
//   alpha *= v2.w * v2.w                      (vertical fades, squared)
//   alpha = alpha * _AlphaMultiplier + _AlphaFromFog * 0.2
//   out = color * alpha, alpha (additive blend, One One)
// RGBA route: color = _Color.rgb (texture used for alpha only); no uv2/vfade.
Shader "ChroMapper/Rain"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _MaskTex ("Mask", 2D) = "white" {}

        [Space(20)]
        _Color ("Color", Color) = (1,1,1,1)
        _Intensity ("Intensity", float) = 1
        _AlphaMultiplier ("Alpha Multiplier", float) = 0.5
        _AlphaFromFog ("Alpha From Fog", float) = 0.183

        [Space(20)]
        _Speed ("Speed", float) = -7
        _TimeOffset ("Time Offset", Vector) = (0,0,0,0)

        [Space(20)]
        [Header(Fade Settings)] [Space]
        _BottomEnd ("Bottom End", float) = -5
        _BottomFadeScale ("Bottom Fade Scale", float) = 8.43
        _TopEnd ("Top End", float) = 20
        _TopFadeScale ("Top Fade Scale", float) = 20

        [Space(20)]
        [Toggle(MASK_RED_IS_ALPHA)] _AlphaSource ("Red Is Alpha", float) = 0

        [Space(20)]
        [KeywordEnum(None, Deferred, Mixed)] _BloomType ("White Boost", float) = 0

        [Space(20)]
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode ("Cull Mode", float) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("Z Test", float) = 4
    }
    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
            "RenderType"="Transparent"
        }

        Blend One One
        Cull [_CullMode]
        ZTest [_ZTest]
        ZWrite Off

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            #pragma multi_compile _ STEREO_INSTANCING_ON

            #pragma shader_feature_local_fragment MASK_RED_IS_ALPHA
            #pragma shader_feature_local_fragment TEXTURE_COLOR
            #pragma shader_feature_local_fragment VERTEX_COLOR
            #pragma shader_feature_local_fragment VERTEX_SQUARE_ALPHA
            #pragma shader_feature_local_fragment _FOGTYPE_COLOR
            #pragma shader_feature_local_fragment _ _BLOOMTYPE_DEFERRED _BLOOMTYPE_MIXED
            #pragma multi_compile _ POST_BLOOM

            #include "UnityCG.cginc"
            #include "ShaderLibrary/CustomBloom.hlsl"

            struct appdata
            {
                float4 vertex   : POSITION;
                float3 uv0      : TEXCOORD0; // x,y = uv; z = per-particle phase offset
                float3 uv1      : TEXCOORD1; // streak direction (world space)
                float4 uv2      : TEXCOORD2; // x = random seed, w = particle alpha
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float2 uv        : TEXCOORD0;
                float4 vfade     : TEXCOORD1; // y = particle curve input, w = vertical fade
                float4 position  : SV_POSITION;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Color;
            float _Intensity;
            float _AlphaMultiplier;
            float _AlphaFromFog;
            float _Speed;
            float4 _TimeOffset;

            float _BottomEnd;
            float _BottomFadeScale;
            float _TopEnd;
            float _TopFadeScale;

            v2f vert(appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                float phase = frac(v.uv2.x - (_Time.x + _TimeOffset.x) * _Speed);

                float3 local = v.vertex.xyz - (phase * v.uv1.xyz);
                float3 world = mul(unity_ObjectToWorld, float4(local, 1.0)).xyz;

                float2 uv = v.uv0.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                uv += (phase * _MainTex_ST.xy) + v.uv0.zz;
                o.uv = uv;

                float bottom = saturate((world.y - _BottomEnd) / max(_BottomFadeScale, 1e-5));
                float top    = saturate((_TopEnd - world.y) / max(_TopFadeScale, 1e-5));
                float vertical = bottom * bottom * (3 - 2 * bottom) * (top * top * (3 - 2 * top));

                o.vfade = float4(v.uv2.xyz, vertical * v.uv2.w);
                o.position = UnityObjectToClipPos(float4(local, 1.0));
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float4 tex = tex2D(_MainTex, i.uv);
                float alpha;
                float3 color;

                #ifdef MASK_RED_IS_ALPHA
                alpha = tex.r;
                #else
                alpha = tex.a;
                #endif

                #if defined(TEXTURE_COLOR)
                color = tex.rgb * _Intensity * _Color.rgb;
                #else
                color = _Color.rgb * _Intensity;
                #endif

                alpha *= _Color.a;
                #if defined(VERTEX_COLOR)
                alpha *= i.vfade.y * 0.4 + 0.7;
                #endif
                #if defined(VERTEX_SQUARE_ALPHA)
                alpha *= i.vfade.w * i.vfade.w;
                #endif
                alpha *= _AlphaMultiplier;
                #if defined(_FOGTYPE_COLOR)
                alpha += _AlphaFromFog * 0.2;
                #endif

                float4 albedo = float4(color, alpha);
                albedo = ApplyBloomTypeWhiteBoost(
                    albedo, 1.0, alpha, 1.0,
                    _BaseColorBoost, _BaseColorBoostThreshold);
                return float4(albedo.rgb * albedo.a, albedo.a);
            }
            ENDHLSL
        }
    }
}
