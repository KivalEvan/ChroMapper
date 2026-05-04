using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Pool;
using ZLinq;

public class ObjectPropertyManager
{
    public InstantiateObjectPrefabManager InstantiateObjectPrefabManager;
    public VivifyAssetBundleManager VivifyAssetBundleManager;
    public TweenManager TweenManager;

    private readonly Dictionary<CustomEventStateData, (TweenFloat tween, List<Action<float>> pooledList)> stateToTween =
        new();

    private readonly Dictionary<CustomEventStateData, List<CustomEventStateHistory>> stateHistory = new();

    public void AssignMaterial(CustomEventStateData state)
    {
        var data = state.Base.Data;
        var asset = data["asset"];
        if (!VivifyAssetBundleManager.AssetPathToMaterial.TryGetValue(asset, out var material)) return;

        var duration = data["duration"] ?? 0;
        var easing = data["easing"].IsString ? Easing.Named(data["easing"]) : Easing.Linear;

        stateHistory.Add(state, ListPool<CustomEventStateHistory>.Get());
        var funcs = ListPool<Action<float>>.Get();

        var properties = data["properties"];
        foreach (var child in properties.Children)
        {
            var id = (string)child["id"];
            var propertyId = Shader.PropertyToID(id);

            var type = (string)child["type"];
            var value = child["value"];
            switch (type)
            {
                case "Texture":
                    {
                        var history = new MaterialHistoryTexture(material, id);
                        stateHistory[state].Add(history);

                        var texture = VivifyAssetBundleManager.AssetPathToTexture.GetValueOrDefault(value);
                        material.SetTexture(propertyId, texture);
                    }
                    break;
                case "Keyword":
                    {
                        var history = new MaterialHistoryKeyword(material, id, value);
                        stateHistory[state].Add(history);

                        material.EnableKeyword(value);
                    }
                    break;
                case "Float":
                    {
                        var history = new MaterialHistoryFloat(material, id);
                        stateHistory[state].Add(history);

                        if (value.IsNumber)
                            material.SetFloat(propertyId, value);
                        else
                        {
                            var pd = PointDefinitionParser.Get(value);
                            if (pd == null) break;
                            funcs.Add(t =>
                            {
                                var v = pd.GetFloat(t);
                                material.SetFloat(propertyId, v);
                            });
                        }
                    }
                    break;
                case "Vector":
                    {
                        var history = new MaterialHistoryVector(material, id);
                        stateHistory[state].Add(history);

                        var pd = PointDefinitionParser.Get(value);
                        if (pd == null) break;
                        funcs.Add(t =>
                        {
                            var v = pd.GetVector4(t);
                            material.SetVector(propertyId, v);
                        });
                    }
                    break;
                case "Color":
                    {
                        var history = new MaterialHistoryColor(material, id);
                        stateHistory[state].Add(history);

                        var pd = PointDefinitionParser.Get(value);
                        if (pd == null) break;
                        funcs.Add(t =>
                        {
                            var v = pd.GetColor(t);
                            material.SetColor(propertyId, v);
                        });
                    }
                    break;
            }
        }

        if (funcs.Count > 0)
        {
            var tween = new TweenFloat(
                state.StartTime,
                state.StartTime + duration,
                0,
                1,
                easing,
                t =>
                {
                    for (var i = 0; i < funcs.Count; i++) funcs[i](t);
                });
            stateToTween.Add(state, (tween, funcs));
            TweenManager.Add(tween);
        }
        else
            ListPool<Action<float>>.Release(funcs);
    }

    public void AssignGlobal(CustomEventStateData state)
    {
        var data = state.Base.Data;

        var duration = data["duration"] ?? 0;
        var easing = data["easing"].IsString ? Easing.Named(data["easing"]) : Easing.Linear;

        stateHistory.Add(state, ListPool<CustomEventStateHistory>.Get());
        var funcs = ListPool<Action<float>>.Get();

        var properties = data["properties"];
        foreach (var child in properties.Children)
        {
            var id = (string)child["id"];
            var propertyId = Shader.PropertyToID(id);

            var type = (string)child["type"];
            var value = child["value"];
            switch (type)
            {
                case "Texture":
                    {
                        var history = new GlobalHistoryTexture(id);
                        stateHistory[state].Add(history);

                        var texture = VivifyAssetBundleManager.AssetPathToTexture.GetValueOrDefault(value);
                        Shader.SetGlobalTexture(propertyId, texture);
                    }
                    break;
                case "Keyword":
                    {
                        var history = new GlobalHistoryKeyword(id, value);
                        stateHistory[state].Add(history);

                        Shader.EnableKeyword(value);
                    }
                    break;
                case "Float":
                    {
                        var history = new GlobalHistoryFloat(id);
                        stateHistory[state].Add(history);

                        if (value.IsNumber)
                            Shader.SetGlobalFloat(propertyId, value);
                        else
                        {
                            var pd = PointDefinitionParser.Get(value);
                            if (pd == null) break;
                            funcs.Add(t =>
                            {
                                var v = pd.GetFloat(t);
                                Shader.SetGlobalFloat(propertyId, v);
                            });
                        }
                    }
                    break;
                case "Vector":
                    {
                        var history = new GlobalHistoryVector(id);
                        stateHistory[state].Add(history);

                        var pd = PointDefinitionParser.Get(value);
                        if (pd == null) break;
                        funcs.Add(t =>
                        {
                            var v = pd.GetVector4(t);
                            Shader.SetGlobalVector(propertyId, v);
                        });
                    }
                    break;
                case "Color":
                    {
                        var history = new GlobalHistoryColor(id);
                        stateHistory[state].Add(history);

                        var pd = PointDefinitionParser.Get(value);
                        if (pd == null) break;
                        funcs.Add(t =>
                        {
                            var v = pd.GetColor(t);
                            Shader.SetGlobalColor(propertyId, v);
                        });
                    }
                    break;
            }
        }

        if (funcs.Count > 0)
        {
            var tween = new TweenFloat(
                state.StartTime,
                state.StartTime + duration,
                0,
                1,
                easing,
                t =>
                {
                    for (var i = 0; i < funcs.Count; i++) funcs[i](t);
                });
            stateToTween.Add(state, (tween, funcs));
            TweenManager.Add(tween);
        }
        else
            ListPool<Action<float>>.Release(funcs);
    }

