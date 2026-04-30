using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.CompilerServices;
using SimpleJSON;
using UnityEngine;
using UnityEngine.Pool;
using ZLinq;

public static class PointDefinitionParser
{
    public static readonly Dictionary<string, PointDefinitionInterpolator> NameCacheParsedInterpolators = new();
    public static readonly Dictionary<JSONNode, PointDefinitionInterpolator> NodeCacheParsedInterpolators = new();

    public static PointDefinitionInterpolator Get(string name, JSONNode node)
    {
        if (NameCacheParsedInterpolators.TryGetValue(name, out var cached)) return cached;
        var pd = Parse(node);
        NameCacheParsedInterpolators.Add(name, pd);
        return pd;
    }

    public static PointDefinitionInterpolator Get(string name) => NameCacheParsedInterpolators.GetValueOrDefault(name);

    public static PointDefinitionInterpolator Get(JSONNode node)
    {
        if (node == null) return null;
        if (node.IsString) return NameCacheParsedInterpolators.GetValueOrDefault(node);
        if (NodeCacheParsedInterpolators.TryGetValue(node, out var cached)) return cached;
        var interpolators = Parse(node);
        NodeCacheParsedInterpolators.Add(node, interpolators);
        return interpolators;
    }

    private static PointDefinitionInterpolator Parse(JSONNode node)
    {
        if (!node.IsArray) return null;
        if (node.AsArray.Count == 0) return null;

        if (!node[0].IsArray)
        {
            var pd = new PointDefinitionInterpolator(ParseOperation(node).Rhs);
            return pd;
        }

        using (ListPool<IPointDefinitionValue>.Get(out var values))
        {
            foreach (var point in node.Children)
            {
                if (!point.IsArray) return null; // bruh

                var value = new PointDefinitionValueBuilder();
                var children = point.Children.ToArray();

                var valueIndex = 0;
                var reachedEnd = false;
                var lastTimeIndex = Array.FindLastIndex(children, x => x.IsNumber);
                if (lastTimeIndex == -1) return null; // also bruh

                for (var i = 0; i < children.Length; i++)
                {
                    var child = children[i];
                    if (lastTimeIndex == i)
                    {
                        value.T = child;
                        reachedEnd = true;
                    }

                    if (child.IsArray)
                    {
                        value.AddOperation(ParseOperation(child));
                        reachedEnd = true;
                        continue;
                    }

                    if (reachedEnd)
                    {
                        if (child.IsString)
                        {
                            if ((string)child == "splineCatmullRom")
                                value.SplineCatmullRom = true;
                            else if ((string)child == "lerpHSV")
                                value.LerpHSV = true;
                            else if (((string)child).StartsWith("e")) value.Easing = Easing.Named(child);
                        }

                        continue;
                    }

                    if (child.IsString)
                        foreach (var func in GetBaseGetter(child))
                            value.SetGetter(valueIndex++, func);
                    else if (child.IsNumber)
                        value.SetGetter(valueIndex++, child);
                    else
                        value.SetGetter(valueIndex++, 0f);
                }

                values.Add(value.Build());
            }

            var pd = new PointDefinitionInterpolator(values.AsValueEnumerable().OrderBy(x => x.T).ToArray());
            return pd;
        }
    }

    public static PointOperation ParseOperation(JSONNode node)
    {
        var value = new PointDefinitionValueBuilder();
        PointOperation valueOp = null;
        var valueIndex = 0;
        var reachedEnd = false;

        foreach (var child in node.Children)
        {
            if (child.IsArray)
            {
                var op = ParseOperation(child);
                value.AddOperation(op);
                continue;
            }

            if (reachedEnd) continue;

            if (child.IsString)
            {
                switch ((string)child)
                {
                    case "opAdd":
                        valueOp = new PointOperationAdd(value);
                        reachedEnd = true;
                        break;
                    case "opSub":
                        valueOp = new PointOperationSub(value);
                        reachedEnd = true;
                        break;
                    case "opMul":
                        valueOp = new PointOperationMul(value);
                        reachedEnd = true;
                        break;
                    case "opDiv":
                        valueOp = new PointOperationDiv(value);
                        reachedEnd = true;
                        break;
                }

                if (reachedEnd) continue;

                foreach (var func in GetBaseGetter(child)) value.SetGetter(valueIndex++, func);
            }
            else if (child.IsNumber)
                value.SetGetter(valueIndex++, child);
            else
                value.SetGetter(valueIndex++, 0f);
        }

        valueOp ??= new PointOperationNone(value);
        valueOp.Rhs = value.Build();
        return valueOp;
    }

