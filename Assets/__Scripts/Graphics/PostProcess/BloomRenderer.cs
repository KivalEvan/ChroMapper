using System;
using UnityEngine;

// Custom bloom + chromatic aberration for the editor cameras, replacing Unity's
// Post Processing v2 stack (com.unity.postprocessing is no longer a dependency).
// Drives ChroMapper/Post Process/Bloom through OnRenderImage on the built-in
// render pipeline.
//
// The bloom pyramid mirrors the game's PyramidBloomRendererSO.RenderBloom and the
// previous CustomBloomRenderer (see Bloom.findings.md): a half-size pyramid with
// an alpha-gated prefilter, 13-tap/4-tap box downsampling, tent/box upsampling
// with combine, and a composite that scales the bloom by the auto-exposure knee
// and runs it through the ACES curve before adding it to the scene. Chromatic
// aberration is a port of the PPv2 Uber pass: spectral samples along the radial
// offset with the default R/G/B lookup. AA is camera MSAA (CameraController
// UpdateAA -> QualitySettings.antiAliasing), matching the game, which has no
// post-process AA.
public class BloomRenderer : MonoBehaviour
{
    [SerializeField] private Shader bloomShader;

    [Space]
    // Values the mapper scene's profile fed into the PPv2 CustomBloom effect
    // (Post Processing Profile SRP.asset): intensity 1, diffusion 6, CA 0.1.
    [SerializeField] private float intensity = 1f;
    [SerializeField] private float diffusion = 6f;
    [SerializeField] private float autoExposureLimit = 1000f;
    [SerializeField] private bool legacyAutoExposure;
    [SerializeField] private float chromaticAberrationIntensity = 0.1f;

    private static readonly int sampleScaleId = Shader.PropertyToID("_SampleScale");
    private static readonly int intensityId = Shader.PropertyToID("_Intensity");
    private static readonly int bloomTexId = Shader.PropertyToID("_BloomTex");
    private static readonly int bloomParamsId = Shader.PropertyToID("_BloomParams");
    private static readonly int globalIntensityTexId = Shader.PropertyToID("_GlobalIntensityTex");
    private static readonly int bloomTexelSizeId = Shader.PropertyToID("_BloomTexelSize");
    private static readonly int chromaticAberrationId = Shader.PropertyToID("_ChromaticAberration");

    private const int maxPyramidSize = 16;

    private Material bloomMaterial;
    private BeatmapRuntimeContext context;
    private bool fastMode;
    private bool chromaticAberrationEnabled = true;

    private void Start()
    {
        bloomMaterial = new Material(bloomShader);

        Settings.NotifyBySettingName(nameof(Settings.ChromaticAberration), UpdateChromaticAberration);
        Settings.NotifyBySettingName(nameof(Settings.HighQualityBloom), UpdateHighQualityBloom);
        context = FindAnyObjectByType<BeatmapRuntimeContext>();
        if (context != null)
        {
            context.OnEnvironmentLoaded += HandleEnvironmentLoaded;
            // Catch up if the environment was already loaded before this Start
            if (context.Descriptor != null) HandleEnvironmentLoaded(context.Descriptor);
        }

        UpdateChromaticAberration(Settings.Instance.ChromaticAberration);
        UpdateHighQualityBloom(Settings.Instance.HighQualityBloom);
    }

    private void OnDestroy()
    {
        // Only the context event is managed here; the Settings notifications
        // are shared with BloomfogRenderingController, so never clear them.
        if (context != null) context.OnEnvironmentLoaded -= HandleEnvironmentLoaded;
    }

    // The game authors the post-bloom auto-exposure limit per environment
    // (BloomFogEnvironmentParams, default 1000) and transitions it on environment
    // load via BloomFogSO - not a game-wide constant. Mirror the bloom-fog path
    // here; 0 means the environment does not author it, so keep the default.
    private void HandleEnvironmentLoaded(EnvironmentDescriptor environment)
    {
        if (environment == null) return;
        var limit = environment.BloomFogParams.AutoExposureLimit;
        if (limit > 0f) autoExposureLimit = limit;
    }

