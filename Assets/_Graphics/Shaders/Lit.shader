// Replacement for the Beat Saber game shader Custom/SimpleLit.
Shader "ChroMapper/Lit"
{
    Properties
    {
        _Color ("Color", Color) = (1, 1, 1, 1)

        [KeywordEnum(None, Import, External Scale, Object Space, Additive Offset)] _Secondary_UVs ("Secondary UVs", float) = 0
        [ShowIfAny(_SECONDARY_UVS_EXTERNAL_SCALE, _SECONDARY_UVS_OBJECT_SPACE)] _UVScale ("UV Scale", Vector) = (1,1,1,1)
        [ShowIfAny(_SECONDARY_UVS_ADDITIVE_OFFSET)] _AdditiveUVOffset ("UV Offset", Vector) = (0,0,0,0)
        [VectorShowIfAny(2)] _InputUvMultiplier ("UV Multiplier", Vector) = (1,1,0,0)



        [Header(Texture)] [Space]
        [Toggle(METAL_SMOOTHNESS_TEXTURE)] _EnableMetalSmoothnessTex ("Multi Purpose Map", float) = 0
        [ShowIfAny(METAL_SMOOTHNESS_TEXTURE)] _MetalSmoothnessTex ("MPM Texture", 2D) = "white" {}
        [KeywordEnum(None, MPM R, MPM A)] _Metallic_Texture_Source ("Metallic Source", float) = 0
        _Metallic ("Metallic", Range(0, 1)) = 1
        [KeywordEnum(None, MPM A, MPM G Roughness)] _Smoothness_Texture_Source ("Smoothness Source", float) = 0
        _Smoothness ("Smoothness", Range(0, 1)) = 0.5
        [Space(12)] [Toggle(SPECULAR_ANTIFLICKER)] _SpecularAntiflicker ("Smoothness Anti-Flicker", Float) = 0
        [ShowIfAny(SPECULAR_ANTIFLICKER)] _AntiflickerStrength ("Antiflicker Strength", Range(0, 1)) = 0.7
        [ShowIfAny(SPECULAR_ANTIFLICKER)] _AntiflickerDistanceScale ("Antiflicker Distance Scale", Float) = 0.1
        [ShowIfAny(SPECULAR_ANTIFLICKER)] _AntiflickerDistanceOffset ("Antiflicker Distance Offset", Float) = 21
        [Toggle(PRECISE_NORMAL)] _PreciseNormal ("Precise Normal", float) = 0



        [Header(Vertex)] [Space]
        [EnumShowIfAny(7, None, Color, Emission, MetalSmoothness, Special, Displacement, Emissive Mult Add)] _VertexMode ("Vertex Color Mode", float) = 0
        [ShowIfAny(_VERTEXMODE_EMISSION, _VERTEXMODE_SPECIAL, _VERTEXMODE_EMISSIVE_MULT_ADD)] _EmissionThreshold ("Emission Threshold", Range(0, 1)) = 0
        [ShowIfAny(_VERTEXMODE_EMISSION, _VERTEXMODE_SPECIAL, _VERTEXMODE_EMISSIVE_MULT_ADD)] _EmissionColor ("Emission Color", Color) = (1,1,1,0)
        [ShowIfAny(_VERTEXMODE_EMISSION, _VERTEXMODE_SPECIAL, _VERTEXMODE_EMISSIVE_MULT_ADD)] _EmissionStrength ("Emission Strength", float) = 1
        [ShowIfAny(_VERTEXMODE_EMISSION, _VERTEXMODE_SPECIAL, _VERTEXMODE_EMISSIVE_MULT_ADD)] _EmissionBloomIntensity ("Emission Bloom Intensity", float) = 1
        [ShowIfAny(_VERTEXMODE_EMISSION, _VERTEXMODE_SPECIAL, _VERTEXMODE_EMISSIVE_MULT_ADD)] _QuestWhiteboostMultiplier ("Whiteboost Multiplier", float) = 1
        [EnumShowIfAny(3, None, MainEffect, Always, _VERTEXMODE_EMISSION, _VERTEXMODE_SPECIAL, _VERTEXMODE_EMISSIVE_MULT_ADD)] _Vertex_WhiteBoostType ("Color Treatment", float) = 0
        [Space]
        [ToggleShowIfAny(DISPLACEMENT_SPATIAL, _VERTEXMODE_DISPLACEMENT)] _DisplacementSpatial ("RGB Direction", float) = 0
        [ToggleShowIfAny(DISPLACEMENT_BIDIRECTIONAL, 2, DISPLACEMENT_SPATIAL, _VERTEXMODE_DISPLACEMENT)] _DisplacementBidirectional ("RGB Bidirectional", float) = 0
        [EnumShowIfAny(3, None, Flat, Full, _VERTEXMODE_DISPLACEMENT)] _Spectrogram ("Spectrogram", float) = 0
        [ShowIfAny(_VERTEXMODE_DISPLACEMENT)] _DisplacementStrength ("Displacement Strength", float) = 0.1
        [ShowIfAny(_VERTEXMODE_DISPLACEMENT)] _DisplacementAxisMultiplier ("Axis Multiplier", Vector) = (1,1,1,1)
        [Space]
        [Toggle(VERTEXDISPLACEMENT_MASK)] _EnableVertexDisplacementMask ("Vertex Displacement Mask", float) = 0
        [EnumShowIfAny(2, Texture, 3D Texture, VERTEXDISPLACEMENT_MASK)] _VertexDisplacement_Mask_Source ("Mask Source", float) = 0
        [ShowIfAny(VERTEXDISPLACEMENT_MASK)] _VertexDisplacementMask ("Mask Texture", 2D) = "white" {}
        [ShowIfAny(VERTEXDISPLACEMENT_MASK)] _VertexDisplacementMaskSpeed ("Mask Texture Speed", Vector) = (0, 1, 0, 0)
        _VertexDisplacementMaskMode ("Mask Mode", Float) = 0
        [ShowIfAny(VERTEXDISPLACEMENT_MASK)] _VertexDisplacementMaskMultiplier ("Mask Multiplier", float) = 1
        [ShowIfAny(VERTEXDISPLACEMENT_MASK)] _VertexDisplacementMaskOffset ("Mask Offset", float) = 0
        [ShowIfAny(VERTEXDISPLACEMENT_MASK)] _VertexDisplacement3DTexture ("Noise Tex", 3D) = "white" {}
        [ShowIfAny(VERTEXDISPLACEMENT_MASK)] _VertexDisplacement3DTexOffset ("Texture Offset", Vector) = (0, 0, 0, 0)
        [ShowIfAny(VERTEXDISPLACEMENT_MASK)] _VertexDisplacement3DTexPanning ("Texture Panning", Vector) = (0, 0, 0, 0)
        [ShowIfAny(VERTEXDISPLACEMENT_MASK)] _VertexDisplacement3DTexScale ("Texture Scale", float) = 5



        [Header(Emission)] [Space]
        [KeywordEnum(None, Simple, Pulse, Flipbook)] _EmissionTexture ("Emission Texture", float) = 0
        [EnumShowIfAny(4, Texture, Fill, MPM G, SDF, _EMISSIONTEXTURE_SIMPLE, _EMISSIONTEXTURE_FLIPBOOK, _EMISSION_TEXTURE_SOURCE_SDF)] _Emission_Texture_Source ("Source", float) = 0
        [ShowIfAny(1, _EMISSION_TEXTURE_SOURCE_TEXTURE, _EMISSIONTEXTURE_SIMPLE, _EMISSIONTEXTURE_FLIPBOOK)] _EmissionTex ("Texture", 2D) = "white" {}
        [VectorShowIfAny(2, 2, _EMISSIONTEXTURE_SIMPLE, _EMISSION_TEXTURE_SOURCE_TEXTURE)] _EmissionTexSpeed ("Texture Speed", Vector) = (0,0,0,0)
        [ToggleShowIfAny(SECONDARY_UVS_EMISSION, 2, 0_SECONDARY_UVS_NONE, _EMISSION_TEXTURE_SOURCE_TEXTURE, _EMISSIONTEXTURE_SIMPLE)] _SecondaryUVsEmissionTex ("Use Secondary UVs", float) = 0
        [EnumShowIfAny(3, Emission G, Copy Emission, MPM R, _EMISSIONTEXTURE_SIMPLE)] _Emission_Alpha_Source ("Alpha Source", float) = 0
        _EmissionBrightness ("Brightness", float) = 1
        [ToggleShowIfAny(ENABLE_EMISSION_ANGLE_DISAPPEAR, _EMISSIONTEXTURE_SIMPLE, _EMISSIONTEXTURE_PULSE, _EMISSIONTEXTURE_FLIPBOOK)] _EnableEmissionAngleDisappear ("Angle Disappear", float) = 0
        [ShowIfAny(1, ENABLE_EMISSION_ANGLE_DISAPPEAR, _EMISSIONTEXTURE_SIMPLE, _EMISSIONTEXTURE_PULSE, _EMISSIONTEXTURE_FLIPBOOK)] _EmissionThresholdAngle ("Threshold Angle", float) = 0
        [EnumShowIfAny(4, Flat, Whiteboost, Gradient, MainEffect, _EMISSIONTEXTURE_SIMPLE, _EMISSIONTEXTURE_PULSE, _EMISSIONTEXTURE_FLIPBOOK)] _EmissionColorType ("Color Treatment", float) = 0
        [ShowIfAny(1, 0_EMISSIONCOLORTYPE_GRADIENT, _EMISSIONTEXTURE_SIMPLE, _EMISSIONTEXTURE_PULSE, _EMISSIONTEXTURE_FLIPBOOK)] _EmissionTexColor ("Color", Color) = (1,1,1,1)
        [Space]
        [ShowIfAny(1, _EMISSIONCOLORTYPE_GRADIENT, _EMISSIONTEXTURE_SIMPLE, _EMISSIONTEXTURE_PULSE, _EMISSIONTEXTURE_FLIPBOOK)] _EmissionGradientTex ("Gradient LUT", 2D) = "white" {}
        [ShowIfAny(_EMISSIONCOLORTYPE_GRADIENT)] _EmissionGradientPosition ("LUT Position", float) = 0.5
        [ShowIfAny(_EMISSIONCOLORTYPE_GRADIENT)] _EmissionGradientPanningSpeed ("LUT Panning", float) = 0
        [ShowIfAny(_EMISSIONCOLORTYPE_GRADIENT)] _EmissionGradientIntensity ("LUT Intensity", float) = 1
        [Space]
        [ShowIfAny(_EMISSIONTEXTURE_PULSE)] _PulseMask ("Pulse Mask", 2D) = "white" {}
        [ToggleShowIfAny(SECONDARY_UVS_PULSE, 2, 0_SECONDARY_UVS_NONE, _EMISSIONTEXTURE_PULSE)] _SecondaryUVsPulseTex ("Use Secondary UVs", Float) = 0
        [ToggleShowIfAny(INVERT_PULSE, _EMISSIONTEXTURE_PULSE)] _InvertPulseTexture ("Invert Pulse Texture", Float) = 0
        [ToggleShowIfAny(PULSE_MULTIPLY_TEXTURE, _EMISSIONTEXTURE_PULSE)] _PulseMultiplyByTexture ("Multiply by Pulse Texture", Float) = 0
        [ShowIfAny(_EMISSIONTEXTURE_PULSE)] _PulseWidth ("Pulse Width", Float) = 0.1
        [ShowIfAny(_EMISSIONTEXTURE_PULSE)] _PulseSpeed ("Pulse Speed", Float) = 0.2
        [ShowIfAny(_EMISSIONTEXTURE_PULSE)] _PulseSmooth ("Pulse Smoothness", Range(0, 0.2)) = 0.02
        [Space]
        [ShowIfAny(_EMISSIONTEXTURE_FLIPBOOK)] _FlipbookColumns ("Flipbook Columns", float) = 8
        [ShowIfAny(_EMISSIONTEXTURE_FLIPBOOK)] _FlipbookRows ("Flipbook Rows", float) = 8
        [ShowIfAny(_EMISSIONTEXTURE_FLIPBOOK)] _FlipbookNonloopableFrames ("Full Non-loopable frames", float) = 0
        [ShowIfAny(_EMISSIONTEXTURE_FLIPBOOK)] _FlipbookSpeed ("Flipbook Speed", float) = 1
        [ToggleShowIfAny(FLIPBOOK_BLENDING_OFF, _EMISSIONTEXTURE_FLIPBOOK)] _FlipbookBlendingOff ("No Frame Blending", float) = 0
        [HideInInspector] _StartTime ("Flipbook Start Time", float) = 0
        [Space]
        [ToggleShowIfAny(EMISSION_MASK, _EMISSIONTEXTURE_SIMPLE, _EMISSIONTEXTURE_PULSE)] _EnableEmissionMask ("Emission Mask", float) = 0
        [EnumShowIfAny(3, Multiply, Add, Masked Add, EMISSION_MASK)] _MaskBlend ("Blend", float) = 0
        [ShowIfAny(1, EMISSION_MASK, _EMISSIONTEXTURE_PULSE, _EMISSIONTEXTURE_SIMPLE)] _EmissionMask ("Texture", 2D) = "white" {}
        [ToggleShowIfAny(SECONDARY_UVS_EMISSION_MASK, 2, 0_SECONDARY_UVS_NONE, EMISSION_MASK)] _SecondaryUVsMask ("Use Secondary UVs", float) = 0
        [VectorShowIfAny(2, 1, EMISSION_MASK, _EMISSIONTEXTURE_PULSE, _EMISSIONTEXTURE_SIMPLE)] _EmissionMaskSpeed ("Texture Speed", Vector) = (0,1,0,0)
        [ShowIfAny(1, EMISSION_MASK, _EMISSIONTEXTURE_PULSE, _EMISSIONTEXTURE_SIMPLE)] _EmissionMaskIntensity ("Intensity", float) = 1
        [Space]
        [ToggleShowIfAny(SECONDARY_EMISSION_MASK, _EMISSIONTEXTURE_SIMPLE, _EMISSIONTEXTURE_PULSE)] _EnableSecondaryEmissionMask ("Secondary Emission Mask", float) = 0
        [EnumShowIfAny(3, Multiply, Add, Masked Add, SECONDARY_EMISSION_MASK)] _Secondary_Mask_Blend ("Blend", float) = 0
        [ShowIfAny(1, SECONDARY_EMISSION_MASK, _EMISSIONTEXTURE_PULSE, _EMISSIONTEXTURE_SIMPLE)] _SecondaryEmissionMask ("Texture", 2D) = "white" {}
        [ToggleShowIfAny(SECONDARY_UVS_EMISSION_MASK2, 2, 0_SECONDARY_UVS_NONE, SECONDARY_EMISSION_MASK)] _SecondaryUVsMask2 ("Use Secondary UVs", float) = 0
        [VectorShowIfAny(2, 1, SECONDARY_EMISSION_MASK, _EMISSIONTEXTURE_PULSE, _EMISSIONTEXTURE_SIMPLE)] _SecondaryEmissionMaskSpeed ("Texture Speed", Vector) = (0,1,0,0)
        [ShowIfAny(1, SECONDARY_EMISSION_MASK, _EMISSIONTEXTURE_PULSE, _EMISSIONTEXTURE_SIMPLE)] _SecondaryEmissionMaskIntensity ("Intensity", float) = 1
        [Space]
        [ShowIfAny(_EMISSIONTEXTURE_PULSE, _EMISSIONTEXTURE_SIMPLE)] _EmissionMaskStepValue ("Step Value", Range(0, 1)) = 0.5
        [ShowIfAny(_EMISSIONTEXTURE_PULSE, _EMISSIONTEXTURE_SIMPLE)] _EmissionMaskStepWidth ("Step Width", Range(0, 0.5)) = 0.1
        [Space]
        _EmissionTexBloomIntensity ("Bloom Intensity", float) = 1
        _EmissionTexWhiteBoostMultiplier ("White Boost Multiplier", float) = 1



        [Header(Parallax)] [Space]
        [KeywordEnum(None, Flexible, RGB)] _Parallax ("Parallax Emission", Float) = 0
        [ToggleShowIfAny(_PARALLAX_FLEXIBLE_REFLECTED, 0_PARALLAX_NONE)] _EnableReflectedDir ("Reflected Direction", Float) = 0
        [EnumShowIfAny(2, Planar, Warped, 0_PARALLAX_NONE)] _Parallax_Projection ("Parallax Projection", Float) = 0
        [ShowIfAny(0_PARALLAX_NONE)] _ParallaxColor ("Parallax Color", Color) = (1, 1, 1, 1)
        [ShowIfAny(0_PARALLAX_NONE)] _ParallaxMap ("Parallax Map", 2D) = "black" {}
        [ToggleShowIfAny(SECONDARY_UVS_PARALLAX, 2, 0_SECONDARY_UVS_NONE, 0_PARALLAX_NONE)] _SecondaryUVsParallax ("Parallax Texture Secondary UVs", Float) = 0
        [VectorShowIfAny(2, 0_PARALLAX_NONE)] _ParallaxTexSpeed ("Parallax Speed", Vector) = (0, 0, 0, 0)
        [ShowIfAny(0_PARALLAX_NONE)] _ParallaxIntensity ("Parallax Intensity", Float) = 1
        [ShowIfAny(0_PARALLAX_NONE)] _ParallaxIntensity_Step ("Parallax Intensity Step", Float) = -0.25
        [ShowIfAny(_PARALLAX_FLEXIBLE)] _Layers ("Layers", Range(2, 6)) = 3
        [ShowIfAny(0_PARALLAX_NONE)] _StartOffset ("Start Offset", Float) = 1
        [ShowIfAny(0_PARALLAX_NONE)] _OffsetStep ("Offset Step", Float) = 1
        [ToggleShowIfAny(PARALLAX_IRIDESCENCE, 0_PARALLAX_NONE)] _Parallax_Iridescence ("Iridescence", Float) = 0
        [ShowIfAny(2, 0_PARALLAX_NONE, PARALLAX_IRIDESCENCE)] _IridescenceAxesMultiplier ("Axes Multiplier", Vector) = (1, 2, 3, 0)
        [ShowIfAny(2, 0_PARALLAX_NONE, PARALLAX_IRIDESCENCE)] _IridescenceTiling ("Iridescence Tiling", Float) = 0.25
        [ShowIfAny(2, 0_PARALLAX_NONE, PARALLAX_IRIDESCENCE)] _IridescenceColorInfluence ("Color Influence", Range(0, 1)) = 0
        [EnumShowIfAny(3, None, Texture, Vertex Color, 0_PARALLAX_NONE)] _Parallax_Masking ("Mask by", Float) = 0
        [ShowIfAny(2, 0_PARALLAX_NONE, _PARALLAX_MASKING_TEXTURE)] _ParallaxMaskingMap ("Parallax Mask", 2D) = "white" {}
        [VectorShowIfAny(2, 2, 0_PARALLAX_NONE, _PARALLAX_MASKING_TEXTURE)] _ParallaxMaskSpeed ("Mask Speed", Vector) = (0, 0, 0, 0)
        [ShowIfAny(2, 0_PARALLAX_NONE, _PARALLAX_MASKING_TEXTURE)] _ParallaxMaskIntensity ("Mask Intensity", Range(0, 1)) = 1



        [Header(Lighting)] [Space]
        _AmbientMinimalValue ("Ambient Minimum", Range(0, 1)) = 0
        _NominalDiffuseLevel ("Ambient Color", Color) = (0, 0, 0, 0)
        _AmbientMultiplier ("Ambient Color Multiplier", float) = 1
        [Space]
        [Toggle(PRIVATE_POINT_LIGHT)] _EnablePrivatePointLight ("Private Point Light", float) = 0
        [ShowIfAny(PRIVATE_POINT_LIGHT)] _PrivatePointLightColor ("Color", Color) = (0,0.5,1,1)
        [ToggleShowIfAny(POINT_LIGHT_IS_LOCAL, PRIVATE_POINT_LIGHT)] _PointLightPositionLocal ("Make Position Local", float) = 0
        [ShowIfAny(PRIVATE_POINT_LIGHT)] _PrivatePointLightIntensity ("Intensity Multiplier", float) = 1
        [ShowIfAny(PRIVATE_POINT_LIGHT)] _PrivatePointLightPosition ("Light World Position", Vector) = (0,0,0,1)
        [Space]
        [Toggle(DIFFUSE)] _EnableDiffuse ("Diffuse", float) = 1
        [ToggleShowIfAny(BOTH_SIDES_DIFFUSE, DIFFUSE)] _EnableBothSidesDiffuse ("Both Sides Diffuse", float) = 0
        [ShowIfAny(2, BOTH_SIDES_DIFFUSE, DIFFUSE)] _BothSidesDiffuseMultiplier ("Other Diffuse Multiplier", float) = 1
        [ToggleShowIfAny(LIGHT_FALLOFF, DIFFUSE, SPECULAR)] _EnableLightFalloff ("Light Falloff", float) = 0
        [Space]
        [Toggle(DIFFUSE_TEXTURE)] _EnableDiffuseTexture ("Albedo Texture", float) = 0
        [EnumShowIfAny(3, Texture, MPM R, MPM A Smoothness, DIFFUSE_TEXTURE)] _Diffuse_Texture_Source ("Diffuse Texture Source", float) = 0
        [ShowIfAny(2, DIFFUSE_TEXTURE, _DIFFUSE_TEXTURE_SOURCE_TEXTURE)] _DiffuseTex ("Diffuse Texture", 2D) = "white" {}
        [ShowIfAny(2, DIFFUSE_TEXTURE, _DIFFUSE_TEXTURE_SOURCE_MPM_A_SMOOTHNESS)] _AlbedoMultiplier ("Albedo Multiplier", float) = 1
        [Space]
        [Toggle(SPECULAR)] _EnableSpecular ("Specular", float) = 1
        [ShowIfAny(SPECULAR)] _SpecularIntensity ("Intensity", float) = 1
        [Space(12)] [Toggle(NORMAL_MAP)] _EnableNormalMap ("Normal Map", Float) = 0
        [ShowIfAny(NORMAL_MAP)] _NormalTexture ("Normal Texture", 2D) = "bump" {}
        [ShowIfAny(NORMAL_MAP)] _NormalScale ("Normal Scale", Float) = 1
        [HideInInspector] _SphericalNormalOffsetCenter ("Spherical Normal Offset Center", Vector) = (0,0,0,0)
        [HideInInspector] _SphericalNormalOffsetIntensity ("Spherical Normal Offset Intensity", Float) = 0



        [Header(Reflection)] [Space]
        [ToggleHeader(REFLECTION_PROBE)] _EnableReflectionProbe ("Enable Reflection Probe", Float) = 0
        [ToggleHeader(_PROBE_CALCULATION_PRECISE)] _EnablePreciseProbeCalculation ("Precise Probe Calculation", Float) = 0
        [Toggle(REFLECTION_TEXTURE)] _EnableReflectionTexture ("Reflection Texture", Float) = 0
        [ShowIfAny(REFLECTION_TEXTURE)] _ReflectionTexIntensity ("Texture Intensity", Float) = 1
        [ShowIfAny(REFLECTION_TEXTURE)] _EnvironmentReflectionCube ("Environment Reflection", Cube) = "" {}
        [Toggle(MULTIPLY_REFLECTIONS)] _EnableMultiplyReflections ("Multiply Reflections", float) = 0
        [Toggle(REFLECTION_PROBE_BOX_PROJECTION)] _EnableBoxProjection ("Box Projection", float) = 0
        [ShowIfAny(2, REFLECTION_PROBE, _PROBE_CALCULATION_PRECISE)] _ReflectionProbeGrayscale ("Probe Grayscale Factor", Range(0, 1)) = 0.2
        [ShowIfAny(2, REFLECTION_PROBE, _PROBE_CALCULATION_PRECISE)] _ColoredMetalMultiplier ("Colored Metal Multiplier", Range(0, 15)) = 3.5
        [ShowIfAny(2, REFLECTION_PROBE, _PROBE_CALCULATION_PRECISE)] _WhiteOffset ("White Offset", float) = 2
        [ShowIfAny(REFLECTION_PROBE)] _ReflectionProbeIntensity ("Reflection Probe Intensity", float) = 0.4
        [ToggleShowIfAny(REFLECTION_PROBE_BOX_PROJECTION, REFLECTION_PROBE)] _ReflectionProbeBoxProjection ("Box Projection", Float) = 1
        [ToggleShowIfAny(REFLECTION_PROBE_BOX_PROJECTION_OFFSET, 2, REFLECTION_PROBE, REFLECTION_PROBE_BOX_PROJECTION)] _EnableBoxProjectionOffset ("Box Projection Offset", Float) = 0
        [ShowIfAny(3, REFLECTION_PROBE, REFLECTION_PROBE_BOX_PROJECTION, REFLECTION_PROBE_BOX_PROJECTION_OFFSET)] _ReflectionProbeBoxProjectionSizeOffset ("Box Projection Size Offset", Vector) = (0, 0, 0, 0)
        [ShowIfAny(3, REFLECTION_PROBE, REFLECTION_PROBE_BOX_PROJECTION, REFLECTION_PROBE_BOX_PROJECTION_OFFSET)] _ReflectionProbeBoxProjectionPositionOffset ("Box Projection Position Offset", Vector) = (0, 0, 0, 0)

        [Header(Rim Dim)] [Space]
        [Toggle(ENABLE_RIM_DIM)] _EnableRimDim ("Rim Dim", float) = 0
        [ToggleShowIfAny(INVERT_RIM_DIM, ENABLE_RIM_DIM)] _InvertRimDim ("Invert", float) = 0
        [ShowIfAny(ENABLE_RIM_DIM)] _RimScale ("Scale", float) = 1
        [ShowIfAny(ENABLE_RIM_DIM)] _RimOffset ("Offset", float) = 1
        [ShowIfAny(ENABLE_RIM_DIM)] _RimDistanceOffset ("Distance Offset", float) = 2
        [ShowIfAny(ENABLE_RIM_DIM)] _RimDistanceScale ("Distance Scale", float) = 0.3
        [ShowIfAny(ENABLE_RIM_DIM)] _RimSmoothness ("Smoothness", float) = 1
        [ShowIfAny(ENABLE_RIM_DIM)] _RimDarkening ("Darkening", float) = 0
        [EnumShowIfAny(3, None, Lerp, Additive)] _RimLight ("Rim Light Type", Float) = 0
        [ToggleShowIfAny(DIRECTIONAL_RIM, _RIMLIGHT_LERP, _RIMLIGHT_ADDITIVE)] _EnableDirectionalRim ("Directional Rim", Float) = 0
        [VectorShowIfAny(3, 1, DIRECTIONAL_RIM, _RIMLIGHT_LERP, _RIMLIGHT_ADDITIVE)] _RimPerpendicularAxis ("Perpendicular Axis", Vector) = (0,1,0,0)
        [ShowIfAny(_RIMLIGHT_LERP, _RIMLIGHT_ADDITIVE)] _RimLightColor ("Rim Light Color", Color) = (1,1,1,1)
        [ShowIfAny(_RIMLIGHT_LERP, _RIMLIGHT_ADDITIVE)] _RimLightEdgeStart ("Rim Light Edge Start", Float) = 0
        [ShowIfAny(_RIMLIGHT_LERP, _RIMLIGHT_ADDITIVE)] _RimLightIntensity ("Rim Light Intensity", Float) = 0
        [ShowIfAny(_RIMLIGHT_LERP, _RIMLIGHT_ADDITIVE)] _RimLightBloomIntensity ("Rim Light Bloom Intensity", Float) = 0
        [EnumShowIfAny(2, None, MainEffect, _RIMLIGHT_LERP, _RIMLIGHT_ADDITIVE)] _Rim_WhiteBoostType ("Rim Color Treatment", Float) = 0
        [ShowIfAny(_RIMLIGHT_LERP, _RIMLIGHT_ADDITIVE)] _RimLightWhiteboostMultiplier ("Rim White Boost Multiplier", Float) = 1
        [HideInInspector] _ColorFogMultiplier ("Color Fog Multiplier", Float) = 0
        [HideInInspector] _ColorFogHighlightMultiplier ("Color Fog Highlight Multiplier", Float) = 0
        [HideInInspector] _ColorFogInfluence ("Color Fog Influence", Float) = 1
        [HideInInspector] _ColorFogMax ("Color Fog Maximum", Float) = 1
        [HideInInspector] [Toggle(UV_COLOR_SEGMENTS)] _UVColorSegments ("UV Color Segments", Float) = 0
        [Toggle(HIGHLIGHT_SELECTION)] _HighlightSelection ("Highlight Selection", Float) = 0
        [ShowIfAny(HIGHLIGHT_SELECTION)] _SegmentToHighlight ("Segment To Highlight", Float) = -1

        [EnumShowIfAny(4, None, Grid, Scanline, Legacy)] _Hologram ("Hologram Effect", Float) = 0
        [ShowIfAny(_HOLOGRAM_GRID, _HOLOGRAM_SCANLINE, _HOLOGRAM_LEGACY)] _HologramColor ("Hologram Color", Color) = (1,1,1,1)
        [ShowIfAny(_HOLOGRAM_GRID, _HOLOGRAM_LEGACY)] _HologramGridSize ("Hologram Grid Size", Float) = 3
        [ShowIfAny(_HOLOGRAM_GRID)] _HologramFill ("Hologram Fill", Float) = -0.6
        [ShowIfAny(_HOLOGRAM_GRID, _HOLOGRAM_SCANLINE)] _HologramStripeSpeed ("Hologram Stripe Speed", Float) = 1.43
        [ShowIfAny(_HOLOGRAM_GRID, _HOLOGRAM_SCANLINE)] _HologramScanDistance ("Hologram Scan Distance", Float) = 2
        [ShowIfAny(_HOLOGRAM_GRID, _HOLOGRAM_SCANLINE)] _HologramPhaseOffset ("Hologram Phase Offset", Range(-1,1)) = 0
        [ShowIfAny(_HOLOGRAM_GRID, _HOLOGRAM_SCANLINE)] _HoloIntensity ("Hologram Intensity", Float) = 1
        [ShowIfAny(_HOLOGRAM_GRID, _HOLOGRAM_SCANLINE)] _HaltScan ("Halt Scanning", Float) = 0

        [Header(Occlusion)] [Space]
        [Toggle(GROUND_FADE)] _EnableGroundFade ("Height Occlusion", Float) = 0
        [ShowIfAny(GROUND_FADE)] _GroundFadeScale ("Height Occlusion Scale", Float) = 0.5
        [ShowIfAny(GROUND_FADE)] _GroundFadeOffset ("Height Occlusion Offset", Float) = 1
        [Space]
        [Toggle(OCCLUSION)] _EnableOcclusion ("Texture Occlusion", Float) = 0
        [ShowIfAny(OCCLUSION)] _OcclusionIntensity ("Occlusion Intensity", Range(0, 1)) = 1
        [HideInInspector] _DirtTex ("Source Occlusion Texture", 2D) = "white" {}
        [HideInInspector] _LightMap1 ("Source Light Map 1", 2D) = "black" {}
        [HideInInspector] _LightMap2 ("Source Light Map 2", 2D) = "black" {}
        [Toggle(OCCLUSION_DETAIL)] _EnableOcclusionDetail ("Texture Occlusion Detail", Float) = 0
        [ShowIfAny(OCCLUSION_DETAIL)] _DirtDetailTex ("Occlusion Detail Texture", 2D) = "white" {}
        [ShowIfAny(OCCLUSION_DETAIL)] _OcclusionDetailIntensity ("Occlusion Detail Intensity", Range(0, 1)) = 0.4
        [Space]
        [Toggle(DISTANCE_DARKENING)] _EnableDistanceDarkening ("Worldspace Occlusion", float) = 0
        [ShowIfAny(DISTANCE_DARKENING)] _DarkeningScale ("Scale", float) = 0.35
        [ShowIfAny(DISTANCE_DARKENING)] _DarkeningIntensity ("Intensity", float) = 1
        [VectorShowIfAny(3, DISTANCE_DARKENING)] _DarkeningCenter ("Center", Vector) = (0,0,0,0)
        [VectorShowIfAny(3, DISTANCE_DARKENING)] _DarkeningDirection ("Axes", Vector) = (1,1,1,1)

        [Header(Dissolve)] [Space]
        [Toggle(DISSOLVE)] _EnableDissolve ("Dissolve", float) = 0
        [FloatToggleShowIfAny(DISSOLVE)] _InvertDissolve ("Invert", float) = 0
        [Space]
        [ShowIfAny(DISSOLVE)] _DissolveAxisVector ("Axis Direction", Vector) = (0, 1, 0, 0)
        [ToggleShowIfAny(DISSOLVE_PROGRESS, DISSOLVE)] _UseDissolveProgress ("Dissolve Progress", Float) = 0
        [ShowIfAny(2, DISSOLVE, 0DISSOLVE_PROGRESS)] _DissolveOffset ("Dissolve Offset", Float) = 0
        [ShowIfAny(2, DISSOLVE, DISSOLVE_PROGRESS)] _DissolveStartValue ("Start Value", float) = -1
        [ShowIfAny(2, DISSOLVE, DISSOLVE_PROGRESS)] _DissolveEndValue ("End Value", float) = 1
        [ShowIfAny(2, DISSOLVE, DISSOLVE_PROGRESS)] _DissolveProgress ("Progress", Range(-1, 1)) = 0
        [Space]
        [ToggleShowIfAny(DISSOLVE_COLOR, DISSOLVE)] _UseDissolveColor ("Dissolve Color", Float) = 0
        [ShowIfAny(2, DISSOLVE, DISSOLVE_COLOR)] _DissolveColor ("Edge Color", Color) = (1, 0.5, 0, 1)
        [ShowIfAny(2, DISSOLVE, DISSOLVE_COLOR)] _DissolveColorIntensity ("Edge Color Intensity", float) = 3
        [ShowIfAny(2, DISSOLVE, DISSOLVE_COLOR)] _CutColorFalloff ("Edge Falloff", float) = 5
        [ShowIfAny(2, DISSOLVE, DISSOLVE_COLOR)] _CutColorBacksideFalloff ("Backside Falloff", float) = 0.5
        [ToggleShowIfAny(DISSOLVE_TEXTURE, DISSOLVE)] _UseDissolveTexture ("Dissolve Texture", Float) = 0
        [ShowIfAny(2, DISSOLVE, DISSOLVE_TEXTURE)] _DissolveTexture ("Dissolve Texture", 2D) = "black" {}
        [VectorShowIfAny(2, 2, DISSOLVE, DISSOLVE_TEXTURE)] _DissolveTextureSpeed ("Texture Speed", Vector) = (0,0,0,0)
        [ShowIfAny(2, DISSOLVE, DISSOLVE_TEXTURE)] _DissolveTextureInfluence ("Texture Influence", Float) = 0.2

        [Header(Distortion)] [Space]
        [Toggle(DISTORTION_SIMPLE)] _EnableDistortion ("Distortion", float) = 0
        [ShowIfAny(DISTORTION_SIMPLE)] _DistortionTex ("Distortion Texture", 2D) = "white" {}
        [ShowIfAny(DISTORTION_SIMPLE)] _DistortionStrength ("Strength", float) = 0.1
        [ShowIfAny(DISTORTION_SIMPLE)] _DistortionPanning ("Panning", Vector) = (1, 1, 0, 0)
        [ShowIfAny(DISTORTION_SIMPLE)] _DistortionAxes ("Axes", Vector) = (1, 1, 0, 0)

        [Header(SDF)] [Space]
        _SDFNoiseOffset ("Noise offset", Vector) = (0, 0, 0, 0)
        _SDFNoisePanning ("Noise panning", Vector) = (0, 0, 0, 0)
        _SDFNoiseIntensity ("Noise Intensity", Float) = 1
        _SDFNoiseScale ("Noise Scale", Float) = 5
        _SDFPointIntensity ("Color Intensity", Float) = 1
        _SDFNegativeIntensity ("Negative Intensity", Float) = 0.5
        _SDFNoiseTex ("Noise Tex", 3D) = "white" {}

        [HideInInspector] _LookupTex ("Source 3D Lookup Texture", 3D) = "gray" {}
        [HideInInspector] _LookupGridSize ("3D Lookup Grid Size", Vector) = (1,1,1,1)
        [HideInInspector] _LookupGridElementIndex ("3D Lookup Grid Element", Vector) = (0,0,0,0)
        [HideInInspector] _LookupGridObjectSpacePivot ("3D Lookup Object Pivot", Vector) = (0,0,0,0)
        [HideInInspector] _LookupXDisplacementMapping ("3D Lookup X Mapping", Vector) = (0,0,0,0)
        [HideInInspector] _LookupYDisplacementMapping ("3D Lookup Y Mapping", Vector) = (0,0,0,0)
        [HideInInspector] _LookupZDisplacementMapping ("3D Lookup Z Mapping", Vector) = (0,0,0,0)
        [HideInInspector] _LookupRadialDisplacementMapping ("3D Lookup Radial Mapping", Vector) = (0,0,0,0)
        [HideInInspector] _LookupScaleMapping ("3D Lookup Scale Mapping", Vector) = (0,0,0,0)
        [HideInInspector] _LookupRotationMapping ("3D Lookup Rotation Mapping", Vector) = (0,0,0,0)
        [HideInInspector] _LookupEmissiveMapping ("3D Lookup Emissive Mapping", Vector) = (0,0,0,0)
        [HideInInspector] _LookupXYZDisplacementScale ("3D Lookup XYZ Scale", Float) = 0
        [HideInInspector] _LookupRadialDisplacementScale ("3D Lookup Radial Scale", Float) = 1
        [HideInInspector] _LookupMaxScale ("3D Lookup Maximum Scale", Float) = 1
        [HideInInspector] _LookupRotationMultiplier ("3D Lookup Rotation Multiplier", Float) = 0
        [HideInInspector] _LookupEmissiveModulationStrength ("3D Lookup Emission Strength", Float) = 1



        [Header(Others)] [Space]
        [KeywordEnum(Standard, Song Time, Freeze)] _Custom_Time ("Time Behavior", float) = 0
        [KeywordEnum(After Emissive, Before Emissive)] _ACES_Approach ("ACES Approach", float) = 0
        [Toggle(MESH_PACKING)] _MeshPacking ("Mesh Packed Instancing", Float) = 0
        [ShowIfAny(MESH_PACKING)] _MeshPackingId ("Mesh Packing ID", float) = 0
        [Toggle(COLOR_ARRAY)] _UseColorArray ("Color Array", float) = 0


        [Header(Fog Settings)] [Space]
        [Toggle(FOG)] _EnableFog ("Enable Fog", float) = 1
        [ShowIfAny(FOG)] _FogStartOffset ("Fog Start Offset", float) = 1
        [ShowIfAny(FOG)] _FogScale ("Fog Scale", float) = 1
        [Space]
        [ToggleShowIfAny(HEIGHT_FOG, FOG)] _EnableHeightFog ("Enable Height Fog", float) = 0
        [ShowIfAny(2, FOG, HEIGHT_FOG)] _FogHeightOffset ("Fog Height Offset", float) = 0
        [ShowIfAny(2, FOG, HEIGHT_FOG)] _FogHeightScale ("Fog Height Scale", float) = 1
        [ToggleShowIfAny(HEIGHT_FOG_DEPTH_SOFTEN, 2, FOG, HEIGHT_FOG)] _EnableHeightFogSoften ("Soften with Distance", Float) = 0
        [ShowIfAny(3, FOG, HEIGHT_FOG, HEIGHT_FOG_DEPTH_SOFTEN)] _FogSoften ("Soften Scale", Float) = 1
        [ShowIfAny(3, FOG, HEIGHT_FOG, HEIGHT_FOG_DEPTH_SOFTEN)] _FogSoftenOffset ("Soften Offset", Float) = 1
        [ShowIfAny(FOG)] _EmissionFogSuppression ("Emission Fog Suppression", Range(0, 1)) = 0
        [ShowIfAny(FOG)] _MainEffectFogSuppression ("Main Effect Fog Suppression", Range(0, 1)) = 0

        [Header(Settings)] [Space]
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode ("Cull Mode", float) = 2
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("Z Test", float) = 4
        [Enum(Off, 0, On, 1)] _ZWrite ("Z Write", float) = 1

        [Header(Blending)] [Space]
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendSrcFactor ("Foreground Factor", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendDstFactor ("Background Factor", Float) = 0
        [Header(Bloom Blending)] [Space]
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendSrcFactorA ("Foreground Factor", Float) = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendDstFactorA ("Background Factor", Float) = 0

        [Header(Stencil)] [Space]
        _StencilRefValue ("Stencil Ref Value", Float) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)] _StencilComp ("Stencil Comp Func", Float) = 8
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilPass ("Stencil Pass Op", Float) = 0
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
        }

        Blend [_BlendSrcFactor] [_BlendDstFactor], [_BlendSrcFactorA] [_BlendDstFactorA]
        Cull [_CullMode]
        ZTest [_ZTest]
        ZWrite [_ZWrite]

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

            #pragma shader_feature_local _ _SECONDARY_UVS_IMPORT _SECONDARY_UVS_EXTERNAL_SCALE _SECONDARY_UVS_OBJECT_SPACE _SECONDARY_UVS_ADDITIVE_OFFSET

            #pragma shader_feature_local_fragment METAL_SMOOTHNESS_TEXTURE
            #pragma shader_feature_local_fragment _ _METALLIC_TEXTURE_SOURCE_MPM_R _METALLIC_TEXTURE_SOURCE_MPM_A
            #pragma shader_feature_local_fragment _ _SMOOTHNESS_TEXTURE_SOURCE_MPM_A _SMOOTHNESS_TEXTURE_SOURCE_MPM_G_ROUGHNESS
            #pragma shader_feature_local PRECISE_NORMAL

            #pragma shader_feature_local _ _VERTEXMODE_COLOR _VERTEXMODE_EMISSION \
                _VERTEXMODE_METALSMOOTHNESS _VERTEXMODE_SPECIAL _VERTEXMODE_DISPLACEMENT \
                _VERTEXMODE_EMISSIVE_MULT_ADD
            #pragma shader_feature_local _ _VERTEX_WHITEBOOSTTYPE_MAINEFFECT \
                _VERTEX_WHITEBOOSTTYPE_ALWAYS

            #pragma shader_feature_local_vertex DISPLACEMENT_SPATIAL
            #pragma shader_feature_local_vertex DISPLACEMENT_BIDIRECTIONAL
            #pragma shader_feature_local_vertex _ _SPECTROGRAM_FLAT _SPECTROGRAM_FULL
            #pragma shader_feature_local MESH_PACKING
            #pragma shader_feature_local_vertex VERTEXDISPLACEMENT_MASK
            #pragma shader_feature_local_vertex _ _VERTEXDISPLACEMENT_MASK_SOURCE_3D_TEXTURE \
                _VERTEXDISPLACEMENT_MASK_SOURCE_EMISSION_TEXTURE

            #pragma shader_feature_local _ _EMISSIONTEXTURE_SIMPLE _EMISSIONTEXTURE_PULSE \
                _EMISSIONTEXTURE_FLIPBOOK
            #pragma shader_feature_local_fragment _ _EMISSION_TEXTURE_SOURCE_MPM_G
            #pragma shader_feature_local_fragment _ _EMISSION_TEXTURE_SOURCE_SDF
            #pragma shader_feature_local SECONDARY_UVS_EMISSION
            #pragma shader_feature_local SECONDARY_UVS_PULSE
            #pragma shader_feature_local_fragment INVERT_PULSE
            #pragma shader_feature_local_fragment PULSE_MULTIPLY_TEXTURE
            #pragma shader_feature_local_fragment _ _EMISSION_ALPHA_SOURCE_COPY_EMISSION _EMISSION_ALPHA_SOURCE_MPM_R

            #pragma shader_feature_local_fragment EMISSION_MASK
            #pragma shader_feature_local_fragment _ _MASKBLEND_ADD _MASKBLEND_MASKED_ADD
            #pragma shader_feature_local SECONDARY_UVS_EMISSION_MASK

            #pragma shader_feature_local_fragment SECONDARY_EMISSION_MASK
            #pragma shader_feature_local_fragment _ _SECONDARY_MASK_BLEND_ADD _SECONDARY_MASK_BLEND_MASKED_ADD
            #pragma shader_feature_local SECONDARY_UVS_EMISSION_MASK2

            #pragma shader_feature_local_fragment FLIPBOOK_BLENDING_OFF

            #pragma shader_feature_local PRIVATE_POINT_LIGHT
            #pragma shader_feature_local_fragment POINT_LIGHT_IS_LOCAL

            #pragma shader_feature_local DIFFUSE
            #pragma shader_feature_local_fragment BOTH_SIDES_DIFFUSE
            #pragma shader_feature_local_fragment LIGHT_FALLOFF
            #pragma shader_feature_local_fragment DIFFUSE_TEXTURE
            #pragma shader_feature_local_fragment _ _DIFFUSE_TEXTURE_SOURCE_TEXTURE _DIFFUSE_TEXTURE_SOURCE_MPM_R _DIFFUSE_TEXTURE_SOURCE_MPM_A_SMOOTHNESS

            #pragma shader_feature_local SPECULAR

            #pragma shader_feature_local INVERT_RIM_DIM

            #pragma shader_feature_local_fragment _ _PARALLAX_FLEXIBLE _PARALLAX_RGB
            #pragma shader_feature_local _PARALLAX_FLEXIBLE_REFLECTED
            #pragma shader_feature_local_fragment _ _PARALLAX_PROJECTION_WARPED
            #pragma shader_feature_local PARALLAX_IRIDESCENCE
            #pragma shader_feature_local SECONDARY_UVS_PARALLAX
            #pragma shader_feature_local_fragment _ _PARALLAX_MASKING_TEXTURE _PARALLAX_MASKING_VERTEX_COLOR

            #pragma shader_feature_local_fragment DISTORTION_SIMPLE
            #pragma shader_feature_local NOISE_DITHERING
            #pragma shader_feature_local_fragment MULTIPLY_REFLECTIONS
            #pragma shader_feature_local REFLECTION_TEXTURE
            #pragma shader_feature_local REFLECTION_PROBE
            #pragma shader_feature_local_fragment REFLECTION_PROBE_BOX_PROJECTION
            #pragma shader_feature_local_fragment REFLECTION_PROBE_BOX_PROJECTION_OFFSET

            #pragma shader_feature_local_fragment GROUND_FADE

            #pragma shader_feature_local _ _CUSTOM_TIME_SONG_TIME _CUSTOM_TIME_FREEZE
            #pragma shader_feature_local_fragment _ _ACES_APPROACH_BEFORE_EMISSIVE
            #pragma multi_compile_fragment _ ACES_TONE_MAPPING
            #pragma shader_feature_local COLOR_ARRAY
            #pragma shader_feature_local UV_COLOR_SEGMENTS
            #pragma shader_feature_local HIGHLIGHT_SELECTION
            #pragma shader_feature_local _ _HOLOGRAM_GRID _HOLOGRAM_SCANLINE _HOLOGRAM_LEGACY

            #pragma shader_feature_local_fragment FOG
            #pragma shader_feature_local_fragment HEIGHT_FOG
            #pragma shader_feature_local_fragment HEIGHT_FOG_DEPTH_SOFTEN
            #pragma shader_feature_local LIGHTMAP
            #pragma shader_feature_local_fragment OCCLUSION
            #pragma shader_feature_local_fragment DISTANCE_DARKENING
            #pragma shader_feature_local_fragment DISSOLVE
            #pragma shader_feature_local_fragment DISSOLVE_PROGRESS
            #pragma shader_feature_local_fragment DISSOLVE_COLOR

            // Source-exact selectors dropped or merged by the generated material UI.
            // They are declared independently so source-signature collisions remain distinct.
            #pragma shader_feature_local COLOR_BY_FOG
            #pragma shader_feature_local DIRECTIONAL_RIM
            #pragma shader_feature_local DISSOLVE_TEXTURE
            #pragma shader_feature_local ENABLE_EMISSION_ANGLE_DISAPPEAR
            #pragma shader_feature_local ENABLE_RIM_DIM
            #pragma shader_feature_local FOG_COLOR_HIGHLIGHT
            #pragma shader_feature_local INSTANCED_PRIVATE_POINT_LIGHT
            #pragma shader_feature_local NORMAL_MAP
            #pragma shader_feature_local OCCLUSION_BEFORE_EMISSION
            #pragma shader_feature_local OCCLUSION_DETAIL
            #pragma shader_feature_local REFLECTION_STATIC
            #pragma shader_feature_local SECONDARY_UVS_MPM
            #pragma shader_feature_local SECONDARY_UVS_OCCLUSION
            #pragma shader_feature_local SECONDARY_UVS_OCCLUSION_DETAIL
            #pragma shader_feature_local SPECULAR_ANTIFLICKER
            #pragma shader_feature_local TEXTURE3D_EMISSION
            #pragma shader_feature_local TEXTURE3D_LOOKUP
            #pragma shader_feature_local USE_SPHERICAL_NORMAL_OFFSET
            #pragma shader_feature_local _DISSOLVE_SPACE_WORLD_CENTERED
            #pragma shader_feature_local _DISTORTION_TARGET_EMISSIONTEX
            #pragma shader_feature_local _ _EMISSIONCOLORTYPE_GRADIENT \
                _EMISSIONCOLORTYPE_MAINEFFECT _EMISSIONCOLORTYPE_WHITEBOOST
            #pragma shader_feature_local _ _METALLIC_TEXTURE_MPM_R
            #pragma shader_feature_local _OCCLUSION_SOURCE_MPM_B
            #pragma shader_feature_local _PROBE_CALCULATION_PRECISE
            #pragma shader_feature_local _ _RIMLIGHT_LERP _RIMLIGHT_ADDITIVE
            #pragma shader_feature_local _RIM_WHITEBOOSTTYPE_MAINEFFECT
            #pragma shader_feature_local _ _SMOOTHNESS_TEXTURE_MPM_A \
                _SMOOTHNESS_TEXTURE_MPM_G_ROUGHNESS

            #pragma multi_compile_fragment _ BLOOM_FOG

            #include "UnityCG.cginc"
            #include "ShaderLibrary/CustomTonemapping.hlsl"
            #include "Packages/com.llealloo.audiolink/Runtime/Shaders/AudioLink.cginc"

            // Payload requirements use canonical source feature selectors.
            #define USE_UV_SCALE defined(_SECONDARY_UVS_EXTERNAL_SCALE) || defined(_SECONDARY_UVS_OBJECT_SPACE)
            #define USE_SECONDARY_UV USE_UV_SCALE || defined(_SECONDARY_UVS_IMPORT) || \
                defined(_SECONDARY_UVS_ADDITIVE_OFFSET) || defined(SECONDARY_UVS_EMISSION) || \
                defined(SECONDARY_UVS_PULSE) || \
                defined(SECONDARY_UVS_EMISSION_MASK) || defined(SECONDARY_UVS_EMISSION_MASK2) || \
                defined(SECONDARY_UVS_PARALLAX) || defined(SECONDARY_UVS_MPM) || \
                defined(SECONDARY_UVS_OCCLUSION) || \
                defined(SECONDARY_UVS_OCCLUSION_DETAIL) || defined(LIGHTMAP)
            #define USE_NOISE_SCREEN_POSITION defined(NOISE_DITHERING)
            #define USE_NORMAL_MAP_PAYLOAD defined(NORMAL_MAP)
            #define USE_ANTIFLICKER_NORMAL_PAYLOAD defined(SPECULAR_ANTIFLICKER)
            #if defined(MESH_PACKING)
            #if USE_SECONDARY_UV || defined(COLOR_ARRAY)
            #define USE_MESH_PACKING_UV1 0
            #else
            #define USE_MESH_PACKING_UV1 1
            #endif
            #else
            #define USE_MESH_PACKING_UV1 0
            #endif

            #define USE_SPHERE_SDF_3D_VERTEX \
                 defined(_VERTEXMODE_DISPLACEMENT) && defined(VERTEXDISPLACEMENT_MASK) && \
                 defined(_VERTEXDISPLACEMENT_MASK_SOURCE_3D_TEXTURE) && \
                 defined(_VERTEX_WHITEBOOSTTYPE_MAINEFFECT) && defined(_CUSTOM_TIME_FREEZE) && \
                 !defined(_VERTEXMODE_COLOR) && !defined(_VERTEXMODE_EMISSION) && \
                 !defined(_VERTEXMODE_METALSMOOTHNESS) && !defined(_VERTEXMODE_SPECIAL) && \
                 !defined(_VERTEXMODE_EMISSIVE_MULT_ADD) && !defined(_VERTEX_WHITEBOOSTTYPE_ALWAYS) && \
                 !defined(DISPLACEMENT_SPATIAL) && !defined(DISPLACEMENT_BIDIRECTIONAL) && \
                 !defined(_SPECTROGRAM_FLAT) && !defined(_SPECTROGRAM_FULL) && !defined(MESH_PACKING) && \
                 !defined(_CUSTOM_TIME_SONG_TIME)
            #define USE_RIBBON_SPATIAL_MASK_VERTEX \
                 defined(_VERTEXMODE_DISPLACEMENT) && defined(DISPLACEMENT_SPATIAL) && \
                 defined(DISPLACEMENT_BIDIRECTIONAL) && defined(VERTEXDISPLACEMENT_MASK) && \
                 defined(_VERTEX_WHITEBOOSTTYPE_MAINEFFECT) && defined(_CUSTOM_TIME_FREEZE) && \
                !defined(_VERTEXDISPLACEMENT_MASK_SOURCE_3D_TEXTURE) && \
                  !defined(_VERTEX_WHITEBOOSTTYPE_ALWAYS) && \
                 !defined(_CUSTOM_TIME_SONG_TIME) && !defined(MESH_PACKING) && \
                 !defined(_SPECTROGRAM_FLAT) && !defined(_SPECTROGRAM_FULL)
            // USE_SECONDARY_UV
            // USE_UV_SCALE
            float4 _UVScale;
            // --
            // _SECONDARY_UVS_ADDITIVE_OFFSET
            float4 _AdditiveUVOffset;
            // --
            float2 _InputUvMultiplier;
            // --

            // METAL_SMOOTHNESS_TEXTURE
            sampler2D _MetalSmoothnessTex;
            float4 _MetalSmoothnessTex_ST;
            #if USE_NORMAL_MAP_PAYLOAD
            sampler2D _NormalTexture;
            float4 _NormalTexture_ST;
            float _NormalScale;
            #endif
            // --
            float _Smoothness;
            float _Metallic;

            samplerCUBE _ReflectionProbeTexture1;
            samplerCUBE _ReflectionProbeTexture2;
            #if defined(REFLECTION_TEXTURE)
            samplerCUBE _EnvironmentReflectionCube;
            float _ReflectionTexIntensity;
            #endif
            float4 _LightProbeLightBakeIdA;
            float4 _LightProbeLightBakeIdB;
            float4 _LightProbeLightBakeIdC;
            float4 _LightProbeLightBakeIdD;
            float4 _LightProbeLightBakeIdE;
            float4 _LightProbeLightBakeIdF;
            float3 _ReflectionProbePosition;
            float3 _ReflectionProbeBoundsMin;
            float3 _ReflectionProbeBoundsMax;
            float _ReflectionProbeIntensity;
            float _ReflectionProbeGrayscale;
            float _ColoredMetalMultiplier;
            float _WhiteOffset;
            float _AntiflickerStrength;
            float _AntiflickerDistanceScale;
            float _AntiflickerDistanceOffset;
            float3 _ReflectionProbeBoxProjectionSizeOffset;
            float3 _ReflectionProbeBoxProjectionPositionOffset;

            #if defined(NOISE_DITHERING)
            sampler2D _GlobalBlueNoiseTex;
            float2 _GlobalBlueNoiseParams;
            float _GlobalRandomValue;
            #endif

            #define USE_VERTEX_EMISSION (defined(_VERTEXMODE_EMISSION) || \
                defined(_VERTEXMODE_SPECIAL) || defined(_VERTEXMODE_EMISSIVE_MULT_ADD))
            #define USE_VERTEX_COLOR (USE_VERTEX_EMISSION || defined(_VERTEXMODE_COLOR) || \
                defined(_VERTEXMODE_METALSMOOTHNESS) || defined(_VERTEXMODE_DISPLACEMENT))
            #if defined(PRIVATE_POINT_LIGHT) && !defined(INSTANCED_PRIVATE_POINT_LIGHT)
            #define USE_UNIFORM_PRIVATE_POINT_COLOR 1
            #else
            #define USE_UNIFORM_PRIVATE_POINT_COLOR 0
            #endif
            // USE_VERTEX_EMISSION
            float _EmissionThreshold;
            float _EmissionStrength;
            float _EmissionBloomIntensity;
            float _QuestWhiteboostMultiplier;
            // --

            #define ENABLE_EMISSION_TEXTURE defined(_EMISSIONTEXTURE_SIMPLE) || defined(_EMISSIONTEXTURE_PULSE) || defined(_EMISSIONTEXTURE_FLIPBOOK)
            #define USE_EMISSION_TEXTURE !defined(_EMISSION_TEXTURE_SOURCE_MPM_G) && (defined(_EMISSIONTEXTURE_SIMPLE) || defined(_EMISSIONTEXTURE_FLIPBOOK))
            // USE_EMISSION_TEXTURE
            sampler2D _EmissionTex;
            float4 _EmissionTex_ST;
            // _EMISSIONTEXTURE_SIMPLE
            float2 _EmissionTexSpeed;
            // --
            // --

            // EMISSION_ANGLE_DISAPPEAR && ENABLE_EMISSION_TEXTURE
            float _EmissionThresholdAngle;
            // --

            #define USE_EMISSION_TEXTURE_COLOR ENABLE_EMISSION_TEXTURE
            // USE_EMISSION_GRADIENT_TEXTURE removed — gradient is now handled inside USE_EMISSION_TEXTURE_COLOR
            sampler2D _EmissionGradientTex;
            float4 _EmissionGradientTex_ST;
            // --
            // _EMISSIONBLOOMTYPE_GRADIENT
            float _EmissionGradientPanningSpeed;
            float _EmissionGradientIntensity;
            // --

            sampler2D _PulseMask;
            float4 _PulseMask_ST;
            float _PulseWidth;
            float _PulseSpeed;
            float _PulseSmooth;

            // _EMISSIONTEXTURE_FLIPBOOK
            float _FlipbookColumns;
            float _FlipbookRows;
            float _FlipbookNonloopableFrames;
            float _FlipbookSpeed;
            // --

            float _EmissionTexBloomIntensity;
            float _EmissionTexWhiteBoostMultiplier;

            #define USE_EMISSION_MASK defined(_EMISSIONTEXTURE_PULSE) || defined(_EMISSIONTEXTURE_SIMPLE)
            // USE_EMISSION_MASK
            // EMISSION_MASK
            sampler2D _EmissionMask;
            float4 _EmissionMask_ST;
            float2 _EmissionMaskSpeed;
            // --
            // SECONDARY_EMISSION_MASK
            sampler2D _SecondaryEmissionMask;
            float4 _SecondaryEmissionMask_ST;
            float2 _SecondaryEmissionMaskSpeed;
            // --
            float _EmissionMaskStepValue;
            float _EmissionMaskStepWidth;
            // --

            float _AmbientMinimalValue;
            float _AmbientMultiplier;
            #if defined(_HOLOGRAM_GRID) || defined(_HOLOGRAM_SCANLINE) || defined(_HOLOGRAM_LEGACY)
            float4 _TimeHelperOffset;
            float _HologramGridSize;
            float _HologramScanDistance;
            float _HoloIntensity;
            #endif

            // DIFFUSE_TEXTURE
            sampler2D _DiffuseTex;
            float4 _DiffuseTex_ST;
            float _AlbedoMultiplier;
            // --

            sampler2D _DirtDetailTex;
            float4 _DirtDetailTex_ST;
            sampler2D _DirtTex;
            float4 _DirtTex_ST;
            float _OcclusionIntensity;
            sampler2D _LightMap1;
            sampler2D _LightMap2;
            float3 _LightmapLightBakeIdA;
            float3 _LightmapLightBakeIdB;
            float3 _LightmapLightBakeIdC;
            float3 _LightmapLightBakeIdD;
            float3 _LightmapLightBakeIdE;
            float3 _LightmapLightBakeIdF;

            // DIFFUSE
            float _BothSidesDiffuseMultiplier;
            // --

            // SPECULAR
            float _SpecularIntensity;
            // --

            float3 _SphericalNormalOffsetCenter;
            float _SphericalNormalOffsetIntensity;

            // _VERTEXMODE_DISPLACEMENT
            float _DisplacementStrength;
            float4 _DisplacementAxisMultiplier;
            // --

            // VERTEXDISPLACEMENT_MASK
            #if defined(VERTEXDISPLACEMENT_MASK)
            #if defined(_VERTEXDISPLACEMENT_MASK_SOURCE_3D_TEXTURE)
            sampler3D _VertexDisplacement3DTexture;
            float3 _VertexDisplacement3DTexOffset;
            float3 _VertexDisplacement3DTexPanning;
            float _VertexDisplacement3DTexScale;
            #elif !defined(_VERTEXDISPLACEMENT_MASK_SOURCE_EMISSION_TEXTURE)
            sampler2D _VertexDisplacementMask;
            float4 _VertexDisplacementMask_ST;
            float2 _VertexDisplacementMaskSpeed;
            #endif
            float _VertexDisplacementMaskMode;
            float _VertexDisplacementMaskMultiplier;
            float _VertexDisplacementMaskOffset;

            inline float ComposeVertexDisplacementMask(float displacementScale, float mask)
            {
                // The recovered active source route uses scalar mode 0. Its mask
                // composition multiplies the displacement scale by the sampled mask.
                return _VertexDisplacementMaskMode == 0.0
                    ? displacementScale * mask
                    : displacementScale + mask;
            }
            #endif
            // --

            // _SPECTROGRAM_FULL
            float4 _SpectrogramData[32]; // 128 floats packed as 32 Vector4s
            // --

            // RIM_DIM
            float _RimScale;
            float _RimOffset;
            float _RimDistanceOffset;
            float _RimDistanceScale;
            float _RimSmoothness;
            float _RimDarkening;
            float _RimLightEdgeStart;
            float _RimLightIntensity;
            float _RimLightBloomIntensity;
            float3 _RimPerpendicularAxis;
            float _RimLightWhiteboostMultiplier;
            float _ColorFogMultiplier;
            float _ColorFogHighlightMultiplier;
            float _ColorFogInfluence;
            float _ColorFogMax;
            // --

            // DISTORTION_SIMPLE
            sampler2D _DistortionTex;
            float4 _DistortionTex_ST;
            float _DistortionStrength;
            float2 _DistortionPanning;
            float2 _DistortionAxes;
            // --

            // PARALLAX_IRIDESCENCE
            sampler2D _ParallaxMap;
            float4 _ParallaxMap_ST;
            float2 _ParallaxTexSpeed;
            float4 _ParallaxColor;
            float _ParallaxIntensity;
            float _ParallaxIntensity_Step;
            float _StartOffset;
            float _OffsetStep;
            float _Layers;
            float _IridescenceTiling;
            float3 _IridescenceAxesMultiplier;
            float _IridescenceColorInfluence;
            // _EMISSION_TEXTURE_SOURCE_SDF
            float4 _SDFPointArray[3];
            float3 _SDFNoisePanning;
            float3 _SDFNoiseOffset;
            float _SDFNoiseIntensity;
            float _SDFNoiseScale;
            float _SDFPointIntensity;
            float _SDFNegativeIntensity;
            sampler3D _SDFNoiseTex;
            #if defined(TEXTURE3D_LOOKUP)
            sampler3D _LookupTex;
            float3 _LookupGridSize;
            float4 _LookupXDisplacementMapping;
            float4 _LookupYDisplacementMapping;
            float4 _LookupZDisplacementMapping;
            float4 _LookupRadialDisplacementMapping;
            float4 _LookupScaleMapping;
            float4 _LookupRotationMapping;
            float4 _LookupEmissiveMapping;
            float _LookupXYZDisplacementScale;
            float _LookupRadialDisplacementScale;
            float _LookupMaxScale;
            float _LookupRotationMultiplier;
            float _LookupEmissiveModulationStrength;
            #endif
            // --

            // _PARALLAX_MASKING_TEXTURE
            sampler2D _ParallaxMaskingMap;
            float4 _ParallaxMaskingMap_ST;
            float2 _ParallaxMaskSpeed;
            float _ParallaxMaskIntensity;
            // --
            // --

            // GROUND_FADE
            float _GroundFadeScale;
            float _GroundFadeOffset;
            // --

            #define USE_FOG_SUPPRESSION defined(_EMISSIONTEXTURE_SIMPLE) || defined(_EMISSIONTEXTURE_PULSE) || defined(_EMISSIONTEXTURE_FLIPBOOK) || defined(_VERTEXMODE_EMISSION) || defined(_VERTEXMODE_SPECIAL)
            // BLOOM_FOG && FOG
            float _FogStartOffset;
            float _FogScale;
            // HEIGHT_FOG
            float _FogHeightOffset;
            float _FogHeightScale;
            float _FogSoften;
            float _FogSoftenOffset;
            // --
            // USE_FOG_SUPPRESSION
            float _EmissionFogSuppression;
            float _MainEffectFogSuppression;
            // --
            // --

            // DISTANCE_DARKENING
            float _DarkeningScale;
            float _DarkeningIntensity;
            float3 _DarkeningCenter;
            float3 _DarkeningDirection;

            // DISSOLVE
            #if defined(DISSOLVE)
            float3 _DissolveAxisVector;
            float _DissolveOffset;
            float _DissolveProgress;
            float _DissolveStartValue;
            float _DissolveEndValue;
            float _InvertDissolve;
            float _CutColorFalloff;
            float _CutColorBacksideFalloff;
            float4 _DissolveColor;
            float _DissolveColorIntensity;
            sampler2D _DissolveTexture;
            float4 _DissolveTexture_ST;
            float2 _DissolveTextureSpeed;
            float _DissolveTextureInfluence;
            #endif
            // --

            // COLOR_ARRAY
            float4 _ColorsArray[200];
            #if defined(COLOR_ARRAY)
            float _Intensity;
            float _AlphaMultiplier;
            #endif
            #if defined(UV_COLOR_SEGMENTS)
            float4 _UVColors[10];
            float4 _UVRimColors[10];
            #endif
            #if defined(HIGHLIGHT_SELECTION)
            int _SegmentToHighlight;
            #endif


            #if defined(UNITY_INSTANCING_ENABLED)
            UNITY_INSTANCING_BUFFER_START(Props)
                UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
                UNITY_DEFINE_INSTANCED_PROP(float4, _NominalDiffuseLevel)
                UNITY_DEFINE_INSTANCED_PROP(float, _EmissionBrightness)
                UNITY_DEFINE_INSTANCED_PROP(float4, _EmissionColor)
                UNITY_DEFINE_INSTANCED_PROP(float4, _EmissionTexColor)
                UNITY_DEFINE_INSTANCED_PROP(float, _EmissionGradientPosition)
                UNITY_DEFINE_INSTANCED_PROP(float, _EmissionMaskIntensity)
                UNITY_DEFINE_INSTANCED_PROP(float, _SecondaryEmissionMaskIntensity)
            #if !USE_UNIFORM_PRIVATE_POINT_COLOR
            UNITY_DEFINE_INSTANCED_PROP(float4, _PrivatePointLightColor)
            #endif
            UNITY_DEFINE_INSTANCED_PROP(float, _OcclusionDetailIntensity)
            UNITY_DEFINE_INSTANCED_PROP(float, _TimeOffset)
            UNITY_DEFINE_INSTANCED_PROP(float, _MeshPackingId)
            #if defined(_EMISSIONTEXTURE_FLIPBOOK)
            UNITY_DEFINE_INSTANCED_PROP(float, _StartTime)
            #endif
            UNITY_DEFINE_INSTANCED_PROP(float4, _DisplacementAxisMultiplier)
            UNITY_DEFINE_INSTANCED_PROP(float, _DisplacementStrength)
            UNITY_DEFINE_INSTANCED_PROP(float, _EmissionGradientIntensity)
            UNITY_DEFINE_INSTANCED_PROP(float, _SDFNoiseIntensity)
            UNITY_DEFINE_INSTANCED_PROP(float, _SDFNoiseScale)
            UNITY_DEFINE_INSTANCED_PROP(float, _DistortionStrength)
            #if defined(_RIMLIGHT_LERP) || defined(_RIMLIGHT_ADDITIVE)
            UNITY_DEFINE_INSTANCED_PROP(float4, _RimLightColor)
            #endif
            #if defined(COLOR_ARRAY)
            UNITY_DEFINE_INSTANCED_PROP(float, _ColorsArrayOffset)
            #endif
            #if defined(TEXTURE3D_LOOKUP)
            UNITY_DEFINE_INSTANCED_PROP(float4, _LookupGridElementIndex)
            UNITY_DEFINE_INSTANCED_PROP(float4, _LookupGridObjectSpacePivot)
            #endif
            #if defined(_HOLOGRAM_GRID) || defined(_HOLOGRAM_SCANLINE) || defined(_HOLOGRAM_LEGACY)
            UNITY_DEFINE_INSTANCED_PROP(float4, _HologramColor)
            UNITY_DEFINE_INSTANCED_PROP(float, _HologramFill)
            UNITY_DEFINE_INSTANCED_PROP(float, _HologramPhaseOffset)
            UNITY_DEFINE_INSTANCED_PROP(float, _HologramStripeSpeed)
            UNITY_DEFINE_INSTANCED_PROP(float, _HaltScan)
            #endif
            UNITY_INSTANCING_BUFFER_END(Props)
            #else
            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
                float4 _NominalDiffuseLevel;
                float4 _EmissionColor;
                float4 _EmissionTexColor;
                float _EmissionBrightness;
                float _EmissionGradientPosition;
                float _EmissionMaskIntensity;
                float _SecondaryEmissionMaskIntensity;
                float4 _PrivatePointLightColor;
                float _OcclusionDetailIntensity;
                float _TimeOffset;
                float _MeshPackingId;
                #if defined(_RIMLIGHT_LERP) || defined(_RIMLIGHT_ADDITIVE)
                float4 _RimLightColor;
                #endif
                #if defined(_EMISSIONTEXTURE_FLIPBOOK)
                float _StartTime;
                #endif
                #if defined(COLOR_ARRAY)
                float _ColorsArrayOffset;
                #endif
                #if defined(TEXTURE3D_LOOKUP)
                float4 _LookupGridElementIndex;
                float4 _LookupGridObjectSpacePivot;
                #endif
                #if defined(_HOLOGRAM_GRID) || defined(_HOLOGRAM_SCANLINE) || defined(_HOLOGRAM_LEGACY)
                float4 _HologramColor;
                float _HologramFill;
                float _HologramPhaseOffset;
                float _HologramStripeSpeed;
                float _HaltScan;
                #endif
            CBUFFER_END
            #endif
            #if defined(UNITY_INSTANCING_ENABLED) && USE_UNIFORM_PRIVATE_POINT_COLOR
            float4 _PrivatePointLightColor;
            #endif

            #if defined(UNITY_INSTANCING_ENABLED)
            // This exact source family keeps brightness shared while its color, mask, and time controls are instanced.
            float _EmissionBrightness;
            #endif

            #define USE_WORLD_NORMAL defined(DIFFUSE) || defined(SPECULAR) || \
                defined(PARALLAX_IRIDESCENCE) || defined(_PARALLAX_FLEXIBLE_REFLECTED) || \
                defined(PRIVATE_POINT_LIGHT) || \
                defined(REFLECTION_TEXTURE) || defined(REFLECTION_PROBE) || defined(REFLECTION_STATIC) || \
                defined(_VERTEXMODE_DISPLACEMENT) || \
                defined(USE_SPHERICAL_NORMAL_OFFSET) || \
                defined(ENABLE_EMISSION_ANGLE_DISAPPEAR) || \
                defined(ENABLE_RIM_DIM) || defined(UV_COLOR_SEGMENTS) || \
                defined(_RIMLIGHT_LERP) || defined(_RIMLIGHT_ADDITIVE) || \
                defined(TEXTURE3D_LOOKUP) || \
                USE_NORMAL_MAP_PAYLOAD || USE_ANTIFLICKER_NORMAL_PAYLOAD

            #include "ShaderLibrary/Data.hlsl"
            #include "ShaderLibrary/Surface.hlsl"
            #include "ShaderLibrary/Dissolve.hlsl"
            #include "ShaderLibrary/Iridescence.hlsl"
            #include "ShaderLibrary/Parallax.hlsl"
            #include "ShaderLibrary/CustomLighting.hlsl"
            #include "ShaderLibrary/LitReflection.hlsl"
            #include "ShaderLibrary/Emission.hlsl"
            #include "ShaderLibrary/Hologram.hlsl"
            #include "ShaderLibrary/PostProcess.hlsl"
            #include "ShaderLibrary/RimLight.hlsl"
            // ------------------------------------------------------------------
            // Lit.shader vertex program (appdata / v2f / vert).
            // Inlined from the former ShaderLibrary/LitVertex.hlsl: this vertex
            // plumbing is Lit.shader-specific (its payload macros and properties
            // are defined in this shader's body), so it lives here, not in the
            // shared ShaderLibrary.
            // ------------------------------------------------------------------
            #include "ShaderLibrary/Fog.hlsl"
            #include "ShaderLibrary/CustomTime.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                #if USE_VERTEX_COLOR
                float4 color : COLOR;
                #endif
                float2 uv1 : TEXCOORD0;
                #if USE_SECONDARY_UV || defined(COLOR_ARRAY)
                float2 uv2 : TEXCOORD1;
                #elif USE_RIBBON_SPATIAL_MASK_VERTEX
                float2 displacementUv : TEXCOORD1;
                #endif
                #if defined(_SPECTROGRAM_FULL)
                float2 uv3 : TEXCOORD2;
                #endif
                #if USE_WORLD_NORMAL
                float3 normal : NORMAL;
                #endif
                #if USE_NORMAL_MAP_PAYLOAD
                float4 tangent : TANGENT;
                #endif
                #if defined(MESH_PACKING)
                #if USE_MESH_PACKING_UV1
                float2 packingUv : TEXCOORD1;
                #else
                float2 packingUv : TEXCOORD3;
                #endif
                #endif
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                #if USE_VERTEX_COLOR
                float4 color : COLOR0;
                #endif
                #if USE_VERTEX_EMISSION
                float4 emission : COLOR1;
                #endif
                #if USE_SECONDARY_UV
                float4 uv : TEXCOORD0;
                #else
                float2 uv : TEXCOORD0;
                #endif
                float3 worldPos : TEXCOORD1;
                float4 screenPos : TEXCOORD2;
                #if USE_WORLD_NORMAL
                float3 worldNormal : TEXCOORD3;
                #endif
                #if USE_NORMAL_MAP_PAYLOAD
                float3 tangentWS : TEXCOORD12;
                float3 bitangentWS : TEXCOORD13;
                #endif
                #if USE_ANTIFLICKER_NORMAL_PAYLOAD
                float3 antiflickerNormal : TEXCOORD15;
                #endif
                #if USE_NOISE_SCREEN_POSITION
                float4 noiseScreenPos : TEXCOORD4;
                #endif
                #if defined(COLOR_ARRAY)
                float2 colorArrayId : TEXCOORD17;
                #endif
                #if defined(ENABLE_EMISSION_ANGLE_DISAPPEAR)
                float emissionAngle : TEXCOORD18;
                #endif
                #if defined(REFLECTION_TEXTURE)
                float3 reflectionTextureDirection : TEXCOORD10;
                float reflectionTextureRimFactor : TEXCOORD14;
                #elif defined(ENABLE_RIM_DIM)
                float rimDim : TEXCOORD14;
                #endif
                #if defined(LIGHTMAP)
                float2 lightmapUv : TEXCOORD11;
                #endif
                #if defined(_EMISSIONTEXTURE_FLIPBOOK)
                float2 flipbookUv : TEXCOORD22;
                float4 flipbookFrameSelector : TEXCOORD16;
                #endif
                #if defined(TEXTURE3D_LOOKUP) && defined(TEXTURE3D_EMISSION)
                float lookupEmission : TEXCOORD33;
                #endif
                #if defined(UV_COLOR_SEGMENTS)
                float4 uvSegmentColor : TEXCOORD19;
                float4 uvSegmentRimColor : TEXCOORD20;
                #endif
                #if defined(HIGHLIGHT_SELECTION)
                float highlightSelection : TEXCOORD21;
                #endif
                #if defined(_HOLOGRAM_GRID)
                float3 hologramObjectPosition : TEXCOORD30;
                #endif
                UNITY_VERTEX_INPUT_INSTANCE_ID};

            v2f vert(appdata i, uint id : SV_VertexID)
            {
                v2f o;

                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_TRANSFER_INSTANCE_ID(i, o);
                #if defined(HIGHLIGHT_SELECTION)
                o.highlightSelection = _SegmentToHighlight == 0;
                #endif

                #if USE_MESH_PACKING_UV1
                float exactMeshPackingId = UNITY_ACCESS_INSTANCED_PROP(Props, _MeshPackingId);
                if (abs(i.packingUv.y - exactMeshPackingId) > 0.1)
                    i.vertex = float4(0.0, 0.0, 0.0, 0.0);
                #endif

                #if USE_SPHERE_SDF_3D_VERTEX
                {
                    float timeOffset = UNITY_ACCESS_INSTANCED_PROP(Props, _TimeOffset);
                    float4 undisplacedWorldPosition = mul(unity_ObjectToWorld, i.vertex);
                    float3 displacementUv = _VertexDisplacement3DTexScale *
                        undisplacedWorldPosition.xyz;
                    displacementUv += _VertexDisplacement3DTexPanning * timeOffset * 0.1 +
                        _VertexDisplacement3DTexOffset;
                    float displacementLod = _VertexDisplacement3DTexScale *
                        undisplacedWorldPosition.w;
                    float3 displacementMask = tex3Dlod(
                        _VertexDisplacement3DTexture,
                        float4(displacementUv, displacementLod)).rgb;
                    displacementMask = _VertexDisplacementMaskMultiplier * displacementMask +
                        _VertexDisplacementMaskOffset;
                    float displacementStrength = i.color.b *
                        UNITY_ACCESS_INSTANCED_PROP(Props, _DisplacementStrength);
                    float3 displacementAxis =
                        UNITY_ACCESS_INSTANCED_PROP(Props, _DisplacementAxisMultiplier).xyz;
                    i.vertex.xyz += displacementMask * displacementStrength * displacementAxis * i.normal;
                }
                #elif USE_RIBBON_SPATIAL_MASK_VERTEX
                {
                    float frozenTime = UNITY_ACCESS_INSTANCED_PROP(Props, _TimeOffset) * 0.05;
                    float2 displacementUv = i.displacementUv * _VertexDisplacementMask_ST.xy +
                        _VertexDisplacementMask_ST.zw;
                    displacementUv += _VertexDisplacementMask_ST.xy *
                        _VertexDisplacementMaskSpeed * frozenTime;
                    float3 displacementMask = tex2Dlod(
                        _VertexDisplacementMask, float4(displacementUv, 0.0, 0.0)).rgb;
                    displacementMask = _VertexDisplacementMaskMultiplier * displacementMask +
                        _VertexDisplacementMaskOffset;
                    float3 displacementDirection = (i.color.rgb * 2.0 - 1.0) *
                        UNITY_ACCESS_INSTANCED_PROP(Props, _DisplacementAxisMultiplier).xyz;
                    float displacementStrength =
                        UNITY_ACCESS_INSTANCED_PROP(Props, _DisplacementStrength);
                    i.vertex.xyz += displacementMask * displacementStrength * displacementDirection;
                }
                #elif defined(_VERTEXMODE_DISPLACEMENT)
                {
                    float3 dispDir;
                #if defined(DISPLACEMENT_SPATIAL)
                // RGB channels → XYZ displacement direction
                dispDir = i.color.xyz;
                #   if defined(DISPLACEMENT_BIDIRECTIONAL)
                dispDir = dispDir * 2.0 - 1.0;
                #   endif
                dispDir *= _DisplacementAxisMultiplier.xyz;
                #else
                // Default: displace along vertex normal, magnitude from blue channel
                dispDir = i.normal * i.color.b;
                #   if defined(DISPLACEMENT_BIDIRECTIONAL)
                dispDir = dispDir * 2.0 - 1.0;
                #   endif
                dispDir *= _DisplacementAxisMultiplier.xyz;
                #endif

                float spectrogramScale = 1.0;
                #if defined(_SPECTROGRAM_FULL)
                // uv3.x (0-1) indexes across 128 frequency bins uploaded by SpectrogramPropertyRowAnimator
                {
                    uint bin = (uint)(i.uv3.x * 128.0);
                    uint v4idx = bin / 4;
                    uint comp = bin % 4;
                    float4 entry = _SpectrogramData[v4idx];
                    spectrogramScale = comp == 0 ? entry.x : comp == 1 ? entry.y : comp == 2 ? entry.z : entry.w;
                }
                #endif

                float _dispScale = _DisplacementStrength * (spectrogramScale);

                #if defined(VERTEXDISPLACEMENT_MASK)
                { 
                #if defined(_VERTEXDISPLACEMENT_MASK_SOURCE_3D_TEXTURE)
                // 3D texture mask — matches decompiled SimpleLit exactly:
                // sample world-space position scaled/panned/offset into the 3D tex,
                // then multiply+offset the result to get a scalar mask.
                {
                    float4 _timeOffset = UNITY_ACCESS_INSTANCED_PROP(Props, _TimeOffset);
                    float3 _dmCoord = _VertexDisplacement3DTexPanning * _timeOffset.xxx;
                    _dmCoord = _dmCoord * float3(0.1, 0.1, 0.1) + _VertexDisplacement3DTexOffset;
                    // world-space position of unmodified vertex
                    float3 _dmWorldPos = mul(unity_ObjectToWorld, i.vertex).xyz;
                    float4 _dmSampCoord = float4(_VertexDisplacement3DTexScale.xxx * _dmWorldPos + _dmCoord, 0.0);
                    float4 _dmSamp = tex3Dlod(_VertexDisplacement3DTexture, _dmSampCoord);
                    float3 _dmVal = _VertexDisplacementMaskMultiplier.xxx * _dmSamp.xyz
                        + _VertexDisplacementMaskOffset.xxx;
                    _dispScale = ComposeVertexDisplacementMask(_dispScale, _dmVal.x);
                }
                #elif defined(_VERTEXDISPLACEMENT_MASK_SOURCE_EMISSION_TEXTURE)
                {
                    #if defined(_CUSTOM_TIME_FREEZE)
                    float _dmTime = UNITY_ACCESS_INSTANCED_PROP(Props, _TimeOffset) * 0.05;
                    #else
                    float _dmTime = (_Time.y + UNITY_ACCESS_INSTANCED_PROP(Props, _TimeOffset)) * 0.05;
                    #endif
                    float2 _dmUv = i.uv1.xy * _EmissionTex_ST.xy + _EmissionTex_ST.zw;
                    _dmUv += _EmissionTex_ST.xy * _EmissionTexSpeed * _dmTime.xx;
                    float _dmSample = tex2Dlod(_EmissionTex, float4(_dmUv, 0.0, 0.0)).r;
                    _dispScale = ComposeVertexDisplacementMask(
                        _dispScale,
                        _VertexDisplacementMaskMultiplier * _dmSample + _VertexDisplacementMaskOffset);
                }
                #else
                // 2D texture mask — matches SimpleLit VERTEXDISPLACEMENT_MASK path
                { 
                #if defined(_CUSTOM_TIME_FREEZE)
                float _dmTime = UNITY_ACCESS_INSTANCED_PROP(Props, _TimeOffset) * 0.05;
                #else
                float _dmTime = (_Time.y + UNITY_ACCESS_INSTANCED_PROP(Props, _TimeOffset)) * 0.05;
                #endif
                float2 _dmUv = i.uv1.xy * _VertexDisplacementMask_ST.xy + _VertexDisplacementMask_ST.zw;
                float2 _dmPan = _VertexDisplacementMask_ST.xy * _VertexDisplacementMaskSpeed;
                _dmUv = _dmPan * _dmTime.xx + _dmUv;
                float4 _dmSamp = tex2Dlod(_VertexDisplacementMask, float4(_dmUv, 0, 0));
                float3 _dmVal = _VertexDisplacementMaskMultiplier.xxx * _dmSamp.xyz
                    + _VertexDisplacementMaskOffset.xxx;
                 _dispScale = ComposeVertexDisplacementMask(_dispScale, _dmVal.x);
                        }
                #endif
                    }
                #endif

                i.vertex.xyz += _dispScale * dispDir;
                }
                #endif

                #if defined(TEXTURE3D_LOOKUP)
                {
                    float3 lookupIndex = UNITY_ACCESS_INSTANCED_PROP(
                        Props, _LookupGridElementIndex).xyz;
                    float3 lookupUv = (lookupIndex + 0.5) / _LookupGridSize;
                    float4 lookupValue = tex3Dlod(_LookupTex, float4(lookupUv, 0.0));
                    lookupValue = lookupValue * 2.0 - 1.0;

                    float3 radialVector = 0.001.xxx - UNITY_ACCESS_INSTANCED_PROP(
                        Props, _LookupGridObjectSpacePivot).xyz;
                    float radialDistance = length(radialVector);
                    float3 radialDirection = radialVector * rsqrt(dot(radialVector, radialVector));
                    float radialFactor = pow(2.0, log(_LookupRadialDisplacementScale) *
                                             dot(lookupValue, _LookupRadialDisplacementMapping));
                    float lookupScale = pow(2.0, log(_LookupMaxScale) *
                                            dot(lookupValue, _LookupScaleMapping));
                    float rotation = dot(lookupValue, _LookupRotationMapping) *
                        _LookupRotationMultiplier * 6.28319;
                    float sine = sin(rotation);
                    float cosine = cos(rotation);

                    float3 scaledPosition = lookupScale * i.vertex.xyz;
                    float2 rotatedPosition = float2(
                        cosine * scaledPosition.x - sine * scaledPosition.y,
                        sine * scaledPosition.x + cosine * scaledPosition.y);
                    float2 rotatedNormal = float2(
                        cosine * i.normal.x - sine * i.normal.y,
                        sine * i.normal.x + cosine * i.normal.y);
                    i.vertex.xyz = float3(rotatedPosition, scaledPosition.z);
                    i.normal.xy = rotatedNormal;
                    i.vertex.xyz += radialDistance * (radialFactor - 1.0) * radialDirection;
                    i.vertex.xyz += _LookupXYZDisplacementScale * float3(
                        dot(lookupValue, _LookupXDisplacementMapping),
                        dot(lookupValue, _LookupYDisplacementMapping),
                        dot(lookupValue, _LookupZDisplacementMapping));
                #if defined(TEXTURE3D_EMISSION)
                o.lookupEmission = (1.0 + dot(lookupValue, _LookupEmissiveMapping)) *
                    _LookupEmissiveModulationStrength * 0.5;
                #endif
                }
                #endif

                o.vertex = UnityObjectToClipPos(i.vertex);
                #if USE_VERTEX_COLOR
                o.color = i.color;
                // TODO: wtf does this do
                #if USE_VERTEX_EMISSION
                #if defined(COLOR_ARRAY)
                {
                    float _caIdx = round(i.uv2.x * 10.0 + i.uv2.y +
                        UNITY_ACCESS_INSTANCED_PROP(Props, _ColorsArrayOffset));
                    o.emission = _ColorsArray[_caIdx];
                }
                #else
                o.emission = UNITY_ACCESS_INSTANCED_PROP(Props, _EmissionColor);
                #endif
                #endif
                #endif

                o.uv.xy = i.uv1.xy;
                #if defined(_HOLOGRAM_GRID)
                o.hologramObjectPosition = i.vertex.xyz;
                #endif
                #if defined(UV_COLOR_SEGMENTS)
                uint uvSegmentIndex = (uint)max(i.uv1.x * 10.0, 0.0);
                o.uvSegmentColor = _UVColors[uvSegmentIndex];
                o.uvSegmentRimColor = _UVRimColors[uvSegmentIndex];
                #endif
                #if defined(HIGHLIGHT_SELECTION)
                #if defined(UV_COLOR_SEGMENTS)
                o.highlightSelection = floor(i.uv1.x * 10.0) == floor(_SegmentToHighlight);
                #endif
                #endif
                #if defined(LIGHTMAP)
                o.lightmapUv = i.uv2.xy * unity_LightmapST.xy + unity_LightmapST.zw;
                #endif
                #if USE_SECONDARY_UV
                o.uv.zw = i.uv2.xy;
                #if USE_UV_SCALE
                o.uv.zw *= _UVScale.xy;
                #endif

                #if defined(_EMISSIONTEXTURE_FLIPBOOK)
                {
                    float totalFrames = trunc(_FlipbookRows * _FlipbookColumns);
                    float loopingFrameCount = trunc(totalFrames - _FlipbookNonloopableFrames);
                    float elapsed = _SongTime.y +
                        UNITY_ACCESS_INSTANCED_PROP(Props, _TimeOffset) -
                        UNITY_ACCESS_INSTANCED_PROP(Props, _StartTime);
                    float frameTime = elapsed * _FlipbookSpeed;
                    float loopingTime = frameTime - _FlipbookNonloopableFrames;
                    float loopingProduct = loopingFrameCount * loopingTime;
                    float signedLoopingFrameCount = loopingProduct >= -loopingProduct
                                                        ? loopingFrameCount
                                                        : -loopingFrameCount;
                    float wrappedFrame = frac(loopingTime / signedLoopingFrameCount) *
                        signedLoopingFrameCount + _FlipbookNonloopableFrames;
                    float frame = frameTime < totalFrames ? frameTime : wrappedFrame;
                    float frameFloor = floor(frame);
                    float columnQuotient = frameFloor / _FlipbookColumns;
                    float columnSign = columnQuotient >= -columnQuotient ? 1.0 : -1.0;
                    float column = frac(abs(columnQuotient)) * columnSign * _FlipbookColumns;
                    float row = _FlipbookRows - 1.0 - floor(frame / _FlipbookColumns);
                    o.flipbookUv = (float2(column, row) + i.uv1.xy) /
                        float2(_FlipbookColumns, _FlipbookRows);

                    float frameFraction = frac(frame);
                    float4 frameSelector = frameFraction < 0.75
                                               ? float4(0.0, 0.0, 1.0, 0.0)
                                               : float4(0.0, 0.0, 0.0, 1.0);
                    frameSelector = frameFraction < 0.5 ? float4(0.0, 1.0, 0.0, 0.0) : frameSelector;
                    frameSelector = frameFraction < 0.25 ? float4(1.0, 0.0, 0.0, 0.0) : frameSelector;
                    o.flipbookFrameSelector = i.uv1.x + i.uv1.y <= 0.01 ? 0.0.xxxx : frameSelector;
                }
                #endif
                #if defined(_SECONDARY_UVS_ADDITIVE_OFFSET)
                o.uv.zw += _AdditiveUVOffset.xy;
                #endif
                o.uv.zw *= _InputUvMultiplier.xy;
                #endif

                #if USE_WORLD_NORMAL
                float3 sourceLocalNormal = i.normal;
                #if defined(USE_SPHERICAL_NORMAL_OFFSET)
                sourceLocalNormal = lerp(
                    sourceLocalNormal,
                    i.vertex.xyz + _SphericalNormalOffsetCenter,
                    _SphericalNormalOffsetIntensity);
                #endif
                #if defined(PRECISE_NORMAL)
                o.worldNormal = UnityObjectToWorldNormal(sourceLocalNormal);
                #else
                o.worldNormal = normalize(UnityObjectToWorldNormal(sourceLocalNormal));
                #endif
                #if USE_NORMAL_MAP_PAYLOAD
                o.tangentWS = normalize(UnityObjectToWorldDir(i.tangent.xyz));
                float tangentSign = i.tangent.w * unity_WorldTransformParams.w;
                o.bitangentWS = cross(o.worldNormal, o.tangentWS) * tangentSign;
                #endif
                #endif
                #if USE_ANTIFLICKER_NORMAL_PAYLOAD
                o.antiflickerNormal = o.worldNormal;
                #endif
                o.worldPos.xyz = mul(unity_ObjectToWorld, i.vertex).xyz;
                #if defined(ENABLE_EMISSION_ANGLE_DISAPPEAR)
                float3 emissionViewDirection = normalize(
                    _WorldSpaceCameraPos - o.worldPos.xyz);
                float emissionAngleDot = abs(dot(o.worldNormal, emissionViewDirection));
                o.emissionAngle = smoothstep(0.0, 1.0, saturate(
                                                 (emissionAngleDot - 0.05) / (_EmissionThresholdAngle
                                                     - 0.05)));
                #endif
                #if defined(REFLECTION_TEXTURE)
                float3 reflectionTextureViewDirection = normalize(
                    _WorldSpaceCameraPos - o.worldPos.xyz);
                o.reflectionTextureRimFactor = saturate(
                    _RimOffset + 1.0 - dot(o.worldNormal, reflectionTextureViewDirection));
                o.reflectionTextureDirection = reflect(
                    -reflectionTextureViewDirection, o.worldNormal);
                #elif defined(ENABLE_RIM_DIM)
                float3 rimViewDirection = normalize(_WorldSpaceCameraPos - o.worldPos.xyz);
                float rimNormalDot = dot(o.worldNormal, rimViewDirection);
                #if defined(INVERT_RIM_DIM)
                float rimFacing = saturate(rimNormalDot + _RimOffset);
                #else
                float rimFacing = saturate(1.0 + _RimOffset - rimNormalDot);
                #endif
                float rimDistance = max(
                        distance(_WorldSpaceCameraPos, o.worldPos.xyz) - _RimDistanceOffset, 0.0) *
                    _RimDistanceScale + _RimScale;
                o.rimDim = rimDistance * rimFacing;
                #endif
                o.screenPos = ComputeScreenPosCustom(o.vertex);
                #if USE_NOISE_SCREEN_POSITION
                o.noiseScreenPos.xy = o.screenPos.xy * _GlobalBlueNoiseParams;
                o.noiseScreenPos.xy += o.vertex.w * _GlobalRandomValue + unity_ObjectToWorld._m03_m13;
                o.noiseScreenPos.zw = o.vertex.zw;
                #endif
                #if defined(MESH_PACKING) && \
                    !USE_MESH_PACKING_UV1
                float meshPackingID = UNITY_ACCESS_INSTANCED_PROP(Props, _MeshPackingId);
                float packingCull = abs(i.packingUv.y - meshPackingID) > 0.1;
                o.vertex.xyz = packingCull ? 0 : o.vertex.xyz;
                #endif
                #if defined(COLOR_ARRAY)
                o.colorArrayId.x = i.uv2.x;
                o.colorArrayId.y = i.uv2.y +
                    UNITY_ACCESS_INSTANCED_PROP(Props, _ColorsArrayOffset);
                #endif

                return o;
            }


            float4 frag(v2f i, float facing : VFACE) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);

                #if USE_SECONDARY_UV
                float2 uv2 = i.uv.zw;
                #else
                float2 uv2 = i.uv.xy;
                #endif

                float4 baseColor = UNITY_ACCESS_INSTANCED_PROP(Props, _Color);
                #if defined(UV_COLOR_SEGMENTS)
                baseColor = i.uvSegmentColor;
                #endif
                #if defined(COLOR_ARRAY) && !defined(_EMISSIONCOLORTYPE_MAINEFFECT)
                float colorIndex = round(i.colorArrayId.x * 10 + i.colorArrayId.y);
                float4 arrayColor = _ColorsArray[colorIndex];
                baseColor.rgb = arrayColor.rgb * _Intensity;
                baseColor.a = arrayColor.a * _AlphaMultiplier;
                #endif
                #if defined(_VERTEXMODE_COLOR)
                baseColor *= i.color;
                #endif

                // Always start from black — baseColor contributes only via diffuse/ambient,
                // matching SimpleLit's behaviour so objects are pitch dark without emission or lights.
                float4 albedo = 0;
                baseColor = ResolveSurfaceBaseColor(
                    i.uv.xy, baseColor, _InputUvMultiplier, _Smoothness,
                    _AlbedoMultiplier, _DiffuseTex, _DiffuseTex_ST,
                    _MetalSmoothnessTex, _MetalSmoothnessTex_ST);

                float3 worldPos = i.worldPos;

                #if defined(DISSOLVE)
                float dissolveTime = _Time.y + UNITY_ACCESS_INSTANCED_PROP(Props, _TimeOffset);
                float dissolveFactor = ResolveDissolve(
                    worldPos, i.uv.xy, dissolveTime, facing,
                    _DissolveAxisVector, _DissolveOffset, _DissolveProgress,
                    _DissolveStartValue, _DissolveEndValue, _InvertDissolve,
                    _CutColorFalloff, _CutColorBacksideFalloff,
                    _DissolveColor.a,
                    _DissolveTexture, _DissolveTexture_ST,
                    _DissolveTextureSpeed, _DissolveTextureInfluence);
                #endif
                #if USE_WORLD_NORMAL
                #if defined(PRECISE_NORMAL)
                float3 worldNormal = normalize(i.worldNormal);
                #else
                float3 worldNormal = i.worldNormal;
                #endif
                #else
                float3 worldNormal = 1;
                #endif
                #if USE_NORMAL_MAP_PAYLOAD
                worldNormal = ResolveSurfaceNormal(
                    i.uv.xy, worldNormal, i.tangentWS, i.bitangentWS,
                    _InputUvMultiplier, _NormalTexture, _NormalTexture_ST,
                    _NormalScale);
                #endif

                // Composable lighting boundary. The canonical structures feed the
                // single feature-composed output path in source order.
                SurfaceData composableSurface = InitializeSurfaceData(
                    worldPos, worldNormal, i.uv.xy, uv2, baseColor,
                    _Metallic, _Smoothness);
                #if defined(LIGHTMAP)
                composableSurface.lightmapUv = i.lightmapUv;
                #endif
                #if USE_VERTEX_COLOR
                ResolveSurfaceMaterial(
                    composableSurface, i.color, _Metallic, _Smoothness,
                    _InputUvMultiplier, _MetalSmoothnessTex,
                    _MetalSmoothnessTex_ST, _DirtTex, _DirtTex_ST,
                    _OcclusionIntensity, _DirtDetailTex, _DirtDetailTex_ST,
                    UNITY_ACCESS_INSTANCED_PROP(Props, _OcclusionDetailIntensity),
                    UNITY_ACCESS_INSTANCED_PROP(Props, _EmissionMaskIntensity));
                #else
                ResolveSurfaceMaterial(
                    composableSurface, 1.0, _Metallic, _Smoothness,
                    _InputUvMultiplier, _MetalSmoothnessTex,
                    _MetalSmoothnessTex_ST, _DirtTex, _DirtTex_ST,
                    _OcclusionIntensity, _DirtDetailTex, _DirtDetailTex_ST,
                    UNITY_ACCESS_INSTANCED_PROP(Props, _OcclusionDetailIntensity),
                    UNITY_ACCESS_INSTANCED_PROP(Props, _EmissionMaskIntensity));
                #endif
                // The lighting library takes per-material inputs as arguments
                // instead of reading uniforms it cannot assume are declared.
                #if defined(UNITY_INSTANCING_ENABLED)
                float3 nominalDiffuseLevel =
                    UNITY_ACCESS_INSTANCED_PROP(Props, _NominalDiffuseLevel).rgb;
                #else
                float3 nominalDiffuseLevel = _NominalDiffuseLevel.rgb;
                #endif
                #if defined(UNITY_INSTANCING_ENABLED) && !USE_UNIFORM_PRIVATE_POINT_COLOR
                float3 privatePointLightColor =
                    UNITY_ACCESS_INSTANCED_PROP(Props, _PrivatePointLightColor).rgb;
                #else
                float3 privatePointLightColor = _PrivatePointLightColor.rgb;
                #endif
                float3 ambientLight = CalculateAmbient(
                    nominalDiffuseLevel, _AmbientMinimalValue, _AmbientMultiplier);
                LightingData composableLighting = ResolveLitDirectLighting(
                    composableSurface, ambientLight, privatePointLightColor,
                    _LightMap1, _LightMap2,
                    _LightmapLightBakeIdA, _LightmapLightBakeIdB,
                    _LightmapLightBakeIdC, _LightmapLightBakeIdD,
                    _LightmapLightBakeIdE, _LightmapLightBakeIdF,
                    _BothSidesDiffuseMultiplier, _SpecularIntensity,
                    _GroundFadeScale, _GroundFadeOffset);
                float3 composableReflectionNormal = worldNormal;
                #if USE_ANTIFLICKER_NORMAL_PAYLOAD && \
                    !defined(_VERTEXMODE_METALSMOOTHNESS)
                composableReflectionNormal = dot(worldNormal, worldNormal) >= 1.01
                                                 ? i.antiflickerNormal
                                                 : worldNormal;
                #endif
                #if defined(REFLECTION_TEXTURE)
                float composableReflectionTextureRimDim =
                    CalculateLitReflectionTextureRimDim(
                        worldPos, i.reflectionTextureRimFactor,
                        _RimDistanceOffset, _RimDistanceScale, _RimScale);
                composableLighting.reflection = ResolveLitReflectionTexture(
                    composableSurface, i.reflectionTextureDirection,
                    composableReflectionTextureRimDim,
                    _EnvironmentReflectionCube, _ReflectionTexIntensity,
                    _RimSmoothness, _RimDarkening);
                #else
                #if defined(ENABLE_RIM_DIM)
                float composableRimDim = i.rimDim;
                #else
                float composableRimDim = 0.0;
                #endif
                composableLighting.reflection = ResolveLitReflection(
                    composableSurface, composableReflectionNormal,
                    composableRimDim,
                    _ReflectionProbeTexture1, _ReflectionProbeTexture2,
                    _LightProbeLightBakeIdA, _LightProbeLightBakeIdB,
                     _LightProbeLightBakeIdC, _LightProbeLightBakeIdD,
                     _LightProbeLightBakeIdE, _LightProbeLightBakeIdF,
                     _ReflectionProbeIntensity,
                     _ReflectionProbeGrayscale,
                     _ColoredMetalMultiplier,
                     _WhiteOffset,
                     _ReflectionProbeBoundsMin, _ReflectionProbeBoundsMax,
                    _ReflectionProbePosition,
                    _ReflectionProbeBoxProjectionSizeOffset,
                    _ReflectionProbeBoxProjectionPositionOffset,
                    _RimSmoothness, _RimDarkening,
                    _AntiflickerDistanceOffset, _AntiflickerDistanceScale,
                    _AntiflickerStrength,
                    _GroundFadeScale, _GroundFadeOffset);
                #endif
                EmissionData composableEmission = InitializeEmissionData();
                float4 composableTime = ResolveTime(
                    UNITY_ACCESS_INSTANCED_PROP(Props, _TimeOffset));

                albedo += ComposeLitLighting(composableLighting);

                #if defined(_HOLOGRAM_GRID) || defined(_HOLOGRAM_SCANLINE) || defined(_HOLOGRAM_LEGACY)
                #if defined(_HOLOGRAM_GRID)
                albedo = ApplyHologram(
                    albedo, worldPos, i.hologramObjectPosition, composableTime,
                    _TimeHelperOffset, _HologramGridSize, _HologramScanDistance,
                    _HoloIntensity,
                    UNITY_ACCESS_INSTANCED_PROP(Props, _HaltScan),
                    UNITY_ACCESS_INSTANCED_PROP(Props, _HologramStripeSpeed),
                    UNITY_ACCESS_INSTANCED_PROP(Props, _HologramPhaseOffset),
                    UNITY_ACCESS_INSTANCED_PROP(Props, _HologramFill),
                    UNITY_ACCESS_INSTANCED_PROP(Props, _HologramColor));
                #elif defined(_HOLOGRAM_SCANLINE)
                albedo = ApplyHologram(
                    albedo, worldPos, 0.0.xxx, composableTime,
                    _TimeHelperOffset, 0.0, _HologramScanDistance,
                    _HoloIntensity,
                    UNITY_ACCESS_INSTANCED_PROP(Props, _HaltScan),
                    UNITY_ACCESS_INSTANCED_PROP(Props, _HologramStripeSpeed),
                    UNITY_ACCESS_INSTANCED_PROP(Props, _HologramPhaseOffset),
                    0.0,
                    UNITY_ACCESS_INSTANCED_PROP(Props, _HologramColor));
                #else
                albedo = ApplyHologram(
                    albedo, worldPos, 0.0.xxx, composableTime,
                    _TimeHelperOffset, _HologramGridSize, 0.0, 0.0,
                    0.0, 0.0, 0.0, 0.0,
                    UNITY_ACCESS_INSTANCED_PROP(Props, _HologramColor));
                #endif
                #endif

                #if defined(DISTANCE_DARKENING)
                albedo.rgb *= CalculateSourceDistanceDarkening(
                    worldPos, _DarkeningCenter, _DarkeningDirection,
                    _DarkeningScale, _DarkeningIntensity);
                #endif

                #if defined(OCCLUSION) && defined(OCCLUSION_BEFORE_EMISSION)
                albedo.rgb *= composableSurface.occlusion;
                #endif
                #if defined(OCCLUSION_DETAIL)
                albedo.rgb *= composableSurface.occlusionDetail;
                #endif

                // EMISSION
                #if defined(ACES_TONE_MAPPING) && defined(_ACES_APPROACH_BEFORE_EMISSIVE)
                albedo = ApplyAcesTonemapping(albedo);
                #endif

                #if defined(_PARALLAX_FLEXIBLE) || defined(_PARALLAX_RGB)
                #if USE_VERTEX_COLOR
                albedo = ApplyParallax(
                    albedo, composableSurface, i.color,
                    _InputUvMultiplier, UNITY_ACCESS_INSTANCED_PROP(Props, _TimeOffset),
                    _ParallaxTexSpeed, _ParallaxIntensity, _ParallaxIntensity_Step,
                    _Layers, _StartOffset, _OffsetStep,
                    _IridescenceColorInfluence,
                    _ParallaxMap, _ParallaxMap_ST,
                    _ParallaxMaskingMap, _ParallaxMaskingMap_ST,
                    _ParallaxMaskSpeed, _ParallaxMaskIntensity,
                    _IridescenceAxesMultiplier, _IridescenceTiling,
                    _ParallaxColor);
                #else
                albedo = ApplyParallax(
                    albedo, composableSurface, 1.0.xxxx,
                    _InputUvMultiplier, UNITY_ACCESS_INSTANCED_PROP(Props, _TimeOffset),
                    _ParallaxTexSpeed, _ParallaxIntensity, _ParallaxIntensity_Step,
                    _Layers, _StartOffset, _OffsetStep,
                    _IridescenceColorInfluence,
                    _ParallaxMap, _ParallaxMap_ST,
                    _ParallaxMaskingMap, _ParallaxMaskingMap_ST,
                    _ParallaxMaskSpeed, _ParallaxMaskIntensity,
                    _IridescenceAxesMultiplier, _IridescenceTiling,
                    _ParallaxColor);
                #endif
                #endif

                #if USE_EMISSION_TEXTURE_COLOR
                #if defined(_EMISSIONTEXTURE_FLIPBOOK)
                composableEmission = ResolveFlipbookEmission(
                    i.flipbookUv, i.flipbookFrameSelector,
                    _EmissionTex, _EmissionTex_ST, _EmissionBrightness,
                    UNITY_ACCESS_INSTANCED_PROP(Props, _EmissionTexColor),
                    _EmissionTexBloomIntensity);
                albedo = ComposeEmission(albedo, composableEmission);
                #if USE_VERTEX_EMISSION
                EmissionData flipbookVertexEmission = ResolveVertexEmission(i.color, i.emission,
                    _EmissionThreshold, _EmissionStrength,
                    _BaseColorBoost, _BaseColorBoostThreshold,
                    _QuestWhiteboostMultiplier, _EmissionBloomIntensity);
                albedo.rgb += flipbookVertexEmission.color;
                albedo.a += flipbookVertexEmission.bloomAlpha;
                #endif
                #else
                #if defined(COLOR_ARRAY)
                float2 composableColorArrayId = i.colorArrayId;
                #else
                float2 composableColorArrayId = 0.0;
                #endif
                #if defined(ENABLE_EMISSION_ANGLE_DISAPPEAR)
                float composableEmissionAngle = i.emissionAngle;
                #else
                float composableEmissionAngle = 1.0;
                #endif
                #if defined(TEXTURE3D_LOOKUP) && defined(TEXTURE3D_EMISSION)
                float composableLookupEmission = i.lookupEmission;
                #else
                float composableLookupEmission = 1.0;
                #endif
                composableEmission = ResolveFeatureEmission(
                    composableSurface, composableTime, composableColorArrayId,
                    composableEmissionAngle, composableLookupEmission,
                    _InputUvMultiplier, _EmissionBrightness,
                    _EmissionTex, _EmissionTex_ST, _EmissionTexSpeed,
                    _PulseMask, _PulseMask_ST,
                    _PulseWidth, _PulseSpeed, _PulseSmooth,
                    _EmissionTexBloomIntensity,
                    _DistortionTex, _DistortionTex_ST, _DistortionPanning,
                    _DistortionAxes,
                    UNITY_ACCESS_INSTANCED_PROP(Props, _DistortionStrength),
                    _EmissionMask, _EmissionMask_ST, _EmissionMaskSpeed,
                    UNITY_ACCESS_INSTANCED_PROP(Props, _EmissionMaskIntensity),
                    _SecondaryEmissionMask, _SecondaryEmissionMask_ST,
                    _SecondaryEmissionMaskSpeed,
                    UNITY_ACCESS_INSTANCED_PROP(
                        Props, _SecondaryEmissionMaskIntensity),
                    UNITY_ACCESS_INSTANCED_PROP(
                        Props, _OcclusionDetailIntensity),
                    UNITY_ACCESS_INSTANCED_PROP(
                        Props, _EmissionGradientPosition),
                    _EmissionGradientPanningSpeed,
                    _EmissionGradientTex, _EmissionGradientTex_ST,
                    UNITY_ACCESS_INSTANCED_PROP(
                        Props, _EmissionGradientIntensity),
                    _SDFPointArray, _SDFNegativeIntensity, _SDFPointIntensity,
                    UNITY_ACCESS_INSTANCED_PROP(Props, _SDFNoiseScale),
                    _SDFNoisePanning, _SDFNoiseOffset,
                    UNITY_ACCESS_INSTANCED_PROP(Props, _SDFNoiseIntensity),
                    _SDFNoiseTex,
                    _ColorsArray, UNITY_ACCESS_INSTANCED_PROP(Props, _EmissionTexColor),
                    _EmissionTexWhiteBoostMultiplier, _BaseColorBoost,
                    _BaseColorBoostThreshold);
                albedo.rgb += composableEmission.color;
                albedo.a += composableEmission.bloomAlpha;
                #endif
                #endif

                #if USE_VERTEX_EMISSION && !defined(_EMISSIONTEXTURE_FLIPBOOK)
                EmissionData composableVertexEmission = ResolveVertexEmission(
                    i.color, i.emission,
                    _EmissionThreshold, _EmissionStrength,
                    _BaseColorBoost, _BaseColorBoostThreshold,
                    _QuestWhiteboostMultiplier, _EmissionBloomIntensity);
                albedo.rgb += composableVertexEmission.color;
                albedo.a += composableVertexEmission.bloomAlpha;
                #endif

                #if defined(_RIMLIGHT_ADDITIVE)
                albedo = ApplyAdditiveRimLight(
                    albedo, worldPos, worldNormal,
                    _RimLightEdgeStart,
                    UNITY_ACCESS_INSTANCED_PROP(Props, _RimLightColor),
                    _RimLightIntensity, _RimLightBloomIntensity,
                    _RimPerpendicularAxis, _RimLightWhiteboostMultiplier,
                    _BaseColorBoost, _BaseColorBoostThreshold);
                #endif

                #if defined(OCCLUSION) && !defined(OCCLUSION_BEFORE_EMISSION)
                albedo.rgb *= composableSurface.occlusion;
                #if defined(_RIMLIGHT_ADDITIVE)
                albedo.a *= composableSurface.occlusion;
                #endif
                #endif

                #if defined(_RIMLIGHT_LERP)
                #if defined(UV_COLOR_SEGMENTS)
                albedo = ApplyRimLight(
                    albedo, worldPos, worldNormal, _RimLightEdgeStart,
                    i.uvSegmentRimColor, _RimLightIntensity,
                    _RimLightBloomIntensity,
                    _RimPerpendicularAxis, _RimLightWhiteboostMultiplier,
                    _BaseColorBoost, _BaseColorBoostThreshold);
                #else
                albedo = ApplyRimLight(
                    albedo, worldPos, worldNormal, _RimLightEdgeStart,
                    UNITY_ACCESS_INSTANCED_PROP(Props, _RimLightColor),
                    _RimLightIntensity, _RimLightBloomIntensity,
                    _RimPerpendicularAxis, _RimLightWhiteboostMultiplier,
                    _BaseColorBoost, _BaseColorBoostThreshold);
                #endif
                #endif

                #if defined(ACES_TONE_MAPPING) && !defined(_ACES_APPROACH_BEFORE_EMISSIVE)
                albedo = ApplyAcesTonemapping(albedo);
                #endif

                #if defined(HIGHLIGHT_SELECTION)
                albedo = ApplyHighlightSelection(
                    albedo, worldPos, composableTime, i.highlightSelection);
                #endif

                // Apply dissolve edge color
                #if defined(DISSOLVE) && defined(DISSOLVE_COLOR)
                albedo.rgb = lerp(albedo.rgb, _DissolveColorIntensity * _DissolveColor.rgb, dissolveFactor);
                #endif

                #if defined(COLOR_BY_FOG) && \
                    !defined(_HOLOGRAM_GRID) && !defined(_HOLOGRAM_LEGACY)
                albedo = ApplyColorFog(
                    albedo, worldPos, _ColorFogMultiplier, _ColorFogMax,
                    _ColorFogHighlightMultiplier, _ColorFogInfluence,
                    _FogHeightScale, _FogHeightOffset);
                #endif

                // Terminal fog composition — bloom fog, height fog, and blue-noise
                // dithering are applied as separate passes so the fog handling
                // lives in Fog.hlsl and PostProcess.hlsl.
                #if defined(BLOOM_FOG) && defined(FOG) && \
                    !defined(_HOLOGRAM_GRID) && !defined(_HOLOGRAM_LEGACY)
                #if defined(HEIGHT_FOG)
                float customFogFactor = CalculateCustomFogFactor(
                    distanceSquared(worldPos), _FogStartOffset, _FogScale);
                float customHeightFogFactor = CalculateBloomFogHeightFactor(
                    worldPos, _FogHeightOffset, _FogHeightScale,
                    _FogSoften, _FogSoftenOffset);
                albedo = ApplyBloomHeightFogCalculatedFactor(
                    albedo, i.screenPos, customFogFactor, customHeightFogFactor);
                #else
                albedo = ApplyBloomFog(
                    albedo, i.screenPos, worldPos, _FogStartOffset, _FogScale);
                #endif
                #elif defined(FOG) && defined(HEIGHT_FOG) && \
                    !defined(COLOR_BY_FOG) && \
                    !defined(_HOLOGRAM_GRID) && !defined(_HOLOGRAM_LEGACY)
                #if defined(HEIGHT_FOG_DEPTH_SOFTEN)
                albedo = ApplySoftenedHeightFog(
                    albedo, worldPos,
                    _FogHeightScale, _FogHeightOffset,
                    _FogSoften, _FogSoftenOffset);
                #else
                albedo = ApplyHeightFog(
                    albedo, worldPos, _FogHeightScale, _FogHeightOffset);
                #endif
                #endif

                #if defined(NOISE_DITHERING)
                #if USE_NOISE_SCREEN_POSITION
                albedo = ApplyNoiseDither(albedo, i.noiseScreenPos, _GlobalBlueNoiseTex);
                #else
                albedo = ApplyNoiseDither(albedo, 0.0, _GlobalBlueNoiseTex);
                #endif
                #endif
                return albedo;
            }
            ENDHLSL
        }
    }
}
