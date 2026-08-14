using UnityEngine;

[ExecuteAlways]
public class BakedReflectionProbe : MonoBehaviour
{
    private static readonly int reflectionProbeBoundsMinId = Shader.PropertyToID("_ReflectionProbeBoundsMin");
    private static readonly int reflectionProbeBoundsMaxId = Shader.PropertyToID("_ReflectionProbeBoundsMax");
    private static readonly int reflectionProbePositionId = Shader.PropertyToID("_ReflectionProbePosition");
    private static readonly int reflectionProbeTexture1Id = Shader.PropertyToID("_ReflectionProbeTexture1");
    private static readonly int reflectionProbeTexture2Id = Shader.PropertyToID("_ReflectionProbeTexture2");

    public int ResolutionBeforeDownsample = 2048;
    public int DownsampleByHalfCount = 1;
    public Vector3 Size;
    public Vector3 Offset;
    public ReflectionProbeDataSO ReflectionProbeData;

    public Vector3 Position => transform.position;

    protected void Start()
    {
        if (ReflectionProbeData == null)
        {
            Debug.LogWarning("Reflection Probe Data not set");
            return;
        }

        SendDataToShaders();
    }

    public void SendDataToShaders()
    {
        var position = transform.position;
        var boundsCenter = position + Offset;
        Shader.SetGlobalVector(reflectionProbeBoundsMinId, boundsCenter - Size * 0.5f);
        Shader.SetGlobalVector(reflectionProbeBoundsMaxId, boundsCenter + Size * 0.5f);
        Shader.SetGlobalVector(reflectionProbePositionId, position);
        Shader.SetGlobalTexture(reflectionProbeTexture1Id, ReflectionProbeData.ReflectionProbeCubemap1);
        Shader.SetGlobalTexture(reflectionProbeTexture2Id, ReflectionProbeData.ReflectionProbeCubemap2);
    }
}
