using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using ZLinq;

public class FireGroupEffect : LightColorGroupEffect
{
    [SerializeField] private List<FireGroupEffectEntry> fireEntries = new();
    private FireElement[] ownedElements = Array.Empty<FireElement>();
    private FireElement[] elementsToUpdate = Array.Empty<FireElement>();
    private bool sharedPointLightsInitialized;

    public void Register(int elementId, FireEffect fire) =>
        fireEntries.Add(new FireGroupEffectEntry { ElementId = elementId, Effect = fire });

    protected override IEnumerable<int> GetElementIds() =>
        base.GetElementIds().Concat(fireEntries.Select(entry => entry.ElementId));

    public override void Initialize()
    {
        base.Initialize();
        sharedPointLightsInitialized = false;
        ownedElements = activeContainers
            .AsValueEnumerable()
            .Select(container => new FireElement(
                container,
                fireEntries
                    .Where(entry => entry.ElementId == container.ElementId)
                    .Select(entry => entry.Effect)))
            .ToArray();
        elementsToUpdate = ownedElements;
        RebuildStates();
    }

    protected override void HandleBoostChange(bool boost)
    {
        // no op
    }

    public override void Refresh()
    {
        var time = Atsc.CurrentSongBpmTime;
        foreach (var element in ownedElements) element.Container.EventContainer.SetStateAt(time);

        RebuildStates();
        if (!sharedPointLightsInitialized) InitializeSharedPointLights();
        UpdateTime(false, time);
    }

    private void InitializeSharedPointLights()
    {
        // Defer until the first refresh, after every group's elements have been initialised.
        var allTargets = GetComponentInParent<EnvironmentDescriptor>()
            .LightColorGroupEffectManager
            .IdToEffect.Values
            .AsValueEnumerable()
            .OfType<FireGroupEffect>()
            .SelectMany(group => group.ownedElements)
            .SelectMany(element => element.Targets)
            .ToArray();
        var targets = ownedElements
            .AsValueEnumerable()
            .SelectMany(element => element.Targets)
            .ToArray();
        foreach (var target in targets)
        {
            target.Shared = allTargets
                .AsValueEnumerable()
                .Where(other => other != target && target.Effect.SharesPointLightWith(other.Effect))
                .ToArray();
            // Track the actual last writer across groups sharing this property block.
            var pointLightOwner = allTargets.First(other =>
                other == target || target.Effect.SharesPointLightWith(other.Effect));
            target.PointLight = pointLightOwner.PointLight;
            target.PointLight.HasApplied = false;
        }

        // Shared point lights can read fires from other groups. Advance each source element
        // once before evaluating any targets, rather than once per shared light comparison.
        elementsToUpdate = ownedElements
            .AsValueEnumerable()
            .Concat(
                targets
                    .SelectMany(target => target.Shared)
                    .Select(target => target.Element))
            .Distinct()
            .ToArray();

        sharedPointLightsInitialized = true;
    }

    private void RebuildStates()
    {
        var secondsPerBeat = Atsc.GetSecondsFromBeat(1f);
        var songEndTime = Atsc.SongAudioSource.clip.length;
        foreach (var element in ownedElements) element.RebuildStates(secondsPerBeat, songEndTime);
    }

    public override void UpdateTime(bool isPlaying, float time)
    {
        var songSeconds = Atsc.GetSecondsFromBeat(time);
        foreach (var element in elementsToUpdate) element.UpdateState(isPlaying, time);

        foreach (var element in ownedElements)
        {
            foreach (var target in element.Targets)
            {
                var visible = target.Evaluate(songSeconds, out var interval, out var flipbookAlpha, out var bloomAlpha);
                var fire = target.Effect;
                target.ApplyIfChanged(interval.StartTime, visible, flipbookAlpha, bloomAlpha);

                var pointLightColor = fire.PointLightColor * bloomAlpha;
                foreach (var other in target.Shared)
                {
                    other.Evaluate(songSeconds, out _, out _, out var sharedAlpha);
                    if (sharedAlpha <= bloomAlpha) continue;
                    bloomAlpha = sharedAlpha;
                    pointLightColor = other.Effect.PointLightColor * sharedAlpha;
                }

                if (!target.PointLight.HasApplied || !target.PointLight.Color.Equals(pointLightColor))
                {
                    fire.ApplyPointLightColor(pointLightColor);
                    target.PointLight.Color = pointLightColor;
                    target.PointLight.HasApplied = true;
                }

                if (!fire.ContributeCustomLightColor) continue;
                element.ApplyContributionIfChanged(fire.ContributionColor);
            }
        }
    }

    private sealed class FireElement
    {
        public readonly LightColorGroupContainer Container;
        public readonly FireTarget[] Targets;
        private FirePlayback[] playbacks = Array.Empty<FirePlayback>();
        private bool hasAppliedContribution;
        private Color appliedContribution;

        public FireElement(LightColorGroupContainer container, IEnumerable<FireEffect> effects)
        {
            Container = container;
            Targets = effects
                .AsValueEnumerable()
                .Select(effect => new FireTarget(effect, this))
                .ToArray();
        }

