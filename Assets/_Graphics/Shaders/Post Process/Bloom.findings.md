# Post Process Bloom Findings

## Scope

Recovery of the game's full-screen bloom post-process (`Hidden/PostProcessing/Bloom`)
and its replacement of the Unity Post Processing v2 pipeline in ChroMapper.
The complete pyramid (prefilter, downsample/upsample, combine) now runs in
`CustomBloom.shader`, driven per-frame by `BloomRenderer` (built-in RP
`OnRenderImage`), and the PPv2 package, profiles, volumes, and layer components
have been removed from the project. Chromatic aberration (the PPv2 effect that
was active in the mapper scene) was ported into the same shader as an extra
pass.

## Source Inventory

- Corpus: `/home/kival/beat-saber-shaders-1.44.3/by-shader/Shaders/Hidden/PostProcessing/Bloom/`
  - 281 program occurrences, 46 unique fragment binaries, 60 keyword variants.
  - Keywords: only `IS_SCREENSPACE_EFFECT` + `STEREO_INSTANCING_ON` (no local
    keywords, no stock-PPv2 soft-knee variants).
- Bundle: `sharedassets_assets_all_5a1884675c6f9c74e663e3e0d934338d.bundle`.
- Project asset `Assets/Libraries/HM/Rendering/Bloom/Bloom.shader` is a stripped
  dummy (DummyShaderTextExporter) - the real code exists only as compiled binaries.
- Decompiled project path: `/mnt/programs/Code/Beat Saber/Decomp 1.42.100/ExportedProject/Assets/Libraries/HM/Rendering/Bloom/`
  - `PyramidBloomRenderer.asset` (script `PyramidBloomRendererSO`, stripped).
  - `PyramidBloomMainEffectSO.cs` - stripped. Runtime parameter values
    (threshold gate k, intensity, adaptive flag) are not recoverable; only the
    math shapes below are.
- Game source for the runtime side (1.44.2, not stripped):
  `/home/kival/Code/Beat Saber/1.44.2/HMRendering/`
  - `PyramidBloomRendererSO.cs` - the command-buffer driver: `RenderBloom`
    writes `_BloomParams = Vector4(autoExposureLimit, fractionalLod, alphaWeights,
    legacyAutoExposure ? 1 : 0)` (line 166) and binds `_GlobalIntensityTex` to the
    smallest pyramid level (line 176), the per-frame probe.
  - `BloomFogSO.cs` / `BloomFogEnvironmentParams.cs` / `BloomFogEnvironment.cs`:
    the per-environment authored values (autoExposureLimit default 1000,
    legacyAutoExposure default false) and their transitions, plus the in-Unity
    tooltips quoted below.
  - Version note: 1.44.2 declares a `LEGACY_AUTOEXPOSURE` global keyword
    (`PyramidBloomRendererSO.cs:53`); the 1.44.3 compiled fragments ship without
    it - the flag was folded into the `_BloomParams.w` uniform between versions.
- Not the bloom: `Hidden/MainEffect` is the screen-clear pass (`CLEAR_SCREEN_ALPHA`),
  not a bloom pass. `Custom/BloomPrePassLine` and `Custom/BloomSkyboxQuad` render
  bloom sources into the main buffer.

## Recovered Prefilter

- Fragment: `fragment-9bbb0fcf745e8647.hlsl` (13-tap, alpha-gated).
- Kernel: 4 taps at `uv + texelSize * (+-0.5, +-0.5)` weighted 1/8 each, plus 9 taps
  at `uv + texelSize * {-1, 0, 1}^2` with corner/cross/center weights
  1/32 / 2/32 / 3/32 (center 0.09375, cross 0.0625, corner 0.03125). The ring
  weights are the binary's exact accumulation (the compiler batches the ring as
  4 groups of 4 taps at 1/32 each, double/triple-counting center and cross
  samples). Total weight 31/32 (0.96875); PPv2's `DownsampleBox13Tap` uses a
  different, normalized layout - do not substitute.
- Gate: `color.rgb *= saturate(color.a * k)` with `k = cb0[103].z`. The gate is
  applied to the 13-tap-averaged alpha.
