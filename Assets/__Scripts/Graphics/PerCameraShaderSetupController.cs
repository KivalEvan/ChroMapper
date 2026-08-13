using UnityEngine;

// Built-in pipeline equivalent of SetShaderDefaults, SetFrustumPlanes, and
// MainEffectPreRenderPass. Every camera receives defaults before its draw. The
// selected editor camera then receives the configured main-effect state.
[DefaultExecutionOrder(-1000)]
public sealed class PerCameraShaderSetupController : MonoBehaviour
{
    public static PerCameraShaderSetupController Instance { get; private set; }

    private const string postBloomKeyword = "POST_BLOOM";

    private static readonly int baseColorBoostId = Shader.PropertyToID("_BaseColorBoost");
    private static readonly int baseColorBoostThresholdId = Shader.PropertyToID("_BaseColorBoostThreshold");
    private static readonly int frustumPlanesId = Shader.PropertyToID("_FrustumPlanes");

    [SerializeField] private PyramidBloomMainEffectController mainEffectController;

    private readonly Plane[] planes = new Plane[6];
    private readonly Vector4[] vectorPlanes = new Vector4[6];

    private Camera activeCamera;
    private bool active;
    private bool postBloomKeywordWasEnabled;

    public void AssignToCamera(CameraController cameraController) =>
        activeCamera = cameraController == null ? null : cameraController.Camera;

    private void OnEnable()
    {
        if (active) return;
        Instance = this;
        active = true;
        postBloomKeywordWasEnabled = Shader.IsKeywordEnabled(postBloomKeyword);
        Camera.onPreRender += OnCameraPreRender;
    }

    private void OnDisable()
    {
        if (!active) return;
        if (Instance == this) Instance = null;
        active = false;
        Camera.onPreRender -= OnCameraPreRender;

        Shader.SetGlobalFloat(baseColorBoostId, 1f);
        Shader.SetGlobalFloat(baseColorBoostThresholdId, 0f);
        Shader.SetGlobalVectorArray(frustumPlanesId, new Vector4[6]);
        SetPostBloomKeyword(postBloomKeywordWasEnabled);
    }

    private void OnCameraPreRender(Camera renderingCamera)
    {
        ApplyCameraState(renderingCamera);
    }

    public void ApplyCameraState(Camera renderingCamera)
    {
        Shader.SetGlobalFloat(baseColorBoostId, 1f);
        Shader.SetGlobalFloat(baseColorBoostThresholdId, 0f);
        SetPostBloomKeyword(false);
        UpdateFrustumPlanes(renderingCamera);

        if (renderingCamera != activeCamera
            && renderingCamera.GetComponent<MirrorCamera>() == null)
            return;

        if (mainEffectController == null)
            return;

        mainEffectController.ApplyPreRenderState();
        SetPostBloomKeyword(mainEffectController.IsReady);
    }

    private void UpdateFrustumPlanes(Camera renderingCamera)
    {
        var projectionMatrix = GL.GetGPUProjectionMatrix(
            renderingCamera.projectionMatrix,
            renderingCamera.targetTexture != null);
        GeometryUtility.CalculateFrustumPlanes(
            projectionMatrix * renderingCamera.worldToCameraMatrix,
            planes);

        for (var i = 0; i < planes.Length; i++)
        {
            var plane = planes[i];
            vectorPlanes[i] = new Vector4(
                plane.normal.x,
                plane.normal.y,
                plane.normal.z,
                plane.distance);
        }

        Shader.SetGlobalVectorArray(frustumPlanesId, vectorPlanes);
    }

    private static void SetPostBloomKeyword(bool enabled)
    {
        if (enabled)
        {
            if (!Shader.IsKeywordEnabled(postBloomKeyword)) Shader.EnableKeyword(postBloomKeyword);
        }
        else if (Shader.IsKeywordEnabled(postBloomKeyword))
        {
            Shader.DisableKeyword(postBloomKeyword);
        }
    }
}
