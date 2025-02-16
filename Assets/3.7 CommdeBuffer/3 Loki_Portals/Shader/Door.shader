Shader "Shader/Portal"
{
    Properties
    {
        [Header(Glass)]
        // 主纹理
        _MainTex     ("Main Texture", 2D)                   = "white" {}
        _ColorInt    ("Main Texture Tint", Range(0.0, 1.0)) = 0.5
        // 凹凸贴图
        _BumpMap     ("Bumpmap", 2D)                        = "bump" {}
        _BumpInt     ("Bumpmap Intensity", Range(0, 64))    = 10
        // 扰动
        _NoiseTex    ("Noise Texture", 2D)                  = "bump" {}
        _NoiseInt    ("Distort Intensity", Range(0.0, 1.0)) = 0.5

        _GlassColor  ("Glass Color", Color)                 = (1, 1, 1, 1)
        _Transparency("Transparency", Range(0.0, 1.0))      = 0.5

        [Header(Border)]
        _BorderSize         ("Border Size", Range(0.0, 0.05))        = 0.01
  [HDR] _BorderColor        ("Border Color", Color)                  = (0.0, 0.0, 0.0, 1.0)
        _BorderTransparency ("Border Transparency", Range(0.0, 1.0)) = 0.5
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue" = "Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite On
        //ZTest LEqual
        // unity内置阴影shader，将物体的深度信息渲染到阴影贴图中
		UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"

        Pass
        {
            Name"BASE"
            Tags {"LightMode"="Always" }

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
                float4 vertex    : SV_POSITION;
                float2 uvmain    : TEXCOORD0;
                float2 uvbump    : TEXCOORD1;
                float2 uvdistort : TEXCOORD2;
                float4 uvgrab    : TEXCOORD3;
            };

            // Glass
            sampler2D _MainTex;    float4 _MainTex_ST;
            float     _ColorInt;
            sampler2D _BumpMap;    float4 _BumpMap_ST;
            float     _BumpInt;
            sampler2D _NoiseTex;   float4 _NoiseTex_ST;
            float     _NoiseInt;
            fixed4    _GlassColor;
            float     _Transparency;
            // Border
            float     _BorderSize;
            float4    _BorderColor;
            float     _BorderTransparency;

            // 用于生成矩形的函数
            /*
            UV * 2 - 1：将UV坐标从[0, 1]范围转换到[-1, 1]范围。
            abs(...)：取绝对值，使得坐标值在[-1, 1]范围内对称。
            - float2(Width, Height)：减去矩形的宽度和高度，得到距离矩形边界的距离。

            fwidth(d)：计算d在屏幕空间中的导数，用于抗锯齿处理。fwidth通常返回d在x和y方向上的导数之和。
            d / fwidth(d)：将距离d归一化，使得距离的单位与屏幕像素相关。
            1 - ...：将距离转换为一个从1到0的渐变值，距离越近值越大，距离越远值越小。

            min(d.x, d.y)：取d.x和d.y中的较小值，表示距离矩形边界的最小距离。
            saturate(...)：将结果限制在[0, 1]范围内，确保输出值不会超出这个范围。
            */
            void Unity_Rectangle_float(float2 UV, float Width, float Height, out float Out)
            {
                float2 d = abs(UV * 2 - 1) - float2(Width, Height);
                d = 1 - d / fwidth(d);
                Out = saturate(min(d.x, d.y));
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uvbump = TRANSFORM_TEX(v.uv, _BumpMap);
                o.uvmain = TRANSFORM_TEX(v.uv, _MainTex);
                o.uvdistort = TRANSFORM_TEX(v.uv, _NoiseTex);
                // 解决平台差异
                #if UNITY_UV_STARTS_AT_TOP
                float scale = -1.0;
                #else
                float scale = 1.0;
                #endif
                // 将顶点裁剪空间下的坐标，计算NDC空间上的位置后，映射到模糊纹理的uv
                o.uvgrab.xy = (float2 (o.vertex.x, o.vertex.y * scale) + o.vertex.w) * 0.5;
                o.uvgrab.zw = o.vertex.zw;
                return o;
            }

            // 抓屏得到的模糊纹理会赋值到此
            sampler2D _GrabBlurTexture;
            float4    _GrabBlurTexture_TexelSize;

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed2 distort = (tex2D(_NoiseTex, i.uvdistort).xy * 2 - 1) * _NoiseInt;
                fixed2 distortUV = i.uvmain + distort;
                fixed4 glassCol = tex2D(_MainTex, distortUV) * _GlassColor;
                glassCol = fixed4(glassCol.rgb, _Transparency);

                // 计算方框mask
                float rectangleMask;
                float borderSize = 1 - _BorderSize;
                Unity_Rectangle_float(i.uvmain, borderSize, borderSize, rectangleMask);
                rectangleMask = 1 - rectangleMask;
                fixed4 borderColor = _BorderColor * rectangleMask * _BorderTransparency;

                // 模糊
                half2 bump = UnpackNormal(tex2D(_BumpMap, i.uvbump)).rg;
                float2 offset = bump * _BumpInt * _GrabBlurTexture_TexelSize.xy;
                i.uvgrab.xy = offset * i.uvgrab.z + i.uvgrab.xy;
                half4 col = tex2Dproj(_GrabBlurTexture, UNITY_PROJ_COORD(i.uvgrab));

                fixed4 finalCol = lerp(col, glassCol, _ColorInt) + borderColor;
                return finalCol;
            }
            ENDCG
        }
    }
}
