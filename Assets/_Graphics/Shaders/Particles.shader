// Replacement for the Beat Saber game shader Custom/CustomParticles.
Shader "ChroMapper/Particles"
{
    Properties
    {
        _Color ("Color", Color) = (1, 1, 1, 1)

        [Space]
        [Toggle(SECONDARY_COLOR)] _EnableSecondaryColor ("Use Secondary Color", float) = 0
        [ShowIfAny(SECONDARY_COLOR)] _SecondaryColor ("Secondary Color", Color) = (1,1,1,1)
        [ShowIfAny(SECONDARY_COLOR)] _SecondaryColorTex ("Secondary Color Texture", 2D) = "white" {}
        [ShowIfAny(SECONDARY_COLOR)] _SecondaryColorPanning ("Secondary Color Panning", Vector) = (0,0,0,0)

        [Space]
        [Toggle(COLOR_GRADIENT)] _UseColorGradient ("Use Color Gradient", float) = 0
        [ShowIfAny(COLOR_GRADIENT)] _ColorGradient ("Gradient LUT", 2D) = "white" {}
        [ShowIfAny(COLOR_GRADIENT)] _GradientPosition ("Gradient Position", Range(0, 1)) = 0.5
        [ShowIfAny(COLOR_GRADIENT)] _GradientPanningSpeed ("Gradient Panning Speed", float) = 0

        [Space]
        [Toggle(SPECTROGRAM_COLOR)] _UseSpectrogram ("Color by Spectrogram", float) = 0
        [ShowIfAny(SPECTROGRAM_COLOR)] _SpectrogramBaseValue ("Spectrogram Base Value", Range(0, 1)) = 0.2
        [ShowIfAny(SPECTROGRAM_COLOR)] _SpectrogramRange ("Spectrogram Range", Range(0, 1)) = 0.2

        [Space]
        [Toggle(COLOR_ARRAY)] _UseColorArray ("Use Color Array", float) = 0

        [Space]
        [KeywordEnum(None, Import)] _Secondary_UVs ("Secondary UVs", float) = 0
        [Toggle] _EnableRotateUV ("Rotate UVs 90", float) = 0
        _RotateUV ("Rotation Angle", float) = 0
        [Toggle] _RotateMainUVOnly ("Rotate Main UV Only", float) = 0



        [Header(Vertex)] [Space]
        [Toggle(VERTEX_COLOR)] _EnableVertexColor ("Vertex Color", float) = 0
        [ToggleShowIfAny(VERTEX_SQUARE_ALPHA, VERTEX_COLOR)] _SquareVertexAlpha ("Square Vertex Alpha", float) = 0
        [ToggleShowIfAny(VERTEX_RED_IS_ALPHA, VERTEX_COLOR)] _RedIsVertexAlpha ("Red is Vertex Alpha", float) = 0
        [EnumShowIfAny(3, RGBA, A, RGB, VERTEX_COLOR)] _VertexChannels ("Vertex Channels", float) = 0

        [Toggle(VERTEX_FLIPBOOK)] _EnableVertexFlipbook ("Enable Vertex Flipbook", float) = 0
        [ShowIfAny(VERTEX_FLIPBOOK)] _VertexFlipbookCount ("Frame Count", float) = 1
        [ShowIfAny(VERTEX_FLIPBOOK)] _VertexFlipbookSpeed ("Flipbook Speed", float) = 1
        [ToggleShowIfAny(VERTEX_FLIPBOOK_FADE, VERTEX_FLIPBOOK)] _EnableVertexFlipbookFade ("Enable Flipbook Fade", float) = 0

        [Space]
        [Toggle(VERTEX_DISPLACEMENT)] _VertexDisplacement ("Use Vertex Displacement", float) = 0
        [ShowIfAny(2, VERTEX_DISPLACEMENT, SPATIAL_DISPLACEMENT)] _DisplacementTex ("Displacement Texture", 2D) = "white" {}
        [ToggleShowIfAny(SPATIAL_DISPLACEMENT, VERTEX_DISPLACEMENT)] _3DDisplacement ("3D Displacement", float) = 0
        [ShowIfAny(2, VERTEX_DISPLACEMENT, SPATIAL_DISPLACEMENT)] _DisplacementStrength ("Strength", float) = 0.1
        [ShowIfAny(2, VERTEX_DISPLACEMENT, SPATIAL_DISPLACEMENT)] _DisplacementAxes ("Per Axis Strength", Vector) = (1,1,1,0)
        [ShowIfAny(2, VERTEX_DISPLACEMENT, SPATIAL_DISPLACEMENT)] _DisplacementPanningSpeed ("Panning Speed", float) = 1
        [ShowIfAny(2, VERTEX_DISPLACEMENT, SPATIAL_DISPLACEMENT)] _DisplacementPanning ("Panning", Vector) = (0,0,0,0)
        [EnumShowIfAny(2, None, Full, SPATIAL_DISPLACEMENT)] _Spectrogram ("Spectrogram Influence", float) = 0
        [ShowIfAny(_SPECTROGRAM_FULL)] _UV3Offset ("UV3 Offset", float) = 0
        [ShowIfAny(_SPECTROGRAM_FULL)] _UV3Scale ("UV3 Scale", float) = 1

        [Space]
        [KeywordEnum(None, Around_X, Around_Y, Around_Z)] _Curve_Vertices ("Curve Vertices (Object Space)", float) = 0



        [Header(Texture)] [Space]
        [Toggle(MAIN_TEXTURE)] _UseMainTex ("Base Texture", float) = 1
        _BaseLayer ("Base Color", float) = 1
        _MainTex ("Texture", 2D) = "white" {}

        [Space]
        [Toggle(PIXELATE)] _Pixelate ("Pixelate", float) = 0
        [VectorShowIfAny(2, PIXELATE)] _PixelateResolution ("Pixelate Resolution", Vector) = (64,64,0,0)

        [Space]
        [Toggle(TEXTURE_COLOR)] _EnableTextureColor ("Use Texture Color", float) = 0
        [EnumShowIfAny(2, Alpha, Red, 0TEXTURE_COLOR)] _AlphaChannel ("Alpha Channel", float) = 0

        [Space]
        _Intensity("Color Intensity", float) = 1
        _UvPanning ("UV Panning", Vector) = (0,0,0,0)

        [Space]
        [Toggle(CUSTOM_WRAPPING)] _EnableCustomPadding ("Custom Repeat Wrapping", float) = 0
        [VectorShowIfAny(2, CUSTOM_WRAPPING)] _CustomPadding ("Custom Padding", Vector) = (0,0,0,0)

        [Space]
        [Toggle(TEXTURE_FLIPBOOK)] _UseTextureFlipbook ("Use Texture Flipbook", float) = 0
        [ShowIfAny(TEXTURE_FLIPBOOK)] _FlipbookColumns ("Flipbook Columns", float) = 8
        [ShowIfAny(TEXTURE_FLIPBOOK)] _FlipbookRows ("Flipbook Rows", float) = 8
        [ShowIfAny(TEXTURE_FLIPBOOK)] _FlipbookNonloopableFrames ("Full Non-loopable frames", float) = 0
        [ShowIfAny(TEXTURE_FLIPBOOK)] _FlipbookSpeed ("Flipbook Speed", float) = 1
        [ToggleShowIfAny(FLIPBOOK_BLENDING_OFF, TEXTURE_FLIPBOOK)] _FlipbookBlendingOff ("No Frame Blending", float) = 0

        [Space]
        [Toggle(MASK)] _EnableMask ("Mask", float) = 0
        [ToggleShowIfAny(SECONDARY_UVS_MASK, MASK)] _MaskSecondaryUVs ("Use Secondary UVs", float) = 0
        [ToggleShowIfAny(MASK_RED_IS_ALPHA, MASK)] _MaskRedIsAlpha ("Red is Alpha", float) = 0
        [EnumShowIfAny(3, Multiply, Add, Masked Add, MASK)] _MaskBlend ("Mask Blend", float) = 0
        [ShowIfAny(MASK)] _MaskTex ("Mask Texture", 2D) = "white" {}
        [ShowIfAny(MASK)] _MaskStrength ("Mask Strength", float) = 1
        [ShowIfAny(MASK)] _MaskPanning ("Mask Panning", Vector) = (0,0,0,0)

        [Space]
        [Toggle(MASK2)] _EnableMask2 ("Secondary Mask", float) = 0
        [ToggleShowIfAny(SECONDARY_UVS_MASK2, MASK2)] _Mask2SecondaryUVs ("Use Secondary UVs", float) = 0
        [ToggleShowIfAny(MASK2_RED_IS_ALPHA, MASK2)] _Mask2RedIsAlpha ("Red is Alpha", float) = 0
        [EnumShowIfAny(3, Multiply, Add, Masked Add, MASK2)] _Mask2Blend ("Secondary Mask Blend", float) = 0
        [ShowIfAny(MASK2)] _Mask2Tex ("Secondary Mask Texture", 2D) = "white" {}
        [ShowIfAny(MASK2)] _Mask2Strength ("Secondary Mask Strength", float) = 1
        [ShowIfAny(MASK2)] _Mask2Panning ("Secondary Mask Panning", Vector) = (0,0,0,0)

        [Space]
        [KeywordEnum(None, Simple)] _Distortion ("Distortion", float) = 0
        [ShowIfAny(_DISTORTION_SIMPLE)] _DistortionTex ("Distortion Texture", 2D) = "white" {}
        [ShowIfAny(_DISTORTION_SIMPLE)] _DistortionStrength ("Distortion Strength", float) = 0.2
        [ShowIfAny(_DISTORTION_SIMPLE)] _DistortionAxes ("Distortion Axes", Vector) = (1, 1, 0, 0)
        [ShowIfAny(_DISTORTION_SIMPLE)] _DistortionPanning ("Distortion Panning", Vector) = (0, 0, 0, 0)
        [ToggleShowIfAny(DISTORTION_TARGET_MASK, MASK)] _DistortionTargetMask ("Distort Mask UVs", float) = 0

        [Header(Dissolve)] [Space]
        [KeywordEnum(None, Alpha Clip)] _CutoutType ("Cutout", float) = 0
        [ShowIfAny(_CUTOUTTYPE_WORLDSPACE_NOISE, _CUTOUTTYPE_ALPHA_CLIP, _CUTOUTTYPE_SCALE)] _Cutout ("Threshold", Range(0, 1)) = 0.5



        [Header(Alpha Handling)] [Space]
        _AlphaMultiplier ("Alpha Multiplier", float) = 1
        [Toggle(SQUARE_ALPHA)] _SquareAlpha("Square Alpha", float) = 1

        [Space]
        [Toggle(VIEW_ALIGN_DISAPPEAR)] _EnableViewAlignDisappear ("View Align Disappear", float) = 0
        [ShowIfAny(VIEW_ALIGN_DISAPPEAR)] _SquareAngleForViewAlignDisappear ("Square Angle", float) = 0
        [ShowIfAny(VIEW_ALIGN_DISAPPEAR)] _ViewAlignFactor ("View Align Factor", float) = 1.5
        [ShowIfAny(VIEW_ALIGN_DISAPPEAR)] _ViewAlignOffset ("View Align Offset", float) = 0



        [Header(Others)] [Space]
        [KeywordEnum(None, Deferred, Mixed)] _BloomType ("Bloom Type", float) = 0
        [ShowIfAny(_BLOOMTYPE_DEFERRED, _BLOOMTYPE_MIXED)] _QuestWhiteboostMultiplier ("White Multiplier", float) = 1
        [ShowIfAny(_BLOOMTYPE_DEFERRED, _BLOOMTYPE_MIXED)] _BloomMultiplier ("Bloom Multiplier", float) = 1
        [Toggle(REMAP_WHITEBOOST_START)] _EnableRemapWhiteBoostStart ("Remap White Boost Start", float) = 0
        [ShowIfAny(_BLOOMTYPE_DEFERRED, _BLOOMTYPE_MIXED)] _WhiteBoostRemapStart ("Alpha for no White Boost", Range(0, 1)) = 0

        [Space]
        [KeywordEnum(None, Full, Y Axis, Camera Facing)] _Billboard ("Billboard", float) = 0
        [ShowIfAny(_BILLBOARD_FULL, _BILLBOARD_CAMERA_FACING)] _BillboardScale ("Billboard Scale", float) = 1

        [Space]
        [KeywordEnum(Standard, Song Time, Freeze)] _Custom_Time ("Time Behavior", float) = 0
        [Toggle(MESH_PACKING)] _MeshPacking ("Use Mesh Packed Instancing", Float) = 0
        [ShowIfAny(MESH_PACKING)] _MeshPackingId ("Mesh Packing ID", float) = 0



        [Header(Lifetime and Soft Particles)] [Space]
        [Toggle(LIFETIME)] _EnableLifetime ("Use Lifetime Fade", float) = 0
        [ShowIfAny(LIFETIME)] _Lifetime ("Lifetime Fade", float) = 1
        [ToggleShowIfAny(SOFT_PARTICLES)] _EnableSoftParticles ("Soft Particles", float) = 0
        [ShowIfAny(SOFT_PARTICLES)] _SoftFactor ("Soft Factor", Range(0, 50)) = 0
        [ToggleShowIfAny(CLOSE_TO_CAMERA_DISAPPEAR)] _EnableViewAlignedDisappearDistance ("Close-to-Camera Disappear", float) = 0
        [ShowIfAny(CLOSE_TO_CAMERA_DISAPPEAR)] _CloseCameraDisappearDistance ("Disappear Distance", float) = 0.5
        [ShowIfAny(CLOSE_TO_CAMERA_DISAPPEAR)] _CloseCameraDisappearWidth ("Disappear Width", float) = 1
        [ShowIfAny(CLOSE_TO_CAMERA_DISAPPEAR)] _CloseCameraDisappearStrength ("Disappear Strength", float) = 1

        [Header(Dissolve)] [Space]
        [Toggle(DISSOLVE)] _EnableDissolve ("Dissolve", float) = 0
        [KeywordEnum(None, World, World Centered)] _Dissolve_Space ("Dissolve Space", float) = 0
        [ShowIfAny(DISSOLVE)] _DissolveAxisVector ("Dissolve Axis", Vector) = (0, 1, 0, 0)
        [ShowIfAny(DISSOLVE)] _DissolveOffset ("Dissolve Offset", float) = 0
        [ShowIfAny(DISSOLVE)] _DissolveScale ("Dissolve Scale", float) = 5
        [ShowIfAny(DISSOLVE)] _DissolveReverse ("Reverse Dissolve", float) = 0
        [ShowIfAny(DISSOLVE)] _DissolveStrength ("Dissolve Strength", float) = 1
        [ToggleShowIfAny(DISSOLVE_PROGRESS_FROM_VERTEX_ALPHA, DISSOLVE)] _DissolveProgressFromVertexAlpha ("Get Progress from Vertex Alpha", float) = 0
        [ShowIfAny(DISSOLVE)] _DissolveProgress ("Dissolve Progress", Range(-1, 1)) = 0

        [Header(World Space Panning)] [Space]
        [Toggle(WORLDSPACE_PANNING_MAIN)] _EnableWorldspacePanningMain ("Worldspace Panning (Main)", float) = 0
        [ShowIfAny(WORLDSPACE_PANNING_MAIN)] _WorldspacePanningSpeed ("Panning Speed", float) = 1
        [ShowIfAny(WORLDSPACE_PANNING_MAIN)] _WorldspacePanningDirection ("Worldspace Panning Direction", Vector) = (0, 0, 1, 0)
        [ShowIfAny(WORLDSPACE_PANNING_MAIN)] _WorldspacePanningOffset ("Worldspace Panning Offset", Vector) = (0, 0, 0, 0)

        [Header(MIPMAP and Noise)]
        [Toggle(MIPMAP_BIAS)] _EnableMipmapBias ("Mipmap Bias", float) = 0
        [ShowIfAny(MIPMAP_BIAS)] _MipmapBias ("Texture Mipmap Bias", float) = 0
        [ShowIfAny(MIPMAP_BIAS)] _MipmapFade ("View Angle Fade", float) = 0
        [Toggle(NOISE_DITHERING)] _EnableNoiseDithering ("Noise Dithering", float) = 0

        [Space]
        [Toggle(HOLOGRAM)] _EnableHologram ("Hologram", float) = 0
        [ShowIfAny(HOLOGRAM)] _HologramColor ("Hologram Color", Color) = (0.5, 0.8, 1, 1)
        [Toggle(FAKE_MIRROR_TRANSPARENCY)] _EnableFakeMirrorTransparency ("Fake Mirror Transparency", float) = 0
        [ShowIfAny(FAKE_MIRROR_TRANSPARENCY)] _FakeMirrorTransparency ("Fake Mirror Transparency", float) = 0.5

        [Toggle(FILL_ALPHA)] _EnableFillAlpha ("Fill Alpha", float) = 0
        [ShowIfAny(FILL_ALPHA)] _FillAlpha ("Fill Alpha", Range(0, 1)) = 1
        [Toggle(_OVERRIDE_FINAL_ALPHA_COLOR_BASED)] _EnableOverrideFinalAlpha ("Override Final Alpha (Color Based)", float) = 0
        [ShowIfAny(_OVERRIDE_FINAL_ALPHA_COLOR_BASED)] _OverrideFinalAlpha ("Override Alpha Amount", Range(0, 1)) = 0

        [Header(Fog Settings)] [Space]
        [KeywordEnum(None, Lerp, Color, Alpha)] _FogType ("Fog Type", float) = 0
        [ShowIfAny(_FOGTYPE_LERP, _FOGTYPE_COLOR, _FOGTYPE_ALPHA)] _FogStartOffset ("Fog Start Offset", float) = 0
        [ShowIfAny(_FOGTYPE_LERP, _FOGTYPE_COLOR, _FOGTYPE_ALPHA)] _FogScale ("Fog Scale", float) = 1
        [Space]
        [ToggleShowIfAny(HEIGHT_FOG, _FOGTYPE_LERP, _FOGTYPE_COLOR, _FOGTYPE_ALPHA)] _EnableHeightFog ("Enable Height Fog", float) = 0
        [ShowIfAny(4, _FOGTYPE_LERP, _FOGTYPE_COLOR, _FOGTYPE_ALPHA, HEIGHT_FOG)] _FogHeightOffset ("Fog Height Offset", float) = 0
        [ShowIfAny(4, _FOGTYPE_LERP, _FOGTYPE_COLOR, _FOGTYPE_ALPHA, HEIGHT_FOG)] _FogHeightScale ("Fog Height Scale", float) = 1
        [ToggleShowIfAny(PRECISE_FOG, _FOGTYPE_LERP, _FOGTYPE_COLOR, _FOGTYPE_ALPHA)] _PreciseFog ("Precise Fog", float) = 0

        [Header(Settings)] [Space]
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendModeSrc ("Blend Src", float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendModeDst ("Blend Dst", float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendModeSrcA ("Blend Src A", float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendModeDstA ("Blend Dst A", float) = 1
        [Enum(UnityEngine.Rendering.BlendOp)] _BlendOp ("Blend Operation", float) = 0
        [Space]
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode ("Cull Mode", float) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("Z Test", float) = 4
        [Enum(Off, 0, On, 1)] _ZWrite ("Z Write", float) = 0
        _OffsetFactor ("Offset Factor", float) = 0
        _OffsetUnits ("Offset Units", float) = 0

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
            "RenderType"="Transparent"
        }

        Blend [_BlendModeSrc] [_BlendModeDst], [_BlendModeSrcA] [_BlendModeDstA]
        BlendOp [_BlendOp]
        Cull [_CullMode]
        ZTest [_ZTest]
        ZWrite [_ZWrite]
        Lighting Off
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

            #pragma shader_feature_local SECONDARY_COLOR

            #pragma shader_feature_local COLOR_GRADIENT

            #pragma shader_feature_local_vertex SPECTROGRAM_COLOR
            #pragma shader_feature_local_fragment SPECTROGRAM_COLOR

            #pragma shader_feature_local COLOR_ARRAY

            #pragma shader_feature_local _ _SECONDARY_UVS_IMPORT

            #pragma shader_feature_local_vertex VERTEX_COLOR
            #pragma shader_feature_local_vertex VERTEX_SQUARE_ALPHA
            #pragma shader_feature_local_vertex VERTEX_RED_IS_ALPHA
            #pragma shader_feature_local_vertex _ _VERTEXCHANNELS_A _VERTEXCHANNELS_RGB

            #pragma shader_feature_local_vertex VERTEX_DISPLACEMENT
            #pragma shader_feature_local_vertex SPATIAL_DISPLACEMENT
            #pragma shader_feature_local_vertex _ _SPECTROGRAM_FULL

            #pragma shader_feature_local_vertex _ _CURVE_VERTICES_AROUND_X _CURVE_VERTICES_AROUND_Y _CURVE_VERTICES_AROUND_Z
            #pragma shader_feature_local_vertex MESH_PACKING

            #pragma shader_feature_local MAIN_TEXTURE

            #pragma shader_feature_local_fragment PIXELATE

            #pragma shader_feature_local_fragment TEXTURE_COLOR
            #pragma shader_feature_local_fragment _ _ALPHACHANNEL_RED

            #pragma shader_feature_local_fragment CUSTOM_WRAPPING

            #pragma shader_feature_local TEXTURE_FLIPBOOK
            #pragma shader_feature_local FLIPBOOK_BLENDING_OFF

            #pragma shader_feature_local MASK
            #pragma shader_feature_local SECONDARY_UVS_MASK
            #pragma shader_feature_local MASK_RED_IS_ALPHA
            #pragma shader_feature_local _ _MASKBLEND_ADD _MASKBLEND_MASKED_ADD

            #pragma shader_feature_local MASK2
            #pragma shader_feature_local SECONDARY_UVS_MASK2
            #pragma shader_feature_local MASK2_RED_IS_ALPHA
            #pragma shader_feature_local _ _MASK2BLEND_ADD _MASK2BLEND_MASKED_ADD

            #pragma shader_feature_local _ _DISTORTION_SIMPLE
            #pragma shader_feature_local_fragment DISTORTION_TARGET_MASK

            #pragma shader_feature_local_fragment _ _CUTOUTTYPE_ALPHA_CLIP

            #pragma shader_feature_local_fragment SQUARE_ALPHA
            #pragma shader_feature_local_fragment VIEW_ALIGN_DISAPPEAR

            // Lifetime / depth / distance gates
            #pragma shader_feature_local_fragment LIFETIME
            #pragma shader_feature_local SOFT_PARTICLES
            #pragma shader_feature_local_fragment CLOSE_TO_CAMERA_DISAPPEAR
            #pragma shader_feature_local_fragment FILL_ALPHA
            #pragma shader_feature_local_fragment _OVERRIDE_FINAL_ALPHA_COLOR_BASED

            // Dissolve
            #pragma shader_feature_local DISSOLVE
            #pragma shader_feature_local _DISSOLVE_SPACE_NONE _DISSOLVE_SPACE_WORLD _DISSOLVE_SPACE_WORLD_CENTERED
            #pragma shader_feature_local DISSOLVE_PROGRESS_FROM_VERTEX_ALPHA

            // World-space mapping / vertex flipbook
            #pragma shader_feature_local_vertex WORLDSPACE_PANNING_MAIN
            #pragma shader_feature_local VERTEX_FLIPBOOK
            #pragma shader_feature_local VERTEX_FLIPBOOK_FADE

            // Sampling / dithering / fx
            #pragma shader_feature_local MIPMAP_BIAS
            #pragma shader_feature_local_fragment NOISE_DITHERING
            #pragma shader_feature_local_fragment HOLOGRAM
            #pragma shader_feature_local_fragment FAKE_MIRROR_TRANSPARENCY
            #pragma shader_feature_local_fragment PRECISE_FOG

            #pragma shader_feature_local_fragment _ _BLOOMTYPE_DEFERRED _BLOOMTYPE_MIXED
            // Global: the post-process bloom runs (mirrors the game's MAIN_EFFECT_ENABLED gate).
            #pragma multi_compile _ POST_BLOOM
            #pragma shader_feature_local_fragment REMAP_WHITEBOOST_START

            #pragma shader_feature_local_vertex _ _BILLBOARD_FULL _BILLBOARD_Y_AXIS _BILLBOARD_CAMERA_FACING
            #pragma shader_feature_local _ _CUSTOM_TIME_SONG_TIME _CUSTOM_TIME_FREEZE

            #pragma shader_feature_local_fragment _ _FOGTYPE_LERP _FOGTYPE_COLOR _FOGTYPE_ALPHA
            #pragma shader_feature_local_fragment HEIGHT_FOG

            #pragma multi_compile_fragment _ BLOOM_FOG
            #define FOG (defined(_FOGTYPE_LERP) || defined(_FOGTYPE_COLOR) || defined(_FOGTYPE_ALPHA))

            #include "UnityCG.cginc"
            #include "ShaderLibrary/Fog.hlsl"
            #include "ShaderLibrary/CustomBloom.hlsl"
            #include "ShaderLibrary/CustomTime.hlsl"
            #include "Packages/com.llealloo.audiolink/Runtime/Shaders/AudioLink.cginc"

            // SECONDARY_COLOR
            sampler2D _SecondaryColorTex;
            float4 _SecondaryColorTex_ST;
            float4 _SecondaryColorPanning;
            // --

            // COLOR_GRADIENT
            sampler2D _ColorGradient;
            float4 _ColorGradient_ST;
            float _GradientPosition;
            float _GradientPanningSpeed;
            // --

            // SPECTROGRAM_COLOR
            float _SpectrogramBaseValue;
            float _SpectrogramRange;
            // --

            // _SECONDARY_UVS_IMPORT
            float _EnableRotateUV;
            float _RotateUV;
            float _RotateMainUVOnly;
            // --

            // VERTEX_DISPLACEMENT
            sampler2D _DisplacementTex;
            float4 _DisplacementTex_ST;
            float _DisplacementStrength;
            // SPATIAL_DISPLACEMENT
            float4 _DisplacementAxes;
            // --
            float _DisplacementPanningSpeed;
            float4 _DisplacementPanning;
            // _SPECTROGRAM_FULL
            float _UV3Offset;
            float _UV3Scale;
            // --
            // --

            // MAIN_TEXTURE
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _BaseLayer;
            // --

            // PIXELATE
            float2 _PixelateResolution;
            // --

            float _Intensity;
            float4 _UvPanning;

            // COLOR_ARRAY
            #if defined(COLOR_ARRAY)
            float4 _ColorsArray[150];
            float _ColorsArrayOffset;
            #endif
            // --

            // CUSTOM_WRAPPING
            float2 _CustomPadding;
            // --

            // TEXTURE_FLIPBOOK
            float _FlipbookColumns;
            float _FlipbookRows;
            float _FlipbookNonloopableFrames;
            float _FlipbookSpeed;
            // VERTEX_FLIPBOOK
            float _VertexFlipbookCount;
            float _VertexFlipbookSpeed;
            // --

            // MASK
            sampler2D _MaskTex;
            float4 _MaskTex_ST;
            // --

            // MASK2
            sampler2D _Mask2Tex;
            float4 _Mask2Tex_ST;
            // --

            sampler2D _DistortionTex;
            float4 _DistortionTex_ST;

            UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);

            // LIFETIME
            float _Lifetime;
            // --

            // SOFT_PARTICLES
            float _SoftFactor;
            // --

            // CLOSE_TO_CAMERA_DISAPPEAR
            float _CloseCameraDisappearDistance;
            float _CloseCameraDisappearWidth;
            float _CloseCameraDisappearStrength;
            // --

            // DISSOLVE
            float4 _DissolveAxisVector;
            float _DissolveOffset;
            float _DissolveScale;
            float _DissolveReverse;
            float _DissolveStrength;
            float _DissolveProgress;
            // --

            // WORLDSPACE_PANNING_MAIN
            float _WorldspacePanningSpeed;
            float4 _WorldspacePanningDirection;
            float4 _WorldspacePanningOffset;
            // --

            // MIPMAP_BIAS
            float _MipmapBias;
            float _MipmapFade;
            // --

            // NOISE_DITHERING / HOLOGRAM
            sampler2D _GlobalBlueNoiseTex;
            float4 _HologramColor;
            // --

            // FAKE_MIRROR_TRANSPARENCY
            float _FakeMirrorTransparency;
            // --

            // FILL_ALPHA / _OVERRIDE_FINAL_ALPHA_COLOR_BASED
            float _FillAlpha;
            float _OverrideFinalAlpha;
            // --

            #define USE_BILLBOARD defined(_BILLBOARD_FULL) || defined(_BILLBOARD_Y_AXIS) || defined(_BILLBOARD_CAMERA_FACING)

            inline float3 GetParticlesCameraPosition()
            {
                #if defined(UNITY_SINGLE_PASS_STEREO) || defined(STEREO_INSTANCING_ON) || defined(STEREO_MULTIVIEW_ON)
                return unity_StereoWorldSpaceCameraPos[unity_StereoEyeIndex];
                #else
                return _WorldSpaceCameraPos;
                #endif
            }


            #if defined(UNITY_INSTANCING_ENABLED)
            UNITY_INSTANCING_BUFFER_START(Props)
                UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
                UNITY_DEFINE_INSTANCED_PROP(float4, _SecondaryColor)
                UNITY_DEFINE_INSTANCED_PROP(float, _MaskStrength)
                UNITY_DEFINE_INSTANCED_PROP(float, _Mask2Strength)
                UNITY_DEFINE_INSTANCED_PROP(float, _TimeOffset)
                UNITY_DEFINE_INSTANCED_PROP(float, _MeshPackingId)
            UNITY_INSTANCING_BUFFER_END(Props)
            #endif

            UNITY_INSTANCING_BUFFER_START(PerDrawSprite)
                UNITY_DEFINE_INSTANCED_PROP(float4, unity_SpriteRendererColorArray)
                UNITY_DEFINE_INSTANCED_PROP(half2, unity_SpriteFlipArray)
            UNITY_INSTANCING_BUFFER_END(PerDrawSprite)
            #define _RendererColor UNITY_ACCESS_INSTANCED_PROP(PerDrawSprite, unity_SpriteRendererColorArray)
            #define _Flip UNITY_ACCESS_INSTANCED_PROP(PerDrawSprite, unity_SpriteFlipArray)

            CBUFFER_START(UnityPerMaterial)
                #if !defined(UNITY_INSTANCING_ENABLED)
                float4 _Color;
                float4 _SecondaryColor;
                // _RendererColor and _Flip are now macros in the non-instanced path above,
                // so we do not declare them as uniforms here (they would never be set anyway).
                float _MaskStrength;
                float _Mask2Strength;
                float _TimeOffset;
                float _MeshPackingId;
                #endif
                float _EnableExternalAlpha;
                float2 _MaskPanning;
                float4 _Mask2Panning;
                float4 _DistortionPanning;
                float _DistortionStrength;
                float4 _DistortionAxes;
                float _Cutout;
                float _AlphaMultiplier;
                float _SquareAngleForViewAlignDisappear;
                float _ViewAlignFactor;
                float _ViewAlignOffset;
                float _BloomMultiplier;
                float _WhiteBoostRemapStart;
                float _QuestWhiteboostMultiplier;
                float _BillboardScale;
                float _FogStartOffset;
                float _FogScale;
                float _FogHeightOffset;
                float _FogHeightScale;
            CBUFFER_END

            inline float CalculateParticleHeightFogClearFactor(float3 worldPosition)
            {
                float heightInput = worldPosition.y * _FogHeightScale + _FogHeightOffset;
                #if defined(PRECISE_FOG)
                // The source PRECISE_FOG route evaluates this curve per fragment. ChroMapper
                // already carries worldPosition to the fragment stage, so use the exact curve here.
                heightInput -= _CustomFogHeightFogHeight + _CustomFogHeightFogStartY;
                heightInput = saturate(heightInput / _CustomFogHeightFogHeight);
                return 1.0 - heightInput * heightInput * (3.0 - 2.0 * heightInput);
                #else
                return CalculateHeightFogFactor(heightInput);
                #endif
            }

            struct appdata_t
            {
                float4 vertex : POSITION;

                float4 color : COLOR;

                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 uv1 : TEXCOORD0;
                #if defined(_SECONDARY_UVS_IMPORT)
                float2 uv2 : TEXCOORD1;
                #endif
                #if defined(_SPECTROGRAM_FULL) || defined(SPECTROGRAM_COLOR)
                float2 uv3 : TEXCOORD2;
                #endif
                #if defined(MESH_PACKING)
                float2 packingUv : TEXCOORD3;
                #endif
                #if defined(COLOR_ARRAY)
                float2 colorIndexUv : TEXCOORD4; // ADD — encodes color index as (tens, units)
                #endif
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;

                float4 color : COLOR;

                #if defined(_SECONDARY_UVS_IMPORT) || defined(VERTEX_FLIPBOOK)
                float4 uv : TEXCOORD0;
                #else
                float2 uv : TEXCOORD0;
                #endif
                float3 worldPos : TEXCOORD1;
                float4 screenPos : TEXCOORD2;
                float3 localPos : TEXCOORD3;

                #if defined(TEXTURE_FLIPBOOK)
                float4 flipbookWeights : TEXCOORD7;
                #endif

                #if defined(DISSOLVE_PROGRESS_FROM_VERTEX_ALPHA)
                float vertexAlpha : TEXCOORD8;
                #endif

                #if defined(COLOR_ARRAY)
                float2 colorIndexUv : TEXCOORD4;
                #endif

                #if defined(SPECTROGRAM_COLOR)
                float2 spectrogramUv : TEXCOORD5;
                #endif

                #if defined(MIPMAP_BIAS) || defined(VIEW_ALIGN_DISAPPEAR)
                float3 worldNormal : TEXCOORD6;
                #endif

                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            inline float4 UnityFlipSprite(in float3 pos, in half2 flip)
            {
                // _Flip is (0,0) when not set by a SpriteRenderer (e.g. particle systems).
                // Guard against this so vertices are not collapsed to the origin.
                half2 safeFlip = (abs(flip.x) < 0.001 && abs(flip.y) < 0.001) ? half2(1, 1) : flip;
                return float4(pos.xy * safeFlip, pos.z, 1.0);
            }

            inline float4 GetSpriteRendererColor()
            {
                // SpriteRenderer supplies both per-draw values. Particle and mesh
                // renderers leave the flip at zero, so their color must stay white.
                float isSpriteRenderer = step(0.5, max(abs(_Flip.x), abs(_Flip.y)));
                return lerp(float4(1, 1, 1, 1), _RendererColor, isSpriteRenderer);
            }

            v2f vert(appdata_t i)
            {
                v2f o;

                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_TRANSFER_INSTANCE_ID(i, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.color = float4(1, 1, 1, 1);
                #if defined(TEXTURE_FLIPBOOK)
                o.flipbookWeights = float4(1, 0, 0, 0);
                #endif
                #if defined(DISSOLVE_PROGRESS_FROM_VERTEX_ALPHA)
                o.vertexAlpha = i.color.a;
                #endif

                #if USE_BILLBOARD
                float3 worldOrigin = mul(unity_ObjectToWorld, float4(0, 0, 0, 1)).xyz;
                o.localPos = i.vertex.xyz;

                #if defined(_BILLBOARD_FULL)
                // The source FULL route uses the camera basis directly. ChroMapper can match
                // this route because the editor mesh supplies a local vertex position.
                // Transform only the object origin to view space (not the vertex)
                float4 viewOrigin = mul(UNITY_MATRIX_V, float4(worldOrigin, 1));
                // Only offset XY in view space — zero Z so depth stays anchored at the object origin.
                // Use vertex.xy only (ignore Z), and scale uniformly via _BillboardScale scalar.
                float4 billboardViewPos = viewOrigin + float4(i.vertex.xy * _BillboardScale, 0.0, 0.0);
                // Store real world-space position (from the unmodified vertex) for fog/lighting in frag.
                o.worldPos = mul(unity_ObjectToWorld, i.vertex).xyz;
                o.vertex = mul(UNITY_MATRIX_P, billboardViewPos);
                #endif

                #if defined(_BILLBOARD_CAMERA_FACING)
                // The source CAMERA_FACING route has a separate camera-facing basis. ChroMapper
                // editor particle meshes do not carry the source particle orientation stream.
                // Use the same camera-plane adapter as FULL and document this parity limit.
                float4 cameraFacingOrigin = mul(UNITY_MATRIX_V, float4(worldOrigin, 1));
                float4 cameraFacingViewPos = cameraFacingOrigin +
                    float4(i.vertex.xy * _BillboardScale, 0.0, 0.0);
                o.worldPos = mul(unity_ObjectToWorld, i.vertex).xyz;
                o.vertex = mul(UNITY_MATRIX_P, cameraFacingViewPos);
                #endif

                #if defined(_BILLBOARD_Y_AXIS)
                float3 localUp = normalize(mul((float3x3)unity_ObjectToWorld, float3(0, 1, 0)));
                float3 cameraPosition = GetParticlesCameraPosition();
                float3 dirToCam = cameraPosition - worldOrigin;
                float3 look = normalize(dirToCam - localUp * dot(dirToCam, localUp));
                float3 right = -normalize(cross(localUp, look));

                o.worldPos = worldOrigin + right * i.vertex.x * _BillboardScale + localUp * i.vertex.y *
                    _BillboardScale;
                o.vertex = mul(UNITY_MATRIX_VP, float4(o.worldPos, 1.0));
                #endif

                #else

                #if defined(VERTEX_DISPLACEMENT) || defined(SPATIAL_DISPLACEMENT)
                float4 time = GetTime(UNITY_ACCESS_INSTANCED_PROP(Props, _TimeOffset)) / 2;
                float2 dispUV = TRANSFORM_TEX(i.uv1, _DisplacementTex)
                    + _DisplacementPanning.xy * time.y * _DisplacementPanningSpeed;
                float3 dispSample = tex2Dlod(_DisplacementTex, float4(dispUV, 0, 0)).xyz * 2.0 - 1.0;

                #if defined(SPATIAL_DISPLACEMENT)
                float3 bitangent = i.tangent.yzx * i.normal.zxy - i.normal.yzx * i.tangent.zxy;
                float3 dispDir = dispSample.x * i.tangent.xyz
                    + dispSample.y * bitangent
                    + dispSample.z * i.normal.xyz;
                dispDir = normalize(dispDir);

                #if defined(_SPECTROGRAM_FULL)
                float spectrogramIndex = i.uv3.x * _UV3Scale + _UV3Offset;
                float4 audioData = AudioLinkLerpMultiline(
                    ALPASS_DFT + uint2(spectrogramIndex * AUDIOLINK_ETOTALBINS, 0));
                float dispAmount = _DisplacementStrength * audioData.b * 2;
                #else
                float dispAmount = _DisplacementStrength;
                #endif
                i.vertex.xyz += dispDir * dispAmount * _DisplacementAxes.xyz;
                #else
                i.vertex.y += dispSample.x * _DisplacementStrength;
                #endif
                #endif

                float angle, s, c;
                #if defined(_CURVE_VERTICES_AROUND_X)
                angle = i.vertex.y;
                sincos(angle, s, c);
                i.vertex.xyz = float3(i.vertex.x, i.vertex.y * c - i.vertex.z * s, i.vertex.y * s + i.vertex.z * c);
                float3 normal = float3(i.normal.x, i.normal.y * c - i.normal.z * s, i.normal.y * s + i.normal.z * c);
                #elif defined(_CURVE_VERTICES_AROUND_Y)
                angle = i.vertex.x;
                sincos(angle, s, c);
                i.vertex.xyz = float3(i.vertex.x * c - i.vertex.z * s, i.vertex.y, i.vertex.x * s + i.vertex.z * c);
                float3 normal = float3(i.normal.x * c - i.normal.z * s, i.normal.y, i.normal.x * s + i.normal.z * c);
                #elif defined(_CURVE_VERTICES_AROUND_Z)
                angle = i.vertex.y / i.vertex.x;
                sincos(angle, s, c);
                i.vertex.xyz = float3(i.vertex.x * c, i.vertex.x * s, i.vertex.z);
                float3 normal = float3(i.normal.x * c, i.normal.x * s, i.normal.z);
                #endif

                o.vertex = UnityFlipSprite(i.vertex, _Flip);
                o.localPos = o.vertex.xyz;
                o.worldPos = mul(unity_ObjectToWorld, o.vertex).xyz;
                o.vertex = UnityObjectToClipPos(o.vertex);
                #endif
                #if !defined(VERTEX_DISPLACEMENT) && !defined(SPATIAL_DISPLACEMENT)
                float4 time = GetTime(UNITY_ACCESS_INSTANCED_PROP(Props, _TimeOffset)) / 2;
                #endif
                #if defined(MAIN_TEXTURE)
                {
                    #if defined(WORLDSPACE_PANNING_MAIN)
                    // World-space main UV (corpus vertex decode: project the panning
                    // direction onto the surface basis, then apply tile/pan).
                    float3 wTangent = i.tangent.xyz;
                    float3 wBitangent = i.normal.yzx * i.tangent.zxy - i.tangent.yzx * i.normal.zxy;
                    float2 wuv = abs(float2(dot(_WorldspacePanningDirection.xyz, wTangent),
                                            dot(_WorldspacePanningDirection.xyz, wBitangent))) * _MainTex_ST.xy;
                    float2 worldspaceUv = i.uv1.xy * wuv + _MainTex_ST.zw;
                    worldspaceUv += time.y * _WorldspacePanningSpeed * wuv;
                    o.uv.xy = worldspaceUv + _WorldspacePanningOffset.xy;
                    #else
                    float2 panOffset = time.y * _UvPanning.xy * _MainTex_ST.xy;
                    o.uv.xy = i.uv1.xy * _MainTex_ST.xy + _MainTex_ST.zw + panOffset;
                    #endif
                }
                #else
                o.uv.xy = i.uv1.xy;
                #endif
                #if defined(_SECONDARY_UVS_IMPORT)
                o.uv.zw = i.uv2.xy;
                #endif
                if (_EnableRotateUV > 0.5)
                {
                    float rotation = abs(_RotateUV) > 0.0001 ? radians(_RotateUV) : UNITY_PI * 0.5;
                    float rotationSin;
                    float rotationCos;
                    sincos(rotation, rotationSin, rotationCos);
                    float2 mainCenteredUv = o.uv.xy - 0.5;
                    o.uv.xy = float2(
                        mainCenteredUv.x * rotationCos - mainCenteredUv.y * rotationSin,
                        mainCenteredUv.x * rotationSin + mainCenteredUv.y * rotationCos) + 0.5;
                    #if defined(_SECONDARY_UVS_IMPORT)
                    if (_RotateMainUVOnly < 0.5)
                    {
                        float2 secondaryCenteredUv = o.uv.zw - 0.5;
                        o.uv.zw = float2(
                            secondaryCenteredUv.x * rotationCos - secondaryCenteredUv.y * rotationSin,
                            secondaryCenteredUv.x * rotationSin + secondaryCenteredUv.y * rotationCos) + 0.5;
                    }
                    #endif
                }
                o.screenPos = ComputeScreenPosCustom(o.vertex);
                #if defined(SOFT_PARTICLES)
                o.screenPos.z = -mul(UNITY_MATRIX_V, float4(o.worldPos, 1.0)).z;
                #endif

                #if defined(TEXTURE_FLIPBOOK)
                // CustomParticles uses packed RGBA frames inside each atlas cell. The
                // frame fraction blends adjacent channels; it does not select a whole
                // atlas image as a conventional flipbook does.
                float flipbookTime = time.y * _FlipbookSpeed;
                float flipbookTotal = max(_FlipbookColumns * _FlipbookRows, 1.0);
                float flipbookFrame = flipbookTime;
                if (_FlipbookNonloopableFrames > 0.0)
                    flipbookFrame = min(flipbookFrame, _FlipbookNonloopableFrames - 1.0);
                else
                    flipbookFrame = fmod(flipbookFrame, flipbookTotal);

                float flipbookCell = floor(flipbookFrame);
                float flipbookFraction = frac(flipbookFrame);
                float flipbookColumn = fmod(flipbookCell, _FlipbookColumns);
                float flipbookRow = floor(flipbookCell / _FlipbookColumns);
                o.uv.xy = float2(
                    (o.uv.x + flipbookColumn) / _FlipbookColumns,
                    (o.uv.y + (_FlipbookRows - 1.0 - flipbookRow)) / _FlipbookRows);

                #if defined(FLIPBOOK_BLENDING_OFF)
                float flipbookChannelIndex = min(floor(flipbookFraction * 4.0), 3.0);
                o.flipbookWeights = float4(
                    flipbookChannelIndex == 0.0,
                    flipbookChannelIndex == 1.0,
                    flipbookChannelIndex == 2.0,
                    flipbookChannelIndex == 3.0);
                #else
                float3 flipbookChannel = float3(
                    flipbookFraction * 3.0 - 1.0,
                    1.0 - flipbookFraction * 3.0,
                    flipbookFraction * 3.0 - 2.0);
                o.flipbookWeights = float4(
                    max(1.0 - flipbookFraction * 3.0, 0.0),
                    max(1.0 - abs(flipbookChannel.x), 0.0),
                    max(1.0 - abs(flipbookChannel.z), 0.0),
                    max(flipbookFraction * 3.0 - 2.0, 0.0));
                #endif
                #endif

                #if defined(VERTEX_FLIPBOOK)
                // The source route uses vertex color red as the frame, green as a
                // per-particle phase offset, and advances that phase by its own speed.
                // It is independent from the texture-atlas flipbook speed above.
                float vfCount = max(_VertexFlipbookCount, 1.0001);
                float vfRange = max(vfCount - 1.0, 0.0001);
                float vfFrame = time.y * _VertexFlipbookSpeed + i.color.g * vfCount;
                float vfPhase = vfFrame / vfRange;
                vfPhase = (vfPhase >= 0.0 ? 1.0 : -1.0) * frac(abs(vfPhase));
                vfPhase *= vfRange;

                float vfFramePosition = (vfPhase + 1.0) / vfCount;
                bool vfPastEnd = vfFramePosition > 1.0;
                bool vfHalfFramePassed = 0.5 / vfCount < i.color.r;
                bool vfFrameBeforeCurrent = vfFramePosition < i.color.r;
                bool vfWrapped = (vfHalfFramePassed && vfPastEnd) || !vfPastEnd;
                bool vfCull = vfFrameBeforeCurrent || (vfWrapped && i.color.r < vfPhase / vfCount);
                if (vfCull)
                    o.vertex = UnityObjectToClipPos(float4(0, 0, 0, 1));

                #if defined(VERTEX_FLIPBOOK_FADE)
                float vfFade = saturate((i.color.r - vfPhase / vfCount) * vfCount);
                float vfSmooth = vfFade * vfFade * (3.0 - 2.0 * vfFade);
                vfFade = vfSmooth * vfSmooth;
                #endif
                #endif

                #if defined(VERTEX_COLOR)
                o.color = i.color * UNITY_ACCESS_INSTANCED_PROP(Props, _Color);
                #if defined(VERTEX_RED_IS_ALPHA)
                o.color = float4(1, 1, 1, o.color.r);
                #endif
                #if defined(VERTEX_SQUARE_ALPHA)
                o.color.a *= o.color.a;
                #if defined(_VERTEXCHANNELS_A)
                o.color.rgb = 0;
                #elif defined(_VERTEXCHANNELS_RGB)
                o.color.a = 0;
                #endif
                #endif

                #endif
                #if defined(VERTEX_FLIPBOOK) && defined(VERTEX_FLIPBOOK_FADE)
                o.color.a *= vfFade;
                #endif
                #if defined(MESH_PACKING)
                float packingCull = abs(i.packingUv.y - UNITY_ACCESS_INSTANCED_PROP(Props, _MeshPackingId)) > 0.1;
                o.vertex.xyz = packingCull ? float3(0.0, 0.0, 0.0) : o.vertex.xyz;
                #endif

                #if defined(COLOR_ARRAY)
                o.colorIndexUv.x = i.colorIndexUv.x;
                o.colorIndexUv.y = i.colorIndexUv.y + _ColorsArrayOffset;
                #endif

                #if defined(SPECTROGRAM_COLOR)
                // Apply the same scale/offset that the displacement spectrogram path uses,
                // so _UV3Scale and _UV3Offset control which frequency band range is sampled.
                o.spectrogramUv.x = i.uv3.x * _UV3Scale + _UV3Offset;
                o.spectrogramUv.y = i.uv3.y;
                #endif

                #if defined(MIPMAP_BIAS) || defined(VIEW_ALIGN_DISAPPEAR)
                o.worldNormal = normalize(mul((float3x3)unity_ObjectToWorld, i.normal));
                #endif

                /**
                float rawId = UNITY_ACCESS_INSTANCED_PROP (Props, _MeshPackingId);
                float meshPackingId = fmod (rawId, 10.0) ;
                float meshSubId = floor ((rawId + 0.001) / 10.0) ;
                #if defined (MESH_PACKING)
                float packingCull = (abs (i.packingUv.y - meshPackingId) > 0.1) ||
                (abs (i.packingUv.x - meshSubId) > 0.1) ;
                o.vertex.xyz = packingCull ? float3(0.0, 0.0, 0.0) : o.vertex.xyz;
                #endif
                **/


                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                float4 time = GetTime(UNITY_ACCESS_INSTANCED_PROP(Props, _TimeOffset)) / 2;

                #if defined(_SECONDARY_UVS_IMPORT)
                // TODO: secondary uv stuff
                float2 uv2 = i.uv.zw;
                #else
                float2 uv2 = i.uv.xy;
                #endif

                #if defined(VERTEX_COLOR)
                float4 color = i.color;
                #elif defined(COLOR_ARRAY)
                // Decode packed index: tens digit in x, units digit in y (with offset applied in vert)
                float _colorIdx = round(i.colorIndexUv.x * 10.0 + i.colorIndexUv.y);
                float4 color = _ColorsArray[_colorIdx];
                #else
                float4 color = i.color * UNITY_ACCESS_INSTANCED_PROP(Props, _Color);
                #endif
                color *= GetSpriteRendererColor();
                color.rgb *= _Intensity;

                #if !defined(TEXTURE_FLIPBOOK) && defined(TEXTURE_COLOR)
                float4 albedo = float4(1, 1, 1, color.a);
                #else
                float4 albedo = color;
                #endif
                #if defined(MAIN_TEXTURE)
                #if defined(PIXELATE)
                float2 uv = floor(i.uv.xy * _PixelateResolution) / _PixelateResolution;
                #else
                // Step 1: start from interpolated UV
                float2 uv = i.uv.xy;
                // Step 2: apply distortion to base UV first, so flipbook inherits it
                #if defined(_DISTORTION_SIMPLE)
                {
                    float2 distortScrollUv = uv * _DistortionTex_ST.xy + _DistortionTex_ST.zw
                        + time.y * _DistortionPanning.xy * _DistortionTex_ST.xy;
                    float2 distortionSample = tex2D(_DistortionTex, distortScrollUv).rg;
                    uv += (distortionSample * 2.0 - 1.0) * (_DistortionStrength * 0.1) * _DistortionAxes.xy;
                }
                #endif
                #if defined(CUSTOM_WRAPPING)
                {
                    float2 customPadding = max(_CustomPadding + 1.0, 1e-4);
                    uv = frac(uv / customPadding) * customPadding;
                }
                #endif
                #endif
                #if defined(TEXTURE_FLIPBOOK)
                {
                    // Each atlas cell contains up to four frames in RGBA. The vertex
                    // stage supplies the channel blend weights decoded from the source
                    // flipbook route.
                    float4 flipbookSample = tex2D(_MainTex, uv);
                    float flipbookValue = dot(flipbookSample, i.flipbookWeights) * _BaseLayer;
                    albedo.a *= flipbookValue;
                }
                #else
                // Non-flipbook path: sample using distorted uv
                #if defined(TEXTURE_COLOR)
                // Sample full RGBA — RGB multiplies into color, alpha drives transparency
                #if defined(MIPMAP_BIAS)
                float4 _texSample = tex2Dbias(_MainTex, float4(uv, 0, _MipmapBias)) * _BaseLayer;
                #else
                float4 _texSample = tex2D(_MainTex, uv) * _BaseLayer;
                #endif
                albedo.rgb *= _texSample.rgb;
                #if defined(_ALPHACHANNEL_RED)
                albedo.a *= _texSample.r;
                #else
                albedo.a *= _texSample.a;
                #endif
                #else
                // Non-texture-color: only alpha channel drives transparency
                #if defined(MIPMAP_BIAS)
                float4 _mipSample = tex2Dbias(_MainTex, float4(uv, 0, _MipmapBias));
                #else
                float4 _mipSample = tex2D(_MainTex, uv);
                #endif
                #if defined(_ALPHACHANNEL_RED)
                albedo.a *= _mipSample.r * _BaseLayer;
                #else
                // Keep texture alpha out of RGB. Final premultiplication applies it once.
                albedo.a *= _mipSample.a * _BaseLayer;
                #endif
                #endif
                #endif
                #endif

                #if defined(SECONDARY_COLOR)
                float4 secondaryColorTex = tex2D(_SecondaryColorTex,
                                                 TRANSFORM_TEX(i.uv, _SecondaryColorTex) + _SecondaryColorPanning * time
                                                 .yy);
                float3 blendedColor = lerp(
                    UNITY_ACCESS_INSTANCED_PROP(Props, _Color).rgb,
                    UNITY_ACCESS_INSTANCED_PROP(Props, _SecondaryColor).rgb,
                    saturate(secondaryColorTex.r));
                albedo.rgb *= blendedColor;
                #endif

                #if defined(COLOR_GRADIENT)
                float2 gradientUv = float2(
                    saturate(albedo.a),
                    frac(_GradientPosition + time.y * _GradientPanningSpeed));
                float4 gradient = tex2D(_ColorGradient, TRANSFORM_TEX(gradientUv, _ColorGradient));
                albedo.rgb *= gradient.rgb;
                #endif

                #if defined(MASK)
                #if defined(SECONDARY_UVS_MASK)
                float2 maskUv = uv2.xy;
                #else
                float2 maskUv = i.uv.xy;
                #endif
                float2 maskSampleUv = TRANSFORM_TEX(maskUv, _MaskTex) + _MaskPanning * time.yy;
                #if defined(DISTORTION_TARGET_MASK)
                float2 maskDistortionUv = TRANSFORM_TEX(maskUv, _DistortionTex)
                    + _DistortionPanning.xy * time.y;
                float2 maskDistortion = tex2D(_DistortionTex, maskDistortionUv).rg;
                maskSampleUv += (maskDistortion * 2.0 - 1.0) *
                    (_DistortionStrength * 0.1) * _DistortionAxes.xy;
                #endif
                float4 _maskSample = tex2D(_MaskTex, maskSampleUv);
                float maskStrength = UNITY_ACCESS_INSTANCED_PROP(Props, _MaskStrength);
                #if defined(MASK_RED_IS_ALPHA)
                float maskValue = _maskSample.r;
                #else
                float maskValue = _maskSample.a;
                #endif
                #if defined(_MASKBLEND_ADD)
                albedo.a = saturate(albedo.a + maskValue * maskStrength);
                #elif defined(_MASKBLEND_MASKED_ADD)
                albedo.a *= 1.0 + maskValue * maskStrength;
                #else
                albedo.a *= lerp(1.0, maskValue, maskStrength);
                #endif
                #endif

                #if defined(MASK2)
                #if defined(SECONDARY_UVS_MASK2)
                float2 mask2Uv = uv2.xy;
                #else
                float2 mask2Uv = i.uv.xy;
                #endif
                float4 _mask2Sample = tex2D(_Mask2Tex, TRANSFORM_TEX(mask2Uv, _Mask2Tex) + _Mask2Panning * time.yy);
                float mask2Strength = UNITY_ACCESS_INSTANCED_PROP(Props, _Mask2Strength);
                #if defined(MASK2_RED_IS_ALPHA)
                float mask2Value = _mask2Sample.r;
                #else
                float mask2Value = _mask2Sample.a;
                #endif
                #if defined(_MASK2BLEND_ADD)
                albedo.a = saturate(albedo.a + mask2Value * mask2Strength);
                #elif defined(_MASK2BLEND_MASKED_ADD)
                albedo.a *= 1.0 + mask2Value * mask2Strength;
                #else
                albedo.a *= lerp(1.0, mask2Value, mask2Strength);
                #endif
                #endif

                // Dissolve (game: DISSOLVE + _DISSOLVE_SPACE_WORLD[_CENTERED] +
                // DISSOLVE_PROGRESS_FROM_VERTEX_ALPHA). Axis distance gates the whole
                // alpha chain; the strength multiplies alongside (fragment 482eee84d4f6d9db).
                #if defined(DISSOLVE)
                {
                    float3 axis = normalize(_DissolveAxisVector.xyz);
                    float3 dissolvePosition = i.localPos;
                    #if defined(_DISSOLVE_SPACE_WORLD) || defined(_DISSOLVE_SPACE_WORLD_CENTERED)
                     dissolvePosition = i.worldPos;
                     #endif
                     #if defined(_DISSOLVE_SPACE_WORLD_CENTERED)
                     // The source centered route subtracts the object's world translation
                     // (cb1[3]), not the camera position.
                     dissolvePosition -= unity_ObjectToWorld._m03_m13_m23;
                     #endif
                     float d = dot(dissolvePosition, axis) - _DissolveOffset;
                    d *= (_DissolveReverse > 0.5) ? -1.0 : 1.0;
                    float t = saturate(d * _DissolveScale + 0.5);
                    albedo.a *= t * _DissolveStrength;
                }
                #endif
                #if defined(DISSOLVE_PROGRESS_FROM_VERTEX_ALPHA)
                {
                    // Per-vertex progress: the mesh bakes the dissolve position into
                    // vertex alpha, making particles dissolve individually.
                    albedo.a *= saturate(i.vertexAlpha);
                }
                #endif

                // Lifetime / soft particles / close-to-camera: alpha-chain gates decoded
                // from LIFETIME (e7fc61bdf833e455), SOFT_PARTICLES (ebdcf1970fae8aeb)
                // and CLOSE_TO_CAMERA_DISAPPEAR (db0bff392a1dacb8) fragments.
                #if defined(LIFETIME)
                albedo.a *= saturate(_Lifetime);
                #endif

                #if defined(SOFT_PARTICLES)
                {
                    // Match the source depth-texture route. `screenPos.z` is converted to
                    // eye depth in the vertex stage, so it can be compared with the
                    // linearized scene depth from Unity's camera depth texture.
                    float sceneDepth = LinearEyeDepth(
                        SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.screenPos)));
                    float softFade = saturate((sceneDepth - i.screenPos.z) * _SoftFactor);
                    albedo.a *= softFade;
                }
                #endif

                #if defined(CLOSE_TO_CAMERA_DISAPPEAR)
                {
                    float dist = length(GetParticlesCameraPosition() - i.worldPos);
                    float s = saturate((dist - _CloseCameraDisappearDistance)
                                       / max(_CloseCameraDisappearWidth, 1e-4));
                    float fade = s * s * (3.0 - 2.0 * s);
                    albedo.a *= lerp(1.0, fade, _CloseCameraDisappearStrength);
                }
                #endif

                #if defined(MIPMAP_BIAS)
                {
                    // View-angle fade: grazing billboards fade out, bias already applied
                    // to the main texture sample above.
                    float3 viewDir = normalize(GetParticlesCameraPosition() - i.worldPos);
                    float vd = abs(dot(viewDir, normalize(i.worldNormal)));
                    albedo.a *= saturate(vd * _MipmapFade + (1.0 - _MipmapFade));
                }
                #endif

                #if defined(VIEW_ALIGN_DISAPPEAR)
                {
                    float3 cameraToParticle = normalize(i.worldPos - GetParticlesCameraPosition());
                    float alignment = abs(dot(cameraToParticle, normalize(i.worldNormal)));
                    if (_SquareAngleForViewAlignDisappear > 0.5)
                        alignment *= alignment;
                    float viewAlign = alignment * _ViewAlignFactor + _ViewAlignOffset;
                    if (_ViewAlignFactor < 0.0) viewAlign += 1.0;
                    albedo.a *= saturate(viewAlign);
                }
                #endif

                albedo.a *= _AlphaMultiplier;

                #if defined(SQUARE_ALPHA)
                // The source square route is saturate(alpha) * alpha, not alpha squared.
                albedo.a *= saturate(albedo.a);
                #endif

                #if defined(SPECTROGRAM_COLOR)
                {
                    float binIndex = i.spectrogramUv.x * AUDIOLINK_ETOTALBINS;
                    float4 audioData = AudioLinkLerpMultiline(ALPASS_DFT + uint2(binIndex, 0));
                    float binValue = audioData.b; // blue channel = amplitude

                    // smoothstep remap: how far up the bar is this fragment?
                    float rangeDivisor = 1.0 / max(binValue - _SpectrogramRange * binValue, 0.0001);
                    float t = saturate(rangeDivisor * (i.spectrogramUv.y - _SpectrogramRange * binValue));
                    float sm = t * t * (3.0 - 2.0 * t);
                    float brightness = sm * binValue * 1.5;
                    brightness = max(brightness, _SpectrogramBaseValue);
                    // Fragments above the bar peak are hidden via alpha only, not by zeroing RGB.
                    // Previously `albedo *= mask * brightness` killed both RGB and alpha when mask=0,
                    // making the color vanish even though alpha-blending would have discarded it anyway.
                    // Matches CustomParticles where brightness scaled vertex color intensity and the
                    // bar mask only gated the final alpha output.
                    float barMask = (float)(binValue >= i.spectrogramUv.y);
                    albedo.rgb *= brightness;
                    albedo.a *= barMask * brightness;
                }
                #endif

                #if defined(_CUTOUTTYPE_ALPHA_CLIP)
                if (albedo.a < _Cutout) discard;
                #endif

                // Consolidated CustomParticles white boost: the shared Lit composition
                // (premultiply + white-boost term) over the alpha chain. The remap
                // folds into the boost input only (DXBC 04ac3ff0), the white-boost
                // multiplier slot feeds both type routes (DXBC 137.w), and only the
                // Mixed route scales the output alpha (DXBC 138.x slot; the Deferred
                // route matches it only when POST_BLOOM is on, DXBC e025580b).
                #if defined(NOISE_DITHERING)
                {
                    // Screen-space dither noise added to color before premultiply
                    // (game: noise.r - 0.5 * 1/255, added pre-bloom).
                    float2 noiseUv = i.screenPos.xy / i.screenPos.w;
                    albedo.rgb += (tex2D(_GlobalBlueNoiseTex, noiseUv).r - 0.5) * (1.0 / 255.0);
                }
                #endif

                #if defined(HOLOGRAM)
                {
                    // Transliteration of the 1.44.3 HOLOGRAM fragment: travelling scan
                    // band + sine grid + moving wave, added to the color pre-premultiply.
                    float hTime = time.y * 3.0;
                    float3 wp = i.worldPos - GetParticlesCameraPosition();
                    float bandIn = min(frac((hTime + wp.x) * 0.2) * 2.0, 1.0);
                    float bandS = min(bandIn * 20.0, 1.0);
                    float band = bandS * (3.0 - 2.0 * bandS) * (1.0 - bandS);
                    float grid =
                        sin(frac(wp.x * 3.0 - hTime * 0.3) * 3.14159)
                        * sin(frac(wp.y * 3.0 - hTime) * 3.14159)
                        * sin(frac(wp.z * 3.0 + hTime * 0.7) * 3.14159);
                    float wave = cos(hTime * 2.0 + wp.y + wp.z) * 0.4 + 0.8;
                    albedo.rgb += band * (band + grid * wave) * _HologramColor.rgb;
                }
                #endif

                #if FOG && !defined(BLOOM_FOG) && defined(HEIGHT_FOG)
                {
                    // Source retained non-bloom fog routes use height fog only. Distance fog
                    // is supplied by the separate BLOOM_FOG path and is not present in these variants.
                    float fogClearFactor = CalculateParticleHeightFogClearFactor(i.worldPos);
                    float fogAlphaFactor = 1.0 - fogClearFactor;
                    #if defined(_FOGTYPE_LERP)
                    // LERP preserves source alpha and blends unpremultiplied RGB toward 0.1.
                    albedo = ApplyHeightFog(albedo, i.worldPos, _FogHeightScale, _FogHeightOffset);
                    #elif defined(_FOGTYPE_COLOR)
                    // The retained COLOR route uses the source 0.1 fog color and gates alpha.
                    albedo.rgb *= 0.1;
                    albedo.a *= fogAlphaFactor;
                    #elif defined(_FOGTYPE_ALPHA)
                    // ALPHA changes alpha only; final premultiplication scales RGB once.
                    albedo.a *= fogAlphaFactor;
                    #endif
                }
                #endif

                float bloomValue = albedo.a;
                float boostInput = bloomValue;
                float whiteboostMultiplier = _QuestWhiteboostMultiplier;
                #if defined(REMAP_WHITEBOOST_START)
                boostInput = (bloomValue * _QuestWhiteboostMultiplier - _WhiteBoostRemapStart)
                    / max(1.0 - _WhiteBoostRemapStart, 1e-4);
                boostInput = max(boostInput, 0.0);
                whiteboostMultiplier = 1.0;
                #endif
                #if defined(_BLOOMTYPE_MIXED) || (defined(_BLOOMTYPE_DEFERRED) && !defined(POST_BLOOM))
                albedo.rgb = CalculateBloomComposition(albedo.rgb, bloomValue, boostInput, whiteboostMultiplier,
                                                       _BaseColorBoost, _BaseColorBoostThreshold);
                #if defined(_BLOOMTYPE_MIXED)
                albedo.a = bloomValue * _BloomMultiplier;
                #else
                albedo.a = bloomValue;
                #endif
                #elif defined(_BLOOMTYPE_DEFERRED)
                // POST_BLOOM on: the post-process bloom provides the glow, so the
                // Deferred route compiles the boost out (game: MAIN_EFFECT_ENABLED on,
                // DXBC e025580b). Plain premultiplied composition, alpha scaled
                // like the Mixed route.
                albedo = CalculateBloomPostComposition(albedo.rgb, bloomValue, _BloomMultiplier);
                #else
                albedo.rgb *= abs(albedo.a);
                #endif

                #if defined(FAKE_MIRROR_TRANSPARENCY)
                {
                    // Fake mirror transparency: premultiplied output becomes a dark glass
                    // quad. The game squares the main transparency slot into alpha and RGB.
                    float total = _FakeMirrorTransparency * _FakeMirrorTransparency;
                    albedo.rgb *= total;
                    albedo.a = total;
                }
                #endif

                #if defined(FILL_ALPHA)
                // Force a constant final alpha (used by the game with a small fill value
                // so fully transparent particles still receive depth/overdraw passes).
                albedo.a = _FillAlpha;
                #endif

                #if defined(_OVERRIDE_FINAL_ALPHA_COLOR_BASED)
                {
                    // Final alpha derived from color brightness: dark pixels stay opaque.
                    float maxComp = max(max(albedo.r, albedo.g), albedo.b);
                    albedo.a = _OverrideFinalAlpha * (1.0 - maxComp);
                }
                #endif

                #if defined(BLOOM_FOG) && FOG
                {
                #if defined(HEIGHT_FOG)
                    albedo = ApplyBloomHeightFog(
                        albedo, i.screenPos, i.worldPos, _FogStartOffset, _FogScale,
                        _FogHeightOffset, _FogHeightScale);
                #else
                    albedo = ApplyBloomFog(albedo, i.screenPos, i.worldPos, _FogStartOffset, _FogScale);
                #endif
                }
                #endif

                return albedo;
            }
            ENDHLSL
        }
    }
}
