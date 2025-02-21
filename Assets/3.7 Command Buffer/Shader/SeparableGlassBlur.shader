Shader "Unlit/SeparableGlassBlur"
{
    Properties
    {
        _MainTex ("Base(RGB)", 2D) = "" {}
    }

    CGINCLUDE
    #include "UnityCG.cginc"

    struct v2f
    {
        float4 vertex : SV_POSITION;
        float2 uv : TEXCOORD0;
        float4 uv01 : TEXCOORD1;
        float4 uv23 : TEXCOORD2;
        float4 uv45 : TEXCOORD3;
    };

    float4 offsets;  //从外部传入，制定模糊的半径和方向

    sampler2D _MainTex;

    v2f vert (appdata_img v)
    {
        v2f o;
        o.vertex = UnityObjectToClipPos(v.vertex);
        o.uv.xy = v.texcoord.xy;

        //计算上下左右用于模糊采样的UV值
        o.uv01 = v.texcoord.xyxy + offsets.xyxy * float4(1, 1, -1, -1);
        o.uv23 = v.texcoord.xyxy + offsets.xyxy * float4(1, 1, -1, -1) * 2.0;
        o.uv45 = v.texcoord.xyxy + offsets.xyxy * float4(1, 1, -1, -1) * 3.0;

        return o;
    }

    fixed4 frag (v2f i) : COLOR
    {
        fixed4 col = float4 (0, 0, 0, 0);

        // 使用加权平均, 不同距离给不同权重
        col += 0.40 * tex2D (_MainTex, i.uv);
        col += 0.15 * tex2D (_MainTex, i.uv01.xy);
        col += 0.15 * tex2D (_MainTex, i.uv01.zw);
        col += 0.10 * tex2D (_MainTex, i.uv23.xy);
        col += 0.10 * tex2D (_MainTex, i.uv23.zw);
        col += 0.05 * tex2D (_MainTex, i.uv45.xy);
        col += 0.05 * tex2D (_MainTex, i.uv45.zw);

        return col;
    }
    ENDCG

    SubShader
    {
        Pass
        {
            ZTest Always Cull Off
            ZWrite Off
            Fog { Mode off }
            
            CGPROGRAM
            #pragma fragmentoption ARB_precision_hint_fastest
            #pragma vertex vert
            #pragma fragment frag
            ENDCG
        }
    }
    FallBack off
}
