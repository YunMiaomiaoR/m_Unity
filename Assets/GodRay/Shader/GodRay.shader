Shader "PostEffect/GodRay"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BlurTex ("Blur",2D)     = "white" {}
    }

    CGINCLUDE
    // 径向采样次数
    #define RADIAL_SAMPLE_COUNT 6
    #include "UnityCG.cginc"

    // 提取亮部图像
    struct v2fExtractBright
    {
        float4 vertex : SV_POSITION;
        float2 uv     : TEXCOORD0;
    };

    // 径向模糊
    struct v2fRadialBlur
    {
        float4 vertex     : SV_POSITION;
        float2 uv         : TEXCOORD0;
        float2 blurOffset : TEXCOORD1;
    };

    // 混合
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

    // 提取亮部图像
    v2fExtractBright vertExtractBright (appdata_img v)
    {
        v2fExtractBright o;
        o.vertex = UnityObjectToClipPos(v.vertex);
        o.uv = v.texcoord.xy;
        // 平台差异化处理
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

         // 仅当color大于设置的阈值的时候才输出
         float4 thresholdColor = saturate(col - _ColorThreshold) * distanceControl;
         float luminanceColor = Luminance(thresholdColor.rgb);  // Luminance是内置函数
         luminanceColor = pow(luminanceColor, _PowFactor);
         return luminanceColor;
         //return fixed4(luminanceColor, luminanceColor, luminanceColor, 1);
    }


    // 径向模糊
    v2fRadialBlur vertRadialBlur(appdata_img v)
    {
        v2fRadialBlur o;
        o.vertex = UnityObjectToClipPos(v.vertex);
        o.uv = v.texcoord.xy;
        // 径向模糊采样偏移值 * 沿光方向权重
        o.blurOffset = _offsets * (_ViewProtLightPos.xy - o.uv);
        return o;
    }

    fixed4 fragRadialBlur(v2fRadialBlur i) : SV_Target
    {
        half4 color = half4(0, 0, 0, 0);
        // 迭代将采样得到的RGB累加
        for(int j = 0; j < RADIAL_SAMPLE_COUNT; j++)
        {
            color += tex2D(_MainTex, i.uv);
            i.uv.xy += i.blurOffset;
        }
        // 最后除以迭代次数
        return color / RADIAL_SAMPLE_COUNT;
    }


    // 混合
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

        // 提取亮部
        Pass
        {
            CGPROGRAM
            #pragma vertex vertExtractBright
            #pragma fragment fragExtractBright
            ENDCG
        }

        // 径向模糊
        Pass
        {
            CGPROGRAM
            #pragma vertex vertRadialBlur
            #pragma fragment fragRadialBlur
            ENDCG
        }

        // 混合
        Pass
        {
            CGPROGRAM
            #pragma vertex vertGodRay
            #pragma fragment fragGodRay
            ENDCG
        }
    }
}
