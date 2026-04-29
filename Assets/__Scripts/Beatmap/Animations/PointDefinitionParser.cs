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

        using (ListPool<PointDefinitionValue>.Get(out var values))
        {
            foreach (var point in node.Children)
            {
                if (!point.IsArray) return null; // bruh

                var value = new PointDefinitionValue();
                values.Add(value);
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
            }

            var pd = new PointDefinitionInterpolator(values.AsValueEnumerable().OrderBy(x => x.T).ToArray());
            return pd;
        }
    }

    public static PointOperation ParseOperation(JSONNode node)
    {
        var value = new PointDefinitionValue();
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

        return valueOp ?? new PointOperationNone(value);
    }

    private static readonly Dictionary<char, int> swizzleToIndex = new()
    {
        { 'x', 0 }, { 'y', 1 }, { 'z', 2 }, { 'w', 3 },
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

public sealed class PointDefinitionInterpolator
{
    private readonly PointDefinitionValue[] points;

    private (int index, PointDefinitionValue value) a;
    private (int index, PointDefinitionValue value) b;

    public PointDefinitionInterpolator(PointDefinitionValue value)
    {
        points = new[] { value };
        a = b = (0, value);
    }

    public PointDefinitionInterpolator(PointDefinitionValue[] values)
    {
        points = values;
        if (points.Length == 0) throw new ArgumentException("Point definition must contain at least 1 point");
        a = (0, points[0]);
        b = points.Length > 1 ? (1, points[1]) : a;
    }

    public float GetFloat(float normalized)
    {
        SearchIfNeeded(normalized);
        if (a.value == b.value) return b.value.Float;

        var t = Mathf.InverseLerp(a.value.T, b.value.T, normalized);
        var easing = b.value.Easing;
        t = Mathf.Clamp01(easing(t));

        return Mathf.LerpUnclamped(a.value.Float, b.value.Float, t);
    }

    public Vector3 GetVector3(float normalized)
    {
        SearchIfNeeded(normalized);
        if (a.value == b.value) return b.value.Vector3;

        var t = Mathf.InverseLerp(a.value.T, b.value.T, normalized);
        var easing = b.value.Easing;
        t = Mathf.Clamp01(easing(t));

        if (!b.value.SplineCatmullRom) return Vector3.LerpUnclamped(a.value.Vector3, b.value.Vector3, t);

        // Catmull-Rom Spline
        var p0 = a.index - 1 < 0 ? points[a.index].Vector3 : points[a.index - 1].Vector3;
        var p1 = points[a.index].Vector3;
        var p2 = points[b.index].Vector3;
        var p3 = b.index + 1 > points.Length - 1
            ? points[b.index].Vector3
            : points[b.index + 1].Vector3;

        var tt = t * t;
        var ttt = tt * t;

        var q0 = -ttt + (2.0f * tt) - t;
        var q1 = (3.0f * ttt) - (5.0f * tt) + 2.0f;
        var q2 = (-3.0f * ttt) + (4.0f * tt) + t;
        var q3 = ttt - tt;

        var c = 0.5f * ((p0 * q0) + (p1 * q1) + (p2 * q2) + (p3 * q3));

        return c;
    }

    public Vector4 GetVector4(float normalized)
    {
        SearchIfNeeded(normalized);
        if (a.value == b.value) return b.value.Vector4;

        var t = Mathf.InverseLerp(a.value.T, b.value.T, normalized);
        var easing = b.value.Easing;
        t = Mathf.Clamp01(easing(t));

        return Vector4.LerpUnclamped(a.value.Vector4, b.value.Vector4, t);
    }

    public Quaternion GetQuaternion(float normalized)
    {
        SearchIfNeeded(normalized);
        if (a.value == b.value) return b.value.Quaternion;

        var t = Mathf.InverseLerp(a.value.T, b.value.T, normalized);
        var easing = b.value.Easing;
        t = Mathf.Clamp01(easing(t));

        return Quaternion.SlerpUnclamped(a.value.Quaternion, b.value.Quaternion, t);
    }

    public Color GetColor(float normalized)
    {
        SearchIfNeeded(normalized);
        if (a.value == b.value) return b.value.Color;

        var t = Mathf.InverseLerp(a.value.T, b.value.T, normalized);
        var easing = b.value.Easing;
        t = Mathf.Clamp01(easing(t));

        var p = a.value.Color;
        var q = b.value.Color;

        return b.value.LerpHSV ? LightColorTween.LerpHSV(p, q, t) : Color.LerpUnclamped(p, q, t);
    }

    private void SearchIfNeeded(float normalized)
    {
        if (points.Length < 3) return;
        if (a.value.T <= normalized && normalized < b.value.T) return;

        var prev = 0;
        var next = points.Length - 1;

        while (prev < next - 1)
        {
            var m = (prev + next) / 2;
            var t = points[m].T;

            if (t < normalized)
                prev = m;
            else
                next = m;
        }

        a.index = prev;
        a.value = points[prev];
        b.index = next;
        b.value = points[next];
    }
}

// unity cant use c# expression tree without runnin into exception for unsupported platform :(
// also i need to clean this up with better structure, just throwing ideas out first
public sealed class PointDefinitionValue
{
    private float x;
    private float y;
    private float z;
    private float w;

    public float T;
    public Func<float, float> Easing = global::Easing.Linear;

    public bool SplineCatmullRom;
    public bool LerpHSV;

    private PointOperation[] pointOperations = Array.Empty<PointOperation>();

    private Func<float> getterX;
    private Func<float> getterY;
    private Func<float> getterZ;
    private Func<float> getterW;

    public float X
    {
        get
        {
            var val = getterX();
            return pointOperations
                .AsValueEnumerable()
                .Aggregate(val, (current, pointOperation) => pointOperation.EvaluateX(current));
        }
        set => x = value;
    }

    public float Y
    {
        get
        {
            var val = getterY();
            return pointOperations
                .AsValueEnumerable()
                .Aggregate(val, (current, pointOperation) => pointOperation.EvaluateY(current));
        }
        set => y = value;
    }

    public float Z
    {
        get
        {
            var val = getterZ();
            return pointOperations
                .AsValueEnumerable()
                .Aggregate(val, (current, pointOperation) => pointOperation.EvaluateZ(current));
        }
        set => z = value;
    }

    public float W
    {
        get
        {
            var val = getterW();
            return pointOperations
                .AsValueEnumerable()
                .Aggregate(val, (current, pointOperation) => pointOperation.EvaluateW(current));
        }
        set => w = value;
    }

    public PointDefinitionValue()
    {
        getterX = () => x;
        getterY = () => y;
        getterZ = () => z;
        getterW = () => w;
    }

    public void SetGetter(int index, float val)
    {
        switch (index)
        {
            case 0:
                x = val;
                break;
            case 1:
                y = val;
                break;
            case 2:
                z = val;
                break;
            case 3:
                w = val;
                break;
        }
    }

    public void SetGetter(int index, Func<float> getter)
    {
        switch (index)
        {
            case 0:
                getterX = getter;
                break;
            case 1:
                getterY = getter;
                break;
            case 2:
                getterZ = getter;
                break;
            case 3:
                getterW = getter;
                break;
        }
    }

    public void AddOperation(PointOperation operation) => pointOperations = pointOperations.Append(operation).ToArray();

    // maybe if i decide expression is nicer
    // public void CompileExpression(){}

    public float Float => X;
    public Vector3 Vector2 => new(X, Y);
    public Vector3 Vector3 => new(X, Y, Z);
    public Vector4 Vector4 => new(X, Y, Z, W);
    public Quaternion Quaternion => Quaternion.Euler(X, Y, Z);
    public Color Color => new(X, Y, Z, W);
}

public abstract class PointOperation
{
    public readonly PointDefinitionValue Rhs;
    public abstract float EvaluateX(float lhs);
    public abstract float EvaluateY(float lhs);
    public abstract float EvaluateZ(float lhs);
    public abstract float EvaluateW(float lhs);

    protected PointOperation(PointDefinitionValue rhs) => Rhs = rhs;
}

public class PointOperationNone : PointOperation
{
    public override float EvaluateX(float lhs) => lhs;
    public override float EvaluateY(float lhs) => lhs;
    public override float EvaluateZ(float lhs) => lhs;
    public override float EvaluateW(float lhs) => lhs;

    public PointOperationNone(PointDefinitionValue rhs) : base(rhs) { }
}

public class PointOperationAdd : PointOperation
{
    public override float EvaluateX(float lhs) => lhs + Rhs.X;
    public override float EvaluateY(float lhs) => lhs + Rhs.Y;
    public override float EvaluateZ(float lhs) => lhs + Rhs.Z;
    public override float EvaluateW(float lhs) => lhs + Rhs.W;

    public PointOperationAdd(PointDefinitionValue rhs) : base(rhs) { }
}

public class PointOperationSub : PointOperation
{
    public override float EvaluateX(float lhs) => lhs - Rhs.X;
    public override float EvaluateY(float lhs) => lhs - Rhs.Y;
    public override float EvaluateZ(float lhs) => lhs - Rhs.Z;
    public override float EvaluateW(float lhs) => lhs - Rhs.W;

    public PointOperationSub(PointDefinitionValue rhs) : base(rhs) { }
}

public class PointOperationMul : PointOperation
{
    public override float EvaluateX(float lhs) => lhs * Rhs.X;
    public override float EvaluateY(float lhs) => lhs * Rhs.Y;
    public override float EvaluateZ(float lhs) => lhs * Rhs.Z;
    public override float EvaluateW(float lhs) => lhs * Rhs.W;

    public PointOperationMul(PointDefinitionValue rhs) : base(rhs) { }
}

public class PointOperationDiv : PointOperation
{
    public override float EvaluateX(float lhs) => SafeDivide(lhs, Rhs.X);
    public override float EvaluateY(float lhs) => SafeDivide(lhs, Rhs.Y);
    public override float EvaluateZ(float lhs) => SafeDivide(lhs, Rhs.Z);
    public override float EvaluateW(float lhs) => SafeDivide(lhs, Rhs.W);

    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    private static float SafeDivide(float lhs, float rhs) => rhs == 0f ? 0f : lhs / rhs;

    public PointOperationDiv(PointDefinitionValue rhs) : base(rhs) { }
}

public class PointGetterSmoothing
{
    private float previous;
    private readonly float smoothFactor;
    private readonly Func<float> getter;

    public float Value => previous = Mathf.Lerp(previous, getter(), smoothFactor * TimeHelper.DeltaTime);
    public float GetValue() => Value;

    public PointGetterSmoothing(Func<float> getter, float smoothFactor)
    {
        this.getter = getter;
        this.smoothFactor = smoothFactor;
    }
}
