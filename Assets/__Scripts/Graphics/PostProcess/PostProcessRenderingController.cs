using UnityEngine;
using UnityEngine.Rendering;

// Built-in pipeline equivalent of the game's MainEffect renderer pass. The
// scene owns this controller and its command buffer.
public sealed class PostProcessRenderingController : MonoBehaviour
{
    [SerializeField] private PyramidBloomMainEffectController mainEffectController;
    [SerializeField] private ChromaticAberrationRenderer chromaticAberrationRenderer;

    private const CameraEvent postProcessCameraEvent = CameraEvent.BeforeImageEffects;

    private static readonly int sourceTextureId = Shader.PropertyToID("_ChroMapperPostProcessSource");
    private static readonly int mainEffectOutputId = Shader.PropertyToID("_ChroMapperMainEffectOutput");

    private Camera activeCamera;
    private CommandBuffer commandBuffer;
    private bool active;
    private bool commandBufferAttached;

    public void AssignToCamera(CameraController cameraController)
    {
        DetachCommandBuffer();
        activeCamera = cameraController == null ? null : cameraController.Camera;
        AttachCommandBuffer();
    }

    private void OnEnable() => Activate();

    private void OnDisable() => Deactivate();

    private void OnDestroy()
    {
        Deactivate();
        if (commandBuffer == null) return;
        commandBuffer.Release();
        commandBuffer = null;
    }

    private void Activate()
    {
        if (active) return;
        active = true;
        Camera.onPreRender += OnCameraPreRender;
        AttachCommandBuffer();
    }

    private void Deactivate()
    {
        if (!active) return;
        active = false;
        Camera.onPreRender -= OnCameraPreRender;
        DetachCommandBuffer();
    }

    private void AttachCommandBuffer()
    {
        if (!active || activeCamera == null || commandBufferAttached) return;

        commandBuffer ??= new CommandBuffer { name = "ChroMapper Main Effect" };
        activeCamera.AddCommandBuffer(postProcessCameraEvent, commandBuffer);
        commandBufferAttached = true;
    }

    private void DetachCommandBuffer()
    {
        if (!commandBufferAttached) return;
        if (activeCamera != null)
            activeCamera.RemoveCommandBuffer(postProcessCameraEvent, commandBuffer);
        commandBufferAttached = false;
        commandBuffer?.Clear();
    }

    private void OnCameraPreRender(Camera renderingCamera)
    {
        if (renderingCamera != activeCamera || commandBuffer == null) return;

        commandBuffer.Clear();
        var renderMainEffect = mainEffectController != null && mainEffectController.IsReady;
        var renderChromaticAberration =
            chromaticAberrationRenderer != null && chromaticAberrationRenderer.IsReady;
        var renderFade = mainEffectController != null && mainEffectController.IsFadeReady;
        if (!renderMainEffect && !renderChromaticAberration && !renderFade) return;

        var sourceWidth = Mathf.Max(activeCamera.scaledPixelWidth, 1);
        var sourceHeight = Mathf.Max(activeCamera.scaledPixelHeight, 1);
        var cameraTarget = new RenderTargetIdentifier(BuiltinRenderTextureType.CameraTarget);

        if (!renderMainEffect && !renderChromaticAberration)
        {
            mainEffectController.RecordFade(commandBuffer, cameraTarget);
            return;
        }

        commandBuffer.GetTemporaryRT(
            sourceTextureId,
            sourceWidth,
            sourceHeight,
            0,
            FilterMode.Bilinear,
            RenderTextureFormat.ARGBHalf,
            RenderTextureReadWrite.Linear);
        commandBuffer.Blit(cameraTarget, sourceTextureId);

        if (renderMainEffect && renderChromaticAberration)
        {
            commandBuffer.GetTemporaryRT(
                mainEffectOutputId,
                sourceWidth,
                sourceHeight,
                0,
                FilterMode.Bilinear,
                RenderTextureFormat.ARGBHalf,
                RenderTextureReadWrite.Linear);
            mainEffectController.RecordRender(
                commandBuffer, sourceTextureId, sourceWidth, sourceHeight, mainEffectOutputId);
            chromaticAberrationRenderer.RecordRender(
                commandBuffer, mainEffectOutputId, cameraTarget, sourceWidth, sourceHeight);
            commandBuffer.ReleaseTemporaryRT(mainEffectOutputId);
        }
        else if (renderMainEffect)
        {
            mainEffectController.RecordRender(
                commandBuffer, sourceTextureId, sourceWidth, sourceHeight, cameraTarget);
        }
        else if (renderChromaticAberration)
        {
            chromaticAberrationRenderer.RecordRender(
                commandBuffer, sourceTextureId, cameraTarget, sourceWidth, sourceHeight);
            if (renderFade) mainEffectController.RecordFade(commandBuffer, cameraTarget);
        }
        else
        {
            mainEffectController.RecordFade(commandBuffer, cameraTarget);
        }

        commandBuffer.ReleaseTemporaryRT(sourceTextureId);
    }
}
