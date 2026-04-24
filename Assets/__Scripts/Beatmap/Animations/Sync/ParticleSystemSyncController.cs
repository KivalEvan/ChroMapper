using UnityEngine;

[RequireComponent(typeof(ParticleSystem))]
public class ParticleSystemSyncController : SyncController
{
    private ParticleSystem _particleSystem = null!;

    public override void ResetTime() { }

    public override void Sync(float speed)
    {
        var particleSystemMain = _particleSystem.main;
        particleSystemMain.simulationSpeed = speed;
    }

    private void Awake() => _particleSystem = GetComponent<ParticleSystem>();
}
