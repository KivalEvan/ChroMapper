using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;

// Built-in pipeline equivalent of Beat Saber 1.44.1's screen-displacement
// passes. Registered displacement renderers are excluded from the normal
// camera pass and drawn after the other transparent objects.
public sealed class ScreenDisplacementRenderingController : MonoBehaviour
{
    private const CameraEvent displacementCameraEvent = CameraEvent.AfterForwardAlpha;

    private static readonly int grabTextureId = Shader.PropertyToID("_ScreenDisplacementGrabTexture");
    private static readonly int grabTextureTexelSizeId =
        Shader.PropertyToID("_ScreenDisplacementGrabTexture_TexelSize");
    [SerializeField, Range(0, 31)] private int displacementLayer = 31;

    private readonly List<ScreenDisplacementRenderer> sortedRenderers = new();

    private Camera activeCamera;
    private CommandBuffer commandBuffer;
    private int previousDisplacementLayerMask;
    private bool active;
    private bool commandBufferAttached;
    private bool screenDisplacementEnabled;
    private bool settingsCallbackSubscribed;

    public void AssignToCamera(CameraController cameraController)
    {
        DetachCommandBuffer();
        activeCamera = cameraController == null ? null : cameraController.Camera;
        AttachCommandBuffer();
    }

    private void OnEnable()
    {
        UpdateScreenDisplacement(Settings.Instance.ScreenDisplacement);
        if (!settingsCallbackSubscribed)
        {
            Settings.NotifyBySettingName(nameof(Settings.ScreenDisplacement), UpdateScreenDisplacement);
            settingsCallbackSubscribed = true;
        }
        if (screenDisplacementEnabled) Activate();
    }

    private void OnDisable()
    {
        if (settingsCallbackSubscribed)
        {
            Settings.StopNotifyingBySettingName(
                nameof(Settings.ScreenDisplacement), UpdateScreenDisplacement);
            settingsCallbackSubscribed = false;
        }
        Deactivate();
        ScreenDisplacementRenderer.SetEnabled(false);
    }

    private void OnDestroy()
    {
        OnDisable();
        Deactivate();
        if (commandBuffer != null)
        {
            commandBuffer.Release();
            commandBuffer = null;
        }
    }

    private void Activate()
    {
        if (active || !screenDisplacementEnabled) return;
        active = true;
        ScreenDisplacementRenderer.SetEnabled(true);
        Camera.onPreRender += OnCameraPreRender;
        AttachCommandBuffer();
    }

    private void Deactivate()
    {
        if (active)
        {
            active = false;
            Camera.onPreRender -= OnCameraPreRender;
        }
        DetachCommandBuffer();
        ScreenDisplacementRenderer.SetEnabled(false);
    }

    private void AttachCommandBuffer()
    {
        if (!active || activeCamera == null || commandBufferAttached) return;

        commandBuffer ??= new CommandBuffer { name = "ChroMapper Screen Displacement" };
        var layerBit = 1 << displacementLayer;
        previousDisplacementLayerMask = activeCamera.cullingMask & layerBit;
        activeCamera.cullingMask &= ~layerBit;
        activeCamera.AddCommandBuffer(displacementCameraEvent, commandBuffer);
        commandBufferAttached = true;
    }

    private void DetachCommandBuffer()
    {
        if (!commandBufferAttached) return;

        if (activeCamera != null)
        {
            activeCamera.RemoveCommandBuffer(displacementCameraEvent, commandBuffer);
            var layerBit = 1 << displacementLayer;
            activeCamera.cullingMask =
                (activeCamera.cullingMask & ~layerBit) | previousDisplacementLayerMask;
        }

        commandBufferAttached = false;
        commandBuffer?.Clear();
        Shader.SetGlobalTexture(grabTextureId, null);
        Shader.SetGlobalVector(grabTextureTexelSizeId, Vector4.zero);
    }

