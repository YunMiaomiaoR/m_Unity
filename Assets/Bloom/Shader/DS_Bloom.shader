Shader "Unlit/DS_Bloom"
{
    Properties
    {
        // 变量名和C#脚本中的对应
        _MainTex            ("Texture", 2D)                 = "white" {}
[HideInInspector] _Bloom    ("Bloom(RGB)", 2D)              = "black" {} //高斯模糊后的结果
        _LuminanceThreshold ("Luminance Threshold", Float)  = 0.5 //阈值
        _BlurSize           ("Blur Size", Float)            = 1.0 //模糊半径
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        ZTest Always
        Cull Off

        CGINCLUDE
        #include "UnityCG.cginc"

        sampler2D _MainTex; float4 _MainTex_ST;
        half4     _MainTex_TexelSize;
        sampler2D _Bloom;
        float     _LuminanceThreshold;
        float     _BlurSize;

        // ---- 第一个Pass使用 ----
        // 输出结构
        struct v2fExtractBright
        {
            float4 pos : SV_POSITION;
            float2 uv  : TEXCOORD0;
        };

        // 顶点着色器
        v2fExtractBright vertExtractBright (appdata_img v)
        {
            v2fExtractBright o;
            o.pos = UnityObjectToClipPos(v.vertex);
            o.uv = v.texcoord;
            return o;
        }

        // 明亮度公式
        fixed luminance(fixed4 color)
        {
            // 计算亮度值
            return 0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b;
        }

        // 片元着色器 -- 提取高亮区域
        fixed4 fragExtractBright (v2fExtractBright i) : SV_Target
        {
            fixed4 col = tex2D(_MainTex, i.uv);
            // 调用luminance得到采样后像素的亮度值，再减去阈值
			// 使用clamp函数将结果截取在[0,1]范围内
            fixed value = clamp(luminance(col) - _LuminanceThreshold, 0.0, 1.0);
            // 将val与原贴图采样得到的像素值相乘，得到提取后的亮部区域
            return col * value;
        }

        // ---- 第2、3个Pass使用 ----
        struct v2fBlur
        {
            float4 pos   : SV_POSITION;
            float2 uv[5] : TEXCOORD0;
			// 此处定义5维数组用来计算5个纹理坐标
        	// 由于卷积核大小为5x5的二维高斯核可以拆分两个大小为5的一维高斯核
        	// uv[0]存储了当前的采样纹理
        	// uv[1][2][3][4]为高斯模糊中对邻域采样时使用的纹理坐标        
        };

        // 顶点着色器 -- 竖直方向模糊
        v2fBlur vertBlurVertical(appdata_img v)
        {
            v2fBlur o;
            o.pos = UnityObjectToClipPos(v.vertex);
            half2 uv = v.texcoord;
            o.uv[0] = uv;
            //uv[0]就是（0,0）

        	//对竖直方向进行模糊
            //uv[1]，向上挪动1个单位(0, 1)
        	//uv[2]，向下挪动1个单位(0, -1)
        	//uv[3]，向上挪动2个单位(0, 2)
        	//uv[4]，向下挪动2个单位(0, -2)
            o.uv[1] = uv + float2(0.0, _MainTex_TexelSize.y * 1.0) * _BlurSize;
            o.uv[2] = uv - float2(0.0, _MainTex_TexelSize.y * 1.0) * _BlurSize;
            o.uv[3] = uv + float2(0.0, _MainTex_TexelSize.y * 2.0) * _BlurSize;
            o.uv[4] = uv - float2(0.0, _MainTex_TexelSize.y * 2.0) * _BlurSize;

            return o;
        }

        // 顶点着色器 -- 水平方向模糊
        v2fBlur vertBlurHorizontal(appdata_img v)
        {
            v2fBlur o;
            o.pos = UnityObjectToClipPos(v.vertex);
            half2 uv = v.texcoord;
            o.uv[0] = uv;
            //uv[0]就是（0,0）

        	//对竖直方向进行模糊，对应(1, 0)、(-1, 0)、(2, 0)、(-2, 0)
            o.uv[1] = uv + float2(_MainTex_TexelSize.y * 1.0, 0.0) * _BlurSize;
            o.uv[2] = uv - float2(_MainTex_TexelSize.y * 1.0, 0.0) * _BlurSize;
            o.uv[3] = uv + float2(_MainTex_TexelSize.y * 2.0, 0.0) * _BlurSize;
            o.uv[4] = uv - float2(_MainTex_TexelSize.y * 2.0, 0.0) * _BlurSize;

            return o;
        }

        // 片元着色器 -- 高斯模糊
        fixed4 fragBlur(v2fBlur i) : SV_Target
        {
            // 因为二维高斯核具有可分离性，而分离得到的一维高斯核具有对称性, 所以只需要在数组存放三个高斯权重即可
            float weight[3] = {0.4026, 0.2442, 0.0545};
            // sum初始化为当前的像素诚意它对应的权重值(滤波后的结果)
            fixed3 sum = tex2D(_MainTex, i.uv[0]).rgb * weight[0];
            // 进行卷积运算，根据对称性完成两次循环
				// 第一次循环计算第二个和第三个格子内的结果
				// 第二次循环计算第四个和第五个格子内的结果
            for (int it = 1; it < 3; it++)
            {
                sum += tex2D(_MainTex, i.uv[it*2-1]).rgb * weight[it];
                sum += tex2D(_MainTex, i.uv[it*2]).rgb * weight[it];
            }
            return fixed4(sum, 1.0);
        }

        // ---- 第四个Pass使用 ----
        // 输出结构 —— 混合亮部图像
        struct v2fBloom
        {
            float4 pos : SV_POSITION;
            float4 uv  : TEXCOORD0;
        };
        
        // 顶点着色器
        v2fBloom vertBloom (appdata_img v)
        {
            v2fBloom o;
            o.pos = UnityObjectToClipPos(v.vertex);
            o.uv.xy = v.texcoord;   //xy分量为_MainTex的纹理坐标
            o.uv.zw = v.texcoord;   //zw分量为_Bloom的纹理坐标
            // 平台差异化处理
            #if UNITY_UV_STARTS_AT_TOP
            if (_MainTex_TexelSize.y < 0.0)
                o.uv.w = 1.0 - o.uv.w;
            #endif
            return o;
        }

        fixed4 fragBloom(v2fBloom i) : SV_Target
        {
            return tex2D(_MainTex, i.uv.xy) + tex2D(_Bloom, i.uv.zw);
        }
        ENDCG
        
        // ---- 第一个Pass，提取较亮区域 ----
        Pass
        {
            CGPROGRAM
            #pragma vertex vertExtractBright
            #pragma fragment fragExtractBright
            ENDCG
        }

        // ---- 第二个Pass，垂直模糊 ----
        Pass
        {
            CGPROGRAM
            #pragma vertex vertBlurVertical
            #pragma fragment fragBlur
            ENDCG
        }

        // ---- 第三个Pass，水平模糊 ----
        Pass
        {
            CGPROGRAM
            #pragma vertex vertBlurHorizontal
            #pragma fragment fragBlur
            ENDCG
        }

        // ---- 第四个Pass，亮部混合 ----
        Pass
        {
            CGPROGRAM
            #pragma vertex vertBloom
            #pragma fragment fragBloom
            ENDCG
        }
    }
    FallBack Off
}