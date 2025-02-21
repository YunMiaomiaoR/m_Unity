Shader "Unlit/Blend"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [Enum(UnityEngine.Rendering.BlendOp)]   _BlendOp    ("BlendOp", Float)      = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend   ("SrcBlend", Float)     = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend   ("DstBlend", Float)     = 0
        [Enum(Off, 0, On, 1)]                   _ZWriteMode ("ZWriteMode", Float)   = 1
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue" = "Transparent" }
        ZWrite [_ZWriteMode]
        BlendOp [_BlendOp]
        Blend [_SrcBlend] [_DstBlend]
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

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {  
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                return col;
            }
            ENDCG
        }
    }
}
