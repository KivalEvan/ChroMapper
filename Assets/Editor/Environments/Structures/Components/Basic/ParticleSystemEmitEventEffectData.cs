using UnityEngine;

public class ParticleSystemEmitEventEffectData : EnvironmentComponentData<ParticleSystemEmitEventEffect>
{
    public string EventType;
    public int ParticleSystemParentTransform;
    public int MaxSpawnedParticleSystems = 4;

    public override void FillComponents(
        GameObject self,
        ParticleSystemEmitEventEffect comp,
        CreateContainer container)
    {
        comp.Prefab = container.Library.ParticleSystemEventControllerPrefab;
        comp.ParticleSystemParentTransform =
            container.GetComponentOrNull<Transform>(ParticleSystemParentTransform);
        comp.MaxSpawnedParticleSystems = MaxSpawnedParticleSystems;
        container.Descriptor.BasicEventEffectManager.Register(ConvertUtils.ToEventType(EventType), comp);
    }
}
