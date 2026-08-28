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

    private Cubemap blackCubemap;

    public Vector3 Position => transform.position;

    protected void Start() => SendDataToShaders();

    public void SendDataToShaders()
    {
        var position = transform.position;
        var boundsCenter = position + Offset;
        Shader.SetGlobalVector(reflectionProbeBoundsMinId, boundsCenter - Size * 0.5f);
        Shader.SetGlobalVector(reflectionProbeBoundsMaxId, boundsCenter + Size * 0.5f);
        Shader.SetGlobalVector(reflectionProbePositionId, position);
        Shader.SetGlobalTexture(
            reflectionProbeTexture1Id,
            ReflectionProbeData != null && ReflectionProbeData.ReflectionProbeCubemap1 != null
                ? ReflectionProbeData.ReflectionProbeCubemap1
                : GetOrCreateBlackCubemap());
        Shader.SetGlobalTexture(
            reflectionProbeTexture2Id,
            ReflectionProbeData != null && ReflectionProbeData.ReflectionProbeCubemap2 != null
                ? ReflectionProbeData.ReflectionProbeCubemap2
                : GetOrCreateBlackCubemap());
    }

    private Cubemap GetOrCreateBlackCubemap()
    {
        if (blackCubemap == null)
        {
            blackCubemap = new Cubemap(1, TextureFormat.RGBA32, false)
            {
                hideFlags = HideFlags.HideAndDontSave
            };
            var black = new[] { Color.black };
            blackCubemap.SetPixels(black, CubemapFace.PositiveX);
            blackCubemap.SetPixels(black, CubemapFace.NegativeX);
            blackCubemap.SetPixels(black, CubemapFace.PositiveY);
            blackCubemap.SetPixels(black, CubemapFace.NegativeY);
            blackCubemap.SetPixels(black, CubemapFace.PositiveZ);
            blackCubemap.SetPixels(black, CubemapFace.NegativeZ);
            blackCubemap.Apply();
        }

        return blackCubemap;
    }
}
