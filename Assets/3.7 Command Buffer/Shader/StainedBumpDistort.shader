// 没有使用grab pass并且采样率一张不同的贴图
Shader "Unlit/Stained BumpDistort (no Grab)"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BumpMap ("Bumpmap", 2D) = "bump" {}

        _BumpInt ("扭曲程度", Range(0, 64)) = 10
        _TintAmt ("玻璃显色", Range(0, 1)) = 0.1
    }

    Category{
        // 保证其他物体在这个物体之前渲染
        Tags { "Queue"="Transparent" "RenderType"="Opaque" }

        SubShader
        {
            Pass
            {
                Name "BASE"
                Tags {"LightMode" = "Always"}
                Blend SrcAlpha OneMinusSrcAlpha

                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #pragma multi_compile fog
                #include "UnityCG.cginc"

                struct appdata
                {
                    float4 vertex : POSITION;
                    float2 uv : TEXCOORD0;
                };

                struct v2f
                {
                    float4 vertex : SV_POSITION;
                    float4 uvgrab : TEXCOORD0;
                    float2 uvbump : TEXCOORD1;
                    float2 uv : TEXCOORD2;
                    UNITY_FOG_COORDS(3)
                };

                sampler2D _MainTex; float4 _MainTex_ST;
                sampler2D _BumpMap; float4 _BumpMap_ST;

                float _BumpInt;
                half  _TintAmt;

                v2f vert (appdata v)
                {
                    v2f o;
                    o.vertex = UnityObjectToClipPos(v.vertex);

                 // UNITY_UV_STARTS_AT_TOP 是为了解决 RT coordinates 的平台差异
                 // Direct3D Metal 和 Game Consoles 是：坐标顶部为0，向下增加
                 // OpenGL 和 OpenGL ES是：坐标底部为0，向上增加
                 #if UNITY_UV_STARTS_AT_TOP
                     float scale = -1.0;
                 #else
                     float scale = 1.0;
                 #endif
                    // 计算采样RT的uv
                    o.uvgrab.xy = (float2(o.vertex.x, o.vertex.y*scale) + o.vertex.w) * 0.5;    //remap到[0,1] 标准化设备→纹理坐标
                    o.uvgrab.zw = o.vertex.zw;
                    o.uvbump = TRANSFORM_TEX(v.uv, _BumpMap);
                    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                    UNITY_TRANSFER_FOG(o, o.vertex);
                    return o;
                }

                sampler2D _GrabBlurTexture;
                // _GrabBlurTexture_TexelSize = Vector4(1/width, 1/height, width, height); 模糊纹理的每个像素的尺寸
                // 在Direct平台，如果我们开启了抗锯齿，则xxx_TexelSize.y 会编程负值，好让我们能正确采样
                // 所以可以使用if(_MainTex_TexelSize.y < 0) 作用是判断我们当前是否开启了抗锯齿
                float4 _GrabBlurTexture_TexelSize;

                fixed4 frag (v2f i) : SV_Target
                {
                    // 计算扰动的纹理坐标。我们只读取xy 不重构z，来进行优化
                    half2 bump = UnpackNormal(tex2D(_BumpMap, i.uvbump)).rg;
                    float2 offset = bump * _BumpInt * _GrabBlurTexture_TexelSize.xy;
                    i.uvgrab.xy = offset * i.uvgrab.z + i.uvgrab.xy;
                    
                    half4 col = tex2Dproj(_GrabBlurTexture, UNITY_PROJ_COORD(i.uvgrab));    //采样模糊后的贴图
                    //UNITY_PROJ_COORD(a) 函数：传入一个四维变量，返回适合投影纹理读取的纹理坐标，在大多数平台上是返回传入的值
                    //tex2Dproj 处理透视投影，它会执行透视除法，适用于投影空间坐标。

                    half4 tint = tex2D(_MainTex, i.uv);
                    col = lerp(col, tint, _TintAmt);

                    UNITY_APPLY_FOG(i.fogCoord, col);

                    return col;
                }
                ENDCG
            }
        }

    }
}
