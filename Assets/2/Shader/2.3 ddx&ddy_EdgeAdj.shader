Shader "Unlit/ddx&ddy/EdgeAdj"
{
    Properties
    {
        // UI选项卡
        [KeywordEnum(IncreaseEdgeAdj, BrightEdgeAdj)] _EADJ("Edge Adj type", Float) = 0
        _MainTex    ("Tex", 2D)             = "white"{}
        _Intensity  ("Intensity", Range(0, 20)) = 2
    }
    SubShader
    {

        Pass
        {
            Tags { "RenderType"="Opaque" }
            Cull off
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // 多重编译
            #pragma multi_compile _EADJ_INCREASEEDGEADJ _EADJ_BRIGHTEDGEADJ

            #include "UnityCG.cginc"

            // 输入参数
            sampler2D   _MainTex;
            float4      _MainTex_ST;
            float       _Intensity;

            // 输入结构
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };
            // 输出结构
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            // 顶点Shader
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }
            // 像素Shader
            // float f : VFACE开启双面渲染
            fixed4 frag (v2f i, float f : VFACE) : SV_Target
            {
                // 正面不透明度1，背面不透明度0.5
                fixed a = 1;
                if (f < 0) 
                    a = 0.5;
                fixed3 col = tex2D(_MainTex, i.uv).rgb;
                
                // 边缘调整：增加边缘差异调整
                /* 类似两个3x3的卷积核处理
                one:
                | 0| 0| 0|
                | 0|-1| 1|
                | 0| 0| 0|

                two:
                | 0| 0| 0|
                | 0|-1| 0|
                | 0| 1| 0|
                */
                #if _EADJ_INCREASEEDGEADJ
                //使用(ddx(c) + ddy(c))，没有绝对值，会让边缘的像素亮度差异变大，即：加强边缘突出
                col += (ddx(col) + ddy(col)) * _Intensity;
                // 边缘调整：增加边缘亮度调整
                // _EADJ_BRIGHTEDGEADJ
                #elif _EADJ_BRIGHTEDGEADJ
                col += fwidth(col) * _Intensity;    // fwidth 即 abs(ddx(col)) + abs(ddy(col))
                #endif

                return fixed4(col, a);
            }
            ENDCG
        }
    }
}
