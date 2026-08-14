using System;
using UnityEngine;

public abstract class FireEffect : MonoBehaviour, ILightColorEventEffect
{
    private static readonly int EffectStartSongTimeId = Shader.PropertyToID("_EffectStartSongTime");
    private static readonly int ColorId = Shader.PropertyToID("_Color");
    private static readonly int PrivatePointLightColorId = Shader.PropertyToID("_PrivatePointLightColor");
    private static readonly int EmissionTexColorId = Shader.PropertyToID("_EmissionTexColor");

    public MaterialPropertyBlockController FlipBookPropertyBlockController;
    public MaterialPropertyBlockController BloomPropertyBlockController;
    public MaterialPropertyBlockController PrivatePointLightPropertyBlockController;
    public MaterialPropertyBlockController EmissionTextureColorPropertyBlockController;
    public BloomPrePassBackgroundNonLightRenderer BloomPrePassRenderer;
    public bool UseEmissionColor;
    public bool ContributeCustomLightColor = true;
    public float BloomIntensityMultiplier = 1f;
    public Color PointLightColor = Color.yellow;
    public Color CustomLightColor = Color.white;
    public Action<float> CustomLightAlphaChanged;

    private bool renderersEnabled;
    private float effectStartTime = float.NaN;
    private float lastFlipBookAlpha = float.NaN;
    private float lastBloomAlpha = float.NaN;

    public void Initialize()
    {
        SetEffectStartTime(-1000f);
        UpdateRenderers(0f, 0f);
        SetRenderersEnabled(false);
    }

    public abstract void UpdateFireState(
        bool isPlaying,
        float currentTime,
        float startTime,
        float endTime,
        float brightness);

    protected void SetEffectStartTime(float time)
    {
        if (effectStartTime.Equals(time)) return;
        effectStartTime = time;
        FlipBookPropertyBlockController.Mpb.SetFloat(EffectStartSongTimeId, time);
        FlipBookPropertyBlockController.ApplyChanges();
    }

    protected void UpdateRenderers(float flipBookAlpha, float bloomAlpha)
    {
        if (lastFlipBookAlpha.Equals(flipBookAlpha) && lastBloomAlpha.Equals(bloomAlpha)) return;
        lastFlipBookAlpha = flipBookAlpha;
        lastBloomAlpha = bloomAlpha;
        FlipBookPropertyBlockController.Mpb.SetColor(ColorId, new Color(1f, 1f, 1f, flipBookAlpha));
        FlipBookPropertyBlockController.ApplyChanges();
        BloomPropertyBlockController.Mpb.SetColor(
            ColorId,
            new Color(1f, 1f, 1f, bloomAlpha * BloomIntensityMultiplier));
        BloomPropertyBlockController.ApplyChanges();

        var lightController = UseEmissionColor
            ? EmissionTextureColorPropertyBlockController
            : PrivatePointLightPropertyBlockController;
        lightController.Mpb.SetColor(
            UseEmissionColor ? EmissionTexColorId : PrivatePointLightColorId,
            PointLightColor * bloomAlpha);
        lightController.ApplyChanges();

        if (ContributeCustomLightColor) CustomLightAlphaChanged?.Invoke(bloomAlpha);
    }

    protected void SetRenderersEnabled(bool enabled)
    {
        if (renderersEnabled == enabled) return;
        renderersEnabled = enabled;
        FlipBookPropertyBlockController.ShowRenderer(enabled);
        BloomPrePassRenderer.enabled = enabled;
    }

    protected void EndEffect()
    {
        UpdateRenderers(0f, 0f);
        SetRenderersEnabled(false);
    }
}

public class BurstFireEffect : FireEffect
{
    public float FadeOutDuration = 1f;
    public AnimationCurve FlipbookFadeOutCurve = AnimationCurve.Linear(0f, 1f, 1f, 0f);
    public AnimationCurve BloomFadeOutCurve = AnimationCurve.Linear(0f, 0f, 1f, 0f);

    public override void UpdateFireState(
        bool isPlaying,
        float currentTime,
        float startTime,
        float endTime,
        float brightness)
    {
        var elapsed = currentTime - startTime;
        if (brightness <= 0f || elapsed < 0f || elapsed >= FadeOutDuration || (!isPlaying && elapsed > 0.0001f))
        {
            EndEffect();
            return;
        }

        SetRenderersEnabled(true);
        SetEffectStartTime(startTime);
        var progress = Mathf.Clamp01(elapsed / FadeOutDuration);
        UpdateRenderers(FlipbookFadeOutCurve.Evaluate(progress), BloomFadeOutCurve.Evaluate(progress));
    }
}

public class ContinuousFireEffect : FireEffect
{
    public float FadeInDuration = 1f;
    public float FadeOutDuration = 1f;
    public float SustainDuration = 1f;
    public AnimationCurve FlipbookSustainCurve = AnimationCurve.Linear(0f, 1f, 1f, 1f);
    public AnimationCurve BloomSustainCurve = AnimationCurve.Linear(0f, 1f, 1f, 1f);

    public override void UpdateFireState(
        bool isPlaying,
        float currentTime,
        float startTime,
        float endTime,
        float brightness)
    {
        if (brightness <= 0f || currentTime < startTime || currentTime >= endTime)
        {
            EndEffect();
            return;
        }

        SetRenderersEnabled(true);
        SetEffectStartTime(startTime);
        var fadeInEndTime = Mathf.Min(startTime + FadeInDuration, endTime);
        var fadeOutStartTime = Mathf.Max(endTime - FadeOutDuration, startTime);
        var fadeIn = Mathf.InverseLerp(startTime, fadeInEndTime, Mathf.Clamp(currentTime, startTime, fadeInEndTime));
        var fadeOut = 1f - Mathf.InverseLerp(
            fadeOutStartTime,
            endTime,
            Mathf.Clamp(currentTime, fadeOutStartTime, endTime));
        var sustainProgress = (currentTime - startTime) / SustainDuration;
        var fade = Easing.Quadratic.Out(fadeIn) * Easing.Quadratic.InOut(fadeOut);
        UpdateRenderers(
            fade * FlipbookSustainCurve.Evaluate(sustainProgress),
            fade * BloomSustainCurve.Evaluate(sustainProgress));
    }
}
