Shader "PostEffect/GodRay"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BlurTex ("Blur",2D)     = "white" {}
    }

    CGINCLUDE
    // �����������
    #define RADIAL_SAMPLE_COUNT 6
    #include "UnityCG.cginc"

    // ��ȡ����ͼ��
    struct v2fExtractBright
    {
        float4 vertex : SV_POSITION;
        float2 uv     : TEXCOORD0;
    };

    // ����ģ��
    struct v2fRadialBlur
    {
        float4 vertex     : SV_POSITION;
        float2 uv         : TEXCOORD0;
        float2 blurOffset : TEXCOORD1;
    };

    // ���
    struct v2fGodRay
    {
        float4 vertex : SV_POSITION;
        float2 uv     : TEXCOORD0;
        float2 uv1    : TEXCOORD1;
    };
    
    sampler2D _MainTex; float4 _MainTex_TexelSize;
    sampler2D _BlurTex; float4 _BlurTex_TexelSize;
    float4    _ViewProtLightPos;
    float4    _offsets;
    float4    _ColorThreshold;
    float     _LightRadius;
    float     _PowFactor;
    float4    _LightColor;
    float     _LightFactor;

    // ��ȡ����ͼ��
    v2fExtractBright vertExtractBright (appdata_img v)
    {
        v2fExtractBright o;
        o.vertex = UnityObjectToClipPos(v.vertex);
        o.uv = v.texcoord.xy;
        // ƽ̨���컯����
        #if UNITY_UV_STARTS_AT_TOP
        if (_MainTex_TexelSize.y < 0)
            o.uv.y = 1 - o.uv.y;
        #endif
        return o;
    }

    fixed4 fragExtractBright (v2fExtractBright i) : SV_Target
    {
         fixed4 col = tex2D(_MainTex, i.uv);
         float distFormLight = length(_ViewProtLightPos.xy - i.uv);
         float distanceControl = saturate(_LightRadius - distFormLight);

         // ����color�������õ���ֵ��ʱ������
         float4 thresholdColor = saturate(col - _ColorThreshold) * distanceControl;
         float luminanceColor = Luminance(thresholdColor.rgb);  // Luminance�����ú���
         luminanceColor = pow(luminanceColor, _PowFactor);
         return luminanceColor;
         //return fixed4(luminanceColor, luminanceColor, luminanceColor, 1);
    }


    // ����ģ��
    v2fRadialBlur vertRadialBlur(appdata_img v)
    {
        v2fRadialBlur o;
        o.vertex = UnityObjectToClipPos(v.vertex);
        o.uv = v.texcoord.xy;
        // ����ģ������ƫ��ֵ * �عⷽ��Ȩ��
        o.blurOffset = _offsets * (_ViewProtLightPos.xy - o.uv);
        return o;
    }

    fixed4 fragRadialBlur(v2fRadialBlur i) : SV_Target
    {
        half4 color = half4(0, 0, 0, 0);
        // �����������õ���RGB�ۼ�
        for(int j = 0; j < RADIAL_SAMPLE_COUNT; j++)
        {
            color += tex2D(_MainTex, i.uv);
            i.uv.xy += i.blurOffset;
        }
        // �����Ե�������
        return color / RADIAL_SAMPLE_COUNT;
    }


    // ���
    v2fGodRay vertGodRay(appdata_img v)
    {
        v2fGodRay o;
        o.vertex = UnityObjectToClipPos(v.vertex);
        o.uv.xy = v.texcoord.xy;
        o.uv1.xy = o.uv.xy;

        #if UNITY_UV_STARTS_AT_TOP
        if (_MainTex_TexelSize.y < 0)
            o.uv.y = 1 - o.uv.y;
        #endif
        return o;
    }

    fixed4 fragGodRay(v2fGodRay i) : SV_Target
    {
        fixed4 org = tex2D(_MainTex, i.uv1);
        fixed4 blur = tex2D(_BlurTex, i.uv);
        return org + _LightFactor * blur * _LightColor;
    }
    ENDCG

    SubShader
    {
        ZTest Always
        Cull Off
        ZWrite Off

        // ��ȡ����
        Pass
        {
            CGPROGRAM
            #pragma vertex vertExtractBright
            #pragma fragment fragExtractBright
            ENDCG
        }

        // ����ģ��
        Pass
        {
            CGPROGRAM
            #pragma vertex vertRadialBlur
            #pragma fragment fragRadialBlur
            ENDCG
        }

        // ���
        Pass
        {
            CGPROGRAM
            #pragma vertex vertGodRay
            #pragma fragment fragGodRay
            ENDCG
        }
    }
}
