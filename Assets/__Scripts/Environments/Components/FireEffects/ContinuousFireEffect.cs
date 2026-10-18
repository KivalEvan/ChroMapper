using UnityEngine;

public class ContinuousFireEffect : FireEffect
{
    public float FadeInDuration = 1f;
    public float FadeOutDuration = 1f;
    public float SustainDuration = 1f;
    public AnimationCurve FlipbookSustainCurve = AnimationCurve.Linear(0f, 1f, 1f, 1f);
    public AnimationCurve BloomSustainCurve = AnimationCurve.Linear(0f, 1f, 1f, 1f);

    internal override (float flipbookAlpha, float bloomAlpha) EvaluateEffect(float elapsedSeconds, float durationSeconds)
    {
        var fadeInDuration = Mathf.Min(FadeInDuration, durationSeconds);
        var fadeOutStart = Mathf.Max(durationSeconds - FadeOutDuration, 0f);
        var fadeIn = fadeInDuration > 0f ? Mathf.Clamp01(elapsedSeconds / fadeInDuration) : 1f;
        var fadeOut = FadeOutDuration > 0f
            ? 1f - Mathf.InverseLerp(fadeOutStart, durationSeconds, elapsedSeconds)
            : 1f;
        var envelope = Easing.Quadratic.Out(fadeIn) * Easing.Quadratic.InOut(fadeOut);
        var progress = elapsedSeconds / SustainDuration;
        return (
            envelope * FlipbookSustainCurve.Evaluate(progress),
            envelope * BloomSustainCurve.Evaluate(progress));
    }
}
