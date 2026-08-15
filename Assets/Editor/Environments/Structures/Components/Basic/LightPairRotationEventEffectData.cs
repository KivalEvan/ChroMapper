using UnityEngine;

public class LightPairRotationEventEffectData : EnvironmentComponentData<LightPairRotation>
{
    public EnvironmentEventType EventTypeL;
    public int TransformL;
    public EnvironmentEventType EventTypeR;
    public int TransformR;
    public EnvironmentEventType SwitchOverrideRandomValuesEvent;
    public Vector3 RotationVector;
    public bool OverrideRandomValues;
    public bool UseZPositionForAngleOffset;
    public float ZPositionAngleOffsetScale;
    public float StartRotation;

    public override void FillComponents(GameObject self, LightPairRotation comp, CreateContainer container)
    {
        comp.enabled = true;
        if (EventTypeL != -1)
            comp.LeftEffect = container.Descriptor.BasicEventEffectManager.GetOrRegister<LightRotationEffect>(EventTypeL);
        if (EventTypeR != -1)
            comp.RightEffect = container.Descriptor.BasicEventEffectManager.GetOrRegister<LightRotationEffect>(EventTypeR);
        if (SwitchOverrideRandomValuesEvent != -1)
        {
            comp.SwitchEffect = container.Descriptor.BasicEventEffectManager
                .GetOrRegister<GenericCallbackEventEffect>(SwitchOverrideRandomValuesEvent);
        }

        var lT = container.GetComponentOrNull<Transform>(TransformL);
        lT.gameObject.GetComponent<ChromaIDMarker>().MarkUse = true;
        var rT = container.GetComponentOrNull<Transform>(TransformR);
        rT.gameObject.GetComponent<ChromaIDMarker>().MarkUse = true;
        comp.Transforms =
            new LightPairRotation.TransformContainer[] { new() { Transform = lT }, new() { Transform = rT } };
        comp.RotationVector = RotationVector;
        comp.OverrideRandomValues = OverrideRandomValues;
        comp.UseZPositionForAngleOffset = UseZPositionForAngleOffset;
        comp.ZPositionAngleOffsetScale = ZPositionAngleOffsetScale;
        comp.StartRotation = StartRotation;
    }
}
