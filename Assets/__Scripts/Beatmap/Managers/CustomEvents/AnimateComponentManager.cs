using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Pool;
using ZLinq;

public class AnimateComponentManager
{
    public TracksManager TracksManager;
    public TweenManager TweenManager;

    private static readonly int customFogOffsetId = Shader.PropertyToID("_CustomFogOffset");
    private static readonly int customFogHeightFogStartYId = Shader.PropertyToID("_CustomFogHeightFogStartY");
    private static readonly int customFogHeightFogHeightId = Shader.PropertyToID("_CustomFogHeightFogHeight");
    private static readonly int customFogAttenuationId = Shader.PropertyToID("_CustomFogAttenuation");

    private readonly Dictionary<CustomEventStateData, (TweenFloat tween, List<Action<float>> pooledList)> stateToTween =
        new();

    private readonly Dictionary<CustomEventStateData, List<CustomEventStateHistory>> stateHistory = new();

    public void Assign(CustomEventStateData state)
    {
        var data = state.Base.Data;
        var track = data["track"];
        if (track == null) return;

        float duration = data["duration"] ?? 0f;
        var easing = data["easing"].IsString ? Easing.Named(data["easing"]) : Easing.Linear;

        stateHistory.Add(state, ListPool<CustomEventStateHistory>.Get());
        var funcs = ListPool<Action<float>>.Get();

        // we always treat this as valid
        if (data["BloomFogEnvironment"] != null)
        {
            var bloomFogData = data["BloomFogEnvironment"];

            if (bloomFogData["attenuation"] != null)
            {
                var value = bloomFogData["attenuation"];
                var history = new GlobalHistoryFloat(customFogAttenuationId);
                stateHistory[state].Add(history);

                if (value.IsNumber)
                    Shader.SetGlobalFloat(customFogAttenuationId, value);
                else
                {
                    var pd = PointDefinitionParser.Get(value);
                    if (pd != null)
                    {
                        funcs.Add(t =>
                        {
                            var v = pd.GetFloat(t);
                            Shader.SetGlobalFloat(customFogAttenuationId, v);
                        });
                    }
                }
            }

            if (bloomFogData["offset"] != null)
            {
                var value = bloomFogData["offset"];
                var history = new GlobalHistoryFloat(customFogOffsetId);
                stateHistory[state].Add(history);

                if (value.IsNumber)
                    Shader.SetGlobalFloat(customFogOffsetId, value);
                else
                {
                    var pd = PointDefinitionParser.Get(value);
                    if (pd != null)
                    {
                        funcs.Add(t =>
                        {
                            var v = pd.GetFloat(t);
                            Shader.SetGlobalFloat(customFogOffsetId, v);
                        });
                    }
                }
            }

            if (bloomFogData["startY"] != null)
            {
                var value = bloomFogData["startY"];
                var history = new GlobalHistoryFloat(customFogHeightFogStartYId);
                stateHistory[state].Add(history);

                if (value.IsNumber)
                    Shader.SetGlobalFloat(customFogHeightFogStartYId, value);
                else
                {
                    var pd = PointDefinitionParser.Get(value);
                    if (pd != null)
                    {
                        funcs.Add(t =>
                        {
                            var v = pd.GetFloat(t);
                            Shader.SetGlobalFloat(customFogHeightFogStartYId, v);
                        });
                    }
                }
            }

            if (bloomFogData["height"] != null)
            {
                var value = bloomFogData["height"];
                var history = new GlobalHistoryFloat(customFogHeightFogHeightId);
                stateHistory[state].Add(history);

                if (value.IsNumber)
                    Shader.SetGlobalFloat(customFogHeightFogHeightId, value);
                else
                {
                    var pd = PointDefinitionParser.Get(value);
                    if (pd != null)
                    {
                        funcs.Add(t =>
                        {
                            var v = pd.GetFloat(t);
                            Shader.SetGlobalFloat(customFogHeightFogHeightId, v);
                        });
                    }
                }
            }
        }

        if (data["TubeBloomPrePassLight"] != null)
        {
            var tubeLightData = data["TubeBloomPrePassLight"];
            if (TracksManager.TrackToBloomFogLights.TryGetValue(track, out var list))
            {
                if (tubeLightData["colorAlphaMultiplier"] != null)
                {
                    var value = tubeLightData["colorAlphaMultiplier"];
                    var history = new TubeLightColorAlphaMultiplierHistory(list);
                    stateHistory[state].Add(history);

                    if (value.IsNumber)
                    {
                        foreach (var controller in list) controller.ColorAlphaMultiplier = value;
                    }
                    else
                    {
                        var pd = PointDefinitionParser.Get(value);
                        if (pd != null)
                        {
                            funcs.Add(t =>
                            {
                                var v = pd.GetFloat(t);
                                foreach (var controller in list) controller.ColorAlphaMultiplier = v;
                            });
                        }
                    }
                }

                if (tubeLightData["bloomFogIntensityMultiplier"] != null)
                {
                    var value = tubeLightData["bloomFogIntensityMultiplier"];
                    var history = new TubeLightColorBloomFogIntensityHistory(list);
                    stateHistory[state].Add(history);

                    if (value.IsNumber)
                    {
                        foreach (var controller in list) controller.BloomFogIntensityMultiplier = value;
                    }
                    else
                    {
                        var pd = PointDefinitionParser.Get(value);
                        if (pd != null)
                        {
                            funcs.Add(t =>
                            {
                                var v = pd.GetFloat(t);
                                foreach (var controller in list) controller.BloomFogIntensityMultiplier = v;
                            });
                        }
                    }
                }
            }
        }

        if (funcs.Count > 0)
        {
            var tween = new TweenFloat(
                state.StartTime,
                state.StartTime + duration,
                0f,
                1f,
                easing,
                t =>
                {
                    for (var i = 0; i < funcs.Count; i++) funcs[i](t);
                }
            );
            stateToTween.Add(state, (tween, funcs));
            TweenManager.Add(tween);
        }
        else
            ListPool<Action<float>>.Release(funcs);
    }

    public void Revert(CustomEventStateData state)
    {
        if (stateHistory.Remove(state, out var history))
        {
            foreach (var h in history) h.Revert();
            ListPool<CustomEventStateHistory>.Release(history);
        }

        if (stateToTween.Remove(state, out var p))
        {
            TweenManager.Remove(p.tween);
            ListPool<Action<float>>.Release(p.pooledList);
        }
    }
}
