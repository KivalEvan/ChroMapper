Shader "Hidden/MainEffect"
{
    Properties
    {
        [HideInInspector] _MainTex ("Main Texture", 2D) = "white" {}
        _BloomIntensity ("Bloom Intensity", Float) = 1
        _Fade ("Fade", Float) = 1
    }

    HLSLINCLUDE

    #include "UnityCG.cginc"
    #include "../ShaderLibrary/CustomBloom.hlsl"

    struct VaryingsDefault
    {
        float4 vertex : SV_POSITION;
        float2 texcoord : TEXCOORD0;
    };

    VaryingsDefault VertDefault(appdata_img input)
    {
        VaryingsDefault output;
        output.vertex = UnityObjectToClipPos(input.vertex);
        output.texcoord = input.texcoord;
        return output;
    }

    Texture2D _MainTex;
    SamplerState sampler_MainTex;
    Texture2D _MainEffectBloomTexture;
    SamplerState sampler_MainEffectBloomTexture;
    Texture2D _GlobalBlueNoiseTex;
    SamplerState sampler_GlobalBlueNoiseTex;

    float4 _MainEffectSourceTexelSize;
    float2 _GlobalBlueNoiseParams;
    float _GlobalRandomValue;
    float _BloomIntensity;
    float _Fade;
    float4 FragMainEffect(VaryingsDefault input) : SV_Target
    {
        float2 texelSize = _MainEffectSourceTexelSize.xy;
        float alpha = (
            _MainTex.Sample(
                sampler_MainTex, input.texcoord + texelSize * float2(-0.5, 0.5)).a +
            _MainTex.Sample(
                sampler_MainTex, input.texcoord + texelSize * float2(0.0, -0.5)).a +
            _MainTex.Sample(
                sampler_MainTex, input.texcoord + texelSize * float2(0.5, 0.5)).a +
            _MainTex.Sample(sampler_MainTex, input.texcoord).a) * 0.25;

        float4 center = _MainTex.Sample(sampler_MainTex, input.texcoord);
        float3 scene = saturate(
            center.rgb + alpha * alpha * _BaseColorBoost - _BaseColorBoostThreshold);
        float3 bloom = _MainEffectBloomTexture.Sample(
            sampler_MainEffectBloomTexture, input.texcoord).rgb * _BloomIntensity;
        float2 noiseUv = input.texcoord * _GlobalBlueNoiseParams + _GlobalRandomValue;
        float dither =
            (_GlobalBlueNoiseTex.SampleLevel(sampler_GlobalBlueNoiseTex, noiseUv, 0.0).r - 0.5) /
            255.0;

        float outputAlpha = center.a;
        #if defined(CLEAR_SCREEN_ALPHA)
        outputAlpha = 0.0;
        #endif

        return float4((scene + dither + bloom) * _Fade, outputAlpha);
    }

    ENDHLSL

    SubShader
    {
        Cull Off
        ZWrite Off
        ZTest Always

        Pass
        {
            HLSLPROGRAM
            #pragma target 3.0
            #pragma vertex VertDefault
            #pragma fragment FragMainEffect
            #pragma multi_compile_local _ CLEAR_SCREEN_ALPHA
            ENDHLSL
        }
    }
}
