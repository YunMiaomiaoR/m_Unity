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
            // 声明了一个 2D 纹理数组 用于存储多层图像数据。
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
                fixed4 col = 0; //最终
                fixed4 top = 0; //当前
                // 循环处理多个图层, 从最远的深度开始，
                for(int k = 0; k < DepthRenderedIndex + 1; k++)
                {
                    fixed4 front = UNITY_SAMPLE_TEX2DARRAY(FinalClips, float3(i.uv, DepthRenderedIndex - k));
                    col.rgb = col.rgb * (1 - front.a) + front.rgb * front.a;    //对颜色进行加权平均，考虑当前图层的透明度
                    col.a = 1 - (1 - col.a) * (1 - front.a);    //混合透明度，计算结果是当前颜色和当前图层透明度的加权平均
                    top = col;
                }
                col.a = saturate(col.a);
                // 被最后丢弃的图层，最外层补上 避免黑斑（可以不用）
                col.rgb = col.rgb + top.rgb * (1 - col.a);

                return col;
            }
            ENDCG
        }
    }
}
