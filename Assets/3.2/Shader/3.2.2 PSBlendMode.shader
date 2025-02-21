Shader "Unlit/PSBlendMode"
{
    Properties
    {
        // IntRange只能是整数数值
        [IntRange]_ModeID ("Mode ID", Range(0.0, 26.0)) = 0.0
        [Header(A is Dst Texture)]
        [Space(10)]
        _Color1         ("TextureColor_A", Color)   = (1.0, 1.0, 1.0, 0.5)
        _MainTex1       ("Texture_A", 2D)           = "white" {}
        [Space(100)]

        [Header(B is Src Texture)]
        _Color2         ("TextureColor_B", Color)   = (1.0, 1.0, 1.0, 0.5)
        _MainTex2       ("Texture_B", 2D)           = "white" {}

        [HideInInspector]_IDChoose ("", Float)      = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        ZWrite On
        Blend One Zero  // Normal
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "./Include/PSBlendMode.cginc"

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

            uniform float _ModeID;
            uniform float4 _Color1;
            uniform float4 _Color2;
            uniform sampler2D _MainTex1; uniform float4 _MainTex1_ST;
            uniform sampler2D _MainTex2;


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex1);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 D = tex2D(_MainTex1, i.uv) * _Color1;
                fixed4 S = tex2D(_MainTex2, i.uv) * _Color2;
                float4 result = float4(OutPutMode(S, D, _ModeID), 1.0);
                // 如果模式 ID 不是 1，则使用 Alphablend 混合 RGB 值，并保持 Alpha 通道
                if(_ModeID != 1)
                {
                    result.rgb = Alphablend(result, D);
                }
                return result;
            }
            ENDCG
        }
    }
    CustomEditor "PSModeGUI"
}
