Shader "Hidden/ChroMapper/Copy Camera Depth"
{
    SubShader
    {
        Cull Off
        ZWrite Off
        ZTest Always

        Pass
        {
            HLSLPROGRAM
            #pragma target 3.0
            #pragma vertex vert_img
            #pragma fragment frag
            #include "UnityCG.cginc"

            UNITY_DECLARE_DEPTH_TEXTURE(_ChroMapperActiveDepthTexture);

            float frag(v2f_img input) : SV_Target
            {
                return SAMPLE_DEPTH_TEXTURE(_ChroMapperActiveDepthTexture, input.uv);
            }
            ENDHLSL
        }
    }
}
