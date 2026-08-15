using UnityEngine;

public class LightPairSinMoveEventEffectData : EnvironmentComponentData<LightPairSinMove>
{
    public EnvironmentEventType EventTypeL;
    public int TransformL;
    public EnvironmentEventType EventTypeR;
    public int TransformR;
    public EnvironmentEventType SwitchOverrideRandomValuesEvent;
    public bool OverrideRandomValues;
    public float StartValueOffset;
    public Vector3 StartPositionOffset;
    public Vector3 EndPositionOffset;

    public override void FillComponents(GameObject self, LightPairSinMove comp, CreateContainer container)
    {
        comp.enabled = true;
        if (EventTypeL != -1)
            comp.LeftEffect = container.Descriptor.BasicEventEffectManager.GetOrRegister<LightRotationEffect>(EventTypeL);
        if (EventTypeR != -1)
            comp.RightEffect = container.Descriptor.BasicEventEffectManager.GetOrRegister<LightRotationEffect>(EventTypeR);
        if (SwitchOverrideRandomValuesEvent != -1)
        {
            comp.SwitchEffect =
                container.Descriptor.BasicEventEffectManager.GetOrRegister<GenericCallbackEventEffect>(SwitchOverrideRandomValuesEvent);
        }

        var lT = container.GetComponentOrNull<Transform>(TransformL);
        lT.gameObject.GetComponent<ChromaIDMarker>().MarkUse = true;
        var rT = container.GetComponentOrNull<Transform>(TransformR);
        rT.gameObject.GetComponent<ChromaIDMarker>().MarkUse = true;
        comp.Transforms =
            new LightPairSinMove.TransformContainer[] { new() { Transform = lT }, new() { Transform = rT } };
        comp.OverrideRandomValues = OverrideRandomValues;
        comp.StartValueOffset = StartValueOffset;
        comp.StartPositionOffset = StartPositionOffset;
        comp.EndPositionOffset = EndPositionOffset;
    }
}
