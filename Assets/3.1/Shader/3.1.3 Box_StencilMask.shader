Shader "Unlit/3.1.3 Box_StencilMask"
{
    Properties
    {
        _Color   ("Color", Color) = (0, 0, 0, 0)
        _SRef    ("Stencil Ref", Int) = 1
        [Enum(UnityEngine.Rendering.CompareFunction)]   _SComp  ("Stencil Comp", Float) = 8
        [Enum(UnityEngine.Rendering.StencilOp)]         _SOp    ("Stencil Op", Float)   = 2
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue" = "Geometry+1" }
        ZWrite off
        ColorMask 0

        Stencil{
            Ref  [_SRef]
            Comp [_SComp]
            Pass [_SOp]
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            half4 _Color;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv) * _Color;
                return col;
            }
            ENDCG
        }
    }
}
