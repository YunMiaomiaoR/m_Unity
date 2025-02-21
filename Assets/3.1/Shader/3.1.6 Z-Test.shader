Shader "Unlit/3.1.6 Z-Test"
{
    Properties
    {
        _MainTex ("Texture", 2D)  = "white" {}
        _Color   ("Color", Color) = (1.0, 1.0, 1.0, 1.0)

        [Enum(Off, 0 ,On, 1)]_ZWriteMode("ZWrite Mode", Float) = 1
        [Enum(UnityEngine.Rendering.CompareFunction)]_ZComp("ZTest Comp", Float) = 4
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        ZWrite [_ZWriteMode]
        ZTest  [_ZComp]
        Cull Off
        LOD 100

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

            sampler2D _MainTex; float4 _MainTex_ST;
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