    public void UpdateChromaticAberration(object o) => chromaticAberrationEnabled = Convert.ToBoolean(o);

    public void UpdateHighQualityBloom(object obj) => fastMode = !Convert.ToBoolean(obj);

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (bloomMaterial == null)
        {
            Graphics.Blit(source, destination);
            return;
        }

        // Iteration count (PyramidBloomRendererSO.RenderBloom):
        // log2(max(w, h)) + min(diffusion, 10) - 10, clamped to [1, 16]. The
        // fractional part becomes _SampleScale, the upsample tent radius.
        var tw = source.width;
        var th = source.height;
        var logs = Mathf.Log(Mathf.Max(tw, th), 2f) + Mathf.Min(diffusion, 10f) - 10f;
        var logsI = Mathf.FloorToInt(logs);
        var iterations = Mathf.Clamp(logsI, 1, maxPyramidSize);
        var sampleScale = 0.5f + logs - logsI;

        var qualityOffset = fastMode ? 1 : 0;

        // Downsample: pass 0 is the prefilter (alpha gate), the rest are the
        // 13-tap (1) or 4-tap (2) box downsample.
        var downs = new RenderTexture[iterations];
        var lastDown = source;
        for (var i = 0; i < iterations; i++)
        {
            var down = downs[i] = RenderTexture.GetTemporary(tw, th, 0, RenderTextureFormat.ARGBHalf);
            bloomMaterial.SetVector(bloomTexelSizeId, new Vector4(1f / tw, 1f / th, tw, th));
            Graphics.Blit(lastDown, down, bloomMaterial, i == 0 ? 0 : 1 + qualityOffset);
            lastDown = down;
            tw = Mathf.Max(tw / 2, 1);
            th = Mathf.Max(th / 2, 1);
        }

        // Upsample: tent (3) or box (4), adding the level below as it goes.
        bloomMaterial.SetFloat(sampleScaleId, sampleScale);
        var lastUp = downs[iterations - 1];
        for (var i = iterations - 2; i >= 0; i--)
        {
            var up = RenderTexture.GetTemporary(downs[i].width, downs[i].height, 0, RenderTextureFormat.ARGBHalf);
            bloomMaterial.SetVector(
                bloomTexelSizeId,
                new Vector4(1f / lastUp.width, 1f / lastUp.height, lastUp.width, lastUp.height));
            bloomMaterial.SetTexture(bloomTexId, downs[i]);
            Graphics.Blit(lastUp, up, bloomMaterial, 3 + qualityOffset);
            lastUp = up;
        }

        // Composite (pass 5): add the bloom to the scene, gated by the
        // auto-exposure knee and ACES-tonemapped. The top pyramid mip is bound
        // as the 1x1 luminance probe exactly like the game does.
        bloomMaterial.SetFloat(intensityId, intensity);
        bloomMaterial.SetVector(
            bloomParamsId,
            new Vector4(autoExposureLimit, sampleScale, 0f, legacyAutoExposure ? 1f : 0f));
        bloomMaterial.SetTexture(globalIntensityTexId, downs[iterations - 1]);
        bloomMaterial.SetTexture(bloomTexId, lastUp);
        bloomMaterial.SetVector(
            bloomTexelSizeId,
            new Vector4(1f / source.width, 1f / source.height, source.width, source.height));
        var composite = RenderTexture.GetTemporary(source.width, source.height, 0, RenderTextureFormat.ARGBHalf);
        Graphics.Blit(source, composite, bloomMaterial, 5);

        // Chromatic aberration (pass 6) on top of the composite, like the PPv2
        // stack ordering (bloom ran BeforeStack, CA in the main stack).
        if (chromaticAberrationEnabled)
        {
            bloomMaterial.SetFloat(chromaticAberrationId, chromaticAberrationIntensity * 0.05f);
            Graphics.Blit(composite, destination, bloomMaterial, 6);
        }
        else
        {
            Graphics.Blit(composite, destination);
        }

        RenderTexture.ReleaseTemporary(composite);
        for (var i = 0; i < iterations; i++) RenderTexture.ReleaseTemporary(downs[i]);
    }
}
