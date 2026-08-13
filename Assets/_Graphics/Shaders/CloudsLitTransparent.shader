// ChroMapper/Clouds Lit Transparent
// Replacement for the Beat Saber game shader Custom/CloudsLitTransparent
// (billie environment clouds).
// Recovered and verified line-by-line 2026-08-07 from the 1.44.3 DXBC
// (billieenvironment_scenes_all bundle), the compiled variant matching the
// BillieClouds material keyword set:
//   fragment-732b1e460d13565d.hlsl, vertex-5fb9ced67522fa87.glsl
//
// Vertex (recovered, ALIGN_NORMALS_TO_WORLD_ORIGIN variant):
//   angle  = (TEXCOORD1.xyz · _RotateLayerSpeeds.xyz) * _Time.x * deg2rad
//            (per-particle rotation layers; recovered adds a small time offset
//            cb0[159].x on top of _Time.x, which is 0 for the Billie material)
//   pos    = world pos rotated around the world Y axis: x' = c*x - s*z,
//            z' = s*x + c*z                    (swirl of the cloud sheet)
//   pos.y += sin(worldPos.x * _VertexWaveFrequency + _Time.z)   (asm 54-56:
//            * _VertexWaveAmplitude                      third time slot)
//   out: v1 = rotated world pos (runway fade), v2 = world-origin normal
//        (i.e. -normalize(world xz), built from the world X/Z only, lit like a
//        plane facing away from origin)
// Fragment (recovered):
//   scroll  = (_Time.x + _DistortTexSpeed.z) * _DistortTexSpeed.xy * ST.xy
//   uvDistort = uv * _DistortTex_ST + ST + scroll
//   d        = tex2D(_DistortTex, uvDistort)
//   uvMain   = uv * _DiffuseTexture_ST + ST
//              + _DistortAmount * (d.r - uvMain.x, d.a - uvMain.y)
//   base     = tex2D(_DiffuseTexture, uvMain)
//   light    = frontLobe + backLobe * _BackLightingBoost * base.g
//              (5 recovered directional lights; ChroMapper uses the main light)
//   bake     = per-instance lightmap color (uniform _LightBakeColor fallback
//              for the recovered cb2-indexed per-instance array)
//   bottom   = saturate((world.y - min) / (max - min)) ^ 2   (square, not smoothstep)
//   runway   = 1 - saturate(gate * _RunwayFadeScale / dist + _RunwayFadeOffset)
//              with dist = len(world.x, world.y-1, gate),
//              gate = (world.z > 0) ? 1 : 0   (strictly positive half only;
//              on the other side the offset alone drives the fade)  (FADE_RUNWAY)
//   color    = base.b * light * bake * bottom         (blue channel tints the whole)
//   alpha    = base.a * runway * bottom * bake.alpha
//              (recovered: r2 = (1,1,1,base.a) * bake[instance] at asm 103;
//              base.a reaches o0.w through r2.w, not r0.w)
Shader "ChroMapper/Clouds Lit Transparent"
{
    Properties
    {
        _DiffuseTexture ("Diffuse Texture", 2D) = "white" {}
        _DistortTex ("Distort Texture", 2D) = "black" {}

[Space(20)]
        _DistortTexSpeed ("Distort Tex Speed", Vector) = (0.4, 0, 0, 0)
        _DistortAmount ("Distort Amount", float) = 0.01

        [Space(20)]
        _Color ("Color", Color) = (1,1,1,1)
        _BackLightingBoost ("Backlighting Boost", float) = 1.5
        _LightBakeColor ("Light Bake Color", Color) = (1,1,1,1)

        [Space(20)]
        [Header(Fades)] [Space]
        _FadeBottomMin ("Fade Bottom Min", float) = -15
        _FadeBottomMax ("Fade Bottom Max", float) = 0
        _RunwayFadeOffset ("Runway Fade Offset", float) = -0.63
        _RunwayFadeScale ("Runway Fade Scale", float) = 10

        [Space(20)]
        [Header(Vertex)] [Space]
        _RotateLayerSpeeds ("Rotate Layer Speeds", Vector) = (4, 16, 24, 32)
        _VertexWaveFrequency ("Vertex Wave Frequency", float) = 4
        _VertexWaveAmplitude ("Vertex Wave Amplitude", float) = 0.06

        [Space(20)]
        _FogStartOffset ("Fog Start Offset", float) = 0
        _FogScale ("Fog Scale", float) = 1
        [KeywordEnum(None, Deferred, Mixed)] _BloomType ("White Boost", float) = 0
    }
    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
            "RenderType"="Transparent"
        }

        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        ZTest LEqual
        Cull Off

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            #pragma multi_compile _ STEREO_INSTANCING_ON

            #pragma shader_feature_local ALIGN_NORMALS_TO_WORLD_ORIGIN
            #pragma shader_feature_local_fragment BACK_LIGHTING
            #pragma shader_feature_local_fragment DIFFUSE
            #pragma shader_feature_local_fragment DIFFUSE_TEXTURE
            #pragma shader_feature_local_fragment DISTORT_TEXTURE
            #pragma shader_feature_local_fragment FADE_BOTTOM
            #pragma shader_feature_local_fragment FADE_RUNWAY
            #pragma shader_feature_local_vertex VERTEX_WAVE
            #pragma shader_feature_local_vertex _VERTEXMODE_ROTATELAYERS
            #pragma shader_feature_local_fragment _ _BLOOMTYPE_DEFERRED _BLOOMTYPE_MIXED

            #pragma multi_compile_fragment _ BLOOM_FOG
            #pragma multi_compile _ POST_BLOOM

            #include "UnityCG.cginc"
            #include "ShaderLibrary/Fog.hlsl"
            #include "ShaderLibrary/CustomBloom.hlsl"
            #include "ShaderLibrary/CloudShared.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float4 tex01  : TEXCOORD1; // per-particle rotation layer weights (x,y,z)
                float2 uv     : TEXCOORD2; // the main texture UV travels on TEXCOORD2
                float3 normal : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float2 uv       : TEXCOORD0;
                float3 world    : TEXCOORD1;
                float3 nor      : TEXCOORD2;
                float4 screenPos : TEXCOORD3;
                float4 position : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _DiffuseTexture;
            float4 _DiffuseTexture_ST;
            sampler2D _DistortTex;
            float4 _DistortTex_ST;
            float4 _DistortTexSpeed;
            float _DistortAmount;
            float4 _Color;
            float _BackLightingBoost;
            float4 _LightBakeColor;
            float _FadeBottomMin;
            float _FadeBottomMax;
            float _RunwayFadeOffset;
            float _RunwayFadeScale;
            float4 _RotateLayerSpeeds;
            float _VertexWaveFrequency;
            float _VertexWaveAmplitude;
            float _FogStartOffset;
            float _FogScale;

            v2f vert(appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                // per-particle rotation layer weights (TEXCOORD1.xyz)
                float3 wp = mul(unity_ObjectToWorld, v.vertex).xyz;
                float3 pos = wp;
                #if defined(_VERTEXMODE_ROTATELAYERS)
                float layerA = dot(v.tex01.xyz, _RotateLayerSpeeds.xyz);
                float angle = layerA * _Time.x * 0.0174532925199433;
                pos = RotateCloudPositionY(wp, angle);
                #endif

                // wave on the world Y; the phase is driven by the unrotated
                // world X and the time component (asm 54-56)
                #if defined(VERTEX_WAVE)
                pos.y += sin(wp.x * _VertexWaveFrequency + _Time.z) * _VertexWaveAmplitude;
                #endif

                o.world = pos;

                // world-origin aligned radial normal (horizontal, toward origin)
                #if defined(ALIGN_NORMALS_TO_WORLD_ORIGIN)
                o.nor = -normalize(float3(pos.x, 0.0, pos.z));
                #else
                o.nor = normalize(UnityObjectToWorldNormal(v.normal));
                #endif

                o.uv = v.uv;
                o.position = mul(unity_MatrixVP, float4(pos, 1.0));
                o.screenPos = ComputeScreenPosCustom(o.position);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                float4 base = 1.0;
                float2 uvM = i.uv * _DiffuseTexture_ST.xy + _DiffuseTexture_ST.zw;

                #if defined(DISTORT_TEXTURE)
                // distort pass (recovered: scroll = (time + offset) * speed * ST.xy)
                float2 tScroll = (_Time.x + _DistortTexSpeed.z) * _DistortTexSpeed.xy * _DistortTex_ST.xy;
                float2 uvD = i.uv * _DistortTex_ST.xy + _DistortTex_ST.zw + tScroll;
                float4 d = tex2D(_DistortTex, uvD);

                // main uv = uv*ST + ST.zw + _DistortAmount * (d.r - uv.x, d.a - uv.y)
                uvM += _DistortAmount * float2(d.r - uvM.x, d.a - uvM.y);
                #endif

                #if defined(DIFFUSE_TEXTURE)
                base = tex2D(_DiffuseTexture, uvM);
                #endif

                // light: recovered 5-direction sum simplified to the primary
                // recovered direction plus the back lobe. The source scales the
                // back lobe by _BackLightingBoost * diffuse.green (see asm 96-98).
                float3 N = normalize(i.nor);
                float3 Ld = normalize(_WorldSpaceLightPos0.xyz);
                float3 light = 1.0;
                #if defined(DIFFUSE)
                light = saturate(dot(N, Ld)) * _LightColor0.rgb;
                #if defined(BACK_LIGHTING)
                light += saturate(dot(-N, Ld)) * _LightColor0.rgb * (_BackLightingBoost * base.g);
                #endif
                #endif

                // per-instance light bake (recovered: cb2 indexed array; ChroMapper
                // substitutes a uniform). Alpha passes through the bake alpha.
                float3 bake = _LightBakeColor.rgb;
                float bakeA = _LightBakeColor.a;

                // bottom fade: saturate((world.y - min) / (max - min)) squared
                // (recovered 104-107: clamp then x*x, not smoothstep)
                float bot = 1.0;
                #if defined(FADE_BOTTOM)
                bot = CalculateSquaredRangeFade(i.world.y, _FadeBottomMin, _FadeBottomMax);
                #endif

                // runway fade (recovered 113-125):
                //   len   = length(world.x, world.y - 1, gate)
                //   factor = saturate(gate / len * _RunwayFadeScale + _RunwayFadeOffset)
                //   runway = 1 - factor       (gate is 1 only for world.z > 0)
                float runway = 1.0;
                #if defined(FADE_RUNWAY)
                runway = CalculateCloudRunwayFade(i.world, _RunwayFadeScale, _RunwayFadeOffset);
                #endif

                // recovered asm 60-61: final rgb is scaled by the diffuse BLUE
                // channel (r0.z survives the light multiply untouched)
                float3 color = base.b * light * bake * bot;
                float alpha = base.a * runway * bot * bakeA;   // base.a reaches alpha via r2.w (asm 103)

                float4 albedo = float4(color, alpha);
                albedo = ApplyBloomTypeWhiteBoost(
                    albedo, 1.0, alpha, 1.0,
                    _BaseColorBoost, _BaseColorBoostThreshold);
                #if defined(BLOOM_FOG)
                albedo = ApplyBloomFog(albedo, i.screenPos, i.world, _FogStartOffset, _FogScale);
                #endif
                return albedo;
            }
            ENDHLSL
        }
    }
}
