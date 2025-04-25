
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
            float4    _CurrentRT_TexelSize; // 贴图大小信息
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
                // 最小偏移单位
                float3 offset = float3(_CurrentRT_TexelSize.xy, 0);
                float2 uv = i.uv;
                // 获取 上下左右 值
                float p0 = tex2D(_CurrentRT, uv + offset.zy).x; // 上
                float p1 = tex2D(_CurrentRT, uv - offset.zy).x; // 下
                float p2 = tex2D(_CurrentRT, uv - offset.xz).x; // 左
                float p3 = tex2D(_CurrentRT, uv + offset.xz).x; // 右
                // 上一帧的中心值
                float p00 = tex2D(_PreRT, uv).x;
                // 散开：当前帧上下左右四个像素值的和除2，减去上一帧像素的值
                float disp = (p0 + p1 + p2 + p3) / 2 - p00;
                // 加衰减
                disp *= 0.99;
                //disp *= 1 - pow(0.1, _DispPow);
    
                return float4(disp,0,0,1);
            }
            ENDCG
        }
    }
}
