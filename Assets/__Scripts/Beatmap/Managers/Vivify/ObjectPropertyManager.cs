using System;
using System.Collections.Generic;
using System.Linq;
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

    private readonly Dictionary<CustomEventStateData, List<ObjectPropertyStateHistory>> stateHistory = new();

    public void AssignMaterial(CustomEventStateData state)
    {
        var data = state.Base.Data;
        var asset = data["asset"];
        if (!VivifyAssetBundleManager.AssetPathToMaterial.TryGetValue(asset, out var material)) return;

        var duration = data["duration"] ?? 0;
        var easing = data["easing"].IsString ? Easing.Named(data["easing"]) : Easing.Linear;

        stateHistory.Add(state, ListPool<ObjectPropertyStateHistory>.Get());
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

        stateHistory.Add(state, ListPool<ObjectPropertyStateHistory>.Get());
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

        stateHistory.Add(state, ListPool<ObjectPropertyStateHistory>.Get());
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
            ListPool<ObjectPropertyStateHistory>.Release(history);
        }

        if (stateToTween.Remove(state, out var p))
        {
            TweenManager.Remove(p.tween);
            ListPool<Action<float>>.Release(p.pooledList);
        }
    }
}

public abstract class ObjectPropertyStateHistory
{
    protected readonly string Property;
    public abstract void Revert();

    protected ObjectPropertyStateHistory(string property) => Property = property;
}

public class MaterialHistoryTexture : ObjectPropertyStateHistory
{
    private readonly Material material;
    private readonly int propertyId;
    private readonly Texture value;

    public MaterialHistoryTexture(Material material, string property) : base(property)
    {
        this.material = material;
        propertyId = Shader.PropertyToID(property);
        value = material.GetTexture(propertyId);
    }

    public override void Revert() => material.SetTexture(propertyId, value);
}

public class MaterialHistoryKeyword : ObjectPropertyStateHistory
{
    private readonly Material material;
    private readonly string keyword;
    private readonly bool value;

    public MaterialHistoryKeyword(Material material, string property, string keyword) : base(property)
    {
        this.material = material;
        value = material.IsKeywordEnabled(keyword);
    }

    public override void Revert()
    {
        if (value)
            material.EnableKeyword(keyword);
        else
            material.DisableKeyword(keyword);
    }
}

public class MaterialHistoryFloat : ObjectPropertyStateHistory
{
    private readonly Material material;
    private readonly int propertyId;
    private readonly float value;

    public MaterialHistoryFloat(Material material, string property) : base(property)
    {
        this.material = material;
        propertyId = Shader.PropertyToID(property);
        value = material.GetFloat(propertyId);
    }

    public override void Revert() => material.SetFloat(propertyId, value);
}

public class MaterialHistoryVector : ObjectPropertyStateHistory
{
    private readonly Material material;
    private readonly int propertyId;
    private readonly Vector4 value;

    public MaterialHistoryVector(Material material, string property) : base(property)
    {
        this.material = material;
        propertyId = Shader.PropertyToID(property);
        value = material.GetVector(propertyId);
    }

    public override void Revert() => material.SetVector(propertyId, value);
}

public class MaterialHistoryColor : ObjectPropertyStateHistory
{
    private readonly Material material;
    private readonly int propertyId;
    private readonly Color value;

    public MaterialHistoryColor(Material material, string property) : base(property)
    {
        this.material = material;
        propertyId = Shader.PropertyToID(property);
        value = material.GetColor(propertyId);
    }

    public override void Revert() => material.SetColor(propertyId, value);
}

public class GlobalHistoryTexture : ObjectPropertyStateHistory
{
    private readonly int propertyId;
    private readonly Texture value;

    public GlobalHistoryTexture(string property) : base(property)
    {
        propertyId = Shader.PropertyToID(property);
        value = Shader.GetGlobalTexture(propertyId);
    }

    public override void Revert() => Shader.SetGlobalTexture(propertyId, value);
}

public class GlobalHistoryKeyword : ObjectPropertyStateHistory
{
    private readonly string keyword;
    private readonly bool value;

    public GlobalHistoryKeyword(string property, string keyword) : base(property) =>
        value = Shader.IsKeywordEnabled(keyword);

    public override void Revert()
    {
        if (value)
            Shader.EnableKeyword(keyword);
        else
            Shader.DisableKeyword(keyword);
    }
}

public class GlobalHistoryFloat : ObjectPropertyStateHistory
{
    private readonly int propertyId;
    private readonly float value;

    public GlobalHistoryFloat(string property) : base(property)
    {
        propertyId = Shader.PropertyToID(property);
        value = Shader.GetGlobalFloat(propertyId);
    }

    public override void Revert() => Shader.SetGlobalFloat(propertyId, value);
}

public class GlobalHistoryVector : ObjectPropertyStateHistory
{
    private readonly int propertyId;
    private readonly Vector4 value;

    public GlobalHistoryVector(string property) : base(property)
    {
        propertyId = Shader.PropertyToID(property);
        value = Shader.GetGlobalVector(propertyId);
    }

    public override void Revert() => Shader.SetGlobalVector(propertyId, value);
}

public class GlobalHistoryColor : ObjectPropertyStateHistory
{
    private readonly int propertyId;
    private readonly Color value;

    public GlobalHistoryColor(string property) : base(property)
    {
        propertyId = Shader.PropertyToID(property);
        value = Shader.GetGlobalColor(propertyId);
    }

    public override void Revert() => Shader.SetGlobalColor(propertyId, value);
}

public class AnimatorHistoryBool : ObjectPropertyStateHistory
{
    private readonly (Animator animator, bool value)[] animatorValue;

    public AnimatorHistoryBool(Animator[] animators, string property) : base(property) =>
        animatorValue = animators.Select(x => (x, x.GetBool(property))).ToArray();

    public override void Revert()
    {
        foreach (var (animator, value) in animatorValue) animator.SetBool(Property, value);
    }
}

public class AnimatorHistoryFloat : ObjectPropertyStateHistory
{
    private readonly (Animator animator, float value)[] animatorValue;

    public AnimatorHistoryFloat(Animator[] animators, string property) : base(property) =>
        animatorValue = animators.Select(x => (x, x.GetFloat(property))).ToArray();

    public override void Revert()
    {
        foreach (var (animator, value) in animatorValue) animator.SetFloat(Property, value);
    }
}

public class AnimatorHistoryInt : ObjectPropertyStateHistory
{
    private readonly (Animator animator, int value)[] animatorValue;

    public AnimatorHistoryInt(Animator[] animators, string property) : base(property) =>
        animatorValue = animators.Select(x => (x, x.GetInteger(property))).ToArray();

    public override void Revert()
    {
        foreach (var (animator, value) in animatorValue) animator.SetInteger(Property, value);
    }
}

public class AnimatorHistoryTrigger : ObjectPropertyStateHistory
{
    private readonly (Animator animator, bool value)[] animatorValue;

    public AnimatorHistoryTrigger(Animator[] animators, string property) : base(property) =>
        animatorValue = animators.Select(x => (x, x.GetBool(property))).ToArray();

    public override void Revert()
    {
        foreach (var (animator, value) in animatorValue)
        {
            if (value)
                animator.SetTrigger(Property);
            else
                animator.ResetTrigger(Property);
        }
    }
}
