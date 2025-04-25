Shader "Unlit/Floor"
{
    Properties
    {
        [Header(Color)]
        _MainTex ("Main Texure", 2D) = "white" {}
        _BaseColor("Base Color", Color) = (0.5,0.5,0.5,1)
[HDR]   _TintCol ("Tint Color", Color) = (0.5, 0.5, 1, 1)
//[HDR]   _WayCol  ("Way Color", Color) = (0.5, 0.5, 1, 1)
        _Opacity ("Opacity", Range(0, 1)) = 0.5

        [Header(Reflection)]
        _ReflectionInt   ("Reflection Intensity", Range(0, 1)) = 0.5
        _HorizonDistance ("Horizon Distance", Range(1, 30)) = 5

        [Header(Flow)]
        _MaskTex ("Mask Texture", 2D) = "white" {}
        _FlowInt ("Flow Intensity", Range(0.0, 5.0))   = 1.0
        _FlowSpeed ("Flow Speed - XY", Vector) = (0.5, 0.5 , 0, 0)

        _NoiseTex ("Noise Texture", 2D) = "white" {}
        _NoiseInt ("Noise Intensity", Range(0.0, 0.1)) = 0.02
        _DistortTex("DistortTex", 2D) = "white"{}
        _DistortInt("Distort Intensity", Range(0.0, 5.0)) = 1.0
        
        [Header(Star)]
		_StarTex("Star Texture", 2D) = "white" {}
        _StarColor("Star Color", Color) = (1, 1, 1, 1)
        _ShiningSpeed ("Shining Speed", Float) = 0.1
    }
    SubShader
    {
        Tags { "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "TransparentCutout" }
        Blend SrcAlpha OneMinusSrcAlpha
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #pragma target 3.0

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 viewNormal: NORMAL;
                float4 screenPos : TEXCOORD1;
				float3 viewDir:TEXCOORD2;
                float3 nDir   : TEXCOORD3;
                float2 noiseUV   : TEXCOORD4;
                float2 distortUV : TEXCOORD5;
            };

            // Color
            sampler2D _MainTex;  float4 _MainTex_ST;
            half4     _BaseColor;
            half4     _TintCol, _WayCol;
            float     _Opacity;
            
            // reflect
            sampler2D _ReflectionTex;   float4 _ReflectionTex_ST;
            float     _ReflectionInt;
            float     _HorizonDistance;

            // Flow
            sampler2D _MaskTex;     float4 _MaskTex_TexelSize, _MaskTex_ST;
            float     _FlowInt;
            float2    _FlowSpeed;

            sampler2D _NoiseTex; float4 _NoiseTex_ST;
            float     _NoiseInt;
            sampler2D _DistortTex; float4 _DistortTex_ST;
            float     _DistortInt;

            // Star
            sampler2D _StarTex;  float4 _StarTex_ST;
            half4     _StarColor;
            float     _ShiningSpeed;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.screenPos = ComputeScreenPos(o.vertex);
				float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.viewDir = normalize(_WorldSpaceCameraPos.xyz - worldPos.xyz);
                o.nDir   = UnityObjectToWorldNormal(v.normal);
                o.viewNormal = COMPUTE_VIEW_NORMAL;
                o.noiseUV = TRANSFORM_TEX(v.uv, _NoiseTex);
                o.distortUV = TRANSFORM_TEX(v.uv, _DistortTex);
                return o;
            }

            // 高度To法线函数
            float3 HigthToNormal(sampler2D heigthTex ,float2 heigth_TexelSize , float2 uv)
            {
                float3 offset = float3(heigth_TexelSize.xy,0);
                float factor = _FlowInt;
                float3 S = float3(1,0, (tex2D(heigthTex,uv + offset.xz).x - tex2D(heigthTex,uv - offset.xz).x)*factor); //x方向
                float3 T = float3(0,1, (tex2D(heigthTex,uv + offset.zy).x - tex2D(heigthTex,uv - offset.zy).x)*factor); //y方向
                float3 d = cross(S,T) + float3(0.5,0.5,1);   //叉积计算法线方向，对法线进行偏移，调整其颜色范围
                return d;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 flowDir = normalize(HigthToNormal(_MaskTex, _MaskTex_TexelSize.xy, i.uv));

                // 非匀速流动 + Flowmap
                // 采样向量场信息, 将颜色值从[0, 1]映射到 方向向量[-1, 1]
                // float3 flowDir = tex2D(_Flowmap, i.uv) * 2.0 - 1.0;
                // 调整采样时的UV为：adjust_uv = uv - flowDir * time
                // flowDir *= -_FlowInt;

                // 构造两个差半相位的波形函数
                float phase0 = frac(_Time.y * _FlowSpeed);
                float phase1 = frac(_Time.y * _FlowSpeed + 0.5);

                // 波形函数
                float flowFactor0 = cos(sin(cos(phase0 * UNITY_PI)) + 0.5);
                float flowFactor1 = cos(sin(cos(phase1 * UNITY_PI)) + 0.5);

                // 扰动UV,[0, 1]→[-1,1]; 传递颜色用rgba，传递向量用xyzw，本质上没有区别
                float2 waterDistort = (tex2D(_DistortTex, i.distortUV).xy * 2 - 1) * _DistortInt;

                // UV流速
                float2 noiseUV = float2((i.noiseUV.x + phase0) + waterDistort.x,
                                        (i.noiseUV.y + phase0) + waterDistort.y);

                // 采样噪声
                float surfaceNoise = tex2D(_NoiseTex, noiseUV).r;

                // 采样用的uv
                float2 tilingUV = i.uv * _MainTex_ST.xy + _MainTex_ST.zw + surfaceNoise * _NoiseInt;
                
                // 采样
                half3 tex0 = tex2D(_MainTex, tilingUV - flowDir.xy * flowFactor0);
                half3 tex1 = tex2D(_MainTex, tilingUV - flowDir.xy * flowFactor1);

                // 构造权重函数
                float flowLerp = abs(phase0 - 0.5) * 2;
                half3 seaCol = lerp(tex0, tex1, flowLerp) * _BaseColor * _TintCol;

                // 反射
                float2 reflectUV = i.screenPos.xy / i.screenPos.w + surfaceNoise * _NoiseInt;
                fixed4 var_ReflectionTex = tex2D(_ReflectionTex, reflectUV);
                fixed3 reflectCol = var_ReflectionTex.rgb * seaCol;
                // 混合反射与水面颜色
                //fixed3 finalCol = seaCol * var_ReflectionTex;
                fixed3 finalCol = lerp(seaCol, var_ReflectionTex, _ReflectionInt);
                // 加入菲涅尔效应增强真实感
                float fresnel = pow(1.0 - saturate(dot(i.viewDir, i.nDir)), _HorizonDistance);
                finalCol += var_ReflectionTex * fresnel * 0.5;

                //// 星光闪烁
			    //第一次采样星光图，
			    fixed4 star0 = tex2D(_StarTex, TRANSFORM_TEX(-i.uv, _StarTex));
			    //第二次采样星光贴图，第二次采样的UV做偏移
			    fixed4 star1 = tex2D(_StarTex, tilingUV - phase0 * _ShiningSpeed);
			    //把两张星光图简单相乘，只有两张图有白点重合的地方才会显示，这样就有闪烁的效果了，最后乘上星光颜色
			    seaCol += (star0.rgb * star1.rgb * _StarColor);

                return half4 (finalCol, _Opacity);
            }
            ENDCG
        }
    }
}
