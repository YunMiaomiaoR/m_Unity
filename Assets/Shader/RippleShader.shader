
Shader "Unlit/RippleShader"
{
    Properties
    {
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

            sampler2D _PreRT, _CurrentRT;
            float4    _CurrentRT_TexelSize; // ��ͼ��С��Ϣ
            //float _DispPow;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // ��Сƫ�Ƶ�λ
                float3 offset = float3(_CurrentRT_TexelSize.xy, 0);
                float2 uv = i.uv;
                // ��ȡ �������� ֵ
                float p0 = tex2D(_CurrentRT, uv + offset.zy).x; // ��
                float p1 = tex2D(_CurrentRT, uv - offset.zy).x; // ��
                float p2 = tex2D(_CurrentRT, uv - offset.xz).x; // ��
                float p3 = tex2D(_CurrentRT, uv + offset.xz).x; // ��
                // ��һ֡������ֵ
                float p00 = tex2D(_PreRT, uv).x;
                // ɢ������ǰ֡���������ĸ�����ֵ�ĺͳ�2����ȥ��һ֡���ص�ֵ
                float disp = (p0 + p1 + p2 + p3) / 2 - p00;
                // ��˥��
                disp *= 0.99;
                //disp *= 1 - pow(0.1, _DispPow);
    
                return float4(disp,0,0,1);
            }
            ENDCG
        }
    }
}