    private void OnCameraPreRender(Camera renderingCamera)
    {
        if (renderingCamera != activeCamera || commandBuffer == null) return;

        commandBuffer.Clear();
        CollectRenderers();
        if (sortedRenderers.Count == 0) return;

        var grabDescriptor = GetGrabDescriptor();
        var sourceWidth = grabDescriptor.width;
        var sourceHeight = grabDescriptor.height;
        var cameraTarget = new RenderTargetIdentifier(BuiltinRenderTextureType.CameraTarget);

        commandBuffer.GetTemporaryRT(grabTextureId, grabDescriptor, FilterMode.Bilinear);
        commandBuffer.Blit(cameraTarget, grabTextureId);
        commandBuffer.SetGlobalTexture(grabTextureId, grabTextureId);
        commandBuffer.SetGlobalVector(
            grabTextureTexelSizeId,
            new Vector4(1f / sourceWidth, 1f / sourceHeight, sourceWidth, sourceHeight));
        commandBuffer.SetRenderTarget(cameraTarget);

        foreach (var displacementRenderer in sortedRenderers)
        {
            var renderer = displacementRenderer.TargetRenderer;
            commandBuffer.DrawRenderer(renderer, renderer.sharedMaterial, 0, -1);
        }

        commandBuffer.SetGlobalTexture(grabTextureId, Texture2D.blackTexture);
        commandBuffer.SetGlobalVector(grabTextureTexelSizeId, Vector4.zero);
        commandBuffer.ReleaseTemporaryRT(grabTextureId);
    }

    private void CollectRenderers()
    {
        sortedRenderers.Clear();
        foreach (var displacementRenderer in ScreenDisplacementRenderer.Renderers)
        {
            if (displacementRenderer != null && displacementRenderer.IsReady)
                sortedRenderers.Add(displacementRenderer);
        }

        var cameraTransform = activeCamera.transform;
        sortedRenderers.Sort((left, right) =>
        {
            var leftRenderer = left.TargetRenderer;
            var rightRenderer = right.TargetRenderer;
            var comparison = SortingLayer.GetLayerValueFromID(leftRenderer.sortingLayerID)
                .CompareTo(SortingLayer.GetLayerValueFromID(rightRenderer.sortingLayerID));
            if (comparison != 0) return comparison;

            comparison = leftRenderer.sortingOrder.CompareTo(rightRenderer.sortingOrder);
            if (comparison != 0) return comparison;

            comparison = leftRenderer.sharedMaterial.renderQueue
                .CompareTo(rightRenderer.sharedMaterial.renderQueue);
            if (comparison != 0) return comparison;

            // Approximate the game's QuantizedFrontToBack criterion. The built-in
            // command buffer does not expose URP's renderer-list sorter.
            var leftDepth = Vector3.Dot(
                leftRenderer.bounds.center - cameraTransform.position,
                cameraTransform.forward);
            var rightDepth = Vector3.Dot(
                rightRenderer.bounds.center - cameraTransform.position,
                cameraTransform.forward);
            return leftDepth.CompareTo(rightDepth);
        });
    }

    private void UpdateScreenDisplacement(object value)
    {
        screenDisplacementEnabled = System.Convert.ToBoolean(value);
        if (screenDisplacementEnabled)
        {
            ScreenDisplacementRenderer.SetEnabled(true);
            if (isActiveAndEnabled) Activate();
        }
        else
        {
            Deactivate();
        }
    }

    private RenderTextureDescriptor GetGrabDescriptor()
    {
        var descriptor = GetCameraTargetDescriptor();
        descriptor.depthBufferBits = 0;
        descriptor.depthStencilFormat = GraphicsFormat.None;
        descriptor.msaaSamples = 1;
        descriptor.useDynamicScale = false;
        descriptor.useDynamicScaleExplicit = false;
        return descriptor;
    }

    private RenderTextureDescriptor GetCameraTargetDescriptor()
    {
        if (activeCamera.targetTexture != null)
        {
            var descriptor = activeCamera.targetTexture.descriptor;
            descriptor.width = Mathf.Max(activeCamera.scaledPixelWidth, 1);
            descriptor.height = Mathf.Max(activeCamera.scaledPixelHeight, 1);
            return descriptor;
        }

        return new RenderTextureDescriptor(
            Mathf.Max(activeCamera.scaledPixelWidth, 1),
            Mathf.Max(activeCamera.scaledPixelHeight, 1),
            activeCamera.allowHDR ? RenderTextureFormat.DefaultHDR : RenderTextureFormat.Default,
            0)
        {
            sRGB = QualitySettings.activeColorSpace == ColorSpace.Linear
        };
    }

}
