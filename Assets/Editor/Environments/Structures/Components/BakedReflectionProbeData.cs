using UnityEngine;

public class BakedReflectionProbeData : EnvironmentComponentData<BakedReflectionProbe>
{
    public Vector3 ProbeSize;
    public Vector3 ProbePosition;

    public override void FillComponents(
        GameObject self,
        BakedReflectionProbe comp,
        CreateContainer container)
    {
        comp.Size = ProbeSize;
        comp.transform.position = ProbePosition;
    }
}