        public void RebuildStates(float secondsPerBeat, float songEndTime)
        {
            hasAppliedContribution = false;
            foreach (var target in Targets) target.InvalidateAppliedState();
            var events = Container
                .EventContainer.Collection
                .AsValueEnumerable()
                .Where(evt => evt.StartTime != short.MinValue && evt.StartTime != float.MaxValue)
                .ToArray();
            var nextPlaybacks = new List<FirePlayback>();
            // Continuous fires share trigger history regardless of their visual envelopes.
            // Burst duration also controls which retriggers are ignored, so it must match.
            // Regroup on refresh to account for duration edits without reordering targets.
            foreach (var group in Targets.GroupBy(target =>
                target.Effect is BurstFireEffect burst ? (float?)burst.FadeOutDuration : null))
            {
                var playback = playbacks
                        .AsValueEnumerable()
                        .FirstOrDefault(candidate => candidate.BurstDuration == group.Key)
                    ?? new FirePlayback(group.Key);
                playback.RebuildStates(events, secondsPerBeat, songEndTime);
                foreach (var target in group) target.Playback = playback;
                nextPlaybacks.Add(playback);
            }

            playbacks = nextPlaybacks.ToArray();
        }

        public void ApplyContributionIfChanged(Color color)
        {
            if (hasAppliedContribution && appliedContribution.Equals(color)) return;
            var allInitialized = true;
            foreach (var light in Container.Lights)
            {
                light.SetColor(color);
                allInitialized &= light.HasInitialized;
            }
            appliedContribution = color;
            // A callback before LightController.Start may not have applied its color yet.
            hasAppliedContribution = allInitialized;
        }

        public void UpdateState(bool isPlaying, float time)
        {
            if (playbacks.Length == 0) return;
            var events = Container.EventContainer;
            events.IsCurrentOrFindState(time, isPlaying);
            foreach (var playback in playbacks) playback.UpdateState(events.CurrentState);
        }
    }

    private sealed class PointLightState
    {
        public bool HasApplied;
        public Color Color;
    }

    private sealed class FireTarget
    {
        public readonly FireEffect Effect;
        public readonly FireElement Element;
        public FirePlayback Playback;
        public FireTarget[] Shared = Array.Empty<FireTarget>();
        public PointLightState PointLight = new();
        private bool hasAppliedState;
        private (float startTime, bool visible, float flipbookAlpha, float bloomAlpha, Color contribution) appliedState;

        public FireTarget(FireEffect effect, FireElement element)
        {
            Effect = effect;
            Element = element;
            Effect.EnsureInitialized();
        }

        public void InvalidateAppliedState()
        {
            hasAppliedState = false;
            PointLight.HasApplied = false;
        }

        public void ApplyIfChanged(float startTime, bool visible, float flipbookAlpha, float bloomAlpha)
        {
            var state = (
                visible ? startTime : -1000f,
                visible,
                flipbookAlpha,
                bloomAlpha * Effect.BloomIntensityMultiplier,
                Effect.CustomLightColor.WithAlpha(bloomAlpha));
            if (hasAppliedState && appliedState.Equals(state)) return;

            Effect.Apply(startTime, visible, flipbookAlpha, bloomAlpha);
            appliedState = state;
            hasAppliedState = true;
        }

        public bool Evaluate(
            float songSeconds,
            out FireInterval interval,
            out float flipbookAlpha,
            out float bloomAlpha)
        {
            interval = Playback.CurrentInterval;
            if (songSeconds < interval.StartTime || songSeconds >= interval.EndTime)
            {
                interval = default;
                flipbookAlpha = bloomAlpha = 0f;
                return false;
            }

            (flipbookAlpha, bloomAlpha) = Effect.EvaluateEffect(
                songSeconds - interval.StartTime,
                interval.EndTime - interval.StartTime);
            return true;
        }
    }

    private readonly struct FireInterval
    {
        public readonly float StartTime;
        public readonly float EndTime;

        public FireInterval(float startTime, float endTime)
        {
            StartTime = startTime;
            EndTime = endTime;
        }
    }

    private sealed class FirePlayback
    {
        public readonly float? BurstDuration;
        public FireInterval CurrentInterval { get; private set; }
        private readonly Dictionary<LightColorEventStateData, FireInterval> states = new();
        private LightColorEventStateData currentState;

        public FirePlayback(float? burstDuration)
        {
            BurstDuration = burstDuration;
        }

        public void RebuildStates(
            IReadOnlyList<LightColorEventStateData> events,
            float secondsPerBeat,
            float songEndTime)
        {
            states.Clear();
            currentState = null;
            var interval = default(FireInterval);
            var active = false;
            // Remember the accepted trigger at each GLS state so seeks preserve ignored retriggers.
            for (var i = 0; i < events.Count; i++)
            {
                var evt = events[i];
                var brightness = evt.UsePrevious ? ((LightColorEventStateData)evt.Previous).Brightness : evt.Brightness;
                var startTime = evt.StartTime * secondsPerBeat;
                if (BurstDuration.HasValue)
                {
                    if (brightness > 0f && (!active || startTime >= interval.EndTime))
                    {
                        active = true;
                        interval = new FireInterval(startTime, startTime + BurstDuration.Value);
                    }
                }
                else if (brightness <= 0f)
                {
                    active = false;
                }
                else if (!active)
                {
                    active = true;
                    var endTime = i + 1 < events.Count ? events[i + 1].StartTime * secondsPerBeat : songEndTime;
                    interval = new FireInterval(startTime, endTime);
                }

                states.Add(evt, interval);
            }
        }

        public void UpdateState(LightColorEventStateData state)
        {
            if (currentState == state) return;

            currentState = state;
            states.TryGetValue(currentState, out var interval);
            CurrentInterval = interval;
        }
    }
}

[Serializable]
public struct FireGroupEffectEntry
{
    public int ElementId;
    public FireEffect Effect;
}
