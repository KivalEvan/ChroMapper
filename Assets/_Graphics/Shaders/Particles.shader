// Replacement for the Beat Saber game shader Custom/CustomParticles.
Shader "ChroMapper/Particles"
{
    // AUDIT FINDINGS (Beat Saber 1.44.3)
    // CP1. The 1.42.2 Custom/CustomParticles Properties block is authoritative:
    //      238 ordered properties with established ChroMapper aliases only.
    // CP2. The recovered corpus contains 16,640 variants and 1,574 unique DXBC
    //      binaries. The global matrix inventory is recorded in CP36. All production
    //      routes represented by a corpus row compile here. CP10 lists selectors
    //      that have no recovered corpus row.
    // CP3. MAIN_EFFECT_ENABLED maps to POST_BLOOM, ENABLE_BLOOM_FOG maps to
    //      BLOOM_FOG, and material ENABLE_* keywords use their normalized names.
    // CP4. _WHITEBOOSTTYPE_MAINEFFECT compiles boost out under POST_BLOOM;
    //      _WHITEBOOSTTYPE_ALWAYS retains it. Remapping affects only boost input.
    // CP5. DISTORTION_SIMPLE is the authoritative simple-distortion keyword.
    //      DISTORTION_TARGET_MASK is binary-inert in every shipped 1.44.3 state.
    // CP6. Vertex color channel selection is independent from alpha squaring.
    //      Red-as-alpha changes only the alpha source. A mode leaves RGB owned by
    //      the base material/MPB color. The RGB-only selector has no corpus row.
    // CP7. Full, Y-axis, and camera-facing billboards preserve their distinct
    //      recovered bases. Full billboard fog position intentionally remains the
    //      unmodified object vertex, matching vertex 98bda790d7ce5d9c.
    // CP8. Custom wrapping and blue-noise coordinates follow fragments
    //      cef90552ffd515a3 and f6b512c446c16492 rather than generic approximations.
    // CP9. All nine unique Prodigy keyword sets match exact mono and stereo table
    //      rows. Earlier unresolved-set counts mixed a broader exported inventory
    //      with the environment-specific material inventory.
    // CP10. OVERDRAW_VIEW is diagnostic and remains omitted. The following declared
    //       keywords have zero rows in _variants.csv, so there is no production binary
    //       hash from which to recover their math: ROTATE_UV, ROTATE_MAIN_ONLY, REVEAL,
    //       DISSOLVE_COLOR/TEXTURE/TEXTURE_MULTIPLY/PROGRESS, GRADIENT_ALPHA,
    //       VERTEX_DISPLACEMENT, VERTEX_DISPLACEMENT_COLOR, _VERTEXCHANNELS_RGB,
    //       _ALPHACHANNEL_TEXTURE_BLEND, _DIAGONAL_CHANNEL, DISTORTION_FLOWMAP,
    //       DISTORTION_TARGET_MASK2, secondary UV TRAILS/OBJECT_SPACE/FLOWMAP/
    //       DISPLACEMENT/EROSION, all per-particle random routes except MAIN,
    //       MOTION_VECTORS, NOTE_VERTEX_DISTORTION, GREEN_CHANNEL_WHITEBOOST,
    //       VERTEX_START_END, WORLD_NOISE, EROSION and its source routes,
    //       _DISSOLVE_SPACE_UV and all dissolve-grid routes, _CUTOUTTYPE_SCALE,
    //       _OVERRIDE_FINAL_ALPHA_FLAT, CHROMATIC_ABERRATION, all rim-light routes,
    //       _CURVE_VERTICES_AROUND_X/Y, and _SPECTROGRAM_FLAT.
    //       EMISSION_3D_TEX is likewise unrepresented. No formula is invented for them.
    // CP11. MAIN_PER_PARTICLE_RANDOM is retained in both stages for keyword-set
    //       identity. Its recovered vertex 8a3c8f3abc9cc82c is byte-identical to
    //       active MAIN_TEXTURE-only routes; UV time/instance offset is shared.
    // CP12. Active color-pipeline contracts are renderer-neutral: ParticleSystemRenderer
    //       start color and MeshRenderer vertex color enter as raw COLOR, while
    //       SpriteRenderer color is applied once after base/vertex composition.
    //       Gaga A-only vertex 664453940ed6f426 and fragments 97633975ff8242d0
    //       and a1de6c28d2c2bc24 keep RGB in effective _Color and use COLOR.w only
    //       for alpha. VERTEX_SQUARE_ALPHA is vertex 680a9e19 with fragment
    //       a07d89c2029583eb; SECONDARY_COLOR is fragment c347aec55350b829;
    //       COLOR_ARRAY plus VERTEX_COLOR is vertex 6a1bdbd1ae957d1e and fragment
    //       5f2886e66f649c15. Spectrogram color is vertex d2178af6c7f7f78f with
    //       fragment a3f22f0c5d7e57a1. These active routes preserve all three
    //       renderer contracts.
    // CP13. The recoverable inactive production cluster is represented by vertex
    //       2c574604de1e85ca954a4082b43ec3967814c6d6dcf1959c9b528c0d975988d8
    //       and fragment
    //       5431f008df503651ec5b2ba6df53a167b5bd851cf049b005ede0b5b2d1d15d7b:
    //       external-scale/main secondary UVs, world-space panning, color-by-fog
    //       highlight/primary-mask, fill/color override, and world-noise cutout.
    //       Plane clipping and distortion-secondary/world-panning are cross-checked
    //       by fragment
    //       4eed5d58254824a2fe2923799305661cb58c989b6c51b6726898d2852eff1c6d.
    // CP14. Remaining proven fixes use fragments 4eed5d58254824a2fe2923799305661cb58c989b6c51b6726898d2852eff1c6d and
    //       5431f008df503651ec5b2ba6df53a167b5bd851cf049b005ede0b5b2d1d15d7b:
    //       distortion coordinates initialize independently of SECONDARY_COLOR; FILL_ALPHA
    //       selects its mask/color and max-combines premultiplied fill RGB before final alpha.
    // CP15. Prodigy crowd fragment 953990a3053f67d9 clips the selected packed
    //       frame before fog, then applies height-fog LERP, dither, alpha, square
    //       alpha, and premultiplication. Vertex 5ef6afe6d212829d uses
    //       _Time + _TimeHelperOffset + _TimeOffset - _StartTime and loops only
    //       the cells after _FlipbookNonloopableFrames.
    // CP16. All 18 unique Coldplay material keyword sets match exact mono and
    //       stereo recovered rows. None selects packed texture flipbook sampling.
    // CP17. Grid fake-mirror fragment 0acfd9a96e1b5eca scales its final RGB and
    //       alpha by _FakeMirrorTransparency squared times _BloomMultiplier.
    // CP18. Halloween 2 cutout fragment 40d13975545fd678 clips main texture
    //       alpha times material alpha before fog, then applies LERP fog,
    //       dither, alpha multiplication, square alpha, and premultiplication.
    // CP19. Corpus-wide route review assigns packed timing to TEXTURE_FLIPBOOK
    //       and early source-alpha clipping to _CUTOUTTYPE_ALPHA_CLIP. _BaseLayer
    //       scales sampled RGB only; fragments 2b5ddcbb1144c55d and
    //       14f09f6316d7d72b prove that it does not scale sampled alpha.
    // CP20. All 14 unique Metallica particle keyword sets match exact mono and
    //       stereo recovered rows. Existing billboard, packed flipbook, gradient,
    //       vertex-alpha dissolve, mip-angle fade, fog, and bloom stages cover them.
    // CP21. All ten unique Monstercat 2 particle keyword sets match exact mono
    //       and stereo recovered rows. Existing distortion, fog, alpha, bloom,
    //       and fake-mirror stages cover them.
    // CP22. All 12 unique Britney particle keyword sets match exact mono and
    //       stereo recovered rows. Orphan distortion selectors remain inert,
    //       and soft depth requires its runtime depth-texture parent.
    // CP23. All eight unique Collider particle keyword sets match exact mono
    //       and stereo recovered rows. Collider adds no new particle predicate.
    // CP24. All 11 unique Hip Hop particle keyword sets match exact mono and
    //       stereo recovered rows. MESH_PACKING reads its independent packed
    //       id from the additional UV stream instead of vertex color green.
    // CP25. All 14 unique Daft Punk particle keyword sets match exact mono and
    //       stereo recovered rows. Daft Punk adds no new particle predicate.
    // CP26. All eight unique Lattice particle keyword sets match exact mono and
    //       stereo recovered rows. Lattice adds no new particle predicate.
    // CP27. All six unique Rolling Stones particle keyword sets match exact mono
    //       and stereo recovered rows. Rolling Stones adds no new predicate.
    // CP28. All eight unique Queen particle keyword sets match exact mono and
    //       stereo recovered rows. Color-fog dither runs after the 0.1 RGB scale.
    // CP29. Linkin Park 2, Panic 2, and Dragons 2 particle routes match exact
    //       mono and stereo rows. They add no new executable particle predicate.
    // CP30. Rock Mixtape, The Weeknd, and Lizzo particle routes match exact mono
    //       and stereo rows. They add no new executable particle predicate.
    // CP31. The Second, EDM, Pyro, and Weave particle routes match exact mono and
    //       stereo rows. Pyro limits mip bias to texture sampling.
    // CP32. Gaga and original Halloween (Spooky) particle routes match exact
    //       mono and stereo rows. They add no new executable particle predicate.
    // CP33. Billie and Skrillex particle routes match exact mono and stereo rows.
    //       They add no new executable particle predicate.
    // CP34. Interscope and Kaleidoscope particle routes match exact mono and
    //       stereo rows. They add no new executable particle predicate.
    // CP35. BTS and original Linkin Park particle routes match exact mono and
    //       stereo rows. They add no new executable particle predicate.
    // CP36. The global matrix reaudit covers 44 matrices, 345 particle routes,
    //       103 canonical states, and 1,380 records. It contains 130 canonical
    //       vertex binaries and 204 canonical fragment binaries, with zero
    //       unresolved records or hash mismatches.
    // CP37. The 13 legacy matrices add one Green Day state and no new particle
    //       predicate. R1 removes the duplicate vertex-alpha multiplication.
    //       R2 restores gradient/mask order and the unsaturated LUT coordinate.
    //       R3 restores raw time bases and per-site instance weights.
    // CP38. The final reaudit restores TEXTURE_COLOR RGB factors, independent
    //       mask and distortion coordinates, RGB-only height-fog LERP, and
    //       cross-stage declarations for shared vertex/fragment selectors.
    Properties
    {
		[BigHeader(COLOR)] [Space(18)] _Color ("Base Color", Vector) = (1,1,1,1)
		[Space(18)] [Toggle(COLOR_BY_FOG)] _EnableObstacle ("Color by Fog", Float) = 0
		[InfoBox(Error Texture mask is planned but not implemented yet, 2, COLOR_BY_FOG, _FOG_MASK_SOURCE_TEXTURE)] [InfoBox(Error Mask feature is not enabled, 3, COLOR_BY_FOG, _FOG_MASK_SOURCE_PRIMARY_MASK, 0MASK)] [EnumShowIfAny(3, None, Texture, Primary Mask, COLOR_BY_FOG)] _Fog_Mask_Source ("Fog Mask Source", Float) = 0
		[ShowIfAny(COLOR_BY_FOG)] _ObstacleFogMultiplier ("Fog Multiplier", Float) = 1
		[ShowIfAny(COLOR_BY_FOG)] _ObstacleFogMax ("Fog Max Brightness", Float) = 1
		[ShowIfAny(COLOR_BY_FOG)] _ObstacleColorInfluence ("Color Influence", Range(0, 1)) = 0.5
		[ToggleShowIfAny(FOG_COLOR_HIGHLIGHT, COLOR_BY_FOG)] _FogColorHighlight ("Use Fog Highlight", Float) = 0
		[ShowIfAny(2, COLOR_BY_FOG, FOG_COLOR_HIGHLIGHT)] _ObstacleFogHighlightMultiplier ("Fog Highlight Multiplier", Float) = 30000
		[Space(12)] [Toggle(SECONDARY_COLOR)] _EnableSecondaryColor ("Use Secondary Color", Float) = 0
		[ShowIfAny(SECONDARY_COLOR)] _SecondaryColor ("Secondary Color", Vector) = (1,1,1,1)
		[ShowIfAny(SECONDARY_COLOR)] _SecondaryColorTex ("Secondary Color Texture", 2D) = "white" {}
		[ShowIfAny(SECONDARY_COLOR)] _SecondaryColorPanning ("Secondary Color Panning", Vector) = (0,0,0,0)
		[Space(12)] [Toggle(COLOR_GRADIENT)] _UseColorGradient ("Use Color Gradient", Float) = 0
		[ShowIfAny(COLOR_GRADIENT)] _ColorGradient ("Gradient LUT", 2D) = "white" {}
		[ToggleShowIfAny(GRADIENT_ALPHA, COLOR_GRADIENT)] _GradientUseAlpha ("Use Gradient Alpha", Float) = 0
		[ShowIfAny(COLOR_GRADIENT)] _GradientPosition ("Gradient Position", Range(0, 1)) = 0.5
		[ShowIfAny(COLOR_GRADIENT)] _GradientPanningSpeed ("Gradient Panning Speed", Float) = 0
		[Space(12)] [Toggle(SPECTROGRAM_COLOR)] _UseSpectrogram ("Color by Spectrogram", Float) = 0
		[InfoBox(Spectrogram Color relies on uv3 where x defines column and y height, SPECTROGRAM_COLOR)] [InfoBox(ERROR Do not use Spectrogram Color with Flat Spectrogram Displacement, 2, SPECTROGRAM_COLOR, _SPECTROGRAM_FLAT)] [ShowIfAny(SPECTROGRAM_COLOR)] _SpectrogramBaseValue ("Spectrogram Base Value", Range(0, 1)) = 0.2
		[ShowIfAny(SPECTROGRAM_COLOR)] _SpectrogramRange ("Spectrogram Range", Range(0, 1)) = 0.2
		[Space(12)] [Toggle(COLOR_ARRAY)] _UseColorArray ("Use Color Array", Float) = 0
		[BigHeader(OVERARCHING FEATURES)] [Space(18)] [KeywordEnum(None, Import, External Scale, Trails, Object Space)] _Secondary_UVs ("Secondary UVs", Float) = 0
		[InfoBox(INFO Avoid nested scale and use with Material Property Block Local Scale Animator for best results, _SECONDARY_UVS_OBJECT_SPACE)] [SpaceShowIfAny(10, _SECONDARY_UVS_EXTERNAL_SCALE, _SECONDARY_UVS_OBJECT_SPACE)] [ShowIfAny(_SECONDARY_UVS_EXTERNAL_SCALE, _SECONDARY_UVS_OBJECT_SPACE)] _UVScale ("UV Scale", Vector) = (1,1,1,1)
		[InfoBox(Use this offset manually updated via C# instead of texture panning if scale changes during gameplay to avoid artifacts, _SECONDARY_UVS_OBJECT_SPACE, _SECONDARY_UVS_EXTERNAL_SCALE)] [ShowIfAny(_SECONDARY_UVS_EXTERNAL_SCALE, _SECONDARY_UVS_OBJECT_SPACE)] _UVManualOffset ("UV Manual Offset", Vector) = (0,0,0,0)
		[HideInInspector] _EnableRotateUV ("Rotate UVs 90", Float) = 0
		[HideInInspector] _RotateUV ("Rotation Angle", Float) = 0
		[HideInInspector] _RotateMainUVOnly ("Rotate Main UV Only", Float) = 0
		[Space(12)] [Toggle(WORLDSPACE_PANNING)] _WorldspacePanning ("Worldspace Panning", Float) = 0
		[ShowIfAny(WORLDSPACE_PANNING)] _WorldspacePanningSpeed ("Panning Speed", Float) = 1
		[Space(12)] [InfoBox(Useful for noise based particles _ Requires Stable Random Stream added _ More details on Confluence, PARTICLE_VERTEX_STREAM)] [Toggle(PARTICLE_VERTEX_STREAM)] _UsesParticleVertexStream ("Uses Particle Vertex Stream", Float) = 0
		[BigHeader(VERTEX FEATURES)] [Space(18)] [Toggle(VERTEX_START_END)] _EnableStartEnd ("Start to End Features", Float) = 0
		[InfoBox(Allows small tweaks to vertices of a rectangular mesh alongside its vertical UV, VERTEX_START_END)] [ShowIfAny(VERTEX_START_END)] _AlphaStart ("Alpha Start", Float) = 1
		[ShowIfAny(VERTEX_START_END)] _AlphaEnd ("Alpha End", Float) = 1
		[ShowIfAny(VERTEX_START_END)] _WidthStart ("Width Start", Float) = 1
		[ShowIfAny(VERTEX_START_END)] _WidthEnd ("Width End", Float) = 1
		[Space(12)] [Toggle(VERTEX_COLOR)] _EnableVertexColor ("Enable Vertex Color", Float) = 0
		[ToggleShowIfAny(VERTEX_SQUARE_ALPHA, VERTEX_COLOR)] _SquareVertexAlpha ("Square Vertex Alpha", Float) = 0
		[ToggleShowIfAny(VERTEX_RED_IS_ALPHA, VERTEX_COLOR)] _RedIsVertexAlpha ("Red is Vertex Alpha", Float) = 0
		[EnumShowIfAny(2, RGBA, A, VERTEX_COLOR)] _VertexChannels ("Vertex Channels", Float) = 0
		[ToggleShowIfAny(LIFETIME, VERTEX_COLOR)] _EnableLifetime ("Enable Lifetime Alpha", Float) = 0
		[Space(12)] [Toggle(VERTEX_FLIPBOOK)] _EnableVertexFlipbook ("Enable Vertex Flipbook", Float) = 0
		[InfoBox(Frame in red color _ Offset to randomize in green color, VERTEX_FLIPBOOK)] [ShowIfAny(VERTEX_FLIPBOOK)] _VertexFlipbookCount ("Frame Count", Float) = 1
		[ShowIfAny(VERTEX_FLIPBOOK)] _VertexFlipbookSpeed ("Flipbook Speed", Float) = 1
		[ToggleShowIfAny(VERTEX_FLIPBOOK_FADE, VERTEX_FLIPBOOK)] _EnableVertexFlipbookFade ("Enable Flipbook Fade", Float) = 0
		[HideInInspector] _VertexDisplacement ("Use Vertex Displacement", Float) = 0
		[HideInInspector] _DisplacementSecondaryUVs ("Use Secondary UVs", Float) = 0
		[ShowIfAny(SPATIAL_DISPLACEMENT)] _DisplacementTex ("Mask Texture", 2D) = "white" {}
		[Toggle(SPATIAL_DISPLACEMENT)] _3DDisplacement ("3D Displacement", Float) = 0
		[HideInInspector] _DisplacementPerParticleRandomization ("Per Particle Randomization", Float) = 0
		[ShowIfAny(SPATIAL_DISPLACEMENT)] _DisplacementStrength ("Strength", Float) = 0.1
		[ShowIfAny(SPATIAL_DISPLACEMENT)] _DisplacementAxes ("Per Axis Strength", Vector) = (1,1,1,0)
		[ShowIfAny(SPATIAL_DISPLACEMENT)] _DisplacementPanningSpeed ("Panning Speed", Float) = 1
		[ShowIfAny(SPATIAL_DISPLACEMENT)] _DisplacementPanning ("Panning", Vector) = (0,0,0,0)
		[InfoBox(Full Spectrogram uses uv3 coords to map 64 spectrogram channels, 2, SPATIAL_DISPLACEMENT, _SPECTROGRAM_FULL)] [EnumShowIfAny(3, None, Flat, Full, SPATIAL_DISPLACEMENT)] _Spectrogram ("Spectrogram Influence", Float) = 0
		[ShowIfAny(_SPECTROGRAM_FULL)] _UV3Offset ("UV3 Offset", Float) = 0
		[ShowIfAny(_SPECTROGRAM_FULL)] _UV3Scale ("UV3 Scale", Float) = 1
		[Space(12)] [KeywordEnum(None, Around_X, Around_Y, Around_Z)] _Curve_Vertices ("Curve Vertices (Object Space)", Float) = 0
		[BigHeader(TEXTURE FEATURES)] [Space(10)] [Toggle(MAIN_TEXTURE)] _UseMainTex ("Base Texture", Float) = 1
		_BaseLayer ("Base Color", Float) = 1
		[Header(Main Texture)] [Space(12)] _MainTex ("Main Texture", 2D) = "black" {}
		[ToggleShowIfAny(SECONDARY_UVS_MAIN, _SECONDARY_UVS_TRAILS, _SECONDARY_UVS_EXTERNAL_SCALE, _SECONDARY_UVS_OBJECT_SPACE, _SECONDARY_UVS_IMPORT)] _MainTexSecondaryUVs ("Use Secondary UVs", Float) = 0
		[ToggleShowIfAny(WORLDSPACE_PANNING_MAIN, WORLDSPACE_PANNING)] _EnableMainTexWorldSpacePanning ("Add worldspace panning", Float) = 0
		[Toggle(PIXELATE)] _Pixelate ("Pixelate", Float) = 0
		[VectorShowIfAny(2, PIXELATE)] _PixelateResolution ("Pixelate Resolution", Vector) = (64,64,0,0)
		[ToggleShowIfAny(TEXTURE_COLOR, 0TEXTURE_FLIPBOOK)] _EnableTextureColor ("Use Texture Color", Float) = 0
		[Space(12)] [InfoBox(WARNING Distortion and Texture Flipbooks will not work with this feature, 1, _ALPHACHANNEL_TEXTURE_BLEND, TEXTURE_FLIPBOOK, DISTORTION_FLOWMAP, DISTORTION_SIMPLE)] [InfoBox(WARNING Billboard Y Axis should be used for this feature, 2, _ALPHACHANNEL_TEXTURE_BLEND, 0_BILLBOARD_Y_AXIS)] [InfoBox(Texture Channels are as follows The Red Channel is top and bottom The Blue channel is Left and Right The Green Channel is Diagonal Top and The Alpha Channel is Diagonal Bottom, _ALPHACHANNEL_TEXTURE_BLEND)] [EnumShowIfAny(3, Alpha, Red, Texture Blend, 0TEXTURE_COLOR)] _AlphaChannel ("Alpha Channel", Float) = 0
		[Space(12)] [ShowIfAny(2, _ALPHACHANNEL_TEXTURE_BLEND, 0_DIAGONAL_CHANNEL)] _TopBotFadeAngle ("Top/Bot Fade Angle", Range(0, 1)) = 0.5
		[ShowIfAny(2, _ALPHACHANNEL_TEXTURE_BLEND, 0_DIAGONAL_CHANNEL)] _LeftRightFadeAngle ("Left/Right Fade Angle", Range(0, 1)) = 0.5
		[ToggleShowIfAny(_DIAGONAL_CHANNEL)] _Diagonal_Channel ("Use Diagonal Channels", Float) = 0
		[ToggleShowIfAny(MAIN_PER_PARTICLE_RANDOM, PARTICLE_VERTEX_STREAM)] _MainPerParticleRandomization ("Per Particle Randomization", Float) = 0
		_Intensity ("Color Intensity", Float) = 1
		_UvPanning ("UV Panning", Vector) = (0,0,0,0)
		[Space(12)] [Toggle(CUSTOM_WRAPPING)] _EnableCustomPadding ("Custom Repeat Wrapping", Float) = 0
		[InfoBox(Texture must have Clamp wrapping mode, CUSTOM_WRAPPING)] [VectorShowIfAny(2, CUSTOM_WRAPPING)] _CustomPadding ("Custom Padding", Vector) = (0,0,0,0)
		[Space(12)] [Toggle(TEXTURE_FLIPBOOK)] _UseTextureFlipbook ("Use Texture Flipbook", Float) = 0
		[InfoBox(Keep in sRGB or alpha will have different intensity, TEXTURE_FLIPBOOK)] [InfoBox(Frame 1 contains frames 1234 in RGBA channels Frame 2 contains 4567 (5678 if blending is disabled), TEXTURE_FLIPBOOK)] [ShowIfAny(TEXTURE_FLIPBOOK)] _FlipbookColumns ("Flipbook Columns", Float) = 8
		[ShowIfAny(TEXTURE_FLIPBOOK)] _FlipbookRows ("Flipbook Rows", Float) = 8
		[ShowIfAny(TEXTURE_FLIPBOOK)] _FlipbookNonloopableFrames ("Full Non-loopable frames", Float) = 0
		[ShowIfAny(TEXTURE_FLIPBOOK)] _FlipbookSpeed ("Flipbook Speed", Float) = 1
		[ToggleShowIfAny(FLIPBOOK_BLENDING_OFF, TEXTURE_FLIPBOOK)] _FlipbookBlendingOff ("No Frame Blending", Float) = 0
		[SpaceShowIfAny(12, TEXTURE_FLIPBOOK)] [InfoBox(Frame 1 contains frames 12 in RG BA channels Frame 2 contains 23, 2, MOTION_VECTORS, TEXTURE_FLIPBOOK)] [ToggleShowIfAny(MOTION_VECTORS, TEXTURE_FLIPBOOK)] _UseMotionVectors ("Use Motion Vectors", Float) = 0
		[ShowIfAny(2, MOTION_VECTORS, TEXTURE_FLIPBOOK)] _MotionVectorTex ("Motion Vector Texture", 2D) = "white" {}
		[ShowIfAny(2, MOTION_VECTORS, TEXTURE_FLIPBOOK)] _MotionVectorColumns ("Motion Vector Columns", Float) = 8
		[ShowIfAny(2, MOTION_VECTORS, TEXTURE_FLIPBOOK)] _MotionVectorRows ("Motion Vector Rows", Float) = 8
		[ShowIfAny(2, MOTION_VECTORS, TEXTURE_FLIPBOOK)] _MotionVectorSpeed ("Motion Vector Speed", Float) = 1
		[ShowIfAny(2, MOTION_VECTORS, TEXTURE_FLIPBOOK)] _MotionVectorIntensity ("Motion Vector Intensity", Float) = 1
		[Space(16)] [Toggle(MASK)] _EnableMask ("Layer 2", Float) = 0
		[ToggleShowIfAny(SECONDARY_UVS_MASK, 1, MASK, _SECONDARY_UVS_TRAILS, _SECONDARY_UVS_EXTERNAL_SCALE, _SECONDARY_UVS_OBJECT_SPACE, _SECONDARY_UVS_IMPORT)] _MaskSecondaryUVs ("Use Secondary UVs", Float) = 0
		[ToggleShowIfAny(MASK_RED_IS_ALPHA, MASK)] _MaskRedIsAlpha ("Red is Alpha", Float) = 0
		[EnumShowIfAny(3, Multiply, Add, Masked Add, MASK)] _MaskBlend ("Layer 2 Blend", Float) = 0
		[ShowIfAny(MASK)] _MaskTex ("Layer 2 Texture", 2D) = "white" {}
		[ToggleShowIfAny(MASK_PER_PARTICLE_RANDOM, 2, MASK, PARTICLE_VERTEX_STREAM)] _MaskPerParticleRandomization ("Per Particle Randomization", Float) = 0
		[ShowIfAny(MASK)] _MaskStrength ("Layer 2 Strength", Float) = 1
		[ToggleShowIfAny(WORLDSPACE_PANNING_MASK, 2, MASK, WORLDSPACE_PANNING)] _MaskTexWorldspacePanning ("Add worldspace panning", Float) = 0
		[ShowIfAny(MASK)] _MaskPanning ("Layer 2 Panning", Vector) = (0,0,0,0)
		[ToggleShowIfAny(MASK_DISSOLVE, MASK)] _MaskDissolve ("Dissolve along UVs", Float) = 0
		[ShowIfAny(2, MASK_DISSOLVE, MASK)] _MaskDissolveTiling ("Layer 2 Dissolve Tiling", Float) = 3
		[ShowIfAny(2, MASK_DISSOLVE, MASK)] _MaskDissolveOffset ("Layer 2 Dissolve Offset", Float) = 0
		[Space(12)] [Toggle(MASK2)] _EnableMask2 ("Layer 3", Float) = 0
		[ToggleShowIfAny(SECONDARY_UVS_MASK2, 1, MASK2, _SECONDARY_UVS_TRAILS, _SECONDARY_UVS_EXTERNAL_SCALE, _SECONDARY_UVS_OBJECT_SPACE, _SECONDARY_UVS_IMPORT)] _Mask2SecondaryUVs ("Use Secondary UVs", Float) = 0
		[ToggleShowIfAny(WORLDSPACE_PANNING_MASK2, 2, MASK2, WORLDSPACE_PANNING)] _Mask2TexWorldspacePanning ("Add worldspace panning", Float) = 0
		[ToggleShowIfAny(MASK2_RED_IS_ALPHA, MASK2)] _Mask2RedIsAlpha ("Red is Alpha", Float) = 0
		[EnumShowIfAny(3, Multiply, Add, Masked Add, MASK2)] _Mask2Blend ("Layer 3 Blend", Float) = 0
		[ShowIfAny(MASK2)] _Mask2Tex ("Layer 3 Texture", 2D) = "white" {}
		[ToggleShowIfAny(MASK2_PER_PARTICLE_RANDOM, 2, MASK2, PARTICLE_VERTEX_STREAM)] _Mask2ParticleRandomization ("Per Particle Randomization", Float) = 0
		[ShowIfAny(MASK2)] _Mask2Strength ("Layer 3 Strength", Float) = 1
		[ShowIfAny(MASK2)] _Mask2Panning ("Layer 3 Panning", Vector) = (0,0,0,0)
		_RimLight ("Rim Light Type", Float) = 0
		_RimlightInvert ("Invert Rimlight", Float) = 0
		_RimLightEdgeStart ("Rim Light Edge Start", Float) = 0.5
		_RimLightIntensity ("Rim Light Intensity", Float) = 1
		[Space(12)] [Toggle(WORLD_NOISE)] _EnableWorldNoise ("Enable World Noise", Float) = 0
		[InfoBox(The game needs to be played once first for the noise to be initiated, WORLD_NOISE)] [ShowIfAny(WORLD_NOISE)] _WorldNoiseScale ("World Noise Scale", Float) = 1
		[ShowIfAny(WORLD_NOISE)] _WorldNoiseIntensityOffset ("World Intensity Offset", Float) = 0
		[ShowIfAny(WORLD_NOISE)] _WorldNoiseIntensityScale ("World Intenstity Scale", Float) = 1
		[ShowIfAny(WORLD_NOISE)] _WorldNoiseScrolling ("World Noise Scrolling", Vector) = (0,0,0,1)
		[Space(12)] [Toggle(EROSION)] _Erosion ("Erosion", Float) = 0
		[EnumShowIfAny(4, Erosion, MainTex, Mask, Secondary Mask, Vertex Alpha, Combined, EROSION)] _Erosion_Source ("Erosion Source", Float) = 0
		[ToggleShowIfAny(SECONDARY_UVS_EROSION, 1, EROSION, _SECONDARY_UVS_TRAILS, _SECONDARY_UVS_EXTERNAL_SCALE, _SECONDARY_UVS_OBJECT_SPACE, _SECONDARY_UVS_IMPORT)] _ErosionSecondaryUVs ("Use Secondary UVs", Float) = 0
		[ToggleShowIfAny(WORLDSPACE_PANNING_EROSION, 2, EROSION, WORLDSPACE_PANNING)] _ErosionTexWorldspacePanning ("Add worldspace panning", Float) = 0
		[ToggleShowIfAny(EROSION_PER_PARTICLE_RANDOM, 3, EROSION, PARTICLE_VERTEX_STREAM, _EROSION_SOURCE_EROSION)] _ErosionPerParticleRandomization ("Per Particle Randomization", Float) = 0
		[SpaceShowIfAny(12, 2, EROSION, _EROSION_SOURCE_EROSION)] [ShowIfAny(2, EROSION, _EROSION_SOURCE_EROSION)] _ErosionTex ("Erosion Texture", 2D) = "white" {}
		[ShowIfAny(2, EROSION, _EROSION_SOURCE_EROSION)] _ErosionPanning ("Mask Panning", Vector) = (0,0,0,0)
		[ToggleShowIfAny(EROSION_VERTEX_ALPHA_THRESHOLD, EROSION)] _ErosionVertexThreshold ("Use Vertex Alpha as Threshold", Float) = 0
		[ShowIfAny(2, EROSION, 0EROSION_VERTEX_ALPHA_THRESHOLD)] _ErosionThreshold ("Erosion Threshold", Range(0, 1)) = 0.5
		[ShowIfAny(EROSION)] _ErosionSmoothness ("Erosion Smoothness", Range(0, 0.5)) = 0.1
		[Space(12)] [KeywordEnum(None, Simple, Flowmap)] Distortion ("Distortion", Float) = 0
		[SpaceShowIfAny(12, DISTORTION_FLOWMAP, DISTORTION_SIMPLE)] [EnumShowIfAny(3, Main, Mask, Mask2, DISTORTION_FLOWMAP, DISTORTION_SIMPLE)] Distortion_Target ("Distortion Target", Float) = 0
		[ToggleShowIfAny(SECONDARY_UVS_FLOWMAP, 1, DISTORTION_FLOWMAP, _SECONDARY_UVS_TRAILS, _SECONDARY_UVS_EXTERNAL_SCALE, _SECONDARY_UVS_OBJECT_SPACE, _SECONDARY_UVS_IMPORT)] _FlowmapSecondaryUVs ("Use Secondary UVs", Float) = 0
		[ToggleShowIfAny(WORLDSPACE_PANNING_FLOWMAP, 2, DISTORTION_FLOWMAP, WORLDSPACE_PANNING)] _FlowmapTexWorldspacePanning ("Add worldspace panning", Float) = 0
		[ShowIfAny(DISTORTION_FLOWMAP)] _FlowTex ("Flowmap Texture", 2D) = "black" {}
		[ToggleShowIfAny(FLOWMAP_PER_PARTICLE_RANDOM, 2, DISTORTION_FLOWMAP, PARTICLE_VERTEX_STREAM)] _FlowmapParticleRandomization ("Per Particle Randomization", Float) = 0
		[ShowIfAny(DISTORTION_FLOWMAP)] _FlowSpeed ("Flow Speed", Range(0, 1)) = 0.2
		[ShowIfAny(DISTORTION_FLOWMAP)] _FlowStrength ("Flow Strength", Range(-1, 1)) = 0.2
		[VectorShowIfAny(2, DISTORTION_FLOWMAP)] _FlowAdd ("Flowmap Additional Direction", Vector) = (0,0,0,0)
		[ShowIfAny(DISTORTION_FLOWMAP)] _FlowPanning ("Flowmap Panning", Vector) = (0,0,0,0)
		[SpaceShowIfAny(12, DISTORTION_FLOWMAP)] [ToggleShowIfAny(SECONDARY_UVS_DISTORTION, 1, DISTORTION_SIMPLE, _SECONDARY_UVS_TRAILS, _SECONDARY_UVS_EXTERNAL_SCALE, _SECONDARY_UVS_OBJECT_SPACE, _SECONDARY_UVS_IMPORT)] _DistortionSecondaryUVs ("Use Secondary UVs", Float) = 0
		[ToggleShowIfAny(WORLDSPACE_PANNING_DISTORTION, 2, DISTORTION_SIMPLE, WORLDSPACE_PANNING)] _DistortionTexWorldspacePanning ("Add worldspace panning", Float) = 0
		[ToggleShowIfAny(DISTORTION_PER_PARTICLE_RANDOM, 2, DISTORTION_SIMPLE, PARTICLE_VERTEX_STREAM)] _DistortionParticleRandomization ("Per Particle Randomization", Float) = 0
		[ShowIfAny(DISTORTION_SIMPLE)] _DistortionTex ("Distortion Texture", 2D) = "black" {}
		[ShowIfAny(DISTORTION_SIMPLE)] _DistortionStrength ("Distortion Strength", Float) = 0.2
		[ShowIfAny(DISTORTION_SIMPLE)] _DistortionAxes ("Distortion Axes", Vector) = (1,1,0,0)
		[ShowIfAny(DISTORTION_SIMPLE)] _DistortionPanning ("Distortion Panning", Vector) = (0,0,0,0)
		[SpaceShowIfAny(12, DISTORTION_SIMPLE)] [BigHeader(FOG)] [Space(18)] [KeywordEnum(None, Alpha, Color, Lerp)] _FogType ("Fog Type", Float) = 0
		[ShowIfAny(_FOGTYPE_ALPHA, _FOGTYPE_LERP, _FOGTYPE_COLOR)] _FogStartOffset ("Fog Start Offset", Float) = 0
		[ShowIfAny(_FOGTYPE_ALPHA, _FOGTYPE_LERP, _FOGTYPE_COLOR)] _FogScale ("Fog Scale", Float) = 1
		[ToggleShowIfAny(HEIGHT_FOG, _FOGTYPE_ALPHA, _FOGTYPE_LERP, _FOGTYPE_COLOR)] _EnableHeightFog ("Enable Height Fog", Float) = 0
		[ShowIfAny(1, HEIGHT_FOG, _FOGTYPE_ALPHA, _FOGTYPE_LERP, _FOGTYPE_COLOR)] _FogHeightScale ("Fog Height Scale", Float) = 1
		[ShowIfAny(1, HEIGHT_FOG, _FOGTYPE_ALPHA, _FOGTYPE_LERP, _FOGTYPE_COLOR)] _FogHeightOffset ("Fog Height Offset", Float) = 0
		[ToggleShowIfAny(PRECISE_FOG, _FOGTYPE_ALPHA, _FOGTYPE_LERP,  _FOGTYPE_COLOR)] _PreciseFog ("High (Frag) Precision", Float) = 0
		[BigHeader(DISSOLVE LIKE FEATURES)] [Space(18)] [Toggle(DISSOLVE)] _EnableDissolve ("Enable Dissolve", Float) = 0
		[InfoBox(To change direction it is better to use negative Axis Vector instead of Dissolve invert, 1, DISSOLVE)] [ShowIfAny(DISSOLVE)] _DissolveScale ("Dissolve Falloff Scale", Float) = 5
		[FloatToggleShowIfAny(DISSOLVE)] _DissolveReverse ("Invert Dissolve", Float) = 0
		[EnumShowIfAny(4, Local, World, World Centered, Uv, DISSOLVE)] _Dissolve_Space ("Dissolve Space", Float) = 0
		[ShowIfAny(2, DISSOLVE, 0_DISSOLVEAXIS_AVATAR)] _DissolveAxisVector ("Dissolve Axis", Vector) = (0,1,0,0)
		[ToggleShowIfAny(DISSOLVE_PROGRESS, DISSOLVE)] _UseDissolveProgress ("Dissolve Progress", Float) = 0
		[ShowIfAny(3, DISSOLVE, 0_DISSOLVEAXIS_AVATAR, 0DISSOLVE_PROGRESS)] _DissolveOffset ("Dissolve Offset", Float) = 0
		[ShowIfAny(2, DISSOLVE, DISSOLVE_PROGRESS)] _DissolveStartValue ("Dissolve Start Value", Float) = 0
		[ShowIfAny(2, DISSOLVE, DISSOLVE_PROGRESS)] _DissolveEndValue ("Dissolve End Value", Float) = 10
		[ToggleShowIfAny(DISSOLVE_PROGRESS_FROM_VERTEX_ALPHA, 3, DISSOLVE, DISSOLVE_PROGRESS)] _DissolveProgressFromVertexAlpha ("Get Progress from Vertex Alpha", Float) = 0
		[ShowIfAny(3, DISSOLVE, 0DISSOLVE_PROGRESS_FROM_VERTEX_ALPHA, DISSOLVE_PROGRESS)] _DissolveProgress ("Dissolve Progress", Range(-1, 1)) = 0
		[SpaceShowIfAny(24, 1, DISSOLVE)] [ToggleShowIfAny(DISSOLVE_COLOR, 1, DISSOLVE)] _UseDissolveColor ("Use Dissolve Color", Float) = 0
		[ShowIfAny(2, DISSOLVE, DISSOLVE_COLOR)] _DissolveColor ("Dissolve Color", Vector) = (0,1,1,0)
		[ShowIfAny(2, DISSOLVE, DISSOLVE_COLOR)] _DissolveColorIntensity ("Color Intensity", Float) = 1
		[ShowIfAny(2, DISSOLVE, DISSOLVE_COLOR)] _CutColorFalloff ("Cut Falloff Scale", Float) = 4
		[FloatToggleShowIfAny(DISSOLVE, DISSOLVE_COLOR)] _MultiplyDissolveGridByAlpha ("Multiply by Alpha", Float) = 0
		[SpaceShowIfAny(24, 2, DISSOLVE, DISSOLVE_COLOR)] [EnumShowIfAny(4, None, Local, World, Uv, DISSOLVE)] _Dissolve_Grid ("Dissolve Grid", Float) = 0
		[ShowIfAny(3, DISSOLVE, 0_DISSOLVE_GRID_NONE, DISSOLVE_COLOR)] _GridThickness ("Grid Thickness", Float) = 1.5
		[ShowIfAny(3, DISSOLVE, 0_DISSOLVE_GRID_NONE, DISSOLVE_COLOR)] _GridSize ("Grid Size", Float) = 10
		[ShowIfAny(3, DISSOLVE, 0_DISSOLVE_GRID_NONE, DISSOLVE_COLOR)] _GridFalloff ("Grid Falloff Scale", Float) = 4
		[ShowIfAny(3, DISSOLVE, 0_DISSOLVE_GRID_NONE, DISSOLVE_COLOR)] _GridSpeed ("Grid Speed", Float) = 0.1
		[SpaceShowIfAny(24, 3, DISSOLVE, 0_DISSOLVE_GRID_NONE, DISSOLVE_COLOR)] [ToggleShowIfAny(DISSOLVE_TEXTURE, 1, DISSOLVE)] _UseDissolveTexture ("Use Dissolve Texture", Float) = 0
		[ShowIfAny(2, DISSOLVE, DISSOLVE_TEXTURE)] _DissolveTexture ("Dissolve Texture", 2D) = "black" {}
		[VectorShowIfAny(2, 2, DISSOLVE, DISSOLVE_TEXTURE)] _DissolveTextureSpeed ("Texture Speed", Vector) = (0,0,0,0)
		[ShowIfAny(2, DISSOLVE, DISSOLVE_TEXTURE)] _DissolveTextureInfluence ("Texture Influence", Float) = 0.2
		[SpaceShowIfAny(24, 2, DISSOLVE, DISSOLVE_TEXTURE)] [Space(12)] [InfoBox(Requires external plane position and normal, PLANE_CLIP)] [Toggle(PLANE_CLIPPING)] _PlaneClipping ("Plane Clipping", Float) = 0
		[ShowIfAny(PLANE_CLIPPING)] _ClippingPlanePosition ("Plane position", Vector) = (0,0,0,0)
		[ShowIfAny(PLANE_CLIPPING)] _ClippingPlaneNormal ("Plane normal", Vector) = (0,1,1,0)
		[Space(12)] [Toggle(REVEAL)] _EnableReveal ("Use Reveal", Float) = 0
		[Space(12)] [KeywordEnum(None, Alpha Clip, Worldspace Noise, Scale)] _CutoutType ("Cutout", Float) = 0
		[SpaceShowIfAny(10, _CUTOUTTYPE_WORLDSPACE_NOISE, _CUTOUTTYPE_ALPHA_CLIP, _CUTOUTTYPE_SCALE)] [ShowIfAny(_CUTOUTTYPE_WORLDSPACE_NOISE, _CUTOUTTYPE_ALPHA_CLIP, _CUTOUTTYPE_SCALE)] _Cutout ("Threshold", Range(0, 1)) = 0.5
		[ShowIfAny(_CUTOUTTYPE_WORLDSPACE_NOISE)] _CutoutTexScale ("Noise Scale", Float) = 1
		[ShowIfAny(_CUTOUTTYPE_WORLDSPACE_NOISE)] _CutoutGradientWidth ("Fade Width", Range(0.01, 0.1)) = 0.05
		[ShowIfAny(_CUTOUTTYPE_WORLDSPACE_NOISE, _CUTOUTTYPE_SCALE)] _CutoutTexOffset ("Offset", Vector) = (0,0,0,0)
		[BigHeader(SPECIAL FEATURES)] [Space(18)] [Toggle(FAKE_MIRROR_TRANSPARENCY)] _EnableFakeMirrorTransparency ("Fake Mirror Transparency", Float) = 0
		[ShowIfAny(FAKE_MIRROR_TRANSPARENCY)] _FakeMirrorTransparency ("Mirror Transparency Multiplier", Float) = 1
		[Space(12)] [Toggle(NOTE_VERTEX_DISTORTION)] _EnableVertexDistortion ("Note Vertex Distortion", Float) = 0
		[Space(12)] [Toggle(HOLOGRAM)] _EnableHologram ("Legacy Hologram", Float) = 0
		[ShowIfAny(HOLOGRAM)] _HologramColor ("Hologram Color", Vector) = (1,1,1,1)
		[BigHeader(ALPHA HANDLING)] [Space(18)] _AlphaMultiplier ("Alpha Multiplier", Float) = 1
		[Space(12)] [Toggle(SQUARE_ALPHA)] _SquareAlpha ("Square Alpha", Float) = 1
		[Space(12)] [Toggle(FILL_ALPHA)] _EnableFillAlpha ("Enable Fill Alpha", Float) = 0
		[ShowIfAny(FILL_ALPHA)] _FillAlpha ("Fill Alpha", Float) = 0.1
		[FloatEnumShowIfAny(2, None, MainTex Blue, FILL_ALPHA)] _FillMask ("Fill Mask", Float) = 0
		[FloatEnumShowIfAny(4, Base Color, Material, Black, White, FILL_ALPHA)] _FillColor ("Fill Color", Float) = 0
		[Space(12)] [Toggle(CLOSE_TO_CAMERA_DISAPPEAR)] _EnableCloseToCameraDisappear ("Close to Camera Dissapear", Float) = 0
		[ShowIfAny(CLOSE_TO_CAMERA_DISAPPEAR)] _CloseCameraDisappearDistance ("Close to Camera Offset", Float) = 0.5
		[ShowIfAny(CLOSE_TO_CAMERA_DISAPPEAR)] _CloseCameraDisappearWidth ("Close to Camera Factor", Float) = 0.5
		[Space(12)] [Toggle(VIEW_ALIGN_DISAPPEAR)] _EnableViewAlignDisappear ("View Align Disappear", Float) = 0
		[FloatToggleShowIfAny(VIEW_ALIGN_DISAPPEAR)] _SquareAngleForViewAlignDisappear ("Square Angle", Float) = 0
		[ShowIfAny(VIEW_ALIGN_DISAPPEAR)] _ViewAlignFactor ("View Align Factor", Float) = 1.5
		[ShowIfAny(VIEW_ALIGN_DISAPPEAR)] _ViewAlignOffset ("View Align Offset", Float) = 0
		[Space(12)] [Toggle(SOFT_PARTICLES)] _EnableSoftParticles ("Soft Particles", Float) = 0
		[ShowIfAny(SOFT_PARTICLES)] _SoftFactor ("Soft Factor", Range(0, 50)) = 0
		[Space(12)] [InfoBox(Main usecase is when using DST Color blend of One minus Src Alpha, _OVERRIDE_FINAL_ALPHA_FLAT, _OVERRIDE_FINAL_ALPHA_COLOR_BASED)] [KeywordEnum(None, Flat, Color Based)] _Override_Final_Alpha ("Override Final Alpha", Float) = 0
		[InfoBox(Override value lerps to 0 as base color value approaches 1, _OVERRIDE_FINAL_ALPHA_COLOR_BASED)] [ShowIfAny(_OVERRIDE_FINAL_ALPHA_FLAT, _OVERRIDE_FINAL_ALPHA_COLOR_BASED)] _OverrideFinalAlpha ("Final Alpha", Float) = 0.7
		[BigHeader(OTHER FEATURES)] [Space(18)] [Space(12)] [KeywordEnum(None, MainEffect, Always)] _WhiteBoostType ("White Boost", Float) = 0
		[SpaceShowIfAny(12, _WHITEBOOSTTYPE_MAINEFFECT, _WHITEBOOSTTYPE_ALWAYS)] [ShowIfAny(_WHITEBOOSTTYPE_MAINEFFECT, _WHITEBOOSTTYPE_ALWAYS)] _QuestWhiteboostMultiplier ("Quest Whiteboost Multiplier", Float) = 1
		[ShowIfAny(_WHITEBOOSTTYPE_MAINEFFECT, _WHITEBOOSTTYPE_ALWAYS)] _BloomMultiplier ("PC Bloom Multiplier", Float) = 1
		[InfoBox(Make sure Main Texture contains green channel created for this purpose and uses neither Texture Color nor Flipbook nor Flowmap, 1, GREEN_CHANNEL_WHITEBOOST, _WHITEBOOSTTYPE_MAINEFFECT, _WHITEBOOSTTYPE_ALWAYS)] [ToggleShowIfAny(GREEN_CHANNEL_WHITEBOOST, _WHITEBOOSTTYPE_MAINEFFECT, _WHITEBOOSTTYPE_ALWAYS)] _GreenChannelWhiteboost ("G channel controls whiteboost", Float) = 0
		[ToggleShowIfAny(REMAP_WHITEBOOST_START, _WHITEBOOSTTYPE_MAINEFFECT, _WHITEBOOSTTYPE_ALWAYS)] _RemapWhiteboostStart ("Remap Whiteboost Start", Float) = 0
		[ShowIfAny(1, REMAP_WHITEBOOST_START, _WHITEBOOSTTYPE_MAINEFFECT, _WHITEBOOSTTYPE_ALWAYS)] _WhiteBoostRemapStart ("Alpha for no Whiteboost", Range(0, 1)) = 0
		[SpaceShowIfAny(12, 1, REMAP_WHITEBOOST_START, _WHITEBOOSTTYPE_MAINEFFECT, _WHITEBOOSTTYPE_ALWAYS)] [Space(12)] [KeywordEnum(None, Full, Y Axis, Camera Facing)] _Billboard ("Billboard", Float) = 0
		[InfoBox(Scale XZ should be always equal, _BILLBOARD_Y_AXIS)] [ShowIfAny(_BILLBOARD_FULL, _BILLBOARD_CAMERA_FACING)] _BillboardScale ("Billboard Scale", Float) = 1
		[Space(12)] [Toggle(NOISE_DITHERING)] _EnableNoiseDithering ("Noise Dithering", Float) = 0
		[KeywordEnum(Standard, Song Time, Freeze)] _Custom_Time ("Time Behavior", Float) = 0
		[Toggle(MIPMAP_BIAS)] _EnableMipmapBias ("Mipmap Bias", Float) = 0
		[InfoBox(Only applies to Main Texture, MIPMAP_BIAS)] [ShowIfAny(MIPMAP_BIAS)] _MipmapBias ("Bias Value", Float) = 0
		[Toggle(CHROMATIC_ABERRATION)] _UseChromaticAberration ("Chromatic Aberration", Float) = 0
		_ChromaticAberration ("Aberration Channels", Vector) = (5,0,0,0)
		[BigHeader(SETTINGS)] [Space(18)] [Header(Color Blending)] [Space] [Enum(UnityEngine.Rendering.BlendMode)] _BlendModeSrc ("Color Contribution", Float) = 1
		[Enum(UnityEngine.Rendering.BlendMode)] _BlendModeDst ("Color Background", Float) = 1
		[Space] [InfoBox(Support on Quest ends after LogicalClear)] [Enum(UnityEngine.Rendering.BlendOp)] _BlendOp ("Blend Operation", Float) = 0
		[Header(Bloom Blending)] [Space] [Enum(UnityEngine.Rendering.BlendMode)] _BlendModeSrcA ("Alpha Contribution", Float) = 0
		[Enum(UnityEngine.Rendering.BlendMode)] _BlendModeDstA ("Alpha Background", Float) = 1
		[Space()] [Header(Base Settings)] [Space] [Enum(UnityEngine.Rendering.CullMode)] _CullMode ("Cull Mode", Float) = 0
		[Enum(Off, 0, On, 1)] _ZWrite ("Z Write", Float) = 0
		[Space] [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("ZTest", Float) = 4
		[Space] _OffsetFactor ("Offset Factor", Float) = 0
		_OffsetUnits ("Offset Units", Float) = 0
		[Header(Stencils)] [Space] _StencilRefValue ("Stencil Ref Value", Float) = 0
		[Enum(UnityEngine.Rendering.CompareFunction)] _StencilComp ("Stencil Comp Func", Float) = 8
		[Enum(UnityEngine.Rendering.StencilOp)] _StencilPass ("Stencill Pass Op", Float) = 0
		[Space(12)] [Header(Instancing and Rendering)] [Space] [Toggle(MESH_PACKING)] _MeshPacking ("Use Mesh Packed Instancing", Float) = 0
		[InfoBox(Id below is for debug only and needs to be set via Material Property Blocks, MESH_PACKING)] [ShowIfAny(MESH_PACKING)] _MeshPackingId ("Mesh Packing Id", Float) = 1
		_BloomPreset ("Dummy Custom Shader Inspector Property", Float) = 0
		_BlendingPreset ("Dummy Custom Shader Inspector Property", Float) = 0
		_StencilPreset ("Dummy Custom Shader Inspector Property", Float) = 0
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
            #pragma multi_compile _ STEREO_INSTANCING_ON

            #pragma shader_feature_local SECONDARY_COLOR
            #pragma shader_feature_local_fragment COLOR_BY_FOG
            #pragma shader_feature_local_fragment FOG_COLOR_HIGHLIGHT
            #pragma shader_feature_local_fragment _ _FOG_MASK_SOURCE_PRIMARY_MASK

            #pragma shader_feature_local COLOR_GRADIENT

            #pragma shader_feature_local_vertex SPECTROGRAM_COLOR
            #pragma shader_feature_local_fragment SPECTROGRAM_COLOR

            #pragma shader_feature_local COLOR_ARRAY

            #pragma shader_feature_local _ _SECONDARY_UVS_IMPORT _SECONDARY_UVS_EXTERNAL_SCALE
            #pragma shader_feature_local SECONDARY_UVS_MAIN
            #pragma shader_feature_local WORLDSPACE_PANNING

            #pragma shader_feature_local VERTEX_COLOR
            // Vertex binary 680a9e19 forwards raw alpha; fragment a07d89c2
            // squares the interpolated factor. Compile this keyword in both stages.
            #pragma shader_feature_local VERTEX_SQUARE_ALPHA
            #pragma shader_feature_local_vertex VERTEX_RED_IS_ALPHA
            #pragma shader_feature_local_vertex _ _VERTEXCHANNELS_A

            #pragma shader_feature_local_vertex SPATIAL_DISPLACEMENT
            #pragma shader_feature_local_vertex _ _SPECTROGRAM_FULL

            #pragma shader_feature_local_vertex _ _CURVE_VERTICES_AROUND_Z
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

            #pragma shader_feature_local _ DISTORTION_SIMPLE
            #pragma shader_feature_local_fragment DISTORTION_TARGET_MASK
            #pragma shader_feature_local SECONDARY_UVS_DISTORTION
            #pragma shader_feature_local WORLDSPACE_PANNING_DISTORTION

            #pragma shader_feature_local_fragment _ _CUTOUTTYPE_ALPHA_CLIP _CUTOUTTYPE_WORLDSPACE_NOISE
            #pragma shader_feature_local_fragment PLANE_CLIPPING

            #pragma shader_feature_local_fragment SQUARE_ALPHA
            #pragma shader_feature_local VIEW_ALIGN_DISAPPEAR

            // Lifetime / depth / distance gates
            #pragma shader_feature_local_fragment LIFETIME
            #pragma shader_feature_local_vertex LIFETIME
            #pragma shader_feature_local SOFT_PARTICLES
            #pragma shader_feature_local_fragment CLOSE_TO_CAMERA_DISAPPEAR
            #pragma shader_feature_local_fragment FILL_ALPHA
            #pragma shader_feature_local_fragment _ _OVERRIDE_FINAL_ALPHA_COLOR_BASED

            // Dissolve
            #pragma shader_feature_local DISSOLVE
            #pragma shader_feature_local _ _DISSOLVE_SPACE_WORLD _DISSOLVE_SPACE_WORLD_CENTERED
            #pragma shader_feature_local DISSOLVE_PROGRESS_FROM_VERTEX_ALPHA

            // World-space mapping / vertex flipbook
            #pragma shader_feature_local_vertex WORLDSPACE_PANNING_MAIN
            #pragma shader_feature_local VERTEX_FLIPBOOK
            #pragma shader_feature_local VERTEX_FLIPBOOK_FADE

            // Sampling / dithering / fx
            #pragma shader_feature_local MIPMAP_BIAS
            #pragma shader_feature_local NOISE_DITHERING
            #pragma shader_feature_local MAIN_PER_PARTICLE_RANDOM
            #pragma shader_feature_local_fragment HOLOGRAM
            #pragma shader_feature_local_fragment FAKE_MIRROR_TRANSPARENCY
            #pragma shader_feature_local_fragment PRECISE_FOG

            #pragma shader_feature_local_fragment _ _WHITEBOOSTTYPE_MAINEFFECT _WHITEBOOSTTYPE_ALWAYS
            // Global: the post-process bloom runs (mirrors the game's MAIN_EFFECT_ENABLED gate).
            #pragma multi_compile _ POST_BLOOM
            // DEPTH_TEXTURE is ChroMapper's runtime alias; DEPTH_TEXTURE_ENABLED is
            // Beat Saber 1.44.3's global. Compile both names for the same depth route.
            #pragma multi_compile _ DEPTH_TEXTURE DEPTH_TEXTURE_ENABLED
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
            #include "ShaderLibrary/SpectrogramShared.hlsl"
            #include "ShaderLibrary/PostProcess.hlsl"

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
            // Global 64-sample spectrogram data, uploaded by the Spectrogram
            // component (Shader.SetGlobalFloatArray). The game 1.44.3 particle
            // shader reads the same 64-bin layout from its constant buffer.
            float _SpectrogramData[64];
            // --

            // _SECONDARY_UVS_IMPORT
            float4 _UVScale;
            float4 _UVManualOffset;
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

            // COLOR_BY_FOG / world-noise cutout globals and controls.
            sampler3D _CutoutTex;
            float _ObstacleFogMultiplier;
            float _ObstacleFogMax;
            float _ObstacleColorInfluence;
            float _ObstacleFogHighlightMultiplier;
            float _CutoutTexScale;
            float _CutoutGradientWidth;
            float4 _CutoutTexOffset;

            // PLANE_CLIPPING is driven by material properties in exported data.
            float4 _ClippingPlanePosition;
            float4 _ClippingPlaneNormal;

            UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);
            float4 _CameraDepthTexture_TexelSize;

            // LIFETIME
            // --

            // SOFT_PARTICLES
            float _SoftFactor;
            // --

            // CLOSE_TO_CAMERA_DISAPPEAR
            float _CloseCameraDisappearDistance;
            float _CloseCameraDisappearWidth;
            // --

            // DISSOLVE
            float4 _DissolveAxisVector;
            float _DissolveOffset;
            float _DissolveScale;
            float _DissolveReverse;
            float _DissolveProgress;
            // --

            // WORLDSPACE_PANNING_MAIN
            float _WorldspacePanningSpeed;
            // --

            // MIPMAP_BIAS
            float _MipmapBias;
            // --

            // NOISE_DITHERING / HOLOGRAM
            sampler2D _GlobalBlueNoiseTex;
            float2 _GlobalBlueNoiseParams;
            float _GlobalRandomValue;
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
                UNITY_DEFINE_INSTANCED_PROP(float, _StartTime)
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
                float _StartTime;
                float _MeshPackingId;
                #endif
                float _EnableExternalAlpha;
                float2 _MaskPanning;
                float4 _Mask2Panning;
                float4 _DistortionPanning;
                float _DistortionStrength;
                float4 _DistortionAxes;
                float _Cutout;
                float _FillMask;
                float _FillColor;
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
                float3 uv1 : TEXCOORD0;
                #if defined(MESH_PACKING) || defined(_SECONDARY_UVS_IMPORT) || defined(COLOR_ARRAY)
                float2 uv2 : TEXCOORD1;
                #endif
                #if defined(_SPECTROGRAM_FULL) || defined(SPECTROGRAM_COLOR)
                float2 uv3 : TEXCOORD2;
                #endif
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;

                float4 color : COLOR;

                #if defined(_SECONDARY_UVS_IMPORT) || defined(_SECONDARY_UVS_EXTERNAL_SCALE) || \
                    defined(SECONDARY_UVS_DISTORTION) || defined(VERTEX_FLIPBOOK)
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

                #if defined(COLOR_ARRAY)
                float2 colorIndexUv : TEXCOORD4;
                #endif

                #if defined(SECONDARY_COLOR)
                float2 secondaryUv : TEXCOORD9;
                #endif

                #if defined(MASK) && defined(MASK2)
                float4 layeredMaskUv : TEXCOORD12;
                #if defined(DISTORTION_SIMPLE)
                float2 layeredDistortionUv : TEXCOORD13;
                #endif
                #elif defined(MASK)
                float2 maskUv : TEXCOORD12;
                #elif defined(MASK2)
                float2 mask2Uv : TEXCOORD12;
                #endif

                #if defined(DISTORTION_SIMPLE) && !(defined(MASK) && defined(MASK2))
                float2 distortionUv : TEXCOORD11;
                #endif

                #if defined(NOISE_DITHERING)
                float4 noiseScreenPos : TEXCOORD10;
                #endif

                #if defined(VIEW_ALIGN_DISAPPEAR)
                float3 worldNormal : TEXCOORD6;
                #endif

                float bloomFogDistanceSquared : TEXCOORD5;

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
                // Game 1.44.3 (vertex 8d1fba3a): orthonormal basis derived from
                // the object's view-space direction. The quad maps X to the
                // right vector and Y to the up vector, scaled by _BillboardScale,
                // and is projected from view space.
                float4 cameraFacingViewOrigin = mul(UNITY_MATRIX_V, float4(worldOrigin, 1));
                float3 cameraFacingRight = normalize(
                    float3(cameraFacingViewOrigin.z, 0.0, -cameraFacingViewOrigin.y));
                float3 cameraFacingUp = normalize(
                    cross(cameraFacingViewOrigin.xyz, cameraFacingRight));
                float4 cameraFacingViewPos = cameraFacingViewOrigin + float4(
                    (i.vertex.x * cameraFacingRight + i.vertex.y * cameraFacingUp) * _BillboardScale,
                    0.0);
                o.worldPos = mul(unity_MatrixInvV, cameraFacingViewPos).xyz;
                o.vertex = mul(UNITY_MATRIX_P, cameraFacingViewPos);
                #endif

                #if defined(_BILLBOARD_Y_AXIS)
                // Game 1.44.3 (vertex f676b0af): rotate the vertex XZ in object
                // space using the object's view-space direction (a symmetric XZ
                // transform, not a world-space basis reconstruction). Vertex Y is
                // preserved. No billboard scale applies to this route.
                float4 yAxisViewOrigin = mul(UNITY_MATRIX_V, float4(worldOrigin, 1));
                float2 yAxisDir = normalize(yAxisViewOrigin.xz + float2(1e-10, 0.0));
                float yAxisNewX = -yAxisDir.y * i.vertex.x + yAxisDir.x * i.vertex.z;
                float yAxisNewZ = yAxisDir.x * i.vertex.x - yAxisDir.y * i.vertex.z;
                o.worldPos = mul(unity_ObjectToWorld,
                                 float4(yAxisNewX, i.vertex.y, yAxisNewZ, 1)).xyz;
                o.vertex = mul(UNITY_MATRIX_VP, float4(o.worldPos, 1.0));
                #endif

                #else

                #if defined(SPATIAL_DISPLACEMENT)
                float4 time = GetTime(UNITY_ACCESS_INSTANCED_PROP(Props, _TimeOffset));
                float2 dispUV = TRANSFORM_TEX(i.uv1, _DisplacementTex)
                    + _DisplacementPanning.xy * time.y * _DisplacementPanningSpeed;
                float3 dispSample = tex2Dlod(_DisplacementTex, float4(dispUV, 0, 0)).xyz * 2.0 - 1.0;

                float3 bitangent = i.tangent.yzx * i.normal.zxy - i.normal.yzx * i.tangent.zxy;
                float3 dispDir = dispSample.x * i.tangent.xyz
                    + dispSample.y * bitangent
                    + dispSample.z * i.normal.xyz;
                dispDir = normalize(dispDir);

                #if defined(_SPECTROGRAM_FULL)
                // Game 1.44.3 (vertex f2f5f1a8): the spectrogram value comes from
                // the 64-bin audio array (index = uv3.x * 63). ChroMapper uses the
                // same 64-sample _SpectrogramData global as Spectrogram.shader.
                float spectrogramIndex = i.uv3.x * _UV3Scale + _UV3Offset;
                float dispAmount = _DisplacementStrength *
                    _SpectrogramData[CalculateSpectrogramIndex(spectrogramIndex)];
                #else
                float dispAmount = _DisplacementStrength;
                #endif
                i.vertex.xyz += dispDir * dispAmount * _DisplacementAxes.xyz;
                #endif

                #if defined(_CURVE_VERTICES_AROUND_Z)
                float angle = i.vertex.y / i.vertex.x;
                float s, c;
                sincos(angle, s, c);
                i.vertex.xyz = float3(i.vertex.x * c, i.vertex.x * s, i.vertex.z);
                #endif

                o.vertex = UnityFlipSprite(i.vertex, _Flip);
                o.localPos = o.vertex.xyz;
                o.worldPos = mul(unity_ObjectToWorld, o.vertex).xyz;
                o.vertex = UnityObjectToClipPos(o.vertex);
                #endif
                #if !defined(SPATIAL_DISPLACEMENT)
                float4 time = GetTime(UNITY_ACCESS_INSTANCED_PROP(Props, _TimeOffset));
                #endif
                #if defined(MAIN_TEXTURE)
                {
                #if defined(WORLDSPACE_PANNING_MAIN)
                // The recovered route projects _UVScale onto the tangent basis.
                float3 worldspaceBitangent =
                    i.tangent.yzx * i.normal.zxy - i.normal.yzx * i.tangent.zxy;
                float2 worldspaceProjection = abs(float2(
                    dot(_UVScale.xyz, i.tangent.xyz),
                    dot(_UVScale.xyz, worldspaceBitangent))) * _MainTex_ST.xy;
                float2 worldspaceUv = i.uv1.xy * worldspaceProjection + _MainTex_ST.zw;
                float2 worldspacePan = time.y * _UvPanning.xy;
                worldspacePan *= worldspaceProjection;
                worldspaceUv += worldspacePan;

                float3 worldToObjectRow = unity_WorldToObject._m30_m31_m32;
                float2 worldspaceSpeedProjection;
                worldspaceSpeedProjection.y = dot(
                    abs(i.normal.xyz),
                    worldToObjectRow.yzy * float3(-1.0, 1.0, 1.0));
                worldspaceSpeedProjection.x = dot(
                    abs(i.normal.yzx), worldToObjectRow.xxz);
                worldspaceUv += worldspaceSpeedProjection * _WorldspacePanningSpeed;
                o.uv.xy = worldspaceUv + _UVManualOffset.xy;
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
                #elif defined(_SECONDARY_UVS_EXTERNAL_SCALE)
                // Recovered external-scale route has no TEXCOORD1 input. It derives
                // the secondary coordinates from the primary UV and the external
                // scale/manual offset controls (vertex 2c574604de1e85ca...).
                o.uv.zw = i.uv1.xy * _UVScale.xy + _UVManualOffset.xy;
                #endif
                #if defined(MAIN_TEXTURE) && defined(SECONDARY_UVS_MAIN) && \
                    !defined(WORLDSPACE_PANNING_MAIN) && \
                    (defined(_SECONDARY_UVS_IMPORT) || defined(_SECONDARY_UVS_EXTERNAL_SCALE))
                o.uv.xy = o.uv.zw * _MainTex_ST.xy + _MainTex_ST.zw
                    + time.y * _UvPanning.xy * _MainTex_ST.xy;
                #endif
                #if defined(MASK) && defined(MASK2)
                // Vertex 6017450af174125e supplies independent main, mask,
                // mask-2, and distortion coordinates for layered-mask materials.
                float layeredTime = GetTime(
                    UNITY_ACCESS_INSTANCED_PROP(Props, _TimeOffset)).y;
                #if defined(MAIN_TEXTURE) && !defined(SECONDARY_UVS_MAIN)
                o.uv.xy = i.uv1.xy * _MainTex_ST.xy + _MainTex_ST.zw
                    + layeredTime * _UvPanning.xy * _MainTex_ST.xy;
                #endif
                float2 layeredMaskBaseUv = i.uv1.xy;
                float2 layeredMask2BaseUv = i.uv1.xy;
                #if defined(SECONDARY_UVS_MASK) && \
                    (defined(_SECONDARY_UVS_IMPORT) || defined(_SECONDARY_UVS_EXTERNAL_SCALE))
                layeredMaskBaseUv = o.uv.zw;
                #endif
                #if defined(SECONDARY_UVS_MASK2) && \
                    (defined(_SECONDARY_UVS_IMPORT) || defined(_SECONDARY_UVS_EXTERNAL_SCALE))
                layeredMask2BaseUv = o.uv.zw;
                #endif
                o.layeredMaskUv.xy = layeredMaskBaseUv * _MaskTex_ST.xy + _MaskTex_ST.zw
                    + layeredTime * _MaskPanning.xy * _MaskTex_ST.xy;
                o.layeredMaskUv.zw = layeredMask2BaseUv * _Mask2Tex_ST.xy + _Mask2Tex_ST.zw
                    + layeredTime * _Mask2Panning.xy * _Mask2Tex_ST.xy;
                #if defined(DISTORTION_SIMPLE)
                o.layeredDistortionUv = i.uv1.xy * _DistortionTex_ST.xy +
                    _DistortionTex_ST.zw + layeredTime * _DistortionPanning.xy *
                    _DistortionTex_ST.xy * 0.1;
                #endif
                #elif defined(MASK)
                float2 maskBaseUv = i.uv1.xy;
                #if defined(SECONDARY_UVS_MASK) && \
                    (defined(_SECONDARY_UVS_IMPORT) || defined(_SECONDARY_UVS_EXTERNAL_SCALE))
                maskBaseUv = o.uv.zw;
                #endif
                o.maskUv = maskBaseUv * _MaskTex_ST.xy + _MaskTex_ST.zw
                    + time.y * _MaskPanning.xy * _MaskTex_ST.xy;
                #elif defined(MASK2)
                float2 mask2BaseUv = i.uv1.xy;
                #if defined(SECONDARY_UVS_MASK2) && \
                    (defined(_SECONDARY_UVS_IMPORT) || defined(_SECONDARY_UVS_EXTERNAL_SCALE))
                mask2BaseUv = o.uv.zw;
                #endif
                o.mask2Uv = mask2BaseUv * _Mask2Tex_ST.xy + _Mask2Tex_ST.zw
                    + time.y * _Mask2Panning.xy * _Mask2Tex_ST.xy;
                #endif
                #if defined(SECONDARY_COLOR)
                // Game 1.44.3 (vertex 610b0183): the secondary-color sample UV is
                // the raw main (or imported secondary) UV transformed by the
                // secondary texture's own ST, plus time panning.
                #if defined(_SECONDARY_UVS_IMPORT)
                o.secondaryUv = i.uv2.xy;
                #else
                o.secondaryUv = i.uv1.xy;
                #endif
                #endif
                #if defined(DISTORTION_SIMPLE) && !(defined(MASK) && defined(MASK2))
                #if defined(SECONDARY_UVS_DISTORTION) && \
                    !defined(WORLDSPACE_PANNING_DISTORTION) && \
                    (defined(_SECONDARY_UVS_IMPORT) || defined(_SECONDARY_UVS_EXTERNAL_SCALE))
                float2 distortionBaseUv = o.uv.zw;
                #else
                float2 distortionBaseUv = i.uv1.xy;
                #endif
                #if defined(WORLDSPACE_PANNING_DISTORTION)
                // The recovered route uses the same basis and matrix term as main UVs.
                float3 distortionBitangent =
                    i.tangent.yzx * i.normal.zxy - i.normal.yzx * i.tangent.zxy;
                float2 distortionProjection = abs(float2(
                    dot(_UVScale.xyz, i.tangent.xyz),
                    dot(_UVScale.xyz, distortionBitangent))) * _DistortionTex_ST.xy;
                float2 distortionUv =
                    distortionBaseUv * distortionProjection + _DistortionTex_ST.zw;
                float2 distortionPan = time.y * _DistortionPanning.xy;
                distortionPan *= distortionProjection;
                distortionUv += distortionPan * 0.1;

                float3 worldToObjectRow = unity_WorldToObject._m30_m31_m32;
                float2 worldspaceSpeedProjection;
                worldspaceSpeedProjection.y = dot(
                    abs(i.normal.xyz),
                    worldToObjectRow.yzy * float3(-1.0, 1.0, 1.0));
                worldspaceSpeedProjection.x = dot(
                    abs(i.normal.yzx), worldToObjectRow.xxz);
                distortionUv += worldspaceSpeedProjection * _WorldspacePanningSpeed;
                o.distortionUv = distortionUv + _UVManualOffset.xy;
                #else
                o.distortionUv = distortionBaseUv * _DistortionTex_ST.xy + _DistortionTex_ST.zw
                    + time.y * _DistortionPanning.xy * _DistortionTex_ST.xy * 0.1;
                #endif
                #endif
                #if defined(SECONDARY_COLOR)
                o.secondaryUv = o.secondaryUv * _SecondaryColorTex_ST.xy + _SecondaryColorTex_ST.zw
                    + time.y * _SecondaryColorPanning.xy * _SecondaryColorTex_ST.xy;
                #endif
                o.screenPos = ComputeScreenPosCustom(o.vertex);
                #if defined(NOISE_DITHERING)
                o.noiseScreenPos = BuildNoiseScreenPosition(
                    o.screenPos, o.vertex, _GlobalBlueNoiseParams,
                    _GlobalRandomValue, unity_ObjectToWorld._m03_m13);
                #endif
                // Vertex evidence 28ca48d558555d4a32f7f720ed95a43535436a9ee91ac9adeb6a094d4bd65cab
                // carries particle eye depth only when soft particles have depth support.
                #if defined(SOFT_PARTICLES) && (defined(DEPTH_TEXTURE) || defined(DEPTH_TEXTURE_ENABLED))
                o.screenPos.z = -mul(UNITY_MATRIX_V, float4(o.worldPos, 1.0)).z;
                #endif

                #if defined(TEXTURE_FLIPBOOK)
                // CustomParticles uses packed RGBA frames inside each atlas cell. The
                // frame fraction blends adjacent channels; it does not select a whole
                // atlas image as a conventional flipbook does.
                // Game vertex 5ef6afe6d212829d: the initial cells play once. After
                // the atlas end, only the remaining cells loop. This timing belongs
                // to packed texture flipbooks, not to a specific environment.
                float flipbookTime = (
                    GetTime(UNITY_ACCESS_INSTANCED_PROP(Props, _TimeOffset)).y -
                    UNITY_ACCESS_INSTANCED_PROP(Props, _StartTime)) * _FlipbookSpeed;
                float flipbookTotal = trunc(_FlipbookColumns * _FlipbookRows);
                float flipbookLoopCount = trunc(
                    flipbookTotal - _FlipbookNonloopableFrames);
                float flipbookFrame = flipbookTime;
                if (flipbookTime >= flipbookTotal)
                {
                    flipbookFrame = frac(
                        (flipbookTime - _FlipbookNonloopableFrames) /
                        flipbookLoopCount) * flipbookLoopCount +
                        _FlipbookNonloopableFrames;
                }

                float flipbookCell = floor(flipbookFrame);
                float flipbookFraction = frac(flipbookFrame);
                float flipbookColumn = fmod(flipbookCell, _FlipbookColumns);
                float flipbookRow = floor(flipbookCell / _FlipbookColumns);
                // All recovered packed-flipbook vertices bypass _MainTex_ST and
                // panning. Build the atlas coordinates from the raw input UV.
                o.uv.xy = float2(
                    (i.uv1.x + flipbookColumn) / _FlipbookColumns,
                    (i.uv1.y + (_FlipbookRows - 1.0 - flipbookRow)) / _FlipbookRows);

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
                    o.vertex = UnityObjectToClipPos(float4(0, 0, 0, i.color.a));

                #if defined(VERTEX_FLIPBOOK_FADE)
                float vfFade = saturate((i.color.r - vfPhase / vfCount) * vfCount);
                float vfSmooth = vfFade * vfFade * (3.0 - 2.0 * vfFade);
                vfFade = vfSmooth * vfSmooth;
                #endif
                #endif

                #if defined(VERTEX_COLOR)
                float vertexAlpha = i.color.a;
                #if defined(VERTEX_RED_IS_ALPHA)
                vertexAlpha = i.color.r;
                #endif
                #if defined(_VERTEXCHANNELS_A)
                o.color = float4(1, 1, 1, vertexAlpha);
                #else
                o.color = float4(i.color.rgb, vertexAlpha);
                #endif

                #endif
                #if defined(VERTEX_FLIPBOOK) && defined(VERTEX_FLIPBOOK_FADE)
                o.color.a *= vfFade;
                #endif
                #if defined(LIFETIME)
                float lifetime = 4.0 * i.uv1.z * (1.0 - i.uv1.z);
                o.color.a *= lifetime * lifetime;
                #endif
                #if defined(SPECTROGRAM_COLOR)
                // Game 1.44.3 (vertex d2178af6c7f7f78f): calculate the bar
                // factor per vertex and carry it with the raw color factor.
                float spectrogramIndex = i.uv3.x * _UV3Scale + _UV3Offset;
                float binValue = _SpectrogramData[CalculateSpectrogramIndex(spectrogramIndex)];
                float rangeDivisor = 1.0 / max(binValue - _SpectrogramRange * binValue, 0.0001);
                float t = saturate(rangeDivisor * (i.uv3.y - _SpectrogramRange * binValue));
                float sm = t * t * (3.0 - 2.0 * t);
                float brightness = max(sm * binValue * 1.5, _SpectrogramBaseValue);
                o.color *= (float)(binValue >= i.uv3.y) * brightness;
                #endif
                #if defined(MESH_PACKING)
                // Game 1.44.3 stores the packed sub-mesh id in the additional UV stream,
                // and the active id is supplied per draw.
                // ChroMapper draws each material separately, so the material property
                // fills the per-draw id role.
                float packingCull = abs(i.uv2.y - UNITY_ACCESS_INSTANCED_PROP(Props, _MeshPackingId)) > 0.1;
                o.vertex.xyz = packingCull ? float3(0.0, 0.0, 0.0) : o.vertex.xyz;
                #endif

                #if defined(COLOR_ARRAY)
                o.colorIndexUv.x = i.uv2.x;
                o.colorIndexUv.y = i.uv2.y + _ColorsArrayOffset;
                #endif

                #if defined(VIEW_ALIGN_DISAPPEAR)
                o.worldNormal = UnityObjectToWorldNormal(i.normal);
                #endif

                float3 bloomFogCameraOffset = o.worldPos - GetParticlesCameraPosition();
                o.bloomFogDistanceSquared = dot(bloomFogCameraOffset, bloomFogCameraOffset);

                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                float4 time = GetTime(UNITY_ACCESS_INSTANCED_PROP(Props, _TimeOffset));

                #if defined(PLANE_CLIPPING)
                // Fragment 4eed5d58254824a2...: discard the negative half-space.
                if (dot(i.worldPos - _ClippingPlanePosition.xyz,
                        _ClippingPlaneNormal.xyz) < 0.0)
                    discard;
                #endif

                float worldNoiseCutoutFactor = 1.0;
                #if defined(_CUTOUTTYPE_WORLDSPACE_NOISE)
                // Fragments 5431f008df503651... and 4eed5d58254824a2...:
                // object-relative world position, 1.1 threshold bias, then the
                // cubic smoothstep ramp over _CutoutGradientWidth.
                float3 cutoutPosition = i.worldPos - unity_ObjectToWorld._m03_m13_m23;
                float cutoutNoise = tex3D(
                    _CutoutTex,
                    (cutoutPosition + _CutoutTexOffset.xyz) * _CutoutTexScale).a;
                float cutoutDistance = cutoutNoise - 1.1 * _Cutout + 0.1;
                if (cutoutDistance < 0.0) discard;
                float cutoutRamp = saturate(cutoutDistance / max(_CutoutGradientWidth, 1e-6));
                worldNoiseCutoutFactor = cutoutRamp * cutoutRamp * (3.0 - 2.0 * cutoutRamp);
                #endif

                #if defined(COLOR_ARRAY)
                // Decode packed index: tens digit in x, units digit in y (with offset applied in vert)
                float _colorIdx = round(i.colorIndexUv.x * 10.0 + i.colorIndexUv.y);
                float4 color = _ColorsArray[_colorIdx];
                #else
                float4 color = UNITY_ACCESS_INSTANCED_PROP(Props, _Color);
                #endif
                #if defined(SECONDARY_COLOR) && !defined(COLOR_ARRAY)
                {
                    // Game 1.44.3 (fragment 2999a954): the material color becomes
                    // the secondary blend, and the alpha factor is the maximum of
                    // the two color alphas.
                    float secBlend = saturate(tex2D(_SecondaryColorTex, i.secondaryUv).r);
                    float4 secondaryColor = UNITY_ACCESS_INSTANCED_PROP(Props, _SecondaryColor);
                    float4 primaryColor = UNITY_ACCESS_INSTANCED_PROP(Props, _Color);
                    float4 blended = float4(
                        lerp(primaryColor.rgb, secondaryColor.rgb, secBlend),
                        max(primaryColor.a, secondaryColor.a));
                color = blended;
                }
                #endif
                #if defined(VERTEX_COLOR)
                // Vertex factors are raw COLOR channels. Square only the selected
                // vertex alpha factor; material/MPB alpha remains applied once.
                float vertexAlphaFactor = i.color.a;
                #if defined(VERTEX_SQUARE_ALPHA)
                vertexAlphaFactor *= vertexAlphaFactor;
                #endif
                color.rgb *= i.color.rgb;
                color.a *= vertexAlphaFactor;
                #else
                // Spectrogram color is the only non-vertex-color factor carried here.
                color *= i.color;
                #endif
                color *= GetSpriteRendererColor();
                color.rgb *= _Intensity;

                float4 albedo = color;
                #if defined(MAIN_TEXTURE)
                float mainTextureBlue = 1.0;
                #if defined(PIXELATE)
                float2 uv = floor(i.uv.xy * _PixelateResolution) / _PixelateResolution;
                #else
                // Step 1: start from interpolated UV
                float2 uv = i.uv.xy;
                // Step 2: apply distortion to base UV first, so flipbook inherits it
                #if defined(DISTORTION_SIMPLE)
                {
                    #if defined(MASK) && defined(MASK2)
                    // Fragment db5d6342028cbf16 scales the sampled flow before
                    // its signed offset; the -1 term is not scaled.
                    float2 distortionSample = tex2D(
                        _DistortionTex, i.layeredDistortionUv).rg;
                    uv += distortionSample * (_DistortionStrength * 0.1) *
                        _DistortionAxes.xy * 2.0 - 1.0;
                    #else
                    float2 distortScrollUv = i.distortionUv;
                    float2 distortionSample = tex2D(_DistortionTex, distortScrollUv).rg;
                    uv += distortionSample * (_DistortionStrength * 0.1) *
                        _DistortionAxes.xy * 2.0 - 1.0;
                    #endif
                }
                #endif
                #if defined(CUSTOM_WRAPPING)
                {
                    // Fragment 641ba0cb: preserve the signed wrapping period.
                    float2 customPadding = _CustomPadding + 1.0;
                    float2 biasedUv = customPadding * 10.0 + uv;
                    float2 wrappingProduct = customPadding * biasedUv;
                    float2 wrappingPeriod = float2(
                        wrappingProduct.x >= -wrappingProduct.x
                            ? customPadding.x
                            : -customPadding.x,
                        wrappingProduct.y >= -wrappingProduct.y
                            ? customPadding.y
                            : -customPadding.y);
                    uv = frac(biasedUv / wrappingPeriod) * wrappingPeriod;
                }
                #endif
                #endif
                #if defined(TEXTURE_FLIPBOOK)
                {
                    // Each atlas cell contains up to four frames in RGBA. The vertex
                    // stage supplies the channel blend weights decoded from the source
                    // flipbook route.
                    float4 flipbookSample = tex2D(_MainTex, uv);
                    mainTextureBlue = flipbookSample.b;
                    float flipbookValue = dot(flipbookSample, i.flipbookWeights);
                    #if defined(_CUTOUTTYPE_ALPHA_CLIP)
                    // Alpha-clip variants compare source alpha times effective color
                    // alpha before masks, fades, fog, dither, and alpha processing.
                    if (flipbookValue * color.a < _Cutout) discard;
                    #endif
                    albedo.a *= flipbookValue;
                }
                #else
                // Non-flipbook path: sample using distorted uv
                #if defined(TEXTURE_COLOR)
                // Sample full RGBA — RGB multiplies into color, alpha drives transparency
                #if defined(MIPMAP_BIAS)
                 float4 _texSample = tex2Dbias(_MainTex, float4(uv, 0, _MipmapBias));
                 #else
                 float4 _texSample = tex2D(_MainTex, uv);
                 #endif
                 mainTextureBlue = _texSample.b;
                albedo.rgb *= _texSample.rgb * _BaseLayer;
                #if defined(_ALPHACHANNEL_RED)
                #if defined(_CUTOUTTYPE_ALPHA_CLIP)
                if (_texSample.r * color.a < _Cutout) discard;
                #endif
                albedo.a *= _texSample.r;
                #else
                #if defined(_CUTOUTTYPE_ALPHA_CLIP)
                if (_texSample.a * color.a < _Cutout) discard;
                #endif
                albedo.a *= _texSample.a;
                #endif
                #else
                // Non-texture-color: only alpha channel drives transparency
                #if defined(MIPMAP_BIAS)
                float4 _mipSample = tex2Dbias(_MainTex, float4(uv, 0, _MipmapBias));
                 #else
                 float4 _mipSample = tex2D(_MainTex, uv);
                 #endif
                 mainTextureBlue = _mipSample.b;
                #if defined(_ALPHACHANNEL_RED)
                #if defined(_CUTOUTTYPE_ALPHA_CLIP)
                if (_mipSample.r * color.a < _Cutout) discard;
                #endif
                albedo.a *= _mipSample.r;
                #else
                // Keep texture alpha out of RGB. Final premultiplication applies it once.
                #if defined(_CUTOUTTYPE_ALPHA_CLIP)
                if (_mipSample.a * color.a < _Cutout) discard;
                #endif
                albedo.a *= _mipSample.a;
                #endif
                #endif
                #endif
                #endif

                #if defined(MASK)
                #if defined(MASK2)
                float2 maskUv = i.layeredMaskUv.xy;
                #else
                float2 maskUv = i.maskUv;
                #endif
                float2 maskSampleUv = maskUv;
                // Britney orphan-mask evidence fff04977a2ce473345eff9e1bc27c9b117137b252b2c3b227e87c3bbc6aff6ec
                // has no distortion sample: the mask target requires the simple-distortion parent.
                float4 _maskSample = tex2D(_MaskTex, maskSampleUv);
                float maskStrength = UNITY_ACCESS_INSTANCED_PROP(Props, _MaskStrength);
                #if defined(MASK_RED_IS_ALPHA)
                float maskValue = _maskSample.r;
                #else
                float maskValue = _maskSample.a;
                #endif
                #if defined(_MASKBLEND_ADD)
                albedo.a += maskValue * maskStrength * color.a;
                #elif defined(_MASKBLEND_MASKED_ADD)
                albedo.a *= 1.0 + maskValue * maskStrength;
                #else
                albedo.a *= lerp(1.0, maskValue, maskStrength);
                #endif
                #endif

                #if defined(MASK2)
                #if defined(MASK)
                float2 mask2Uv = i.layeredMaskUv.zw;
                #else
                float2 mask2Uv = i.mask2Uv;
                #endif
                float2 mask2SampleUv = mask2Uv;
                float4 _mask2Sample = tex2D(_Mask2Tex, mask2SampleUv);
                float mask2Strength = UNITY_ACCESS_INSTANCED_PROP(Props, _Mask2Strength);
                #if defined(MASK2_RED_IS_ALPHA)
                float mask2Value = _mask2Sample.r;
                #else
                float mask2Value = _mask2Sample.a;
                #endif
                #if defined(_MASK2BLEND_ADD)
                albedo.a += mask2Value * mask2Strength * color.a;
                #elif defined(_MASK2BLEND_MASKED_ADD)
                albedo.a *= 1.0 + mask2Value * mask2Strength;
                #else
                albedo.a *= lerp(1.0, mask2Value, mask2Strength);
                #endif
                #endif

                #if defined(COLOR_GRADIENT)
                // Recovered fragments sample the gradient after both mask layers.
                // The LUT uses the unsaturated accumulated alpha and CustomTime.x.
                float2 gradientUv = float2(
                    albedo.a,
                    frac(_GradientPosition + time.x * _GradientPanningSpeed));
                float4 gradient = tex2D(_ColorGradient, gradientUv);
                albedo.rgb *= gradient.rgb;
                #endif

                // Dissolve applies the recovered axis factor to the existing alpha chain.
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
                albedo.a *= t;
                }
                #endif
                // Lifetime / soft particles / close-to-camera: alpha-chain gates decoded
                // from LIFETIME (e7fc61bdf833e455), SOFT_PARTICLES (ebdcf1970fae8aeb)
                // and CLOSE_TO_CAMERA_DISAPPEAR (db0bff392a1dacb8) fragments.
                // Britney no-global evidence ebdcf1970fae8aebda52d280eda3714430d252c10ecdd4fadb74b064ec9666f7
                // has no depth sample. Depth-enabled evidence f316ae8ed7c1d00d20b76511973fd04e3dc11c374e9ab3f4728b9e6db89901d0
                // recovers depth-texture clamp, viewport scaling, biased sampling, reciprocal decode,
                // particle-eye-depth subtraction, and saturated _SoftFactor fading.
                #if defined(SOFT_PARTICLES) && (defined(DEPTH_TEXTURE) || defined(DEPTH_TEXTURE_ENABLED))
                {
                    float2 projectedUv = i.screenPos.xy / i.screenPos.w;
                    float2 projectionLimit = 1.0 - 0.5 * _CameraDepthTexture_TexelSize.xy;
                    projectedUv = min(projectedUv, projectionLimit);
                    #if defined(UNITY_SINGLE_PASS_STEREO) || defined(STEREO_INSTANCING_ON) || defined(STEREO_MULTIVIEW_ON)
                    projectedUv = UnityStereoTransformScreenSpaceTex(projectedUv);
                    #endif
                    // The recovered SampleBias value is neutral in ChroMapper's
                    // full-resolution built-in depth route. Use Unity's depth macro
                    // so stereo texture-array sampling remains platform-safe.
                    float rawDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, projectedUv);
                    float sceneDepth = 1.0 / (_ZBufferParams.z * rawDepth + _ZBufferParams.w);
                    float softFade = saturate((sceneDepth - i.screenPos.z) * _SoftFactor);
                    albedo.a *= softFade;
                }
                #endif

                #if defined(CLOSE_TO_CAMERA_DISAPPEAR)
                // Game 1.44.3 (fragment db0bff39): linear gate on view-space
                // eye depth, not Euclidean distance and not smoothstepped.
                float eyeDepth = -mul(UNITY_MATRIX_V, float4(i.worldPos, 1.0)).z;
                float fade = saturate((eyeDepth - _CloseCameraDisappearDistance)
                    * _CloseCameraDisappearWidth);
                albedo.a *= fade;
                #endif

                #if defined(VIEW_ALIGN_DISAPPEAR)
                float3 cameraToParticle = normalize(i.worldPos - GetParticlesCameraPosition());
                float alignment = abs(dot(cameraToParticle, normalize(i.worldNormal)));
                if (_SquareAngleForViewAlignDisappear > 0.5)
                    alignment *= alignment;
                float viewAlign = alignment * _ViewAlignFactor + _ViewAlignOffset;
                if (_ViewAlignFactor < 0.0) viewAlign += 1.0;
                // Fragment e17f3714 clamps only the upper bound. Negative
                // factors remain available to the later alpha stages.
                albedo.a *= min(viewAlign, 1.0);
                #endif

                #if !defined(_CUTOUTTYPE_ALPHA_CLIP)
                albedo.a *= _AlphaMultiplier;
                albedo.a *= worldNoiseCutoutFactor;

                #if defined(SQUARE_ALPHA)
                // The source square route is saturate(alpha) * alpha, not alpha squared.
                albedo.a *= saturate(albedo.a);
                #endif
                #endif

                #if defined(NOISE_DITHERING) && defined(_FOGTYPE_COLOR) && defined(HEIGHT_FOG) \
                    && !defined(BLOOM_FOG) && !defined(COLOR_BY_FOG) \
                    && !defined(_CUTOUTTYPE_ALPHA_CLIP)
                #define PARTICLES_DITHER_AFTER_COLOR_FOG 1
                #endif

                // Consolidated CustomParticles white boost: the shared Lit composition
                // (premultiply + white-boost term) over the alpha chain. The remap
                // folds into the boost input only (DXBC 04ac3ff0), the white-boost
                // multiplier slot feeds both type routes (DXBC 137.w), and only the
                // Mixed route scales the output alpha (DXBC 138.x slot; the Deferred
                // route matches it only when POST_BLOOM is on, DXBC e025580b).
                #if defined(NOISE_DITHERING) && !defined(_CUTOUTTYPE_ALPHA_CLIP) \
                    && !defined(PARTICLES_DITHER_AFTER_COLOR_FOG)
                // Screen-space dither noise added to color before premultiply
                // (game: noise.r - 0.5 * 1/255, added pre-bloom).
                albedo = ApplyNoiseDither(
                    albedo, i.noiseScreenPos, _GlobalBlueNoiseTex);
                #endif

                #if defined(HOLOGRAM)
                // Game 1.44.3 (fragment 26e48514): the pattern is anchored to
                // the object's local position and time includes the custom
                // time terms.
                float hTime = time.w;
                float3 lp = i.localPos;
                float bandIn = min(frac((hTime + lp.y * 0.99) * 0.2) * 2.0, 1.0);
                float bandS = min(bandIn * 20.0, 1.0);
                float band = bandS * bandS * (3.0 - 2.0 * bandS) * (1.0 - bandIn);
                float3 gridArg = lp * 3.0 - hTime * float3(0.0, 1.0, 0.0);
                float grid = sin(frac(gridArg.x) * 3.14159)
                    * sin(frac(gridArg.y) * 3.14159)
                    * sin(frac(gridArg.z) * 3.14159);
                grid *= 1.2 * 1.2 * 1.2;
                float wave = cos(hTime * 2.0 + lp.x + lp.y - lp.z * 7.0) * 0.4 + 0.8;
                albedo.rgb += band * (band + grid * wave) * _HologramColor.rgb;
                #endif

                #if defined(COLOR_BY_FOG)
                // The particle family uses the same recovered color-fog curve as
                // Custom/Lit. Primary-mask variants blend that result by layer 2.
                float4 unfoggedColor = albedo;
                float4 colorFog = ApplyColorFog(
                    albedo, i.worldPos, _ObstacleFogMultiplier, _ObstacleFogMax,
                    _ObstacleFogHighlightMultiplier, _ObstacleColorInfluence,
                    _FogHeightScale, _FogHeightOffset);
                #if defined(_FOG_MASK_SOURCE_PRIMARY_MASK) && defined(MASK)
                albedo = lerp(unfoggedColor, colorFog, saturate(maskValue));
                #else
                albedo = colorFog;
                #endif
                #endif

                #if FOG && !defined(BLOOM_FOG) && defined(HEIGHT_FOG) && !defined(COLOR_BY_FOG)

                // Source retained non-bloom fog routes use height fog only. Distance fog
                // is supplied by the separate BLOOM_FOG path and is not present in these variants.
                float fogClearFactor = CalculateParticleHeightFogClearFactor(i.worldPos);
                float fogAlphaFactor = 1.0 - fogClearFactor;
                float whiteBoostFogFactor = 1.0;
                #if defined(_FOGTYPE_LERP)
                // LERP changes RGB only. Its clear factor still attenuates the
                // white-boost input on the represented boost route.
                albedo.rgb = lerp(albedo.rgb, float3(0.1, 0.1, 0.1), fogClearFactor);
                whiteBoostFogFactor = fogAlphaFactor;
                #elif defined(_FOGTYPE_COLOR)
                // The retained COLOR route uses the source 0.1 fog color and gates alpha.
                albedo.rgb *= 0.1;
                albedo.a *= fogAlphaFactor;
                #if defined(PARTICLES_DITHER_AFTER_COLOR_FOG)
                albedo = ApplyNoiseDither(
                    albedo, i.noiseScreenPos, _GlobalBlueNoiseTex);
                #endif
                #elif defined(_FOGTYPE_ALPHA)
                // ALPHA changes alpha only; final premultiplication scales RGB once.
                albedo.a *= fogAlphaFactor;
                #endif

                #endif

                #if defined(_CUTOUTTYPE_ALPHA_CLIP)
                // Alpha-clip fragments 953990a3053f67d9 and 40d13975545fd678:
                // early source-alpha clip, fog, optional dither, alpha multiplier,
                // optional square alpha, then final premultiplication.
                #if defined(NOISE_DITHERING)
                albedo = ApplyNoiseDither(
                    albedo, i.noiseScreenPos, _GlobalBlueNoiseTex);
                #endif
                albedo.a *= _AlphaMultiplier;
                albedo.a *= worldNoiseCutoutFactor;
                #if defined(SQUARE_ALPHA)
                albedo.a *= saturate(albedo.a);
                #endif
                #endif

                float bloomValue = albedo.a;
                #if FOG && !defined(BLOOM_FOG) && defined(HEIGHT_FOG) && \
                    !defined(COLOR_BY_FOG) && defined(_FOGTYPE_LERP)
                float boostInput = bloomValue * whiteBoostFogFactor;
                #else
                float boostInput = bloomValue;
                #endif
                float whiteboostMultiplier = _QuestWhiteboostMultiplier;
                #if defined(REMAP_WHITEBOOST_START)
                boostInput = (bloomValue * _QuestWhiteboostMultiplier - _WhiteBoostRemapStart)
                    / max(1.0 - _WhiteBoostRemapStart, 1e-4);
                boostInput = max(boostInput, 0.0);
                whiteboostMultiplier = 1.0;
                #endif
                #if defined(_WHITEBOOSTTYPE_ALWAYS) || (defined(_WHITEBOOSTTYPE_MAINEFFECT) && !defined(POST_BLOOM))
                albedo.rgb = CalculateBloomComposition(albedo.rgb, bloomValue, boostInput, whiteboostMultiplier,
                                                       _BaseColorBoost, _BaseColorBoostThreshold);
                #if defined(_WHITEBOOSTTYPE_ALWAYS)
                albedo.a = bloomValue * _BloomMultiplier;
                #else
                albedo.a = bloomValue;
                #endif
                #elif defined(_WHITEBOOSTTYPE_MAINEFFECT)
                // POST_BLOOM on: the post-process bloom provides the glow, so the
                // Deferred route compiles the boost out (game: MAIN_EFFECT_ENABLED on,
                // DXBC e025580b). Plain premultiplied composition, alpha scaled
                // like the Mixed route.
                albedo = CalculateBloomPostComposition(albedo.rgb, bloomValue, _BloomMultiplier);
                #else
                albedo.rgb *= abs(albedo.a);
                #endif

                #if defined(FAKE_MIRROR_TRANSPARENCY)
                // Fake mirror transparency: premultiplied output becomes a dark glass
                // quad. The game squares the main transparency slot into alpha and RGB.
                float total = _FakeMirrorTransparency * _FakeMirrorTransparency *
                    _BloomMultiplier;
                albedo.rgb *= total;
                albedo.a = total;
                #endif

                #if defined(FILL_ALPHA)
                // Fragment 5431f008: fill is an RGB floor, not a replacement alpha.
                float fillCoverage = _FillAlpha * worldNoiseCutoutFactor;
                #if defined(MAIN_TEXTURE)
                if (_FillMask > 0.5)
                    fillCoverage *= mainTextureBlue;
                #endif
                #if defined(HEIGHT_FOG)
                fillCoverage *= CalculateParticleHeightFogClearFactor(i.worldPos);
                #endif

                float3 fillColor = UNITY_ACCESS_INSTANCED_PROP(Props, _Color).rgb;
                if (_FillColor > 0.5 && _FillColor < 1.5)
                    fillColor = albedo.rgb;
                else if (_FillColor > 1.5 && _FillColor < 2.5)
                    fillColor = float3(0, 0, 0);
                else if (_FillColor > 2.5)
                    fillColor = float3(1, 1, 1);
                albedo.rgb = max(albedo.rgb, fillColor * fillCoverage);
                #endif

                #if defined(_OVERRIDE_FINAL_ALPHA_COLOR_BASED)
                // Final alpha derived from color brightness: dark pixels stay opaque.
                float maxComp = max(max(albedo.r, albedo.g), albedo.b);
                albedo.a = _OverrideFinalAlpha * (1.0 - maxComp);
                #endif

                #if defined(BLOOM_FOG)

                // Game 1.44.3 bloom-fog routes (fragments 19a980f8, d525d2b1,
                // 0d8f52d5, a262264a, 31686655): the material applies analytic
                // fog. Height fog gates alpha with the smoothstep ramp; the
                // distance term attenuates it. The fog texture supplies the fog
                // color for the COLOR and LERP routes (ALPHA never samples it).
                float distanceFog = 1.0 - CalculateCustomFogFactor(
                    i.bloomFogDistanceSquared, _FogStartOffset, _FogScale);
                float fogAmount = distanceFog;
                #if defined(HEIGHT_FOG)
                float fogClearFactor = CalculateParticleHeightFogClearFactor(i.worldPos);
                fogAmount = (1.0 - fogClearFactor) * distanceFog;
                #endif
                #if defined(_FOGTYPE_ALPHA)
                albedo.a *= fogAmount;
                #elif defined(_FOGTYPE_COLOR)
                albedo.rgb *= SampleBloomPrePass(i.screenPos).rgb;
                albedo.a *= fogAmount;
                #elif defined(_FOGTYPE_LERP)
                albedo.rgb = lerp(albedo.rgb, SampleBloomPrePass(i.screenPos).rgb, 1.0 - fogAmount);
                #endif

                #endif

                return albedo;
            }
            ENDHLSL
        }
    }
}
