using System;
using System.Collections.Generic;
using SimpleJSON;
using UnityEngine;

public class ObjectPropertyManager
{
    public InstantiateObjectPrefabManager InstantiateObjectPrefabManager;
    public VivifyAssetBundleManager VivifyAssetBundleManager;
    public CustomEventPropertyTimeline PropertyTimeline;

    private readonly List<TriggerHistory> triggerHistories = new();
    private readonly List<AnimatedAnimatorProperty> animatedAnimatorProperties = new();

    public void AssignMaterial(CustomEventStateData state)
    {
        var data = state.Base.Data;
        if (!VivifyAssetBundleManager.AssetPathToMaterial.TryGetValue(data["asset"], out var material)) return;
        var easing = GetEasing(data);

        foreach (var child in data["properties"].Children)
        {
            var id = (string)child["id"];
            var propertyId = Shader.PropertyToID(id);
            var key = "property:" + propertyId;
            var value = child["value"];
            switch ((string)child["type"])
            {
                case "Texture":
                    var texture = VivifyAssetBundleManager.AssetPathToTexture.GetValueOrDefault(value);
                    PropertyTimeline.Register(state, material, key,
                        () => material.GetTexture(propertyId), v => material.SetTexture(propertyId, v), _ => texture);
                    break;
                case "Keyword":
                    var keyword = id;
                    var keywordPoints = value.IsBoolean || value.IsNumber ? null : PointDefinitionParser.Get(value);
                    PropertyTimeline.Register(state, material, "keyword:" + keyword,
                        () => material.IsKeywordEnabled(keyword),
                        enabled =>
                        {
                            if (enabled) material.EnableKeyword(keyword);
                            else material.DisableKeyword(keyword);
                        }, t => keywordPoints != null ? keywordPoints.GetFloat(t) >= 1f
                            : value.IsBoolean ? value.AsBool : value.AsFloat >= 1f, easing);
                    break;
                case "Float":
                    RegisterFloat(state, material, key, value,
                        () => material.GetFloat(propertyId), v => material.SetFloat(propertyId, v), easing);
                    break;
                case "Vector":
                    var vector = PointDefinitionParser.Get(value);
                    if (vector != null)
                        PropertyTimeline.Register(state, material, key,
                            () => material.GetVector(propertyId), v => material.SetVector(propertyId, v),
                            vector.GetVector4, easing);
                    break;
                case "Color":
                    var color = PointDefinitionParser.Get(value);
                    if (color != null)
                        PropertyTimeline.Register(state, material, key,
                            () => material.GetColor(propertyId), v => material.SetColor(propertyId, v),
                            color.GetColor, easing);
                    break;
            }
        }
    }

    public void AssignGlobal(CustomEventStateData state)
    {
        var data = state.Base.Data;
        var easing = GetEasing(data);
        foreach (var child in data["properties"].Children)
        {
            var propertyId = Shader.PropertyToID(child["id"]);
            var key = "property:" + propertyId;
            var value = child["value"];
            switch ((string)child["type"])
            {
                case "Texture":
                    var texture = VivifyAssetBundleManager.AssetPathToTexture.GetValueOrDefault(value);
                    PropertyTimeline.Register(state, null, key,
                        () => Shader.GetGlobalTexture(propertyId), v => Shader.SetGlobalTexture(propertyId, v),
                        _ => texture);
                    break;
                case "Keyword":
                    var keyword = (string)child["id"];
                    var keywordPoints = value.IsBoolean || value.IsNumber ? null : PointDefinitionParser.Get(value);
                    PropertyTimeline.Register(state, null, "keyword:" + keyword,
                        () => Shader.IsKeywordEnabled(keyword),
                        enabled =>
                        {
                            if (enabled) Shader.EnableKeyword(keyword);
                            else Shader.DisableKeyword(keyword);
                        }, t => keywordPoints != null ? keywordPoints.GetFloat(t) >= 1f
                            : value.IsBoolean ? value.AsBool : value.AsFloat >= 1f, easing);
                    break;
                case "Float":
                    RegisterFloat(state, null, key, value,
                        () => Shader.GetGlobalFloat(propertyId), v => Shader.SetGlobalFloat(propertyId, v), easing);
                    break;
                case "Vector":
                    var vector = PointDefinitionParser.Get(value);
                    if (vector != null)
                        PropertyTimeline.Register(state, null, key,
                            () => Shader.GetGlobalVector(propertyId), v => Shader.SetGlobalVector(propertyId, v),
                            vector.GetVector4, easing);
                    break;
                case "Color":
                    var color = PointDefinitionParser.Get(value);
                    if (color != null)
                        PropertyTimeline.Register(state, null, key,
                            () => Shader.GetGlobalColor(propertyId), v => Shader.SetGlobalColor(propertyId, v),
                            color.GetColor, easing);
                    break;
            }
        }
    }

