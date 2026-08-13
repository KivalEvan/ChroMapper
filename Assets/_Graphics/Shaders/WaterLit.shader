// Replacement for the Beat Saber game shader Custom/WaterLit.
Shader "ChroMapper/Water Lit"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _Metallic ("Metallic", Range(0, 1)) = 0
        _Smoothness ("Smoothness", Range(0, 1)) = 0.5
        _SpecularIntensity ("Specular Intensity", float) = 1

        [Space]
        [Toggle(Z_FADE)] _ZFade ("Z Fade", float) = 0
        [ShowIfAny(Z_FADE)] _ZFadePosition ("Z Fade Position", float) = 0
        [ShowIfAny(Z_FADE)] _ZFadeScale ("Z Fade Scale", float) = 1

        [Space]
        [Toggle(NORMAL_MAP)] _EnableNormalMap ("Enable Normal Map", float) = 0
        [ShowIfAny(NORMAL_MAP)] _NormalTex ("Normal Texture", 2D) = "bump" {}
        [ShowIfAny(NORMAL_MAP)] _NormalScale ("Normal Scale", float) = 1
        [ShowIfAny(NORMAL_MAP)] _NormalScaleVertical ("Falling Normal Scale", float) = 1
        [ShowIfAny(NORMAL_MAP)] _NormalTexScrolling ("Texture Scrolling", Vector) = (0,2,0,0)
        [Toggle(DETAIL_NORMAL_MAP)] _EnableDetailNormalMap ("Enable Detail Normal Map", float) = 0
        [ShowIfAny(DETAIL_NORMAL_MAP)] _DetailNormalTextureScale ("Detail Normal Scale", float) = 1
        [ShowIfAny(DETAIL_NORMAL_MAP)] _DetailNormalIntensity ("Detail Normal Intensity", float) = 0
        [ShowIfAny(DETAIL_NORMAL_MAP)] _DetailNormalTexScrolling ("Detail Texture Scrolling", Vector) = (0.05,2,0,0)

        [Header(Reflection)] [Space]
        [Toggle(REFLECTION_PROBE)] _EnableReflectionProbe ("Enable Reflection Probe", Float) = 0
        [ShowIfAny(REFLECTION_PROBE)] _ReflectionProbeIntensity ("Probe Intensity", Float) = 1
        [ToggleShowIfAny(REFLECTION_PROBE_BOX_PROJECTION, REFLECTION_PROBE)] _ReflectionProbeBoxProjection ("Box Projection", Float) = 1
        [ToggleShowIfAny(REFLECTION_PROBE_BOX_PROJECTION_OFFSET, 2, REFLECTION_PROBE, REFLECTION_PROBE_BOX_PROJECTION)] _EnableBoxProjectionOffset ("Box Projection Offset", Float) = 0
        [ShowIfAny(3, REFLECTION_PROBE, REFLECTION_PROBE_BOX_PROJECTION, REFLECTION_PROBE_BOX_PROJECTION_OFFSET)] _ReflectionProbeBoxProjectionSizeOffset ("Box Projection Size Offset", Vector) = (0,0,0,0)
        [ShowIfAny(3, REFLECTION_PROBE, REFLECTION_PROBE_BOX_PROJECTION, REFLECTION_PROBE_BOX_PROJECTION_OFFSET)] _ReflectionProbeBoxProjectionPositionOffset ("Box Projection Position Offset", Vector) = (0,0,0,0)

        [Space]
        [Toggle(LIGHTMAP)] _EnableLightmap ("Enable Lightmap", float) = 0
        [HideInInspector] _LightMap1 ("Light Map 1", 2D) = "black" {}
        [HideInInspector] _LightMap2 ("Light Map 2", 2D) = "black" {}

        [Space]
        [Toggle(NOISE_DITHERING)] _EnableNoiseDithering ("Enable Noise Dithering", float) = 1

        [Header(Fog Settings)] [Space]
        [Toggle(FOG)] _EnableFog ("Enable Fog", float) = 1
        [ShowIfAny(FOG)] _FogStartOffset ("Fog Start Offset", float) = 0
        [ShowIfAny(FOG)] _FallingFogStartOffset ("Falling Start Offset", float) = 0
        [ShowIfAny(FOG)] _FogScale ("Fog Scale", float) = 1
        [Space]
        [ToggleShowIfAny(HEIGHT_FOG, FOG)] _EnableHeightFog ("Enable Height Fog", float) = 0
        [ShowIfAny(2, FOG, HEIGHT_FOG)] _FogHeightOffset ("Fog Height Offset", float) = 0
        [ShowIfAny(2, FOG, HEIGHT_FOG)] _FogHeightScale ("Fog Height Scale", float) = 1

        [Space]
        [KeywordEnum(None, Deferred, Mixed)] _BloomType ("White Boost", float) = 0

        [Space]
        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull", float) = 2
        [Enum(Off, 0, On, 1)] _ZWrite ("Z Write", float) = 1
        _StencilRefValue ("Stencil Ref Value", float) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)] _StencilComp ("Stencil Comp Func", float) = 8
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilPass ("Stencil Pass Op", float) = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendModeSrc ("Blend Src Factor", float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendModeDst ("Blend Dst Factor", float) = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendModeSrcA ("Blend Src Factor A", float) = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendModeDstA ("Blend Dst Factor A", float) = 0
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
        }

        LOD 200
        Blend [_BlendModeSrc] [_BlendModeDst], [_BlendModeSrcA] [_BlendModeDstA]
        Cull [_Cull]
        ZTest LEqual
        ZWrite [_ZWrite]

        Pass
        {
            Stencil
            {
                Ref [_StencilRefValue]
                Comp [_StencilComp]
                Pass [_StencilPass]
            }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing

            #pragma shader_feature_local_fragment Z_FADE
            #pragma shader_feature_local_fragment NORMAL_MAP
            #pragma shader_feature_local_fragment DETAIL_NORMAL_MAP
            #pragma shader_feature_local_fragment LIGHTMAP
            #pragma shader_feature_local_fragment NOISE_DITHERING
            #pragma shader_feature_local_fragment FOG
            #pragma shader_feature_local_fragment HEIGHT_FOG
            #pragma shader_feature_local_fragment REFLECTION_PROBE
            #pragma shader_feature_local_fragment REFLECTION_PROBE_BOX_PROJECTION
            #pragma shader_feature_local_fragment REFLECTION_PROBE_BOX_PROJECTION_OFFSET
            #pragma shader_feature_local_fragment _ _BLOOMTYPE_DEFERRED _BLOOMTYPE_MIXED

            #pragma multi_compile_fragment _ BLOOM_FOG
            #pragma multi_compile_fragment _ ACES_TONE_MAPPING
            #pragma multi_compile _ POST_BLOOM

            #include "UnityCG.cginc"
            #include "ShaderLibrary/Fog.hlsl"
            #include "ShaderLibrary/CustomLighting.hlsl"
            #include "ShaderLibrary/LitReflection.hlsl"
            #include "ShaderLibrary/CustomTonemapping.hlsl"
            #include "ShaderLibrary/CustomBloom.hlsl"
            #include "ShaderLibrary/PostProcess.hlsl"

            float _Metallic;
            float _Smoothness;
            float _SpecularIntensity;
            float _ReflectionProbeIntensity;
            float3 _ReflectionProbeBoxProjectionSizeOffset;
            float3 _ReflectionProbeBoxProjectionPositionOffset;

            float _ZFadePosition;
            float _ZFadeScale;

            sampler2D _NormalTex;
            float4 _NormalTex_ST;
            float _NormalScale;
            float _NormalScaleVertical;
            float2 _NormalTexScrolling;
            float _DetailNormalTextureScale;
            float _DetailNormalIntensity;
            float2 _DetailNormalTexScrolling;

            sampler2D _LightMap1;
            sampler2D _LightMap2;
            float3 _LightmapLightBakeIdA;
            float3 _LightmapLightBakeIdB;
            float3 _LightmapLightBakeIdC;
            float3 _LightmapLightBakeIdD;
            float3 _LightmapLightBakeIdE;
            float3 _LightmapLightBakeIdF;

            sampler2D _GlobalBlueNoiseTex;
            float2 _GlobalBlueNoiseParams;
            float _GlobalRandomValue;

            float _FogStartOffset;
            float _FallingFogStartOffset;
            float _FogScale;
            float _FogHeightOffset;
            float _FogHeightScale;

            UNITY_INSTANCING_BUFFER_START(Props)
                UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
            UNITY_INSTANCING_BUFFER_END(Props)

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                float4 screenPos : TEXCOORD3;
                float4 tangent : TEXCOORD4;
                float2 lightmapUv : TEXCOORD5;
                float4 noiseScreenPos : TEXCOORD6;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert(appdata i)
            {
                v2f o;

                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_TRANSFER_INSTANCE_ID(i, o);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = UnityObjectToClipPos(i.vertex);
                o.worldPos = mul(unity_ObjectToWorld, i.vertex).xyz;
                o.worldNormal = normalize(UnityObjectToWorldNormal(i.normal));
                o.uv.xy = i.uv.xy;
                o.screenPos = ComputeScreenPosCustom(o.vertex);
                o.lightmapUv = i.uv1 * unity_LightmapST.xy + unity_LightmapST.zw;
                o.noiseScreenPos.xy = o.screenPos.xy * _GlobalBlueNoiseParams;
                o.noiseScreenPos.xy += o.vertex.w * _GlobalRandomValue + unity_ObjectToWorld._m03_m13;
                o.noiseScreenPos.zw = o.vertex.zw;
                o.tangent = float4(
                    normalize(UnityObjectToWorldDir(i.tangent.xyz)),
                    i.tangent.w * unity_WorldTransformParams.w);

                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                float4 albedo = UNITY_ACCESS_INSTANCED_PROP(Props, _Color);
                float3 worldPos = i.worldPos;

                #if defined(Z_FADE)
                albedo.a *= saturate((_ZFadePosition - worldPos.z) * _ZFadeScale);
                #endif

                float3 worldNormal = i.worldNormal;

                #if defined(NORMAL_MAP)
                float3 normalTangent = UnpackNormalWithScale(
                    tex2D(_NormalTex, TRANSFORM_TEX(i.uv, _NormalTex) + _NormalTexScrolling.xy * _Time.xx),
                    1.0);
                #if defined(DETAIL_NORMAL_MAP)
                float3 detailNormalTangent = UnpackNormalWithScale(
                    tex2D(_NormalTex, TRANSFORM_TEX(i.uv, _NormalTex) +
                          _DetailNormalTexScrolling.xy * _Time.xx),
                    _DetailNormalTextureScale);
                normalTangent = lerp(
                    normalTangent,
                    detailNormalTangent,
                    _DetailNormalIntensity);
                #endif
                float fallingNormalScale = 1.0 + _NormalScaleVertical * (1.0 - worldNormal.y);
                normalTangent.xy *= fallingNormalScale;
                normalTangent = normalize(normalTangent);
                float3 worldTangent = normalize(i.tangent.xyz);
                float3 worldBitangent = cross(worldNormal, worldTangent) * i.tangent.w;
                float3x3 tbn = float3x3(worldTangent, worldBitangent, worldNormal);
                float3 mappedWorldNormal = normalize(mul(normalTangent, tbn));
                worldNormal = normalize(lerp(worldNormal, mappedWorldNormal, _NormalScale));
                #endif

                float3 diffuseLighting = CalculateLightDiffuse(worldNormal);
                float3 diffuseColor = diffuseLighting * albedo.rgb;
                float3 lighting = diffuseColor * (0.96 * (1.0 - _Metallic));
                float3 specularColor = 0.04 + _Metallic * (diffuseColor - 0.04);
                float3 specularLighting = CalculateLightSpecular(
                    worldPos, worldNormal, _Smoothness);
                lighting += specularLighting * specularColor * _SpecularIntensity;

                #if defined(REFLECTION_PROBE)
                SurfaceData reflectionSurface = InitializeSurfaceData(
                    worldPos, worldNormal, i.uv, i.uv, albedo,
                    _Metallic, _Smoothness);
                lighting += ResolveUnityReflectionProbe(
                    reflectionSurface, worldNormal, _ReflectionProbeIntensity,
                    _ReflectionProbeBoxProjectionSizeOffset,
                    _ReflectionProbeBoxProjectionPositionOffset);
                #endif

                #if defined(LIGHTMAP)
                float3 lightmap1 = tex2D(_LightMap1, i.lightmapUv).rgb;
                float3 lightmap2 = tex2D(_LightMap2, i.lightmapUv).rgb;
                float3 decodedLightmap =
                    lightmap1.r * _LightmapLightBakeIdA +
                    lightmap1.g * _LightmapLightBakeIdB +
                    lightmap1.b * _LightmapLightBakeIdC +
                    lightmap2.r * _LightmapLightBakeIdD +
                    lightmap2.g * _LightmapLightBakeIdE +
                    lightmap2.b * _LightmapLightBakeIdF;
                lighting += decodedLightmap * 4.594793 * (1.0 - _Metallic) * albedo.rgb;
                #endif

                albedo.rgb = lighting;

                #if defined(ACES_TONE_MAPPING)
                albedo = ApplyAcesTonemapping(albedo);
                #endif

                albedo = ApplyBloomTypeWhiteBoost(
                    albedo, 1.0, albedo.a, 1.0,
                    _BaseColorBoost, _BaseColorBoostThreshold);

                #if defined(BLOOM_FOG) && defined(FOG)
                float fogStartOffset = CalculateWaterLitFogStartOffset(
                    worldNormal.y, _FogStartOffset, _FallingFogStartOffset);
                #if defined(HEIGHT_FOG)
                albedo = ApplyBloomHeightFog(albedo, i.screenPos, worldPos, fogStartOffset, _FogScale,
                                             _FogHeightOffset,
                                             _FogHeightScale);
                #else
                albedo = ApplyBloomFog(albedo, i.screenPos, worldPos, fogStartOffset, _FogScale);
                #endif
                #elif defined(FOG) && defined(HEIGHT_FOG)
                float heightFogInput = worldPos.y * _FogHeightScale + _FogHeightOffset;
                heightFogInput -= _CustomFogHeightFogHeight + _CustomFogHeightFogStartY;
                heightFogInput = saturate(heightFogInput / _CustomFogHeightFogHeight);
                float heightFogFactor = 1.0 -
                    heightFogInput * heightFogInput * (3.0 - 2.0 * heightFogInput);
                albedo.rgb = lerp(albedo.rgb, 0.1.xxx, heightFogFactor);
                #endif

                #if defined(NOISE_DITHERING)
                albedo = ApplyNoiseDither(albedo, i.noiseScreenPos, _GlobalBlueNoiseTex);
                #endif

                return albedo;
            }
            ENDHLSL
        }
    }
}