    public void AssignAnimator(CustomEventStateData state)
    {
        var data = state.Base.Data;

        var objectId = data["id"];

        var duration = data["duration"] ?? 0;
        var easing = data["easing"].IsString ? Easing.Named(data["easing"]) : Easing.Linear;

        stateHistory.Add(state, ListPool<CustomEventStateHistory>.Get());
        var funcs = ListPool<Action<float>>.Get();

        var properties = data["properties"];
        foreach (var child in properties.Children)
        {
            var id = (string)child["id"];
            var type = (string)child["type"];
            var value = child["value"];

            var objects = InstantiateObjectPrefabManager.GetObjectById(objectId);
            var animators = objects
                .AsValueEnumerable()
                .SelectMany(x => x.Animators)
                .ToArray();
            switch (type)
            {
                case "Trigger":
                    {
                        var history = new AnimatorHistoryTrigger(animators, id);
                        stateHistory[state].Add(history);

                        foreach (var a in animators)
                        {
                            if (value)
                                a.SetTrigger(id);
                            else
                                a.ResetTrigger(id);
                        }
                    }
                    break;
                case "Float":
                    {
                        var history = new AnimatorHistoryFloat(animators, id);
                        stateHistory[state].Add(history);

                        if (value.IsNumber)
                        {
                            foreach (var a in animators) a.SetFloat(id, value);
                        }
                        else
                        {
                            var pd = PointDefinitionParser.Get(value);
                            if (pd == null) break;
                            funcs.Add(t =>
                            {
                                var v = pd.GetFloat(t);
                                foreach (var a in InstantiateObjectPrefabManager
                                    .GetObjectById(objectId)
                                    .AsValueEnumerable()
                                    .SelectMany(x => x.Animators))
                                    a.SetFloat(id, v);
                            });
                        }
                    }
                    break;
                case "Integer":
                    {
                        var history = new AnimatorHistoryInt(animators, id);
                        stateHistory[state].Add(history);

                        if (value.IsNumber)
                        {
                            foreach (var a in animators) a.SetInteger(id, value);
                        }
                        else
                        {
                            var pd = PointDefinitionParser.Get(value);
                            if (pd == null) break;
                            funcs.Add(t =>
                            {
                                var v = pd.GetFloat(t);
                                foreach (var a in InstantiateObjectPrefabManager
                                    .GetObjectById(objectId)
                                    .AsValueEnumerable()
                                    .SelectMany(x => x.Animators))
                                    a.SetInteger(id, (int)v);
                            });
                        }
                    }
                    break;
                case "Bool":
                    {
                        var history = new AnimatorHistoryBool(animators, id);
                        stateHistory[state].Add(history);

                        if (value.IsBoolean)
                        {
                            foreach (var a in animators) a.SetBool(id, value);
                        }
                        else
                        {
                            var pd = PointDefinitionParser.Get(value);
                            if (pd == null) break;
                            funcs.Add(t =>
                            {
                                var v = pd.GetFloat(t);
                                foreach (var a in InstantiateObjectPrefabManager
                                    .GetObjectById(objectId)
                                    .AsValueEnumerable()
                                    .SelectMany(x => x.Animators))
                                    a.SetBool(id, v >= 1);
                            });
                        }
                    }
                    break;
            }

            if (funcs.Count > 0)
            {
                var tween = new TweenFloat(
                    state.StartTime,
                    state.StartTime + duration,
                    0,
                    1,
                    easing,
                    t =>
                    {
                        for (var i = 0; i < funcs.Count; i++) funcs[i](t);
                    });
                stateToTween.Add(state, (tween, funcs));
                TweenManager.Add(tween);
            }
            else
                ListPool<Action<float>>.Release(funcs);
        }
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
