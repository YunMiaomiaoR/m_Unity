Shader "Hidden/ConstraintDepth_Opaque"
{
    Properties
    {
        _MainTex ("Diffuse(RGB) Alpha(A)", 2D)      = "white" {}
        _Color   ("Diffuse Color", Color)           = (1, 1, 1, 1)
        _Cutoff  ("Alpha Cut-off Threshold", Range(0.1, 1.0)) = 0.7
    }
    SubShader
    {
        Tags { "RenderType"="TransparentCutout" "Queue" = "AlphaTest" }
        Blend Off
        Cull Off
        ZWrite On
        Colormask 0

        Pass
        {
        Name "OPAQUE"
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

            sampler2D _MainTex; float4 _MainTex_ST;
            half4 _Color;
            float _Cutoff;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 a = tex2D(_MainTex, i.uv).a * _Color.a;
                clip(a - _Cutoff);
                return 0;
            }
            ENDCG
        }
    }
}
