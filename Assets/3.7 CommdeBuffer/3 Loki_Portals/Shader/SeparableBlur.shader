Shader "Hidden/SeparableGlassBlur"
{
    Properties
    {
        _MainTex ("Base(RGB)", 2D) = "" {}
    }

    CGINCLUDE
        #include "UnityCG.cginc"
       
        struct v2f
        {
            float4 vertex : POSITION;
            float2 uv : TEXCOORD0;

            float4 uv01 : TEXCOORD1;
            float4 uv23 : TEXCOORD2;
            float4 uv45 : TEXCOORD3;
        };

        float4 offsets;
        sampler2D _MainTex;

        // 偏移顶点uv，使其读取到周围颜色进行混合
        v2f vert (appdata_img v)
        {
            v2f o;
            o.vertex = UnityObjectToClipPos(v.vertex);

            o.uv.xy = v.texcoord.xy;

            o.uv01 = v.texcoord.xyxy + offsets.xyxy * float4(1, 1, -1, -1);
            o.uv23 = v.texcoord.xyxy + offsets.xyxy * float4(1, 1, -1, -1) * 2.0;
            o.uv45 = v.texcoord.xyxy + offsets.xyxy * float4(1, 1, -1, -1) * 3.0;

            return o;
        }

        fixed4 frag (v2f i) : COLOR
        {
            fixed4 col = fixed4 (0, 0, 0, 0);

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
            ZTest Always 
            Cull Off 
            ZWrite Off

            CGPROGRAM
            //在处理片段着色器运算时，编译器将优先选择执行速度最快的精度级别，而不是最精确的计算。
            #pragma fragmentoption ARB_percision_hint_fastest
            #pragma vertex vert
            #pragma fragment frag
            ENDCG
        }
    }
    FallBack off
}
