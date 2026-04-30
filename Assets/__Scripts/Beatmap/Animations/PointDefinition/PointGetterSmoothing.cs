using System;
using UnityEngine;

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
