Shader "ChroMapper/Object/Obstacle Distortion"
{
    Properties
    {
        [Header(Displacement)] [Space]
        _MainTex ("Displacement Texture", 2D) = "white" {}
        _DisplacementStrength ("Displacement Strength", Float) = 0.01

        [Space]
        [Toggle(SCALE_UV)] _ScaleUV ("Scale UV", Float) = 0
        _UVScale ("UV Scale", Vector) = (1, 1, 1, 0)

        [Space]
        [Toggle(SCROLL_UV)] _ScrollUV ("Scroll UV", Float) = 0
        _ScrollUVVelocity ("Scroll UV Velocity", Vector) = (0, 0, 0, 0)

        [Header(Color)] [Space]
        _Color ("Obstacle Color", Color) = (1, 1, 1, 1)
        _TintColor ("Core Tint Color", Color) = (1, 1, 1, 1)
        _AddColor ("Add Color", Color) = (0, 0, 0, 0)
        _DisplacementAlphaMul ("Displacement Alpha Mul", Float) = 1
        [Toggle(CLIP_LOW_ALPHA)] _ClipLowAlpha ("Clip Low Alpha", Float) = 1

        [Header(Distortion)] [Space]
        [Toggle(VIEW_ANGLE_AFFECTS_DISTORTION)]
        _ViewAngleAffectsDistortion ("View Angle Affects Distortion", Float) = 1
        _ViewAngleDistortionParam ("View Angle Distortion Param", Float) = 4

        [Space]
        [Toggle(USE_DISTORTED_TEXTURE_ONLY)]
        _UseDistortedTextureOnly ("Use Distorted Texture Only", Float) = 0

        [Space]
        [Toggle(DEPTH_AWARE_DISTORTION)]
        _DepthAwareDistortion ("Depth Aware Distortion", Float) = 0

        [Header(Cutout)] [Space]
        [Toggle(CUTOUT)] _EnableCutout ("Enable Cutout", Float) = 0
        _CutoutTexScale ("Cutout Texture Scale", Float) = 1
        _CutoutTexOffset ("Cutout Texture Offset", Vector) = (0, 0, 0, 0)
        _Cutout ("Cutout", Range(0, 1)) = 0

        [Header(Rim Dim)] [Space]
        [Toggle(RIM_DIM)] _EnableRimDim ("Enable Rim Dim", Float) = 0
        _RimDimScale ("Rim Scale", Float) = 1
        _RimDimOffset ("Rim Offset", Float) = 1

        [Header(Fog Settings)] [Space]
        [Toggle(FOG)] _EnableFog ("Enable Fog", Float) = 0
        _FogStartOffset ("Fog Start Offset", Float) = 0
        _FogScale ("Fog Scale", Float) = 1
        [Space]
        _FogHeightOffset ("Fog Height Offset", Float) = 0
        _FogHeightScale ("Fog Height Scale", Float) = 1

        [Space]
        [Toggle(CLIPPING)] _EnableClipping ("Enable Clipping", Float) = 0

        [Header(Settings)] [Space]
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode ("Cull Mode", Float) = 0
        [Toggle] _ZWrite ("Z Write", Float) = 0

        [Space]
        [Header(Color Blending)]
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendSrcFactor ("Foreground Factor", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendDstFactor ("Background Factor", Float) = 0
        [Enum(UnityEngine.Rendering.BlendOp)] _BlendOp ("Blend Operation", Float) = 0

        [Space]
        [Header(Bloom Blending)]
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendSrcFactorA ("Foreground Alpha Factor", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendDstFactorA ("Background Alpha Factor", Float) = 0

    }

    SubShader
    {
        Tags
        {
            "Queue" = "Transparent+50"
            "IgnoreProjector" = "True"
            "RenderType" = "Transparent"
        }

        Blend [_BlendSrcFactor] [_BlendDstFactor], [_BlendSrcFactorA] [_BlendDstFactorA]
        BlendOp [_BlendOp]
        Cull [_CullMode]
        ZTest LEqual
        ZWrite [_ZWrite]

        Pass
        {
            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing

            #pragma shader_feature_local_vertex SCALE_UV
            #pragma shader_feature_local_fragment SCROLL_UV
            #pragma shader_feature_local_fragment FOG
            #pragma shader_feature_local_fragment CLIP_LOW_ALPHA
            #pragma shader_feature_local_fragment VIEW_ANGLE_AFFECTS_DISTORTION
            #pragma shader_feature_local_fragment USE_DISTORTED_TEXTURE_ONLY
            #pragma shader_feature_local_fragment DEPTH_AWARE_DISTORTION
            #pragma shader_feature_local_fragment CUTOUT
            #pragma shader_feature_local_fragment RIM_DIM
            #pragma shader_feature_local_fragment CLIPPING

            #pragma multi_compile_fragment _ DEPTH_TEXTURE
            #pragma multi_compile_fragment _ BLOOM_FOG
            #pragma multi_compile_fragment _ CM_PREVIEW_MODE

            #pragma shader_feature_local_fragment HEIGHT_FOG

            #include "UnityCG.cginc"
            #include "../ShaderLibrary/Camera.hlsl"
            #include "../ShaderLibrary/Fog.hlsl"
            #include "../ShaderLibrary/Cutout.hlsl"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _ScreenDisplacementGrabTexture;
            float4 _ScreenDisplacementGrabTexture_TexelSize;
            sampler2D _CameraDepthTexture;
            sampler3D _CutoutTex;

            float _DisplacementStrength;
            float _DisplacementAlphaMul;
            float4 _UVScale;
            float4 _ScrollUVVelocity;
            float _ViewAngleDistortionParam;
            float _CutoutTexScale;
            float _RimDimScale;
            float _RimDimOffset;
            float4 _ClippingPlane;

            float _FogStartOffset;
            float _FogScale;
            float _FogHeightOffset;
            float _FogHeightScale;

            UNITY_INSTANCING_BUFFER_START(Props)
                UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
                UNITY_DEFINE_INSTANCED_PROP(float4, _TintColor)
                UNITY_DEFINE_INSTANCED_PROP(float4, _AddColor)
                UNITY_DEFINE_INSTANCED_PROP(float, _Cutout)
                UNITY_DEFINE_INSTANCED_PROP(float4, _CutoutTexOffset)
            UNITY_INSTANCING_BUFFER_END(Props)

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD2;
                float3 worldNormal : TEXCOORD3;
                float4 screenPos : TEXCOORD4;
                float4 color : COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert(appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                UNITY_TRANSFER_INSTANCE_ID(v, o);

                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                #if defined(SCALE_UV)
                float3 tangent = v.tangent.xyz;
                float3 bitangent = cross(tangent, v.normal);
                o.uv *= float2(
                    dot(_UVScale.xyz, tangent),
                    dot(_UVScale.xyz, bitangent));
                #endif
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.screenPos = ComputeScreenPosCustom(o.pos);
                o.color = v.color;
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                #if defined(CLIPPING)
                clip(dot(float4(i.worldPos, 1), _ClippingPlane));
                #endif

                float cutout = UNITY_ACCESS_INSTANCED_PROP(Props, _Cutout);
                float4 cutoutTexOffset = UNITY_ACCESS_INSTANCED_PROP(Props, _CutoutTexOffset);
                #if defined(CUTOUT)
                float3 objectOrigin = unity_ObjectToWorld._m03_m13_m23;
                float3 cutoutPosition = CalculateObjectSpaceCutoutPosition(
                    i.worldPos, objectOrigin, cutoutTexOffset.xyz, _CutoutTexScale);
                float cutoutNoise = tex3D(_CutoutTex, cutoutPosition).a;
                ApplyCutoutNoise(cutoutNoise, cutout);
                #endif

                float2 displacementUv = i.uv;
                #if defined(SCROLL_UV)
                displacementUv += _ScrollUVVelocity.xy * _Time.y;
                #endif

                float4 obstacleColor = UNITY_ACCESS_INSTANCED_PROP(Props, _Color);
                float4 tintColor = UNITY_ACCESS_INSTANCED_PROP(Props, _TintColor);
                float4 addColor = UNITY_ACCESS_INSTANCED_PROP(Props, _AddColor);
                float displacementControlAlpha = obstacleColor.a * i.color.a;

                // ScreenDisplacementHD centers the sampled RG channels before scaling
                // displacement in thousandths.
                float2 displacement = tex2D(_MainTex, displacementUv).rg - 0.5;
                float displacementScale = 0.001;

                #if defined(STEREO_INSTANCING_ON) || defined(UNITY_SINGLE_PASS_STEREO) || defined(STEREO_MULTIVIEW_ON)
                displacementScale *= 0.5;
                #endif

                displacement *= _DisplacementStrength * displacementScale * displacementControlAlpha;

                #if defined(VIEW_ANGLE_AFFECTS_DISTORTION)
                float3 viewDirection = normalize(_WorldSpaceCameraPos - i.worldPos);
                float viewFactor = saturate(sqrt(abs(dot(viewDirection, normalize(i.worldNormal))))
                    * _ViewAngleDistortionParam);
                displacement *= viewFactor;
                #endif

                float2 screenUv = i.screenPos.xy / i.screenPos.w;
                float2 distortedUv = (i.screenPos.xy + displacement) / i.screenPos.w;

                #if defined(DEPTH_AWARE_DISTORTION) && defined(DEPTH_TEXTURE)
                float sceneDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, distortedUv));
                float surfaceDepth = LinearEyeDepth(i.screenPos.z / i.screenPos.w);
                distortedUv = lerp(screenUv, distortedUv, step(surfaceDepth - 0.01, sceneDepth));
                #endif

                float displacementAlpha = saturate(displacementControlAlpha);

                #if defined(CLIP_LOW_ALPHA)
                clip(displacementAlpha - 0.01);
                #endif

                // Keep bilinear samples inside the copied render target. The game clamps to
                // half a texel below the upper edge before sampling its grab texture.
                float2 grabUvMax = 1.0 - 0.5 * _ScreenDisplacementGrabTexture_TexelSize.xy;
                screenUv = min(screenUv, grabUvMax);
                distortedUv = min(distortedUv, grabUvMax);

                float4 originalColor = tex2D(_ScreenDisplacementGrabTexture, screenUv);
                float4 distortedColor = tex2D(_ScreenDisplacementGrabTexture, distortedUv)
                    * tintColor + addColor;

                #if defined(USE_DISTORTED_TEXTURE_ONLY)
                float4 color = distortedColor;
                #else
                float4 color = lerp(originalColor, distortedColor, displacementAlpha);
                #endif
                // Preserve the grabbed scene's bloom mask. ScreenDisplacementHD
                // scales sampled alpha instead of replacing it with obstacle opacity.
                color.a *= _DisplacementAlphaMul;

                #if defined(RIM_DIM)
                float3 rimViewDirection = normalize(_WorldSpaceCameraPos - i.worldPos);
                float rim = saturate((1 - abs(dot(rimViewDirection, normalize(i.worldNormal))))
                    * _RimDimScale + _RimDimOffset);
                color.rgb *= rim;
                #endif

                #if defined(CM_PREVIEW_MODE) && defined(FOG)
                #if defined(BLOOM_FOG) && defined(HEIGHT_FOG)
                color = ApplyBloomHeightFog(color, i.screenPos, i.worldPos, _FogStartOffset, _FogScale,
                                            _FogHeightOffset, _FogHeightScale);
                #elif defined(BLOOM_FOG)
                color = ApplyBloomFog(color, i.screenPos, i.worldPos, _FogStartOffset, _FogScale);
                #else
                color = ApplyHeightFog(color, i.worldPos, _FogHeightScale, _FogHeightOffset);
                #endif
                #endif

                return color;
            }
            ENDHLSL
        }
    }
}
