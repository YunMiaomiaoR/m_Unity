Shader "Unlit/3.1.1 StencilMask"
{
    Properties
    {
        _ID("Mask ID", int) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue" = "Geometry+1" }    // 渲染队列
        ColorMask 0 // RGBA\RGB\R\G\B\0  0表示什么都不输出
        ZWrite off
        Stencil
        {
            // 前像素stencil值与ID进行比较
            Ref[_ID]
            //测试条件
            Comp always // 默认always
            //如果测试通过对此stencil值进行的写入操作：保持当前stencil值
            Pass replace // 默认keep
            //如果测试失败对此stencil值进行的写入操作：保持当前stencil值
            // Fail keep
            //如果深度测试失败对此stencil值进行的写入操作：保持当前stencil值
            // ZFail keep
            // 不写都是默认
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
