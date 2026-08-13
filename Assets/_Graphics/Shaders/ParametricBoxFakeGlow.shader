// Replacement for the Beat Saber game shader Custom/ParametricBoxFakeGlow.
Shader "ChroMapper/Parametric Box Fake Glow"
{
    Properties
    {
        _Color ("Color", Color) = (1, 1, 1, 1)
        _MainTex ("Texture", 2D) = "white" {}
        [KeywordEnum(None, Deferred, Mixed)] _BloomType ("White Boost", float) = 1

        _SizeParams("Size Params", Vector) = (3,2,0,0.3)
        [Space] _AngleDisappearParam ("Angle Disappear Param", float) = 1
        [Toggle(CUTOUT)] _EnableCutout ("Enable Vertex Cutout", float) = 0
        [ToggleShowIfAny(WORLDSPACE_NOISE_CUTOUT, CUTOUT)] _WorldspaceNoiseCutout ("Worldspace Noise Cutout", float) = 0
        [ShowIfAny(2, CUTOUT, WORLDSPACE_NOISE_CUTOUT)] _CutoutTexScale ("Cutout Noise Scale", float) = 1
        [ShowIfAny(CUTOUT)] _Cutout ("Cutout", Range(0, 1)) = 0
        [HideInInspector] _CutoutTex ("Cutout Texture", 3D) = "white" {}
        [Toggle(CLIPPING)] _EnableClipping ("Enable Clipping", float) = 0
        [ShowIfAny(CLIPPING)] _ClipPlane ("Clip Plane", Vector) = (0,1,0,0)

        [Header(Fog Settings)] [Space]
        _FogStartOffset ("Fog Start Offset", float) = 1
        _FogScale ("Fog Scale", float) = 1
        [Space]
        [ToggleShowIfAny(HEIGHT_FOG, FOG)] _EnableHeightFog ("Enable Height Fog", float) = 0
        [ShowIfAny(2, FOG, HEIGHT_FOG)] _FogHeightOffset ("Fog Height Offset", float) = 0
        [ShowIfAny(2, FOG, HEIGHT_FOG)] _FogHeightScale ("Fog Height Scale", float) = 1

        [Header(Settings)] [Space]
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendModeSrc ("Blend Src", float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendModeDst ("Blend Dst", float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendModeSrcA ("Blend Src A", float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendModeDstA ("Blend Dst A", float) = 1
        [Enum(UnityEngine.Rendering.BlendOp)] _BlendOp ("Blend Operation", float) = 0

        [Space]
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode ("Cull Mode", float) = 2
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("Z Test", float) = 4
    }

    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
            "IgnoreProjector"="True"
            "RenderType"="Transparent"
        }

        Blend [_BlendModeSrc] [_BlendModeDst], [_BlendModeSrcA] [_BlendModeDstA]
        BlendOp [_BlendOp]
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
            #pragma multi_compile _ BLOOM_FOG
            #pragma shader_feature_local HEIGHT_FOG
            #pragma multi_compile_local _FOGTYPE_ALPHA
            #pragma shader_feature_local _ _BLOOMTYPE_DEFERRED _BLOOMTYPE_MIXED
            #pragma shader_feature_local_fragment CUTOUT
            #pragma shader_feature_local_fragment WORLDSPACE_NOISE_CUTOUT
            #pragma shader_feature_local_fragment CLIPPING
            // Global: the post-process bloom runs (mirrors the game's MAIN_EFFECT_ENABLED gate).
            #pragma multi_compile _ POST_BLOOM

            #include "UnityCG.cginc"
            #include "ShaderLibrary/Camera.hlsl"
            #include "ShaderLibrary/Fog.hlsl"
            #include "ShaderLibrary/CustomBloom.hlsl"
            #include "ShaderLibrary/Cutout.hlsl"
            #include "ShaderLibrary/ParametricShared.hlsl"

            UNITY_INSTANCING_BUFFER_START(Props)
                UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
                UNITY_DEFINE_INSTANCED_PROP(float4, _SizeParams)
            UNITY_INSTANCING_BUFFER_END(Props)

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
                float3 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD2;
                float4 screenPos : TEXCOORD3;
                float3 localPos : TEXCOORD4;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float _AngleDisappearParam;
            sampler3D _CutoutTex;
            float _CutoutTexScale;
            float _Cutout;
            float4 _ClipPlane;

            float _FogStartOffset;
            float _FogScale;
            float _FogHeightOffset;
            float _FogHeightScale;

            v2f vert(appdata i)
            {
                v2f o;

                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                UNITY_TRANSFER_INSTANCE_ID(i, o);

                float4 sizeParams = UNITY_ACCESS_INSTANCED_PROP(Props, _SizeParams);

                // DXBC 139018e7: retain each vertex's face and scale its offset
                // from that face to keep the border width constant.
                float3 faceSide = sign(i.vertex.xyz);
                i.vertex.xyz = faceSide +
                    (i.vertex.xyz - faceSide) * (2.0 * sizeParams.w / sizeParams.xyz);

                o.vertex = UnityObjectToClipPos(i.vertex);

                o.uv.xy = i.uv.xy;
                o.worldPos = mul(unity_ObjectToWorld, i.vertex).xyz;
                o.localPos = i.vertex.xyz;
                o.screenPos = ComputeScreenPosCustom(o.vertex);

                float3 viewDirection = normalize(o.worldPos - GetParametricCameraPosition());
                float3 worldNormal = normalize(mul((float3x3)unity_ObjectToWorld, i.normal));
                o.uv.z = min(abs(dot(viewDirection, worldNormal)), 1.0);

                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                half4 color = UNITY_ACCESS_INSTANCED_PROP(Props, _Color);

                // DXBC e329b30d: texture alpha is squared; texture RGB is not sampled.
                float alpha = tex2D(_MainTex, TRANSFORM_TEX(i.uv.xy, _MainTex)).a;
                alpha *= alpha;
                alpha *= saturate(i.uv.z * _AngleDisappearParam * color.a);

                #if defined(CUTOUT)
                float3 cutoutPosition = i.localPos;
                #if defined(WORLDSPACE_NOISE_CUTOUT)
                cutoutPosition = i.worldPos;
                #endif
                ApplyCutoutNoise(
                    tex3D(_CutoutTex, cutoutPosition * _CutoutTexScale).r, _Cutout);
                #endif
                #if defined(CLIPPING)
                clip(dot(float4(i.worldPos, 1.0), _ClipPlane));
                #endif

                #if defined(BLOOM_FOG)
                // The recovered bloom-fog path attenuates alpha. It does not sample the
                // bloom pre-pass and does not apply a color transform.
                float3 cameraPosition = GetParametricCameraPosition();
                float fogInverse = CalculateParametricDistanceTransmission(
                    i.worldPos, cameraPosition, _FogStartOffset, _FogScale, 1.0,
                    _CustomFogOffset, _CustomFogAttenuation);
                #if defined(HEIGHT_FOG)
                float heightFade = CalculateParametricHeightRamp(
                    i.worldPos.y, _FogHeightScale, _FogHeightOffset,
                    _CustomFogHeightFogHeight, _CustomFogHeightFogStartY);
                alpha *= saturate(heightFade * fogInverse);
                #else
                alpha *= saturate(fogInverse);
                #endif
                #else
                #if defined(HEIGHT_FOG)
                alpha *= CalculateParametricHeightRamp(
                    i.worldPos.y, _FogHeightScale, _FogHeightOffset,
                    _CustomFogHeightFogHeight, _CustomFogHeightFogStartY);
                #endif
                #endif

                half4 result = half4(color.rgb * alpha, alpha);
                // acbb090e reads only the shared base boost and threshold slots.
                // The dispatcher preserves the additive and POST_BLOOM contracts.
                result = ApplyBloomTypeComposition(
                    result, color.rgb, 1, alpha, 1,
                    _BaseColorBoost, _BaseColorBoostThreshold, 0, alpha);
                return result;
            }
            ENDHLSL
        }
    }
}
