Shader "Unlit/ddx&ddy/EdgeAdj"
{
    Properties
    {
        // UIѡ�
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
            // ���ر���
            #pragma multi_compile _EADJ_INCREASEEDGEADJ _EADJ_BRIGHTEDGEADJ

            #include "UnityCG.cginc"

            // �������
            sampler2D   _MainTex;
            float4      _MainTex_ST;
            float       _Intensity;

            // ����ṹ
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };
            // ����ṹ
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            // ����Shader
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }
            // ����Shader
            // float f : VFACE����˫����Ⱦ
            fixed4 frag (v2f i, float f : VFACE) : SV_Target
            {
                // ���治͸����1�����治͸����0.5
                fixed a = 1;
                if (f < 0) 
                    a = 0.5;
                fixed3 col = tex2D(_MainTex, i.uv).rgb;
                
                // ��Ե���������ӱ�Ե�������
                /* ��������3x3�ľ���˴���
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
                //ʹ��(ddx(c) + ddy(c))��û�о���ֵ�����ñ�Ե���������Ȳ����󣬼�����ǿ��Եͻ��
                col += (ddx(col) + ddy(col)) * _Intensity;
                // ��Ե���������ӱ�Ե���ȵ���
                // _EADJ_BRIGHTEDGEADJ
                #elif _EADJ_BRIGHTEDGEADJ
                col += fwidth(col) * _Intensity;    // fwidth �� abs(ddx(col)) + abs(ddy(col))
                #endif

                return fixed4(col, a);
            }
            ENDCG
        }
    }
}
