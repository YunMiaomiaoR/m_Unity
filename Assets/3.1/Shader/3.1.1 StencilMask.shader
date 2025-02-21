Shader "Unlit/3.1.1 StencilMask"
{
    Properties
    {
        _ID("Mask ID", int) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue" = "Geometry+1" }    // ��Ⱦ����
        ColorMask 0 // RGBA\RGB\R\G\B\0  0��ʾʲô�������
        ZWrite off
        Stencil
        {
            // ǰ����stencilֵ��ID���бȽ�
            Ref[_ID]
            //��������
            Comp always // Ĭ��always
            //�������ͨ���Դ�stencilֵ���е�д����������ֵ�ǰstencilֵ
            Pass replace // Ĭ��keep
            //�������ʧ�ܶԴ�stencilֵ���е�д����������ֵ�ǰstencilֵ
            // Fail keep
            //�����Ȳ���ʧ�ܶԴ�stencilֵ���е�д����������ֵ�ǰstencilֵ
            // ZFail keep
            // ��д����Ĭ��
        }

        Pass
        {
            CGINCLUDE

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                return o;
            }


            fixed4 frag (v2f i) : SV_Target
            {
                return half4(1, 1, 1, 1);
            }
            ENDCG
        }
    }
}
