// ChroMapper custom bloom + chromatic aberration.
//
// Replaces Unity's Post Processing v2 stack (com.unity.postprocessing is no
// longer a dependency): the PPv2 StdLib/xRLib vertex helpers and Sampling.hlsl
// kernels are inlined below so this shader compiles without the package.
// Driven by BloomRenderer through OnRenderImage (built-in render pipeline).
//
// Prefilter and combine were consolidated with the recovered game pipeline
// (Hidden/PostProcessing/Bloom): the prefilter is a classic 13-tap downsample
// gated by the alpha channel (the bloom mask), and the combine scales the bloom
// by the auto-exposure knee and runs it through the ACES curve before adding it
// to the scene. The knee mirrors the game's _BloomParams uniform
// (fragment-47497f82473c772f + PyramidBloomRendererSO, see Bloom.findings.md).
// Chromatic aberration ports the PPv2 Uber pass: spectral samples along the
// radial offset with the default R/G/B spectral lookup.
Shader "ChroMapper/Post Process/Bloom"
{
    Properties
    {
        _BloomThreshold ("Bloom Threshold (alpha gate)", Float) = 1
        _Intensity ("Bloom Intensity", Float) = 1
        _BloomParams ("Bloom Params (x=autoExposureLimit, w=legacyAutoExposure)", Vector) = (1000, 0, 0, 0)
        _GlobalIntensityTex ("Global Intensity Tex (1x1 luminance probe)", 2D) = "" {}
    }

    HLSLINCLUDE

    // ---- Vertex helpers, inlined from PPv2 3.5.4 StdLib.hlsl / xRLib.hlsl ----
    // (Desktop identity for the stereo helpers; ChroMapper is a non-VR editor tool.)

    float2 TransformTriangleVertexToUV(float2 vertex)
    {
        return (vertex + 1.0) * 0.5;
    }

    float2 TransformStereoScreenSpaceTex(float2 uv, float w)
    {
        return uv;
    }

    float2 UnityStereoTransformScreenSpaceTex(float2 uv)
    {
        return TransformStereoScreenSpaceTex(saturate(uv), 1.0);
    }

    struct AttributesDefault
    {
        float3 vertex : POSITION;
    };

    struct VaryingsDefault
    {
        float4 vertex : SV_POSITION;
        float2 texcoord : TEXCOORD0;
        float2 texcoordStereo : TEXCOORD1;
    };

    VaryingsDefault VertDefault(AttributesDefault v)
    {
        VaryingsDefault o;
        o.vertex = float4(v.vertex.xy, 0.0, 1.0);
        o.texcoord = TransformTriangleVertexToUV(v.vertex.xy);

#if UNITY_UV_STARTS_AT_TOP
        o.texcoord = o.texcoord * float2(1.0, -1.0) + float2(0.0, 1.0);
#endif

        o.texcoordStereo = TransformStereoScreenSpaceTex(o.texcoord, 1.0);
        return o;
    }

    // ---- Sampling kernels, verbatim from PPv2 3.5.4 Sampling.hlsl ----

    // Better, temporally stable box filtering
    // [Jimenez14] http://goo.gl/eomGso
    // . . . . . . .
    // . A . B . C .
    // . . D . E . .
    // . F . G . H .
    // . . I . J . .
    // . K . L . M .
    // . . . . . . .
    half4 DownsampleBox13Tap(TEXTURE2D_ARGS(tex, samplerTex), float2 uv, float2 texelSize)
    {
        half4 A = SAMPLE_TEXTURE2D(tex, samplerTex, UnityStereoTransformScreenSpaceTex(uv + texelSize * float2(-1.0, -1.0)));
        half4 B = SAMPLE_TEXTURE2D(tex, samplerTex, UnityStereoTransformScreenSpaceTex(uv + texelSize * float2( 0.0, -1.0)));
        half4 C = SAMPLE_TEXTURE2D(tex, samplerTex, UnityStereoTransformScreenSpaceTex(uv + texelSize * float2( 1.0, -1.0)));
        half4 D = SAMPLE_TEXTURE2D(tex, samplerTex, UnityStereoTransformScreenSpaceTex(uv + texelSize * float2(-0.5, -0.5)));
        half4 E = SAMPLE_TEXTURE2D(tex, samplerTex, UnityStereoTransformScreenSpaceTex(uv + texelSize * float2( 0.5, -0.5)));
        half4 F = SAMPLE_TEXTURE2D(tex, samplerTex, UnityStereoTransformScreenSpaceTex(uv + texelSize * float2(-1.0,  0.0)));
        half4 G = SAMPLE_TEXTURE2D(tex, samplerTex, UnityStereoTransformScreenSpaceTex(uv                                 ));
        half4 H = SAMPLE_TEXTURE2D(tex, samplerTex, UnityStereoTransformScreenSpaceTex(uv + texelSize * float2( 1.0,  0.0)));
        half4 I = SAMPLE_TEXTURE2D(tex, samplerTex, UnityStereoTransformScreenSpaceTex(uv + texelSize * float2(-0.5,  0.5)));
        half4 J = SAMPLE_TEXTURE2D(tex, samplerTex, UnityStereoTransformScreenSpaceTex(uv + texelSize * float2( 0.5,  0.5)));
        half4 K = SAMPLE_TEXTURE2D(tex, samplerTex, UnityStereoTransformScreenSpaceTex(uv + texelSize * float2(-1.0,  1.0)));
        half4 L = SAMPLE_TEXTURE2D(tex, samplerTex, UnityStereoTransformScreenSpaceTex(uv + texelSize * float2( 0.0,  1.0)));
        half4 M = SAMPLE_TEXTURE2D(tex, samplerTex, UnityStereoTransformScreenSpaceTex(uv + texelSize * float2( 1.0,  1.0)));

        half2 div = (1.0 / 4.0) * half2(0.5, 0.125);

        half4 o = (D + E + I + J) * div.x;
        o += (A + B + G + F) * div.y;
        o += (B + C + H + G) * div.y;
        o += (F + G + L + K) * div.y;
        o += (G + H + M + L) * div.y;

        return o;
    }

    // Standard box filtering
    half4 DownsampleBox4Tap(TEXTURE2D_ARGS(tex, samplerTex), float2 uv, float2 texelSize)
    {
        float4 d = texelSize.xyxy * float4(-1.0, -1.0, 1.0, 1.0);

        half4 s;
        s =  (SAMPLE_TEXTURE2D(tex, samplerTex, UnityStereoTransformScreenSpaceTex(uv + d.xy)));
        s += (SAMPLE_TEXTURE2D(tex, samplerTex, UnityStereoTransformScreenSpaceTex(uv + d.zy)));
        s += (SAMPLE_TEXTURE2D(tex, samplerTex, UnityStereoTransformScreenSpaceTex(uv + d.xw)));
        s += (SAMPLE_TEXTURE2D(tex, samplerTex, UnityStereoTransformScreenSpaceTex(uv + d.zw)));

        return s * (1.0 / 4.0);
    }

    // 9-tap bilinear upsampler (tent filter)
    half4 UpsampleTent(TEXTURE2D_ARGS(tex, samplerTex), float2 uv, float2 texelSize, float4 sampleScale)
    {
        float4 d = texelSize.xyxy * float4(1.0, 1.0, -1.0, 0.0) * sampleScale;

        half4 s;
        s =  SAMPLE_TEXTURE2D(tex, samplerTex, UnityStereoTransformScreenSpaceTex(uv - d.xy));
        s += SAMPLE_TEXTURE2D(tex, samplerTex, UnityStereoTransformScreenSpaceTex(uv - d.wy)) * 2.0;
        s += SAMPLE_TEXTURE2D(tex, samplerTex, UnityStereoTransformScreenSpaceTex(uv - d.zy));

        s += SAMPLE_TEXTURE2D(tex, samplerTex, UnityStereoTransformScreenSpaceTex(uv + d.zw)) * 2.0;
        s += SAMPLE_TEXTURE2D(tex, samplerTex, UnityStereoTransformScreenSpaceTex(uv       )) * 4.0;
        s += SAMPLE_TEXTURE2D(tex, samplerTex, UnityStereoTransformScreenSpaceTex(uv + d.xw)) * 2.0;

        s += SAMPLE_TEXTURE2D(tex, samplerTex, UnityStereoTransformScreenSpaceTex(uv + d.zy));
        s += SAMPLE_TEXTURE2D(tex, samplerTex, UnityStereoTransformScreenSpaceTex(uv + d.wy)) * 2.0;
        s += SAMPLE_TEXTURE2D(tex, samplerTex, UnityStereoTransformScreenSpaceTex(uv + d.xy));

        return s * (1.0 / 16.0);
    }

    // Standard box filtering
    half4 UpsampleBox(TEXTURE2D_ARGS(tex, samplerTex), float2 uv, float2 texelSize, float4 sampleScale)
    {
        float4 d = texelSize.xyxy * float4(-1.0, -1.0, 1.0, 1.0) * (sampleScale * 0.5);

        half4 s;
        s =  (SAMPLE_TEXTURE2D(tex, samplerTex, UnityStereoTransformScreenSpaceTex(uv + d.xy)));
        s += (SAMPLE_TEXTURE2D(tex, samplerTex, UnityStereoTransformScreenSpaceTex(uv + d.zy)));
        s += (SAMPLE_TEXTURE2D(tex, samplerTex, UnityStereoTransformScreenSpaceTex(uv + d.xw)));
        s += (SAMPLE_TEXTURE2D(tex, samplerTex, UnityStereoTransformScreenSpaceTex(uv + d.zw)));

        return s * (1.0 / 4.0);
    }

    #include "../ShaderLibrary/CustomTonemapping.hlsl"

    TEXTURE2D_SAMPLER2D(_MainTex, sampler_MainTex);
    TEXTURE2D_SAMPLER2D(_BloomTex, sampler_BloomTex);
    TEXTURE2D_SAMPLER2D(_GlobalIntensityTex, sampler_GlobalIntensityTex);

    // Per-blit texel size (xy = 1/size, zw = size), set by BloomRenderer so each
    // pyramid level samples at its own resolution (Graphics.Blit does not update
    // _MainTex_TexelSize for intermediate render textures).
    float4 _BloomTexelSize;
    float _SampleScale;
    float _Intensity;
    float _BloomThreshold;
    // PPv2 Uber _ChromaticAberration_Amount = intensity * 0.05, set by BloomRenderer.
    float _ChromaticAberration;
    // Game _BloomParams (PyramidBloomRendererSO.RenderBloom): x = autoExposureLimit,
    // y = fractional pyramid LOD, z = alphaWeights, w = legacyAutoExposure flag.
    // y/z are unused by the composite; x/w drive the auto-exposure knee below.
    float4 _BloomParams;

    // Recovered game prefilter kernel (fragment-9bbb0fcf745e8647): 13-tap downsample,
    // 4 taps at +-0.5 texel x 1/8 plus 9 taps at { -1, 0, 1 }^2 with corner/cross/center
    // weights 1/32 / 2/32 / 3/32 (total 31/32). The ring weights mirror the game
    // binary's exact accumulation (center counted 3x, cross 2x, corners 1x). Works on
    // float4 so the alpha channel, the bloom mask, flows through the pyramid.
    float4 Downsample13Classic(TEXTURE2D_ARGS(tex, samplerTex), float2 uv, float2 texelSize)
    {
        float4 a0 = SAMPLE_TEXTURE2D(tex, samplerTex, UnityStereoTransformScreenSpaceTex(uv + texelSize * float2( 0.5,  0.5)));
        float4 a1 = SAMPLE_TEXTURE2D(tex, samplerTex, UnityStereoTransformScreenSpaceTex(uv + texelSize * float2(-0.5,  0.5)));
        float4 a2 = SAMPLE_TEXTURE2D(tex, samplerTex, UnityStereoTransformScreenSpaceTex(uv + texelSize * float2( 0.5, -0.5)));
        float4 a3 = SAMPLE_TEXTURE2D(tex, samplerTex, UnityStereoTransformScreenSpaceTex(uv + texelSize * float2(-0.5, -0.5)));

        float4 c0 = SAMPLE_TEXTURE2D(tex, samplerTex, UnityStereoTransformScreenSpaceTex(uv + texelSize * float2(-1, -1)));
        float4 c1 = SAMPLE_TEXTURE2D(tex, samplerTex, UnityStereoTransformScreenSpaceTex(uv + texelSize * float2( 0, -1)));
        float4 c2 = SAMPLE_TEXTURE2D(tex, samplerTex, UnityStereoTransformScreenSpaceTex(uv + texelSize * float2( 1, -1)));
        float4 c3 = SAMPLE_TEXTURE2D(tex, samplerTex, UnityStereoTransformScreenSpaceTex(uv + texelSize * float2(-1,  0)));
        float4 c4 = SAMPLE_TEXTURE2D(tex, samplerTex, UnityStereoTransformScreenSpaceTex(uv));
        float4 c5 = SAMPLE_TEXTURE2D(tex, samplerTex, UnityStereoTransformScreenSpaceTex(uv + texelSize * float2( 1,  0)));
        float4 c6 = SAMPLE_TEXTURE2D(tex, samplerTex, UnityStereoTransformScreenSpaceTex(uv + texelSize * float2(-1,  1)));
        float4 c7 = SAMPLE_TEXTURE2D(tex, samplerTex, UnityStereoTransformScreenSpaceTex(uv + texelSize * float2( 0,  1)));
        float4 c8 = SAMPLE_TEXTURE2D(tex, samplerTex, UnityStereoTransformScreenSpaceTex(uv + texelSize * float2( 1,  1)));

        return (a0 + a1 + a2 + a3) * 0.125
             + (c0 + c2 + c6 + c8) * 0.03125
             + (c1 + c3 + c5 + c7) * 0.0625
             + c4 * 0.09375;
    }

    float4 FragPrefilter(VaryingsDefault i) : SV_Target
    {
        // Recovered game prefilter: 13-tap downsample, then the alpha-driven gate
        // rgb *= saturate(alpha * k) with k = _BloomThreshold (game cb0[103].z).
        // The alpha channel is the bloom mask: the game's Deferred route writes
        // alpha = a * bloomMultiplier, so pixels with alpha 0 never reach the bloom
        // pyramid. k defaults to 1, saturate(a) = a for a <= 1, which matches the
        // previous premultiply behaviour.
        float4 color = Downsample13Classic(
            TEXTURE2D_PARAM(_MainTex, sampler_MainTex), i.texcoord,
            _BloomTexelSize.xy);
        color.rgb *= saturate(color.a * _BloomThreshold);
        return color;
    }

    float4 FragDownsample13(VaryingsDefault i) : SV_Target
    {
        float4 color = DownsampleBox13Tap(
            TEXTURE2D_PARAM(_MainTex, sampler_MainTex), i.texcoord,
            _BloomTexelSize.xy);
        return color;
    }

    float4 FragDownsample4(VaryingsDefault i) : SV_Target
    {
        float4 color = DownsampleBox4Tap(
            TEXTURE2D_PARAM(_MainTex, sampler_MainTex), i.texcoord,
            _BloomTexelSize.xy);
        return color;
    }

    float4 Combine(float4 bloom, float2 uv)
    {
        float4 color = SAMPLE_TEXTURE2D(_BloomTex, sampler_BloomTex, uv);
        return bloom + color;
    }

    float4 FragUpsampleTent(VaryingsDefault i) : SV_Target
    {
        float4 bloom = UpsampleTent(
            TEXTURE2D_PARAM(_MainTex, sampler_MainTex), i.texcoord, _BloomTexelSize.xy,
            _SampleScale);
        return Combine(bloom, i.texcoordStereo);
    }

    float4 FragUpsampleBox(VaryingsDefault i) : SV_Target
    {
        float4 bloom = UpsampleBox(
            TEXTURE2D_PARAM(_MainTex, sampler_MainTex), i.texcoord, _BloomTexelSize.xy,
            _SampleScale);
        return Combine(bloom, i.texcoordStereo);
    }

    float4 FragComposite(VaryingsDefault i) : SV_Target
    {
        float4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord);

        // Give whiteness to glowing material, and lets other lights light material show through blooms.
        float alpha = saturate(color.a);
        float4 invert = 1 - color;
        color = alpha * invert + color;

        // Recovered game combine (fragment-47497f82473c772f): scale the bloom by the
        // auto-exposure knee, then run it through the ACES curve (2.51/0.03/2.43/0.59/0.14,
        // the same constants as ApplyAcesTonemapping) before adding it to the scene.
        // The game selects between two knees with the runtime cbuffer flag cb0[103].w
        // (not a keyword), fed per-frame from _BloomParams.w = legacyAutoExposure:
        //   legacy (w > 0): min(luma * limit, 0.1 / sqrt(luma))   luma-proportional
        //   default (w = 0): min(limit * 0.004, 0.1 / sqrt(luma)) fixed fraction
        // with limit = _BloomParams.x = autoExposureLimit and luma = Rec601 luma
        // (0.3/0.59/0.11) of the per-frame 1x1 probe _GlobalIntensityTex, sampled at
        // (0.5, 0.5) exactly like the game. The probe is the top mip of the bloom
        // pyramid, bound by BloomRenderer (game: cmd.SetGlobalTexture on the
        // smallest pyramid level). _Intensity is ChroMapper's master scale on top.
        float4 bloom = SAMPLE_TEXTURE2D(_BloomTex, sampler_BloomTex, i.texcoord);
        float luma = dot(
            SAMPLE_TEXTURE2D(_GlobalIntensityTex, sampler_GlobalIntensityTex, float2(0.5, 0.5)).rgb,
            float3(0.3, 0.59, 0.11));
        float cap = 0.1 / sqrt(max(luma, 1e-5));
        float knee = _BloomParams.w > 0.0
            ? min(luma * _BloomParams.x, cap)
            : min(_BloomParams.x * 0.004, cap);
        bloom = ApplyAcesTonemapping(bloom * knee * _Intensity);
        color.rgb += bloom.rgb;
        color.rgb = saturate(color.rgb);

        return color;
    }

    // Bilinear sample of the PPv2 default 3x1 spectral LUT (R, G, B texels,
    // TextureWrapMode.Clamp) at uv.x = t, matching the hardware filtering of
    // the texture ChromaticAberrationRenderer builds.
    float3 SpectralLut(float t)
    {
        float x = t * 3.0 - 0.5;
        float3 r = float3(1.0, 0.0, 0.0);
        float3 g = float3(0.0, 1.0, 0.0);
        float3 b = float3(0.0, 0.0, 1.0);
        if (x <= 0.0) return r;
        if (x < 1.0) return lerp(r, g, x);
        if (x < 2.0) return lerp(g, b, x - 1.0);
        return b;
    }

    float4 FragChromaticAberration(VaryingsDefault i) : SV_Target
    {
        // PPv2 Uber pass (CHROMATIC_ABERRATION): sample the source along the path
        // from uv to the radial "end" point, weighting each sample by the spectral
        // lookup. _ChromaticAberration is intensity * 0.05, set by BloomRenderer;
        // the sample count is distance-driven, clamped to [3, 16] like the game.
        float2 uv = i.texcoord;
        float2 coords = 2.0 * uv - 1.0;
        float2 end = uv - coords * dot(coords, coords) * _ChromaticAberration;

        float2 diff = end - uv;
        int samples = clamp(int(length(_BloomTexelSize.zw * diff / 2.0)), 3, 16);
        float2 delta = diff / samples;
        float2 pos = uv;
        float4 sum = 0.0;
        float4 filterSum = 0.0;

        for (int s = 0; s < samples; s++)
        {
            float t = (s + 0.5) / samples;
            float4 texel = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, UnityStereoTransformScreenSpaceTex(pos));
            float4 filter = float4(SpectralLut(t), 1.0);
            sum += texel * filter;
            filterSum += filter;
            pos += delta;
        }

        return sum / filterSum;
    }

    float4 Frag(VaryingsDefault i) : SV_Target
    {
        float4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord);
        return color;
    }
    ENDHLSL

    SubShader
    {
        Cull Off ZWrite Off ZTest Always

        // 0 prefilter
        Pass
        {
            HLSLPROGRAM
            #pragma vertex VertDefault
            #pragma fragment FragPrefilter
            ENDHLSL
        }
        // 1 downsample 13-tap
        Pass
        {
            HLSLPROGRAM
            #pragma vertex VertDefault
            #pragma fragment FragDownsample13
            ENDHLSL
        }
        // 2 downsample 4-tap
        Pass
        {
            HLSLPROGRAM
            #pragma vertex VertDefault
            #pragma fragment FragDownsample4
            ENDHLSL
        }
        // 3 upsample tent
        Pass
        {
            HLSLPROGRAM
            #pragma vertex VertDefault
            #pragma fragment FragUpsampleTent
            ENDHLSL
        }
        // 4 upsample box
        Pass
        {
            HLSLPROGRAM
            #pragma vertex VertDefault
            #pragma fragment FragUpsampleBox
            ENDHLSL
        }
        // 5 composite
        Pass
        {
            HLSLPROGRAM
            #pragma vertex VertDefault
            #pragma fragment FragComposite
            ENDHLSL
        }
        // 6 chromatic aberration
        Pass
        {
            HLSLPROGRAM
            #pragma vertex VertDefault
            #pragma fragment FragChromaticAberration
            ENDHLSL
        }
        // 7 debug
        Pass
        {
            HLSLPROGRAM
            #pragma vertex VertDefault
            #pragma fragment Frag
            ENDHLSL
        }
    }
}
