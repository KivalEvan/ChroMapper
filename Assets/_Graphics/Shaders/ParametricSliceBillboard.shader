// Replacement for the Beat Saber game shader Custom/Parametric3SliceSprite.
Shader "ChroMapper/Parametric Slice Billboard"
{
    Properties
    {
        _Color ("Color", Color) = (1, 1, 1, 1)
        _MainTex ("Texture", 2D) = "white" {}
        _CapUVSize ("Cap UV Size", Float) = 0.25

        _SizeParams("Size Params", Vector) = (0.25,10,0,0.5)
        [Toggle(ALPHA_WIDTH_SCALE)] _EnableAlphaWidthScale ("Alpha Width Scale", float) = 0
        _AlphaWidth("Alpha Width", Vector) = (1,1,1,1)

        [KeywordEnum(None, Deferred, Mixed)] _BloomType ("White Boost", float) = 0
        [ShowIfAny(_BLOOMTYPE_DEFERRED, _BLOOMTYPE_MIXED)] _BloomWhiteMultiplier ("White Multiplier", float) = 1
        _BloomMultiplier ("Bloom Multiplier", float) = 1

        [Header(Others)] [Space]
        [Toggle(SQUARE_ALPHA)] _SquareAlpha("Square Alpha", float) = 0
        [Toggle(ANGLE_DISAPPEAR)] _AngleDisappear("Angle Disappear", float)= 10
        [Toggle(Y_AXIS_BILLBOARD)] _EnableYAxisBillboard ("Y Axis Billboard", float) = 1
        [Toggle(WORLD_NOISE)] _EnableWorldNoise ("Enable World Noise", float) = 0
        _WorldNoiseScale ("World Noise Scale", float) = 1
        _WorldNoiseIntensityOffset ("World Noise Intensity Offset", float) = 0
        _WorldNoiseIntensityScale ("World Noise Intensity Scale", float) = 1
        _WorldNoiseScrolling ("World Noise Scrolling", Vector) = (0,0,0,1)
        [Toggle(WORLD_SPACE_FADE)] _EnableWorldSpaceFade ("Enable World Space Fade", float) = 0
        _WorldSpaceFadePos ("World Space Fade Position", float) = 0
        _WorldSpaceFadeSlope ("World Space Fade Slope", float) = 1
        [ToggleShowIfAny(WORLD_NOISE_WARP, WORLD_NOISE)] _WorldNoiseSkew ("Noise Field Warp", float) = 0
        _NoiseWarpZoomStrength ("Noise Warp Zoom Strength", float) = 0
        _NoiseWarpSkewStrength ("Noise Warp Skew Strength", float) = 0
        [Toggle(NOISE_DITHERING)] _EnableNoiseDithering ("Enable Noise Dithering", float) = 0

        [Header(Fog Settings)] [Space]
        [Toggle(FOG)] _EnableFog ("Enable Fog", float) = 1
        [ShowIfAny(FOG)] _FogStartOffset ("Fog Start Offset", float) = 1
        [ShowIfAny(FOG)] _FogScale ("Fog Scale", float) = 1
        [Space]
        [ToggleShowIfAny(HEIGHT_FOG, FOG)] _EnableHeightFog ("Enable Height Fog", float) = 1
        [ShowIfAny(2, FOG, HEIGHT_FOG)] _FogHeightOffset ("Fog Height Offset", float) = 0
        [ShowIfAny(2, FOG, HEIGHT_FOG)] _FogHeightScale ("Fog Height Scale", float) = 1
        [Space]
        [ToggleShowIfAny(USE_FOG_FOR_LIGHTS, FOG)] _UseFogForLights("Use Fog For Lights", float) = 1

        [Header(Settings)] [Space]
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendModeSrc ("Blend Src", float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendModeDst ("Blend Dst", float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendModeSrcA ("Blend Src A", float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendModeDstA ("Blend Dst A", float) = 1
        [Enum(UnityEngine.Rendering.BlendOp)] _BlendOp ("Blend Operation", float) = 0

        [Space]
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode ("Cull Mode", float) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("Z Test", float) = 4
        _OffsetFactor ("Offset Factor", Float) = 0
        _OffsetUnits ("Offset Units", Float) = 0
        [Header(Stencil)] [Space]
        _StencilRefValue ("Stencil Ref Value", Float) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)] _StencilComp ("Stencil Comp Func", Float) = 8
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilPass ("Stencil Pass Op", Float) = 0
    }

    SubShader
    {
        Tags
        {
            "PreviewType"="Plane"
            "CanUseSpriteAtlas"="True"
            "Queue"="Transparent"
            "IgnoreProjector"="True"
            "RenderType"="Transparent"
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
            #pragma multi_compile _ STEREO_INSTANCING_ON

            #pragma shader_feature_local_vertex ALPHA_WIDTH_SCALE
            #pragma shader_feature_local_fragment SQUARE_ALPHA
            #pragma shader_feature_local_fragment ANGLE_DISAPPEAR
            #pragma shader_feature_local_vertex Y_AXIS_BILLBOARD
            #pragma shader_feature_local_fragment _ _BLOOMTYPE_DEFERRED _BLOOMTYPE_MIXED
            // Global: the post-process bloom runs (mirrors the game's MAIN_EFFECT_ENABLED gate).
            #pragma multi_compile _ POST_BLOOM

            #pragma multi_compile_local_fragment _FOGTYPE_ALPHA
            #pragma shader_feature_local_fragment FOG
            #pragma shader_feature_local_fragment HEIGHT_FOG
            #pragma shader_feature_local_fragment USE_FOG_FOR_LIGHTS
            #pragma shader_feature_local_fragment WORLD_NOISE
            #pragma shader_feature_local_fragment WORLD_SPACE_FADE
            #pragma shader_feature_local_fragment WORLD_NOISE_WARP
            #pragma shader_feature_local_fragment NOISE_DITHERING

            #pragma multi_compile_fragment _ BLOOM_FOG

            #include "UnityCG.cginc"
            #include "ShaderLibrary/Camera.hlsl"
            #include "ShaderLibrary/Fog.hlsl"
            #include "ShaderLibrary/CustomBloom.hlsl"
            #include "ShaderLibrary/ParametricShared.hlsl"
            #include "ShaderLibrary/PostProcess.hlsl"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _CapUVSize; // Fixed: was incorrectly declared as float2

            float _BloomMultiplier;
            float _BloomWhiteMultiplier;

            float _FogStartOffset;
            float _FogScale;
            float _FogHeightOffset;
            float _FogHeightScale;
            sampler3D _CutoutTex;
            float _WorldNoiseScale;
            float _WorldNoiseIntensityOffset;
            float _WorldNoiseIntensityScale;
            float3 _WorldNoiseScrolling;
            float _WorldSpaceFadePos;
            float _WorldSpaceFadeSlope;
            float _NoiseWarpZoomStrength;
            float _NoiseWarpSkewStrength;
            float4 _TimeHelperOffset;
            sampler2D _GlobalBlueNoiseTex;
            float2 _GlobalBlueNoiseParams;

            UNITY_INSTANCING_BUFFER_START(Props)
                UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
                UNITY_DEFINE_INSTANCED_PROP(float4, _SizeParams)
                UNITY_DEFINE_INSTANCED_PROP(float4, _AlphaWidth)
            UNITY_INSTANCING_BUFFER_END(Props)

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD2;
                float4 screenPos : TEXCOORD3;
                float angleFade : TEXCOORD4;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            float SliceFogFactor(float3 worldPos)
            {
                #if defined(HEIGHT_FOG)
                float heightFade = CalculateParametricHeightRamp(
                    worldPos.y, _FogHeightScale, _FogHeightOffset,
                    _CustomFogHeightFogHeight, _CustomFogHeightFogStartY);
                #else
                float heightFade = 1.0;
                #endif
                #if defined(BLOOM_FOG)
                float distanceInverse = CalculateParametricDistanceTransmission(
                    worldPos, GetParametricCameraPosition(), _FogStartOffset, _FogScale, 1.0,
                    _CustomFogOffset, _CustomFogAttenuation);
                return heightFade * distanceInverse;
                #else
                #if defined(HEIGHT_FOG)
                return 1.0 - heightFade;
                #else
                return 1.0;
                #endif
                #endif
            }

            v2f vert(appdata i)
            {
                v2f o;

                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                UNITY_TRANSFER_INSTANCE_ID(i, o);

                float4 color = UNITY_ACCESS_INSTANCED_PROP(Props, _Color);
                float4 alphaWidth = UNITY_ACCESS_INSTANCED_PROP(Props, _AlphaWidth);
                float4 sizeParams = UNITY_ACCESS_INSTANCED_PROP(Props, _SizeParams);

                // DXBC 19215f1: four source regions split at .1, .5, and .9.
                // Each band carries its own width: expandedWidths.x / alphaWidth.w
                // (end cap / end body) and alphaWidth.z / expandedWidths.y
                // (start body / start cap). The fragment divides uvX by uvScale,
                // so the horizontal sample coordinate always equals uv.x.
                float sourceX = i.vertex.x * sizeParams.x;
                float2 expandedWidths = max(
                    (alphaWidth.wz - alphaWidth.zw) * 1.3333 + alphaWidth.zw,
                    alphaWidth.wz * 0.01);
                float uvX;
                float uvScale;
                float bandWidth;
                if (i.uv.y > 0.9)
                {
                    uvX = i.uv.x * expandedWidths.x;
                    uvScale = expandedWidths.x;
                    bandWidth = expandedWidths.x;
                }
                else if (i.uv.y > 0.5)
                {
                    uvX = i.uv.x * alphaWidth.w;
                    uvScale = alphaWidth.w;
                    bandWidth = alphaWidth.w;
                }
                else if (i.uv.y > 0.1)
                {
                    uvX = i.uv.x * alphaWidth.z;
                    uvScale = alphaWidth.z;
                    bandWidth = alphaWidth.z;
                }
                else
                {
                    uvX = i.uv.x * expandedWidths.y;
                    uvScale = expandedWidths.y;
                    bandWidth = expandedWidths.y;
                }

                float localX = sourceX * bandWidth;

                #if defined(ALPHA_WIDTH_SCALE)
                float widthAlpha = saturate(max(alphaWidth.x, alphaWidth.y) * color.a);
                float widthScale = saturate((widthAlpha - 0.02) / max(widthAlpha, 1e-6));
                widthScale = widthScale * widthScale * (3.0 - (2.0 * widthScale));
                localX *= widthScale;
                #endif

                float capVertex = abs(i.uv.y - 0.5) >= 0.49 ? 1.0 : 0.0;
                float localY = (i.vertex.y - sizeParams.z) * sizeParams.y +
                    (capVertex ? (i.vertex.y - 0.5) * sizeParams.w : 0.0);
                float capDirection = (i.uv.y < 0.5 ? 1.0 : 0.0) - (i.uv.y > 0.5 ? 1.0 : 0.0);
                const float weirdYFix = 0.11; // idk why this is needed
                float adjustedUvY = i.uv.y + (capVertex ? 0.0 : (0.25 + weirdYFix - _CapUVSize) * capDirection);

                float3 localPosition = float3(localX, localY, i.vertex.z);
                float3 cameraObject = mul(
                    unity_WorldToObject, float4(GetParametricCameraPosition(), 1.0)).xyz;
                #if defined(Y_AXIS_BILLBOARD)
                // DXBC a5941c6e: rotate source XZ in object space, then use the full object transform.
                float2 cameraXZ = normalize(cameraObject.xz);
                float2 selectedLocalXZ = float2(localX, i.vertex.z);
                float billboardZ = dot(float2(cameraXZ.x, -cameraXZ.y), selectedLocalXZ);
                float billboardX = dot(float2(-cameraXZ.y, -cameraXZ.x), selectedLocalXZ);
                localPosition.xz = float2(billboardX, billboardZ);
                #endif

                float3 worldPos = mul(unity_ObjectToWorld, float4(localPosition, 1.0)).xyz;
                o.vertex = mul(UNITY_MATRIX_VP, float4(worldPos, 1.0));
                o.worldPos = worldPos;
                o.uv = float4(uvX, adjustedUvY, uvScale,
                              localY > (0.5 - sizeParams.z) ? alphaWidth.y : alphaWidth.x);
                o.screenPos = ComputeScreenPosCustom(o.vertex);

                float cameraHeight = cameraObject.y - localY;
                float cameraDistance = sqrt(dot(cameraObject.xz, cameraObject.xz) + (cameraHeight * cameraHeight));
                float angle = saturate(
                    (dot(cameraObject.xz / cameraDistance, normalize(cameraObject.xz)) - 0.05) * 2.2222223);
                o.angleFade = angle * angle * (3.0 - (2.0 * angle));

                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                half4 color = UNITY_ACCESS_INSTANCED_PROP(Props, _Color);

                float safeUvScale = max(abs(i.uv.z), 1e-5);
                // DXBC 5550caa4: the fragment divides horizontal uv by uvScale (so
                // the sample x is the plain uv.x) but passes vertical uv through.
                float2 adjustedUv = float2(i.uv.x / safeUvScale, i.uv.y);
                float alpha = i.uv.w * i.uv.w * i.uv.w * color.a;

                #if defined(ANGLE_DISAPPEAR)
                alpha *= i.angleFade;
                #endif

                #if defined(USE_FOG_FOR_LIGHTS) && defined(FOG)
                alpha *= SliceFogFactor(i.worldPos);
                #endif

                #if defined(SQUARE_ALPHA)
                // DXBC 40dd4e0f squares the cubic alpha before texture alpha squared.
                alpha *= alpha;
                #endif

                #if defined(WORLD_NOISE)
                float noise = SampleParametricWorldNoise(
                    i.worldPos, _CutoutTex, _WorldNoiseScrolling,
                    _Time.x + _TimeHelperOffset.x, _WorldNoiseScale,
                    _WorldNoiseIntensityOffset, _WorldNoiseIntensityScale,
                    _WorldSpaceFadePos, _WorldSpaceFadeSlope,
                    _NoiseWarpZoomStrength, _NoiseWarpSkewStrength);
                alpha *= noise;
                #endif

                float textureAlpha = tex2D(_MainTex, TRANSFORM_TEX(adjustedUv, _MainTex)).a;
                alpha *= textureAlpha * textureAlpha;

                #if !defined(USE_FOG_FOR_LIGHTS) && defined(FOG)
                alpha *= SliceFogFactor(i.worldPos);
                #endif

                half3 rgb = color.rgb * alpha;
                #if defined(_BLOOMTYPE_MIXED) || (defined(_BLOOMTYPE_DEFERRED) && !defined(POST_BLOOM))
                // DXBC b005f58e (game main-effect type) / fc38f93c (game Always type):
                // both white-boost types share the same quartic term
                // whiteBoost = (bloomValue² * W)² * _BaseColorBoost - _BaseColorBoostThreshold
                // added to the premultiplied color. The game compiles the boost out
                // of the main-effect type when MAIN_EFFECT_ENABLED is on (POST_BLOOM
                // in ChroMapper); the Always type keeps it in both states.
                rgb = CalculateBloomComposition(
                    color.rgb, alpha, alpha * alpha, _BloomWhiteMultiplier,
                    _BaseColorBoost, _BaseColorBoostThreshold);
                #endif

                #if defined(NOISE_DITHERING)
                float4 ditherScreenPos = ScaleNoiseScreenPosition(
                    i.screenPos, _GlobalBlueNoiseParams);
                rgb = ApplyNoiseDitherMasked(
                    rgb, ditherScreenPos, _GlobalBlueNoiseTex, alpha >= 0.001 ? 1.0 : 0.0);
                #endif

                // DXBC 5550caa4 carries bloom in alpha and has no ACES transform.
                return half4(rgb, alpha * _BloomMultiplier);
            }
            ENDHLSL
        }
    }
}
