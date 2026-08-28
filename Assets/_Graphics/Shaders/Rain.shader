Shader "ChroMapper/Rain"
{
    // AUDIT FINDINGS
    // R1 [vertex-4192813907dab31b,3141d8a8b702cbc3,92ac3d56d79743bb]:
    // cb0[137].w is _Height. The authoritative
    // phase is frac(seed.x - (_Time.x + _TimeOffset.x) * _Speed), and local is
    // vertex - phase * _Height * streak. Billie imports _Height=25, _Speed=-7.
    // _TimeOffset is absent from the authoritative Custom_Rain.shader
    // Properties; it remains an unexposed runtime HLSL uniform required by
    // ASM.
    // R2 [vertex-4192813907dab31b,3141d8a8b702cbc3,92ac3d56d79743bb]:
    // UV panning uses _UvPanning.xy, with
    // time.y = _Time.y + _TimeOffset.y, after texture ST scale and offset;
    // Billie _UvPanning=(0,0,0,0). The converted Rain mesh stores the game
    // inputs as uv=TEXCOORD0, streak=NORMAL, and seed=COLOR; reading nonexistent
    // TEXCOORD1/2 made displacement zero and collapsed all random phases.
    // Bottom fade is smooth and the active VERTEX_COLOR top fade is linear.
    // R3 [c09e7dfc,1c0a05a8]: texture alpha is tex.r for RED routes, otherwise
    // tex.a; TEXTURE_COLOR uses tex.rgb * _Intensity * _Color.rgb. Vertex
    // color applies _Color.a, (vfade.y * 0.4 + 0.7), and the controlled
    // VERTEX_SQUARE_ALPHA curve squares vfade.w.
    // R4 [b6296fc7,c09e7dfc]: color fog uses the bloom prepass max channel
    // formula for BLOOM_FOG and the fixed non-bloom alpha formula. Output is
    // premultiplied (color * alpha, alpha); SampleBloomPrePass owns UV ratio.
    // R5 [MaterialProcessor.cs]: imported game _Blend*Factor names remap to
    // canonical _BlendModeSrc/Dst/SrcA/DstA. ENABLE_ keyword prefixes normalize
    // to the local shader keywords used below.
    // R6 [Billie/Rain.mat]: active routes are TEXTURE_COLOR, RED alpha,
    // MASK_RED_IS_ALPHA, VERTEX_COLOR, and VERTEX_SQUARE_ALPHA; _AlphaMultiplier
    // is 0.5, _AlphaFromFog=0.183, fades are bottom -5/8.43 and top 20/20,
    // _MainTex ST is (0.8,0.8,0.16,0), and _UvPanning is zero.
    // Gradient, masks, soft particles, camera/view/lifetime effects, height or
    // precise fog, hologram, noise, white boost, vertex-channel selection,
    // and SQUARE_ALPHA are inert. The retained render-state properties are
    // property-driven. No speculative DEPTH or alternate route is retained.
    // R7 [MaterialProcessor.cs]: KeywordEnum recovers `_FOGTYPE_COLOR` from
    // the imported game keyword set, which does not include a `_FogType` float.
    // The generated ChroMapper material then stores `_FogType=2`; together they
    // select the verified c09e7dfc/b6296fc7 color-fog alpha route.
    Properties
    {
        [Header(Rain)] [Space(10)] _Height ("Height", Float) = 10
        _Speed ("Speed", Float) = 1
        [Space(10)] _BottomFadeScale ("Bottom Fade Scale", Float) = 1
        _TopFadeScale ("Top Fade Scale", Float) = 1
        _BottomEnd ("Bottom End", Float) = 1
        _TopEnd ("Top End", Float) = 1
        [Space(20)] _Color ("Color", Vector) = (1,1,1,1)
        [Toggle(COLOR_GRADIENT)] _EnableColorGradient ("Use Color Gradient", Float) = 0
        [ShowIfAny(COLOR_GRADIENT)] _ColorGradient ("Gradient LUT", 2D) = "white" {}
        [Space] _MainTex ("Main Texture", 2D) = "black" {}
        [Toggle(TEXTURE_COLOR)] _EnableTextureColor ("Use Texture Color", Float) = 0
        [KeywordEnum(Alpha, Red)] _AlphaChannel ("Alpha Channel", Float) = 0
        _Intensity ("Intensity", Float) = 1
        _UvPanning ("UV Panning", Vector) = (0,0,0,0)
        [Space(12)] [Toggle(MASK)] _EnableMask ("Use Mask", Float) = 0
        [ToggleShowIfAny(MASK_ADDITIVE, MASK)] _MaskAdditive ("Blend Additively", Float) = 0
        [ToggleShowIfAny(MASK_RED_IS_ALPHA, MASK)] _MaskRedIsAlpha ("Red is Mask Alpha", Float) = 0
        [ShowIfAny(MASK)] _MaskTex ("Mask Texture", 2D) = "white" {}
        [ShowIfAny(MASK)] _MaskPanning ("Mask Panning", Vector) = (0,0,0,0)
        [ShowIfAny(MASK)] _MaskStrength ("Mask Strength", Float) = 1
        [Space(12)] [Toggle(MASK2)] _EnableMask2 ("Use Secondary Mask", Float) = 0
        [ToggleShowIfAny(MASK2_RED_IS_ALPHA, MASK2)] _Mask2RedIsAlpha ("Red is Mask Alpha", Float) = 0
        [ShowIfAny(MASK2)] _Mask2Tex ("Secondary Mask Texture", 2D) = "white" {}
        [ShowIfAny(MASK2)] _Mask2Panning ("Secondary Mask Panning", Vector) = (0,0,0,0)
        [ShowIfAny(MASK2)] _Mask2MinValue ("Min Mask Value", Float) = 0
        [Space(12)] [Toggle(SOFT_PARTICLES)] _EnableSoftParticles ("Soft Particles", Float) = 0
        [ShowIfAny(SOFT_PARTICLES)] _SoftFactor ("Soft Factor", Range(0, 50)) = 0
        [Space(12)] [Toggle(CLOSE_TO_CAMERA_DISAPPEAR)] _EnableCloseToCameraDisappear ("Close to Camera Dissapear", Float) = 0
        [ShowIfAny(CLOSE_TO_CAMERA_DISAPPEAR)] _CloseToCameraOffset ("Close to Camera Offset", Float) = 0.5
        [ShowIfAny(CLOSE_TO_CAMERA_DISAPPEAR)] _CloseToCameraFactor ("Close to Camera Factor", Float) = 0.5
        [Space(12)] [Toggle(VIEW_ALIGN_DISAPPEAR)] _EnableViewAlignDisappear ("View Align Dissapear", Float) = 0
        [ShowIfAny(VIEW_ALIGN_DISAPPEAR)] _ViewAlignFactor ("View Align Factor", Float) = 1.5
        [Space(12)] [Toggle(VERTEX_COLOR)] _EnableVertexColor ("Enable Vertex Color", Float) = 0
        [ToggleShowIfAny(VERTEX_SQUARE_ALPHA, VERTEX_COLOR)] _SquareVertexAlpha ("Square Vertex Alpha", Float) = 0
        [ToggleShowIfAny(VERTEX_RED_IS_ALPHA, VERTEX_COLOR)] _RedIsVertexAlpha ("Red is Vertex Alpha", Float) = 0
        [EnumShowIfAny(3, RGBA, A, RGB, VERTEX_COLOR)] _VertexChannels ("Vertex Channels", Float) = 0
        [ToggleShowIfAny(LIFETIME, VERTEX_COLOR)] _EnableLifetime ("Enable Lifetime Alpha", Float) = 0
        [Space(12)] [KeywordEnum(None, Alpha, Color, Lerp)] _FogType ("Fog Type", Float) = 0
        [ShowIfAny(_FOGTYPE_ALPHA, _FOGTYPE_LERP)] _FogStartOffset ("Fog Start Offset", Float) = 0
        [ShowIfAny(_FOGTYPE_ALPHA, _FOGTYPE_LERP)] _FogScale ("Fog Scale", Range(0, 4)) = 1
        [ShowIfAny(_FOGTYPE_COLOR)] _AlphaFromFog ("Alpha from Fog", Range(0, 1)) = 0.5
        [ToggleShowIfAny(HEIGHT_FOG, _FOGTYPE_ALPHA, _FOGTYPE_LERP)] _EnableHeightFog ("Enable Height Fog", Float) = 0
        [ToggleShowIfAny(PRECISE_FOG, _FOGTYPE_ALPHA, _FOGTYPE_LERP)] _PreciseFog ("High (Frag) Precision", Float) = 0
        [Space(12)] [Toggle(HOLOGRAM)] _EnableHologram ("Hologram effect", Float) = 0
        [ShowIfAny(HOLOGRAM)] _HologramColor ("Hologram Color", Vector) = (1,1,1,1)
        [Space()] [Header(Other)] [Space] [Toggle(SQUARE_ALPHA)] _SquareAlpha ("Square Alpha", Float) = 1
        _AlphaMultiplier ("Alpha Multiplier", Float) = 1
        [KeywordEnum(None, MainEffect, Always)] _WhiteBoostType ("White Boost", Float) = 0
        [Toggle(NOISE_DITHERING)] _EnableNoiseDithering ("Noise Dithering", Float) = 0
        [Space] [Space(12)] [Header(Settings)] [Space] [Enum(UnityEngine.Rendering.BlendMode)] _BlendModeSrc ("Blend Src", Float) = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendModeDst ("Blend Dst", Float) = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendModeSrcA ("Blend Src Factor A", Float) = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendModeDstA ("Blend Dst Factor A", Float) = 10
        [Enum(UnityEngine.Rendering.BlendOp)] _BlendOp ("Blend Operation", Float) = 0
        [Space] [Enum(UnityEngine.Rendering.CullMode)] _CullMode ("Cull Mode", Float) = 0
        [Space] [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("ZTest", Float) = 4
        [Space] _OffsetFactor ("Offset Factor", Float) = 0
        _OffsetUnits ("Offset Units", Float) = 0
        _StencilRefValue ("Stencil Ref Value", Float) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)] _StencilComp ("Stencil Comp Func", Float) = 8
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilPass ("Stencill Pass Op", Float) = 0
    }

    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        Blend [_BlendModeSrc] [_BlendModeDst], [_BlendModeSrcA] [_BlendModeDstA]
        BlendOp [_BlendOp]
        Cull [_CullMode]
        ZTest [_ZTest]
        ZWrite Off
        Offset [_OffsetFactor], [_OffsetUnits]
        Stencil { Ref [_StencilRefValue] Comp [_StencilComp] Pass [_StencilPass] }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            #pragma shader_feature_local TEXTURE_COLOR
            #pragma shader_feature_local _ALPHACHANNEL_RED
            #pragma shader_feature_local MASK_RED_IS_ALPHA
            #pragma shader_feature_local VERTEX_COLOR
            #pragma shader_feature_local VERTEX_SQUARE_ALPHA
            #pragma shader_feature_local _FOGTYPE_COLOR
            #pragma multi_compile_fragment _ BLOOM_FOG
            #include "UnityCG.cginc"
            #include "ShaderLibrary/Camera.hlsl"
            #include "ShaderLibrary/Fog.hlsl"

            sampler2D _MainTex;
            float4 _Color, _UvPanning, _TimeOffset, _MainTex_ST;
            float _Height, _Speed, _BottomEnd, _BottomFadeScale, _TopEnd, _TopFadeScale;
            float _Intensity, _AlphaFromFog, _AlphaMultiplier;

            struct appdata
            {
                float4 vertex:POSITION;
                float3 uv:TEXCOORD0;
                float3 streak:NORMAL;
                float4 seed:COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            struct v2f
            {
                float2 uv:TEXCOORD0;
                float4 vfade:TEXCOORD1;
                float4 screenPos:TEXCOORD2;
                float4 pos:SV_POSITION;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert(appdata v)
            {
                v2f o; UNITY_SETUP_INSTANCE_ID(v); UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                float2 time = float2(
                    _Time.x + _TimeOffset.x,
                    _Time.y + _TimeOffset.y);
                float phase = frac(v.seed.x - (_Time.x + _TimeOffset.x) * _Speed);
                float3 local = v.vertex.xyz - phase * _Height * v.streak;
                float3 world = mul(unity_ObjectToWorld, float4(local, 1.0)).xyz;
                o.pos = UnityObjectToClipPos(float4(local, 1.0));
                o.screenPos = ComputeScreenPosCustom(o.pos);
                o.uv = v.uv.xy * _MainTex_ST.xy + _MainTex_ST.zw +
                    time.y * _UvPanning.xy * _MainTex_ST.xy + v.uv.z;

                float bottom = smoothstep(0.0, 1.0,
                    saturate((world.y - _BottomEnd) / _BottomFadeScale));
                #if defined(VERTEX_COLOR)
                    float top = saturate((_TopEnd - world.y) / _TopFadeScale);
                #else
                    float top = smoothstep(0.0, 1.0,
                        saturate((_TopEnd - world.y) / _TopFadeScale));
                #endif
                float vertical = bottom * top;
                o.vfade = float4(v.seed.xyz, vertical * v.seed.w);
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float4 tex = tex2D(_MainTex, i.uv);
                #if defined(_ALPHACHANNEL_RED) || defined(MASK_RED_IS_ALPHA)
                    float baseAlpha = tex.r;
                #else
                    float baseAlpha = tex.a;
                #endif
                float3 color;
                #if defined(TEXTURE_COLOR)
                    color = tex.rgb * _Intensity * _Color.rgb;
                #else
                    color = _Color.rgb * _Intensity;
                #endif
                baseAlpha *= _Color.a;
                #if defined(VERTEX_COLOR)
                    baseAlpha *= i.vfade.y * 0.4 + 0.7;
                    #if defined(VERTEX_SQUARE_ALPHA)
                        baseAlpha *= i.vfade.w * i.vfade.w;
                    #endif
                #endif
                float alpha = baseAlpha * _AlphaMultiplier;
                #if defined(_FOGTYPE_COLOR)
                    #if defined(BLOOM_FOG)
                        // b6296fc7: SampleBloomPrePass applies the screen
                        // ratio once to the unnormalized projected position.
                        float3 bloom = SampleBloomPrePass(i.screenPos).rgb;
                        alpha = baseAlpha * _AlphaMultiplier +
                            (max(bloom.r, max(bloom.g, bloom.b)) * 3.0 - 0.1) *
                            _AlphaFromFog;
                    #else
                        // c09e7dfc: the non-bloom color-fog fallback is fixed.
                        alpha = baseAlpha * _AlphaMultiplier + _AlphaFromFog * 0.2;
                    #endif
                #endif
                return float4(color * alpha, alpha);
            }
            ENDHLSL
        }
    }
}
