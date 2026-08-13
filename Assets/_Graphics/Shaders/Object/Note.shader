Shader "ChroMapper/Object/Note"
{
    Properties
    {
        _Color ("Color", Color) = (0, 0, 0, 0)
        _StrobeColor ("Strobe Color", Color) = (0, 0, 0, 0)
        [Toggle] _StrobeColorEnabled ("Strobe Color Enabled", Float) = 0
        _ColorMultiplier ("Color Multiplier", Range(0, 10)) = 1
        _MainTex ("Albedo", 2D) = "white" {}
        _Smoothness ("Smoothness", Range(0, 1)) = 0.95

        [Header(Recovered Note)] [Space]
        [Toggle(CUTOUT)] _EnableCutout ("Cutout", float) = 0
        [Toggle(PLANE_CUT)] _EnablePlaneCut ("Plane Cut", float) = 0
        [Toggle(REFLECTION_MAP)] _EnableReflectionMap ("Reflection Map", float) = 0
        [KeywordEnum(None, Deferred, Mixed)] _BloomType ("Bloom Type", float) = 0
        [HideInInspector] _FinalColorMul ("Final Color Multiplier", float) = 1
        [HideInInspector] _CutoutTexScale ("Cutout Texture Scale", float) = 0.25
        [HideInInspector] _CutPlaneThreshold ("Cut Plane Threshold", float) = 0
        [HideInInspector] _CutPlaneEdgeGlowWidth ("Cut Plane Edge Glow Width", float) = 0.005
        _EnvironmentReflectionCube ("Environment Reflection", Cube) = "" {}

        [Header(Beat Saber)] [Space]
        _Cutout("Cutout", Range(0, 1)) = 0.0
        _CutoutSize("CutoutSize", Range(0.2,10)) = 1
        _CutoutEdgeWidth("Cutout Edge Width", Range(0, 0.2)) = 0.05
        _CutoutEdgeGlow("Cutout Edge Glow", Range(0, 1)) = 0.5
        _CutoutTexOffset("Cutout Tex Offset", Vector) = (0, 0, 0, 0)
        _CutPlane("Cut Plane", Vector) = (0, 0, 0, 0)

        [Header(Rim Dim)] [Space]
        [Toggle(RIM_DIM)] _EnableRimDim("Rim Dim", float) = 1
        _RimScale ("Rim Scale", Range(0, 4)) = 2
        _RimOffset ("Rim Offset", Range(-1, 1)) = 0
        _RimCameraDistanceScale ("Rim Camera Distance Scale", Range(0, 4)) = 0.03
        _RimCameraDistanceOffset ("Rim Camera Distance Offset", float) = 5
        _RimDarkening ("Rim Darkening", Range(0, 1)) = 0

        [Header(Animation)] [Space]
        _OutlineWidth("Outline Width", float) = 0.05
        _OverNoteInterfaceColor("Over Note Interface Color", Color) = (1, 1, 1, 0)
        _Rotation("Rotation", float) = 0
        _AnimationSpawned("Animation Spawned", float) = 0

        [Header(Fog Settings)] [Space]
        [Toggle(_FOGTYPE_LERP)] _EnableFog ("Enable Fog", float) = 1
        _FogStartOffset ("Fog Start Offset", float) = 1
        _FogScale ("Fog Scale", float) = 1
        [Space]
        [Toggle(HEIGHT_FOG)] _EnableHeightFog ("Enable Height Fog", float) = 0
        _FogHeightOffset ("Fog Height Offset", float) = 0
        _FogHeightScale ("Fog Height Scale", float) = 1

        [Header(Editor)] [Space]
        [Toggle] _AlwaysTranslucent("Always Translucent", float) = 0
        _TranslucentAlpha("Translucent Alpha", float) = 0.5
        _ObjectTime ("Object Time", float) = 9999

        [Header(Settings)] [Space]
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode ("Cull Mode", float) = 2
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("Z Test", float) = 4
        [Toggle] _ZWrite ("Z Write", float) = 1
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
        }

        // The recovered shader does not contain recoverable ShaderLab state. Keep the
        // opaque ChroMapper states from Note.shader as the target-side adapter.
        Cull [_CullMode]
        ZTest [_ZTest]
        ZWrite [_ZWrite]

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            // These are the canonical target declarations for the recovered source
            // families. Do not restore the source aliases here.
            #pragma shader_feature_local CUTOUT
            #pragma shader_feature_local PLANE_CUT
            #pragma shader_feature_local REFLECTION_MAP
            #pragma shader_feature_local RIM_DIM
            #pragma shader_feature_local_fragment HEIGHT_FOG
            #pragma shader_feature_local_fragment _ _FOGTYPE_LERP _FOGTYPE_COLOR _FOGTYPE_ALPHA
            #pragma shader_feature_local_fragment _ _BLOOMTYPE_DEFERRED _BLOOMTYPE_MIXED
            // Global: the post-process bloom runs (mirrors the game's MAIN_EFFECT_ENABLED gate).
            #pragma multi_compile _ POST_BLOOM

            #pragma multi_compile_instancing
            #pragma multi_compile _ STEREO_INSTANCING_ON
            #pragma multi_compile_fragment _ BLOOM_FOG
            #pragma multi_compile_fragment _ ACES_TONE_MAPPING
            #pragma multi_compile_fragment _ CM_PREVIEW_MODE

            #include "UnityCG.cginc"
            #include "../ShaderLibrary/Camera.hlsl"
            #include "../ShaderLibrary/Fog.hlsl"
            #include "../ShaderLibrary/CustomBloom.hlsl"
            #include "../ShaderLibrary/CustomTonemapping.hlsl"
            #include "../ShaderLibrary/ObjectShared.hlsl"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler3D _CutoutTex;
            samplerCUBE _EnvironmentReflectionCube;

            float _Smoothness;
            float _FinalColorMul;
            float _CutoutTexScale;
            float _CutPlaneThreshold;
            float _CutPlaneEdgeGlowWidth;

            float _RimScale;
            float _RimOffset;
            float _RimCameraDistanceScale;
            float _RimCameraDistanceOffset;
            float _RimDarkening;

            float _OutlineWidth;
            float _FogStartOffset;
            float _FogScale;
            float _FogHeightOffset;
            float _FogHeightScale;

            float4 _SongTime;

            UNITY_INSTANCING_BUFFER_START(Props)
                UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
                UNITY_DEFINE_INSTANCED_PROP(float4, _StrobeColor)
                UNITY_DEFINE_INSTANCED_PROP(float, _StrobeColorEnabled)
                UNITY_DEFINE_INSTANCED_PROP(float, _ColorMultiplier)
                UNITY_DEFINE_INSTANCED_PROP(float4, _OverNoteInterfaceColor)
                UNITY_DEFINE_INSTANCED_PROP(float, _TranslucentAlpha)
                UNITY_DEFINE_INSTANCED_PROP(float, _Cutout)
                UNITY_DEFINE_INSTANCED_PROP(float, _CutoutSize)
                UNITY_DEFINE_INSTANCED_PROP(float, _CutoutEdgeWidth)
                UNITY_DEFINE_INSTANCED_PROP(float, _CutoutEdgeGlow)
                UNITY_DEFINE_INSTANCED_PROP(float4, _CutoutTexOffset)
                UNITY_DEFINE_INSTANCED_PROP(float4, _CutPlane)
                UNITY_DEFINE_INSTANCED_PROP(float, _Rotation)
                UNITY_DEFINE_INSTANCED_PROP(float, _AlwaysTranslucent)
                UNITY_DEFINE_INSTANCED_PROP(float, _AnimationSpawned)
                UNITY_DEFINE_INSTANCED_PROP(float, _ObjectTime)
            UNITY_INSTANCING_BUFFER_END(Props)

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 localPos : TEXCOORD1;
                float4 reflectionData : TEXCOORD2;
                float4 worldPos : TEXCOORD3;
                float4 rotatedPos : TEXCOORD4;
                float4 screenPos : TEXCOORD5;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            float3 AdaptEnvironmentReflectionDirection(float3 worldReflectionDirection)
            {
                // Source variants apply the _SpawnRotation basis before the cube
                // lookup. ChroMapper supplies the equivalent Y rotation per note.
                float rotation = UNITY_ACCESS_INSTANCED_PROP(Props, _Rotation) * (3.141592653 / 180.0);
                return RotateObjectPositionY(worldReflectionDirection, rotation);
            }

            v2f vert(appdata i)
            {
                v2f o;

                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_TRANSFER_INSTANCE_ID(i, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                float3 cameraPosition = GetStereoAwareCameraPosition();
                float3 worldPosition = mul(unity_ObjectToWorld, i.vertex).xyz;
                float3 worldNormal = normalize(UnityObjectToWorldNormal(i.normal));
                float3 V = normalize(worldPosition - cameraPosition);
                float distanceToCamera = length(worldPosition - cameraPosition);

                // This is the recovered sign convention: V points from the camera
                // toward the fragment, not from the fragment toward the camera.
                float3 worldReflectionDirection = V - 2.0 * dot(V, worldNormal) * worldNormal;
                float rimFactor = 0.0;
                #if defined(RIM_DIM)
                rimFactor = saturate((dot(V, worldNormal) + _RimOffset + 1.0) * _RimScale +
                    max(distanceToCamera - _RimCameraDistanceOffset, 0.0) *
                    _RimCameraDistanceScale);
                #endif

                o.vertex = UnityObjectToClipPos(i.vertex);
                o.uv = i.uv;
                o.localPos = i.vertex;
                o.worldPos = float4(worldPosition, distanceToCamera);
                o.reflectionData = float4(
                    AdaptEnvironmentReflectionDirection(worldReflectionDirection), rimFactor);
                o.screenPos = ComputeScreenPosCustom(o.vertex);

                // These varyings retain the ChroMapper editor animation/translucency
                // contract. They do not participate in the recovered source lighting.
                const float4 offset = float4(0, 0, -1, 0);
                float rotationInRadians = UNITY_ACCESS_INSTANCED_PROP(Props, _Rotation) * (3.141592653 / 180.0);
                float objectTime = UNITY_ACCESS_INSTANCED_PROP(Props, _ObjectTime);
                o.rotatedPos = CalculateRotatedObjectPosition(
                    worldPosition, offset.xyz, rotationInRadians, objectTime, _SongTime.y);
                o.rotatedPos.z -= 1.0;

                return o;
            }

            float4 frag(v2f i, bool isFrontFace : SV_IsFrontFace) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                float4 color = UNITY_ACCESS_INSTANCED_PROP(Props, _Color);
                float4 strobeColor = UNITY_ACCESS_INSTANCED_PROP(Props, _StrobeColor);
                if (UNITY_ACCESS_INSTANCED_PROP(Props, _StrobeColorEnabled) > 0.5)
                {
                    // The editor selects strobe RGB only. Strobe alpha does not enter output.
                    float splitCoordinate = abs(i.localPos.x + i.localPos.y + i.localPos.z) - 0.5;
                    if (splitCoordinate > 0.0)
                        color.rgb = strobeColor.rgb;
                }
                // _ColorMultiplier is an editor MPB contract for both base and strobe RGB.
                // Keep the selected color alpha unchanged for the recovered output math.
                color.rgb *= UNITY_ACCESS_INSTANCED_PROP(Props, _ColorMultiplier);
                float4 interfaceColor = UNITY_ACCESS_INSTANCED_PROP(Props, _OverNoteInterfaceColor);
                float isTranslucent = UNITY_ACCESS_INSTANCED_PROP(Props, _AlwaysTranslucent);
                float animation = UNITY_ACCESS_INSTANCED_PROP(Props, _AnimationSpawned);
                float translucentAlpha = UNITY_ACCESS_INSTANCED_PROP(Props, _TranslucentAlpha);
                float cutout = UNITY_ACCESS_INSTANCED_PROP(Props, _Cutout);
                float cutoutSize = UNITY_ACCESS_INSTANCED_PROP(Props, _CutoutSize);
                float cutoutEdgeWidth = max(
                    UNITY_ACCESS_INSTANCED_PROP(Props, _CutoutEdgeWidth), 0.0);
                float cutoutEdgeGlow = max(
                    UNITY_ACCESS_INSTANCED_PROP(Props, _CutoutEdgeGlow), 0.0);
                float4 cutoutTexOffset = UNITY_ACCESS_INSTANCED_PROP(Props, _CutoutTexOffset);

                #if defined(CM_PREVIEW_MODE)
                // Preview texturing follows face selection and _ColorMultiplier.
                color.rgb *= tex2D(_MainTex, TRANSFORM_TEX(i.uv, _MainTex)).rgb;
                #endif

                float cutoutMask = 0.0;

                #if defined(CUTOUT)
                float3 objectOrigin = mul(unity_ObjectToWorld, float4(0, 0, 0, 1)).xyz;
                float3 cutoutPosition = (i.worldPos.xyz - objectOrigin + cutoutTexOffset.xyz) *
                    (_CutoutTexScale * cutoutSize);
                float noiseA = tex3D(_CutoutTex, cutoutPosition).a;
                float cutoutDistance = noiseA - 1.1 * cutout + 0.1;
                if (cutoutDistance < 0.0)
                    discard;
                // The defaults reproduce the recovered 0.05-wide binary edge mask.
                // These properties retain ChroMapper's runtime note-shader contract.
                cutoutMask = cutoutDistance < cutoutEdgeWidth ? cutoutEdgeGlow : 0.0;
                #endif

                #if defined(PLANE_CUT)
                // The recovered plane route subtracts the cutout-scaled plane
                // threshold before its discard and edge smoothstep. Keep this
                // branch independent of CUTOUT; the source variant contract does
                // not justify an additional family constraint.
                float4 cutPlane = UNITY_ACCESS_INSTANCED_PROP(Props, _CutPlane);
                float planeDistance = dot(i.localPos.xyz, cutPlane.xyz) + cutPlane.w;
                float planeThreshold = cutout * (_CutPlaneThreshold + cutPlane.w);
                planeDistance -= planeThreshold;
                if (planeDistance < 0.0)
                    discard;

                float planeEdge = saturate(
                    (planeDistance - (_CutPlaneEdgeGlowWidth + 0.005)) /
                    (_CutPlaneEdgeGlowWidth - (_CutPlaneEdgeGlowWidth + 0.005)));
                planeEdge = planeEdge * planeEdge * (3.0 - 2.0 * planeEdge);
                cutoutMask = min(planeEdge + cutoutMask, 1.0);
                #endif

                #if !defined(CM_PREVIEW_MODE)
                // Apply the editor timeline marker before transparent dithering.
                // This changes RGB only, so source reflection and cutout alpha remain intact.
                color.rgb = ApplyTimelineWhitening(color.rgb, interfaceColor.rgb,
                                                   i.rotatedPos.z, _OutlineWidth, isTranslucent);
                #endif

                float editorAlpha = animation < 1.0 &&
                                    (isTranslucent >= 1.0 || i.rotatedPos.w <= 0.0)
                                        ? translucentAlpha
                                        : 1.0;
                // Dither is a ChroMapper editor adapter. Source CUTOUT/PLANE_CUT
                // discard and mask evaluation above always happen first.
                if (editorAlpha < 1.0)
                    clip(OrderedDither4x4(i.screenPos.xy / i.screenPos.w, editorAlpha));

                float frontBack = isFrontFace ? 1.0 : 0.2592592537;
                float4 result = 0.0;

                #if defined(REFLECTION_MAP)
                float reflectionFaceSign = isFrontFace ? 1.0 : -1.0;
                float3 environmentReflectionDirection =
                    reflectionFaceSign * i.reflectionData.xyz;
                float x = i.reflectionData.w + 1.0 - _Smoothness +
                    saturate(i.worldPos.w * 0.01 - 0.3);
                float reflectionLod = (1.7 - 0.7 * x) * x * 6.0;
                float4 environment = texCUBElod(
                    _EnvironmentReflectionCube,
                    float4(environmentReflectionDirection, reflectionLod));

                float reflectionFactor = frontBack * _FinalColorMul *
                    (1.0 - i.reflectionData.w * _RimDarkening);
                float3 reflected = reflectionFactor * color.rgb * environment.rgb;
                float3 weightedReflection = reflected * color.a;
                float3 baseMix = color.rgb - weightedReflection;
                result.rgb = cutoutMask * baseMix + weightedReflection;
                #else
                // Recovered no-reflection family: F0 is front/back dependent,
                // and color is the recovered _Color slot.
                result.rgb = frontBack * _FinalColorMul * color.rgb * color.a;
                #endif
                // Alpha is the deferred bloom mask. Keep cutout and plane-cut
                // edge glow active when runtime keywords disable reflections.
                result.a = cutoutMask;

                #if defined(ACES_TONE_MAPPING)
                result = ApplyAcesTonemapping(result);
                #endif

                // There is no target main-effect route in this shader. Apply the
                // recovered white boost only after ACES and keep alpha.
                // Both routes use the shared Lit white-boost term (bloomValue = alpha,
                // multiplier = 1); Mixed is a ChroMapper extension that keeps its
                // white boost when POST_BLOOM is on. Deferred compiles the boost out,
                // matching the game's MAIN_EFFECT_ENABLED fragments.
                result = ApplyBloomTypeComposition(
                    result, result.rgb, 1, result.a, 1,
                    _BaseColorBoost, _BaseColorBoostThreshold, 0, result.a);

                float distanceSquared = i.worldPos.w * i.worldPos.w;
                #if defined(BLOOM_FOG) && (defined(_FOGTYPE_LERP) || defined(_FOGTYPE_COLOR) || defined(_FOGTYPE_ALPHA) || defined(HEIGHT_FOG))
                float fogTransmission = 1.0 - CalculateCustomFogFactor(
                    distanceSquared, _FogStartOffset, _FogScale);
                float fogBlend = 1.0 - fogTransmission;
                #if defined(HEIGHT_FOG)
                float heightFogDensity = CalculateCustomHeightFogFactor(
                    i.worldPos.xyz, _FogHeightOffset, _FogHeightScale);
                // This ordering matches the recovered full fog program:
                // height density is multiplied by distance transmission before
                // the bloom prepass blend is evaluated.
                fogBlend = 1.0 - heightFogDensity * fogTransmission;
                #endif

                float4 bloomPrepassCol = SampleBloomPrePass(i.screenPos);
                float4 bloomfogCol = fogBlend * (-result + bloomPrepassCol) + result;
                float sourceAlpha = result.a;
                result = BlendFogColor(result, bloomfogCol);
                #if !defined(_FOGTYPE_ALPHA)
                result.a = sourceAlpha;
                #endif
                #elif defined(HEIGHT_FOG)
                // The recovered no-bloom height route has no texture dependency.
                // It fades toward the observed constant height-fog color.
                float heightFogAmount = 1.0 - CalculateCustomHeightFogFactor(
                    i.worldPos.xyz, _FogHeightOffset, _FogHeightScale);
                result.rgb = lerp(result.rgb, 0.1.xxx, heightFogAmount);
                #endif

                return result;
            }
            ENDHLSL
        }
    }
}
