Shader "Unlit/3.1.2 StencilMask_sky"
{
    Properties
    {
        _MainTex    ("主纹理", 2D)     = "white"{}
        _Flowmap    ("流动图", 2D)     = "white"{}
        _FlowInt    ("扰动强度", Range(0.0, 5.0))   = 1.0
        _TimeSpeed  ("全局流速", Range(0.0, 1.0))   = 1.0

        _ID         ("Mask ID", Int) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue" = "Geometry+2" }
        LOD 200
        Stencil{
            Ref [_ID]
            Comp equal
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
            // Flowmap一般不需要ST
            sampler2D _Flowmap;
            half _FlowInt;
            half _TimeSpeed;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 采样向量场信息, 将颜色值从[0, 1]映射到 方向向量[-1, 1]
                float3 flowDir = tex2D(_Flowmap, i.uv) * 2.0 - 1.0;
                // 调整采样时的UV为： adjust_uv = uv - flowDir * time
                flowDir *= -_FlowInt;

                // 构造两个波形函数
                float phase0 = frac(_Time.y * _TimeSpeed);
                float phase1 = frac(_Time.y * _TimeSpeed + 0.5);
                // 采样用的uv
                float2 tilingUV = i.uv * _MainTex_ST.xy + _MainTex_ST.zw;
                // 采样
                half3 tex0 = tex2D(_MainTex, tilingUV - flowDir.xy * phase0);
                half3 tex1 = tex2D(_MainTex, tilingUV - flowDir.xy * phase1);
                // 构造权重函数
                float flowLerp = abs(phase0 - 0.5) * 2;
                half3 finalCol = lerp(tex0, tex1, flowLerp);

                return half4 (finalCol, 1.0);
            }
            ENDCG
        }
    }
}