- Alpha: output alpha = the 13-tap-weighted alpha (`o0.w = r0.w`); the alpha
  channel is the bloom mask and flows through the whole pyramid unchanged
  (27 of 46 fragments end with `o0.w = r0.w`).
- No luminance threshold anywhere in the shader (no soft-knee/1e-5 constants).
  Bloom brightness is driven entirely by the scene alpha.

## Recovered Combine

- Fragment: `fragment-47497f82473c772f.hlsl` (3 textures: t0, t1, t2).
- Merge: `bloom = Tent3x3(t0) * cb0[102].y + t1 * cb0[102].x` (tent weights
  center 4 / edge 2 / corner 1, /16) - the game's final upsample-merge of the
  last two pyramid levels.
- Auto-exposure knee (t2 = per-frame probe, sampled at (0.5, 0.5)). t2 is the
  game's `_GlobalIntensityTex`: the smallest pyramid level, not a separate
  capture - so the "probe" is the Rec601 luma of the averaged bloom pyramid top.
  - `luma = dot(probe.rgb, (0.3, 0.59, 0.11))` (Rec601).
  - `knee = (cb0[103].w > 0) ? min(luma * I, 0.1 / sqrt(luma)) : min(0.004 * I, 0.1 / sqrt(luma))`
    with `I = cb0[103].x`. Both branches clamp by `0.1 / sqrt(luma)`; the
    adaptive branch adds `luma * I`, the fallback `0.004 * I`.
  - Runtime mapping (1.44.2 `PyramidBloomRendererSO.RenderBloom:166`): the vector
    is `_BloomParams = (autoExposureLimit, fractionalLod, alphaWeights,
    legacyAutoExposure ? 1 : 0)`, so `I = autoExposureLimit` (authored per
    environment, default 1000) and the flag `.w = legacyAutoExposure`.
    `legacyAutoExposure = true` selects the luma-proportional branch - the game's
    own tooltip: "Makes AE behave inverted at low light situations, making bloom
    stronger the more lights are on". The `0.004 * I` fallback is the default
    (flag off) "new" AE: a fixed fraction of the limit.
  - The selector is a runtime cbuffer flag written per-frame by C# - NOT a shader
    keyword. The shader's only keywords are `IS_SCREENSPACE_EFFECT` and
    `STEREO_INSTANCING_ON` (60 variants, 4 combos); both knees are compiled into
    every fragment and picked dynamically.
  - `bloom *= knee`.
- Tone curve: `out.rgb = clamp((x * (2.51x + 0.03)) / (x * (2.43x + 0.59) + 0.14), 0, 1)`
  - the ACES fitted curve, byte-identical to ChroMapper's
  `ApplyAcesTonemapping` in `ShaderLibrary/CustomTonemapping.hlsl`.
- Alpha: output alpha = merged bloom alpha (`o0.w = r0.w`).

## Recovered Pyramid Notes (not consolidated)

- Subsequent downsample levels use a 4-tap average plus a cubic gamma curve
  `x * (0.3053x^2 + 0.6822x + 0.0125)` ~= `x^2.2` on [0, 1] (fragments
  `0369ce7b7d900c92`, `0ba741ecaac9dd34`) - the pyramid blurs in perceptual
  space. Alpha is not curve-mapped.
- The 3x3 tent upsample matches PPv2's `UpsampleTent`; CM's existing upsample
  passes already reproduce the merge pattern.

## ChroMapper Consolidation

