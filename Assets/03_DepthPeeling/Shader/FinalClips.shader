Shader "Unlit/FinalClips"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
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
            // ������һ�� 2D �������� ���ڴ洢���ͼ�����ݡ�
            UNITY_DECLARE_TEX2DARRAY(FinalClips);

            sampler2D _MainTex; float4 _MainTex_ST;
            uniform int DepthRenderedIndex;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = 0; //����
                fixed4 top = 0; //��ǰ
                // ѭ��������ͼ��, ����Զ����ȿ�ʼ��
                for(int k = 0; k < DepthRenderedIndex + 1; k++)
                {
                    fixed4 front = UNITY_SAMPLE_TEX2DARRAY(FinalClips, float3(i.uv, DepthRenderedIndex - k));
                    col.rgb = col.rgb * (1 - front.a) + front.rgb * front.a;    //����ɫ���м�Ȩƽ�������ǵ�ǰͼ���͸����
                    col.a = 1 - (1 - col.a) * (1 - front.a);    //���͸���ȣ��������ǵ�ǰ��ɫ�͵�ǰͼ��͸���ȵļ�Ȩƽ��
                    top = col;
                }
                col.a = saturate(col.a);
                // ���������ͼ�㣬����㲹�� ����ڰߣ����Բ��ã�
                col.rgb = col.rgb + top.rgb * (1 - col.a);

                return col;
            }
            ENDCG
        }
    }
}
