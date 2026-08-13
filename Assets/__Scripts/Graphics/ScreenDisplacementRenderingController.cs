using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;

// Built-in pipeline equivalent of the game's screen-displacement grab and
// draw passes. Registered displacement renderers are excluded from the normal
// camera pass and drawn after the other transparent objects.
public sealed class ScreenDisplacementRenderingController : MonoBehaviour
{
    private const CameraEvent displacementCameraEvent = CameraEvent.AfterForwardAlpha;

    private static readonly int grabTextureId = Shader.PropertyToID("_ScreenDisplacementGrabTexture");
    private static readonly int grabTextureTexelSizeId =
        Shader.PropertyToID("_ScreenDisplacementGrabTexture_TexelSize");
    private static readonly int activeDepthTextureId = Shader.PropertyToID("_ChroMapperActiveDepthTexture");
    private static readonly int cameraDepthTextureId = Shader.PropertyToID("_CameraDepthTexture");

    [SerializeField, Range(0, 31)] private int displacementLayer = 31;
    [SerializeField] private Shader copyDepthShader;

    private readonly List<ScreenDisplacementRenderer> sortedRenderers = new();

    private Camera activeCamera;
    private CommandBuffer commandBuffer;
    private Material copyDepthMaterial;
    private RenderTexture updatedDepthTexture;
    private int previousDisplacementLayerMask;
    private bool active;
    private bool commandBufferAttached;
    private bool screenDisplacementEnabled;
    private bool settingsCallbackSubscribed;

    private void Awake()
    {
        copyDepthMaterial = new Material(copyDepthShader)
        {
            hideFlags = HideFlags.HideAndDontSave
        };
    }

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
        if (copyDepthMaterial != null) Destroy(copyDepthMaterial);
        ReleaseUpdatedDepthTexture();
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
        Shader.SetGlobalTexture(cameraDepthTextureId, null);
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

        // Unity's built-in depth texture is captured before transparent draws.
        // Copy the updated camera depth after displacement when MSAA is off.
        // With MSAA, keep Unity's resolved opaque depth texture.
        if (!activeCamera.allowMSAA || QualitySettings.antiAliasing <= 1)
        {
            EnsureUpdatedDepthTexture(sourceWidth, sourceHeight);
            commandBuffer.SetGlobalTexture(activeDepthTextureId, BuiltinRenderTextureType.Depth);
            commandBuffer.Blit(null, updatedDepthTexture, copyDepthMaterial);
            commandBuffer.SetGlobalTexture(cameraDepthTextureId, updatedDepthTexture);
            commandBuffer.SetGlobalTexture(activeDepthTextureId, Texture2D.blackTexture);
        }
    }

    private void CollectRenderers()
    {
        sortedRenderers.Clear();
        foreach (var displacementRenderer in ScreenDisplacementRenderer.Renderers)
        {
            if (displacementRenderer != null && displacementRenderer.IsReady)
                sortedRenderers.Add(displacementRenderer);
        }

        var cameraPosition = activeCamera.transform.position;
        sortedRenderers.Sort((left, right) =>
        {
            var leftDistance = (left.transform.position - cameraPosition).sqrMagnitude;
            var rightDistance = (right.transform.position - cameraPosition).sqrMagnitude;
            return rightDistance.CompareTo(leftDistance);
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
        var targetTexture = activeCamera.targetTexture;
        var descriptor = targetTexture != null
            ? targetTexture.descriptor
            : new RenderTextureDescriptor(
                Mathf.Max(activeCamera.scaledPixelWidth, 1),
                Mathf.Max(activeCamera.scaledPixelHeight, 1),
                activeCamera.allowHDR ? RenderTextureFormat.DefaultHDR : RenderTextureFormat.Default,
                0);
        descriptor.depthBufferBits = 0;
        descriptor.depthStencilFormat = GraphicsFormat.None;
        descriptor.msaaSamples = 1;
        return descriptor;
    }

    private void EnsureUpdatedDepthTexture(int width, int height)
    {
        if (updatedDepthTexture != null
            && updatedDepthTexture.width == width
            && updatedDepthTexture.height == height)
            return;

        ReleaseUpdatedDepthTexture();
        updatedDepthTexture = new RenderTexture(width, height, 0, RenderTextureFormat.RFloat)
        {
            name = "ChroMapper Updated Camera Depth",
            filterMode = FilterMode.Point,
            wrapMode = TextureWrapMode.Clamp,
            hideFlags = HideFlags.HideAndDontSave
        };
        updatedDepthTexture.Create();
    }

    private void ReleaseUpdatedDepthTexture()
    {
        if (updatedDepthTexture == null) return;
        updatedDepthTexture.Release();
        Destroy(updatedDepthTexture);
        updatedDepthTexture = null;
    }
}
