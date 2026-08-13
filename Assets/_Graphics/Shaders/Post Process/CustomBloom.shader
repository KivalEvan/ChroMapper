// ChroMapper custom bloom.
//
// Replaces Unity's Post Processing v2 stack (com.unity.postprocessing is no
// longer a dependency). The recovered bloom kernels are shared with bloom fog.
// The scene-owned BloomRenderer records this shader into the main-effect
// command buffer.
//
// Prefilter, pyramid, and final bloom were consolidated with the
// recovered game pipeline (Hidden/PostProcessing/Bloom): the high-quality
// route uses the game's 13-tap kernel. Pyramid levels merge with the game's
// per-level _CombineParams weights. Main bloom ends with a plain tent merge;
// bloom fog uses the separate final pass that applies its exposure knee and
// ACES curve. Hidden/MainEffect blends main bloom with the scene.
// Chromatic aberration moved to its own shader (ChromaticAberration.shader,
// driven by ChromaticAberrationRenderer; see Assets/_Graphics/Shaders/README.md).
Shader "ChroMapper/Post Process/Bloom"
{
    Properties
    {
        // Registered texture properties. CommandBuffer.Blit binds its source through
        // the material's property registry (Shader.PropertyToID set by the
        // framework), and SetTexture updates registered textures - code-only
        // declarations are not enough for either path: the blit source would
        // otherwise fall through to Unity's default 16x16 gray texture on
        // Unity 6 (the sampler never receives the frame).
        _MainTex ("Texture", 2D) = "white" {}
        // Alpha gate k = the game's alphaWeights (PyramidBloomMainEffectSO
        // _alphaWeights = 4): the prefilter scales rgb by saturate(alpha * k).
        // With k = 4 the gate saturates at alpha >= 0.25 (game cb0[103].z).
        _BloomThreshold ("Bloom Threshold (alpha gate)", Float) = 4
    }

    HLSLINCLUDE

    // Vertex helper for the Unity 6 blit mesh.

    #include "UnityCG.cginc"
    #include "../ShaderLibrary/BloomShared.hlsl"

    struct VaryingsDefault
    {
        float4 vertex : SV_POSITION;
        float2 texcoord : TEXCOORD0;
    };

    VaryingsDefault VertDefault(appdata_img v)
    {
        VaryingsDefault o;
        o.vertex = UnityObjectToClipPos(v.vertex);
        o.texcoord = v.texcoord;
        return o;
    }

    TEXTURE2D(_MainTex);
    SAMPLER(sampler_MainTex);
    TEXTURE2D(_BloomTex);
    SAMPLER(sampler_BloomTex);
    TEXTURE2D(_GlobalIntensityTex);
    SAMPLER(sampler_GlobalIntensityTex);

    // Per-blit texel size (xy = 1/size, zw = size), set by BloomRenderer so each
    // pyramid level samples at its own resolution (CommandBuffer.Blit does not update
    // _MainTex_TexelSize for intermediate render textures).
    float4 _BloomTexelSize;
    float _SampleScale;
    float _BloomThreshold;
    // Game _BloomParams (PyramidBloomRendererSO.RenderBloom): x = autoExposureLimit,
    // y = fractional pyramid LOD, z = alphaWeights, w = legacyAutoExposure flag.
    // x/w drive the auto-exposure knee in the final bloom pass. z is mirrored
    // by _BloomThreshold (game alphaWeights = 4) in the prefilter.
    float4 _BloomParams;
    // Game _CombineParams (PyramidBloomRendererSO.RenderBloom, cb0[102]):
    // per-level upsample merge weights (x = destination level, y = accumulated
    // pyramid), set per blit by BloomRenderer.
    float4 _CombineParams;

    float4 FragPrefilter(VaryingsDefault i) : SV_Target
    {
        // Recovered game prefilter: 13-tap downsample, then the alpha-driven gate
        // rgb *= saturate(alpha * k) with k = _BloomThreshold (game cb0[103].z,
        // _alphaWeights = 4). The alpha channel is the bloom mask: the game's
        // Deferred route writes alpha = a * bloomMultiplier, so pixels with
        // alpha 0 never reach the bloom pyramid. With k = 4 the gate saturates
        // at alpha >= 0.25, so a quarter mask coverage passes full colour.
        float4 color = BloomDownsample13Classic(
            TEXTURE2D_PARAM(_MainTex, sampler_MainTex), i.texcoord,
            _BloomTexelSize.xy);
        color.rgb *= saturate(color.a * _BloomThreshold);
        return color;
    }

    float4 FragDownsample13(VaryingsDefault i) : SV_Target
    {
        // The game's mid-pyramid levels use the same 13-tap kernel as the
        // prefilter, without the alpha gate (0x644A670E; 0x77AEF5F8 =
        // prefilter = this kernel + the saturate(alpha * k) gate). The PPv2
        // 13-tap kernel has a different layout.
        float4 color = BloomDownsample13Classic(
            TEXTURE2D_PARAM(_MainTex, sampler_MainTex), i.texcoord,
            _BloomTexelSize.xy);
        return color;
    }

    float4 FragDownsample4(VaryingsDefault i) : SV_Target
    {
        return BloomDownsample4(
            TEXTURE2D_PARAM(_MainTex, sampler_MainTex), i.texcoord,
            abs(_BloomTexelSize.xy));
    }

    float4 FragUpsampleTent(VaryingsDefault i) : SV_Target
    {
        float4 upsampled = BloomUpsampleTent(
            TEXTURE2D_PARAM(_MainTex, sampler_MainTex), i.texcoord, _BloomTexelSize.xy,
            _SampleScale);
        float4 level = SAMPLE_TEXTURE2D(_BloomTex, sampler_BloomTex, i.texcoord);
        return BloomWeightedCombine(
            level, upsampled, _CombineParams.x, _CombineParams.y);
    }

    float4 FragUpsampleBox(VaryingsDefault i) : SV_Target
    {
        float4 upsampled = BloomUpsampleBox(
            TEXTURE2D_PARAM(_MainTex, sampler_MainTex), i.texcoord, _BloomTexelSize.xy,
            _SampleScale);
        float4 level = SAMPLE_TEXTURE2D(_BloomTex, sampler_BloomTex, i.texcoord);
        return BloomWeightedCombine(
            level, upsampled, _CombineParams.x, _CombineParams.y);
    }

    float4 FragFinalUpsampleTent(VaryingsDefault i) : SV_Target
    {
        float4 upsampled = BloomUpsampleTent(
            TEXTURE2D_PARAM(_MainTex, sampler_MainTex), i.texcoord, _BloomTexelSize.xy,
            _SampleScale);
        float4 level = SAMPLE_TEXTURE2D(_BloomTex, sampler_BloomTex, i.texcoord);
        float4 combined = BloomWeightedCombine(
            level, upsampled, _CombineParams.x, _CombineParams.y);
        float3 globalIntensity = SAMPLE_TEXTURE2D(
            _GlobalIntensityTex, sampler_GlobalIntensityTex, float2(0.5, 0.5)).rgb;
        return BloomApplyKneeAndAces(
            combined, globalIntensity, _BloomParams.x, _BloomParams.w);
    }

    ENDHLSL

    SubShader
    {
        Cull Off ZWrite Off ZTest Always

        // 0 high-quality prefilter 13-tap
        Pass
        {
            HLSLPROGRAM
            #pragma vertex VertDefault
            #pragma fragment FragPrefilter
            ENDHLSL
        }
        // 1 high-quality downsample 13-tap
        Pass
        {
            HLSLPROGRAM
            #pragma vertex VertDefault
            #pragma fragment FragDownsample13
            ENDHLSL
        }
        // 2 high-quality intermediate upsample tent
        Pass
        {
            HLSLPROGRAM
            #pragma vertex VertDefault
            #pragma fragment FragUpsampleTent
            ENDHLSL
        }
        // 3 bloom-fog final upsample with exposure knee + ACES
        Pass
        {
            HLSLPROGRAM
            #pragma vertex VertDefault
            #pragma fragment FragFinalUpsampleTent
            ENDHLSL
        }
        // 4 bloom-fog authored 4-tap downsample
        Pass
        {
            HLSLPROGRAM
            #pragma vertex VertDefault
            #pragma fragment FragDownsample4
            ENDHLSL
        }
        // 5 low-definition bloom-fog intermediate box upsample
        Pass
        {
            HLSLPROGRAM
            #pragma vertex VertDefault
            #pragma fragment FragUpsampleBox
            ENDHLSL
        }
    }
}