    public void AssignAnimator(CustomEventStateData state)
    {
        var data = state.Base.Data;
        var objects = InstantiateObjectPrefabManager.GetObjectById(data["id"]);
        var easing = GetEasing(data);
        foreach (var child in data["properties"].Children)
        {
            var id = (string)child["id"];
            var key = "parameter:" + id;
            var type = (string)child["type"];
            var value = child["value"];
            var points = value.IsNumber || value.IsBoolean ? null : PointDefinitionParser.Get(value);
            if (points != null && (type is "Float" or "Integer" or "Bool"))
            {
                var property = new AnimatedAnimatorProperty(state, data["id"], animator =>
                {
                    switch (type)
                    {
                        case "Float":
                            PropertyTimeline.Register(state, animator, key,
                                () => animator.GetFloat(id), v => animator.SetFloat(id, v), points.GetFloat, easing);
                            break;
                        case "Integer":
                            PropertyTimeline.Register(state, animator, key,
                                () => animator.GetInteger(id), v => animator.SetInteger(id, v),
                                t => (int)points.GetFloat(t), easing);
                            break;
                        case "Bool":
                            PropertyTimeline.Register(state, animator, key,
                                () => animator.GetBool(id), v => animator.SetBool(id, v),
                                t => points.GetFloat(t) >= 1, easing);
                            break;
                    }
                });
                animatedAnimatorProperties.Add(property);
                RefreshTargets(property);
                continue;
            }

            foreach (var obj in objects)
            {
                foreach (var animator in obj.Animators)
                {
                    switch (type)
                    {
                        case "Trigger":
                            triggerHistories.Add(new TriggerHistory(state, animator, id));
                            if (value) animator.SetTrigger(id);
                            else animator.ResetTrigger(id);
                            break;
                        case "Float":
                            if (value.IsNumber)
                            {
                                float number = value;
                                PropertyTimeline.Register(state, animator, key,
                                    () => animator.GetFloat(id), v => animator.SetFloat(id, v), _ => number);
                            }
                            break;
                        case "Integer":
                            if (value.IsNumber)
                            {
                                int number = value;
                                PropertyTimeline.Register(state, animator, key,
                                    () => animator.GetInteger(id), v => animator.SetInteger(id, v), _ => number);
                            }
                            break;
                        case "Bool":
                            if (value.IsBoolean)
                            {
                                bool boolean = value;
                                PropertyTimeline.Register(state, animator, key,
                                    () => animator.GetBool(id), v => animator.SetBool(id, v), _ => boolean);
                            }
                            break;
                    }
                }
            }
        }
    }

    public void Revert(CustomEventStateData state)
    {
        PropertyTimeline.Remove(state);
        animatedAnimatorProperties.RemoveAll(property => ReferenceEquals(property.Owner, state));
        for (var i = triggerHistories.Count - 1; i >= 0; i--)
        {
            if (!ReferenceEquals(triggerHistories[i].Owner, state)) continue;
            triggerHistories[i].Restore();
            triggerHistories.RemoveAt(i);
        }
    }

    /// <summary>Restores trigger commands and forgets animated ID bindings; the shared timeline resets separately.</summary>
    public void Reset()
    {
        for (var i = triggerHistories.Count - 1; i >= 0; i--) triggerHistories[i].Restore();
        triggerHistories.Clear();
        animatedAnimatorProperties.Clear();
    }

    /// <summary>Binds active animated ID properties to newly instantiated or reinstantiated targets.</summary>
    public void RefreshTargets()
    {
        foreach (var property in animatedAnimatorProperties) RefreshTargets(property);
    }

    /// <summary>Restores a target's trigger history and forgets its bindings before timeline cleanup and pooling.</summary>
    public void RemoveTarget(UnityEngine.Object target)
    {
        if (target is Animator animator)
            foreach (var property in animatedAnimatorProperties) property.Targets.Remove(animator);
        for (var i = triggerHistories.Count - 1; i >= 0; i--)
        {
            if (!ReferenceEquals(triggerHistories[i].Animator, target)) continue;
            triggerHistories[i].Restore();
            triggerHistories.RemoveAt(i);
        }
    }

    private void RefreshTargets(AnimatedAnimatorProperty property)
    {
        foreach (var obj in InstantiateObjectPrefabManager.GetObjectById(property.ObjectId))
        {
            foreach (var animator in obj.Animators)
            {
                if (animator == null || !property.Targets.Add(animator)) continue;
                property.Register(animator);
            }
        }
    }

    private void RegisterFloat(CustomEventStateData state, UnityEngine.Object target, string key, JSONNode value,
        Func<float> read, Action<float> write, Func<float, float> easing)
    {
        if (value.IsNumber)
        {
            float number = value;
            PropertyTimeline.Register(state, target, key, read, write, _ => number);
        }
        else
        {
            var points = PointDefinitionParser.Get(value);
            if (points != null) PropertyTimeline.Register(state, target, key, read, write, points.GetFloat, easing);
        }
    }

    private static Func<float, float> GetEasing(JSONNode data) =>
        data["easing"].IsString ? Easing.Named(data["easing"]) : Easing.Linear;

    private sealed class AnimatedAnimatorProperty
    {
        public readonly CustomEventStateData Owner;
        public readonly string ObjectId;
        public readonly Action<Animator> Register;
        public readonly HashSet<Animator> Targets = new();

        public AnimatedAnimatorProperty(CustomEventStateData owner, string objectId, Action<Animator> register)
        {
            Owner = owner;
            ObjectId = objectId;
            Register = register;
        }
    }

    private sealed class TriggerHistory
    {
        public readonly CustomEventStateData Owner;
        public readonly Animator Animator;
        private readonly string property;
        private readonly bool value;

        public TriggerHistory(CustomEventStateData owner, Animator animator, string property)
        {
            Owner = owner;
            Animator = animator;
            this.property = property;
            value = animator.GetBool(property);
        }

        public void Restore()
        {
            if (Animator == null) return;
            if (value) Animator.SetTrigger(property);
            else Animator.ResetTrigger(property);
        }
    }
}