    private static readonly Dictionary<char, int> swizzleToIndex = new()
    {
        { 'x', 0 }, { 'y', 1 }, { 'z', 2 }, { 'w', 3 }
    };

    public static IEnumerable<Func<float>> GetBaseGetter(string modifier)
    {
        var mods = modifier.Split(".");

        var swizzling =
            mods.AsValueEnumerable().Skip(1).FirstOrDefault(s => s.AsValueEnumerable().Any(t => "xyzw".Contains(t)));
        var smoothing = mods.AsValueEnumerable().Skip(1).FirstOrDefault(s => s.StartsWith('s'));
        var hasSmoothing = !string.IsNullOrEmpty(smoothing);
        var smoothingValue = hasSmoothing ? float.Parse(smoothing.AsSpan()[1..]) : 0f;

        Func<float> getter;

        switch (mods[0])
        {
            case "baseHeadPosition":
                foreach (var c in swizzling ?? "xyz")
                {
                    var i = swizzleToIndex[c];
                    getter = () =>
                    {
                        var t = Camera.main.transform;
                        return t.position[i];
                    };
                    yield return hasSmoothing
                        ? new PointGetterSmoothing(
                            getter,
                            smoothingValue).GetValue
                        : getter;
                }

                break;
            case "baseHeadLocalPosition":
                foreach (var c in swizzling ?? "xyz")
                {
                    var i = swizzleToIndex[c];
                    getter = () =>
                    {
                        var t = Camera.main.transform;
                        return t.localPosition[i];
                    };
                    yield return hasSmoothing
                        ? new PointGetterSmoothing(
                            getter,
                            smoothingValue).GetValue
                        : getter;
                }

                break;
            case "baseHeadRotation":
                foreach (var c in swizzling ?? "xyz")
                {
                    var i = swizzleToIndex[c];
                    getter = () =>
                    {
                        var t = Camera.main.transform;
                        return t.eulerAngles[i];
                    };
                    yield return hasSmoothing
                        ? new PointGetterSmoothing(
                            getter,
                            smoothingValue).GetValue
                        : getter;
                }

                break;
            case "baseHeadLocalRotation":
                foreach (var c in swizzling ?? "xyz")
                {
                    var i = swizzleToIndex[c];
                    getter = () =>
                    {
                        var t = Camera.main.transform;
                        return t.localEulerAngles[i];
                    };
                    yield return hasSmoothing
                        ? new PointGetterSmoothing(
                            getter,
                            smoothingValue).GetValue
                        : getter;
                }

                break;
            case "baseHeadLocalScale":
                foreach (var c in swizzling ?? "xyz")
                {
                    var i = swizzleToIndex[c];
                    getter = () =>
                    {
                        var t = Camera.main.transform;
                        return t.localScale[i];
                    };
                    yield return hasSmoothing
                        ? new PointGetterSmoothing(
                            getter,
                            smoothingValue).GetValue
                        : getter;
                }

                break;
            case "baseLeftHandPosition":
            case "baseLeftHandLocalPosition":
            case "baseLeftHandRotation":
            case "baseLeftHandLocalRotation":
            case "baseLeftHandLocalScale":
            case "baseRightHandPosition":
            case "baseRightHandLocalPosition":
            case "baseRightHandRotation":
            case "baseRightHandLocalRotation":
            case "baseRightHandLocalScale":
                foreach (var c in swizzling ?? "xyz") yield return () => 0f;
                break;

            case "baseNote0Color":
            case "baseNote1Color":
            case "baseObstaclesColor":
            case "baseSaberAColor":
            case "baseSaberBColor":
            case "baseEnvironmentColor0":
            case "baseEnvironmentColor1":
            case "baseEnvironmentColorW":
            case "baseEnvironmentColor0Boost":
            case "baseEnvironmentColor1Boost":
            case "baseEnvironmentColorWBoost":
                foreach (var c in swizzling ?? "xyzw") yield return () => 0f;
                break;

            case "baseCombo":
            case "baseMultipliedScore":
            case "baseImmediateMaxPossibleMultipliedScore":
            case "baseModifiedScore":
            case "baseImmediateMaxPossibleModifiedScore":
            case "baseRelativeScore":
            case "baseMultiplier":
            case "baseEnergy":
            case "baseSongTime":
            case "baseSongLength":
                foreach (var c in swizzling ?? "x") yield return () => 0f;
                break;
        }
    }
}

// unity cant use c# expression tree without runnin into exception for unsupported platform :(
// also i need to clean this up with better structure, just throwing ideas out first
