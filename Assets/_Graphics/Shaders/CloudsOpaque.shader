// ChroMapper/Clouds Opaque
// Replacement for the Beat Saber game shader Custom/CloudsOpaque (BTS clouds).
// Recovered from the 1.44.3 DXBC (bts_environment bundle):
//   fragment-119bc5fdf0893e09.hlsl (+ dither variant 485a517d5978ccac)
//   vertex-1effd9ad752a9c6e.glsl
//
// Verified line-by-line 2026-08-07 against the recovered programs:
//   - The swirl wave is multiplied by _Time.y:  angle = (v.x + wave * time) / v.z
//   - The wave carries the inverted sign of the phase: sign(-sin(v.z*12.345))
//   - The noise scroll runs on _Time.x (the slow time component), the swirl
//     on _Time.y.  scroll = _WorldNoiseScrolling.xy * _Speed * _Time.x
//   - The dither blend factor is `1 - heightFade * distFade` (the height fade
//     *reduces* the blending), not `distFade * heightFade`.
//   - The dither noise is sampled at raw NDC (v5.xy / v5.w), not mapped to
//     0..1 UV space first.
//   - The noise UV is sampled from the WORLD xz position, not the local one.
//   (The _Offset property is present in the game material data but is not
//   referenced by any program operand; it is kept for API compatibility.)
// Vertex (recovered):
//   phase  = sin(v.vertex.z * 12.345)
//   wave   = sign(-phase) * (phase * 0.5 + 1.0) * _WorldNoiseIntensityScale
//   angle  = (v.vertex.x + wave * _Time.y) / v.vertex.z   (time rotates the swirl)
//   pos    = (sin(angle) * v.z, v.y, cos(angle) * v.z)    (swirl around Y)
//   world  = ObjectToWorld * pos
//   pos.y += tex2Dlod(_NoiseTex, world.xz * _NoiseTex_ST + scroll).x
//            * _WorldNoiseScale + _WorldNoiseIntensityOffset   (world noise)
//   scroll = _WorldNoiseScrolling.xy * _Speed * _Time.x
// Outputs world position, inverted world-origin normal (-normalize(world)) and
// the main texture UV; dither UVs are derived from NDC in the fragment.
// Fragment (recovered):
//   distFade = 1 / (1 + max(0, dist2 * _FogScale + _FogStartOffset))
//   heightFade = smoothstep vertical band around _HeightFogOffset
//   ditherBlend = 1 - heightFade * distFade
//   color = saturate(tex * vertexColor * light) with light = 5-light sum
//   ENABLE_NOISE_DITHERING:  color = lerp(color, noise(NDC), ditherBlend)
//   (The recovered shader samples the dither noise at raw NDC through vertex
//   TEXCOORD5; ChroMapper instead scales/offsets the NDC with _NoiseTex_ST in
//   the fragment, the closest equivalent for an editor runtime.) alpha = 0.
Shader "ChroMapper/Clouds Opaque"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        _NoiseTex ("Noise Texture", 2D) = "black" {}

        [Space(20)]
        _WorldNoiseScale ("World Noise Scale", float) = 0.02
        _WorldNoiseIntensityScale ("World Noise Intensity Scale", float) = 2
        _WorldNoiseIntensityOffset ("World Noise Intensity Offset", float) = -1
        _WorldNoiseScrolling ("World Noise Scrolling", Vector) = (0.2, 0.2, 0, 1)

        [Space(20)]
        _Speed ("Speed", float) = 0.1
        _Offset ("Offset", float) = 0

        [Space(20)]
        _FogStartOffset ("Fog Start Offset", float) = 0
        _FogScale ("Fog Scale", float) = 0.08
        _HeightFogOffset ("Height Fog Offset", float) = 1

        [Space(20)]
        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull", float) = 0

        [Space(20)]
        [Toggle(DIFFUSE)] _EnableDiffuse ("Enable Diffuse", float) = 1
        [Toggle(WORLD_NOISE)] _EnableWorldNoise ("Enable World Noise", float) = 1
        [Toggle(INVERT_DIFFUSE_NORMAL)] _InvertDiffuseNormal ("Invert Diffuse Normal", float) = 1
        [Toggle(FOG)] _EnableFog ("Enable Fog", float) = 1
        [Toggle(NOISE_DITHERING)] _EnableNoiseDithering ("Noise Dithering", float) = 0
        [KeywordEnum(None, Deferred, Mixed)] _BloomType ("White Boost", float) = 0
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
            "Queue"="Geometry"
        }

        Cull [_Cull]
        ZWrite On
        ZTest LEqual

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            #pragma multi_compile _ STEREO_INSTANCING_ON

            #pragma shader_feature_local_fragment DIFFUSE
            #pragma shader_feature_local_vertex WORLD_NOISE
            #pragma shader_feature_local_fragment INVERT_DIFFUSE_NORMAL
            #pragma shader_feature_local_fragment FOG
            #pragma shader_feature_local_fragment NOISE_DITHERING
            #pragma shader_feature_local_fragment _ _BLOOMTYPE_DEFERRED _BLOOMTYPE_MIXED
            #pragma multi_compile _ POST_BLOOM

            #include "UnityCG.cginc"
            #include "ShaderLibrary/CustomBloom.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv     : TEXCOORD0;
                float4 color  : COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float2 uv       : TEXCOORD0;
                float4 color    : TEXCOORD1;
                float3 world    : TEXCOORD2;
                float3 nor      : TEXCOORD3;
                float4 position : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _NoiseTex;
            float4 _NoiseTex_ST;
            float _WorldNoiseScale;
            float _WorldNoiseIntensityScale;
            float _WorldNoiseIntensityOffset;
            float4 _WorldNoiseScrolling;
            float _Speed;
            float _Offset;
            float _FogStartOffset;
            float _FogScale;
            float _HeightFogOffset;

            v2f vert(appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                #if defined(WORLD_NOISE)
                float phase = sin(v.vertex.z * 12.345);
                float wave = sign(-phase) * (phase * 0.5 + 1.0) * _WorldNoiseIntensityScale;

                float angle = (v.vertex.x + wave * _Time.y) / v.vertex.z;
                float3 pos = float3(sin(angle) * v.vertex.z, v.vertex.y, cos(angle) * v.vertex.z);
                #else
                float3 pos = v.vertex.xyz;
                #endif

                // recovered: the fog position and the normal use the pre-noise
                // world position; only the clip position is noise-displaced
                float3 world = mul(unity_ObjectToWorld, float4(pos, 1.0)).xyz;
                o.world = world;
                o.nor = -normalize(world);

                o.uv = v.uv * _MainTex_ST.xy + _MainTex_ST.zw;
                o.color = v.color;

                #if defined(WORLD_NOISE)
                float2 scroll = _WorldNoiseScrolling.xy * _Speed * _Time.x;
                float2 nuv = world.xz * _NoiseTex_ST.xy + _NoiseTex_ST.zw + scroll;
                float noise = tex2Dlod(_NoiseTex, float4(nuv, 0, 0)).x;
                world.y += noise * _WorldNoiseScale + _WorldNoiseIntensityOffset;
                #endif

                o.position = mul(unity_MatrixVP, float4(world, 1.0));
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                float3 cameraPosition = _WorldSpaceCameraPos;
                #if defined(UNITY_SINGLE_PASS_STEREO) || defined(STEREO_INSTANCING_ON) || defined(STEREO_MULTIVIEW_ON)
                cameraPosition = unity_StereoWorldSpaceCameraPos[unity_StereoEyeIndex];
                #endif
                float3 d = i.world - cameraPosition;
                float dist2 = dot(d, d);
                float distFade = 1.0 / (1.0 + max(0.0, dist2 * _FogScale + _FogStartOffset));

                // recovered: t = clamp((world.y + _HeightFogOffset - band) / band),
                // then smoothstep-style t*t*(3-2t)
                float t = saturate((i.world.y + _HeightFogOffset) / _HeightFogOffset);
                float hFade = t * t * (3 - 2 * t);
                float fade = 1.0 - distFade * hFade;

                float3 normal = normalize(i.nor);
                #if defined(INVERT_DIFFUSE_NORMAL)
                normal = -normal;
                #endif
                float3 color = tex2D(_MainTex, i.uv).rgb * i.color.rgb;
                #if defined(DIFFUSE)
                float NdL = saturate(dot(normal, normalize(_WorldSpaceLightPos0.xyz)));
                color *= NdL * _LightColor0.rgb + unity_AmbientSky.rgb * 0.5;
                #endif
                color = saturate(color);

                #if defined(FOG)
                color = lerp(color, 0.1.xxx, fade);
                #endif

                #if defined(NOISE_DITHERING)
                float2 scr = i.position.xy / i.position.w;
                float noise = tex2D(_NoiseTex, scr * _NoiseTex_ST.xy + _NoiseTex_ST.zw).r;
                color = lerp(color, noise.xxx, fade);
                #endif

                float4 albedo = float4(color, 0);
                albedo = ApplyBloomTypeWhiteBoost(
                    albedo, 1.0, i.color.a, 1.0,
                    _BaseColorBoost, _BaseColorBoostThreshold);
                return albedo;
            }
            ENDHLSL
        }
    }
}
