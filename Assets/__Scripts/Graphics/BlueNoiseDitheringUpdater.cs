using UnityEngine;

[ExecuteAlways]
public sealed class BlueNoiseDitheringUpdater : MonoBehaviour
{
    [SerializeField] private BlueNoiseDithering blueNoiseDithering;
    [SerializeField] private RandomValueToShader randomValueToShader;

    private void OnEnable()
    {
        Camera.onPreRender -= HandleCameraPreRender;
        Camera.onPreRender += HandleCameraPreRender;
    }

    private void OnDisable() => Camera.onPreRender -= HandleCameraPreRender;

    private void HandleCameraPreRender(Camera renderingCamera)
    {
        randomValueToShader.SetRandomValueToShaders();
        blueNoiseDithering.SetBlueNoiseShaderParams(
            Mathf.Max(renderingCamera.pixelWidth, 1),
            Mathf.Max(renderingCamera.pixelHeight, 1));
    }
}
