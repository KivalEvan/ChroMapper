// ChroMapper/Set Depth Only
// Replacement for the Beat Saber game shader Custom/SetDepthOnly.
// Vertex: standard object-to-clip transform, passes through the saturated
// vertex color (the game reads the mesh color via TEXCOORD0 and saturates it
// in the vertex stage with mov_sat).
// Fragment: passes the interpolated color straight through (o0 = v0).
// The pass exists to stamp the stencil buffer (and occupy depth) for geometry
// that will be redrawn by a stencil-tested pass (e.g. portals); the color
// output is the saturated vertex color.
// Render state recovered from game material dumps (1.44.3): Stencil Comp 8
// (Always), Pass 2 (Replace), StencilRef per material (1), ZWrite off.
Shader "ChroMapper/Set Depth Only" {
    Properties {
        _StencilRefValue ("Stencil Ref Value", Float) = 1
        [Enum(UnityEngine.Rendering.CompareFunction)] _StencilComp ("Stencil Comp Func", Float) = 8
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilPass ("Stencil Pass Op", Float) = 2
    }
    SubShader {
        Tags {
            "Queue" = "Geometry-1"
            "RenderType" = "Opaque"
        }
        Pass {
            Name ""
            Blend Zero One, Zero One
            ZClip On
            ZWrite Off
            Cull Off

            Stencil {
                Ref [_StencilRefValue]
                Comp [_StencilComp]
                Pass [_StencilPass]
            }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            #pragma multi_compile _ STEREO_INSTANCING_ON

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float4 color : COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 color : TEXCOORD0;
                float4 position : SV_POSITION;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert(appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.position = UnityObjectToClipPos(v.vertex);
                o.color = saturate(v.color);
                return o;
            }

            fixed4 frag(v2f inp) : SV_Target
            {
                return inp.color;
            }
            ENDCG
        }
    }
}
