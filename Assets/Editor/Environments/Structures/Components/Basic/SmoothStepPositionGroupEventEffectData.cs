using UnityEngine;

public class SmoothStepPositionGroupEventEffectData : EnvironmentComponentData<SmoothStepPositionGroupEventEffect>
{
    public int GroupMinY;
    public int GroupMaxY;
    public float GroupStepSize;
    public Vector3 GroupStartPos;
    public string GroupEasing;

    public override void FillComponents(
        GameObject self,
        SmoothStepPositionGroupEventEffect comp,
        CreateContainer container)
    {
        comp.GroupMinY = GroupMinY;
        comp.GroupMaxY = GroupMaxY;
        comp.GroupStepSize = GroupStepSize;
        comp.GroupStartPos = GroupStartPos;
        comp.GroupEasing = GroupEasing;
        comp.SetElements(self.transform);

        container.Descriptor.BasicEventEffectManager.Register(9, comp);
    }
}
