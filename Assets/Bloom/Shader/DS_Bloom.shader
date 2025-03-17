Shader "Unlit/DS_Bloom"
{
    Properties
    {
        // ��������C#�ű��еĶ�Ӧ
        _MainTex            ("Texture", 2D)                 = "white" {}
[HideInInspector] _Bloom    ("Bloom(RGB)", 2D)              = "black" {} //��˹ģ����Ľ��
        _LuminanceThreshold ("Luminance Threshold", Float)  = 0.5 //��ֵ
        _BlurSize           ("Blur Size", Float)            = 1.0 //ģ���뾶
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        ZTest Always
        Cull Off

        CGINCLUDE
        #include "UnityCG.cginc"

        sampler2D _MainTex; float4 _MainTex_ST;
        half4     _MainTex_TexelSize;
        sampler2D _Bloom;
        float     _LuminanceThreshold;
        float     _BlurSize;

        // ---- ��һ��Passʹ�� ----
        // ����ṹ
        struct v2fExtractBright
        {
            float4 pos : SV_POSITION;
            float2 uv  : TEXCOORD0;
        };

        // ������ɫ��
        v2fExtractBright vertExtractBright (appdata_img v)
        {
            v2fExtractBright o;
            o.pos = UnityObjectToClipPos(v.vertex);
            o.uv = v.texcoord;
            return o;
        }

        // �����ȹ�ʽ
        fixed luminance(fixed4 color)
        {
            // ��������ֵ
            return 0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b;
        }

        // ƬԪ��ɫ�� -- ��ȡ��������
        fixed4 fragExtractBright (v2fExtractBright i) : SV_Target
        {
            fixed4 col = tex2D(_MainTex, i.uv);
            // ����luminance�õ����������ص�����ֵ���ټ�ȥ��ֵ
			// ʹ��clamp�����������ȡ��[0,1]��Χ��
            fixed value = clamp(luminance(col) - _LuminanceThreshold, 0.0, 1.0);
            // ��val��ԭ��ͼ�����õ�������ֵ��ˣ��õ���ȡ�����������
            return col * value;
        }

        // ---- ��2��3��Passʹ�� ----
        struct v2fBlur
        {
            float4 pos   : SV_POSITION;
            float2 uv[5] : TEXCOORD0;
			// �˴�����5ά������������5����������
        	// ���ھ���˴�СΪ5x5�Ķ�ά��˹�˿��Բ��������СΪ5��һά��˹��
        	// uv[0]�洢�˵�ǰ�Ĳ�������
        	// uv[1][2][3][4]Ϊ��˹ģ���ж��������ʱʹ�õ���������        
        };

        // ������ɫ�� -- ��ֱ����ģ��
        v2fBlur vertBlurVertical(appdata_img v)
        {
            v2fBlur o;
            o.pos = UnityObjectToClipPos(v.vertex);
            half2 uv = v.texcoord;
            o.uv[0] = uv;
            //uv[0]���ǣ�0,0��

        	//����ֱ�������ģ��
            //uv[1]������Ų��1����λ(0, 1)
        	//uv[2]������Ų��1����λ(0, -1)
        	//uv[3]������Ų��2����λ(0, 2)
        	//uv[4]������Ų��2����λ(0, -2)
            o.uv[1] = uv + float2(0.0, _MainTex_TexelSize.y * 1.0) * _BlurSize;
            o.uv[2] = uv - float2(0.0, _MainTex_TexelSize.y * 1.0) * _BlurSize;
            o.uv[3] = uv + float2(0.0, _MainTex_TexelSize.y * 2.0) * _BlurSize;
            o.uv[4] = uv - float2(0.0, _MainTex_TexelSize.y * 2.0) * _BlurSize;

            return o;
        }

        // ������ɫ�� -- ˮƽ����ģ��
        v2fBlur vertBlurHorizontal(appdata_img v)
        {
            v2fBlur o;
            o.pos = UnityObjectToClipPos(v.vertex);
            half2 uv = v.texcoord;
            o.uv[0] = uv;
            //uv[0]���ǣ�0,0��

        	//����ֱ�������ģ������Ӧ(1, 0)��(-1, 0)��(2, 0)��(-2, 0)
            o.uv[1] = uv + float2(_MainTex_TexelSize.y * 1.0, 0.0) * _BlurSize;
            o.uv[2] = uv - float2(_MainTex_TexelSize.y * 1.0, 0.0) * _BlurSize;
            o.uv[3] = uv + float2(_MainTex_TexelSize.y * 2.0, 0.0) * _BlurSize;
            o.uv[4] = uv - float2(_MainTex_TexelSize.y * 2.0, 0.0) * _BlurSize;

            return o;
        }

        // ƬԪ��ɫ�� -- ��˹ģ��
        fixed4 fragBlur(v2fBlur i) : SV_Target
        {
            // ��Ϊ��ά��˹�˾��пɷ����ԣ�������õ���һά��˹�˾��жԳ���, ����ֻ��Ҫ��������������˹Ȩ�ؼ���
            float weight[3] = {0.4026, 0.2442, 0.0545};
            // sum��ʼ��Ϊ��ǰ�����س�������Ӧ��Ȩ��ֵ(�˲���Ľ��)
            fixed3 sum = tex2D(_MainTex, i.uv[0]).rgb * weight[0];
            // ���о�����㣬���ݶԳ����������ѭ��
				// ��һ��ѭ������ڶ����͵����������ڵĽ��
				// �ڶ���ѭ��������ĸ��͵���������ڵĽ��
            for (int it = 1; it < 3; it++)
            {
                sum += tex2D(_MainTex, i.uv[it*2-1]).rgb * weight[it];
                sum += tex2D(_MainTex, i.uv[it*2]).rgb * weight[it];
            }
            return fixed4(sum, 1.0);
        }

        // ---- ���ĸ�Passʹ�� ----
        // ����ṹ ���� �������ͼ��
        struct v2fBloom
        {
            float4 pos : SV_POSITION;
            float4 uv  : TEXCOORD0;
        };
        
        // ������ɫ��
        v2fBloom vertBloom (appdata_img v)
        {
            v2fBloom o;
            o.pos = UnityObjectToClipPos(v.vertex);
            o.uv.xy = v.texcoord;   //xy����Ϊ_MainTex����������
            o.uv.zw = v.texcoord;   //zw����Ϊ_Bloom����������
            // ƽ̨���컯����
            #if UNITY_UV_STARTS_AT_TOP
            if (_MainTex_TexelSize.y < 0.0)
                o.uv.w = 1.0 - o.uv.w;
            #endif
            return o;
        }

        fixed4 fragBloom(v2fBloom i) : SV_Target
        {
            return tex2D(_MainTex, i.uv.xy) + tex2D(_Bloom, i.uv.zw);
        }
        ENDCG
        
        // ---- ��һ��Pass����ȡ�������� ----
        Pass
        {
            CGPROGRAM
            #pragma vertex vertExtractBright
            #pragma fragment fragExtractBright
            ENDCG
        }

        // ---- �ڶ���Pass����ֱģ�� ----
        Pass
        {
            CGPROGRAM
            #pragma vertex vertBlurVertical
            #pragma fragment fragBlur
            ENDCG
        }

        // ---- ������Pass��ˮƽģ�� ----
        Pass
        {
            CGPROGRAM
            #pragma vertex vertBlurHorizontal
            #pragma fragment fragBlur
            ENDCG
        }

        // ---- ���ĸ�Pass��������� ----
        Pass
        {
            CGPROGRAM
            #pragma vertex vertBloom
            #pragma fragment fragBloom
            ENDCG
        }
    }
    FallBack Off
}