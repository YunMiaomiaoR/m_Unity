Shader "Unlit/3.1.5 PolygonBeta"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

            // CGINCLUDE 用于包含一段可以在多个地方共享的代码片段, 供多个 CGPROGRAM 块或者多个 Pass 使用
            CGINCLUDE
            #include "UnityCG.cginc"
            #pragma vertex vert
            #pragma fragment frag

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

            sampler2D _MainTex; float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            ENDCG

        // 第一个pass渲染一个几何体，不论任何情况都通过测试并对它所覆盖的像素区域stencil值加1
        // 后三个pass分别只对stencil值为2，3，4的区域进行渲染。
        Pass
        {
            Stencil{
                Ref 0
                Comp always
                Pass IncrWrap
                Fail keep
                ZFail IncrWrap
            }

            CGPROGRAM
            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                return fixed4 (0.0, 0.0, 0.0, 0.0);
            }
            ENDCG
        }

        Pass
        {
            Stencil{
                Ref 2
                Comp Equal
                Pass keep
                Fail keep
                ZFail keep
            }

            CGPROGRAM
            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                return fixed4 (0.2, 0.2, 0.2, 1);
            }
            ENDCG
        }

        Pass
        {
            Stencil{
                Ref 3
                Comp Equal
                Pass keep
                Fail keep
                ZFail keep
            }

            CGPROGRAM
            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                return fixed4 (0.6, 0.6, 0.6, 1);
            }
            ENDCG
        }

        Pass
        {
            Stencil{
                Ref 4
                Comp Equal
                Pass keep
                Fail keep
                ZFail keep
            }

            CGPROGRAM
            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                return fixed4 (1, 1, 1, 1);
            }
            ENDCG
        }
    }
}
