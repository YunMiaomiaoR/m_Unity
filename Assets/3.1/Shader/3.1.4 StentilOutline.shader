Shader "Unlit/3.1.4StentilOutline"
{
    Properties
    {
        _MainTex        ("Texture", 2D)                     = "white" {}
        _OutlineWidth   ("Outline Width", Range(0.0, 1.0))  = 0.5
        _OutlineCol     ("Outline Color", Color)            = (1.0, 1.0, 1.0, 1.0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Stencil{
            Ref 0
            Comp Equal
            Pass IncrSat    //Pass渲染完后 对参考值+1
            Fail keep
            ZFail keep
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #pragma target 3.0

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

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                return col;
            }
            ENDCG
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
                float4 normal : NORMAL;
                float2 uv     : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv0    : TEXCOORD0;
            };

            fixed _OutlineWidth;
            half4 _OutlineCol;

            v2f vert (appdata v)
            {
                v2f o;
                // 上一个pass渲染过的像素stencil值已经变为1，无法通过Ref 0+Comp Equal测试，那么现在只会在放大后的stencil值仍然为0的区域进行渲染。
                o.vertex = v.vertex + normalize(v.normal) * _OutlineWidth * 0.01;
                o.vertex = UnityObjectToClipPos(o.vertex);
                o.uv0 = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return _OutlineCol;
            }
            ENDCG
        }
    }
}