- `Assets/_Graphics/Shaders/Post Process/CustomBloom.shader`
  (`ChroMapper/Post Process/Bloom`): self-contained since the PPv2 removal -
  the PPv2 helpers it once included are inlined verbatim from the 3.5.4 sources
  (`StdLib.hlsl`/`xRLib.hlsl`/`Sampling.hlsl`/`Uber.shader`): `VertDefault`,
  identity `UnityStereoTransformScreenSpaceTex`, `DownsampleBox13Tap`,
  `DownsampleBox4Tap`, `UpsampleTent`, `UpsampleBox`. The only include is
  `../ShaderLibrary/CustomTonemapping.hlsl` (for `ApplyAcesTonemapping`).
  - `FragPrefilter` (pass 0): the recovered game prefilter - classic 13-tap
    downsample + `rgb *= saturate(a * _BloomThreshold)`. `_BloomThreshold`
    defaults to 1. Runs at the base resolution.
  - Passes 1-2: PPv2 13-tap / 4-tap downsample (fastMode selects 4-tap).
  - Passes 3-4: PPv2 tent / box upsample (fastMode selects box).
  - `FragComposite` (pass 5): the recovered game combine - bloom scaled by the
    auto-exposure knee then ACES-curved via `ApplyAcesTonemapping` before being
    added to the scene.
  - `_BloomParams` (Vector, default (1000, 0, 0, 0)): `x = autoExposureLimit`,
    `w = legacyAutoExposure` flag; both knees always compiled and picked by
    `_BloomParams.w > 0`, exactly like the game's `cb0[103].w` select (no
    keyword). `_Intensity` is ChroMapper's master scale on top (default 1).
  - `_GlobalIntensityTex` (the probe, game property name): sampled at (0.5, 0.5)
    with Rec601 weights; `BloomRenderer` binds it to the top mip of its own
    pyramid every frame (the game's `SetGlobalTexture` of the smallest pyramid
    level).
  - `FragChromaticAberration` (pass 6): PPv2 `Uber.shader` CA port
    (`MAX_CHROMATIC_SAMPLES 16`): `end = uv - coords * dot(coords, coords) *
    amount`, `samples = clamp(int(length(_BloomTexelSize.zw * diff / 2)), 3, 16)`,
    spectral LUT (3x1 R/G/B bilinear, PPv2's default lut), weighted sum /
    filterSum. `amount = chromaticAberrationIntensity * 0.05` (PPv2 renderer's
    `_ChromaticAberration_Amount` scale).
  - Pass 7: debug (unused).
  - `_BloomTexelSize` (float4: xy = 1/size, zw = size) is set per-blit by
    `BloomRenderer` because `Graphics.Blit` does not update `_MainTex_TexelSize`
    for intermediate render textures.
- `Assets/__Scripts/Graphics/PostProcess/BloomRenderer.cs` (replaces the PPv2
  `PostProcessingController` + `CustomBloom` effect pair):
  - `OnRenderImage` driver; pyramid size
    `clamp(floor(log2(max(w, h)) + min(diffusion, 10) - 10), 1, 16)` with
    `sampleScale = 0.5 + logs - logsI` (the game's fractional LOD), ARGBHalf
    temporaries; composite binds `_GlobalIntensityTex` = downs[iterations - 1]
    and `_BloomTex` = last upsample; CA blit last; all temporaries released.
    Null material falls back to a straight blit.
  - Runtime wiring: `Settings.NotifyBySettingName` for `HighQualityBloom`
    (inverts into fastMode) and `ChromaticAberration`; reads
    `EnvironmentDescriptor.BloomFogParams.AutoExposureLimit` via
    `BeatmapRuntimeContext.OnEnvironmentLoaded` (only if > 0; catch-up apply at
    Start if the descriptor already loaded). `OnDestroy` unsubscribes only the
    environment event - the Settings notifications are shared with
    `BloomfogRenderingController` and must never be cleared.
  - Defaults: intensity 1, diffusion 6, autoExposureLimit 1000,
    legacyAutoExposure false, chromaticAberrationIntensity 0.1.
- The game's Post material route (`CalculateBloomPostComposition`,
  alpha = a * bloomMultiplier) feeds this prefilter: the multiplier directly
  controls how much of the pixel reaches the bloom pyramid.

## PPv2 Removal (final state)

- Deleted: `CustomBloom.cs` (PPv2 effect), `PostProcessingController.cs`,
  `Post Processing Profile.asset` (guid `acc9b74072cb2944d977b08f730d61f5`),
  `Post Processing Profile SRP.asset` (guid `7f3ec4364e4caab14abb007a7c9dd6d6`),
  `DefaultVolumeProfile.asset`, `UniversalRenderPipelineGlobalSettings.asset`
  (URP leftovers; the URP pipeline assets had already been deleted earlier).
- `Packages/manifest.json` + `packages-lock.json`: `com.unity.postprocessing`
  3.5.4 removed.
- `ProjectSettings/GraphicsSettings.asset`: the
  `m_RenderPipelineGlobalSettingsMap` entry for
  `UnityEngine.Rendering.Universal.UniversalRenderPipeline` removed;
  `m_AlwaysIncludedShaders` still lists the `CustomBloom.shader` guid
  (`0cbf844ebbd3415b8b4c11e904b8c120`).
- Scenes/prefabs: the "Post Processing" GameObjects + PostProcessVolume +
  PostProcessLayer components removed from `03_Mapper.unity` and
  `999_PrefabBuilding.unity` (including that scene's leftover
  `UniversalAdditionalCameraData` component); the PostProcessLayer was removed
  from `MapEditor Camera.prefab` and `Main Camera (Menus).prefab`; the two
  `m_RenderPostProcessing` prefab-instance overrides in `03_Mapper.unity` were
  removed. In `03_Mapper.unity` the old PostProcessingController component
  (`613879336`) is now a `BloomRenderer` on the same GameObject (renamed
  "Bloom Renderer") with the shader asset bound; the old volume (`613879337`)
  was deleted.
- Camera AA: `CameraController.UpdateAA` no longer touches a PPv2 layer; it maps
  the `CameraAA` setting (0-4) to `QualitySettings.antiAliasing` (MSAA) with
  `Mathf.Clamp((int)aaValue, 0, 4)` - the game has no post-process AA, so 0 and
  1 both disable MSAA.
- Note: the old SRP profile's settings-referenced CustomBloom instance
  (fileID `5843264232844884216`) was never read before deletion; an orphan
  duplicate showed intensity 6 / diffusion 9. The BloomRenderer in `03_Mapper`
  was written with intensity 1 / diffusion 6 / CA 0.1 - tune in the inspector
  if the live profile values differed.
- The old `ADAPTIVE_BLOOM` keyword + `_BloomMaxLumaTex` stay removed: the game
  picks the knee with a runtime uniform (`cb0[103].w`), never a keyword.

## Open Questions

- Prefilter gate `k = cb0[103].z` is a constant of the prefilter fragment's *own*
  cbuffer layout - it must not be read as the combine's `_BloomParams.z`
  (alphaWeights). The 1.44.2 source sets no threshold in `RenderBloom`, so k's
  authored source remains unidentified; ChroMapper's `_BloomThreshold`
  (default 1) stands in for it.
- `alphaWeights` (_BloomParams.z): ChroMapper has no equivalent (the merge
  weights come from PPv2's pyramid); left at 0.
- AE values are per-environment authored (default limit 1000 / legacy off) and
  transition between map fog params via `BloomFogSO` - not single game-wide
  constants.
- The PPv2 CA effect's spectral LUT asset was never serialized in the profile
  (default LUT used); the port hardcodes the same default 3x1 R/G/B lut.

## Validation

- Kernels and constants cross-checked against the extracted fragments
  (`fragment-9bbb0fcf745e8647.hlsl`, `fragment-47497f82473c772f.hlsl`,
  `fragment-0369ce7b7d900c92.hlsl`, `fragment-0ba741ecaac9dd34.hlsl`).
- Runtime mechanism cross-checked against the 1.44.2 decompiled source
  (`HMRendering/PyramidBloomRendererSO.cs` lines 146-176, `BloomFogSO.cs`,
  `BloomFogEnvironmentParams.cs`): the `_BloomParams` mapping (x = limit,
  w = legacy flag) and the `_GlobalIntensityTex` pyramid-top binding match the
  compiled fragments 1:1.
- CA pass and helpers cross-checked against the PPv2 3.5.4 sources
  (`Runtime/PostProcessing/Effects/ChromaticAberration.cs`, `Uber.shader`,
  `StdLib.hlsl`, `Sampling.hlsl`, `xRLib.hlsl` - GitHub v2 tag).
- ACES constants match `ShaderLibrary/CustomTonemapping.hlsl`
  (`ApplyAcesTonemapping`).
- No Unity compiler available in this environment; shader changes are validated
  by review only (balanced conditionals, all helpers exist unconditionally in
  the included libraries), and the scene/prefab YAML edits by reference checks
  (all deleted script/profile guids and fileIDs grepped to zero matches across
  `Assets/` + `ProjectSettings/`).
