using System;
using UnityEngine;

public sealed class PointDefinitionInterpolator
{
    private readonly IPointDefinitionValue[] points;

    private (int index, IPointDefinitionValue value) a;
    private (int index, IPointDefinitionValue value) b;

    public PointDefinitionInterpolator(IPointDefinitionValue value)
    {
        points = new[] { value };
        a = b = (0, value);
    }

    public PointDefinitionInterpolator(IPointDefinitionValue[] values)
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
